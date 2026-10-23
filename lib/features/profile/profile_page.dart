import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:eclipseverse/theme/app_theme.dart';
import 'package:eclipseverse/core/local_db.dart';

import '../notification/notification_service.dart';
import '../fandom/shared/state_views.dart';
import 'biometric_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await LocalDb.getUserProfile();
    final avatar = await LocalDb.getPref('avatar_path');
    final bio = await LocalDb.getPref('biometric_enabled');
    final notif = await LocalDb.getPref('notification_enabled');
    final supported = await BiometricService.isSupported();
    if (!mounted) return;
    setState(() {
      _name = '${profile?['name'] ?? ''}';
      _email = '${profile?['email'] ?? ''}';
      _avatarPath = (avatar != null && avatar.isNotEmpty) ? avatar : null;
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
      final extension = path.extension(x.path).isEmpty ? '.jpg' : path.extension(x.path);
      final savedPath = path.join(directory, 'eclipseverse_avatar$extension');
      final savedFile = await File(x.path).copy(savedPath);
      await LocalDb.setPref('avatar_path', savedFile.path);
      if (!mounted) return;
      setState(() => _avatarPath = savedFile.path);
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

  Future<void> _testNotification() async {
    if (!_notifEnabled) {
      showSnack(context, 'Aktifkan notifikasi terlebih dahulu');
      return;
    }
    await NotificationService.showTest();
    if (mounted) showSnack(context, 'Notifikasi akan muncul 10 detik lagi');
  }

  ImageProvider? get _avatarImage {
    final p = _avatarPath;
    if (p == null) return null;
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
                const SizedBox(height: AppTheme.spacingLarge),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Login biometric'),
                        subtitle: Text(
                          _bioSupported
                              ? 'Gunakan sidik jari/wajah saat membuka aplikasi'
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
                OutlinedButton.icon(
                  onPressed: _testNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Uji notifikasi'),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
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
