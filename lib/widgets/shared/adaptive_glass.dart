import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../types/glass_quality.dart';
import 'lightweight_liquid_glass.dart';
import 'inherited_liquid_glass.dart';

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
    this.allowElevation = true,
    this.glowIntensity = 0.0,
    super.key,
  });

  final LiquidShape shape;
  final LiquidGlassSettings settings;
  final Widget child;
  final GlassQuality quality;
  final bool useOwnLayer;
  final Clip clipBehavior;

  /// Whether to allow "Specular Elevation" when in a grouped context.
  /// Should be true for interactive objects (buttons) and false for layers/containers.
  final bool allowElevation;

  /// Interactive glow intensity for Skia/Web (0.0-1.0).
  ///
  /// On Impeller, this is ignored and [GlassGlow] widget is used instead.
  /// On Skia/Web, this controls shader-based button press feedback.
  ///
  /// Defaults to 0.0 (no glow).
  final double glowIntensity;

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
    double glowIntensity = 0.0,
  }) {
    return AdaptiveGlass(
      shape: shape,
      settings: const LiquidGlassSettings(), // Inherited via inLayer
      quality: quality,
      useOwnLayer: false,
      clipBehavior: clipBehavior,
      glowIntensity: glowIntensity,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we are on Skia/Web, we CANNOT use LiquidGlass.grouped or withOwnLayer
    // because those will fall back to FakeGlass (solid color) inside the renderer.
    // We MUST use our LightweightLiquidGlass to get actual glass effects.

    final bool canUsePremiumShader =
        !kIsWeb && _canUseImpeller && quality == GlassQuality.premium;

    if (!canUsePremiumShader) {
      // 1. Detect Grouped Elevation
      // When a parent provides the blur (Batch-Blur Optimization), we lose the
      // "double-darkening" effect of nested blurs. We compensate with the
      // densityFactor parameter (0.0-1.0) which triggers synthetic density physics
      // in the shader to make elevated widgets "pop" against the background.
      final inherited =
          context.dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>();
      final bool shouldElevate =
          allowElevation && (inherited?.isBlurProvidedByAncestor ?? false);

      // Calculate density factor for shader (0.0 = normal, 1.0 = elevated)
      final double densityFactor = shouldElevate ? 1.0 : 0.0;

      // Apply subtle elevation boost to settings (preserves saturation!)
      final color = settings.effectiveGlassColor;
      final effectiveSettings = shouldElevate
          ? LiquidGlassSettings(
              glassColor:
                  color.withValues(alpha: (color.a + 0.2).clamp(0.0, 1.0)),
              refractiveIndex: settings.refractiveIndex,
              thickness: settings.effectiveThickness,
              lightAngle: settings.lightAngle,
              lightIntensity:
                  (settings.effectiveLightIntensity * 1.2).clamp(0.0, 10.0),
              chromaticAberration: settings.chromaticAberration,
              blur: settings.effectiveBlur,
              visibility: settings.visibility,
              saturation:
                  settings.effectiveSaturation, // Preserve user saturation!
              ambientStrength:
                  (settings.effectiveAmbientStrength * 0.4).clamp(0.0, 1.0),
            )
          : settings;

      // PIPELINE HAND-OFF (The Secret Sauce)
      // If this is a container (allowElevation=false), we are providing a blur
      // for all our children to use. We update the InheritedLiquidGlass tree.
      if (!allowElevation) {
        return LightweightLiquidGlass(
          shape: shape,
          settings: effectiveSettings,
          densityFactor: 0.0, // Containers are never elevated
          glowIntensity: 0.0, // Containers don't glow
          child: InheritedLiquidGlass(
            settings: effectiveSettings,
            quality: quality,
            isBlurProvidedByAncestor: true,
            child: child,
          ),
        );
      }

      return LightweightLiquidGlass(
        shape: shape,
        settings: effectiveSettings,
        densityFactor: densityFactor, // 0.0 or 1.0 based on elevation
        glowIntensity: glowIntensity, // Pass through from button animation
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
