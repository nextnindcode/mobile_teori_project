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
      if (mounted) setState(() { _isMember = isActive; _membershipData = data; });
    } catch (e) { debugPrint('Gagal memuat status membership: $e'); }
  }

  Future<void> _checkMembershipHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await Supabase.instance.client.from('user_memberships').select('id').eq('user_id', user.id).limit(1);
      if (mounted) setState(() => _hasMembershipHistory = rows.isNotEmpty);
    } catch (e) { debugPrint('Gagal cek riwayat membership: $e'); }
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
    final user = Supabase.instance.client.auth.currentUser;
    final profile = user == null ? null : await LocalDb.getUserProfile(user.id);
    final avatar = user == null ? null : await LocalDb.getPref('avatar_path_${user.id}');
    String? remoteAvatarUrl;
    Map<String, dynamic>? remoteProfile;
    if (user != null) {
      try {
        final row = await Supabase.instance.client.from('profiles').select('display_name, email, avatar_path').eq('id', user.id).maybeSingle().timeout(const Duration(seconds: 6));
        remoteProfile = row == null ? null : Map<String, dynamic>.from(row);
        final storagePath = row?['avatar_path']?.toString();
        if (storagePath != null && storagePath.isNotEmpty) {
          remoteAvatarUrl = Supabase.instance.client.storage.from('eclipseverse-media').getPublicUrl(storagePath);
        }
      } catch (_) {}
    }
    final bio = await LocalDb.getPref('biometric_enabled');
    final notif = await LocalDb.getPref('notification_enabled');
    final supported = await BiometricService.isSupported();
    if (!mounted) return;
    setState(() {
      _name = '${remoteProfile?['display_name'] ?? profile?['name'] ?? ''}';
      _email = '${user?.email ?? remoteProfile?['email'] ?? profile?['email'] ?? ''}';
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) { if (mounted) showSnack(context, 'Silakan login kembali untuk mengubah foto profil.'); return; }
      final savedPath = path.join(directory, 'eclipseverse_avatar_${user.id}$extension');
      final savedFile = await File(x.path).copy(savedPath);
      await LocalDb.setPref('avatar_path_${user.id}', savedFile.path);
      var displayedPath = savedFile.path;
      try {
        final storagePath = 'avatars/${user.id}/profile${path.extension(savedFile.path)}';
        await Supabase.instance.client.storage.from('eclipseverse-media').upload(storagePath, savedFile, fileOptions: FileOptions(upsert: true, contentType: path.extension(savedFile.path).toLowerCase() == '.png' ? 'image/png' : 'image/jpeg')).timeout(const Duration(seconds: 12));
        await Supabase.instance.client.from('profiles').update({'avatar_path': storagePath, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', user.id).timeout(const Duration(seconds: 8));
        displayedPath = Supabase.instance.client.storage.from('eclipseverse-media').getPublicUrl(storagePath);
      } catch (_) {}
      if (!mounted) return;
      setState(() => _avatarPath = displayedPath);
    } catch (_) { if (mounted) showSnack(context, 'Gagal memilih foto'); }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Ubah nama akun'),
        content: TextField(controller: controller, maxLength: 60, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama akun')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (nextName == null || nextName.trim().isEmpty || nextName == _name) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { if (mounted) showSnack(context, 'Silakan login kembali.'); return; }
    try {
      await Supabase.instance.client.from('profiles').update({'display_name': nextName, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', user.id).timeout(const Duration(seconds: 8));
      await LocalDb.saveProfile(userId: user.id, name: nextName, email: _email);
      if (!mounted) return;
      setState(() => _name = nextName);
      showSnack(context, 'Nama akun berhasil diperbarui.');
    } catch (e) {
      if (mounted) showSnack(context, 'Nama akun belum dapat diperbarui. Pastikan profil akun sudah memiliki kolom nama dan coba lagi.');
      debugPrint('Update profile name failed: $e');
    }
  }

  Future<void> _editEmail() async {
    final controller = TextEditingController(text: _email);
    final nextEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah email'),
        content: TextField(controller: controller, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email baru')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Kirim konfirmasi'))],
      ),
    );
    controller.dispose();
    if (nextEmail == null || nextEmail.isEmpty || nextEmail == _email) return;
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(email: nextEmail));
      if (!mounted) return;
      showSnack(context, 'Permintaan perubahan email dikirim. Periksa email untuk konfirmasi.');
    } on AuthException catch (e) { if (mounted) showSnack(context, 'Email belum dapat diubah: ${e.message}'); }
    catch (_) { if (mounted) showSnack(context, 'Gagal mengirim permintaan perubahan email.'); }
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    final values = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: const Text('Ubah password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: passwordController, obscureText: obscurePassword, decoration: InputDecoration(labelText: 'Password baru (min. 6 karakter)', suffixIcon: IconButton(onPressed: () => setDialogState(() => obscurePassword = !obscurePassword), icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off)))),
            const SizedBox(height: 12),
            TextField(controller: confirmController, obscureText: obscureConfirm, decoration: InputDecoration(labelText: 'Konfirmasi password baru', suffixIcon: IconButton(onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm), icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off)))),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(ctx, [passwordController.text, confirmController.text]), child: const Text('Simpan password'))],
        ),
      ),
    );
    passwordController.dispose();
    confirmController.dispose();
    if (values == null) return;
    final nextPassword = values[0];
    final confirmPassword = values[1];
    if (nextPassword.trim().isEmpty || confirmPassword.trim().isEmpty) { if (mounted) showSnack(context, 'Password dan konfirmasi tidak boleh kosong.'); return; }
    if (nextPassword.length < 6) { if (mounted) showSnack(context, 'Password minimal 6 karakter.'); return; }
    if (nextPassword != confirmPassword) { if (mounted) showSnack(context, 'Konfirmasi password tidak cocok.'); return; }
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: nextPassword));
      final user = Supabase.instance.client.auth.currentUser;
      if (_bioEnabled && user?.email != null) {
        try { await SecureStore.saveCredentials(user!.email!, nextPassword); } catch (_) {}
      }
      if (mounted) showSnack(context, 'Password berhasil diperbarui.');
    } on AuthException catch (e) { if (mounted) showSnack(context, 'Password belum dapat diubah: ${e.message}'); }
    catch (_) { if (mounted) showSnack(context, 'Gagal memperbarui password.'); }
  }

  Future<void> _refreshLocation() async {
    setState(() => _locationLoading = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (!mounted || position == null) return;
      setState(() => _locationText = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}');
    } catch (e) { if (mounted) showSnack(context, e.toString().replaceAll('Exception: ', '')); }
    finally { if (mounted) setState(() => _locationLoading = false); }
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
      if (password == null || password.trim().isEmpty) { if (mounted) showSnack(context, 'Password tidak boleh kosong.'); return; }
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
      } catch (_) { if (mounted) showSnack(context, 'Izin notifikasi ditolak. Aktifkan lewat Pengaturan.'); return; }
    } else {
      // Hentikan reminder event yang sudah terjadwal ketika pengguna mematikan toggle.
      try {
        final rows = await Supabase.instance.client.from('events').select('id').eq('status', 'scheduled');
        for (final row in rows) {
          final id = (row['id'] as num?)?.toInt();
          if (id != null) await NotificationService.cancelEventReminder(id);
        }
      } catch (e) { debugPrint('Gagal membatalkan reminder event: $e'); }
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
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Logout'))],
      ),
    );
    if (confirmed == true && mounted) await widget.onLogout?.call();
  }

  ImageProvider? get _avatarImage {
    final p = _avatarPath;
    if (p == null) return null;
    if (p.startsWith('https://') || p.startsWith('http://')) return NetworkImage(p);
    return FileImage(File(p));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(title: const Text('Profil EclipseVerse')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CosmicCard(child: Row(children: [CircleAvatar(radius: 34, backgroundImage: _avatarImage, child: _avatarImage == null ? const Icon(Icons.person, size: 34) : null), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_name.isEmpty ? 'Eclipse Lover' : _name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(_email, style: const TextStyle(color: AppTheme.textSecondary))])), IconButton(onPressed: _pickPhoto, icon: const Icon(Icons.edit_rounded))])),
          const SizedBox(height: 16),
          Card(color: AppTheme.surfaceElevated, child: Column(children: [ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Nama akun'), subtitle: Text(_name.isEmpty ? 'Belum diatur' : _name), trailing: const Icon(Icons.chevron_right), onTap: _editName), ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(_email), trailing: const Icon(Icons.chevron_right), onTap: _editEmail), ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Password'), subtitle: const Text('Ubah password akun'), trailing: const Icon(Icons.chevron_right), onTap: _changePassword)])),
          const SizedBox(height: 12),
          Card(color: AppTheme.surfaceElevated, child: Column(children: [if (_bioSupported) SwitchListTile(value: _bioEnabled, onChanged: _toggleBiometric, title: const Text('Login biometrik'), subtitle: const Text('Gunakan sidik jari atau face unlock')), SwitchListTile(value: _notifEnabled, onChanged: _toggleNotification, title: const Text('Notifikasi event'), subtitle: const Text('Pengingat event yang kamu jadwalkan')), ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Lokasi saat ini'), subtitle: Text(_locationText), trailing: _locationLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh), onTap: _locationLoading ? null : _refreshLocation)])),
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: _confirmLogout, icon: const Icon(Icons.logout), label: const Text('Logout')),
        ],
      ),
    );
  }
}
