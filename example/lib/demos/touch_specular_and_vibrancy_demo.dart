import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Interactive demonstration of the v1.5.0 features:
/// 1. Shader-Level Touch Specular Highlight (GLSL isotropic contact highlight)
/// 2. Nested Glass Degradation via Vibrancy Fill (AdaptiveGlass.vibrancy)
/// 3. Continuous Menu Pointer Tracking (GlassMenu.glowOnTapOnly default: false)
class TouchSpecularAndVibrancyDemo extends StatefulWidget {
  const TouchSpecularAndVibrancyDemo({super.key});

  @override
  State<TouchSpecularAndVibrancyDemo> createState() =>
      _TouchSpecularAndVibrancyDemoState();
}

class _TouchSpecularAndVibrancyDemoState
    extends State<TouchSpecularAndVibrancyDemo> {
  // Specular settings
  double _lightIntensity = 0.8;
  double _thickness = 22.0;
  GlassSpecularSharpness _sharpness = GlassSpecularSharpness.medium;

  // Telemetry
  Offset _pointerPos = Offset.zero;
  bool _isPointerDown = false;

  // Theme
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    final settings = LiquidGlassSettings(
      thickness: _thickness,
      blur: 14,
      lightIntensity: _lightIntensity,
      specularSharpness: _sharpness,
      refractiveIndex: 1.25,
      glassColor: _isDark
          ? CupertinoColors.white.withValues(alpha: 0.12)
          : CupertinoColors.white.withValues(alpha: 0.28),
      ambientStrength: 0.15,
      chromaticAberration: 0.015,
    );

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('v1.5.0 Touch & Vibrancy'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _isDark = !_isDark),
          child: Icon(
            _isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
            size: 20,
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo or rich gradient
          Image.asset(
            'assets/wallpaper.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D0B18),
                    Color(0xFF1B1435),
                    Color(0xFF0F2B48),
                    Color(0xFF091224),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Theme tint scrim
          Container(
            color: _isDark
                ? CupertinoColors.black.withValues(alpha: 0.35)
                : CupertinoColors.white.withValues(alpha: 0.20),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildTouchSpecularSection(settings),
                const SizedBox(height: 24),
                _buildNestedVibrancySection(settings),
                const SizedBox(height: 24),
                _buildMenuTrackingSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0x33000000) : const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark ? const Color(0x22FFFFFF) : const Color(0x44000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'v1.5.0 RELEASE',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'iOS 26 Liquid Glass Parity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Demonstrating GPU-accelerated touch specular highlights, zero-overdraw nested vibrancy fills, and continuous menu drag tracking.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _isDark
                  ? CupertinoColors.systemGrey4
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchSpecularSection(LiquidGlassSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Touch-Driven Specular Highlight',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Drag across the glass surface. The GLSL shader calculates an isotropic specular reflection directly beneath your touch contact point.',
          style: TextStyle(
            fontSize: 12,
            color: _isDark
                ? CupertinoColors.systemGrey3
                : CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Glass Slab
        AdaptiveLiquidGlassLayer(
          settings: settings,
          child: Listener(
            onPointerDown: (e) => setState(() {
              _isPointerDown = true;
              _pointerPos = e.localPosition;
            }),
            onPointerMove: (e) => setState(() {
              _pointerPos = e.localPosition;
            }),
            onPointerUp: (_) => setState(() {
              _isPointerDown = false;
            }),
            onPointerCancel: (_) => setState(() {
              _isPointerDown = false;
            }),
            child: GlassGlow(
              glowRadius: 1.2,
              glowBlurRadius: 32,
              glowColor: CupertinoColors.white.withValues(alpha: 0.35),
              child: GlassContainer(
                height: 180,
                shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                settings: settings,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.sparkles,
                                color: _isPointerDown
                                    ? const Color(0xFF34C759)
                                    : CupertinoColors.systemGrey,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isPointerDown
                                    ? 'Contact Active'
                                    : 'Touch & Drag Surface',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _isPointerDown
                                      ? const Color(0xFF34C759)
                                      : (_isDark
                                          ? CupertinoColors.white
                                          : CupertinoColors.black),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? const Color(0x33000000)
                                  : const Color(0x44FFFFFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _isPointerDown
                                  ? 'X: ${_pointerPos.dx.toStringAsFixed(0)}, Y: ${_pointerPos.dy.toStringAsFixed(0)}'
                                  : 'Idle (Spring at rest)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Text(
                          _isPointerDown
                              ? 'GLSL Uniform 34..36 Tracking Touch'
                              : 'Place finger here and drag',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isDark
                                ? CupertinoColors.white.withValues(alpha: 0.8)
                                : CupertinoColors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Intensity: ${_lightIntensity.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            'Thickness: ${_thickness.toStringAsFixed(0)}px',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            'Sharpness: ${_sharpness.name}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Controls
        Row(
          children: [
            const Text('Light:', style: TextStyle(fontSize: 12)),
            Expanded(
              child: CupertinoSlider(
                value: _lightIntensity,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (v) => setState(() => _lightIntensity = v),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Depth:', style: TextStyle(fontSize: 12)),
            Expanded(
              child: CupertinoSlider(
                value: _thickness,
                min: 8.0,
                max: 45.0,
                divisions: 15,
                onChanged: (v) => setState(() => _thickness = v),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text('Sharpness: ', style: TextStyle(fontSize: 12)),
            CupertinoSegmentedControl<GlassSpecularSharpness>(
              groupValue: _sharpness,
              children: const {
                GlassSpecularSharpness.soft: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Soft', style: TextStyle(fontSize: 11)),
                ),
                GlassSpecularSharpness.medium: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Medium', style: TextStyle(fontSize: 11)),
                ),
                GlassSpecularSharpness.sharp: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Sharp', style: TextStyle(fontSize: 11)),
                ),
              },
              onValueChanged: (v) => setState(() => _sharpness = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNestedVibrancySection(LiquidGlassSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Nested Glass Vibrancy Fill',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'In iOS 26, nested glass avoids costly multi-pass recursive blurs. Child glass controls degrade into tinted vibrancy fills with rim highlights.',
          style: TextStyle(
            fontSize: 12,
            color: _isDark
                ? CupertinoColors.systemGrey3
                : CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),

        // Outer Root Glass Container
        GlassContainer(
          height: 220,
          settings: settings,
          shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Root Glass Surface (BackdropFilter Active)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '0 Overdraw Blurs',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Nested Card (Uses _VibrancyFill under the hood)
                GlassCard(
                  settings: settings,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.waveform_path_ecg,
                          color: Color(0xFF007AFF),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nested GlassCard (Vibrancy Fill)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Transparent tint + specular rim without second blur pass',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _isDark
                                      ? CupertinoColors.systemGrey2
                                      : CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Row of Nested Glass Buttons
                Row(
                  children: [
                    Expanded(
                      child: GlassButton.custom(
                        onTap: () {},
                        settings: settings,
                        shape: const LiquidRoundedRectangle(borderRadius: 12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.play_fill, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Resume',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton.custom(
                        onTap: () {},
                        settings: settings,
                        shape: const LiquidRoundedRectangle(borderRadius: 12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.slider_horizontal_3,
                                  size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Options',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTrackingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Continuous Menu Drag Tracking',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Open the menu and drag your finger across the items. In v1.5.0, glowOnTapOnly defaults to false so the specular glow follows your finger.',
          style: TextStyle(
            fontSize: 12,
            color: _isDark
                ? CupertinoColors.systemGrey3
                : CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GlassMenu(
            menuAlignment: GlassMenuAlignment.bottomCenter,
            autoAdjustToScreen: true,
            // Uses default glowOnTapOnly: false (1.5.0 tracking)
            items: [
              GlassMenuItem(
                title: 'Option 1 — First Item',
                icon: const Icon(CupertinoIcons.star_fill),
                onTap: () {},
              ),
              GlassMenuItem(
                title: 'Option 2 — Drag to Me',
                icon: const Icon(CupertinoIcons.hand_draw_fill),
                onTap: () {},
              ),
              GlassMenuItem(
                title: 'Option 3 — Glow Persists',
                icon: const Icon(CupertinoIcons.sparkles),
                onTap: () {},
              ),
              const GlassMenuDivider(),
              GlassMenuItem(
                title: 'Cancel Action',
                isDestructive: true,
                icon: const Icon(CupertinoIcons.xmark_circle),
                onTap: () {},
              ),
            ],
            triggerBuilder: (ctx, toggle) => GlassButton.custom(
              onTap: toggle,
              width: 220,
              height: 44,
              shape: const LiquidRoundedRectangle(borderRadius: 22),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.line_horizontal_3_decrease, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Open Interactive Menu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
