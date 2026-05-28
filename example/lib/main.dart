import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets_example/apple_messages/apple_messages_demo.dart';
import 'package:liquid_glass_widgets_example/apple_music/apple_music_demo.dart';
import 'package:liquid_glass_widgets_example/apple_news/apple_news_demo.dart';
import 'package:liquid_glass_widgets_example/apple_podcasts/apple_podcasts_demo.dart';
import 'package:liquid_glass_widgets_example/demos/keypad_lock_screen_demo.dart';
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

class AppleLiquidGlassShowcaseApp extends StatelessWidget {
  const AppleLiquidGlassShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Widgets',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          surface: Colors.black,
        ),
      ),
      home: const ShowcaseHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
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
      icon: Icon(CupertinoIcons.play_rectangle),
      activeIcon: Icon(CupertinoIcons.play_rectangle_fill),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: _buildBackground(),
      statusBarStyle: GlassStatusBarStyle.dark,
      settings: RecommendedGlassSettings.standard,
      child: Scaffold(
        extendBody: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_selectedTab) {
            0 => const _ExploreTab(key: ValueKey('explore')),
            1 => const _WidgetsTab(key: ValueKey('widgets')),
            _ => const _DemosTab(key: ValueKey('demos')),
          },
        ),
        bottomNavigationBar: GlassBottomBar(
          selectedIndex: _selectedTab,
          onTabSelected: (i) => setState(() => _selectedTab = i),
          quality: GlassQuality.premium,
          interactionBehavior: GlassInteractionBehavior.full,
          selectedIconColor: const Color(0xFFA855F7),
          unselectedIconColor: Colors.white,
          indicatorColor: Colors.white.withValues(alpha: 0.1),
          iconSize: 28,
          labelFontSize: 10,
          iconLabelSpacing: 0,
          glassSettings: const LiquidGlassSettings(
            glassColor: Color.fromRGBO(28, 28, 30, 0.8),
            thickness: 30,
            blur: 4,
            chromaticAberration: .01,
            lightAngle: GlassDefaults.lightAngle,
            lightIntensity: .5,
            ambientStrength: 0,
            refractiveIndex: 1.2,
            saturation: 1.2,
            specularSharpness: GlassSpecularSharpness.medium,
          ),
          tabs: _tabs,
        ),
      ),
    );
  }
}

/// Deep navy background with ChemAlert-style purple/pink/blue glow accents.
Widget _buildBackground() {
  return Container(
    color: const Color(0xFF020715), // ChemAlert deep navy
    child: Stack(
      children: [
        // Purple glow — upper right (9B59FF / A246F7)
        Positioned(
          top: -50,
          right: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFA246F7).withValues(alpha: 0.32),
                  const Color(0xFF9B59FF).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Hot pink glow — center left (E040FB / EB66FF)
        Positioned(
          top: 280,
          left: -100,
          child: Container(
            width: 460,
            height: 460,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFEB66FF).withValues(alpha: 0.16),
                  const Color(0xFFE040FB).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Blue glow — bottom right (2077FF / 4FC3F7)
        Positioned(
          bottom: -60,
          right: -40,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2077FF).withValues(alpha: 0.18),
                  const Color(0xFF4FC3F7).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        // Subtle purple accent — mid-left
        Positioned(
          top: 120,
          left: 30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF9B59FF).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Purple wash — center screen (behind catalog cards)
        Positioned(
          top: 500,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF9B59FF).withValues(alpha: 0.14),
                    const Color(0xFF7B3FA8).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
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
                  const Text(
                    'Liquid Glass',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'iOS 26 Widget Toolkit',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white.withValues(alpha: 0.4),
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
                              Icon(Icons.apple, color: Colors.white, size: 28),
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
                            'Full-fidelity Apple Music\nrecreation with Liquid Glass',
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
                      color: Colors.white,
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
                          subtitle: 'Sheet · Dialog · Menu',
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
                  const Text(
                    'Widgets',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _WidgetTile(
                          icon: CupertinoIcons.square_stack_3d_up_fill,
                          title: 'Containers',
                          subtitle: 'GlassCard, GlassPanel, GlassContainer',
                          destination: const ContainersPage(),
                        ),
                        _WidgetTile(
                          icon: CupertinoIcons.hand_point_right_fill,
                          title: 'Interactive',
                          subtitle: 'GlassButton, GlassSwitch, GlassSlider',
                          destination: const InteractivePage(),
                        ),
                        _WidgetTile(
                          icon: CupertinoIcons.hourglass,
                          title: 'Feedback',
                          subtitle: 'GlassProgressIndicator, GlassToast',
                          destination: const FeedbackPage(),
                        ),
                        _WidgetTile(
                          icon: CupertinoIcons.square_stack_fill,
                          title: 'Overlays',
                          subtitle: 'GlassSheet, GlassDialog, GlassMenu',
                          destination: const OverlaysPage(),
                        ),
                        _WidgetTile(
                          icon: CupertinoIcons.rectangle_3_offgrid_fill,
                          title: 'Surfaces',
                          subtitle: 'GlassAppBar, GlassBottomBar, GlassTabBar',
                          destination: const SurfacesPage(),
                        ),
                        _WidgetTile(
                          icon: CupertinoIcons.keyboard,
                          title: 'Input',
                          subtitle: 'GlassTextField, GlassSearchBar',
                          destination: const InputPage(),
                          isLast: true,
                        ),
                      ],
                    ),
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
                  const Text(
                    'Demos',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Full-screen app experiences built with Liquid Glass.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.4),
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
            Icon(icon, color: Colors.white60, size: 24),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.4),
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

/// Widget list tile for the Widgets tab.
class _WidgetTile extends StatelessWidget {
  const _WidgetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.destination,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget destination;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return GlassListTile(
      leading: Icon(icon, color: Colors.white54),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: GlassListTile.chevron,
      isLast: isLast,
      onTap: () => _openDemo(context, destination),
    );
  }
}
