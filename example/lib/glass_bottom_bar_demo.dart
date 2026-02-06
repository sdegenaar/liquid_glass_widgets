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

void main() {
  runApp(const GlassBottomBarDemoApp());
}

class GlassBottomBarDemoApp extends StatelessWidget {
  const GlassBottomBarDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glass Bottom Bar Demo',
      theme: ThemeData.dark(),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2070&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),

          // Content
          Center(
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
        ],
      ),
      bottomNavigationBar: GlassBottomBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) => setState(() => _selectedIndex = index),
        // Use distinct colors to verify masking
        selectedIconColor: Colors.white,
        unselectedIconColor: Colors.white.withValues(alpha: 0.4),
        indicatorColor: Colors.blue.withValues(alpha: 0.2),
        maskingQuality: MaskingQuality.high,
        tabs: [
          GlassBottomBarTab(
            label: 'Home',
            icon: CupertinoIcons.home,
            selectedIcon: CupertinoIcons.home,
          ),
          GlassBottomBarTab(
            // Empty label - should center icon
            label: null,
            icon: CupertinoIcons.add_circled,
            selectedIcon: CupertinoIcons.add_circled_solid,
          ),
          GlassBottomBarTab(
            label: 'Profile',
            icon: CupertinoIcons.person,
            selectedIcon: CupertinoIcons.person_fill,
          ),
        ],
      ),
    );
  }
}
