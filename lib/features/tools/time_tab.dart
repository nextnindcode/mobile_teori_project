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
  String? _error;

  @override
  void initState() {
    super.initState();
    final nowWib = TimeService.at(DateTime.now().toUtc(), TimeService.wib.tzName);
    _date = DateTime(nowWib.year, nowWib.month, nowWib.day);
    _time = TimeOfDay(hour: nowWib.hour, minute: nowWib.minute);
  }

  Map<String, tz.TZDateTime> _result() {
    final utc = TimeService.toUtc(
      _date.year, _date.month, _date.day,
      _time.hour, _time.minute, _origin.tzName,
    );
    return TimeService.convertAll(utc);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (d != null) setState(() { _date = d; _error = null; });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() { _time = t; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, tz.TZDateTime> results = {};
    try {
      results = _result();
    } catch (_) {
      _error = 'Tidak dapat mengonversi waktu. Periksa tanggal dan zona asal.';
    }
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        Text('Konversi Waktu Manual', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingSmall),
        const Text(
          'Pilih tanggal, jam, dan zona waktu asal. Jadwal event tersedia di halaman detail event.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _pickDate, icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('d MMM yyyy').format(_date)),
          )),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(child: OutlinedButton.icon(
            onPressed: _pickTime, icon: const Icon(Icons.access_time),
            label: Text(_time.format(context)),
          )),
        ]),
        const SizedBox(height: AppTheme.spacingMedium),
        DropdownField<ZoneOption>(
          label: 'Zona waktu asal',
          value: _origin,
          items: TimeService.originZones
              .map((z) => DropdownMenuItem(value: z, child: Text(z.label)))
              .toList(),
          onChanged: (z) => setState(() { _origin = z ?? _origin; _error = null; }),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ],
        const SizedBox(height: AppTheme.spacingMedium),
        for (var i = 0; i < results.entries.length; i += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: results.entries.skip(i).take(2).map((entry) => Expanded(
              child: Card(
                color: AppTheme.surfaceElevated,
                margin: const EdgeInsets.all(5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: Theme.of(context).textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(DateFormat('HH:mm').format(entry.value), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.coolCyan, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEE, d MMM yyyy').format(entry.value), style: Theme.of(context).textTheme.bodySmall),
                      Text(entry.value.timeZoneName, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }
}
