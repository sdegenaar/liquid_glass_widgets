/// Liquid Glass Widgets — standalone pub.dev example.
///
/// Demonstrates the key APIs and correct initialisation pattern:
///   • LiquidGlassWidgets.initialize() — shader pre-warming (no first-frame flash)
///   • LiquidGlassWidgets.wrap()       — adaptive quality + theming scope
///   • GlassPage                       — per-screen background, Scaffold transparency, backdrop
///   • GlassSearchableBottomBar        — glass nav bar with search
///   • GlassCard                       — glass surface container
///   • GlassButton                     — interactive glass button
///
/// Run from the example/ directory:
///   flutter pub get && flutter run -t example.dart

library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  // Required: initialise Flutter engine before loading shaders.
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm all liquid glass shaders — prevents the white flash on first render
  // and compiles the Impeller pipeline on iOS/macOS/Android.
  await LiquidGlassWidgets.initialize();

  // wrap() installs the adaptive quality scope and optional GlassTheme at the
  // root of the widget tree. Each glass layer manages its own GPU backdrop
  // capture automatically — no manual scoping needed.
  runApp(LiquidGlassWidgets.wrap(child: const LiquidGlassExampleApp()));
}

class LiquidGlassExampleApp extends StatelessWidget {
  const LiquidGlassExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Widgets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          surface: Colors.black,
        ),
      ),
      home: const _HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page — glass nav bar + scrollable content
// ---------------------------------------------------------------------------

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _selectedTab = 0;

  static const _tabs = [
    GlassTab(icon: Icon(Icons.home_rounded), label: 'Home'),
    GlassTab(icon: Icon(Icons.explore_rounded), label: 'Explore'),
    GlassTab(
        icon: Icon(Icons.library_music_rounded), label: 'Library'),
  ];

  @override
  Widget build(BuildContext context) {
    // GlassPage is the recommended pattern for screens that use glass surfaces.
    // It handles Scaffold transparency, backdrop isolation, and background
    // texture sampling for real refraction — all in one widget.
    return GlassPage(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A2E), Color(0xFF1A0A3E), Color(0xFF0D1B2A)],
          ),
        ),
      ),
      child: Scaffold(
        extendBody: true,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Hero card ──────────────────────────────────────────────
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Liquid Glass',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'iOS 26-inspired glassmorphism for Flutter. '
                      'Shader-based refraction, jelly physics, '
                      'and dynamic lighting on every platform.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Glass icon button
                    GlassButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      onTap: () {},
                      label: 'Play',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Example list items ─────────────────────────────────────
              for (final item in [
                (
                  Icons.grid_view_rounded,
                  'Containers',
                  'GlassCard, GlassContainer'
                ),
                (
                  Icons.touch_app_rounded,
                  'Interactive',
                  'GlassButton, GlassSwitch, GlassChip'
                ),
                (
                  Icons.layers_rounded,
                  'Surfaces',
                  'GlassBottomBar, GlassAppBar, GlassModalSheet'
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(item.$1, color: Colors.white70, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item.$3,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // ── Glass searchable nav bar ─────────────────────────────────────
        bottomNavigationBar: GlassTabBar.searchable(
          tabs: _tabs,
          selectedIndex: _selectedTab,
          onTabSelected: (i) => setState(() => _selectedTab = i),
          searchConfig: GlassSearchBarConfig(
            hintText: 'Search',
            onSearchToggle: (_) {},
            onSearchFocusChanged: (_) {},
          ),
        ),
      ),
    );
  }
}
