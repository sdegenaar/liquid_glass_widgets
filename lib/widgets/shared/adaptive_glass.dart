import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../types/glass_quality.dart';
import 'lightweight_liquid_glass.dart';

/// Adaptive glass widget that intelligently chooses between premium and
/// lightweight shaders based on renderer capabilities.
///
/// **Fallback chain:**
/// 1. Premium quality + Impeller available → Full shader (best quality)
/// 2. Premium quality + Skia/web → Lightweight shader (our calibrated shader)
/// 3. Standard quality → Always lightweight shader
/// 4. If lightweight shader fails → FakeGlass (final fallback)
///
/// This ensures users never see FakeGlass unless absolutely necessary.
class AdaptiveGlass extends StatelessWidget {
  const AdaptiveGlass({
    required this.shape,
    required this.settings,
    required this.child,
    this.quality = GlassQuality.standard,
    this.useOwnLayer = true,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final LiquidShape shape;
  final LiquidGlassSettings settings;
  final Widget child;
  final GlassQuality quality;
  final bool useOwnLayer;
  final Clip clipBehavior;

  /// Detects if Impeller rendering engine is active.
  ///
  /// Returns true when shader filters are supported (Impeller),
  /// false when using Skia or web renderers.
  ///
  /// This is the same check used internally by liquid_glass_renderer.
  static bool get _canUseImpeller => ui.ImageFilter.isShaderFilterSupported;

  /// Static helper to render glass in a grouped context without creating a new layer.
  /// This is the adaptive replacement for [LiquidGlass.grouped].
  static Widget grouped({
    required LiquidShape shape,
    required Widget child,
    GlassQuality quality = GlassQuality.standard,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return AdaptiveGlass(
      shape: shape,
      settings: const LiquidGlassSettings(), // Inherited via inLayer
      quality: quality,
      useOwnLayer: false,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ARCHITECTURAL RULE:
    // If we are on Skia/Web, we CANNOT use LiquidGlass.grouped or withOwnLayer
    // because those will fall back to FakeGlass (solid color) inside the renderer.
    // We MUST use our LightweightLiquidGlass to get actual glass effects.

    final bool canUsePremiumShader =
        !kIsWeb && _canUseImpeller && quality == GlassQuality.premium;

    if (!canUsePremiumShader) {
      // Skia path or Standard path: Use our high-performance shader
      // Always use explicit settings to support animations (saturation, etc.)
      // Each widget gets its own shader instance on Skia - this is acceptable
      // performance-wise and necessary for per-widget animations
      return LightweightLiquidGlass(
        shape: shape,
        settings: settings,
        child: child,
      );
    }

    // Impeller + Premium Path: Use the renderer's native path
    if (useOwnLayer) {
      return LiquidGlass.withOwnLayer(
        shape: shape,
        settings: settings,
        fake: false,
        clipBehavior: clipBehavior,
        child: child,
      );
    } else {
      return LiquidGlass.grouped(
        shape: shape,
        clipBehavior: clipBehavior,
        child: child,
      );
    }
  }
}
