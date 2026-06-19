/// Simple demo showcasing GlassBottomBar features:
/// - Magic lens masking effect (MaskingQuality.high)
/// - Icon-only tab support (null labels)
/// - Glass refraction on icons
///
/// For a full-featured example, see example/lib/main.dart
///
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const GlassBottomBarDemoApp()));
}

class GlassBottomBarDemoApp extends StatelessWidget {
  const GlassBottomBarDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Glass Bottom Bar Demo',
      theme: const CupertinoThemeData(brightness: Brightness.dark),
      builder: (context, child) => Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: child!,
      ),
      home: const GlassBottomBarDemoPage(),
    );
  }
}

class GlassBottomBarDemoPage extends StatefulWidget {
  const GlassBottomBarDemoPage({super.key});

  @override
  State<GlassBottomBarDemoPage> createState() => _GlassBottomBarDemoPageState();
}

class _GlassBottomBarDemoPageState extends State<GlassBottomBarDemoPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: Image.network(
        'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2070&auto=format&fit=crop',
        fit: BoxFit.cover,
      ),
      statusBarStyle: GlassStatusBarStyle.auto,
      child: Scaffold(
        extendBody: true,
        body: Center(
          child: Text(
            'Tab $_selectedIndex Selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: GlassTabBar.bottom(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => setState(() => _selectedIndex = index),
          // Use distinct colors to verify masking
          selectedIconColor: Colors.white,
          unselectedIconColor: Colors.white.withValues(alpha: 0.4),
          indicatorColor: Colors.blue.withValues(alpha: 0.2),
          maskingQuality: MaskingQuality.high,
          extraButton: GlassBottomBarExtraButton(
            icon: const Icon(CupertinoIcons.info),
            label: 'something',
            onTap: () {},
          ),
          tabs: [
            GlassTab(
              label: 'Home',
              icon: const Icon(CupertinoIcons.home),
              activeIcon: const Icon(CupertinoIcons.home),
            ),
            GlassTab(
              // Empty label - should center icon
              label: null,
              icon: const Icon(CupertinoIcons.add_circled),
              activeIcon: const Icon(CupertinoIcons.add_circled_solid),
            ),
            GlassTab(
              label: 'Profile',
              icon: const Icon(CupertinoIcons.person),
              activeIcon: const Icon(CupertinoIcons.person_fill),
            ),
          ],
        ),
      ),
    );
  }
}
