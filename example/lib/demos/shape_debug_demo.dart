/// Debug example for testing GlassButton shape and radius behavior.
///
/// This example demonstrates how different shapes and sizes render
/// with GlassButton, including the default LiquidOval, explicit
/// rounded rectangles, and superellipses.
///
/// To run: flutter run -t lib/repro_issue.dart
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const ShapeDebugApp()));
}

class ShapeDebugApp extends StatelessWidget {
  const ShapeDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const ShapeDebugPage(),
    );
  }
}

class ShapeDebugPage extends StatelessWidget {
  const ShapeDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
      ),
      child: Scaffold(
        body: AdaptiveLiquidGlassLayer(
          settings: RecommendedGlassSettings.standard,
          quality: GlassQuality.standard,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GlassButton Shape Debug',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verifying shape and radius behavior',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Default shape (LiquidOval)
                  const _SectionLabel('Default (LiquidOval)'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _IconButton(
                        icon: Icon(Icons.arrow_back_ios_new),
                        label: 'Back',
                      ),
                      _IconButton(
                          icon: Icon(Icons.favorite), label: 'Favorite'),
                      _IconButton(icon: Icon(Icons.share), label: 'Share'),
                      _IconButton(icon: Icon(Icons.close), label: 'Close'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Explicit shapes
                  const _SectionLabel('Explicit Shapes'),
                  const SizedBox(height: 10),
                  _ShapeRow(
                    shape: const LiquidRoundedRectangle(borderRadius: 20),
                    label: 'RoundedRect(20)',
                  ),
                  const SizedBox(height: 12),
                  _ShapeRow(
                    shape: const LiquidRoundedRectangle(borderRadius: 0),
                    label: 'RoundedRect(0)',
                  ),
                  const SizedBox(height: 12),
                  _ShapeRow(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                    label: 'Superellipse(12)',
                  ),
                  const SizedBox(height: 32),

                  // In a Stack (positioned layout)
                  const _SectionLabel('Stack + Positioned'),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Text(
                            'Content behind buttons',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 16,
                          child: _IconButton(
                            icon: Icon(Icons.arrow_back_ios_new),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 16,
                          child: _IconButton(icon: Icon(Icons.close)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Different sizes
                  const _SectionLabel('Different Sizes'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SizedButton(size: 32, iconSize: 14),
                      _SizedButton(size: 40, iconSize: 18),
                      _SizedButton(size: 56, iconSize: 24),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Reusable icon button (matches reporter's pattern)
// =============================================================================

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.label});

  final Widget icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final button = GlassButton(
      icon: icon,
      width: 40,
      height: 40,
      iconSize: 16,
      quality: GlassQuality.standard,
      iconColor: Colors.white,
      onTap: () {},
      glowColor: Colors.blue.withValues(alpha: 0.4),
    );

    if (label == null) return button;

    return Column(
      children: [
        button,
        const SizedBox(height: 8),
        Text(
          label!,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }
}

class _ShapeRow extends StatelessWidget {
  const _ShapeRow({required this.shape, required this.label});

  final LiquidShape shape;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassButton(
          icon: Icon(Icons.star),
          width: 40,
          height: 40,
          iconSize: 16,
          quality: GlassQuality.standard,
          iconColor: Colors.white,
          onTap: () {},
          glowColor: Colors.blue.withValues(alpha: 0.4),
          shape: shape,
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class _SizedButton extends StatelessWidget {
  const _SizedButton({required this.size, required this.iconSize});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassButton(
          icon: Icon(Icons.add),
          width: size,
          height: size,
          iconSize: iconSize,
          quality: GlassQuality.standard,
          iconColor: Colors.white,
          onTap: () {},
          glowColor: Colors.blue.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 8),
        Text(
          '${size.toInt()}px',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
