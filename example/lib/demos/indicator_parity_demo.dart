/// Indicator Parity Demo
///
/// Shows all four [AnimatedGlassIndicator]-powered widgets side-by-side with
/// live tuning sliders so you can compare and calibrate iOS 26 parity:
///   • GlassSegmentedControl
///   • GlassTabBar
///   • GlassBottomBar
///   • GlassSearchableBottomBar
///
/// Run standalone:
///   flutter run -t example/lib/demos/indicator_parity_demo.dart
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
    return CupertinoApp(
      title: 'Indicator Parity',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(brightness: Brightness.dark),
      builder: (context, child) => Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: child!,
      ),
      home: const IndicatorParityDemoPage(),
    );
  }
}

// =============================================================================
// Main page
// =============================================================================

class IndicatorParityDemoPage extends StatefulWidget {
  const IndicatorParityDemoPage({super.key});

  @override
  State<IndicatorParityDemoPage> createState() =>
      _IndicatorParityDemoPageState();
}

class _IndicatorParityDemoPageState extends State<IndicatorParityDemoPage> {
  // ── Shared live tuning values ──────────────────────────────────────────────
  double _pinchStrength = 0.4;
  double _expansionH = 12.0;
  double _expansionV = 8.0;
  double _aberration = 0.15;
  // glassColor alpha — 0.0 = no tint (new default), 0.15 = old default
  double _glassTint = 0.0;

  // ── Per-widget state ───────────────────────────────────────────────────────
  int _segSelected = 0;
  int _tabSelected = 0;
  int _barSelected = 0;
  int _searchBarSelected = 0;
  bool _isSearching = false;

  // ── Tab/segment data ───────────────────────────────────────────────────────
  static const _segments = <GlassTab>[
    GlassTab(label: 'Journals'),
    GlassTab(label: 'Photos'),
    GlassTab(label: 'Clips')
  ];

  static const _tabs = [
    GlassTab(label: 'Featured', icon: Icon(CupertinoIcons.star_fill)),
    GlassTab(label: 'Browse', icon: Icon(CupertinoIcons.square_grid_2x2)),
    GlassTab(label: 'Charts', icon: Icon(CupertinoIcons.chart_bar_fill)),
    GlassTab(label: 'Radio', icon: Icon(CupertinoIcons.radiowaves_left)),
  ];

  static const _barTabs = [
    GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
    GlassTab(label: 'Discover', icon: Icon(CupertinoIcons.compass_fill)),
    GlassTab(label: 'Library', icon: Icon(CupertinoIcons.book_fill)),
    GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person_fill)),
  ];

  // ── Derived ────────────────────────────────────────────────────────────────

  /// Builds the shared indicatorSettings from the live sliders.
  /// Uses baseIndicatorSettings.copyWith so other base values (blur:0, etc.)
  /// are preserved — this is the merge-gap fix in action.
  LiquidGlassSettings get _indicatorSettings =>
      AnimatedGlassIndicator.baseIndicatorSettings.copyWith(
        chromaticAberration: _aberration,
        glassColor: Color.from(
          alpha: _glassTint,
          red: 1,
          green: 1,
          blue: 1,
        ),
      );

  EdgeInsets get _expansion =>
      EdgeInsets.symmetric(horizontal: _expansionH, vertical: _expansionV);

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Background — rich gradient so glass refraction is visible ─────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0D1A),
                  Color(0xFF0F1E3E),
                  Color(0xFF12103A),
                  Color(0xFF1B0A3E),
                ],
              ),
            ),
          ),
          // Decorative orbs — give the glass something colourful to refract.
          Positioned(
            top: 120,
            left: -60,
            child: _GlowOrb(color: const Color(0xFF5E3AFF), size: 220),
          ),
          Positioned(
            top: 300,
            right: -40,
            child: _GlowOrb(color: const Color(0xFF0A84FF), size: 180),
          ),
          Positioned(
            top: 520,
            left: 60,
            child: _GlowOrb(color: const Color(0xFFFF375F), size: 160),
          ),
          Positioned(
            top: 720,
            right: 20,
            child: _GlowOrb(color: const Color(0xFF30D158), size: 140),
          ),
          Positioned(
            top: 920,
            left: -30,
            child: _GlowOrb(color: const Color(0xFFFFD60A), size: 150),
          ),

          // ── Scrollable content ────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 240),
              children: [
                // Title
                const Text(
                  'Indicator Parity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'iOS 26 calibration — all four pill widgets, live tuning',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tuner panel ─────────────────────────────────────────────
                _TunerPanel(
                  pinchStrength: _pinchStrength,
                  expansionH: _expansionH,
                  expansionV: _expansionV,
                  aberration: _aberration,
                  glassTint: _glassTint,
                  onPinchChanged: (v) => setState(() => _pinchStrength = v),
                  onExpansionHChanged: (v) => setState(() => _expansionH = v),
                  onExpansionVChanged: (v) => setState(() => _expansionV = v),
                  onAberrationChanged: (v) => setState(() => _aberration = v),
                  onGlassTintChanged: (v) => setState(() => _glassTint = v),
                ),

                const SizedBox(height: 28),

                // ── GlassSegmentedControl ────────────────────────────────────
                _WidgetSection(
                  label: 'GlassSegmentedControl',
                  color: const Color(0xFF5E3AFF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: GlassSegmentedControl(
                      segments: _segments,
                      selectedIndex: _segSelected,
                      onSegmentSelected: (i) =>
                          setState(() => _segSelected = i),
                      quality: GlassQuality.premium,
                      indicatorPinchStrength: _pinchStrength,
                      indicatorExpansion: _expansion,
                      indicatorSettings: _indicatorSettings,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── GlassSegmentedControl ──────────────────────────────────────────────
                _WidgetSection(
                  label: 'GlassSegmentedControl',
                  color: const Color(0xFF0A84FF),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassSegmentedControl(
                      segments: _tabs,
                      selectedIndex: _tabSelected,
                      onSegmentSelected: (i) =>
                          setState(() => _tabSelected = i),
                      quality: GlassQuality.premium,
                      // height: 56 required for icon + label tabs.
                      // Default 44 is for icon-only or text-only.
                      height: 56,
                      // Full-pill radius — matches the bottom bars' rounded look.
                      borderRadius: 28,
                      iconSize: 20,
                      selectedTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      indicatorPinchStrength: _pinchStrength,
                      indicatorExpansion: _expansion,
                      indicatorSettings: _indicatorSettings,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── GlassBottomBar ───────────────────────────────────────────
                _WidgetSection(
                  label: 'GlassBottomBar',
                  color: const Color(0xFFFF375F),
                  child: GlassTabBar.bottom(
                    tabs: _barTabs,
                    selectedIndex: _barSelected,
                    onTabSelected: (i) => setState(() => _barSelected = i),
                    quality: GlassQuality.premium,
                    indicatorPinchStrength: _pinchStrength,
                    indicatorExpansion: _expansion,
                    // indicatorSettings: _indicatorSettings,
                  ),
                ),

                const SizedBox(height: 16),

                // ── GlassSearchableBottomBar ─────────────────────────────────
                _WidgetSection(
                  label: 'GlassSearchableBottomBar',
                  color: const Color(0xFF30D158),
                  child: GlassTabBar.searchable(
                    tabs: _barTabs,
                    selectedIndex: _searchBarSelected,
                    isSearchActive: _isSearching,
                    onTabSelected: (i) =>
                        setState(() => _searchBarSelected = i),
                    quality: GlassQuality.premium,
                    indicatorPinchStrength: _pinchStrength,
                    indicatorExpansion: _expansion,
                    indicatorSettings: _indicatorSettings,
                    searchConfig: GlassSearchBarConfig(
                      hintText: 'Search…',
                      showsCancelButton: true,
                      onSearchToggle: (v) => setState(() => _isSearching = v),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Live values badge ────────────────────────────────────────
                _LiveValuesBadge(
                  pinchStrength: _pinchStrength,
                  expansionH: _expansionH,
                  expansionV: _expansionV,
                  aberration: _aberration,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tuner panel — collapsible, default closed
// =============================================================================

class _TunerPanel extends StatefulWidget {
  const _TunerPanel({
    required this.pinchStrength,
    required this.expansionH,
    required this.expansionV,
    required this.aberration,
    required this.glassTint,
    required this.onPinchChanged,
    required this.onExpansionHChanged,
    required this.onExpansionVChanged,
    required this.onAberrationChanged,
    required this.onGlassTintChanged,
  });

  final double pinchStrength;
  final double expansionH;
  final double expansionV;
  final double aberration;
  final double glassTint;
  final ValueChanged<double> onPinchChanged;
  final ValueChanged<double> onExpansionHChanged;
  final ValueChanged<double> onExpansionVChanged;
  final ValueChanged<double> onAberrationChanged;
  final ValueChanged<double> onGlassTintChanged;

  @override
  State<_TunerPanel> createState() => _TunerPanelState();
}

class _TunerPanelState extends State<_TunerPanel> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !_isOpen ? () => setState(() => _isOpen = true) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isOpen
              ? Colors.white.withValues(alpha: 0.09)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isOpen
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row — always visible, tappable ─────────────────────
              GestureDetector(
                onTap: () => setState(() => _isOpen = !_isOpen),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.tuningfork,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'LIVE TUNER — applies to all four widgets',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      // Current values summary (visible when closed)
                      if (!_isOpen) ...[
                        _MiniValuePill(
                            label: 'P',
                            value: widget.pinchStrength.toStringAsFixed(1),
                            color: const Color(0xFF5E3AFF)),
                        const SizedBox(width: 4),
                        _MiniValuePill(
                            label: 'E',
                            value:
                                '${widget.expansionH.round()}×${widget.expansionV.round()}',
                            color: const Color(0xFF0A84FF)),
                      ],
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sliders — only when open ──────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: _isOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Color(0x22FFFFFF)),
                            const SizedBox(height: 10),
                            _SliderRow(
                              label: 'Pinch Strength',
                              value: widget.pinchStrength,
                              min: 0,
                              max: 1,
                              divisions: 20,
                              displayValue:
                                  widget.pinchStrength.toStringAsFixed(2),
                              accentColor: const Color(0xFF5E3AFF),
                              onChanged: widget.onPinchChanged,
                            ),
                            _SliderRow(
                              label: 'Expansion H',
                              value: widget.expansionH,
                              min: 0,
                              max: 28,
                              divisions: 28,
                              displayValue: '${widget.expansionH.round()} px',
                              accentColor: const Color(0xFF0A84FF),
                              onChanged: widget.onExpansionHChanged,
                            ),
                            _SliderRow(
                              label: 'Expansion V',
                              value: widget.expansionV,
                              min: 0,
                              max: 20,
                              divisions: 20,
                              displayValue: '${widget.expansionV.round()} px',
                              accentColor: const Color(0xFF0A84FF),
                              onChanged: widget.onExpansionVChanged,
                            ),
                            _SliderRow(
                              label: 'Chromatic Aberration',
                              value: widget.aberration,
                              min: 0,
                              max: 0.5,
                              divisions: 50,
                              displayValue:
                                  widget.aberration.toStringAsFixed(2),
                              accentColor: const Color(0xFFFF9F0A),
                              onChanged: widget.onAberrationChanged,
                            ),
                            _SliderRow(
                              label: 'Glass Tint (α)',
                              value: widget.glassTint,
                              min: 0,
                              max: 0.5,
                              divisions: 50,
                              displayValue: widget.glassTint.toStringAsFixed(2),
                              accentColor: const Color(0xFFBF5AF2),
                              onChanged: widget.onGlassTintChanged,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact pill showing a single tuning value in the collapsed tuner header.
class _MiniValuePill extends StatelessWidget {
  const _MiniValuePill(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label:$value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 30,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accentColor,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Widget section card
// =============================================================================

class _WidgetSection extends StatelessWidget {
  const _WidgetSection({
    required this.label,
    required this.color,
    required this.child,
  });

  final String label;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Preview card with colourful gradient so glass refracts visually
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior:
              Clip.none, // Allow jelly physics and glow to overshoot the card
          child: child,
        ),
      ],
    );
  }
}

// =============================================================================
// Live values summary badge
// =============================================================================

class _LiveValuesBadge extends StatelessWidget {
  const _LiveValuesBadge({
    required this.pinchStrength,
    required this.expansionH,
    required this.expansionV,
    required this.aberration,
  });

  final double pinchStrength;
  final double expansionH;
  final double expansionV;
  final double aberration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT CODE SNIPPET',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _buildSnippet(),
            style: const TextStyle(
              color: Color(0xFF9EF8A8), // code green
              fontSize: 11,
              fontFamily: 'Menlo',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSnippet() {
    final h = expansionH.round();
    final v = expansionV.round();
    final pinch = pinchStrength.toStringAsFixed(2);
    final aber = aberration.toStringAsFixed(2);
    return 'GlassTabBar.bottom(\n'
        '  indicatorPinchStrength: $pinch,\n'
        '  indicatorExpansion: EdgeInsets.symmetric(\n'
        '    horizontal: $h, vertical: $v,\n'
        '  ),\n'
        '  indicatorSettings:\n'
        '    AnimatedGlassIndicator.baseIndicatorSettings\n'
        '      .copyWith(chromaticAberration: $aber),\n'
        '  // Same params on all 4 widgets ↑\n'
        ')';
  }
}

// =============================================================================
// Glow orb — decorative background circle for refraction
// =============================================================================

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
