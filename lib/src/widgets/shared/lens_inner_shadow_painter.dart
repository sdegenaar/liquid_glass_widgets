// ignore_for_file: public_member_api_docs
// Shared internal painter for the iOS 27 `_UILiquidLensView` inner shadow.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
library;

import 'package:flutter/widgets.dart';

import '../../../constants/glass_defaults.dart';

/// Paints the `_UILiquidLensView` top inner shadow for iOS 26 and iOS 27.
///
/// The native lens spec carries `innerShadowOffsetY = 7` and
/// `innerShadowRadius = 3` across both OS versions, with
/// `innerShadowOpacity = 0.12` on iOS 26 (`23A343`) and
/// `innerShadowOpacity = 0.06` on iOS 27 (`24A434`): the shadow of the
/// lens' own silhouette, pushed 7pt down and clipped to the lens, so it
/// darkens the inside of the top edge (and the upper curves of the capsule).
class LensInnerShadowPainter extends CustomPainter {
  const LensInnerShadowPainter({
    required this.borderRadius,
    required this.opacity,
    this.shadowOpacity = defaultShadowOpacity,
  });

  /// `innerShadowOffsetY` of the native lens spec, in logical points.
  static const double offsetY = 7.0;

  /// `innerShadowRadius` of the native lens spec. A Core Animation shadow
  /// radius is twice the Gaussian sigma.
  static const double radius = 3.0;

  /// `innerShadowOpacity` of the native iOS 27 lens spec (`0.06`).
  static const double defaultShadowOpacity = 0.06;

  /// `innerShadowOpacity` of the classic spherical lens (`0.12`).
  static const double classicShadowOpacity = 0.12;

  final double borderRadius;
  final double opacity;
  final double shadowOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      GlassDefaults.safeCircularRadius(borderRadius),
    );
    final shadowPaint = Paint()
      ..color = Color.from(
        alpha: shadowOpacity * opacity,
        red: 0,
        green: 0,
        blue: 0,
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.5);

    // Outer drop shadow of the lifted lens (`shadowOffsetY = 7`, `radius = 3`,
    // `opacity = 0.06`), clipped to the exterior of the lens silhouette so the
    // clear interior is never darkened.
    final outerClip = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(radius * 6 + offsetY))
      ..addRRect(rrect);
    canvas.save();
    canvas.clipPath(outerClip);
    canvas.drawRRect(rrect.shift(const Offset(0, offsetY)), shadowPaint);
    canvas.restore();

    // Inner top shadow (`innerShadowOffsetY = 7`, `innerShadowRadius = 3`),
    // inset by 1.25 pt so the 0..1.25 pt top inner specular rim highlight
    // stays crisp.
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(radius * 6 + offsetY))
      ..addRRect(rrect.shift(const Offset(0, offsetY)));
    canvas.save();
    canvas.clipRRect(rrect.deflate(1.25));
    canvas.drawPath(hole, shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LensInnerShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.opacity != opacity ||
      oldDelegate.shadowOpacity != shadowOpacity;
}
