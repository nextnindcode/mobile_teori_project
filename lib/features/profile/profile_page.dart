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
import '../nearby/location_service.dart';

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
  bool _hasMembershipHistory = false;
  String _locationText = 'Belum diperbarui';
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkMembership();
    _checkMembershipHistory();
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

  Future<void> _checkMembershipHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('user_memberships')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if (mounted) setState(() => _hasMembershipHistory = rows.isNotEmpty);
    } catch (e) {
      debugPrint('Gagal cek riwayat membership: $e');
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

  Future<void> _refreshLocation() async {
    setState(() => _locationLoading = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (!mounted || position == null) return;
      setState(() {
        _locationText =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    final cachedUserId = user?.id ?? await LocalDb.getPref('active_user_id');
    final profile = cachedUserId == null || cachedUserId.isEmpty
        ? null
        : await LocalDb.getUserProfile(cachedUserId);
    final avatar = cachedUserId == null || cachedUserId.isEmpty
        ? null
        : await LocalDb.getPref('avatar_path_${cachedUserId}');
    String? remoteAvatarUrl;
    Map<String, dynamic>? remoteProfile;
    if (user != null) {
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('display_name, email, avatar_path')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 6));
        remoteProfile = row == null ? null : Map<String, dynamic>.from(row);
        final storagePath = row?['avatar_path']?.toString();
        if (storagePath != null && storagePath.isNotEmpty) {
          remoteAvatarUrl = Supabase.instance.client.storage
              .from('eclipseverse-media')
              .getPublicUrl(storagePath);
        }
      } catch (_) {
        // Gunakan cache avatar lokal jika jaringan sedang tidak tersedia.
      }
    }
    final bio = await LocalDb.getPref('biometric_enabled');
    final notif = await LocalDb.getPref('notification_enabled');
    final supported = await BiometricService.isSupported();
    if (!mounted) return;
    setState(() {
      _name = '${remoteProfile?['display_name'] ?? profile?['name'] ?? ''}';
      _email = '${user?.email ?? remoteProfile?['email'] ?? profile?['email'] ?? ''}';
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
      final directory = await getDatabasesPath();
      final extension = path.extension(x.path).isEmpty
          ? '.jpg'
          : path.extension(x.path);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) showSnack(context, 'Silakan login kembali untuk mengubah foto profil.');
        return;
      }
      final savedPath = path.join(directory, 'eclipseverse_avatar_${user.id}$extension');
      final savedFile = await File(x.path).copy(savedPath);
      await LocalDb.setPref('avatar_path_${user.id}', savedFile.path);
      var displayedPath = savedFile.path;
      try {
          final storagePath = 'avatars/${user.id}/profile${path.extension(savedFile.path)}';
          await Supabase.instance.client.storage
              .from('eclipseverse-media')
              .upload(storagePath, savedFile, fileOptions: FileOptions(
                upsert: true,
                contentType: path.extension(savedFile.path).toLowerCase() == '.png' ? 'image/png' : 'image/jpeg',
              ))
              .timeout(const Duration(seconds: 12));
          await Supabase.instance.client
              .from('profiles')
              .update({'avatar_path': storagePath, 'updated_at': DateTime.now().toUtc().toIso8601String()})
              .eq('id', user.id)
              .timeout(const Duration(seconds: 8));
          displayedPath = Supabase.instance.client.storage.from('eclipseverse-media').getPublicUrl(storagePath);
      } catch (_) {
        // Pertahankan salinan lokal khusus akun jika penyimpanan daring tidak tersedia.
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
      if (!ok) { showSnack(context, 'Verifikasi biometric gagal atau dibatalkan'); return; }
      final user = Supabase.instance.client.auth.currentUser;
      final email = user?.email?.trim() ?? '';
      if (email.isEmpty) { showSnack(context, 'Email akun tidak tersedia. Login kembali terlebih dahulu.'); return; }
      final passwordController = TextEditingController();
      final password = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppTheme.surfaceElevated, title: const Text('Aktifkan login biometrik'), content: TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Masukkan password akun saat ini')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(ctx, passwordController.text), child: const Text('Verifikasi'))]));
      passwordController.dispose();
      if (password == null) return;
      if (password.trim().isEmpty) { if (mounted) showSnack(context, 'Password tidak boleh kosong.'); return; }
      try {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
        await SecureStore.saveCredentials(email, password);
        await LocalDb.setPref('biometric_enabled', '1');
        if (mounted) setState(() => _bioEnabled = true);
        if (mounted) showSnack(context, 'Login biometrik berhasil diaktifkan.');
      } on AuthException catch (e) { if (mounted) showSnack(context, 'Verifikasi akun gagal: ${e.message}'); }
      catch (_) { if (mounted) showSnack(context, 'Gagal mengaktifkan login biometrik.'); }
    } else {
      await SecureStore.deleteCredentials();
      await LocalDb.setPref('biometric_enabled', '0');
      if (mounted) setState(() => _bioEnabled = false);
    }
  }

  Future<void> _toggleNotification(bool on) async {
    if (on) {
      try {
        final granted = await NotificationService.init();
        if (!granted) { if (mounted) showSnack(context, 'Izin notifikasi belum diberikan.'); return; }
      } catch (_) {
        if (mounted) showSnack(context, 'Izin notifikasi ditolak. Aktifkan lewat Pengaturan.');
        return;
      }
    } else {
      // Saat notifikasi dinonaktifkan, batalkan pengingat acara yang sudah dijadwalkan.
      try {
        final rows = await Supabase.instance.client
            .from('events')
            .select('id')
            .eq('status', 'scheduled');
        for (final row in rows) {
          final id = (row['id'] as num?)?.toInt();
          if (id != null) await NotificationService.cancelEventReminder(id);
        }
      } catch (e) {
        debugPrint('Gagal membatalkan reminder event: $e');
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
      body: _loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(radius: 56, backgroundColor: AppTheme.primaryDark, backgroundImage: _avatarImage, child: _avatarImage == null ? Text(_name.isEmpty ? '?' : _name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)) : null),
                      Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 18, backgroundColor: AppTheme.primaryLight, child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.photo_library, size: 18), tooltip: 'Pilih foto dari galeri', onPressed: _pickPhoto))),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(_name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                Text(_email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppTheme.spacingMedium),
                Card(child: Column(children: [
                  const Divider(height: 1),
                  const Divider(height: 1),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Lokasi perangkat'), subtitle: Text(_locationText), trailing: _locationLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location), onTap: _locationLoading ? null : _refreshLocation),
                ])),
                const SizedBox(height: AppTheme.spacingMedium),
                Card(child: Column(children: [
                  SwitchListTile(title: const Text('Login dengan sidik jari'), subtitle: Text(_bioSupported ? 'Gunakan sidik jari saat membuka aplikasi' : 'Perangkat tidak mendukung'), value: _bioEnabled, onChanged: _bioSupported ? _toggleBiometric : null),
                  const Divider(height: 1),
                  SwitchListTile(title: const Text('Notifikasi'), subtitle: const Text('Pengingat event dan info pesanan'), value: _notifEnabled, onChanged: _toggleNotification),
                ])),
                const SizedBox(height: AppTheme.spacingMedium),
                Card(child: Column(children: [
                  ListTile(leading: Icon(Icons.workspace_premium, color: _isMember ? Colors.amber : AppTheme.primaryLight), title: Text(_isMember ? 'VIP Member Aktif' : 'Membership EclipseVerse'), subtitle: Text(_isMember ? 'Sisa Kuota Redeem: ${_membershipData?['redeem_quota'] ?? 0} Kali' : 'Akses fitur redeem kartu'), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.pushNamed(context, Routes.membership); _checkMembership(); _checkCardStatus(); }),
                  ListTile(leading: Icon(Icons.style, color: _hasRedeemedCards ? Colors.amber : Colors.grey), title: Text('Koleksi Kartu', style: TextStyle(color: _hasRedeemedCards ? AppTheme.textPrimary : Colors.grey)), subtitle: Text(_hasRedeemedCards ? 'Lihat kartu yang sudah kamu kumpulkan' : 'Belum ada kartu yang diklaim', style: TextStyle(color: _hasRedeemedCards ? AppTheme.textSecondary : Colors.grey)), trailing: const Icon(Icons.chevron_right), onTap: () { if (_hasMembershipHistory || _hasRedeemedCards || _isMember) { Navigator.pushNamed(context, Routes.redeem); } else { Navigator.pushNamed(context, Routes.membership); } }),
                ])),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingMedium),
                OutlinedButton.icon(onPressed: widget.onLogout == null ? null : _confirmLogout, icon: const Icon(Icons.logout), label: const Text('Logout')),
              ],
            ),
    );
  }
}
