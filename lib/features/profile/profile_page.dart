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
      if (mounted) {
        setState(() {
          _isMember = isActive;
          _membershipData = data;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat status membership: $e');
    }
  }

  Future<void> _checkCardStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('user_cards')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if (mounted) {
        setState(() {
          _hasRedeemedCards = res.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Gagal cek kartu: $e');
    }
  }

  Future<void> _load() async {
    final profile = await LocalDb.getUserProfile();
    final avatar = await LocalDb.getPref('avatar_path');
    String? remoteAvatarUrl;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('avatar_path')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 6));
        final storagePath = row?['avatar_path']?.toString();
        if (storagePath != null && storagePath.isNotEmpty) {
          remoteAvatarUrl = Supabase.instance.client.storage
              .from('eclipseverse-media')
              .getPublicUrl(storagePath);
        }
      } catch (_) {
        // Keep local avatar cache if the network is temporarily unavailable.
      }
    }
    final bio = await LocalDb.getPref('biometric_enabled');
    final notif = await LocalDb.getPref('notification_enabled');
    final supported = await BiometricService.isSupported();
    if (!mounted) return;
    setState(() {
      _name = '${profile?['name'] ?? ''}';
      _email = '${profile?['email'] ?? ''}';
      _avatarPath =
          remoteAvatarUrl ??
          ((avatar != null && avatar.isNotEmpty) ? avatar : null);
      _bioSupported = supported;
      _bioEnabled = supported && bio == '1';
      _notifEnabled = notif == '1';
      _loading = false;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (x == null) return;
      // image_picker returns a temporary/cache path; copy it to app storage
      // so the avatar remains available after Android cleans temporary files.
      final directory = await getDatabasesPath();
      final extension = path.extension(x.path).isEmpty
          ? '.jpg'
          : path.extension(x.path);
      final savedPath = path.join(directory, 'eclipseverse_avatar$extension');
      final savedFile = await File(x.path).copy(savedPath);
      await LocalDb.setPref('avatar_path', savedFile.path);
      var displayedPath = savedFile.path;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final storagePath =
              'avatars/${user.id}/profile${path.extension(savedFile.path)}';
          await Supabase.instance.client.storage
              .from('eclipseverse-media')
              .upload(
                storagePath,
                savedFile,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType:
                      path.extension(savedFile.path).toLowerCase() == '.png'
                      ? 'image/png'
                      : 'image/jpeg',
                ),
              )
              .timeout(const Duration(seconds: 12));
          await Supabase.instance.client
              .from('profiles')
              .update({
                'avatar_path': storagePath,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', user.id)
              .timeout(const Duration(seconds: 8));
          displayedPath = Supabase.instance.client.storage
              .from('eclipseverse-media')
              .getPublicUrl(storagePath);
        } catch (_) {
          // Keep the persistent local copy if Storage is unavailable or the user is offline.
        }
      }
      if (!mounted) return;
      setState(() => _avatarPath = displayedPath);
    } catch (_) {
      if (mounted) showSnack(context, 'Gagal memilih foto');
    }
  }

  Future<void> _toggleBiometric(bool on) async {
    if (on) {
      final ok = await BiometricService.authenticate();
      if (!mounted) return;
      if (!ok) {
        showSnack(context, 'Verifikasi biometric gagal atau dibatalkan');
        return;
      }

      // Ambil email & password dari session Supabase
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {}
    } else {
      // Jika dimatikan, hapus kredensial
      await SecureStore.deleteCredentials();
    }

    await LocalDb.setPref('biometric_enabled', on ? '1' : '0');
    if (mounted) setState(() => _bioEnabled = on);
  }

  Future<void> _toggleNotification(bool on) async {
    if (on) {
      try {
        final granted = await NotificationService.init();
        if (!granted) {
          if (mounted) {
            showSnack(context, 'Izin notifikasi belum diberikan.');
          }
          return;
        }
      } catch (_) {
        if (mounted) {
          showSnack(
            context,
            'Izin notifikasi ditolak. Aktifkan lewat Pengaturan.',
          );
        }
        return;
      }
    }
    await LocalDb.setPref('notification_enabled', on ? '1' : '0');
    if (mounted) setState(() => _notifEnabled = on);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari EclipseVerse?'),
        content: const Text('Sesi akun di perangkat ini akan diakhiri.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.onLogout?.call();
    }
  }

  // Future<void> _testNotification() async {
  //   if (!_notifEnabled) {
  //     showSnack(context, 'Aktifkan notifikasi terlebih dahulu');
  //     return;
  //   }
  //   await NotificationService.showTest();
  //   if (mounted) showSnack(context, 'Notifikasi akan muncul 10 detik lagi');
  // }

  ImageProvider? get _avatarImage {
    final p = _avatarPath;
    if (p == null) return null;
    if (p.startsWith('https://') || p.startsWith('http://')) {
      return NetworkImage(p);
    }
    final f = File(p);
    return f.existsSync() ? FileImage(f) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppTheme.primaryDark,
                        backgroundImage: _avatarImage,
                        child: _avatarImage == null
                            ? Text(
                                _name.isEmpty ? '?' : _name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryLight,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.photo_library, size: 18),
                            tooltip: 'Pilih foto dari galeri',
                            onPressed: _pickPhoto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  _email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Login biometric'),
                        subtitle: Text(
                          _bioSupported
                              ? 'Gunakan sidik jari saat membuka aplikasi'
                              : 'Perangkat tidak mendukung',
                        ),
                        value: _bioEnabled,
                        onChanged: _bioSupported ? _toggleBiometric : null,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Notifikasi'),
                        subtitle: const Text(
                          'Pengingat event dan info pesanan',
                        ),
                        value: _notifEnabled,
                        onChanged: _toggleNotification,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Card(
                  child: Column(
                    children: [
                      // 1. Bagian Membership (Atas)
                      ListTile(
                        leading: Icon(
                          Icons.workspace_premium,
                          color: _isMember
                              ? Colors.amber
                              : AppTheme.primaryLight,
                        ),
                        title: Text(
                          _isMember
                              ? 'VIP Member Aktif'
                              : 'Membership EclipseVerse',
                        ),
                        subtitle: Text(
                          _isMember
                              ? 'Sisa Kuota Redeem: ${_membershipData?['redeem_quota'] ?? 0} Kali'
                              : 'Membership untuk menukar kartu baru',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.pushNamed(context, Routes.membership);
                          _checkMembership();
                          _checkCardStatus();
                        },
                      ),

                      // Bagian koleksi kartu
                      ListTile(
                        leading: Icon(
                          Icons.style,
                          // Kalau udah punya kartu jadi warna emas, kalau belum abu-abu
                          color: _hasRedeemedCards ? Colors.amber : Colors.grey,
                        ),
                        title: Text(
                          'Koleksi Kartu',
                          style: TextStyle(
                            color: _hasRedeemedCards
                                ? AppTheme.textPrimary
                                : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          _hasRedeemedCards
                              ? 'Lihat kartu yang sudah kamu kumpulkan'
                              : 'Jelajahi koleksi photocard';
                          style: TextStyle(
                            color: _hasRedeemedCards
                                ? AppTheme.textSecondary
                                : Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Koleksi kartu yang sudah dimiliki tetap bisa dibuka meskipun membership berakhir.
                          Navigator.pushNamed(context, Routes.redeem);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingMedium),
                // OutlinedButton.icon(
                //   onPressed: _testNotification,
                //   icon: const Icon(Icons.notifications_active),
                //   label: const Text('Uji notifikasi'),
                // ),
                // const SizedBox(height: AppTheme.spacingMedium),
                OutlinedButton.icon(
                  onPressed: widget.onLogout == null ? null : _confirmLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
    );
  }
}
