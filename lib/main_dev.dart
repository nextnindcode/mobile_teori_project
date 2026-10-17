// FILE UJI LOKAL MILIK B. Jangan ganti main.dart (milik A).
// Jalankan: flutter run -t lib/main_dev.dart   (di HP/emulator Android)
import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';
import 'package:eclipseverse/core/secure_store.dart';
import 'package:eclipseverse/core/local_db.dart';
import 'package:eclipseverse/features/fandom/fandom_page.dart';
import 'package:eclipseverse/features/fandom/member_detail_page.dart';
import 'package:eclipseverse/features/event/event_page.dart';
import 'package:eclipseverse/features/event/event_detail_page.dart';
import 'package:eclipseverse/features/tools/tools_page.dart';
import 'package:eclipseverse/features/feedback/feedback_page.dart';
import 'package:eclipseverse/features/profile/profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStore.saveToken('DEV-TOKEN-ECLIPSE');
  await LocalDb.saveProfile(
    userId: 1,
    name: 'User Uji',
    email: 'uji@eclipseverse.test',
  );
  runApp(const DevApp());
}

class DevApp extends StatelessWidget {
  const DevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EclipseVerse (dev B)',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/events': (_) => const EventListPage(),
        '/event-detail': (_) => const EventDetailPage(),
        '/member-detail': (_) => const MemberDetailPage(),
        '/tools': (_) => const ToolsPage(),
      },
      home: const _DevMenu(),
    );
  }
}

class _DevMenu extends StatelessWidget {
  const _DevMenu();

  @override
  Widget build(BuildContext context) {
    Widget item(String title, IconData icon, Widget page) => Card(
          child: ListTile(
            leading: Icon(icon, color: AppTheme.primaryDark),
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Menu Uji Modul B')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        children: [
          item('Fandom (13 member)', Icons.people, const FandomPage()),
          item('Event List', Icons.event, const EventListPage()),
          item('Eclipse Tools (Kurs | Waktu)', Icons.handyman, const ToolsPage()),
          item('Saran & Kesan', Icons.feedback, const FeedbackPage()),
          item('Profil', Icons.person, const ProfilePage()),
        ],
      ),
    );
  }
}
