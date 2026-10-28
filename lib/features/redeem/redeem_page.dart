import 'package:flutter/material.dart';
import 'dart:ui';

import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import '../../core/routes.dart';
import 'eclipse_card_model.dart';
import 'photocard_flip_dialog.dart';
import 'redeem_service.dart';
import '../membership/membership_service.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  bool _isLoading = true;
  bool _isMember = false;
  String? _errorMessage;
  int _userPoints = 0;
  int _redeemQuota = 0;
  List<int> _ownedCardIds = [];
  List<EclipseCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isMember = await MembershipService.isActive();
      final membership = await MembershipService.currentMembership();
      final quota = (membership?['redeem_quota'] as num?)?.toInt() ?? 0;
      final results = await Future.wait([
        RedeemService.getUserStats(),
        RedeemService.getCards(),
      ]);

      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      setState(() {
        _isMember = isMember && quota > 0;
        _redeemQuota = quota;
        _userPoints = data['points'] as int? ?? 0;
        _ownedCardIds = (data['owned_cards'] as List? ?? [])
            .map((value) => int.tryParse(value.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
        _cards = results[1] as List<EclipseCard>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openCardDetail(EclipseCard card, bool isOwned) {
    showDialog(
      context: context,
      builder: (_) => PhotocardFlipDialog(card: card, isOwned: isOwned),
    );
  }

  Future<void> _handleRedeem(EclipseCard card) async {
    if (!_isMember || _redeemQuota <= 0) {
      _showUpgradeDialog();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Redeem',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Gunakan 1 kuota membership untuk membuka kartu "${card.name}"? Poin tidak dipotong.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.eclipseViolet),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tukar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);

    try {
      final success = await RedeemService.redeemCard(card.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat! Kartu "${card.name}" berhasil didapatkan!'),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadData();
        if (mounted) _openCardDetail(card, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal redeem kartu. Coba lagi nanti.'), backgroundColor: AppTheme.error),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.error),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AppTheme.coronaGold),
            SizedBox(width: 8),
            Text('Membership Diperlukan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Fitur Redeem Photocard memerlukan kuota membership aktif. Beli atau perpanjang membership EclipseVerse kamu sekarang.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nanti', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.eclipseViolet),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, Routes.membership).then((_) => _loadData());
            },
            child: const Text('Lihat Membership'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        title: const Text('Koleksi Photocard'),
        backgroundColor: AppTheme.deepSpace,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Segarkan data', onPressed: _loadData),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const CosmicLoading(message: 'Memuat koleksi kartu...');
    if (_errorMessage != null) return CosmicErrorView(message: _errorMessage!, onRetry: _loadData);
    if (_cards.isEmpty && _ownedCardIds.isEmpty) {
      return const CosmicEmptyView(title: 'Belum Ada Kartu', subtitle: 'Saat ini belum ada kartu yang bisa ditukar.', icon: Icons.style);
    }

    return Column(
      children: [
        if (!_isMember || _redeemQuota <= 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: .1),
              border: Border.all(color: AppTheme.error.withValues(alpha: .5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.error, size: 32),
                const SizedBox(height: 8),
                const Text('Kuota Redeem Habis', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text(
                  'Kartu yang sudah dimiliki tetap bisa dilihat & di-flip. Untuk membuka kartu baru, kamu membutuhkan kuota membership.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.eclipseViolet),
                    onPressed: () => Navigator.pushNamed(context, Routes.membership).then((_) => _loadData()),
                    child: const Text('Lihat Membership'),
                  ),
                ),
              ],
            ),
          ),

        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.eclipseViolet.withValues(alpha: .3), blurRadius: 15)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Total Poin', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('$_userPoints', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white54),
              Column(
                children: [
                  const Text('Sisa Kuota', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('$_redeemQuota', style: TextStyle(color: _redeemQuota > 0 ? AppTheme.coronaGold : AppTheme.error, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: .6,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final card = _cards[index];
              return _buildCardItem(card, _ownedCardIds.contains(card.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(EclipseCard card, bool isOwned) {
    final canRedeem = _isMember && _redeemQuota > 0;
    return CosmicCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCardDetail(card, isOwned),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: isOwned ? 0 : 4, sigmaY: isOwned ? 0 : 4),
                      child: Image.network(
                        card.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null
                            ? child
                            : Container(color: AppTheme.surfaceSecondary, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.coolCyan))),
                        errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.surfaceSecondary, child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary, size: 40))),
                      ),
                    ),
                    if (!isOwned)
                      Container(
                        color: Colors.black.withValues(alpha: .5),
                        child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 50)),
                      ),
                    if (isOwned)
                      const Positioned(top: 8, right: 8, child: CosmicBadge(text: 'OWNED', color: Colors.green)),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .6), shape: BoxShape.circle),
                        child: const Icon(Icons.flip, size: 16, color: AppTheme.coolCyan),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(card.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    isOwned ? 'Ketuk untuk Flip 3D' : 'Gunakan 1 Kuota Redeem',
                    style: TextStyle(color: isOwned ? AppTheme.coolCyan : AppTheme.coronaGold, fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwned ? AppTheme.surfaceSecondary : (canRedeem ? AppTheme.eclipseViolet : Colors.grey.shade600),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isOwned ? () => _openCardDetail(card, true) : (canRedeem ? () => _handleRedeem(card) : _showUpgradeDialog),
                      child: Text(isOwned ? 'Buka Kartu' : (canRedeem ? 'Tukar' : 'Perlu Member'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
