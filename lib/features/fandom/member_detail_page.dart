import 'package:flutter/material.dart';
import 'package:final_project_bgt_nih/theme/app_theme.dart';
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
      appBar: AppBar(title: Text(_member?.stageName ?? 'Member')),
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
            child: Text(m.initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(m.stageName, textAlign: TextAlign.center, style: t.headlineMedium),
        const SizedBox(height: AppTheme.spacingSmall),
        Center(
          child: Chip(
            label: Text(m.position),
            backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text('Deskripsi', style: t.titleLarge),
        const SizedBox(height: AppTheme.spacingXSmall),
        Text(m.description.isEmpty ? '-' : m.description, style: t.bodyLarge),
        const SizedBox(height: AppTheme.spacingMedium),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline,
                color: AppTheme.primaryDark),
            title: const Text('Fun fact'),
            subtitle: Text(m.funFact.isEmpty ? '-' : m.funFact),
          ),
        ),
      ],
    );
  }
}
