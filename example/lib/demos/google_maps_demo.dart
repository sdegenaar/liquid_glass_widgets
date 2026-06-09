import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// This demo mirrors the exact structure from the user's Google Maps issue:
//   GlassPage → Scaffold → PageView → GlassBottomBar
//
// The ONLY change from their broken code is one line:
//   quality: GlassQuality.premium,          // ← their code (crashes on iOS)
//   platformViewBackdrop: Platform.isIOS     // ← the fix
//
// WebView stands in for GoogleMap — same UIKitView PlatformView type on iOS.
// ─────────────────────────────────────────────────────────────────────────────

class PlatformViewDemo extends StatefulWidget {
  const PlatformViewDemo({super.key});

  @override
  State<PlatformViewDemo> createState() => _PlatformViewDemoState();
}

class _PlatformViewDemoState extends State<PlatformViewDemo> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  static const _tabs = [
    GlassBottomBarTab(icon: Icon(Icons.home_rounded), label: 'Home'),
    GlassBottomBarTab(icon: Icon(Icons.map_rounded), label: 'Map'),
    GlassBottomBarTab(icon: Icon(Icons.person_rounded), label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      child: Scaffold(
        extendBody: true,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: const [
            PlaceholderTab(label: 'Home'),
            MapTab(),
            PlaceholderTab(label: 'Profile'),
          ],
        ),
        bottomNavigationBar: GlassBottomBar(
          settings: const LiquidGlassSettings(glassColor: Colors.black54),
          // ┌─────────────────────────────────────────────────────────────┐
          // │  THE FIX: Use platformViewBackdrop: true on iOS.          │
          // │                                                           │
          // │  Premium uses Impeller's backdrop-sampling shader which   │
          // │  cannot read pixels from a native UIKitView (GoogleMap,   │
          // │  WebView, MapLibre). Setting platformViewBackdrop ensures │
          // │  it falls back to standard BackdropFilter rendering over  │
          // │  native views while maintaining the premium indicator.    │
          // └─────────────────────────────────────────────────────────────┘
          quality: GlassQuality.premium,
          platformViewBackdrop: Platform.isIOS,
          selectedIndex: _selectedIndex,
          onTabSelected: _onTabSelected,
          tabs: _tabs,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map tab — OpenStreetMap via WebView (same UIKitView type as GoogleMap)
// ─────────────────────────────────────────────────────────────────────────────

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(
        Uri.parse('https://www.openstreetmap.org/#map=13/37.7749/-122.4194'),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WebViewWidget(controller: _controller);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder tabs — identical to the user's code
// ─────────────────────────────────────────────────────────────────────────────

class PlaceholderTab extends StatefulWidget {
  const PlaceholderTab({super.key, required this.label});

  final String label;

  @override
  State<PlaceholderTab> createState() => _PlaceholderTabState();
}

class _PlaceholderTabState extends State<PlaceholderTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Text(
        widget.label,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
