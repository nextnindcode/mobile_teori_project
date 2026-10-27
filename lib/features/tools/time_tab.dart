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
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      _error = 'Waktu belum dapat dihitung. Coba pilih tanggal dan zona asal lagi.';
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        Text('Eclipse Time', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
          'Cocokkan waktu antarnegara untuk merencanakan event, live stream, atau jadwal fandom tanpa menghitung selisih jam sendiri.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 16),
        Card(
          color: AppTheme.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Waktu yang ingin dikonversi', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(DateFormat('d MMM yyyy').format(_date)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(_time.format(context)),
                  )),
                ]),
                const SizedBox(height: 12),
                DropdownField<ZoneOption>(
                  label: 'Zona asal',
                  value: _origin,
                  items: TimeService.originZones.map((z) => DropdownMenuItem(
                    value: z,
                    child: Text('${TimeService.flag(z.tzName)}  ${z.label}'),
                  )).toList(),
                  onChanged: (z) => setState(() { _origin = z ?? _origin; _error = null; }),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ],
        const SizedBox(height: 18),
        const Text('Hasil konversi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Satu baris untuk satu zona agar mudah dibandingkan.', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        for (final entry in results.entries)
          Card(
            color: AppTheme.surfaceElevated,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Text(TimeService.flag(TimeService.zoneCode(entry.key)), style: const TextStyle(fontSize: 25)),
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('EEE, d MMM yyyy').format(entry.value)),
              trailing: Text(
                DateFormat('HH:mm').format(entry.value),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.coolCyan),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.eclipseViolet.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.eclipseViolet.withValues(alpha: .25)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cara pakainya', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Pilih tanggal dan jam → pilih zona asal → Eclipse Time langsung menghitung waktu setaranya di zona lain. Cocok untuk cek jam mulai event atau live stream.', style: TextStyle(color: AppTheme.textSecondary, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}
