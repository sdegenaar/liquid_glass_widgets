/// Demo for testing GlassButtons, GlassButtonGroups, and their drop shadow behavior.
///
/// This example demonstrates buttons with different shadow elevations
/// in premium quality, specifically to verify that the shadows are not
/// clipped and dynamically match the shapes of buttons and menus.
///
/// To run: flutter run -t example/lib/main.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const ShadowClippingDemoApp()));
}

class ShadowClippingDemoApp extends StatelessWidget {
  const ShadowClippingDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(brightness: Brightness.light),
      builder: (context, child) => Theme(
        data: ThemeData.light(useMaterial3: true),
        child: child!,
      ),
      home: const ShadowClippingDemoPage(),
    );
  }
}

class ShadowClippingDemoPage extends StatefulWidget {
  const ShadowClippingDemoPage({super.key});

  @override
  State<ShadowClippingDemoPage> createState() => _ShadowClippingDemoPageState();
}

class _ShadowClippingDemoPageState extends State<ShadowClippingDemoPage> {
  int _tabIndex = 0;
  bool _searchActive = false;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: Container(
        color: const Color(0xFFF0F0F5), // Light background to see shadows
      ),
      appBar: const GlassAppBar(
        title: Text('Buttons & Shadows Demo'),
      ),
      bottomBar: GlassSearchableBottomBar(
        selectedIndex: _tabIndex,
        onTabSelected: (idx) => setState(() {
          _tabIndex = idx;
          _searchActive = false;
        }),
        isSearchActive: _searchActive,
        searchConfig: GlassSearchBarConfig(
          onSearchToggle: (active) => setState(() => _searchActive = active),
        ),
        settings: const LiquidGlassSettings(
          shadowElevation: 2.0,
          blur: 15,
          thickness: 20,
        ),
        tabs: [
          GlassBottomBarTab(
            icon: const Icon(CupertinoIcons.house),
            label: 'Home',
          ),
          GlassBottomBarTab(
            icon: const Icon(CupertinoIcons.compass),
            label: 'Discover',
          ),
        ],
      ),
      body: AdaptiveLiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 20,
          blur: 8,
        ),
        quality: GlassQuality.premium,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Premium Buttons with Elevations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Shadows should visibly expand around the buttons and not be cut off at the edge.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ElevatedButton(elevation: 1.0),
                    _ElevatedButton(elevation: 2.0),
                    _ElevatedButton(elevation: 4.0),
                  ],
                ),
                const SizedBox(height: 64),
                const Text(
                  'Glass Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GlassMenu(
                    settings: const LiquidGlassSettings(
                      thickness: 20,
                      blur: 12,
                      shadowElevation: 1.0,
                    ),
                    quality: GlassQuality.premium,
                    items: [
                      GlassMenuItem(
                        title: 'Option 1',
                        icon: const Icon(CupertinoIcons.star),
                        onTap: () {},
                      ),
                      GlassMenuItem(
                        title: 'Option 2',
                        icon: const Icon(CupertinoIcons.heart),
                        onTap: () {},
                      ),
                      GlassMenuItem(
                        title: 'Option 3',
                        titleStyle: const TextStyle(
                            color: CupertinoColors.destructiveRed),
                        icon: const Icon(CupertinoIcons.delete,
                            color: CupertinoColors.destructiveRed),
                        onTap: () {},
                      ),
                    ],
                    triggerBuilder: (context, toggle) => GlassButton(
                      icon: const Icon(CupertinoIcons.ellipsis),
                      width: 56,
                      height: 56,
                      iconSize: 24,
                      iconColor: Colors.black87,
                      onTap: toggle, // Correctly wire up the toggle function
                      useOwnLayer: true, // Required for standalone shadows
                      settings: const LiquidGlassSettings(
                        shadowElevation: 1.0,
                        glassColor: Color(0x99FFFFFF), // Make glass visible
                      ),
                      quality: GlassQuality.premium,
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                const Text(
                  'Button Groups',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                GlassButtonGroup.icons(
                  direction: Axis.horizontal,
                  quality: GlassQuality.premium,
                  useOwnLayer: true,
                  settings: const LiquidGlassSettings(
                    shadowElevation: 2.0,
                  ),
                  items: [
                    GlassGroupItem(
                      icon: const Icon(CupertinoIcons.reply),
                      onTap: () {},
                    ),
                    GlassGroupItem(
                      icon: const Icon(CupertinoIcons.heart),
                      onTap: () {},
                    ),
                    GlassGroupItem(
                      icon: const Icon(CupertinoIcons.share),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                const Text(
                  'Wide Button',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                GlassButton.custom(
                  width: 300,
                  height: 64,
                  shape: const LiquidRoundedRectangle(
                      borderRadius: 12), // Gentle corner radius
                  onTap: () {},
                  useOwnLayer: true,
                  settings: const LiquidGlassSettings(
                    shadowElevation: 1.0,
                    thickness: 20,
                    blur: 10,
                    glassColor: Color(0x99FFFFFF),
                  ),
                  quality: GlassQuality.premium,
                  child: const Text(
                    'Wide Button with Shadow',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ElevatedButton extends StatelessWidget {
  const _ElevatedButton({required this.elevation});

  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassButton(
          icon: const Icon(Icons.favorite),
          width: 64,
          height: 64,
          iconSize: 28,
          quality: GlassQuality.premium,
          useOwnLayer:
              true, // Required for standalone shadows in premium quality
          iconColor: Colors.black87,
          onTap: () {},
          settings: LiquidGlassSettings(
            shadowElevation: elevation,
            thickness: 20,
            blur: 10,
            glassColor: const Color(0x99FFFFFF), // Make glass visible
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Elev $elevation',
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
