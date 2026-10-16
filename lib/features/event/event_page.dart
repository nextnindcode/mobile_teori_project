import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_project_bgt_nih/theme/app_theme.dart';
import '../fandom/shared/state_views.dart';
import 'event_model.dart';
import 'event_service.dart';

String formatEventDate(DateTime utc) {
  final l = utc.toLocal(); // waktu ditampilkan sesuai zona HP
  return '${DateFormat('EEE, d MMM yyyy • HH:mm').format(l)} ${l.timeZoneName}';
}

/// Route /events.
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
      setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _events.isEmpty
                  ? const EmptyView(
                      text: 'Belum ada event', icon: Icons.event_busy)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        itemCount: _events.length,
                        itemBuilder: (_, i) {
                          final e = _events[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_month,
                                  color: AppTheme.primaryDark, size: 32),
                              title: Text(e.title),
                              subtitle: Text(
                                  '${e.city} • ${e.venue}\n${formatEventDate(e.eventDate)}'),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pushNamed(
                                  context, '/event-detail',
                                  arguments: e.id),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
