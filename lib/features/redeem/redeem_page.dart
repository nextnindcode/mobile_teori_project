import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart'; 
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
  List<int> _ownedCardIds = [];

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
      // 1. Cek status member
      final isMember = await MembershipService.checkIsMember();
      
      if (!isMember) {
        setState(() {
          _isMember = false;
          _isLoading = false;
        });
        return;
      }

      // 2. Jika membership, ambil data poin
      final data = await RedeemService.getUserStats();
      setState(() {
        _isMember = true;
        _userPoints = data['points'] ?? 0;
        _ownedCardIds = (data['owned_cards'] as List? ?? [])
            .map((value) => int.tryParse(value.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRedeem(EclipseCard card) async {
    if (_userPoints < card.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin kamu tidak cukup!'), backgroundColor: Colors.red),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Redeem'),
        content: Text('Tukar ${card.cost} poin dengan kartu ${card.name}?'),
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
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal redeem: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
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

    // Layar akan digembok/terkunci apabila bukan membership 
    if (!_isMember && _errorMessage == null) {
      return CosmicEmptyView(
        title: 'Akses Terkunci',
        subtitle: 'Fitur Redeem Card (Photocard) hanya tersedia untuk Member EclipseVerse. Silakan beli paket membership di halaman Profil.',
        icon: Icons.lock_rounded,
        action: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.eclipseViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Home'),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return CosmicErrorView(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    // UI redeem card jika sudah member 
    return Column(
      children: [
        // Header Poin 
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.eclipseViolet.withValues(alpha: 0.3), blurRadius: 15)],
          ),
          child: Column(
            children: [
              const Text('Total Poin Kamu', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text('$_userPoints', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7, 
            ),
            itemCount: dummyCards.length,
            itemBuilder: (context, index) {
              final card = dummyCards[index];
              final isOwned = _ownedCardIds.contains(card.id);
              return _buildCardItem(card, isOwned);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(EclipseCard card, bool isOwned) {
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
                  Image.network(
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
                  
                  if (!isOwned) 
                    Container(
                      color: Colors.black.withValues(alpha: 0.65),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: AppTheme.coronaGold, size: 16),
                      const SizedBox(width: 4),
                      Text('${card.cost} Poin', style: const TextStyle(color: AppTheme.coronaGold, fontWeight: FontWeight.bold)),
                    ],
                  ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwned ? AppTheme.surfaceSecondary : AppTheme.eclipseViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isOwned ? null : () => _handleRedeem(card),
                    child: Text(isOwned ? 'Dimiliki' : 'Tukar'),
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