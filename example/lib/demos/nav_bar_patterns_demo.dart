/// GlassAppBar Navigation Patterns Demo
///
/// Showcases all iOS 26 navigation bar patterns side-by-side:
///
///   1. Transparent + inline title (right of back button)
///   2. Transparent + large title below bar (collapsing on scroll)
///   3. Solid background color (WhatsApp-style)
///   4. Transparent fade-only (no title in bar)
///   5. Tab bar with bottom fade
///   6. Fade header (no app bar) — Apple Music / Podcasts style
///   7. Large title + Search Bar — two-phase iOS 26 collapse
///
/// Run standalone:
///   flutter run -t lib/demos/nav_bar_patterns_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../constants/glass_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(
    child: CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(brightness: Brightness.dark),
      builder: (context, child) => Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: child!,
      ),
      home: const NavBarPatternsDemo(),
    ),
  ));
}

// =============================================================================
// Demo Launcher
// =============================================================================

class NavBarPatternsDemo extends StatelessWidget {
  const NavBarPatternsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        leading: GlassButton(
          icon: const Icon(CupertinoIcons.back),
          onTap: () => Navigator.of(context).pop(),
          width: 40,
          height: 40,
          iconSize: 20,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Top spacer for app bar area
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).top + 44 + 8,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.list(
              children: [
                Text(
                  'Navigation\nPatterns',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: CupertinoColors.label.resolveFrom(context),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All iOS 26 GlassAppBar modes — tap to preview.',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 32),
                _PatternTile(
                  title: 'Inline Title',
                  subtitle: 'Title right of back button — standard compact bar',
                  icon: CupertinoIcons.textformat,
                  onTap: () => _push(context, const _InlineTitleDemo()),
                ),
                const SizedBox(height: 16),
                _PatternTile(
                  title: 'Large Title → Collapse',
                  subtitle:
                      'Large title below bar, collapses to center on scroll',
                  icon: CupertinoIcons.text_alignleft,
                  onTap: () => _push(context, const _LargeTitleCollapseDemo()),
                ),
                const SizedBox(height: 16),
                _PatternTile(
                  title: 'Solid Background',
                  subtitle: 'Opaque colour bar — WhatsApp conversation style',
                  icon: CupertinoIcons.paintbrush,
                  onTap: () => _push(context, const _SolidBackgroundDemo()),
                ),
                const SizedBox(height: 16),
                _PatternTile(
                  title: 'Fade Only (No Bar Title)',
                  subtitle:
                      'Floating back button, content fades under status area',
                  icon: CupertinoIcons.arrow_up_circle,
                  onTap: () => _push(context, const _FadeOnlyDemo()),
                ),
                const SizedBox(height: 16),
                _PatternTile(
                  title: 'Tab Bar + Bottom Fade',
                  subtitle:
                      'Bottom bar with dual edge fade — iOS Settings style',
                  icon: CupertinoIcons.square_grid_2x2,
                  onTap: () => _push(context, const _TabBarBottomFadeDemo()),
                ),
                const SizedBox(height: 16),
                _PatternTile(
                  title: 'Fade Header (No App Bar)',
                  subtitle: 'Fixed title fades on scroll — Apple Music style',
                  icon: CupertinoIcons.music_note_2,
                  onTap: () => _push(context, const _FadeHeaderDemo()),
                ),
                const SizedBox(height: 16),
                _PatternTile(
                  title: 'Large Title + Search Bar',
                  subtitle:
                      'Two-phase collapse: title then search — iOS 26 Messages/Mail style',
                  icon: CupertinoIcons.search,
                  onTap: () => _push(context, const _LargeTitleSearchDemo()),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

// =============================================================================
// Pattern Tile
// =============================================================================

class _PatternTile extends StatelessWidget {
  const _PatternTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      onTap: onTap,
      width: double.infinity,
      height: 80,
      shape: const LiquidRoundedSuperellipse(borderRadius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                size: 16),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shared — dummy scrollable content
// =============================================================================

Widget _buildDummyContent({int count = 25, double topPadding = 0}) {
  return SliverList.separated(
    itemCount: count,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (context, index) => Padding(
      padding: EdgeInsets.only(
        top: index == 0 ? topPadding : 0,
        left: 24,
        right: 24,
      ),
      child: GlassCard(
        settings: RecommendedGlassSettings.overlay,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.primaries[index % Colors.primaries.length]
                    .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item ${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scrollable content to test navigation bar behaviour',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// 1. Inline Title (title right of back button)
// =============================================================================

class _InlineTitleDemo extends StatelessWidget {
  const _InlineTitleDemo();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        title: Text(
          'Inline Title',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        leading: GlassButton(
          quality: GlassQuality.premium,
          icon: const Icon(CupertinoIcons.back),
          onTap: () => Navigator.of(context).pop(),
          width: 40,
          height: 40,
          iconSize: 20,
        ),
        actions: [
          GlassButton(
            icon: const Icon(CupertinoIcons.ellipsis),
            onTap: () {},
            width: 40,
            height: 40,
            iconSize: 20,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topPad + 44 + 16),
          ),
          _buildDummyContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. Large Title → Collapse to Center
// =============================================================================

class _LargeTitleCollapseDemo extends StatefulWidget {
  const _LargeTitleCollapseDemo();

  @override
  State<_LargeTitleCollapseDemo> createState() =>
      _LargeTitleCollapseDemoState();
}

class _LargeTitleCollapseDemoState extends State<_LargeTitleCollapseDemo> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        // Bar title fades in automatically as the large title scrolls away.
        title: Text(
          'Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        largeTitleController: _titleController,
        leading: GlassButton(
          quality: GlassQuality.premium,
          icon: const Icon(CupertinoIcons.back),
          onTap: () => Navigator.of(context).pop(),
          width: 40,
          height: 40,
          iconSize: 20,
        ),
        actions: [
          GlassButton(
            icon: const Icon(CupertinoIcons.camera),
            onTap: () {},
            width: 40,
            height: 40,
            iconSize: 20,
          ),
          GlassButton(
            icon: const Icon(CupertinoIcons.plus),
            onTap: () {},
            width: 40,
            height: 40,
            iconSize: 20,
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _titleController.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topPad + 44),
          ),
          // Large title fades out as user scrolls — zero boilerplate.
          GlassLargeTitle(
            text: 'Chats',
            controller: _titleController,
          ),
          _buildDummyContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. Solid Background Colour
// =============================================================================

class _SolidBackgroundDemo extends StatelessWidget {
  const _SolidBackgroundDemo();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      edgeFade: false,
      appBar: GlassAppBar(
        backgroundColor:
            isDark ? const Color(0xFF1F2C34) : const Color(0xFFE8EDF0),
        title: Text(
          'Solid Background',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        centerTitle: false,
        leading: GlassButton(
          quality: GlassQuality.premium,
          icon: const Icon(CupertinoIcons.back),
          onTap: () => Navigator.of(context).pop(),
          width: 40,
          height: 40,
          iconSize: 20,
        ),
        actions: [
          GlassButton(
            icon: const Icon(CupertinoIcons.videocam),
            onTap: () {},
            width: 40,
            height: 40,
            iconSize: 20,
          ),
          GlassButton(
            icon: const Icon(CupertinoIcons.phone),
            onTap: () {},
            width: 40,
            height: 40,
            iconSize: 20,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topPad + 44 + 16),
          ),
          _buildDummyContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. Fade Only — No Title in Bar
// =============================================================================

class _FadeOnlyDemo extends StatelessWidget {
  const _FadeOnlyDemo();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        leading: GlassButton(
          quality: GlassQuality.premium,
          icon: const Icon(CupertinoIcons.back),
          onTap: () => Navigator.of(context).pop(),
          width: 40,
          height: 40,
          iconSize: 20,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topPad + 44),
          ),
          // Large title as part of content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Browse',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ),
          _buildDummyContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. Tab Bar + Bottom Fade
// =============================================================================

class _TabBarBottomFadeDemo extends StatefulWidget {
  const _TabBarBottomFadeDemo();

  @override
  State<_TabBarBottomFadeDemo> createState() => _TabBarBottomFadeDemoState();
}

class _TabBarBottomFadeDemoState extends State<_TabBarBottomFadeDemo> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      bottomBar: GlassTabBar.bottom(
        selectedIndex: _selectedTab,
        onTabSelected: (index) => setState(() => _selectedTab = index),
        settings:
            RecommendedGlassSettings.standard.copyWith(thickness: 20, blur: 3),
        tabs: const [
          GlassTab(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.bell_fill),
            label: 'Alerts',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.person_fill),
            label: 'Profile',
          ),
        ],
      ),
      appBar: GlassAppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        leading: GlassButton(
          quality: GlassQuality.premium,
          icon: const Icon(CupertinoIcons.back),
          onTap: () => Navigator.of(context).pop(),
          width: 40,
          height: 40,
          iconSize: 20,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topPad + 44 + 16),
          ),
          _buildDummyContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// =============================================================================
// Pattern 6 — Fade Header (No App Bar)
//
// Fixed large title positioned below the status bar that fades out as the
// user scrolls. Uses GlassScaffold.header + headerScrollController.
// This is the pattern Apple Music and Podcasts use for their home screens.
// =============================================================================

class _FadeHeaderDemo extends StatefulWidget {
  const _FadeHeaderDemo();

  @override
  State<_FadeHeaderDemo> createState() => _FadeHeaderDemoState();
}

class _FadeHeaderDemoState extends State<_FadeHeaderDemo> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      topEdgeFade: true,
      bottomEdgeFade: true,

      // ── Fixed header — fades out on scroll ──────────────────────────────
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Listen Now',
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4.resolveFrom(context),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'SD',
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      headerScrollController: _scrollController,
      headerFadeDistance: 30,

      // ── Bottom bar (no app bar in this pattern) ─────────────────────────
      bottomBar: GlassTabBar.bottom(
        selectedIndex: 0,
        onTabSelected: (_) {},
        settings:
            RecommendedGlassSettings.standard.copyWith(thickness: 20, blur: 3),
        tabs: const [
          GlassTab(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.antenna_radiowaves_left_right),
            label: 'Radio',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.music_albums),
            label: 'Library',
          ),
        ],
      ),

      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Extra top space for the fixed header overlay.
          SliverToBoxAdapter(
            child: SizedBox(height: topPad + 90),
          ),
          _buildDummyContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// =============================================================================
// 7. Large Title + Search Bar — Two-Phase iOS 26 Collapse
// =============================================================================
//
// iOS 26 Messages / Mail pattern:
//   Phase 1 (0 → ~52pt): Large title fades out.
//   Phase 2 (~52pt → ~96pt): Search bar collapses under the nav bar.
//
// GlassLargeTitleController drives both phases from a single ScrollController.

class _LargeTitleSearchDemo extends StatefulWidget {
  const _LargeTitleSearchDemo();

  @override
  State<_LargeTitleSearchDemo> createState() => _LargeTitleSearchDemoState();
}

class _LargeTitleSearchDemoState extends State<_LargeTitleSearchDemo> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return GlassScaffold(
      background: const ShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        // Bar title fades in automatically in Phase 1.
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        largeTitleController: _titleController,
        leading: GlassButton(
          quality: GlassQuality.premium,
          icon: const Icon(CupertinoIcons.back),
          onTap: () => Navigator.of(context).pop(),
          width: 40,
          height: 40,
          iconSize: 20,
        ),
        actions: [
          GlassButton(
            icon: const Icon(CupertinoIcons.pencil),
            onTap: () {},
            width: 40,
            height: 40,
            iconSize: 20,
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _titleController.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: topPad + 44),
          ),
          // Phase 1: large title fades out.
          // Phase 2: search bar collapses under nav bar.
          // Both driven automatically by GlassLargeTitleController.
          GlassLargeTitle(
            text: 'Messages',
            controller: _titleController,
            searchBar: GlassSearchBar(
              placeholder: 'Search',
              useOwnLayer: true,
              onChanged: (_) {},
            ),
          ),
          _buildDummyContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
