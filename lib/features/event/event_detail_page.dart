import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';
// File milik C (H12/H13). Sesuaikan path bila berbeda.
import 'package:eclipseverse/features/notification/notification_service.dart';

import '../fandom/shared/state_views.dart';
import 'event_model.dart';
import 'event_page.dart' show formatEventDate;
import 'event_service.dart';

/// Route /event-detail, argumen: eventId (int).
class EventDetailPage extends StatefulWidget {
  final int? eventId;
  const EventDetailPage({super.key, this.eventId});
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _event;
  bool _loading = true;
  bool _started = false;
  bool _reminderOn = false;
  String? _error;
  int? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    _id = widget.eventId ?? (arg is int ? arg : null);
    _load();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Event tidak ditemukan';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final e = await EventService.fetchEventDetail(id);
      if (!mounted) return;
      setState(() => _event = e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleReminder(Event e) async {
    if (_reminderOn) {
      await NotificationService.cancelEventReminder(e.id);
      if (!mounted) return;
      setState(() => _reminderOn = false);
      showSnack(context, 'Pengingat dibatalkan');
      return;
    }
    try {
      await NotificationService.init(); // meminta izin POST_NOTIFICATIONS
      // Diasumsikan mengembalikan true bila jadwal dibuat, false bila izin ditolak.
      final ok = await NotificationService.scheduleEventReminder(e);
      if (!mounted) return;
      if (ok == true) {
        setState(() => _reminderOn = true);
        showSnack(context, 'Pengingat dijadwalkan');
      } else {
        showSnack(
          context,
          'Izin notifikasi ditolak. Aktifkan di Pengaturan agar pengingat bisa dibuat.',
        );
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Gagal membuat pengingat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Event')),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _content(_event!),
    );
  }

  Widget _content(Event e) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      children: [
        const Icon(Icons.calendar_month, size: 64, color: AppTheme.primaryDark),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(e.title, textAlign: TextAlign.center, style: t.headlineMedium),
        const SizedBox(height: AppTheme.spacingMedium),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(formatEventDate(e.eventDate)),
              ),
              ListTile(
                leading: const Icon(Icons.place),
                title: Text(e.venue),
                subtitle: Text(e.city),
              ),
              ListTile(
                leading: const Icon(Icons.my_location),
                title: Text(
                  '${e.latitude.toStringAsFixed(4)}, ${e.longitude.toStringAsFixed(4)}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text('Deskripsi', style: t.titleLarge),
        const SizedBox(height: AppTheme.spacingXSmall),
        Text(e.description.isEmpty ? '-' : e.description, style: t.bodyLarge),
        const SizedBox(height: AppTheme.spacingLarge),
        ElevatedButton.icon(
          onPressed: e.isPast ? null : () => _toggleReminder(e),
          icon: Icon(
            _reminderOn ? Icons.notifications_off : Icons.notifications_active,
          ),
          label: Text(
            e.isPast
                ? 'Event sudah lewat'
                : (_reminderOn ? 'Batalkan pengingat' : 'Ingatkan saya'),
          ),
        ),
      ],
    );
  }
}
