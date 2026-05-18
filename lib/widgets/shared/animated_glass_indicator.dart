import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../constants/glass_defaults.dart';
import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';
import 'glass_effect.dart';

/// A shared component that renders the interactive "Jelly" indicator
/// used in [GlassTabBar], [GlassSegmentedControl], and [GlassBottomBar].
///
/// Handles:
/// - Jelly physics (squash and stretch)
/// - Thickness-based crossfade between background and glass
/// - Positioning and expansion
class AnimatedGlassIndicator extends StatelessWidget {
  /// Optional background key for Skia/Web refraction
  final GlobalKey? backgroundKey;

  /// Current velocity of the drag gesture.
  final double velocity;

  /// Number of items (tabs/segments).
  final int itemCount;

  /// Current alignment of the indicator.
  final Alignment alignment;

  /// Animation value (0.0 to 1.0) indicating drag state.
  /// 0 = resting, >0 = dragging/animating.
  final double thickness;

  /// Rendering quality (standard/premium).
  final GlassQuality quality;

  /// Base color for the indicator (used for background mode).
  final Color indicatorColor;

  /// Whether this is the background (non-glass) pass.
  final bool isBackgroundIndicator;

  /// Whether to render the solid background color pass.
  final bool paintBackground;

  /// Whether to render the glass effect shader pass.
  final bool paintGlass;

  /// Border radius of the indicator.
  final double borderRadius;

  /// Optional glass settings override.
  final LiquidGlassSettings? glassSettings;

  /// Padding to apply around the indicator (e.g., for GlassBottomBar).
  final EdgeInsetsGeometry padding;

  /// How much to expand the indicator during drag (default 8.0).
  final double expansion;

  /// Whether to use LiquidRoundedSuperellipse (Apple style) or standard RoundedRectangle.
  final bool useSuperellipse;

  /// Optional exact width for varying tab sizes (bypasses widthFactor).
  /// Used in scrollable mode where tabs have different widths.
  final double? exactWidth;

  /// Optional exact offset from the left (bypasses alignment).
  /// Used in scrollable mode where tabs have different widths.
  final double? exactOffset;

  /// Optional shadows for the solid background indicator.
  ///
  /// Shadows are applied only to the resting (non-glass) pill so they do not
  /// muddy the liquid glass animation. Pass `null` (default) for no shadow.
  final List<BoxShadow>? shadows;

  /// Forwards to [GlassEffect.baseAlphaMultiplier]. Controls the indicator
  /// pill's center transparency in the interactive shader. Defaults to
  /// [GlassEffect]'s default (0.2). Pass 0.0 together with
  /// [edgeAlphaMultiplier]=0.0 to make the indicator's morphing pill
  /// invisible (e.g. for screens where the morph-time rim flash isn't
  /// wanted).
  final double? baseAlphaMultiplier;

  /// Forwards to [GlassEffect.edgeAlphaMultiplier]. Controls the indicator
  /// pill's rim opacity in the interactive shader AND scales the
  /// previously-hardcoded `borderMask * 0.9` floor in
  /// `interactive_indicator.frag` — so passing 0.0 actually kills the
  /// rim, instead of running into the floor. Defaults to [GlassEffect]'s
  /// default (0.4).
  final double? edgeAlphaMultiplier;

  const AnimatedGlassIndicator({
    super.key,
    required this.velocity,
    required this.itemCount,
    required this.alignment,
    required this.thickness,
    required this.quality,
    required this.indicatorColor,
    required this.isBackgroundIndicator,
    required this.borderRadius,
    this.glassSettings,
    this.padding = EdgeInsets.zero,
    this.expansion = 8.0,
    this.useSuperellipse = true,
    this.backgroundKey,
    this.paintBackground = true,
    this.paintGlass = true,
    this.exactWidth,
    this.exactOffset,
    this.shadows,
    this.baseAlphaMultiplier,
    this.edgeAlphaMultiplier,
  });

  static const _baseGlassSettings = LiquidGlassSettings(
    glassColor: Color.from(
      alpha: 0.15,
      red: 1,
      green: 1,
      blue: 1,
    ),
    refractiveIndex: GlassDefaults.refractiveIndex,
    lightIntensity: GlassDefaults.lightIntensity,
    chromaticAberration: GlassDefaults.chromaticAberration,
    lightAngle: GlassDefaults.lightAngle,
    blur: 0,
  );

  /// Clip budget for the Impeller BackdropFilterLayer.
  ///
  /// A constant margin is used rather than a velocity-proportional one:
  /// the proportional approach changes [clipExpansion] every frame, which
  /// triggers [markNeedsPaint] every frame via the setter's change detection,
  /// causing constant geometry rebuilds and showing stale geometry during fast
  /// drags. A constant value lets the setter's equality check short-circuit
  /// with no repaint.
  ///
  ///  - Horizontal 20 px: covers glass shader antialiased edge rendering.
  ///  - Vertical 12 px: covers max jelly scaleY (≈1.24 × 48 px ≈ 5.8 px)
  ///    plus a generous margin for Impeller subpixel rounding.
  static const _jellyClipExpansion = EdgeInsets.symmetric(
    horizontal: 20.0,
  );

  @override
  Widget build(BuildContext context) {
    // Calculate expansion rectangle based on thickness
    final rect = RelativeRect.lerp(
      RelativeRect.fill,
      RelativeRect.fromLTRB(
        -expansion,
        -expansion,
        -expansion,
        -expansion,
      ),
      thickness,
    );

    // 1. Background Indicator (Resting state)
    // Fade out as the drag spring thickness increases toward 0.15.
    final backgroundOpacity = (1.0 - (thickness / 0.15)).clamp(0.0, 1.0);
    final backgroundIndicator = IgnorePointer(
      child: Opacity(
        opacity: backgroundOpacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: shadows,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );

    // 2. Glass Indicator (Active/Dragging state)
    // We fade the glass in/out by setting `visibility` on the settings rather
    // than wrapping the widget in `Opacity`.
    final fade = thickness.clamp(0.0, 1.0);
    final base = glassSettings ?? _baseGlassSettings;
    final effectiveSettings = base.copyWith(visibility: fade);

    final shape = useSuperellipse
        ? LiquidRoundedSuperellipse(borderRadius: borderRadius * 2)
        : LiquidRoundedRectangle(borderRadius: borderRadius);

    // Default alpha-multipliers for the indicator: GlassEffect's own
    // defaults are 0.2 / 0.4 (matching iOS 26 baseline). Callers can
    // override via the new optional params on this widget — most
    // notably to pass 0.0 / 0.0 and fully kill the morph-time rim on
    // screens where it reads as an unwanted "border flash."
    final glassWidget = GlassEffect(
      shape: shape,
      settings: effectiveSettings,
      quality: quality,
      interactionIntensity: thickness,
      backgroundKey: backgroundKey,
      clipExpansion: _jellyClipExpansion,
      baseAlphaMultiplier: baseAlphaMultiplier ?? 0.2,
      edgeAlphaMultiplier: edgeAlphaMultiplier ?? 0.4,
      child: const GlassGlow(
        glowColor: Colors
            .transparent, // caused grey rectangle flicker if clicking multiple times
        child: SizedBox.expand(),
      ),
    );

    final bool isMinimal = quality == GlassQuality.minimal;
    // Mount early (0.01) so geometry is built before the indicator is visible,
    // preventing a 1-frame flicker at the edges on fast drags.
    final interactiveIndicator = thickness > 0.01
        ? (isMinimal ? glassWidget : RepaintBoundary(child: glassWidget))
        : const SizedBox.expand();

    // Unified indicator child
    final indicatorChild = Stack(
      children: [
        if (paintBackground && backgroundOpacity > 0) backgroundIndicator,
        if (paintGlass && fade > 0.05) interactiveIndicator,
      ],
    );

    final indicatorBody = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRelativeRect(
          rect: rect!,
          child: RepaintBoundary(
            child: Transform(
              alignment: Alignment.center,
              transform: DraggableIndicatorPhysics.buildJellyTransform(
                velocity: Offset(velocity, 0),
                maxDistortion: 0.8,
                velocityScale: 10,
              ),
              child: indicatorChild,
            ),
          ),
        ),
      ],
    );

    Widget positioning;
    if (exactWidth != null && exactOffset != null) {
      // Exact pixel positioning for scrollable mode with variable-width tabs
      positioning = Positioned(
        left: exactOffset,
        top: 0,
        bottom: 0,
        width: exactWidth,
        child: indicatorBody,
      );
    } else {
      // Fractional positioning for fixed-width tabs
      positioning = Positioned.fill(
        child: FractionallySizedBox(
          widthFactor: 1 / itemCount,
          alignment: alignment,
          child: indicatorBody,
        ),
      );
    }

    return Positioned.fill(
      child: Padding(
        padding: padding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [positioning],
        ),
      ),
    );
  }
}
