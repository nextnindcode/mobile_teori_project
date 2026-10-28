import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';

import 'member_model.dart';
import 'member_service.dart';
import 'shared/state_views.dart';

/// Route /member-detail, argumen: memberId (int).
class MemberDetailPage extends StatefulWidget {
  final int? memberId;
  const MemberDetailPage({super.key, this.memberId});
  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  Member? _member;
  bool _loading = true;
  String? _error;
  int? _id;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    _id = widget.memberId ?? (arg is int ? arg : null);
    _load();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Member tidak ditemukan';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final m = await MemberService.fetchDetail(id);
      if (!mounted) return;
      setState(() => _member = m);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        backgroundColor: AppTheme.deepSpace,
        title: Text(_member?.stageName ?? 'Detail Member'),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _content(_member!),
    );
  }

  Widget _content(Member m) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      children: [
        Center(
          child: CircleAvatar(
            radius: 56,
            backgroundColor: memberColor(m.id),
            backgroundImage: m.imageUrl != null && m.imageUrl!.isNotEmpty
                ? NetworkImage(m.imageUrl!)
                : null,
            child: m.imageUrl == null || m.imageUrl!.isEmpty
                ? Text(
                    m.initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          m.stageName,
          textAlign: TextAlign.center,
          style: t.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            Chip(
              label: Text(m.team),
              backgroundColor: AppTheme.eclipseViolet.withValues(alpha: 0.2),
              labelStyle: const TextStyle(
                color: AppTheme.coronaGold,
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide(
                color: AppTheme.eclipseViolet.withValues(alpha: 0.5),
              ),
            ),
            Chip(
              label: Text(m.position),
              backgroundColor: AppTheme.coolCyan.withValues(alpha: 0.18),
              labelStyle: const TextStyle(color: AppTheme.coolCyan),
              side: BorderSide(
                color: AppTheme.coolCyan.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        if (m.extraDetails.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Informasi Member',
            style: t.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          Card(
            color: AppTheme.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: m.extraDetails.entries.map((entry) {
                  final label = entry.key
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
                      .join(' ');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value.toString(), textAlign: TextAlign.end, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'Deskripsi',
          style: t.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXSmall),
        Text(
          m.description.isEmpty ? '-' : m.description,
          style: t.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Card(
          color: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.lightbulb_outline,
              color: AppTheme.coronaGold,
            ),
            title: const Text(
              'Fun fact',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              m.funFact.isEmpty ? '-' : m.funFact,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
