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

  Widget _factTile(IconData icon, String title, String value) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppTheme.coronaGold),
          title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
          subtitle: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      );
\n  Widget _content(Member m) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: double.infinity,
            height: 300,
            child: Image.asset(
              m.imageAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: memberColor(m.id),
                alignment: Alignment.center,
                child: Text(m.initial, style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          m.stageName,
          textAlign: TextAlign.center,
          style: t.headlineMedium?.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Center(
          child: Chip(
            label: Text('${m.team} • ${m.position}'),
            backgroundColor: AppTheme.coolCyan.withValues(alpha: 0.18),
            labelStyle: const TextStyle(color: AppTheme.coolCyan),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'Deskripsi',
          style: t.titleLarge?.copyWith(color: AppTheme.textPrimary),
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
        _factTile(Icons.cake_outlined, 'Tanggal lahir', m.birthDate == null ? '-' : '${m.birthDate!.day.toString().padLeft(2, '0')}-${m.birthDate!.month.toString().padLeft(2, '0')}-${m.birthDate!.year}'),
        _factTile(Icons.restaurant_outlined, 'Makanan kesukaan', m.favoriteFood),
        _factTile(Icons.pets_outlined, 'Spirit animal', m.spiritAnimal),
        _factTile(Icons.palette_outlined, 'Warna favorit', m.favoriteColor),
        _factTile(Icons.interests_outlined, 'Hobi', m.hobby),
        _factTile(Icons.lightbulb_outline, 'Fun fact', m.funFact),
      ],
    );
  }
}
