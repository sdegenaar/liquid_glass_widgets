import re

with open('lib/src/renderer/liquid_shape.dart', 'r') as f:
    content = f.read()

dent_class = """
/// Represents a shape that is formed by subtracting a symmetric top/bottom dent from a base [LiquidShape].
class LiquidShapeSymmetricDent extends LiquidShape {
  const LiquidShapeSymmetricDent({
    required this.baseShape,
    required this.dentDepth,
    required this.dentWidth,
    required this.dentAlignmentX,
    super.side = BorderSide.none,
  });

  final LiquidShape baseShape;
  final double dentDepth;
  final double dentWidth;
  final double dentAlignmentX;

  @override
  OutlinedBorder get _equivalentOutlinedBorder => _LiquidSymmetricDentBorder(
        baseShape: baseShape,
        dentDepth: dentDepth,
        dentWidth: dentWidth,
        dentAlignmentX: dentAlignmentX,
        side: side,
      );

  @override
  LiquidShape copyWith({BorderSide? side}) {
    return LiquidShapeSymmetricDent(
      baseShape: baseShape,
      dentDepth: dentDepth,
      dentWidth: dentWidth,
      dentAlignmentX: dentAlignmentX,
      side: side ?? this.side,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return LiquidShapeSymmetricDent(
      baseShape: baseShape.scale(t) as LiquidShape,
      dentDepth: dentDepth * t,
      dentWidth: dentWidth * t,
      dentAlignmentX: dentAlignmentX,
      side: side.scale(t),
    );
  }

  @override
  List<Object?> get props => [...super.props, baseShape, dentDepth, dentWidth, dentAlignmentX];
}

class _LiquidSymmetricDentBorder extends OutlinedBorder {
  const _LiquidSymmetricDentBorder({
    required this.baseShape,
    required this.dentDepth,
    required this.dentWidth,
    required this.dentAlignmentX,
    super.side = BorderSide.none,
  });

  final LiquidShape baseShape;
  final double dentDepth;
  final double dentWidth;
  final double dentAlignmentX;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final basePath = baseShape.getOuterPath(rect, textDirection: textDirection);
    
    if (dentDepth <= 0) return basePath;

    // Available width for alignment mapping
    final availableWidth = rect.width - dentWidth;
    final left = (dentAlignmentX + 1) / 2 * availableWidth;
    final centerX = left + dentWidth / 2;

    final topDent = Path()
      ..moveTo(centerX - dentWidth * 0.6, rect.top - 10)
      ..lineTo(centerX - dentWidth * 0.6, rect.top)
      ..cubicTo(
        centerX - dentWidth * 0.3, rect.top,
        centerX - dentWidth * 0.4, rect.top + dentDepth,
        centerX, rect.top + dentDepth,
      )
      ..cubicTo(
        centerX + dentWidth * 0.4, rect.top + dentDepth,
        centerX + dentWidth * 0.3, rect.top,
        centerX + dentWidth * 0.6, rect.top,
      )
      ..lineTo(centerX + dentWidth * 0.6, rect.top - 10)
      ..close();

    final bottomDent = Path()
      ..moveTo(centerX - dentWidth * 0.6, rect.bottom + 10)
      ..lineTo(centerX - dentWidth * 0.6, rect.bottom)
      ..cubicTo(
        centerX - dentWidth * 0.3, rect.bottom,
        centerX - dentWidth * 0.4, rect.bottom - dentDepth,
        centerX, rect.bottom - dentDepth,
      )
      ..cubicTo(
        centerX + dentWidth * 0.4, rect.bottom - dentDepth,
        centerX + dentWidth * 0.3, rect.bottom,
        centerX + dentWidth * 0.6, rect.bottom,
      )
      ..lineTo(centerX + dentWidth * 0.6, rect.bottom + 10)
      ..close();

    final dents = Path.combine(PathOperation.union, topDent, bottomDent);
    return Path.combine(PathOperation.difference, basePath, dents);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    baseShape.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  ShapeBorder scale(double t) {
    return _LiquidSymmetricDentBorder(
      baseShape: baseShape.scale(t) as LiquidShape,
      dentDepth: dentDepth * t,
      dentWidth: dentWidth * t,
      dentAlignmentX: dentAlignmentX,
      side: side.scale(t),
    );
  }

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return _LiquidSymmetricDentBorder(
      baseShape: baseShape,
      dentDepth: dentDepth,
      dentWidth: dentWidth,
      dentAlignmentX: dentAlignmentX,
      side: side ?? this.side,
    );
  }
}
"""

with open('lib/src/renderer/liquid_shape.dart', 'w') as f:
    f.write(content + dent_class)

with open('lib/src/renderer/internal/render_liquid_glass_geometry.dart', 'r') as f:
    geom = f.read()

geom = geom.replace("case LiquidTeardropShape():\n        return RawShapeType.squircle;", "case LiquidTeardropShape():\n        return RawShapeType.squircle;\n      case LiquidShapeSymmetricDent(baseShape: final base):\n        return fromLiquidGlassShape(base);")
geom = geom.replace("case LiquidTeardropShape():\n        return shape.topRadius;", "case LiquidTeardropShape():\n        return shape.topRadius;\n      case LiquidShapeSymmetricDent(baseShape: final base):\n        return _getRadiusFromGlassShape(base);")
geom = geom.replace("case LiquidTeardropShape():\n        return shape.bottomRadius;", "case LiquidTeardropShape():\n        return shape.bottomRadius;\n      case LiquidShapeSymmetricDent(baseShape: final base):\n        return _getBottomRadiusFromGlassShape(base);")

with open('lib/src/renderer/internal/render_liquid_glass_geometry.dart', 'w') as f:
    f.write(geom)
