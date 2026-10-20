import 'package:flutter/material.dart';

import '../fandom/fandom_page.dart';
import '../feedback/feedback_page.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';

// Kerangka utama EclipseVerse dengan tab logout yang meminta konfirmasi.
class MainShell extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const MainShell({super.key, this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        const HomePage(),
        const FandomPage(),
        const FeedbackPage(),
        ProfilePage(onLogout: widget.onLogout),
      ];

  Future<void> _confirmLogout() async {
    if (widget.onLogout == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.nightlight_round),
        title: const Text('Keluar dari EclipseVerse?'),
        content: const Text('Kamu perlu login kembali untuk mengakses akun.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.onLogout!.call();
    }
  }

  void _onTabTapped(int index) {
    // Logout adalah aksi, bukan halaman; indeks aktif tetap pada tab sebelumnya.
    if (index == 4) {
      _confirmLogout();
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Fandom'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), activeIcon: Icon(Icons.forum), label: 'Saran'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
