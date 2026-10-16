// Helper parsing JSON dari API PHP (PDO bisa mengembalikan angka sebagai String).

int toInt(dynamic v) =>
    v is int ? v : (int.tryParse('$v') ?? (double.tryParse('$v')?.toInt() ?? 0));

double toDouble(dynamic v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

/// Semua tanggal di database adalah UTC.
DateTime parseUtc(dynamic v) {
  final s = '$v'.trim();
  if (s.isEmpty || s == 'null') return DateTime.now().toUtc();
  final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
  final hasZone =
      iso.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(iso);
  return DateTime.parse(hasZone ? iso : '${iso}Z').toUtc();
}

/// `data` bisa berupa List langsung atau Map berisi satu List (mis. {members: [...]}).
List<Map<String, dynamic>> asList(dynamic data) {
  dynamic l = data;
  if (data is Map) {
    l = data.values.firstWhere((v) => v is List, orElse: () => <dynamic>[]);
  }
  return (l as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

/// `data` bisa berupa objek langsung atau dibungkus (mis. {member: {...}}).
Map<String, dynamic> asObject(dynamic data) {
  final m = Map<String, dynamic>.from(data as Map);
  if (m.containsKey('id')) return m;
  for (final v in m.values) {
    if (v is Map) return Map<String, dynamic>.from(v);
  }
  return m;
}
