import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'eclipse_card_model.dart';
import 'redeem_service.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  bool _isLoading = true;
  String? _errorMessage;
  int _userPoints = 0;
  List<int> _ownedCardIds = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mengambil poin dan kartu dari API backend 
      final data = await RedeemService.getUserStats();
      setState(() {
        _userPoints = data['points'] ?? 0;
        // Konversi list dari API ke List<int> 
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

  Future<void> _verifyBlockchain() async {
    try {
      final result = await RedeemService.verifyBlockchain();
      if (!mounted) return;
      final valid = result['valid'] == true;
      final count = result['block_count'] ?? 0;
      final invalidId = result['invalid_block_id'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            valid
                ? 'Blockchain valid: $count blok terverifikasi.'
                : 'Verifikasi gagal pada blok $invalidId.',
          ),
          backgroundColor: valid ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memverifikasi blockchain: $e')),
      );
    }
  }

  Future<void> _handleRedeem(EclipseCard card) async {
    // Cek poin terlebih dahulu 
    if (_userPoints < card.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin kamu tidak cukup!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Tampilkan dialog konfirmasi 
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
      // Panggil API untuk memproses redeem kartu 
      await RedeemService.redeemCard(card.id, card.cost);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil mendapatkan ${card.name}!'), backgroundColor: Colors.green),
        );
        _fetchData(); // Refresh data poin dan kartu 
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Redeem Card'),
        actions: [
          IconButton(
            onPressed: _verifyBlockchain,
            tooltip: 'Verifikasi blockchain',
            icon: const Icon(Icons.verified_outlined),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryDark));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Gagal memuat data\n$_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: 200, 
                child: ElevatedButton(
                  style: AppTheme.primaryButtonStyle,
                  onPressed: _fetchData,
                  child: const Text('Coba Lagi'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header Poin User 
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.3), 
                blurRadius: 10, 
                offset: const Offset(0, 5)
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Total Poin Kamu', 
                style: TextStyle(color: Colors.white70, fontSize: 16)
              ),
              const SizedBox(height: 8),
              Text(
                '$_userPoints',
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 48, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
        
        // Grid Kartu Member 
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 5)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bagian Gambar Kartu 
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar dari URL 
                  Image.network(
                    card.imageUrl,
                    fit: BoxFit.cover, 
                    
                    // Tampilan jika gambar sedang loading 
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.greyLight,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark),
                        ),
                      );
                    },

                    // Tampilan jika link gambar mati/error 
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.greyLight,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: AppTheme.grey, size: 40),
                        ),
                      );
                    },
                  ),
                  
                  // Jika kartu belum dimiliki: Efek Gelap + Gembok
                  if (!isOwned) 
                    Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white, size: 50),
                      ),
                    ),
                  
                  // Jika kartu sudah dimiliki: Label "OWNED"
                  if (isOwned)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OWNED',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bagian Detail dan Tombol
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  card.name,
                  style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (isOwned)
                  const Text(
                    'Sudah Dimiliki', 
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${card.cost} Poin', 
                        style: TextStyle(
                          color: AppTheme.primaryDark, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                
                // Tombol Tukar 
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
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