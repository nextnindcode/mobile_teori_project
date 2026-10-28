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
  int _mode = 0;
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
    setState(() { _loading = true; _error = null; });
    try {
      final events = await EventService.fetchEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _eventId = events.isEmpty ? null : events.first.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, tz.TZDateTime>? _result() {
    if (_mode == 0) {
      final matches = _events.where((event) => event.id == _eventId);
      if (matches.isEmpty) return null;
      return TimeService.convertAll(matches.first.eventDate);
    }
    final utc = TimeService.toUtc(
      _date.year, _date.month, _date.day, _time.hour, _time.minute, _origin.tzName,
    );
    return TimeService.convertAll(utc);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time != null && mounted) setState(() => _time = time);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppTheme.cosmicHeroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.public_rounded, color: AppTheme.coolCyan, size: 30),
              SizedBox(height: 12),
              Text('TIME ZONE EXPLORER', style: TextStyle(color: AppTheme.coolCyan, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Waktu event, di seluruh dunia', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Cari tahu jam konser di WIB, WITA, WIT, London, Jepang, dan zona lainnya.', style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Dari event'), icon: Icon(Icons.event_outlined)),
            ButtonSegment(value: 1, label: Text('Manual'), icon: Icon(Icons.edit_calendar_outlined)),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) => setState(() => _mode = selection.first),
        ),
        const SizedBox(height: 16),
        if (_mode == 0) _eventPicker() else _manualPicker(),
        const SizedBox(height: 22),
        Row(children: [
          const Icon(Icons.language_rounded, color: AppTheme.coronaGold),
          const SizedBox(width: 8),
          Text('Waktu di berbagai zona', style: Theme.of(context).textTheme.titleMedium),
        ]),
        const SizedBox(height: 10),
        ..._results(),
      ],
    );
  }

  Widget _eventPicker() {
    if (_loading) return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
    if (_error != null) return SizedBox(height: 220, child: ErrorView(message: _error!, onRetry: _loadEvents));
    if (_events.isEmpty) return const EmptyView(text: 'Belum ada event untuk dikonversi');
    return _panel(
      child: DropdownField<int>(
        label: 'Pilih event EclipseVerse',
        value: _eventId!,
        items: _events.map((event) => DropdownMenuItem(
          value: event.id,
          child: Text(event.title, overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (value) => setState(() => _eventId = value ?? _eventId),
      ),
    );
  }

  Widget _manualPicker() {
    return _panel(
      child: Column(children: [
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(DateFormat('d MMM yyyy').format(_date)),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time_rounded),
            label: Text(_time.format(context)),
          )),
        ]),
        const SizedBox(height: 14),
        DropdownField<ZoneOption>(
          label: 'Zona waktu asal',
          value: _origin,
          items: TimeService.originZones.map((zone) =>
            DropdownMenuItem(value: zone, child: Text(zone.label))).toList(),
          onChanged: (zone) => setState(() => _origin = zone ?? _origin),
        ),
      ]),
    );
  }

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      border: Border.all(color: AppTheme.borderSubtle),
    ),
    child: child,
  );

  List<Widget> _results() {
    final result = _result();
    if (result == null) return [
      _panel(child: const Text('Pilih event atau masukkan waktu manual untuk melihat hasil.', style: TextStyle(color: AppTheme.textSecondary))),
    ];
    return [
      for (final entry in result.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _panel(
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: AppTheme.eclipseViolet.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.schedule_rounded, color: AppTheme.coolCyan),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(DateFormat('EEE, d MMM yyyy').format(entry.value), style: Theme.of(context).textTheme.bodySmall),
              ])),
              Text(DateFormat('HH:mm').format(entry.value), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.coronaGold)),
            ]),
          ),
        ),
    ];
  }
}
