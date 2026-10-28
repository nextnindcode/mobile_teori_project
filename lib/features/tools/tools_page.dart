import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';
import 'currency_tab.dart';
import 'time_tab.dart';
import 'moon_tab.dart';

/// Eclipse Tools: kurs, zona waktu, fase Bulan, dan jadwal gerhana.
class ToolsPage extends StatefulWidget {
  final int initialTab;
  const ToolsPage({super.key, this.initialTab = 0});
  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with SingleTickerProviderStateMixin {
  late final TabController _tc;
  bool _argRead = false;

  static int _validTab(int value) => value < 0 ? 0 : (value > 2 ? 2 : value);

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this, initialIndex: _validTab(widget.initialTab));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argRead) return;
    _argRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) _tc.index = _validTab(args);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eclipse Tools'),
        bottom: TabBar(
          controller: _tc,
          isScrollable: false,
          labelColor: AppTheme.coolCyan,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.coronaGold,
          tabs: const [
            Tab(text: 'Kurs'),
            Tab(text: 'Waktu'),
            Tab(text: 'Observatory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: const [CurrencyTab(), TimeTab(), MoonTab()],
      ),
    );
  }
}
