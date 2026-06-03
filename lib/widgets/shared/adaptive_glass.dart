import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../types/glass_quality.dart';
import '../../utils/glass_performance_monitor.dart';
import 'glass_accessibility_scope.dart';
import 'glass_isolation_scope.dart';
import 'lightweight_liquid_glass.dart';
import 'inherited_liquid_glass.dart';

/// A renderer-agnostic glass surface that intelligently selects the best
/// rendering path based on [GlassQuality] and the active Flutter renderer.
///
/// **Fallback chain:**
/// 1. Premium quality + Impeller available → Full shader (best quality)
/// 2. Premium quality + Skia/web → Lightweight shader (our calibrated shader)
/// 3. Standard quality → Always lightweight shader
/// 4. If lightweight shader fails → FakeGlass (final fallback)
///
/// Prefer this over [LiquidGlass] directly: [LiquidGlass] is Impeller-only
/// and silently renders nothing on Skia/Web.
///
/// Example:
/// ```dart
/// AdaptiveGlass(
///   shape: LiquidRoundedSuperellipse(borderRadius: 20),
///   settings: LiquidGlassSettings(blur: 8),
///   child: Text('Hello glass'),
/// )
/// ```
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
    this.isInteractive = false,
    super.key,
  });

  /// The shape that defines the outline and clipping path of the glass surface.
  final LiquidShape shape;

  /// Visual parameters for the glass effect (blur radius, tint, specular etc.).
  final LiquidGlassSettings settings;

  /// The widget displayed inside the glass surface.
  final Widget child;

  /// Controls render fidelity. Defaults to [GlassQuality.standard].
  ///
  /// [GlassQuality.premium] enables the full shader pipeline with specular
  /// reflections and dynamic refraction.
  /// [GlassQuality.minimal] always renders the frosted fallback, avoiding the
  /// shader entirely (useful during animations or on low-end devices).
  final GlassQuality quality;

  /// If `true`, wraps the glass layer in a [RepaintBoundary] (own compositing
  /// layer). This can improve performance when the glass surface moves
  /// independently of the rest of the widget tree, at the cost of extra GPU
  /// memory. Defaults to `true`.
  final bool useOwnLayer;

  /// How to clip the child widget to the [shape] boundary.
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  /// When `true`, optimises the frosted fallback for surfaces that update their
  /// layout bounds frequently (e.g. spring-animated buttons). Omits the
  /// [BackdropFilter] on [GlassQuality.minimal] to avoid compositor flicker.
  final bool isInteractive;

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
  /// This is the adaptive replacement for [LiquidGlass.withOwnLayer].
  static Widget grouped({
    required LiquidShape shape,
    required Widget child,
    GlassQuality quality = GlassQuality.standard,
    Clip clipBehavior = Clip.antiAlias,
    double glowIntensity = 0.0,
    bool isInteractive = false,
  }) {
    return AdaptiveGlass(
      shape: shape,
      settings: const LiquidGlassSettings(), // Inherited via inLayer
      quality: quality,
      useOwnLayer: false,
      clipBehavior: clipBehavior,
      glowIntensity: glowIntensity,
      isInteractive: isInteractive,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Resolve Settings
    // In grouped mode, the explicit `settings` field is a const placeholder;
    // we must inherit the real settings from the ancestor layer.
    final inherited =
        context.dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>();
    final baseSettings =
        (!useOwnLayer && inherited != null) ? inherited.settings : settings;

    // ---- MINIMAL FAST-PATH ---------------------------------------------------
    // GlassQuality.minimal bypasses all custom shaders. Renders via
    // _FrostedFallback: ClipPath(ShapeBorderClipper) + BackdropFilter + tint.
    // ClipPath correctly clips ALL shape types (oval, superellipse, rect).
    // Zero fragment shader cost on any device.
    // --------------------------------------------------------------------------
    if (quality == GlassQuality.minimal || baseSettings.effectiveBlur == 0) {
      return _FrostedFallback(
        shape: shape,
        settings: baseSettings,
        clipBehavior: clipBehavior,
        glowIntensity: glowIntensity,
        isAccessibilityFallback: false,
        isInteractive: isInteractive,
        child: child,
      );
    }

    // ---- IP1: ACCESSIBILITY FAST-PATH ----------------------------------------
    // iOS 26 glass degrades to a solid frosted panel when "Reduce Transparency"
    // is enabled. We honour the equivalent Flutter signal (highContrast, which
    // is the closest available platform proxy for isReduceTransparencyEnabled).
    //
    // When triggered, the entire glass shader pipeline is bypassed. The fallback
    // is a ClipRRect + BackdropFilter(blur) + semi-opaque tinted container —
    // still visually layered, but with no refraction, no specular, and no
    // chromatic aberration. Zero GPU shader cost.
    //
    // GlassAccessibilityScope must be in the widget tree for this to activate;
    // without it, defaults.reduceTransparency = false and we proceed normally.
    // --------------------------------------------------------------------------
    final accessibilityData = GlassAccessibilityData.of(context);
    if (accessibilityData.reduceTransparency) {
      return _FrostedFallback(
        shape: shape,
        settings: baseSettings,
        clipBehavior: clipBehavior,
        glowIntensity: glowIntensity,
        isAccessibilityFallback: true,
        isInteractive: isInteractive,
        child: child,
      );
    }

    // If we are on Skia/Web, we CANNOT use LiquidGlass.withOwnLayer or withOwnLayer
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
      final bool shouldElevate =
          allowElevation && (inherited?.isBlurProvidedByAncestor ?? false);

      // Calculate density factor for shader (0.0 = normal, 1.0 = elevated)
      final double densityFactor = shouldElevate ? 1.0 : 0.0;

      // Normalise settings for the 2D lightweight shader to prevent it from looking
      // overpowering when the user has tuned their settings for the 3D premium shader.
      //
      // BYPASS: When quality is explicitly GlassQuality.standard, the settings
      // are already calibrated for the Standard renderer — skip normalization.
      // Normalization only makes sense when adapting Premium-tuned settings to
      // Standard; if the caller already knows they're on Standard, their values
      // must be passed through unchanged so tuning sliders take full effect.
      final bool skipNormalization = quality == GlassQuality.standard;

      final LiquidGlassSettings normalizedSettings;
      if (skipNormalization) {
        normalizedSettings = baseSettings.copyWith(
          glassColor: baseSettings.glassColor.withValues(
            alpha: (baseSettings.glassColor.a *
                    baseSettings.standardOpacityMultiplier)
                .clamp(0.0, 1.0),
          ),
        );
      } else {
        // Frosting normalization: adapts Premium settings for the 2D shader.
        // Thickness scaled down (2D inner shadows look much thicker than 3D bevels).
        // Light intensity scaled down (2D gradients look brighter than 3D speculars).
        normalizedSettings = baseSettings.copyWith(
          thickness: (baseSettings.effectiveThickness * 0.4)
              .clamp(0.0, double.infinity),
          lightIntensity:
              (baseSettings.effectiveLightIntensity * 0.6).clamp(0.0, 10.0),
          glassColor: baseSettings.glassColor.withValues(
            alpha: (baseSettings.glassColor.a *
                    baseSettings.standardOpacityMultiplier)
                .clamp(0.0, 1.0),
          ),
        );
      }

      // Apply subtle elevation boost to settings (preserves saturation!)
      final color = normalizedSettings.effectiveGlassColor;
      final effectiveSettings = shouldElevate
          ? LiquidGlassSettings(
              glassColor:
                  color, // Removed flat +0.2 alpha boost for predictability
              refractiveIndex: normalizedSettings.refractiveIndex,
              thickness: normalizedSettings.effectiveThickness,
              lightAngle: normalizedSettings.lightAngle,
              lightIntensity: (normalizedSettings.effectiveLightIntensity * 1.2)
                  .clamp(0.0, 10.0),
              chromaticAberration: normalizedSettings.chromaticAberration,
              blur: normalizedSettings.effectiveBlur,
              visibility: normalizedSettings.visibility,
              saturation: normalizedSettings.effectiveSaturation,
              ambientStrength:
                  (normalizedSettings.effectiveAmbientStrength * 0.4)
                      .clamp(0.0, 1.0),
              glowIntensity: normalizedSettings.glowIntensity,
            )
          : normalizedSettings;

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

      // Elevated widgets use PATH B (no backgroundKey). They composite via
      // SrcOver against the container's output.
      final Widget lightweightWidget = LightweightLiquidGlass(
        shape: shape,
        settings: effectiveSettings,
        densityFactor: densityFactor, // 0.0 or 1.0 based on elevation
        glowIntensity:
            glowIntensity * 0.35, // Normalise additive glow to match Impeller
        child: child,
      );

      return lightweightWidget;
    }

    // Impeller + Premium Path: Use the renderer's native path.
    // Wrap in PremiumGlassTracker so GlassPerformanceMonitor can correlate
    // slow raster frames with active premium surfaces.
    //
    // Force useOwnLayer when inside a GlassIsolationScope (e.g. GlassScaffold
    // bottom bar). This gives bars their own compositing layer so body glass
    // cards don't composite over bar buttons.
    //
    // NOTE: isInteractive is NOT included here. It only controls
    // RepaintBoundary wrapping (lines below). Including it would force
    // every GlassButton into its own compositing layer, breaking grouped
    // rendering inside bars (e.g. BottomBarExtraBtn must blend with the
    // tab pill, not render as a separate glass surface). Buttons that need
    // independent refraction should set useOwnLayer: true explicitly.
    //
    // De-isolate children of the own-layer so nested glass (e.g. tab
    // items inside a bottom bar) groups with this layer rather than
    // creating additional own-layers (which would cause double-glass).
    final effectiveUseOwnLayer =
        useOwnLayer || GlassIsolationScope.isIsolated(context);

    if (effectiveUseOwnLayer) {
      Widget premium = LiquidGlass.withOwnLayer(
        shape: shape,
        settings: settings,
        clipBehavior: clipBehavior,
        // De-isolate children so nested glass groups with this own-layer
        // rather than creating its own (which causes double-glass).
        // Carry the parent's defaultQuality through so quality hints
        // (e.g. premium for bars) are preserved even when de-isolated.
        child: GlassIsolationScope(
          isolated: false,
          defaultQuality: GlassIsolationScope.defaultQualityOf(context),
          child: child,
        ),
      );

      return PremiumGlassTracker(
        child: premium,
      );
    } else {
      // Grouped elements (e.g. inside GlassBottomBar) rely on the ancestor's
      // LiquidGlassLayer to provide the RepaintBoundary and BackdropGroup.
      return PremiumGlassTracker(
        child: LiquidGlass.grouped(
          shape: shape,
          clipBehavior: clipBehavior,
          child: child,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// _FrostedFallback — shader-free glass fallback surface
//
// Used by:
//   • GlassQuality.minimal      — developer-requested safe mode
//   • GlassAccessibilityScope   — OS Reduce Transparency preference
//
// Visual quality parity with upstream FakeGlass (whynotmake.it):
//   • BackdropFilter blur  — same sigma as the normal glass blur
//   • Saturation matrix    — Rec. 709 luma-coefficient ColorFilter
//   • Specular rim         — two Canvas strokes with a light-angle linear
//                            gradient (pure srcOver — no GPU readback)
//   • Shape clipping       — ClipRRect for rect/squircle, or ClipOval
//
// No GLSL shaders. No FragmentShader. No Impeller-specific paths.
// Runs identically on Skia, Impeller, Web, Windows, and Linux.
// ---------------------------------------------------------------------------
class _FrostedFallback extends StatelessWidget {
  const _FrostedFallback({
    required this.shape,
    required this.settings,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
    this.glowIntensity = 0.0,
    this.isAccessibilityFallback = false,
    this.isInteractive = false,
  });

  final LiquidShape shape;
  final LiquidGlassSettings settings;
  final Widget child;
  final Clip clipBehavior;
  final double glowIntensity;

  /// When true (OS Reduce Transparency), opacity is boosted for legibility:
  /// alpha = (tint.a × 0.5 + 0.40).clamp(0.40, 0.80).
  ///
  /// When false (GlassQuality.minimal — developer choice), the glass color
  /// alpha is used more directly so the surface stays translucent:
  /// alpha = tint.a.clamp(0.05, 0.55).
  final bool isAccessibilityFallback;

  /// Signals that this surface frequently updates its layout bounds or transform
  /// via spring animations (e.g. GlassButton, interactive pill indicators).
  ///
  /// When true, during [GlassQuality.minimal] we omit the [BackdropFilter] to
  /// prevent compositor desync flicker caused by the bounds changing continuously.
  final bool isInteractive;

  /// Rec. 709 saturation matrix — identical to upstream FakeGlass.
  ///
  /// saturation = 0  → grayscale
  /// saturation = 1  → unchanged
  /// saturation > 1  → over-saturated (default glass is 1.5)
  static List<double> _saturationMatrix(double saturation) {
    const lumR = 0.299;
    const lumG = 0.587;
    const lumB = 0.114;
    final s = saturation;
    final inv = 1.0 - s;
    return [
      lumR * inv + s, lumG * inv, lumB * inv, 0, 0, // R
      lumR * inv, lumG * inv + s, lumB * inv, 0, 0, // G
      lumR * inv, lumG * inv, lumB * inv + s, 0, 0, // B
      0, 0, 0, 1, 0, // A
    ];
  }

  @override
  Widget build(BuildContext context) {
    final blur = settings.effectiveBlur.clamp(0.0, 40.0);
    final tint = settings.effectiveGlassColor;

    final double frostedAlpha = isAccessibilityFallback
        // Accessibility: boost opacity so content remains legible
        // even when Reduce Transparency removes blur on older hardware.
        ? (tint.a * 0.5 + 0.40).clamp(0.40, 0.80)
        // Minimal (developer choice): honour the specified glass color alpha,
        // allowing it to go up to 1.0 for solid color modes.
        : tint.a.clamp(0.05, 1.0);
    final frostedColor = tint.withValues(alpha: frostedAlpha);

    final sat = settings.effectiveSaturation;
    final bool needsSaturation = (sat - 1.0).abs() > 0.01;

    // ── Layer stack (bottom to top) ─────────────────────────────────────────
    //
    // Accessibility fallback: opacity heavily boosted for legibility (Reduce
    // Transparency intent — less see-through = more readable).
    //
    // Minimal developer mode: alpha is used more directly (honours the
    // developer's specified glassColor), giving a lighter, more translucent
    // surface.
    //
    // BackdropFilter rules:
    // - Always used in accessibility mode to ensure strong contrast.
    // - In minimal mode, used for STATIONARY surfaces (app bar, bottom bar)
    //   to retain the frosted glass aesthetic.
    // - OMITTED for INTERACTIVE surfaces (buttons, sliding pills) in minimal
    //   mode because BackdropFilter re-samples the background every frame and
    //   desyncs with spring bounds changes, causing a "flashing" or flickering
    //   artifact beneath the element.
    // ────────────────────────────────────────────────────────────────────────
    final bool useBlur =
        (isAccessibilityFallback || !isInteractive) && blur > 0;

    Widget body;
    if (useBlur) {
      body = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(color: frostedColor),
          child: needsSaturation
              ? BackdropFilter(
                  filter: ui.ColorFilter.matrix(_saturationMatrix(sat)),
                  child: const SizedBox.expand(),
                )
              : const SizedBox.expand(),
        ),
      );
    } else {
      // Minimal interactive path: blur-free frosted tint prevents cache flicker
      // when updating rapidly during spring physics drag.
      body = DecoratedBox(
        decoration: BoxDecoration(color: frostedColor),
        child: const SizedBox.expand(),
      );
    }

    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip
          .hardEdge, // Locks dirty region to widget bounds — prevents page-wide flicker
      children: [
        if (useBlur)
          // Stationary surfaces: blur + tint clipped to shape.
          //
          // Use ClipRRect when the shape resolves to a rounded rect —
          // Flutter PR #177551 (in 3.41+) forwards ClipRRect clip data
          // to iOS PlatformView mutators, so ClipRRect (not ClipPath)
          // is what lets the engine clip a descendant BackdropFilter
          // over a PlatformView. Eliminates the rectangular blur halo
          // around rounded glass surfaces stacked over PlatformViews
          // (e.g. mapbox_maps_flutter, video_player on iOS).
          Positioned.fill(
            child: _ShapeClip(shape: shape, child: body),
          ),

        if (!useBlur)
          // Interactive surfaces: pure ShapeDecoration vector — bypasses the
          // stencil buffer so sub-pixel spring deceleration never causes edge flicker.
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(color: frostedColor, shape: shape),
              child: const SizedBox.expand(),
            ),
          ),

        // Glow intensity wrapper for GlassButton tap feedback
        if (glowIntensity > 0)
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: shape,
                color: Colors.white.withValues(alpha: 0.15 * glowIntensity),
              ),
            ),
          ),

        // Text and contents MUST be strictly clipped to corner radii.
        // Same ClipRRect-over-ClipPath rationale as the blur body
        // above — see the [_ShapeClip] doc comment.
        _ShapeClip(shape: shape, child: child),

        // Specular Rim: drawn as a pure native overlay vector perfectly on top.
        // Wrapped in _ShapeClip because canvas.drawPath draws a center-aligned
        // stroke. Clipping it removes the outer half, creating a true 'inner
        // border' which is optically correct for glass internal reflections.
        //
        // Suppressed for flat-edge shapes (borderRadius: 0) like app bars,
        // where the rim looks like a Material divider rather than a glass edge.
        if (!_isFlatEdge(shape))
          Positioned.fill(
            child: IgnorePointer(
              child: _ShapeClip(
                shape: shape,
                child: CustomPaint(
                  painter: _SpecularRimPainter(
                    shape: shape,
                    settings: settings,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Returns true when [shape] has no rounded corners (borderRadius == 0).
  ///
  /// Full-width surfaces (app bars, bottom bars) use `borderRadius: 0` and
  /// the specular rim on their straight edges looks like a Material divider
  /// rather than an internal glass reflection.
  static bool _isFlatEdge(LiquidShape shape) {
    if (shape is LiquidRoundedRectangle && shape.borderRadius == 0) return true;
    if (shape is LiquidRoundedSuperellipse && shape.borderRadius == 0) {
      return true;
    }
    if (shape is LiquidVerticalRoundedRectangle &&
        shape.topRadius == 0 &&
        shape.bottomRadius == 0) {
      return true;
    }
    if (shape is LiquidVerticalRoundedSuperellipse &&
        shape.topRadius == 0 &&
        shape.bottomRadius == 0) {
      return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// _SpecularRimPainter — light-angle specular rim stroke
//
// Ported from FakeGlass._paintSpecular() (whynotmake.it, MIT).
// Pure Canvas drawing: two gradient strokes with BlendMode.hardLight and
// BlendMode.overlay. Zero GPU shader cost on any platform.
// ---------------------------------------------------------------------------
class _SpecularRimPainter extends CustomPainter {
  const _SpecularRimPainter({
    required this.shape,
    required this.settings,
  });

  final LiquidShape shape;
  final LiquidGlassSettings settings;

  @override
  void paint(Canvas canvas, Size size) {
    final lightIntensity = settings.effectiveLightIntensity.clamp(0.0, 1.0);
    if (lightIntensity == 0) return;

    final ambientStrength = settings.effectiveAmbientStrength.clamp(0.0, 1.0);
    final alpha = Curves.easeOut.transform(lightIntensity);
    final white = Colors.white.withValues(alpha: alpha);

    final rad = settings.lightAngle;
    final x = math.cos(rad);
    // Invert Y to match the GLSL fragment shader coordinate space (up is positive).
    final y = -math.sin(rad);

    // Expand to a square so the gradient angle matches the light angle exactly:
    // a squashed gradient rect distorts the effective direction.
    final bounds = Offset.zero & size;
    final squareBounds = Rect.fromCircle(
      center: bounds.center,
      radius: bounds.size.longestSide / 2,
    );

    // How far the light covers the glass (gradient stop spread).
    final lightCoverage = ui.lerpDouble(.3, .5, lightIntensity)!;

    // Adjust gradient scale for non-square aspect ratios.
    final aspectRatio = size.width / size.height.clamp(0.001, double.infinity);
    final alignmentWithShortestSide = (aspectRatio < 1 ? y : x).abs();
    final aspectAdjustment = 1 - 1 / aspectRatio.clamp(0.001, double.infinity);
    final gradientScale = aspectAdjustment * (1 - alignmentWithShortestSide);

    final inset = ui.lerpDouble(0, .5, gradientScale.clamp(0, 1))!;
    final secondInset =
        ui.lerpDouble(lightCoverage, .5, gradientScale.clamp(0, 1))!;

    final gradient = LinearGradient(
      colors: [
        white,
        white.withValues(alpha: ambientStrength),
        white.withValues(alpha: ambientStrength),
        white,
      ],
      stops: [inset, secondInset, 1 - secondInset, 1 - inset],
      begin: Alignment(x, y),
      end: Alignment(-x, -y),
    ).createShader(squareBounds);

    final path = shape.getOuterPath(bounds);

    // Pass 1: soft base stroke.
    // Doubled width since it is now clipped to the inner half.
    // BlendMode.overlay ensures the highlight reacts organically to the
    // background color underneath, rather than looking like a flat white line.
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient
        ..color = white.withValues(alpha: white.a * 0.4)
        ..blendMode = BlendMode.overlay
        ..style = PaintingStyle.stroke
        ..strokeWidth = ui.lerpDouble(1.0, 2.0, lightIntensity)!,
    );

    // Pass 2: sharp inner rim.
    // Doubled width since it is clipped to the inner half.
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient
        ..color = white.withValues(alpha: white.a * 0.6)
        ..blendMode = BlendMode.overlay
        ..style = PaintingStyle.stroke
        ..strokeWidth = (settings.effectiveThickness / 20).clamp(0.5, 2.0),
    );
  }

  @override
  bool shouldRepaint(_SpecularRimPainter old) =>
      old.settings != settings || old.shape != shape;
}

/// Wraps [child] in [ClipRRect] when the shape resolves to a
/// `RoundedRectangleBorder` (i.e. [LiquidRoundedSuperellipse] or
/// [LiquidVerticalRoundedSuperellipse]), otherwise falls back to
/// [ClipPath] with `ShapeBorderClipper`.
///
/// **Why this matters:** Flutter framework PR #177551 (merged Dec 2025,
/// shipped in 3.41.0-0.0.pre and forward) forwards `ClipRRect` clip data
/// to the iOS PlatformView mutator stack — which lets the engine
/// correctly clip a descendant [BackdropFilter] over a PlatformView.
/// The same fix does NOT apply to `ClipPath`, even when the path inside
/// is mathematically a rounded rect.
///
/// Eliminates the rectangular blur halo that appeared around rounded
/// `_FrostedFallback` surfaces when stacked over a PlatformView (e.g.
/// `mapbox_maps_flutter`'s `MapWidget`, `video_player` on iOS).
///
/// **Caveat — [LiquidOval] is not handled.** Empirically the engine fix
/// does not forward `ClipRRect` with `circular(double.infinity)`, nor
/// does it forward a `LayoutBuilder`-computed finite radius on a
/// `LiquidOval` shape. Callers that need a halo-free circular surface
/// over a PlatformView should pass
/// `LiquidRoundedSuperellipse(borderRadius: size / 2)` instead, which
/// renders identically to a circle on a square widget and triggers the
/// engine fix.
class _ShapeClip extends StatelessWidget {
  const _ShapeClip({required this.shape, required this.child});

  final LiquidShape shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = this.shape;
    if (shape is LiquidRoundedSuperellipse) {
      return ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(shape.borderRadius)),
        child: child,
      );
    }
    if (shape is LiquidVerticalRoundedSuperellipse) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(shape.topRadius),
          bottom: Radius.circular(shape.bottomRadius),
        ),
        child: child,
      );
    }
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: child,
    );
  }
}
