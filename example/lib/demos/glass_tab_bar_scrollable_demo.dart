/// GlassTabBar Scrollable Demo
///
/// Demonstrates a scrollable GlassTabBar with a dynamic number of tabs.
/// The demo shows how to add tabs at runtime and updates the selected
/// tab index accordingly. It also follows the library's initialization
/// pattern (LiquidGlassWidgets.initialize + wrap) for consistency with
/// other examples.

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const TabBarTestApp()));
}

/// Root application widget.
class TabBarTestApp extends StatelessWidget {
  const TabBarTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlassTabBar Scrollable Demo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const TabBarTestHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Home page containing the scrollable GlassTabBar.
class TabBarTestHome extends StatefulWidget {
  const TabBarTestHome({super.key});

  @override
  State<TabBarTestHome> createState() => _TabBarTestHomeState();
}

class _TabBarTestHomeState extends State<TabBarTestHome> {
  int _tabCount = 5; // Start with five tabs.
  int _selectedIndex = 0;

  /// Adds a new tab by incrementing [_tabCount].
  void _addTab() {
    setState(() => _tabCount++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GlassTabBar – isScrollable: true'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Tab',
            onPressed: _addTab,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The scrollable GlassTabBar.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GlassTabBar(
                selectedIndex: _selectedIndex,
                onTabSelected: (i) => setState(() => _selectedIndex = i),
                isScrollable: true,
                tabs: List.generate(
                  _tabCount,
                  (i) => GlassTab(label: 'Tab ${i + 1}'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tab count: $_tabCount',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
