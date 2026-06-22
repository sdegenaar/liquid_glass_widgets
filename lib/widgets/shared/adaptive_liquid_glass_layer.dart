import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../theme/glass_theme_data.dart';
import '../../types/glass_quality.dart';
import '../../utils/glass_performance_monitor.dart';
import 'glass_isolation_scope.dart';
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
/// // With explicit settings:
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   quality: GlassQuality.premium,
///   shape: LiquidRoundedSuperellipse(borderRadius: 32),
///   blendAmount: 10.0, // Impeller-only
///   child: YourContent(),
/// )
///
/// // Or use theme (recommended):
/// AdaptiveLiquidGlassLayer(
///   child: YourContent(), // Uses GlassTheme settings automatically
/// )
/// ```
class AdaptiveLiquidGlassLayer extends StatelessWidget {
  const AdaptiveLiquidGlassLayer({
    required this.child,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 0),
    this.settings,
    this.quality,
    this.clipBehavior = Clip.antiAlias,
    this.clipExpansion = EdgeInsets.zero,
    this.blendAmount = 10.0,
    this.platformViewBackdrop = false,
    super.key,
  });

  /// The widget to display inside the glass layer.
  final Widget child;

  /// The shape of the glass background.
  final LiquidShape shape;

  /// Glass effect settings for the background.
  ///
  /// If null, uses settings from [GlassTheme] based on current brightness.
  final LiquidGlassSettings? settings;

  /// Rendering quality for the glass effect.
  ///
  /// If null, uses quality from [GlassTheme].
  final GlassQuality? quality;

  /// Clip behavior for the glass shape.
  final Clip clipBehavior;

  /// Expansion margin for the compositor clip rect to allow jelly physics to exceed bounds.
  final EdgeInsets clipExpansion;

  /// Blend amount for smooth glass transitions (Impeller-only).
  ///
  /// Higher values create smoother blending between overlapping glass elements.
  /// Only works on Impeller - ignored on Skia (like chromatic aberration).
  ///
  /// Defaults to 10.0.
  final double blendAmount;

  /// When true (typically for iOS PlatformViews), forces the fallback rendering
  /// path (BackdropFilter) instead of the Impeller-native shader.
  final bool platformViewBackdrop;

  /// Detects if Impeller rendering engine is active.
  static bool get _canUseImpeller => ui.ImageFilter.isShaderFilterSupported;

  @override
  Widget build(BuildContext context) {
    // Resolve settings: start with base defaults, apply theme partial override
    // (only non-null fields), then let explicit widget settings win entirely.
    final themeData = GlassThemeData.of(context);
    const baseSettings = LiquidGlassSettings();
    final themeOverride = themeData.settingsFor(context);
    final withTheme = themeOverride?.applyTo(baseSettings) ?? baseSettings;
    final effectiveSettings = settings ?? withTheme;
    final effectiveQuality =
        quality ?? themeData.qualityFor(context) ?? GlassQuality.standard;

    // ---- MINIMAL FAST-PATH --------------------------------------------------
    // GlassQuality.minimal skips LiquidGlassLayer entirely.
    //
    // IMPORTANT: The layer has no shape — it wraps the full bounds including
    // any padding around pill/circle children. Painting a BackdropFilter +
    // tinted Container here bleeds into that padding area, creating the dark
    // rectangle visible above/around the individual glass shapes.
    //
    // The correct approach matches how LiquidGlassLayer works in the normal
    // path: the layer is a TRANSPARENT compositng context. Glass tinting and
    // blur come entirely from the child AdaptiveGlass widgets, each of which
    // renders as _FrostedFallback with correct shape-aware clipping.
    //
    // In minimal mode there are no blend groups, so the layer is a true
    // pass-through — just InheritedLiquidGlass so descendants can read
    // settings and quality.
    // -------------------------------------------------------------------------
    if (effectiveQuality == GlassQuality.minimal) {
      return GlassIsolationScope(
        isolated: false,
        child: InheritedLiquidGlass(
          settings: effectiveSettings,
          quality: effectiveQuality,
          isBlurProvidedByAncestor: false,
          child: child,
        ),
      );
    }

    // Detect if we should use the full Impeller-native rendering pipeline
    final bool useFullRenderer = _canUseImpeller &&
        effectiveQuality == GlassQuality.premium &&
        !platformViewBackdrop;

    // Resolve shadow for SDF rendering. Shadows only apply in light mode.
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final List<BoxShadow> resolvedShadows =
        isDark ? const <BoxShadow>[] : effectiveSettings.effectiveShadow;

    // On Skia/Web, we want to provide a single BackdropFilter for the whole layer
    // to avoid each child doing its own expensive blur.
    Widget content = child;

    return PremiumGlassTracker(
      child: LiquidGlassLayer(
        settings: effectiveSettings,
        shadows: resolvedShadows,
        clipExpansion: clipExpansion,
        child: GlassIsolationScope(
          isolated: false,
          child: InheritedLiquidGlass(
            settings: effectiveSettings,
            quality: effectiveQuality,
            isBlurProvidedByAncestor:
                false, // Root never provides the blur; containers do.
            child: useFullRenderer
                ? LiquidGlassBlendGroup(
                    blend: blendAmount,
                    child: content,
                  )
                : content,
          ),
        ),
      ),
    );
  }
}
