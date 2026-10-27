import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart'; 

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Silakan login kembali.');
      
      // Mengambil data notifikasi khusus untuk user ini, diurutkan dari yang terbaru 
      final rows = await client.from('notifications')
          .select('id,title,message,type,is_read,created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 8));
          
      if (!mounted) return;
      setState(() {
        _notifications = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk merapikan format tanggal (misal: "25 Okt 2026, 15:30")
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr)?.toLocal();
    if (date == null) return '';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Inbox Notifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CosmicLoading(message: 'Memuat pesan...');
    }
    
    if (_errorMessage != null) {
      return CosmicErrorView(
        message: _errorMessage!,
        onRetry: _fetchNotifications,
      );
    }

    if (_notifications.isEmpty) {
      return const CosmicEmptyView(
        title: 'Inbox Kosong',
        subtitle: 'Belum ada pesan atau notifikasi untukmu saat ini.',
        icon: Icons.mark_email_read_outlined,
      );
    }

    // Bungkus dengan RefreshIndicator agar bisa ditarik ke bawah untuk refresh
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: AppTheme.coolCyan,
      backgroundColor: AppTheme.surfaceElevated,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final isOrder = notif['type'] == 'order';
          // 2. Logika UI untuk Titik Biru
          final isRead = notif['is_read'] == true || notif['is_read'] == 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CosmicCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ikon berdasarkan tipe notifikasi
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOrder 
                          ? AppTheme.coronaGold.withValues(alpha: 0.2) 
                          : AppTheme.coolCyan.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOrder ? Icons.shopping_bag_rounded : Icons.campaign_rounded,
                      color: isOrder ? AppTheme.coronaGold : AppTheme.coolCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Teks Notifikasi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif['title'] ?? 'Notifikasi',
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            // Titik biru jika belum dibaca
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.coolCyan,
                                  shape: BoxShape.circle,
                                ),
                              )
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif['message'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(notif['created_at']?.toString()),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}