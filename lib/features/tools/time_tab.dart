import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:eclipseverse/theme/app_theme.dart';

import '../event/event_model.dart';
import '../event/event_service.dart';
import '../fandom/shared/state_views.dart';
import 'time_service.dart';

class TimeTab extends StatefulWidget {
  const TimeTab({super.key});
  @override
  State<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<TimeTab> {
  int _mode = 0; // 0 = dari event, 1 = manual
  List<Event> _events = [];
  int? _eventId;
  bool _loading = true;
  String? _error;

  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  ZoneOption _origin = TimeService.wib;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await EventService.fetchEvents();
      if (!mounted) return;
      setState(() {
        _events = r;
        _eventId = r.isEmpty ? null : r.first.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, tz.TZDateTime>? _result() {
    if (_mode == 0) {
      final hit = _events.where((e) => e.id == _eventId);
      if (hit.isEmpty) return null;
      return TimeService.convertAll(hit.first.eventDate);
    }
    final utc = TimeService.toUtc(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
      _origin.tzName,
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
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Dari event')),
            ButtonSegment(value: 1, label: Text('Manual')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        if (_mode == 0) _eventPicker() else _manualPicker(),
        const SizedBox(height: AppTheme.spacingMedium),
        ..._results(),
      ],
    );
  }

  Widget _eventPicker() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
    }
    if (_error != null) {
      return SizedBox(
        height: 220,
        child: ErrorView(message: _error!, onRetry: _loadEvents),
      );
    }
    if (_events.isEmpty) return const EmptyView(text: 'Belum ada event');
    return DropdownField<int>(
      label: 'Pilih event',
      value: _eventId!,
      items: _events
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.title, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _eventId = v ?? _eventId),
    );
  }

  Widget _manualPicker() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('d MMM yyyy').format(_date)),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(_time.format(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        DropdownField<ZoneOption>(
          label: 'Zona asal',
          value: _origin,
          items: TimeService.originZones
              .map((z) => DropdownMenuItem(value: z, child: Text(z.label)))
              .toList(),
          onChanged: (z) => setState(() => _origin = z ?? _origin),
        ),
      ],
    );
  }

  List<Widget> _results() {
    final r = _result();
    if (r == null) return [];
    return [
      for (final entry in r.entries)
        Card(
          child: ListTile(
            title: Text(
              entry.key,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              '${DateFormat('EEE, d MMM yyyy').format(entry.value)} • ${entry.value.timeZoneName}',
            ),
            trailing: Text(
              DateFormat('HH:mm').format(entry.value),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
    ];
  }
}
