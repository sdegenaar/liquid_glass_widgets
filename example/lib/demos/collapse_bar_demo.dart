/// Demo isolating [GlassTabBar.bottom] collapse behaviour when a
/// [GlassBottomBarCollapseConfig] is set.
///
/// Scroll DOWN  → triggers collapse, pill travels into the + button.
/// Scroll UP    → expands back.
///
/// Use the segment controls to switch:
///   • collapse direction:  towardsExtraButton vs awayFromExtraButton
///   • extra button side:   right (default) vs left
///
/// To run:
///   flutter run -t example/lib/demos/collapse_bar_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const _CollapseBarDemoApp()));
}

class _CollapseBarDemoApp extends StatelessWidget {
  const _CollapseBarDemoApp();

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Collapse Bar Demo',
      theme: const CupertinoThemeData(brightness: Brightness.dark),
      builder: (context, child) => Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: child!,
      ),
      home: const CollapseBarDemoPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public page — also importable by main.dart if desired later
// ─────────────────────────────────────────────────────────────────────────────

class CollapseBarDemoPage extends StatefulWidget {
  const CollapseBarDemoPage({super.key});

  @override
  State<CollapseBarDemoPage> createState() => _CollapseBarDemoPageState();
}

class _CollapseBarDemoPageState extends State<CollapseBarDemoPage> {
  int _selectedTab = 0;
  int _directionIndex = 0; // 0 = towards, 1 = away
  GlassExtraButtonPlacement _placement = GlassExtraButtonPlacement.right;

  final ScrollController _scrollController = ScrollController();

  static const _tabs = <GlassTab>[
    GlassTab(
      label: 'Home',
      icon: Icon(CupertinoIcons.home),
      activeIcon: Icon(CupertinoIcons.house_fill),
    ),
    GlassTab(
      label: 'Search',
      icon: Icon(CupertinoIcons.search),
      activeIcon: Icon(CupertinoIcons.search_circle_fill),
    ),
    GlassTab(
      label: 'Library',
      icon: Icon(CupertinoIcons.book),
      activeIcon: Icon(CupertinoIcons.book_fill),
    ),
  ];

  GlassTabBarCollapseDirection get _direction => _directionIndex == 0
      ? GlassTabBarCollapseDirection.towardsExtraButton
      : GlassTabBarCollapseDirection.awayFromExtraButton;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      // Pure black — the canonical iOS dark mode base that lets
      // #1C1C1E cells read cleanly and the glass bar float naturally.
      background: const ColoredBox(color: CupertinoColors.black),
      statusBarStyle: GlassStatusBarStyle.light,
      child: GlassScaffold(
        backgroundColor: const Color(0x00000000),
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Controls ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Collapse Direction'),
                    SizedBox(height: 8),
                    CupertinoSlidingSegmentedControl<int>(
                      groupValue: _directionIndex,
                      children: const {
                        0: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('→ Towards extra'),
                        ),
                        1: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('← Away from extra'),
                        ),
                      },
                      onValueChanged: (v) {
                        if (v != null) setState(() => _directionIndex = v);
                      },
                    ),
                    SizedBox(height: 14),
                    _Label('Extra Button Side'),
                    SizedBox(height: 8),
                    CupertinoSlidingSegmentedControl<GlassExtraButtonPlacement>(
                      groupValue: _placement,
                      children: const {
                        GlassExtraButtonPlacement.right: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Right  ＋'),
                        ),
                        GlassExtraButtonPlacement.left: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('＋  Left'),
                        ),
                      },
                      onValueChanged: (v) {
                        if (v != null) setState(() => _placement = v);
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      _directionIndex == 0
                          ? '↓ Scroll down — pill should slide INTO the + button with no gap'
                          : '↓ Scroll down — pill collapses to the opposite edge',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),

              // ── Scrollable list ────────────────────────────────────────────
              // Plain solid-color cells — no glass in a scrolling list.
              // (See README performance guidance: glass belongs on chrome only.)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 120),
                  itemCount: _sections.length,
                  itemBuilder: (_, i) => _SectionGroup(section: _sections[i]),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom bar — premium quality, proper glass settings ─────────────
        bottomBar: GlassTabBar.bottom(
          selectedIndex: _selectedTab,
          onTabSelected: (i) => setState(() => _selectedTab = i),
          maskingQuality: MaskingQuality.high,
          quality: GlassQuality.premium,
          settings: const LiquidGlassSettings(
            blur: 20,
            thickness: 20,
            glassColor: Color.fromRGBO(255, 255, 255, 0.15),
            lightAngle: 2.356, // 135° — Apple standard (0.75 * pi)
            lightIntensity: 0.7,
            ambientStrength: 0.5,
            saturation: 1.2,
            refractiveIndex: 1.2,
            chromaticAberration: 0.01,
          ),
          scrollController: _scrollController,
          extraButton: GlassTabBarExtraButton(
            icon: Icon(CupertinoIcons.add),
            label: 'Add',
            placement: _placement,
            onTap: () => _showActionFiredDialog(context),
          ),
          collapseConfig: GlassTabBarCollapseConfig(
            direction: _direction,
            expandOnTap: true,
            // Intentionally slower than the 220ms package default so the
            // collapse trajectory is observable by eye in this demo.
            animationDuration: const Duration(milliseconds: 320),
          ),
          tabs: _tabs,
        ),
      ),
    );
  }

  void _showActionFiredDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Add tapped'),
        content: Text(
          'If the bar was collapsed, the first tap expanded it.\n'
          'This second tap fired the action.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: CupertinoColors.white.withValues(alpha: 0.70),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _Row {
  const _Row(
      {required this.icon,
      required this.color,
      required this.title,
      this.subtitle});
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
}

class _Section {
  const _Section({required this.header, required this.rows});
  final String header;
  final List<_Row> rows;
}

const _sections = <_Section>[
  _Section(header: 'Media', rows: [
    _Row(
        icon: CupertinoIcons.music_note_2,
        color: Color(0xFFFF2D55),
        title: 'Music',
        subtitle: '3,412 songs'),
    _Row(icon: CupertinoIcons.tv_fill, color: Color(0xFF000000), title: 'TV'),
    _Row(
        icon: CupertinoIcons.mic_fill,
        color: Color(0xFF9B59B6),
        title: 'Podcasts'),
  ]),
  _Section(header: 'Social', rows: [
    _Row(
        icon: CupertinoIcons.chat_bubble_2_fill,
        color: Color(0xFF34C759),
        title: 'Messages'),
    _Row(
        icon: CupertinoIcons.phone_fill,
        color: Color(0xFF34C759),
        title: 'Phone'),
    _Row(
        icon: CupertinoIcons.mail,
        color: Color(0xFF007AFF),
        title: 'Mail',
        subtitle: '2 unread'),
  ]),
  _Section(header: 'Tools', rows: [
    _Row(
        icon: CupertinoIcons.map_fill, color: Color(0xFF34C759), title: 'Maps'),
    _Row(
        icon: CupertinoIcons.camera_fill,
        color: Color(0xFF1C1C1E),
        title: 'Camera'),
    _Row(
        icon: CupertinoIcons.calendar,
        color: Color(0xFFFF3B30),
        title: 'Calendar'),
    _Row(
        icon: CupertinoIcons.clock_fill,
        color: Color(0xFF1C1C1E),
        title: 'Clock'),
  ]),
  _Section(header: 'Productivity', rows: [
    _Row(
        icon: CupertinoIcons.doc_text_fill,
        color: Color(0xFFFF9500),
        title: 'Notes'),
    _Row(
        icon: CupertinoIcons.checkmark_square_fill,
        color: Color(0xFF007AFF),
        title: 'Reminders'),
    _Row(
        icon: CupertinoIcons.book_fill,
        color: Color(0xFFFF9500),
        title: 'Books'),
  ]),
  _Section(header: 'System', rows: [
    _Row(
        icon: CupertinoIcons.settings,
        color: Color(0xFF8E8E93),
        title: 'Settings'),
    _Row(
        icon: CupertinoIcons.person_crop_circle_fill,
        color: Color(0xFF007AFF),
        title: 'Account',
        subtitle: 'iCloud, App Store'),
    _Row(
        icon: CupertinoIcons.lock_fill,
        color: Color(0xFF30D158),
        title: 'Privacy & Security'),
  ]),
];

// ─────────────────────────────────────────────────────────────────────────────
// Apple-style grouped section — solid fill, zero GPU cost during scroll
// ─────────────────────────────────────────────────────────────────────────────

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({required this.section});
  final _Section section;

  // Solid fill matching iOS 26 insetGrouped list appearance on dark backgrounds.
  static const _cellFill = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              section.header.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white.withValues(alpha: 0.4),
                letterSpacing: 0.8,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                for (int i = 0; i < section.rows.length; i++)
                  _buildRow(section.rows[i], i, section.rows.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_Row row, int index, int total) {
    final isLast = index == total - 1;
    return Container(
      color: _cellFill,
      child: Column(
        children: [
          CupertinoListTile(
            leading: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: row.color,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(row.icon, color: CupertinoColors.white, size: 17),
            ),
            title: Text(
              row.title,
              style: TextStyle(color: CupertinoColors.white, fontSize: 16),
            ),
            subtitle: row.subtitle != null
                ? Text(
                    row.subtitle!,
                    style: TextStyle(
                      color: CupertinoColors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  )
                : null,
            trailing: const CupertinoListTileChevron(),
            onTap: () {},
          ),
          if (!isLast)
            Container(
              height: 0.5,
              margin: EdgeInsets.only(left: 58),
              color: CupertinoColors.white.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }
}
