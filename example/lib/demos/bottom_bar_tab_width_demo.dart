/// Bottom bar widgets — tabWidth demo
///
/// Demonstrates how [GlassSearchableBottomBar.tabWidth] and
/// [GlassBottomBar.tabWidth] control the tab pill width on both bar variants.
///
/// Run standalone:
///   flutter run -t example/lib/demos/bottom_bar_tab_width_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const _DemoApp()));
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tabWidth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      ),
      home: const TabWidthDemoPage(),
    );
  }
}

// =============================================================================
// Home — interactive controls
// =============================================================================

class TabWidthDemoPage extends StatefulWidget {
  const TabWidthDemoPage({super.key});

  @override
  State<TabWidthDemoPage> createState() => _TabWidthDemoPageState();
}

// Which bar variant is being demonstrated
enum _BarVariant { searchable, standalone }

class _TabWidthDemoPageState extends State<TabWidthDemoPage> {
  // ── Controls ────────────────────────────────────────────────────────────────
  _BarVariant _variant = _BarVariant.searchable;
  int _tabCount = 2;
  double? _tabWidth; // null = expand (default)
  bool _searching = false;
  int _selected = 0;
  bool _showExtraButton = false; // only relevant for standalone bar

  static const _kWidths = <String, double?>{
    '72 px': 72.0,
    '88 px (iOS 26)': 88.0,
    '110 px': 110.0,
    'expand (null)': null,
  };

  static const _kCounts = [2, 3, 4, 5];

  List<GlassBottomBarTab> get _tabs => [
        const GlassBottomBarTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
        const GlassBottomBarTab(
            label: 'Browse', icon: Icon(CupertinoIcons.compass)),
        const GlassBottomBarTab(
            label: 'Library', icon: Icon(CupertinoIcons.book)),
        const GlassBottomBarTab(
            label: 'Radio', icon: Icon(CupertinoIcons.radiowaves_left)),
        const GlassBottomBarTab(
            label: 'Profile', icon: Icon(CupertinoIcons.person)),
      ].take(_tabCount).toList();

  @override
  Widget build(BuildContext context) {
    // Clamp selected index when tab count decreases
    final clampedSelected = _selected.clamp(0, _tabCount - 1);
    if (clampedSelected != _selected) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _selected = clampedSelected));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Background gradient ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                  Color(0xFF533483),
                ],
              ),
            ),
          ),

          // ── Controls panel ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'tabWidth Demo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controls the tab pill width on both bar variants',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bar variant selector
                  _SectionLabel('BAR VARIANT'),
                  const SizedBox(height: 8),
                  _ChipRow(
                    options: const ['Searchable', 'Standalone'],
                    selected: _variant.index,
                    onSelected: (i) => setState(() {
                      _variant = _BarVariant.values[i];
                      _searching = false;
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Tab count selector
                  _SectionLabel('TAB COUNT'),
                  const SizedBox(height: 8),
                  _ChipRow(
                    options: _kCounts.map((c) => '$c tabs').toList(),
                    selected: _kCounts.indexOf(_tabCount),
                    onSelected: (i) => setState(() => _tabCount = _kCounts[i]),
                  ),

                  const SizedBox(height: 16),

                  // tabWidth selector
                  _SectionLabel('TABWIDTH'),
                  const SizedBox(height: 8),
                  _ChipRow(
                    options: _kWidths.keys.toList(),
                    selected: _kWidths.values.toList().indexOf(_tabWidth),
                    onSelected: (i) => setState(
                        () => _tabWidth = _kWidths.values.elementAt(i)),
                  ),

                  // Extra button toggle (standalone only)
                  if (_variant == _BarVariant.standalone) ...[
                    const SizedBox(height: 16),
                    _SectionLabel('EXTRA BUTTON'),
                    const SizedBox(height: 8),
                    _ChipRow(
                      options: const ['None', 'Compose (+)'],
                      selected: _showExtraButton ? 1 : 0,
                      onSelected: (i) =>
                          setState(() => _showExtraButton = i == 1),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Live metrics
                  _MetricsCard(
                    tabCount: _tabCount,
                    tabWidth: _tabWidth,
                    variant: _variant,
                    hasExtraButton: _showExtraButton,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom bar ──────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _variant == _BarVariant.searchable
                ? GlassSearchableBottomBar(
                    tabs: _tabs,
                    selectedIndex: clampedSelected,
                    isSearchActive: _searching,
                    tabWidth: _tabWidth,
                    onTabSelected: (i) => setState(() {
                      _selected = i;
                      _searching = false;
                    }),
                    quality: GlassQuality.premium,
                    searchConfig: GlassSearchBarConfig(
                      hintText: 'Search',
                      showsCancelButton: true,
                      onSearchToggle: (v) => setState(() => _searching = v),
                    ),
                  )
                : GlassBottomBar(
                    tabs: _tabs,
                    selectedIndex: clampedSelected,
                    tabWidth: _tabWidth,
                    onTabSelected: (i) => setState(() => _selected = i),
                    quality: GlassQuality.premium,
                    extraButton: _showExtraButton
                        ? GlassBottomBarExtraButton(
                            icon: const Icon(CupertinoIcons.plus),
                            label: 'Compose',
                            onTap: () {},
                          )
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Metric card
// =============================================================================

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.tabCount,
    required this.tabWidth,
    required this.variant,
    required this.hasExtraButton,
  });

  final int tabCount;
  final double? tabWidth;
  final _BarVariant variant;
  final bool hasExtraButton;

  @override
  Widget build(BuildContext context) {
    final pillW = tabWidth != null ? tabWidth! * tabCount : null;
    final pillLabel = pillW != null
        ? '${pillW.toStringAsFixed(0)} px (${tabWidth!.toStringAsFixed(0)} × $tabCount)'
        : 'fills available space';

    final variantLabel = variant == _BarVariant.searchable
        ? 'GlassSearchableBottomBar'
        : 'GlassBottomBar';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow('Widget', variantLabel),
          const SizedBox(height: 8),
          _MetricRow(
              'tabWidth', tabWidth != null ? '$tabWidth px' : 'null (expand)'),
          const SizedBox(height: 8),
          _MetricRow('tabCount', '$tabCount'),
          const SizedBox(height: 8),
          _MetricRow('Pill width', pillLabel),
          if (variant == _BarVariant.standalone) ...[
            const SizedBox(height: 8),
            _MetricRow('Extra button', hasExtraButton ? 'Compose (+)' : 'none'),
          ],
          const SizedBox(height: 12),
          Text(
            tabWidth != null
                ? '✅ iOS 26 compact sizing — pill is proportional to tabs'
                : '⬛ Expand (default) — tab pill fills all available space',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared small widgets
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final active = i == selected;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF0A84FF)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              options[i],
              style: TextStyle(
                color:
                    active ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }),
    );
  }
}
