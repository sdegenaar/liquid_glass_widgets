import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../utils/indicator_jelly.dart';

// =============================================================================
// Masking Quality
// =============================================================================

/// Rendering quality for the liquid glass masking effect in [GlassTabBar].
///
/// Controls the complexity of the masking effect that creates the "magic lens"
/// appearance where selected tab content appears to glow through the glass indicator.
enum MaskingQuality {
  /// No masking effect, simple icon color change (fastest).
  ///
  /// Uses the traditional approach where tabs simply change color when selected.
  /// No dual-layer rendering or clipping. Best performance, but less visual polish.
  ///
  /// **Recommended for:**
  /// - Apps targeting older devices (iPhone X or older)
  /// - Maximum performance requirements
  /// - 7+ tabs
  off,

  /// Full jelly physics clip path with dual-layer rendering (best quality, default).
  ///
  /// Creates a "magic lens" effect where selected tabs appear to glow through
  /// the glass indicator as it moves. Content is magnified and the clip path
  /// follows the jelly physics for perfect synchronization.
  ///
  /// **Recommended for:**
  /// - Modern devices (iPhone 12+, Pixel 5+)
  /// - 3-5 tabs (typical use case)
  /// - Premium/polished apps
  /// - When visual quality is a priority
  ///
  /// **Performance:** Renders tabs twice with ClipPath operations. Maintains
  /// 60fps on modern devices with typical 3-5 tab configurations.
  high,
}

// =============================================================================
// Search Morph Alignment
// =============================================================================

/// Controls how the tab pill is anchored **horizontally** during the morph
/// animation in a searchable tab bar.
///
/// This only affects the tab pill's position. The search pill position is
/// always computed from the trailing edge.
enum GlassTabPillAnchor {
  /// The tab pill is pinned to the **leading (left) edge** — the right edge
  /// retracts as the pill collapses. This is the default and matches the
  /// classic iOS News / Safari behaviour.
  start,

  /// The tab pill scales **from its centre** — both edges collapse inward
  /// symmetrically as the pill morphs into the collapsed search state, and
  /// expand outward symmetrically when search closes.
  ///
  /// Use this when you want a more balanced, symmetrical animation. Note that
  /// while searching, the search pill will be slightly narrower than in
  /// [start] mode because it starts after the centred collapsed tab pill.
  center,
}

// =============================================================================
// Jelly Clipper
// =============================================================================

/// Clipper that matches the shape and physics of the jelly indicator.
class JellyClipper extends CustomClipper<Path> {
  /// Creates a new [JellyClipper].
  JellyClipper({
    required this.itemCount,
    required this.alignment,
    required this.thickness,
    required this.expansion,
    required this.transform,
    required this.borderRadius,
    this.inverse = false,
    this.jelly,
    this.clampExpansionToTrack = false,
  });

  /// The number of items.
  final int itemCount;

  /// The alignment of the clipper.
  final Alignment alignment;

  /// The thickness of the jelly effect.
  final double thickness;

  /// The expansion insets.
  final EdgeInsets expansion;

  /// The transform matrix.
  final Matrix4 transform;

  /// The border radius.
  final double borderRadius;

  /// Whether the clipper is inverted.
  final bool inverse;

  /// Native-style jelly deformation. When non-null it replaces [transform]
  /// so the mask matches the lens exactly.
  final IndicatorJelly? jelly;

  /// Whether the lifted mask stops at the ends of the clip area, matching
  /// [AnimatedGlassIndicator.clampExpansionToTrack].
  final bool clampExpansionToTrack;

  /// Threshold for clip recalculation optimization.
  ///
  /// When changes in alignment or thickness are below this threshold,
  /// the cached clip path is reused instead of recalculating.
  /// This is below human perception threshold (sub-pixel).
  static const double _recalcThreshold = 0.001;

  @override
  Path getClip(Size size) {
    // AnimatedGlassIndicator pads the WHOLE track before dividing it into
    // equal-width cells. Use the same order here: insetting each cell instead
    // makes the mask narrower than the lens, with a position-dependent offset.
    const indicatorInset = 4.0;
    final trackWidth = size.width - 2 * indicatorInset;
    final tabWidth = trackWidth / itemCount;
    final availableWidth = trackWidth - tabWidth;
    final rawLeft = indicatorInset + (alignment.x + 1) / 2 * availableWidth;

    // Keep the edge tab covered during rubber-band overdrag (#328). Only
    // extend the outward edge; normal positions still match the optical lens.
    final left = rawLeft.clamp(
      double.negativeInfinity,
      indicatorInset + availableWidth,
    );
    final right = (rawLeft + tabWidth).clamp(
      indicatorInset + tabWidth,
      double.infinity,
    );
    final paddedRect = Rect.fromLTRB(
      left,
      indicatorInset,
      right,
      size.height - indicatorInset,
    );

    // Apply expansion based on thickness (drag state)
    var inflatedLeft = paddedRect.left - (expansion.left * thickness);
    var inflatedRight = paddedRect.right + (expansion.right * thickness);
    if (clampExpansionToTrack) {
      inflatedLeft = math.min(paddedRect.left, math.max(inflatedLeft, 0.0));
      inflatedRight =
          math.max(paddedRect.right, math.min(inflatedRight, size.width));
    }
    final inflatedRect = Rect.fromLTRB(
      inflatedLeft,
      paddedRect.top - (expansion.top * thickness),
      inflatedRight,
      paddedRect.bottom + (expansion.bottom * thickness),
    );

    // Clamp radius to avoid invalid RRect paths on Impeller.
    final maxRadius = (inflatedRect.shortestSide / 2) - 0.1;
    final safeRadius = borderRadius > maxRadius ? maxRadius : borderRadius;

    // Create rounded rect path
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        inflatedRect,
        Radius.circular(safeRadius > 0 ? safeRadius : 0),
      ));

    // Apply the jelly transform: the classic velocity squash around the
    // centre, or the native jelly (scale plus shift).
    final Matrix4 centeredTransform;
    final nativeJelly = jelly;
    if (nativeJelly != null) {
      centeredTransform = nativeJelly.matrixFor(inflatedRect);
    } else {
      final center = inflatedRect.center;
      centeredTransform = Matrix4.identity()
        ..translateByDouble(center.dx, center.dy, 0.0, 1.0)
        ..multiply(transform)
        ..translateByDouble(-center.dx, -center.dy, 0.0, 1.0);
    }

    final indicatorPath = path.transform(centeredTransform.storage);

    if (inverse) {
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addPath(indicatorPath, Offset.zero);
    }

    return indicatorPath;
  }

  @override
  bool shouldReclip(JellyClipper oldClipper) {
    if (itemCount == oldClipper.itemCount &&
        inverse == oldClipper.inverse &&
        borderRadius == oldClipper.borderRadius &&
        expansion == oldClipper.expansion &&
        transform == oldClipper.transform &&
        jelly == oldClipper.jelly &&
        clampExpansionToTrack == oldClipper.clampExpansionToTrack &&
        (alignment.x - oldClipper.alignment.x).abs() < _recalcThreshold &&
        (thickness - oldClipper.thickness).abs() < _recalcThreshold) {
      return false;
    }

    return itemCount != oldClipper.itemCount ||
        alignment != oldClipper.alignment ||
        thickness != oldClipper.thickness ||
        expansion != oldClipper.expansion ||
        transform != oldClipper.transform ||
        jelly != oldClipper.jelly ||
        clampExpansionToTrack != oldClipper.clampExpansionToTrack ||
        borderRadius != oldClipper.borderRadius ||
        inverse != oldClipper.inverse;
  }
}
