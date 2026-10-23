import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Inbox Notifikasi')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryDark));
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Gagal memuat notifikasi\n$_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: 200, 
              child: ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: _fetchNotifications, 
                child: const Text('Coba Lagi')
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text('Belum ada notifikasi.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final isOrder = notif['type'] == 'order';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOrder ? Colors.green.withValues(alpha: 0.2) : AppTheme.primaryLight.withValues(alpha: 0.2),
              child: Icon(
                isOrder ? Icons.shopping_bag : Icons.notifications,
                color: isOrder ? Colors.green : AppTheme.primaryDark,
              ),
            ),
            title: Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(notif['message']),
          ),
        );
      },
    );
  }
}