import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'moon_tab.dart';

/// Lunar Observatory berdiri sebagai halaman tersendiri, terpisah dari konversi.
class ObservatoryPage extends StatelessWidget {
  const ObservatoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpace,
      appBar: AppBar(
        title: const Text('Lunar Observatory'),
        backgroundColor: Colors.transparent,
      ),
      body: const MoonTab(),
    );
  }
}
