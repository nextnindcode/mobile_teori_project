import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../theme/app_theme.dart';
import '../fandom/shared/state_views.dart';
import 'time_service.dart';

class TimeTab extends StatefulWidget {
  const TimeTab({super.key});
  @override
  State<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<TimeTab> {
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  ZoneOption _origin = TimeService.wib;
  Map<String, tz.TZDateTime> _results = {};
  bool _hasConverted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final nowWib = TimeService.at(DateTime.now().toUtc(), TimeService.wib.tzName);
    _date = DateTime(nowWib.year, nowWib.month, nowWib.day);
    _time = TimeOfDay(hour: nowWib.hour, minute: nowWib.minute);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) setState(() { _date = d; _hasConverted = false; _error = null; });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() { _time = t; _hasConverted = false; _error = null; });
  }

  void _convert() {
    try {
      final utc = TimeService.toUtc(_date.year, _date.month, _date.day, _time.hour, _time.minute, _origin.tzName);
      setState(() {
        _results = TimeService.convertAll(utc);
        _hasConverted = true;
        _error = null;
      });
    } catch (e) {
      setState(() { _results = {}; _hasConverted = false; _error = 'Waktu belum dapat dihitung. Periksa tanggal dan zona asal.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        Text('Eclipse Time', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
          'Cek jam event, live stream, atau jadwal fandom di negara lain. Masukkan satu waktu, lalu Eclipse Time mengubahnya ke beberapa zona sekaligus.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 16),
        Card(
          color: AppTheme.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Waktu asal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Tentukan kapan acaranya dimulai dan dari zona waktu mana.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_rounded), label: Text(DateFormat('d MMM yyyy').format(_date)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule_rounded), label: Text(_time.format(context)))),
              ]),
              const SizedBox(height: 12),
              DropdownField<ZoneOption>(
                label: 'Zona asal',
                value: _origin,
                items: TimeService.originZones.map((z) => DropdownMenuItem(value: z, child: Text('${TimeService.flag(z.tzName)}  ${z.label}'))).toList(),
                onChanged: (z) => setState(() { _origin = z ?? _origin; _hasConverted = false; _error = null; }),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _convert,
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: const Text('Konversi Waktu'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.eclipseViolet, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ]),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ],
        const SizedBox(height: 18),
        const Text('Hasil konversi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_hasConverted ? 'Waktu setara berdasarkan zona $_origin.label.' : 'Hasil akan muncul setelah kamu menekan Konversi Waktu.', style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        if (_hasConverted)
          ..._results.entries.map((entry) => Card(
            color: AppTheme.surfaceElevated,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Text(TimeService.flag(TimeService.zoneCode(entry.key)), style: const TextStyle(fontSize: 25)),
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('EEE, d MMM yyyy').format(entry.value)),
              trailing: Text(DateFormat('HH:mm').format(entry.value), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.coolCyan)),
            ),
          )),
        if (!_hasConverted)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: EmptyView(title: 'Belum ada hasil', subtitle: 'Pilih tanggal, jam, dan zona asal untuk melihat waktu di negara lain.'),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.eclipseViolet.withValues(alpha: .08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.eclipseViolet.withValues(alpha: .25))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Eclipse Time itu buat apa?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Misalnya event dimulai pukul 19.00 WIB. Kamu ingin tahu jam yang sama di Kuala Lumpur, Seoul, Tokyo, atau London? Pilih 19.00 WIB di atas, tekan Konversi Waktu, lalu bandingkan hasilnya satu baris per zona.', style: TextStyle(color: AppTheme.textSecondary, height: 1.45)),
          ]),
        ),
      ],
    );
  }
}
