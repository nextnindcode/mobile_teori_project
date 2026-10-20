import 'package:flutter/material.dart';

import '../fandom/fandom_page.dart';
import '../feedback/feedback_page.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';

// Kerangka utama dari aplikasi EclipseVerse.
// Berisi 4 tab. Logout tersedia di halaman Profil, bukan tab navigasi.
class MainShell extends StatefulWidget {
  /// Callback untuk Logout.
  final Future<void> Function()? onLogout;

  const MainShell({super.key, this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Tab 0 = Home, 1 = Fandom, 2 = Saran & Kesan, 3 = Profil.
  List<Widget> get _pages => [
        const HomePage(),
        const FandomPage(),
        const FeedbackPage(),
        ProfilePage(onLogout: widget.onLogout),
      ];

  void _onTabTapped(int index) {
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Fandom'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Saran'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
