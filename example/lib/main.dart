import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets_example/apple_messages/apple_messages_demo.dart';
import 'package:liquid_glass_widgets_example/apple_music/apple_music_demo.dart';
import 'package:liquid_glass_widgets_example/apple_news/apple_news_demo.dart';
import 'package:liquid_glass_widgets_example/apple_podcasts/apple_podcasts_demo.dart';
import 'package:liquid_glass_widgets_example/apple_lockscreen/keypad_lock_screen_demo.dart';
import 'package:liquid_glass_widgets_example/demos/nav_bar_patterns_demo.dart';
import 'package:liquid_glass_widgets_example/demos/glass_menu_demo.dart';
import 'package:liquid_glass_widgets_example/demos/glass_modal_sheet_demo.dart';
import 'package:liquid_glass_widgets_example/demos/video_player_demo.dart';
import 'package:liquid_glass_widgets_example/demos/text_field_demo.dart';
import 'package:liquid_glass_widgets_example/demos/bottom_bar_tab_width_demo.dart';

import 'package:liquid_glass_widgets_example/demos/google_maps_demo.dart'
    show PlatformViewDemo;
import 'package:liquid_glass_widgets_example/pages/containers_page.dart';
import 'package:liquid_glass_widgets_example/pages/feedback_page.dart';
import 'package:liquid_glass_widgets_example/pages/input_page.dart';
import 'package:liquid_glass_widgets_example/pages/interactive_page.dart';
import 'package:liquid_glass_widgets_example/pages/overlays_page.dart';
import 'package:liquid_glass_widgets_example/pages/surfaces_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const AppleLiquidGlassShowcaseApp()));
}

class AppleLiquidGlassShowcaseApp extends StatefulWidget {
  const AppleLiquidGlassShowcaseApp({super.key});

  @override
  State<AppleLiquidGlassShowcaseApp> createState() =>
      _AppleLiquidGlassShowcaseAppState();
}

class _AppleLiquidGlassShowcaseAppState
    extends State<AppleLiquidGlassShowcaseApp> {
  /// Global brightness toggle — shared via [_BrightnessScope].
  Brightness _brightness = Brightness.dark;

  void _toggleBrightness() {
    setState(() {
      _brightness = _brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _brightness == Brightness.dark;

    return _BrightnessScope(
      brightness: _brightness,
      toggleBrightness: _toggleBrightness,
      child: CupertinoApp(
        title: 'Liquid Glass Widgets',
        theme: CupertinoThemeData(
          brightness: _brightness,
        ),
        // Demo pages use Material widgets (Scaffold, showModalBottomSheet)
        // that require these localizations. Not needed for glass widgets.
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        // Provide a matching Material Theme for any Scaffold widgets in demo pages.
        builder: (context, child) => Theme(
          data: isDark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          child: child!,
        ),
        home: const ShowcaseHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Inherited widget exposing the current [Brightness] and a toggle callback
/// to any descendant widget in the example app.
class _BrightnessScope extends InheritedWidget {
  const _BrightnessScope({
    required this.brightness,
    required this.toggleBrightness,
    required super.child,
  });

  final Brightness brightness;
  final VoidCallback toggleBrightness;

  static _BrightnessScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_BrightnessScope>()!;
  }

  @override
  bool updateShouldNotify(_BrightnessScope oldWidget) =>
      brightness != oldWidget.brightness;
}

// =============================================================================
// Home Page — GlassBottomBar as hero + content tabs
// =============================================================================

class ShowcaseHomePage extends StatefulWidget {
  const ShowcaseHomePage({super.key});

  @override
  State<ShowcaseHomePage> createState() => _ShowcaseHomePageState();
}

class _ShowcaseHomePageState extends State<ShowcaseHomePage> {
  int _selectedTab = 0;

  static const _tabs = [
    GlassBottomBarTab(
      label: 'Explore',
      icon: Icon(CupertinoIcons.compass),
      activeIcon: Icon(CupertinoIcons.compass_fill),
    ),
    GlassBottomBarTab(
      label: 'Widgets',
      icon: Icon(CupertinoIcons.square_grid_2x2),
      activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
    ),
    GlassBottomBarTab(
      label: 'Demos',
      icon: Icon(Icons.apple, size: 30),
      activeIcon: Icon(Icons.apple, size: 30),
    ),
    GlassBottomBarTab(
      label: 'Examples',
      icon: Icon(CupertinoIcons.cube),
      activeIcon: Icon(CupertinoIcons.cube_fill),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scope = _BrightnessScope.of(context);
    final isDark = scope.brightness == Brightness.dark;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      statusBarStyle:
          isDark ? GlassStatusBarStyle.light : GlassStatusBarStyle.dark,
      settings: RecommendedGlassSettings.standard,
      topEdgeFade: true,
      bottomBar: GlassBottomBar(
        selectedIndex: _selectedTab,
        onTabSelected: (i) => setState(() => _selectedTab = i),
        interactionBehavior: GlassInteractionBehavior.full,
        selectedIconColor: const Color(0xFFA855F7),
        iconSize: 28,
        labelFontSize: 10,
        iconLabelSpacing: 0,
        settings: const LiquidGlassSettings(
          glassColor: Color.fromRGBO(255, 255, 255, 0.08),
          thickness: 30,
          blur: 3,
          chromaticAberration: .01,
          lightAngle: GlassDefaults.lightAngle,
          lightIntensity: .5,
          ambientStrength: 0,
          refractiveIndex: 1.2,
          saturation: 1.2,
          specularSharpness: GlassSpecularSharpness.medium,
        ),
        extraButton: GlassBottomBarExtraButton(
          icon: Icon(isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon),
          label: isDark ? 'Light mode' : 'Dark mode',
          onTap: scope.toggleBrightness,
        ),
        tabs: _tabs,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_selectedTab) {
          0 => const _ExploreTab(key: ValueKey('explore')),
          1 => const _WidgetsTab(key: ValueKey('widgets')),
          2 => const _DemosTab(key: ValueKey('demos')),
          _ => const _ExamplesTab(key: ValueKey('examples')),
        },
      ),
    );
  }
}


// =============================================================================
// Explore Tab — hero overview
// =============================================================================

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liquid Glass',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'iOS 26 Widget Toolkit',
                    style: TextStyle(
                      fontSize: 17,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Featured demo — large card ────────────────────
                  GestureDetector(
                    onTap: () =>
                        _openDemo(context, const AppleMusicHomeScreen()),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8B0000),
                            Color(0xFFFA2D48),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apple, color: Colors.white, size: 30),
                              const SizedBox(width: 6),
                              const Text(
                                'Music',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Apple Music recreation\n with Liquid Glass Widgets',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Searchable bottom bar · Play pill · Tab navigation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Two smaller demo cards ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Messages',
                          icon: CupertinoIcons.chat_bubble_2_fill,
                          color: const Color(0xFF34C759),
                          destination: const MessagesScreen(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Podcasts',
                          icon: CupertinoIcons.mic_fill,
                          color: const Color(0xFFA855F7),
                          destination: const ApplePodcastsHomeScreen(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Staggered widget preview ──────────────────────
                  Text(
                    'Widget Catalog',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Masonry: tall card + two stacked ──────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: tall card spanning both right cards
                        Expanded(
                          flex: 1,
                          child: _StaggeredCatalogCard(
                            icon: CupertinoIcons.rectangle_3_offgrid_fill,
                            title: 'Surfaces',
                            subtitle: 'AppBar · BottomBar · SearchBar · TabBar',
                            destination: const SurfacesPage(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Right: two stacked cards
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StaggeredCatalogCard(
                                icon: CupertinoIcons.hand_point_right_fill,
                                title: 'Interactive',
                                subtitle: 'Button · Switch · Slider',
                                height: 120,
                                destination: const InteractivePage(),
                              ),
                              const SizedBox(height: 14),
                              _StaggeredCatalogCard(
                                icon: CupertinoIcons.hourglass,
                                title: 'Feedback',
                                subtitle: 'Progress · Toast',
                                height: 120,
                                destination: const FeedbackPage(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Row of two ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StaggeredCatalogCard(
                          icon: CupertinoIcons.keyboard,
                          title: 'Input',
                          subtitle: 'TextField · SearchBar',
                          height: 120,
                          destination: const InputPage(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StaggeredCatalogCard(
                          icon: CupertinoIcons.square_stack_fill,
                          title: 'Overlays',
                          subtitle: 'Sheet · Dialog · Menu · Popover',
                          height: 120,
                          destination: const OverlaysPage(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Full-width card ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StaggeredCatalogCard(
                          icon: CupertinoIcons.square_stack_3d_up_fill,
                          title: 'Containers',
                          subtitle: 'Card · Panel · Container',
                          height: 100,
                          destination: const ContainersPage(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Widgets Tab — full catalog
// =============================================================================

class _WidgetsTab extends StatelessWidget {
  const _WidgetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Widgets',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse the full widget catalog.',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Row 1: Containers + Interactive
                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Containers',
                          icon: CupertinoIcons.square_stack_3d_up_fill,
                          color: const Color(0xFF007AFF),
                          destination: const ContainersPage(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Interactive',
                          icon: CupertinoIcons.hand_point_right_fill,
                          color: const Color(0xFFFF9500),
                          destination: const InteractivePage(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 2: Feedback + Overlays
                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Feedback',
                          icon: CupertinoIcons.hourglass,
                          color: const Color(0xFF34C759),
                          destination: const FeedbackPage(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Overlays',
                          icon: CupertinoIcons.square_stack_fill,
                          color: const Color(0xFFAF52DE),
                          destination: const OverlaysPage(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Surfaces + Input
                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Surfaces',
                          icon: CupertinoIcons.rectangle_3_offgrid_fill,
                          color: const Color(0xFF5AC8FA),
                          destination: const SurfacesPage(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Input',
                          icon: CupertinoIcons.keyboard,
                          color: const Color(0xFFFF2D55),
                          destination: const InputPage(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Demos Tab — full-screen app demos
// =============================================================================

class _DemosTab extends StatelessWidget {
  const _DemosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demos',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Polished Apple app reproductions.',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Large featured card
                  _LargeDemoCard(
                    title: 'Apple Music',
                    subtitle:
                        'Searchable bottom bar, play pill, tab navigation',
                    icon: CupertinoIcons.music_note_2,
                    gradient: const [
                      Color(0xFF8B0000),
                      Color(0xFFFA2D48),
                    ],
                    destination: const AppleMusicHomeScreen(),
                  ),
                  const SizedBox(height: 14),

                  _LargeDemoCard(
                    title: 'Messages',
                    subtitle: 'Conversations, edit menus & filter controls',
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    gradient: const [
                      Color(0xFF0A4D20),
                      Color(0xFF34C759),
                    ],
                    destination: const MessagesScreen(),
                  ),
                  const SizedBox(height: 14),

                  _LargeDemoCard(
                    title: 'Podcasts',
                    subtitle:
                        'Mini-player, now playing sheet & scroll collapse',
                    icon: CupertinoIcons.mic_fill,
                    gradient: const [
                      Color(0xFF4A1A6B),
                      Color(0xFFA855F7),
                    ],
                    destination: const ApplePodcastsHomeScreen(),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'News',
                          icon: CupertinoIcons.news_solid,
                          color: const Color(0xFFFF3B30),
                          destination: const AppleNewsHomeScreen(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Lock Screen',
                          icon: CupertinoIcons.lock_fill,
                          color: const Color(0xFF5856D6),
                          destination: const KeypadLockScreenDemo(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Examples Tab — Widget patterns & component reference
// =============================================================================

class _ExamplesTab extends StatelessWidget {
  const _ExamplesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examples',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Widget modes & configuration reference.',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Row 1: Nav Patterns + Context Menus
                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Nav Patterns',
                          icon: CupertinoIcons.rectangle_split_3x1,
                          color: const Color(0xFF007AFF),
                          destination: const NavBarPatternsDemo(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Menus',
                          icon: CupertinoIcons.ellipsis_circle_fill,
                          color: const Color(0xFFFF9500),
                          destination: const MenuDemoPage(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Large card: Modal Sheets
                  _LargeDemoCard(
                    title: 'Modal Sheets',
                    subtitle:
                        'Standard, peek, Apple Maps & smart silence modes',
                    icon: CupertinoIcons.rectangle_on_rectangle,
                    gradient: const [
                      Color(0xFF0E4D92),
                      Color(0xFF5AC8FA),
                    ],
                    destination: const ShowcaseApp(),
                  ),
                  const SizedBox(height: 14),

                  // Row 2: Text Fields + Video Player
                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Text Fields',
                          icon: CupertinoIcons.textbox,
                          color: const Color(0xFF34C759),
                          destination: const TextFieldDemo(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Video Player',
                          icon: CupertinoIcons.play_circle_fill,
                          color: const Color(0xFFFF2D55),
                          destination: const VideoGlassDemoPage(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Tab Widths
                  Row(
                    children: [
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Tab Widths',
                          icon: CupertinoIcons.slider_horizontal_3,
                          color: const Color(0xFFAF52DE),
                          destination: const TabWidthDemoPage(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallDemoCard(
                          title: 'Platform View',
                          icon: CupertinoIcons.map_fill,
                          color: const Color(0xFF5AC8FA),
                          destination: const PlatformViewDemo(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================

void _openDemo(BuildContext context, Widget destination) {
  Navigator.of(context).push(
    CupertinoPageRoute<void>(builder: (_) => destination),
  );
}

/// Staggered glass catalog card — variable height, glass background.
class _StaggeredCatalogCard extends StatelessWidget {
  const _StaggeredCatalogCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.height,
    required this.destination,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double? height;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    Widget button = GlassButton.custom(
      onTap: () => _openDemo(context, destination),
      width: double.infinity,
      height: height ?? 254, // tall card default
      shape: const LiquidRoundedSuperellipse(borderRadius: 12),
      interactionScale: 0.97,
      stretch: 0.15,
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                size: 24),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );

    return button;
  }
}

/// Small demo card with accent color.
class _SmallDemoCard extends StatelessWidget {
  const _SmallDemoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.destination,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDemo(context, destination),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.7),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large demo card with gradient.
class _LargeDemoCard extends StatelessWidget {
  const _LargeDemoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.destination,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDemo(context, destination),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
