/// Quality Comparison Demo — Premium vs Standard side-by-side
///
/// Renders GlassButton, GlassSegmentedControl, GlassCard, and GlassTabBar
/// with IDENTICAL [LiquidGlassSettings] at both quality levels so you can
/// directly compare how the thickness/light normalization affects each widget
/// on the Standard (2D lightweight shader) path.
///
/// Settings are deliberately higher than defaults (thickness: 28,
/// lightIntensity: 0.9) to make the normalization delta clearly visible.
///
/// Run standalone:
///   flutter run -t example/lib/demos/quality_comparison_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ── Premium fixed defaults (never changed) ───────────────────────────────────
const _kDefaultThickness       = 28.0;
const _kDefaultLightIntensity  = 0.9;
const _kDefaultBlur            = 3.0;
const _kDefaultAmbient         = 0.22;
const _kDefaultSaturation      = 1.2;
const _kDefaultRefractiveIndex = 1.25;

// ── Per-widget Standard preset defaults ───────────────────────────────────────
// lightweight_glass.frag shader uniform mapping:
//   opacity   → glassColor.alpha  (body density / translucency — MOST VISIBLE)
//   ambient   → ambientStrength   (multiplier on bgRgb in body layer, subtle)
//   glow      → glowIntensity     (additive brightness — very visible)
//   light     → lightIntensity    (rim specular brightness)
//   thickness → rim width
//   blur      → BackdropFilter frosting
// NOTE: uSaturation in this shader = HUE saturation (mix(luma,color,sat)).
//   For white/achromatic glass it has no effect, so we map opacity → glassColor.alpha instead.
// Tune these until Standard matches Premium, then report values.

const _kPillDefault = _Preset(     // Animated pill / indicator — tuned 2026-05-16
  // thickness→rimThickness (÷0.35 dampener → 0.35×1/0.35=0.35 rendered rim)
  // light→lightIntensity   (÷0.6  dampener → 0.60×1/0.6 =0.60 rendered spec)
  thickness: 1.0, opacity: 0.01, ambient: 0.07, glow: 0.50, light: 1.0, blur: 3.0,
);
const _kBtnDefault = _Preset(      // GlassButton — tuned 2026-05-16
  thickness: 17, opacity: 0.01, ambient: 0.07, glow: 0.75, light: 0.72, blur: 3.0,
);
const _kCardDefault = _Preset(     // GlassCard + tab bar surface — tuned 2026-05-16
  thickness: 19, opacity: 0.01, ambient: 0.07, glow: 0.75, light: 0.72, blur: 3.0,
);

// ── Entry point ───────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(
    // Recommended for production: auto-benchmarks the device and
    // degrades quality gracefully on weaker hardware.
    adaptiveQuality: true,
    child: const _App(),
  ));
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Quality Comparison',
      debugShowCheckedModeBanner: false,
      home: _ComparisonPage(),
    );
  }
}

// ── Demo page ─────────────────────────────────────────────────────────────────

class _ComparisonPage extends StatefulWidget {
  const _ComparisonPage();

  @override
  State<_ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<_ComparisonPage> {
  int _segIndex = 0;
  int _tabIndex = 0;
  bool _switchValue = false;
  double _sliderValue = 0.4;
  bool _backgroundSampling = true;

  // ── Live tuning panel ──────────────────────────────────────────────────
  bool _showTuning = false;

  // ── Per-widget Standard presets ──────────────────────────────────────
  // Premium is locked to fixed defaults and is NEVER modified by sliders.
  _Preset _pill = _kPillDefault;
  _Preset _btn  = _kBtnDefault;
  _Preset _card = _kCardDefault;

  /// Premium — fixed reference, NEVER modified by sliders.
  LiquidGlassSettings get _kGlass => const LiquidGlassSettings(
    glassColor: Colors.white12,
    blur: _kDefaultBlur,
    thickness: _kDefaultThickness,
    lightIntensity: _kDefaultLightIntensity,
    ambientStrength: _kDefaultAmbient,
    chromaticAberration: 0.02,
    refractiveIndex: _kDefaultRefractiveIndex,
    saturation: _kDefaultSaturation,
  );

  /// Standard pill / animated indicator settings.
  LiquidGlassSettings get _kGlassPill => _pill.toSettings();

  /// Standard button settings.
  LiquidGlassSettings get _kGlassBtn => _btn.toSettings();

  /// Standard card / surface settings (also used for tab bar background).
  LiquidGlassSettings get _kGlassCard => _card.toSettings();

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      enableBackgroundSampling: _backgroundSampling,
      background: Stack(
          fit: StackFit.expand,
          children: [
            // Background — mountain landscape gives good glass contrast
            Image.network(
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4'
              '?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1a2a4a),
                      Color(0xFF0d1b2a),
                      Color(0xFF162032)
                    ],
                  ),
                ),
              ),
            ),
            // Subtle dark veil for readability
            Container(color: Colors.black.withValues(alpha: 0.28)),
          ],
        ),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildColumnLabels(),
                const SizedBox(height: 4),
                // Live tuning panel — collapse when not needed
                _TuningPanel(
                  visible: _showTuning,
                  pill: _pill,
                  btn: _btn,
                  card: _card,
                  onPillChanged: (p) => setState(() => _pill = p),
                  onBtnChanged:  (p) => setState(() => _btn  = p),
                  onCardChanged: (p) => setState(() => _card = p),
                ),
                Expanded(child: _buildComparisonList()),
              ],
            ),
          ),
        ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Quality Comparison',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('BG Sample', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CupertinoSwitch(
                        value: _backgroundSampling,
                        onChanged: (v) => setState(() => _backgroundSampling = v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Tuning toggle
          GestureDetector(
            onTap: () => setState(() => _showTuning = !_showTuning),
            child: Text(
              _showTuning ? '▲ Hide tuning' : '▼ Tune settings',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'pill  th=${_pill.thickness.toStringAsFixed(1)} op=${_pill.opacity.toStringAsFixed(2)} amb=${_pill.ambient.toStringAsFixed(3)}\n'
            '      glow=${_pill.glow.toStringAsFixed(2)} li=${_pill.light.toStringAsFixed(2)} blur=${_pill.blur.toStringAsFixed(1)}',
            style: TextStyle(
              color: const Color(0xFF5AC8FA).withValues(alpha: 0.9),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'btn   th=${_btn.thickness.toStringAsFixed(0)} op=${_btn.opacity.toStringAsFixed(2)} amb=${_btn.ambient.toStringAsFixed(3)}\n'
            '      glow=${_btn.glow.toStringAsFixed(2)} li=${_btn.light.toStringAsFixed(2)} blur=${_btn.blur.toStringAsFixed(1)}',
            style: TextStyle(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.9),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'card  th=${_card.thickness.toStringAsFixed(0)} op=${_card.opacity.toStringAsFixed(2)} amb=${_card.ambient.toStringAsFixed(3)}\n'
            '      glow=${_card.glow.toStringAsFixed(2)} li=${_card.light.toStringAsFixed(2)} blur=${_card.blur.toStringAsFixed(1)}',
            style: TextStyle(
              color: const Color(0xFFBB86FC).withValues(alpha: 0.9),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ── Column labels ─────────────────────────────────────────────────────────

  Widget _buildColumnLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _QualityBadge(
              label: 'PREMIUM',
              subtitle: 'Impeller · 3D SDF',
              color: const Color(0xFFFFB830),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QualityBadge(
              label: 'STANDARD',
              subtitle: 'Skia/Web · 2D shader',
              color: const Color(0xFF5AC8FA),
            ),
          ),
        ],
      ),
    );
  }

  // ── Comparison list ───────────────────────────────────────────────────────

  Widget _buildComparisonList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        children: [
          // ── GlassButton ─────────────────────────────────────────────────
          _ComparisonRow(
            label: 'GlassButton',
            premium: GlassButton(
              useOwnLayer: true,
              settings: _kGlass,
              quality: GlassQuality.premium,
              onTap: () {},
              icon: const Icon(CupertinoIcons.play_arrow_solid),
              label: 'Press',
            ),
            standard: GlassButton(
              useOwnLayer: true,
              settings: _kGlassBtn,
              quality: GlassQuality.standard,
              onTap: () {},
              icon: const Icon(CupertinoIcons.play_arrow_solid),
              label: 'Press',
            ),
          ),

          const SizedBox(height: 20),

          // ── GlassSegmentedControl ────────────────────────────────────────
          _ComparisonRow(
            label: 'GlassSegmentedControl',
            premium: GlassSegmentedControl(
              useOwnLayer: true,
              glassSettings: _kGlass,
              indicatorSettings: _kGlass,
              quality: GlassQuality.premium,
              segments: const ['Day', 'Week', 'Month'],
              selectedIndex: _segIndex,
              onSegmentSelected: (i) => setState(() => _segIndex = i),
            ),
            standard: GlassSegmentedControl(
              useOwnLayer: true,
              glassSettings: _kGlassCard,    // surface / background
              indicatorSettings: _kGlassPill, // animated pill indicator
              quality: GlassQuality.standard,
              segments: const ['Day', 'Week', 'Month'],
              selectedIndex: _segIndex,
              onSegmentSelected: (i) => setState(() => _segIndex = i),
            ),
          ),

          const SizedBox(height: 20),

          // ── GlassCard ───────────────────────────────────────────────────
          _ComparisonRow(
            label: 'GlassCard',
            premium: GlassCard(
              useOwnLayer: true,
              settings: _kGlass,
              quality: GlassQuality.premium,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '3D bevel · specular\nreflection',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            standard: GlassCard(
              useOwnLayer: true,
              settings: _kGlassCard,
              quality: GlassQuality.standard,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2D rim · normalised\nthickness & light',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── GlassTabBar (full-width stacked) ─────────────────────────────
          _FullWidthRow(
            label: 'GlassTabBar',
            premiumWidget: GlassTabBar(
              useOwnLayer: true,
              settings: _kGlass,
              quality: GlassQuality.premium,
              tabs: [
                GlassTab(icon: const Icon(CupertinoIcons.home)),
                GlassTab(icon: const Icon(CupertinoIcons.search)),
                GlassTab(icon: const Icon(CupertinoIcons.person)),
              ],
              selectedIndex: _tabIndex,
              onTabSelected: (i) => setState(() => _tabIndex = i),
            ),
            standardWidget: GlassTabBar(
              useOwnLayer: true,
              settings: _kGlassCard,         // tab bar background glass
              indicatorSettings: _kGlassPill, // the pill indicator glass ← tuned here
              quality: GlassQuality.standard,
              tabs: [
                GlassTab(icon: const Icon(CupertinoIcons.home)),
                GlassTab(icon: const Icon(CupertinoIcons.search)),
                GlassTab(icon: const Icon(CupertinoIcons.person)),
              ],
              selectedIndex: _tabIndex,
              onTabSelected: (i) => setState(() => _tabIndex = i),
            ),
          ),

          const SizedBox(height: 20),

          // ── GlassSwitch ───────────────────────────────────────────────────
          _ComparisonRow(
            label: 'GlassSwitch',
            premium: GlassSwitch(
              value: _switchValue,
              quality: GlassQuality.premium,
              onChanged: (v) => setState(() => _switchValue = v),
            ),
            standard: GlassSwitch(
              value: _switchValue,
              quality: GlassQuality.standard,
              onChanged: (v) => setState(() => _switchValue = v),
            ),
          ),

          const SizedBox(height: 20),

          // ── GlassSlider ───────────────────────────────────────────────────
          _FullWidthRow(
            label: 'GlassSlider',
            premiumWidget: GlassSlider(
              value: _sliderValue,
              quality: GlassQuality.premium,
              onChanged: (v) => setState(() => _sliderValue = v),
            ),
            standardWidget: GlassSlider(
              value: _sliderValue,
              quality: GlassQuality.standard,
              onChanged: (v) => setState(() => _sliderValue = v),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

/// Column header badge showing quality tier name and renderer description.
class _QualityBadge extends StatelessWidget {
  const _QualityBadge({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side comparison row for widgets that fit in equal columns.
class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.premium,
    required this.standard,
  });

  final String label;
  final Widget premium;
  final Widget standard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(child: premium),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Center(child: standard),
            ),
          ],
        ),
      ],
    );
  }
}

/// Full-width stacked row for widgets like GlassTabBar that need the full width.
class _FullWidthRow extends StatelessWidget {
  const _FullWidthRow({
    required this.label,
    required this.premiumWidget,
    required this.standardWidget,
  });

  final String label;
  final Widget premiumWidget;
  final Widget standardWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Premium
        Row(
          children: [
            _QualityPill('PREMIUM', const Color(0xFFFFB830)),
            const SizedBox(width: 10),
            Expanded(child: premiumWidget),
          ],
        ),

        const SizedBox(height: 12),

        // Standard
        Row(
          children: [
            _QualityPill('STANDARD', const Color(0xFF5AC8FA)),
            const SizedBox(width: 10),
            Expanded(child: standardWidget),
          ],
        ),
      ],
    );
  }
}

/// Small vertical pill label for the full-width stacked rows.
class _QualityPill extends StatelessWidget {
  const _QualityPill(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Collapsible live tuning panel — 3 independent sections for pill, button, card.
/// Premium is LOCKED. Adjust Standard until it matches Premium, then report values.
class _TuningPanel extends StatelessWidget {
  const _TuningPanel({
    required this.visible,
    required this.pill,
    required this.btn,
    required this.card,
    required this.onPillChanged,
    required this.onBtnChanged,
    required this.onCardChanged,
  });

  final bool visible;
  final _Preset pill;
  final _Preset btn;
  final _Preset card;
  final ValueChanged<_Preset> onPillChanged;
  final ValueChanged<_Preset> onBtnChanged;
  final ValueChanged<_Preset> onCardChanged;

  static const _blue   = Color(0xFF5AC8FA);
  static const _green  = Color(0xFF4ADE80);
  static const _purple = Color(0xFFBB86FC);

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STANDARD ONLY  ·  Premium is locked',
            style: TextStyle(color: Colors.white38, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          const SizedBox(height: 2),
          const Text(
            'saturation → bgBoost  ·  ambient → lift  ·  glow → fresnel edge',
            style: TextStyle(color: Colors.white24, fontSize: 8, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          _PresetSection(label: '● PILL / INDICATOR', color: _blue,
              preset: pill, onChanged: onPillChanged,
              thicknessMin: 0.1, thicknessMax: 8.0,  // rim px (rimThickness)
              thicknessLabel: 'rim px'),
          const SizedBox(height: 8),
          _PresetSection(label: '● BUTTON', color: _green,
              preset: btn, onChanged: onBtnChanged,
              thicknessMin: 0.0, thicknessMax: 30.0), // uThickness
          const SizedBox(height: 8),
          _PresetSection(label: '● CARD / SURFACE', color: _purple,
              preset: card, onChanged: onCardChanged,
              thicknessMin: 0.0, thicknessMax: 30.0), // uThickness
        ],
      ),
    );
  }
}

/// One collapsible preset section inside _TuningPanel.
class _PresetSection extends StatefulWidget {
  const _PresetSection({
    required this.label,
    required this.color,
    required this.preset,
    required this.onChanged,
    this.thicknessMin = 0.0,
    this.thicknessMax = 30.0,
    this.thicknessLabel = 'thickness',
  });

  final String label;
  final Color color;
  final _Preset preset;
  final ValueChanged<_Preset> onChanged;
  final double thicknessMin;
  final double thicknessMax;
  final String thicknessLabel;

  @override
  State<_PresetSection> createState() => _PresetSectionState();
}

class _PresetSectionState extends State<_PresetSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final p = widget.preset;
    final c = widget.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text(widget.label,
                    style: TextStyle(color: c, fontSize: 9,
                        fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'th=${p.thickness.toStringAsFixed(0)} '
                    'op=${p.opacity.toStringAsFixed(2)} '
                    'amb=${p.ambient.toStringAsFixed(3)} '
                    'glow=${p.glow.toStringAsFixed(2)} '
                    'li=${p.light.toStringAsFixed(2)} '
                    'blur=${p.blur.toStringAsFixed(1)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.withValues(alpha: 0.6),
                        fontSize: 8, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 4),
                Text(_expanded ? '▲' : '▼',
                    style: TextStyle(color: c.withValues(alpha: 0.5), fontSize: 8)),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            _Slider(widget.thicknessLabel, p.thickness, widget.thicknessMin, widget.thicknessMax,
                (v) => widget.onChanged(p.copyWith(thickness: v)),  color: c),
            _Slider('opacity',    p.opacity,    0.01, 0.70,
                (v) => widget.onChanged(p.copyWith(opacity: v)),   color: c),
            _Slider('ambient',    p.ambient,    0.0, 0.35,
                (v) => widget.onChanged(p.copyWith(ambient: v)),    color: c),
            _Slider('glow',       p.glow,       0.0, 2.0,
                (v) => widget.onChanged(p.copyWith(glow: v)),       color: c),
            _Slider('light',      p.light,      0.0, 1.5,
                (v) => widget.onChanged(p.copyWith(light: v)),      color: c),
            _Slider('blur',       p.blur,       0.0, 12.0,
                (v) => widget.onChanged(p.copyWith(blur: v)),       color: c),
          ],
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider(this.label, this.value, this.min, this.max, this.onChanged,
      {this.color = Colors.white70});

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            '$label: ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: color.withValues(alpha: 0.5),
              inactiveTrackColor: color.withValues(alpha: 0.15),
              thumbColor: color,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ── _Preset data class ─────────────────────────────────────────────────────────

/// Immutable tuning preset for one Standard widget type.
///
/// Field mapping to [LiquidGlassSettings] / shader uniforms
/// (lightweight_glass.frag — Standard path only, Premium untouched):
///
/// | Preset field | Settings mapping            | Visible effect                |
/// |-------------|----------------------------|-------------------------------|
/// | opacity     | glassColor.alpha            | Body density (most impactful) |
/// | ambient     | ambientStrength             | Background bleed (subtle)     |
/// | glow        | glowIntensity               | Additive brightness           |
/// | light       | lightIntensity              | Rim specular brightness       |
/// | thickness   | thickness                   | Rim width                     |
/// | blur        | blur                        | BackdropFilter frosting       |
class _Preset {
  const _Preset({
    required this.thickness,
    required this.opacity,
    required this.ambient,
    required this.glow,
    required this.light,
    required this.blur,
  });

  final double thickness;
  final double opacity;   // → glassColor.alpha  (body density — MOST VISIBLE)
  final double ambient;   // → ambientStrength    (bgRgb multiplier, subtle)
  final double glow;      // → glowIntensity      (additive glow)
  final double light;     // → lightIntensity     (rim brightness)
  final double blur;      // → blur               (frosting)

  LiquidGlassSettings toSettings() => LiquidGlassSettings(
    glassColor: Colors.white.withValues(alpha: opacity.clamp(0.01, 1.0)),
    thickness: thickness,
    saturation: 1.08,   // Neutral — uSaturation is hue-sat in lightweight_glass.frag;
                        // has no effect on white glass, so fixed at 1.08.
    ambientStrength: ambient,
    glowIntensity: glow,
    lightIntensity: light,
    blur: blur,
    chromaticAberration: 0.02,
    refractiveIndex: _kDefaultRefractiveIndex,
  );

  _Preset copyWith({
    double? thickness,
    double? opacity,
    double? ambient,
    double? glow,
    double? light,
    double? blur,
  }) => _Preset(
    thickness: thickness ?? this.thickness,
    opacity:   opacity   ?? this.opacity,
    ambient:   ambient   ?? this.ambient,
    glow:      glow      ?? this.glow,
    light:     light     ?? this.light,
    blur:      blur      ?? this.blur,
  );
}

