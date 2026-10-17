import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';

import 'member_model.dart';
import 'member_service.dart';
import 'shared/state_views.dart';

/// Tab 1 di /shell (Fandom): kotak cari + grid 13 member.
class FandomPage extends StatefulWidget {
  const FandomPage({super.key});
  @override
  State<FandomPage> createState() => _FandomPageState();
}

class _FandomPageState extends State<FandomPage> {
  final _search = TextEditingController();
  List<Member> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await MemberService.fetchMembers();
      if (!mounted) return;
      setState(() => _all = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Member> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((m) => m.stageName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fandom')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cari member...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final list = _filtered;
    if (list.isEmpty) return const EmptyView(text: 'Member tidak ditemukan');
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: AppTheme.spacingSmall,
        mainAxisSpacing: AppTheme.spacingSmall,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final m = list[i];
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () =>
              Navigator.pushNamed(context, '/member-detail', arguments: m.id),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: memberColor(m.id),
                    child: Text(
                      m.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    m.stageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: AppTheme.fontSizeBodySmall),
                  ),
                  Text(
                    m.position,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
