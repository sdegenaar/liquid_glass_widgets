/// GlassMenu Demo — all 9 alignment positions, adjustable item count,
/// scrollable overflow handling, and premium glass quality.
///
/// Run standalone:
///   flutter run -t example/lib/demos/glass_menu_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ── Glass settings matching the Apple Messages demo quality ──────────────────

const _kTriggerGlass = LiquidGlassSettings(
  glassColor: Colors.white10,
  thickness: 18,
  blur: 3,
  lightIntensity: 0.4,
  ambientStrength: 0.08,
  chromaticAberration: 0.01,
  refractiveIndex: 1.2,
  saturation: 1.15,
);

const _kMenuGlass = LiquidGlassSettings(
  glassColor: Colors.white12,
  thickness: 18,
  blur: 6,
  lightIntensity: 0.6,
  ambientStrength: 0.15,
  chromaticAberration: 0.0,
  refractiveIndex: 0.7,
  saturation: 1.2,
);

// ── App entry point ──────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(
    adaptiveQuality: true,
    child: const _App(),
  ));
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'GlassMenu Demo',
      debugShowCheckedModeBanner: false,
      home: _MenuDemoPage(),
    );
  }
}

// ── Demo screen ─────────────────────────────────────────────────────────────

class _MenuDemoPage extends StatefulWidget {
  const _MenuDemoPage();

  @override
  State<_MenuDemoPage> createState() => _MenuDemoPageState();
}

class _MenuDemoPageState extends State<_MenuDemoPage> {
  int _itemCount = 5;

  List<Widget> get _items => List.generate(
        _itemCount,
        (i) => GlassMenuItem(
          title: 'Option ${i + 1}',
          icon: const Icon(CupertinoIcons.star_fill),
          onTap: () => debugPrint('tapped ${i + 1}'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vibrant wallpaper so glass refraction is clearly visible
          Image.asset(
            'assets/wallpaper.jpg',
            fit: BoxFit.cover,
          ),

          // Dark scrim so the buttons are readable but glass still refracts
          Container(color: Colors.black.withValues(alpha: 0.25)),

          SafeArea(
            child: Column(
              children: [
                // ── Title ────────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'GlassMenu — All Alignments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                // ── Item count slider ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Items: $_itemCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _itemCount.toDouble(),
                          min: 1,
                          max: 20,
                          divisions: 19,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          onChanged: (v) =>
                              setState(() => _itemCount = v.round()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── 3×3 grid of menu triggers ─────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _row([
                          _Trigger(
                            label: '↖ TL',
                            alignment: GlassMenuAlignment.topLeft,
                            items: _items,
                            width: 52,
                            height: 52,
                            shape: const LiquidOval(),
                          ),
                          _Trigger(
                            label: '↑ TC',
                            alignment: GlassMenuAlignment.topCenter,
                            items: _items,
                            width: 96,
                            height: 40,
                          ),
                          _Trigger(
                            label: '↗ TR',
                            alignment: GlassMenuAlignment.topRight,
                            items: _items,
                            width: 52,
                            height: 52,
                            shape: const LiquidOval(),
                          ),
                        ]),
                        _row([
                          _Trigger(
                            label: '← CL',
                            alignment: GlassMenuAlignment.centerLeft,
                            items: _items,
                            width: 96,
                            height: 40,
                          ),
                          _Trigger(
                            label: '●',
                            alignment: GlassMenuAlignment.center,
                            items: _items,
                            width: 56,
                            height: 56,
                            shape: const LiquidOval(),
                          ),
                          _Trigger(
                            label: 'CR →',
                            alignment: GlassMenuAlignment.centerRight,
                            items: _items,
                            width: 96,
                            height: 40,
                          ),
                        ]),
                        _row([
                          _Trigger(
                            label: '↙ BL',
                            alignment: GlassMenuAlignment.bottomLeft,
                            items: _items,
                            width: 52,
                            height: 52,
                            shape: const LiquidOval(),
                          ),
                          _Trigger(
                            label: '↓ BC',
                            alignment: GlassMenuAlignment.bottomCenter,
                            items: _items,
                            width: 96,
                            height: 40,
                          ),
                          _Trigger(
                            label: '↘ BR',
                            alignment: GlassMenuAlignment.bottomRight,
                            items: _items,
                            width: 52,
                            height: 52,
                            shape: const LiquidOval(),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
}

// ── Trigger widget ───────────────────────────────────────────────────────────

class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.label,
    required this.alignment,
    required this.items,
    this.width = 96,
    this.height = 40,
    this.shape,
  });

  final String label;
  final GlassMenuAlignment alignment;
  final List<Widget> items;
  final double width;
  final double height;
  final LiquidShape? shape;

  @override
  Widget build(BuildContext context) {
    final effectiveShape = shape ??
        LiquidRoundedRectangle(borderRadius: height / 2);

    return GlassMenu(
      menuAlignment: alignment,
      autoAdjustToScreen: true,
      items: items,
      glassSettings: _kMenuGlass,
      quality: GlassQuality.premium,
      triggerBuilder: (ctx, toggle) => AdaptiveLiquidGlassLayer(
        child: GlassButton.custom(
          onTap: toggle,
          width: width,
          height: height,
          settings: _kTriggerGlass,
          quality: GlassQuality.premium,
          shape: effectiveShape,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
