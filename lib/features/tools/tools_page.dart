import 'package:flutter/material.dart';
import 'currency_tab.dart';
import 'time_tab.dart';

/// Route /tools, argumen: initialTab (0 = Kurs, 1 = Waktu), bawaan 0.
class ToolsPage extends StatefulWidget {
  final int initialTab;
  const ToolsPage({super.key, this.initialTab = 0});
  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;
  bool _argRead = false;

  static int _clamp01(int v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  @override
  void initState() {
    super.initState();
    _tc = TabController(
        length: 2, vsync: this, initialIndex: _clamp01(widget.initialTab));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argRead) return;
    _argRead = true;
    final a = ModalRoute.of(context)?.settings.arguments;
    if (a is int) _tc.index = _clamp01(a);
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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Kurs'), Tab(text: 'Waktu')],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: const [CurrencyTab(), TimeTab()],
      ),
    );
  }
}
