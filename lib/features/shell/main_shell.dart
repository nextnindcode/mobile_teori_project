import 'package:flutter/material.dart'; 
import 'home_page.dart'; 

// Kerangka utama dari aplikasi EclipseVerse.
// Berisi 5 tab: Home, Fandom Hub, Saran & Kesan, Profil, serta Logout.
// Tab Logout bukan halaman, tetapi untuk memicu dialog + callback onLogout.
class MainShell extends StatefulWidget {
  /// Callback untuk Logout. 
  final VoidCallback? onLogout;

  const MainShell({super.key, this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Placeholder untuk tiap tab. 
  static const List<Widget> _pages = [
    HomePage(), 
    _PlaceholderPage(title: 'Fandom Hub', icon: Icons.people),
    _PlaceholderPage(title: 'Saran & Kesan', icon: Icons.feedback),
    _PlaceholderPage(title: 'Profil', icon: Icons.person),
  ];

  void _onTabTapped(int index) {
    // Tab index 4 = Logout untuk memunculkan dialog, bukan berpindah halaman.
    if (index == 4) {
      _showLogoutDialog();
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apakah Anda Yakin Ingin Keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Panggil callback.
      widget.onLogout?.call();
    }
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
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}

/// Widget placeholder sederhana untuk tiap tab.
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Halaman $title',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('(Placeholder)'),
          ],
        ),
      ),
    );
  }
}