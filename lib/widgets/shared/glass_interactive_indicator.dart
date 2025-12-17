import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';

/// A shared component that renders the interactive "Jelly" indicator
/// used in [GlassTabBar], [GlassSegmentedControl], and [GlassBottomBar].
///
/// Handles:
/// - Jelly physics (squash and stretch)
/// - Thickness-based crossfade between background and glass
/// - Positioning and expansion
class GlassInteractiveIndicator extends StatelessWidget {
  const GlassInteractiveIndicator({
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
  });

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

  static const _baseGlassSettings = LiquidGlassSettings(
    glassColor: Color.from(
      alpha: 0.15,
      red: 1,
      green: 1,
      blue: 1,
    ),
    refractiveIndex: 1.15,
    lightIntensity: 2,
    chromaticAberration: 0.5,
    blur: 0,
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

    Widget indicatorChild;

    if (isBackgroundIndicator) {
      // Fade out background indicator when drag becomes active
      indicatorChild = AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: thickness <= 0.2 ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: const SizedBox.expand(),
        ),
      );
    } else {
      // Render glass indicator
      final shape = useSuperellipse
          ? LiquidRoundedSuperellipse(borderRadius: borderRadius * 2)
          : LiquidRoundedRectangle(borderRadius: borderRadius);

      indicatorChild = LiquidGlass.withOwnLayer(
        fake: quality.usesBackdropFilter,
        settings: glassSettings ??
            _baseGlassSettings.copyWith(
              visibility: thickness,
            ),
        shape: shape,
        child: const GlassGlow(child: SizedBox.expand()),
      );
    }

    return Positioned.fill(
      child: Padding(
        padding: padding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: 1 / itemCount,
                alignment: alignment,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fromRelativeRect(
                      rect: rect!,
                      child: RepaintBoundary(
                        child: SingleMotionBuilder(
                          motion: const Motion.bouncySpring(
                            duration: Duration(milliseconds: 600),
                          ),
                          value: velocity,
                          builder: (context, velocity, child) {
                            return Transform(
                              alignment: Alignment.center,
                              transform:
                                  DraggableIndicatorPhysics.buildJellyTransform(
                                velocity: Offset(velocity, 0),
                                maxDistortion: 0.8,
                                velocityScale: 10,
                              ),
                              child: child,
                            );
                          },
                          child: indicatorChild,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
