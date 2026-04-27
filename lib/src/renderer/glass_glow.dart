import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import '../../utils/glass_spring.dart';

/// {@template glass_glow}
/// If placed as a descendant of a [GlassGlowLayer], this widget will
/// send touch updates to that layer to create a glow effect.
/// {@endtemplate}
class GlassGlow extends StatelessWidget {
  /// {@macro glass_glow}
  const GlassGlow({
    required this.child,
    this.glowColor = Colors.white24,
    this.glowRadius = 1,
    this.pulse = 0,
    this.clipper,
    this.hitTestBehavior = HitTestBehavior.opaque,
    super.key,
  });

  /// The radius of the glow effect relative to the layer's shortest side.
  final double glowRadius;

  /// The color of the glow effect.
  final Color glowColor;

  /// Global pulse intensity (0.0 to 1.0) for a full-window glow effect.
  final double pulse;

  /// The hit test behavior of this gesture listener.
  final HitTestBehavior hitTestBehavior;

  /// The child that will be painted above the glow effect.
  final Widget child;

  /// The shape to clip the glow to.
  final CustomClipper<Path>? clipper;

  @override
  Widget build(BuildContext context) {
    return GlassGlowLayer(
      clipper: clipper,
      pulse: pulse,
      child: Builder(
        builder: (innerContext) => Listener(
          behavior: hitTestBehavior,
          onPointerDown: (event) => _handlePointer(innerContext, event),
          onPointerMove: (event) => _handlePointer(innerContext, event),
          onPointerUp: (event) => _removeTouch(innerContext),
          onPointerCancel: (event) => _removeTouch(innerContext),
          child: child,
        ),
      ),
    );
  }

  void _handlePointer(BuildContext context, PointerEvent event) {
    final layerState = GlassGlowLayer.maybeOf(context);
    if (layerState == null) return;

    final myBox = context.findRenderObject() as RenderBox?;
    final layerBox = layerState.context.findRenderObject() as RenderBox?;

    final Offset pos;
    if (myBox != null &&
        layerBox != null &&
        myBox.attached &&
        layerBox.attached) {
      pos = layerBox.globalToLocal(myBox.localToGlobal(event.localPosition));
    } else {
      pos = event.localPosition;
    }

    layerState.updateTouch(pos, radius: glowRadius, color: glowColor);
  }

  void _removeTouch(BuildContext context) {
    GlassGlowLayer.maybeOf(context)?.removeTouch();
  }
}

/// {@template glass_glow}
/// Represents a layer that can paint a glowing effect below its child.
/// {@endtemplate}
class GlassGlowLayer extends StatefulWidget {
  /// {@macro glass_glow}
  const GlassGlowLayer({
    required this.child,
    this.clipper,
    this.pulse = 0,
    super.key,
  });

  /// The child that will be painted above the glow effect.
  final Widget child;

  /// The shape to clip the glow to.
  final CustomClipper<Path>? clipper;

  /// Global pulse intensity (0.0 to 1.0) for a full-window glow effect.
  final double pulse;

  @override
  State<GlassGlowLayer> createState() => GlassGlowLayerState();

  @internal
  static GlassGlowLayerState? maybeOf(BuildContext context) {
    if (!context.mounted) return null;
    return context.findAncestorStateOfType<GlassGlowLayerState>();
  }
}

@internal
class GlassGlowLayerState extends State<GlassGlowLayer>
    with TickerProviderStateMixin {
  late final _offsetController = OffsetSpringController(
    vsync: this,
    spring: GlassSpring.smooth(duration: const Duration(seconds: 1)),
    initialValue: Offset.zero,
  );

  late final _alphaController = SingleSpringController(
    vsync: this,
    spring: GlassSpring.smooth(),
    initialValue: 0,
    lowerBound: 0,
    upperBound: 1,
  );

  late final _radiusController = SingleSpringController(
    vsync: this,
    spring: GlassSpring.smooth(),
    initialValue: 1.2,
  );

  final _baseRadius = ValueNotifier<double>(0);
  final _baseColor = ValueNotifier<Color>(const Color.fromARGB(0, 0, 0, 0));
  bool _dragging = false;

  @override
  void dispose() {
    _offsetController.dispose();
    _alphaController.dispose();
    _radiusController.dispose();
    _baseRadius.dispose();
    _baseColor.dispose();
    super.dispose();
  }

  void updateTouch(
    Offset offset, {
    required double radius,
    required Color color,
  }) {
    _baseRadius.value = radius;
    _baseColor.value = color;

    if (!_dragging) {
      _dragging = true;
      _offsetController.value = offset;
      _alphaController.spring = GlassSpring.interactive();
      _radiusController.spring = GlassSpring.interactive();
      _alphaController.animateTo(1, fromVelocity: 0);
      _radiusController.animateTo(1, fromVelocity: 0);
    }

    _offsetController.animateTo(offset);
  }

  void removeTouch() {
    if (!_dragging) return;
    _alphaController.spring = GlassSpring.smooth();
    _radiusController.spring = GlassSpring.smooth();
    _dragging = false;
    _radiusController.animateTo(1.2);
    _alphaController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _offsetController,
        _alphaController,
        _radiusController,
        _baseRadius,
        _baseColor,
      ]),
      builder: (context, child) {
        return _RenderGlassGlowLayerWidget(
          clipper: widget.clipper,
          pulse: widget.pulse,
          glowRadius: _baseRadius.value * _radiusController.value,
          glowColor: _baseColor.value.withValues(
            alpha: _baseColor.value.a * _alphaController.value,
          ),
          glowOffset: _offsetController.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _RenderGlassGlowLayerWidget extends SingleChildRenderObjectWidget {
  const _RenderGlassGlowLayerWidget({
    required this.clipper,
    required this.pulse,
    required this.glowRadius,
    required this.glowColor,
    required this.glowOffset,
    required super.child,
  });

  final CustomClipper<Path>? clipper;
  final double pulse;
  final double glowRadius;
  final Color glowColor;
  final Offset glowOffset;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderGlassGlowLayer(
      clipper: clipper,
      pulse: pulse,
      glowRadius: glowRadius,
      glowColor: glowColor,
      glowOffset: glowOffset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGlassGlowLayer renderObject,
  ) {
    renderObject
      ..clipper = clipper
      ..pulse = pulse
      ..glowRadius = glowRadius
      ..glowColor = glowColor
      ..glowOffset = glowOffset;
  }
}

class _RenderGlassGlowLayer extends RenderProxyBox {
  _RenderGlassGlowLayer({
    required double glowRadius,
    required Color glowColor,
    required Offset glowOffset,
    required double pulse,
    CustomClipper<Path>? clipper,
  })  : _glowRadius = glowRadius,
        _glowColor = glowColor,
        _glowOffset = glowOffset,
        _pulse = pulse,
        _clipper = clipper;

  CustomClipper<Path>? _clipper;
  CustomClipper<Path>? get clipper => _clipper;
  set clipper(CustomClipper<Path>? value) {
    if (_clipper == value) return;
    _clipper = value;
    markNeedsPaint();
  }

  double _pulse;
  double get pulse => _pulse;
  set pulse(double value) {
    if (_pulse == value) return;
    _pulse = value;
    markNeedsPaint();
  }

  double _glowRadius;
  double get glowRadius => _glowRadius;
  set glowRadius(double value) {
    if (_glowRadius == value) return;
    _glowRadius = value;
    markNeedsPaint();
  }

  Color _glowColor;
  Color get glowColor => _glowColor;
  set glowColor(Color value) {
    if (_glowColor == value) return;
    _glowColor = value;
    markNeedsPaint();
  }

  Offset _glowOffset;
  Offset get glowOffset => _glowOffset;
  set glowOffset(Offset value) {
    if (_glowOffset == value) return;
    _glowOffset = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 1. Paint the children (glass)
    super.paint(context, offset);

    final canvas = context.canvas;

    // 2. Global Specular Pulse (Full window highlight)
    if (_pulse > 0) {
      final pulsePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08 * _pulse)
        ..blendMode = BlendMode.plus;

      if (_clipper != null) {
        canvas.save();
        canvas.clipPath(_clipper!.getClip(size).shift(offset));
        canvas.drawRect(offset & size, pulsePaint);
        canvas.restore();
      } else {
        canvas.drawRect(offset & size, pulsePaint);
      }
    }

    // 3. Local Interactive Glow (Finger glare)
    if (_glowColor.a > 0 && _glowRadius > 0) {
      final glowPosition = offset + _glowOffset;
      final radius = _glowRadius * math.min(size.width, size.height);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [_glowColor, _glowColor.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: glowPosition, radius: radius))
        ..blendMode = BlendMode.plus;

      if (_clipper != null) {
        canvas.save();
        canvas.clipPath(_clipper!.getClip(size).shift(offset));
        canvas.drawCircle(glowPosition, radius, paint);
        canvas.restore();
      } else {
        canvas.drawCircle(glowPosition, radius, paint);
      }
    }
  }
}
