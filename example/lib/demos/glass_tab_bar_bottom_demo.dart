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
      child: GlassScaffold(
        extendBody: true,
        body: Center(
          child: Text(
            'Tab $_selectedIndex Selected',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: CupertinoColors.black,
                ),
              ],
            ),
          ),
        ),
        bottomBar: GlassTabBar.bottom(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => setState(() => _selectedIndex = index),
          // Use distinct colors to verify masking
          selectedIconColor: CupertinoColors.white,
          unselectedIconColor: CupertinoColors.white.withValues(alpha: 0.4),
          indicatorColor: CupertinoColors.activeBlue.withValues(alpha: 0.2),
          maskingQuality: MaskingQuality.high,
          extraButton: GlassTabBarExtraButton(
            icon: Icon(CupertinoIcons.info),
            label: 'something',
            onTap: () {},
          ),
          tabs: [
            GlassTab(
              label: 'Home',
              icon: Icon(CupertinoIcons.home),
              activeIcon: Icon(CupertinoIcons.home),
            ),
            GlassTab(
              // Empty label - should center icon
              label: null,
              icon: Icon(CupertinoIcons.add_circled),
              activeIcon: Icon(CupertinoIcons.add_circled),
            ),
            GlassTab(
              label: 'Profile',
              icon: Icon(CupertinoIcons.person),
              activeIcon: Icon(CupertinoIcons.person_fill),
            ),
          ],
        ),
      ),
    );
  }
}
