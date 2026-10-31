// ignore_for_file: public_member_api_docs
// Shared internal painter for the iOS 27 `_UILiquidLensView` inner shadow.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
library;

import 'package:flutter/widgets.dart';

import '../../../constants/glass_defaults.dart';

/// Paints the iOS 27 lens inner shadow (`_UILiquidLensView` spec).
///
/// The native lens spec carries `innerShadowOffsetY = 7`,
/// `innerShadowRadius = 3` and `innerShadowOpacity = 0.06`: the shadow of the
/// lens' own silhouette, pushed 7pt down and clipped to the lens, so it
/// darkens the inside of the top edge (and the upper curves of the capsule)
/// by about 6% of black.
class LensInnerShadowPainter extends CustomPainter {
  const LensInnerShadowPainter({
    required this.borderRadius,
    required this.opacity,
  });

  /// `innerShadowOffsetY` of the native lens spec, in logical points.
  static const double offsetY = 7.0;

  /// `innerShadowRadius` of the native lens spec. A Core Animation shadow
  /// radius is twice the Gaussian sigma.
  static const double radius = 3.0;

  /// `innerShadowOpacity` of the native lens spec.
  static const double shadowOpacity = 0.06;

  final double borderRadius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      GlassDefaults.safeCircularRadius(borderRadius),
    );
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(radius * 6 + offsetY))
      ..addRRect(rrect.shift(const Offset(0, offsetY)));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(
      hole,
      Paint()
        ..color = Color.from(
          alpha: shadowOpacity * opacity,
          red: 0,
          green: 0,
          blue: 0,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LensInnerShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.opacity != opacity;
}
