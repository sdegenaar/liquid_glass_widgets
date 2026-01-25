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
        unselectedIconColor: Colors.white.withOpacity(0.4),
        indicatorColor: Colors.blue.withOpacity(0.2),
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
