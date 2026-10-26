import 'package:flutter/material.dart';
import 'dart:ui'; 
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart'; 
import '../../core/routes.dart'; // Pastikan ini di-import untuk navigasi ke membership
import 'eclipse_card_model.dart';
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
      // 1. Cek status membership & kuota
      final isMember = await MembershipService.isActive();
      final membership = await MembershipService.currentMembership();
      final quota = (membership?['redeem_quota'] as num?)?.toInt() ?? 0;

      // 2. SELALU ambil data stats user dan katalog kartu (jangan pedulikan kuota dulu)
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

  Future<void> _handleRedeem(EclipseCard card) async {
    // Cek kuota dulu sebelum lanjut
    if (!_isMember || _redeemQuota <= 0) {
      _showUpgradeDialog();
      return;
    }

    if (_userPoints < card.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin kamu tidak cukup!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_ownedCardIds.contains(card.id)) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Redeem'),
        content: Text('Gunakan 1 kuota membership (Sisa: $_redeemQuota) untuk mendapatkan kartu ${card.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tukar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await RedeemService.redeemCard(card.id, card.cost);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil mendapatkan ${card.name}!'), backgroundColor: Colors.green),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        // Tampilkan pesan error, lalu refresh data agar UI tidak stuck
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal redeem: $e'), backgroundColor: Colors.red),
        );
        await _loadData(); 
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kuota Habis'),
        content: const Text('Kuota redeem kamu sudah habis. Silakan perpanjang membership dengan poin untuk menukar kartu baru.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, Routes.membership).then((_) => _loadData());
            },
            child: const Text('Beli Membership'),
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
        backgroundColor: Colors.transparent,
        title: const Text('Redeem Card'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CosmicLoading(message: 'Memuat data...');
    }

    // Hanya tampilkan Error View kalau memang error koneksi/database
    if (_errorMessage != null) {
      return CosmicErrorView(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    // Jika data kosong atau tidak ada kartu, tampilkan Empty View
    if (_cards.isEmpty && _ownedCardIds.isEmpty) {
       return const CosmicEmptyView(
        title: 'Belum Ada Kartu',
        subtitle: 'Saat ini belum ada kartu yang bisa ditukar.',
        icon: Icons.style,
      );
    }

    return Column(
      children: [
        // Banner Peringatan jika kuota habis
        if (!_isMember || _redeemQuota <= 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.error, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Kuota Redeem Habis',
                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kartu yang sudah dimiliki tetap bisa dilihat di bawah. Untuk menukar kartu baru, silakan perpanjang membership.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.eclipseViolet,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.membership).then((_) => _loadData());
                    },
                    child: const Text('Beli Membership Lagi'),
                  ),
                )
              ],
            ),
          ),

        // Header Poin dan Kuota 
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.eclipseViolet.withValues(alpha: 0.3), blurRadius: 15)],
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
                  Text('$_redeemQuota', style: TextStyle(
                    color: _redeemQuota > 0 ? AppTheme.coronaGold : AppTheme.error, 
                    fontSize: 32, 
                    fontWeight: FontWeight.bold
                  )),
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
              childAspectRatio: 0.6, 
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final card = _cards[index];
              final isOwned = _ownedCardIds.contains(card.id);
              return _buildCardItem(card, isOwned);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(EclipseCard card, bool isOwned) {
    // Jika tidak punya kuota dan bukan member, tombol dimatikan
    final canRedeem = _isMember && _redeemQuota > 0;

    return CosmicCard(
      padding: EdgeInsets.zero,
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
                    imageFilter: ImageFilter.blur(
                      sigmaX: isOwned ? 0 : 4.0, 
                      sigmaY: isOwned ? 0 : 4.0,
                    ),
                    child: Image.network(
                      card.imageUrl,
                      fit: BoxFit.cover, 
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppTheme.surfaceSecondary,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.coolCyan)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.surfaceSecondary,
                          child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary, size: 40)),
                        );
                      },
                    ),
                  ),
                  
                  if (!isOwned) 
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 50)),
                    ),
                  
                  if (isOwned)
                    Positioned(
                      top: 8, right: 8,
                      child: const CosmicBadge(text: 'OWNED', color: Colors.green),
                    ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  card.name,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (isOwned)
                  const Text('Sudah Dimiliki', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on, color: AppTheme.coronaGold, size: 16),
                          const SizedBox(width: 4),
                          Text('${card.cost} Poin', style: const TextStyle(color: AppTheme.coronaGold, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Butuh 1 Kuota', 
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwned 
                          ? AppTheme.surfaceSecondary 
                          : (canRedeem ? AppTheme.eclipseViolet : Colors.grey.shade600),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: Size.zero, 
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isOwned 
                        ? null 
                        : (canRedeem ? () => _handleRedeem(card) : _showUpgradeDialog),
                    child: Text(
                      isOwned 
                          ? 'Dimiliki' 
                          : (canRedeem ? 'Tukar' : 'Perlu Member'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}