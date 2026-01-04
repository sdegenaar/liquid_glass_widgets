import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import 'inherited_liquid_glass.dart';

/// An adaptive liquid glass layer that provides a glass background with proper
/// fallback handling across all platforms.
///
/// This is a custom replacement for `LiquidGlassLayer` that uses `AdaptiveGlass`
/// for rendering, ensuring the background uses the lightweight shader on web/Skia
/// instead of falling back to FakeGlass.
///
/// **Fallback chain for background:**
/// - Premium + Impeller → Full shader (best quality) + blending support
/// - Premium + Skia/web → Lightweight shader (not FakeGlass!)
/// - Standard → Lightweight shader
///
/// **Blending:**
/// - `blendAmount` parameter only works on Impeller (requires full renderer)
/// - On Skia, blending is ignored (widgets render separately)
/// - This matches chromatic aberration behavior (Impeller-only features)
///
/// **Usage:**
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   quality: GlassQuality.premium,
///   shape: LiquidRoundedSuperellipse(borderRadius: 32),
///   blendAmount: 10.0, // Impeller-only
///   child: YourContent(),
/// )
/// ```
class AdaptiveLiquidGlassLayer extends StatelessWidget {
  const AdaptiveLiquidGlassLayer({
    required this.child,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 0),
    this.settings = const LiquidGlassSettings(),
    this.quality = GlassQuality.standard,
    this.clipBehavior = Clip.antiAlias,
    this.blendAmount = 10.0,
    super.key,
  });

  /// The widget to display inside the glass layer.
  final Widget child;

  /// The shape of the glass background.
  final LiquidShape shape;

  /// Glass effect settings for the background.
  final LiquidGlassSettings settings;

  /// Rendering quality for the glass effect.
  final GlassQuality quality;

  /// Clip behavior for the glass shape.
  final Clip clipBehavior;

  /// Blend amount for smooth glass transitions (Impeller-only).
  ///
  /// Higher values create smoother blending between overlapping glass elements.
  /// Only works on Impeller - ignored on Skia (like chromatic aberration).
  ///
  /// Defaults to 10.0.
  final double blendAmount;

  /// Detects if Impeller rendering engine is active.
  static bool get _canUseImpeller => ui.ImageFilter.isShaderFilterSupported;

  @override
  Widget build(BuildContext context) {
    // Detect if we should use the full Impeller-native rendering pipeline
    final bool useFullRenderer =
        _canUseImpeller && quality == GlassQuality.premium;

    // Root Provider: Always exists to satisfy assertions for grouped widgets.
    // When fake is true, it provides the InheritedWidget scope without enabling
    // the heavy backdrop-texture based rendering logic.
    return LiquidGlassLayer(
      settings: settings,
      fake: !useFullRenderer,
      child: InheritedLiquidGlass(
        settings: settings,
        child: useFullRenderer
            ? LiquidGlassBlendGroup(
                blend: blendAmount,
                child: child,
              )
            : child, // On Skia/web, children use LightweightLiquidGlass directly
      ),
    );
  }
}
