import 'package:flutter/material.dart';

import '../../core/auth_service.dart';
import '../../core/routes.dart';
import '../../core/session_timeout_service.dart';
import '../fandom/fandom_page.dart';
import '../feedback/feedback_page.dart';
import '../profile/profile_page.dart';
import '../tools/observatory_page.dart';
import 'home_page.dart';

// Kerangka utama EclipseVerse; tombol keluar tersedia di halaman Profil.
class MainShell extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const MainShell({super.key, this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Key _homeKey = UniqueKey();
  bool _checkingTimeout = false;

  List<Widget> get _pages => [
        HomePage(key: _homeKey),
        const FandomPage(),
        const ObservatoryPage(),
        const FeedbackPage(),
        ProfilePage(onLogout: widget.onLogout),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      SessionTimeoutService.markBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      _checkSessionTimeout();
    }
  }

  Future<void> _checkSessionTimeout() async {
    if (_checkingTimeout) return;
    _checkingTimeout = true;
    try {
      final expired = await SessionTimeoutService.hasExpired();
      await SessionTimeoutService.clearBackgroundTime();
      if (!expired || !mounted) return;

      try {
        await AuthService.logout();
      } catch (e) {
        debugPrint('Logout after session timeout failed: $e');
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.login,
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesi berakhir setelah aplikasi tidak aktif selama 4 hari. Silakan login lagi.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Session timeout check failed: $e');
    } finally {
      _checkingTimeout = false;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      if (index == 0 && _currentIndex != 0) {
        _homeKey = UniqueKey();
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(_pages.length, (index) {
          return IgnorePointer(
            ignoring: _currentIndex != index,
            child: AnimatedOpacity(
              opacity: _currentIndex == index ? 1 : 0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              child: _pages[index],
            ),
          );
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Member',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nightlight_outlined),
            activeIcon: Icon(Icons.nightlight_round),
            label: 'Observatory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Saran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
