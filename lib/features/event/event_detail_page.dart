import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../core/routes.dart';
import '../../theme/cosmic_widgets.dart';
import '../notification/notification_service.dart';
import '../tools/time_service.dart';
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

  String _selectedTzName = 'Asia/Jakarta';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pengingat dibatalkan')));
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
      appBar: AppBar(title: Text(_event?.title ?? 'Detail Event')),
      body: _loading
          ? const CosmicLoading(message: 'Memuat informasi detail event...')
          : _error != null
          ? CosmicErrorView(message: _error!, onRetry: _load)
          : _buildEventBody(_event!),
    );
  }

  Widget _buildEventBody(Event e) {
    // 8 required timezones
    final zones = TimeService.requiredZones;
    final convertedTime = TimeService.at(e.eventDate, _selectedTzName);
    final selectedZoneOption = zones.firstWhere(
      (z) => z.tzName == _selectedTzName,
      orElse: () => zones.first,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                e.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppTheme.surfaceElevated,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
        // Route shortcut to LBS, carrying the selected event ID.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              Routes.nearby,
              arguments: e.id,
            ),
            icon: const Icon(Icons.directions),
            label: const Text('Lihat rute di peta'),
          ),
        ),
        const SizedBox(height: 12),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (e.isPast ? AppTheme.textMuted : AppTheme.coronaGold)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      e.isPast ? 'SELESAI' : 'MENDATANG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: e.isPast
                            ? AppTheme.textSecondary
                            : AppTheme.coronaGold,
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
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppTheme.coronaGold,
                  ),
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

        // Timezone Converter Box (Master Prompt requirement: WIB, WITA, WIT, London, Jepang, Singapura, Malaysia, Thailand)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.eclipseViolet.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.eclipseViolet.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.public,
                      color: AppTheme.coolCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konversi Zona Waktu Dunia',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Waktu event otomatis dikonversi ke zona pilihan',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Horizontal Chips for 8 Timezones
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: zones.map((z) {
                    final isSel = z.tzName == _selectedTzName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(z.label),
                        selected: isSel,
                        selectedColor: AppTheme.eclipseViolet,
                        backgroundColor: AppTheme.deepSpace,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedTzName = z.tzName);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.deepSpace,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu di ${selectedZoneOption.label}:',
                      style: const TextStyle(
                        color: AppTheme.coolCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy · HH:mm')
                          .format(convertedTime),
                      style: const TextStyle(
                        color: AppTheme.coronaGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zona IANA: $_selectedTzName (Offset: ${convertedTime.timeZoneOffset.isNegative ? '-' : '+'}${convertedTime.timeZoneOffset.inHours} Jam)',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
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
                    child: const Icon(
                      Icons.place_outlined,
                      color: AppTheme.coolCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lokasi & Venue',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
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
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppTheme.eclipseViolet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Koordinat GPS',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
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
                e.description.isEmpty
                    ? 'Tidak ada keterangan tambahan.'
                    : e.description,
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
                : (_reminderOn
                      ? AppTheme.surfaceSecondary
                      : AppTheme.eclipseViolet),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
          ),
          onPressed: e.isPast ? null : () => _toggleReminder(e),
          icon: Icon(
            _reminderOn
                ? Icons.notifications_off_outlined
                : Icons.notification_add_outlined,
            size: 20,
          ),
          label: Text(
            e.isPast
                ? 'Event Sudah Berakhir'
                : (_reminderOn
                      ? 'Batalkan Pengingat Notifikasi'
                      : 'Ingatkan Saya (Notifikasi)'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
