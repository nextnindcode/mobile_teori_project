import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import '../notification/notification_service.dart';
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
        _error = 'Event ID tidak valid atau tidak ditemukan.';
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
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleReminder(Event e) async {
    if (_reminderOn) {
      await NotificationService.cancelEventReminder(e.id);
      if (!mounted) return;
      setState(() => _reminderOn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengingat dibatalkan')),
      );
      return;
    }
    try {
      await NotificationService.init();
      final ok = await NotificationService.scheduleEventReminder(e);
      if (!mounted) return;
      if (ok == true) {
        setState(() => _reminderOn = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengingat jadwal berhasil diaktifkan!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin notifikasi ditolak. Aktifkan di Pengaturan.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat pengingat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        title: Text(_event?.title ?? 'Detail Event'),
      ),
      body: _loading
          ? const CosmicLoading(message: 'Memuat informasi detail event...')
          : _error != null
              ? CosmicErrorView(message: _error!, onRetry: _load)
              : _buildEventBody(_event!),
    );
  }

  Widget _buildEventBody(Event e) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CosmicBadge(
                    text: e.city.toUpperCase(),
                    color: AppTheme.coolCyan,
                    textColor: AppTheme.coolCyan,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (e.isPast ? AppTheme.textMuted : AppTheme.coronaGold).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      e.isPast ? 'SELESAI' : 'MENDATANG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: e.isPast ? AppTheme.textSecondary : AppTheme.coronaGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                e.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppTheme.coronaGold),
                  const SizedBox(width: 8),
                  Text(
                    formatEventDate(e.eventDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.coronaGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Location & Coordinates Box
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.nebulaIndigo.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.place_outlined, color: AppTheme.coolCyan, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lokasi & Venue',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.venue}, ${e.city}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.eclipseViolet.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location_rounded, color: AppTheme.eclipseViolet, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Koordinat GPS',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.latitude.toStringAsFixed(5)}, ${e.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Description
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentang Acara',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.description.isEmpty ? 'Tidak ada keterangan tambahan.' : e.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Reminder Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: e.isPast
                ? AppTheme.surfaceSecondary
                : (_reminderOn ? AppTheme.surfaceSecondary : AppTheme.eclipseViolet),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
          ),
          onPressed: e.isPast ? null : () => _toggleReminder(e),
          icon: Icon(
            _reminderOn ? Icons.notifications_off_outlined : Icons.notification_add_outlined,
            size: 20,
          ),
          label: Text(
            e.isPast
                ? 'Event Sudah Berakhir'
                : (_reminderOn ? 'Batalkan Pengingat Notifikasi' : 'Ingatkan Saya (Notifikasi)'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
