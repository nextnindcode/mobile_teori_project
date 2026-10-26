import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import 'member_model.dart';
import 'member_service.dart';

class FandomPage extends StatefulWidget {
  const FandomPage({super.key});

  @override
  State<FandomPage> createState() => _FandomPageState();
}

class _FandomPageState extends State<FandomPage> {
  final _search = TextEditingController();
  List<Member> _all = [];
  String _teamFilter = 'Semua';
  static const _teams = [
    'Semua',
    'Vocal Team',
    'Performance Team',
    'Hip-Hop Team',
  ];

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
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Member> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _all.where((m) {
      final matchFilter = _teamFilter == 'Semua' || m.team == _teamFilter;

      final matchSearch =
          q.isEmpty ||
          m.stageName.toLowerCase().contains(q) ||
          m.position.toLowerCase().contains(q);

      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        title: const Text('Direktori Member EclipseVerse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan data',
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama member atau posisi...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.coolCyan),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _teams.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final team = _teams[index];
                return ChoiceChip(
                  label: Text(team),
                  selected: _teamFilter == team,
                  onSelected: (_) => setState(() => _teamFilter = team),
                );
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const CosmicLoading(message: 'Memuat profil member Eclipse...');
    }
    if (_error != null) {
      return CosmicErrorView(message: _error!, onRetry: _load);
    }
    final list = _filtered;
    if (list.isEmpty) {
      return CosmicEmptyView(
        title: 'Member Tidak Ditemukan',
        subtitle: 'Tidak ada member dengan kata kunci "${_search.text}".',
        icon: Icons.person_search_rounded,
        action: OutlinedButton(
          onPressed: () {
            _search.clear();
            setState(() {});
          },
          child: const Text('Reset Pencarian'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.eclipseViolet,
      backgroundColor: AppTheme.surfaceElevated,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final m = list[i];
          final color = memberColor(m.id);

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pushNamed(
                context,
                Routes.memberDetail,
                arguments: m.id,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 132,
                        child: Image.asset(
                          m.imageAssetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: color.withValues(alpha: 0.25),
                            alignment: Alignment.center,
                            child: Text(
                              m.initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      m.stageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Nampilin posisi
                      m.team,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
