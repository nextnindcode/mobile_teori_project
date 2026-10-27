import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:eclipseverse/theme/app_theme.dart';
import 'package:eclipseverse/core/local_db.dart';
import '../notification/notification_service.dart';
import '../fandom/shared/state_views.dart';
import 'biometric_service.dart';
import '../../core/routes.dart';
import '../../core/secure_store.dart';
import '../membership/membership_service.dart';

class ProfilePage extends StatefulWidget {
  final Future<void> Function()? onLogout;
  const ProfilePage({super.key, this.onLogout});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String? _avatarPath;
  bool _bioSupported = false;
  bool _bioEnabled = false;
  bool _notifEnabled = false;
  bool _loading = true;
  bool _isMember = false;
  Map<String, dynamic>? _membershipData;
  bool _hasRedeemedCards = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkMembership();
    _checkCardStatus();
  }

  Future<void> _checkMembership() async {
    try {
      final isActive = await MembershipService.isActive();
      final data = await MembershipService.currentMembership();
      if (mounted) setState(() { _isMember = isActive; _membershipData = data; });
    } catch (e) { debugPrint('Gagal memuat status membership: $e'); }
  }

  Future<void> _checkCardStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client.from('user_cards').select('id').eq('user_id', user.id).limit(1);
      if (mounted) setState(() => _hasRedeemedCards = res.isNotEmpty);
    } catch (e) { debugPrint('Gagal cek kartu: $e'); }
  }

  Future<void> _load() async {
    final profile = await LocalDb.getUserProfile();
    final avatar = await LocalDb.getPref('avatar_path');
    String? remoteAvatarUrl;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final row = await Supabase.instance.client.from('profiles').select('avatar_path').eq('id', user.id).maybeSingle().timeout(const Duration(seconds: 6));
        final storagePath = row?['avatar_path']?.toString();
        if (storagePath != null && storagePath.isNotEmpty) remoteAvatarUrl = Supabase.instance.client.storage.from('eclipseverse-media').getPublicUrl(storagePath);
      } catch (_) {}
    }
    final bio = await LocalDb.getPref('biometric_enabled');
    final notif = await LocalDb.getPref('notification_enabled');
    final supported = await BiometricService.isSupported();
    if (!mounted) return;
    setState(() {
      _name = '${profile?['name'] ?? ''}';
      _email = '${profile?['email'] ?? ''}';
      _avatarPath = remoteAvatarUrl ?? ((avatar != null && avatar.isNotEmpty) ? avatar : null);
      _bioSupported = supported;
      _bioEnabled = supported && bio == '1';
      _notifEnabled = notif == '1';
      _loading = false;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (x == null) return;
      final directory = await getDatabasesPath();
      final extension = path.extension(x.path).isEmpty ? '.jpg' : path.extension(x.path);
      final savedPath = path.join(directory, 'eclipseverse_avatar$extension');
      final savedFile = await File(x.path).copy(savedPath);
      await LocalDb.setPref('avatar_path', savedFile.path);
      var displayedPath = savedFile.path;
      if (user != null) {
        try {
          final storagePath = 'avatars/${user.id}/profile$extension';
          await Supabase.instance.client.storage.from('eclipseverse-media').upload(storagePath, savedFile, fileOptions: FileOptions(upsert: true, contentType: extension.toLowerCase() == '.png' ? 'image/png' : 'image/jpeg')).timeout(const Duration(seconds: 12));
          await Supabase.instance.client.from('profiles').update({'avatar_path': storagePath, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', user.id).timeout(const Duration(seconds: 8));
          displayedPath = Supabase.instance.client.storage.from('eclipseverse-media').getPublicUrl(storagePath);
        } catch (_) {}
      }
      if (mounted) setState(() => _avatarPath = displayedPath);
    } catch (_) { if (mounted) showSnack(context, 'Gagal memilih foto'); }
  }

  Future<void> _toggleBiometric(bool on) async {
    if (on) {
      final ok = await BiometricService.authenticate();
      if (!mounted) return;
      if (!ok) { showSnack(context, 'Verifikasi biometric gagal atau dibatalkan'); return; }
    } else { await SecureStore.deleteCredentials(); }
    await LocalDb.setPref('biometric_enabled', on ? '1' : '0');
    if (mounted) setState(() => _bioEnabled = on);
  }

  Future<void> _toggleNotification(bool on) async {
    await LocalDb.setPref('notification_enabled', on ? '1' : '0');
    if (!on) await NotificationService.cancelAll();
    if (on) {
      try {
        final granted = await NotificationService.init();
        if (!granted) {
          await LocalDb.setPref('notification_enabled', '0');
          if (mounted) showSnack(context, 'Izin notifikasi belum diberikan.');
          return;
        }
      } catch (_) {
        await LocalDb.setPref('notification_enabled', '0');
        if (mounted) showSnack(context, 'Izin notifikasi ditolak. Aktifkan lewat Pengaturan.');
        return;
      }
    }
    if (mounted) setState(() => _notifEnabled = on);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari EclipseVerse?'),
        content: const Text('Sesi akun di perangkat ini akan diakhiri.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed == true && mounted) await widget.onLogout?.call();
  }

  ImageProvider? get _avatarImage {
    final p = _avatarPath;
    if (p == null) return null;
    if (p.startsWith('https://') || p.startsWith('http://')) return NetworkImage(p);
    final f = File(p);
    return f.existsSync() ? FileImage(f) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading ? const LoadingView() : ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        children: [
          Center(child: Stack(children: [
            CircleAvatar(radius: 56, backgroundColor: AppTheme.primaryDark, backgroundImage: _avatarImage, child: _avatarImage == null ? Text(_name.isEmpty ? '?' : _name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)) : null),
            Positioned(right: 0, bottom: 0, child: CircleAvatar(backgroundColor: AppTheme.primaryLight, child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.photo_library, size: 18), onPressed: _pickPhoto))),
          ])),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(_name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          Text(_email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppTheme.spacingMedium),
          Card(child: Column(children: [
            SwitchListTile(title: const Text('Login biometric'), subtitle: Text(_bioSupported ? 'Gunakan sidik jari saat membuka aplikasi' : 'Perangkat tidak mendukung'), value: _bioEnabled, onChanged: _bioSupported ? _toggleBiometric : null),
            const Divider(height: 1),
            SwitchListTile(title: const Text('Notifikasi'), subtitle: const Text('Pengingat event dan info pesanan'), value: _notifEnabled, onChanged: _toggleNotification),
          ])),
          const SizedBox(height: AppTheme.spacingMedium),
          Card(child: Column(children: [
            ListTile(leading: Icon(Icons.workspace_premium, color: _isMember ? Colors.amber : AppTheme.primaryLight), title: Text(_isMember ? 'VIP Member Aktif' : 'Membership EclipseVerse'), subtitle: Text(_isMember ? 'Sisa Kuota Redeem: ${_membershipData?['redeem_quota'] ?? 0} Kali' : 'Akses fitur redeem kartu'), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.pushNamed(context, Routes.membership); _checkMembership(); _checkCardStatus(); }),
            ListTile(leading: Icon(Icons.style, color: _hasRedeemedCards ? Colors.amber : Colors.grey), title: Text('Koleksi Kartu', style: TextStyle(color: _hasRedeemedCards ? AppTheme.textPrimary : Colors.grey)), subtitle: Text(_hasRedeemedCards ? 'Lihat kartu yang sudah kamu kumpulkan' : 'Belum ada kartu yang diklaim', style: TextStyle(color: _hasRedeemedCards ? AppTheme.textSecondary : Colors.grey)), trailing: const Icon(Icons.chevron_right), onTap: () { if (_hasRedeemedCards || _isMember) { Navigator.pushNamed(context, Routes.redeem); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamu harus jadi Member dan redeem kartu terlebih dahulu!'), backgroundColor: Colors.red)); Navigator.pushNamed(context, Routes.membership); } }),
          ])),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingMedium),
          OutlinedButton.icon(onPressed: widget.onLogout == null ? null : _confirmLogout, icon: const Icon(Icons.logout), label: const Text('Logout')),
        ],
      ),
    );
  }
}
