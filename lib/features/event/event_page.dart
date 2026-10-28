// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import 'event_model.dart';
import 'event_service.dart';

String formatEventDate(DateTime utc) {
  final l = utc.toLocal();
  return DateFormat('EEE, d MMM yyyy • HH:mm').format(l);
}

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Event> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await EventService.fetchEvents();
      if (!mounted) return;
      setState(() => _events = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        title: const Text('Jadwal & Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan data',
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const CosmicLoading(message: 'Memuat jadwal konser & event...')
          : _error != null
          ? CosmicErrorView(message: _error!, onRetry: _load)
          : _events.isEmpty
          ? const CosmicEmptyView(
              title: 'Belum Ada Jadwal Event',
              subtitle: 'Pantau terus untuk pengumuman konser tur berikutnya!',
              icon: Icons.event_busy_rounded,
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.eclipseViolet,
              backgroundColor: AppTheme.surfaceElevated,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _events.length,
                itemBuilder: (_, i) {
                  final e = _events[i];
                  final isPast = e.isPast;

                  // Tentukan warna background dan border
                  final cardColor = isPast
                      ? Colors.grey.shade900.withValues(alpha: 0.5)
                      : AppTheme.surfaceElevated;
                  final borderColor = isPast
                      ? Colors.grey.shade800
                      : AppTheme.borderSubtle;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: cardColor, // Pakai warna dinamis
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.pushNamed(
                        context,
                        Routes.eventDetail,
                        arguments: e.id,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    e.imageUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                          height: 150,
                                          width: double.infinity,
                                          color: AppTheme.surfaceElevated,
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary, size: 36),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            // Row Header: City Badge & Date Status
                            Row(
                              children: [
                                CosmicBadge(
                                  text: e.city.toUpperCase(),
                                  color: isPast
                                      ? Colors.grey
                                      : AppTheme.coolCyan,
                                  textColor: isPast
                                      ? Colors.grey
                                      : AppTheme.coolCyan,
                                  icon: Icons.location_on_outlined,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isPast
                                                ? Colors.grey
                                                : AppTheme.coronaGold)
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    // GANTI TEKS JADI 'EVENT BERAKHIR'
                                    isPast ? 'EVENT BERAKHIR' : 'MENDATANG',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isPast
                                          ? Colors.grey
                                          : AppTheme.coronaGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              e.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                // Judul
                                color: isPast
                                    ? Colors.grey
                                    : AppTheme.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Venue
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 14,
                                  color: isPast
                                      ? Colors.grey.shade600
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.venue,
                                    style: TextStyle(
                                      color: isPast
                                          ? Colors.grey.shade600
                                          : AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Date
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: isPast
                                      ? Colors.grey.shade600
                                      : AppTheme.coronaGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatEventDate(e.eventDate),
                                  style: TextStyle(
                                    color: isPast
                                        ? Colors.grey.shade600
                                        : AppTheme.coronaGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: isPast
                                      ? Colors.grey.shade600
                                      : AppTheme.coolCyan,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
