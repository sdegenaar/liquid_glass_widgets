import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'internal/glass_drag_builder.dart';
import 'package:meta/meta.dart';
import '../../utils/glass_spring.dart';

/// A widget that provides a squash and stretch effect to its child based on
/// user interaction.
///
/// Will listen to drag gestures from the user without interfering with other
/// gestures.
class LiquidStretch extends StatelessWidget {
  /// Creates a new [LiquidStretch] widget with the given [child],
  /// [interactionScale], and [stretch].
  const LiquidStretch({
    required this.child,
    this.interactionScale = 1.05,
    this.stretch = .5,
    this.resistance = .08,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.axis,
    this.allowPositive = true,
    this.allowNegative = true,
    this.allowPositiveX,
    this.allowNegativeX,
    this.allowPositiveY,
    this.allowNegativeY,
    this.suppressInteractionOnChildren = true,
    super.key,
  });

  /// The scale factor to apply when the user is interacting with the widget.
  ///
  /// A value of 1.0 means no scaling.
  ///
  /// A value greater than 2.0 means the widget will grow to double its
  /// original size.
  ///
  /// A value less than 1.0 means the widget will scale down.
  ///
  /// Defaults to 1.05.
  final double interactionScale;

  /// The factor to multiply the drag offset by to determine the stretch
  /// amount in pixels.
  ///
  /// A value of 0.0 means no stretch, while a value of 1.0 means the stretch
  /// would match the drag offset exactly (which you probably don't want).
  ///
  /// Defaults to 0.5.
  final double stretch;

  /// The resistance factor to apply to the drag offset.
  ///
  /// The higher the resisance, the more sticky the drag will feel.
  /// See [OffsetResistanceExtension.withResistance] for details on how this
  /// works.
  ///
  /// Defaults to 0.08.
  final double resistance;

  /// The hit test behavior for the internal gesture Listener.
  ///
  /// Defaults to [HitTestBehavior.opaque].
  final HitTestBehavior hitTestBehavior;

  /// The child widget to apply the stretch effect to.
  final Widget child;

  /// The axis to constrain the stretch to. If null, stretches in both axes.
  final Axis? axis;

  /// Whether to allow stretch in the positive direction (Right/Down).
  final bool allowPositive;

  /// Whether to allow stretch in the negative direction (Left/Up).
  final bool allowNegative;

  /// Optional override for positive X direction (Right).
  final bool? allowPositiveX;

  /// Optional override for negative X direction (Left).
  final bool? allowNegativeX;

  /// Optional override for positive Y direction (Down).
  final bool? allowPositiveY;

  /// Optional override for negative Y direction (Up).
  final bool? allowNegativeY;

  /// Whether to prevent scaling when interacting with children.
  final bool suppressInteractionOnChildren;

  @override
  Widget build(BuildContext context) {
    // NOTE: Do NOT add a fast-path that returns `child` directly when
    // `stretch == 0 && interactionScale == 1.0`.  The GlassModalSheet lerps
    // these values through 0 / 1.0 as the sheet expands, so a fast-path
    // causes the widget type at this slot to switch between the bare child
    // widget and `GlassDragBuilder` on the frame where the lerp crosses the
    // threshold.  That type change forces Flutter to deactivate the entire
    // existing element subtree (firing `initState` on all descendants) and
    // mount a fresh one — which is exactly the regression we fixed in
    // lightweight_liquid_glass.dart.  Always returning `GlassDragBuilder`
    // keeps the tree structure stable throughout the animation.
    return GlassDragBuilder(
      behavior: hitTestBehavior,
      suppressInteractionOnChildren: suppressInteractionOnChildren,
      builder: (context, value, child) {
        final scale = value == null ? 1.0 : interactionScale;
        return SpringBuilder(
          value: scale,
          spring:
              GlassSpring.smooth(duration: const Duration(milliseconds: 300)),
          builder: (context, value, child) => Transform.scale(
            // Avoid exact 1.0 to prevent RenderTransform layer drops on resting
            scale: value == 1.0 ? 1.00001 : value,
            child: child,
          ),
          child: OffsetSpringBuilder(
            value: () {
              if (value == null) return Offset.zero;
              Offset o = value.withResistance(resistance);
              if (axis == Axis.horizontal) {
                o = Offset(o.dx, 0);
              } else if (axis == Axis.vertical) {
                o = Offset(0, o.dy);
              }
              final pX = allowPositiveX ?? allowPositive;
              final nX = allowNegativeX ?? allowNegative;
              final pY = allowPositiveY ?? allowPositive;
              final nY = allowNegativeY ?? allowNegative;

              if (!pX && o.dx > 0) o = Offset(0, o.dy);
              if (!nX && o.dx < 0) o = Offset(0, o.dy);
              if (!pY && o.dy > 0) o = Offset(o.dx, 0);
              if (!nY && o.dy < 0) o = Offset(o.dx, 0);

              return o;
            }(),
            spring: value == null
                ? GlassSpring.bouncy()
                : GlassSpring.interactive(),
            builder: (context, value, child) => RawLiquidStretch(
              stretchPixels: value * stretch,
              axis: axis,
              child: child,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// {@template raw_liquid_stretch}
/// Use this widget to apply a custom stretch effect in pixels to its child.
///
/// You can control the stretch effect by providing an [Offset] in pixels
/// via the [stretchPixels] property.
///
/// If you simply want to apply a stretch effect based on user drag gestures,
/// consider using [LiquidStretch] instead, which provides built-in drag
/// handling and resistance.
/// {@endtemplate}
class RawLiquidStretch extends SingleChildRenderObjectWidget {
  const RawLiquidStretch({
    required this.stretchPixels,
    required super.child,
    this.axis,
    super.key,
  });

  /// The stretch offset in pixels.
  final Offset stretchPixels;

  /// The axis to constrain the stretch to.
  final Axis? axis;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderRawLiquidStretch(
      stretchPixels: stretchPixels,
      axis: axis,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRawLiquidStretch renderObject,
  ) {
    renderObject.stretchPixels = stretchPixels;
    renderObject.axis = axis;
  }
}

@internal
class RenderRawLiquidStretch extends RenderProxyBox {
  RenderRawLiquidStretch({
    required Offset stretchPixels,
    Axis? axis,
  })  : _stretchPixels = stretchPixels,
        _axis = axis;

  Offset _stretchPixels;
  Axis? _axis;

  /// The axis to constrain the stretch to.
  Axis? get axis => _axis;
  set axis(Axis? value) {
    if (_axis == value) return;
    _axis = value;
    markNeedsPaint();
  }

  /// The stretch offset in pixels.
  Offset get stretchPixels => _stretchPixels;
  set stretchPixels(Offset value) {
    if (_stretchPixels == value) {
      return;
    }
    _stretchPixels = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final transform = _getEffectiveTransform();
    if (transform == null) {
      return super.hitTestChildren(result, position: position);
    }

    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final transform = _getEffectiveTransform();
    if (transform == null) {
      super.paint(context, offset);
      return;
    }

    // Check if the matrix is singular
    final det = transform.determinant();
    if (det == 0 || !det.isFinite) {
      layer = null;
      return;
    }

    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final effectiveTransform = _getEffectiveTransform();
    if (effectiveTransform != null) {
      transform.multiply(effectiveTransform);
    }
  }

  Matrix4? _getEffectiveTransform() {
    if (_stretchPixels == Offset.zero) {
      // Avoid exact identity to prevent TransformLayer detachment on rest
      // ignore: deprecated_member_use
      return Matrix4.identity()..translateByDouble(0.0001, 0.0, 0.0, 1.0);
    }

    final scale = getScale(
      stretchPixels: _stretchPixels,
      size: size,
    );

    final matrix = Matrix4.identity();

    // If axis is constrained, scale from the opposite edge
    if (_axis == Axis.vertical) {
      // Scale from bottom if stretching up, or top if stretching down
      // Actually, for a bottom sheet, we usually want to scale from the bottom
      final pivotY = _stretchPixels.dy <= 0 ? size.height : 0.0;
      matrix
        ..translateByDouble(size.width / 2, pivotY, 0.0, 1.0)
        ..scaleByDouble(scale.dx, scale.dy, 1.0, 1.0)
        ..translateByDouble(-size.width / 2, -pivotY, 0.0, 1.0);
    } else if (_axis == Axis.horizontal) {
      final pivotX = _stretchPixels.dx <= 0 ? size.width : 0.0;
      matrix
        ..translateByDouble(pivotX, size.height / 2, 0.0, 1.0)
        ..scaleByDouble(scale.dx, scale.dy, 1.0, 1.0)
        ..translateByDouble(-pivotX, -size.height / 2, 0.0, 1.0);
    } else {
      matrix
        ..translateByDouble(size.width / 2, size.height / 2, 0.0, 1.0)
        ..scaleByDouble(scale.dx, scale.dy, 1.0, 1.0)
        ..translateByDouble(-size.width / 2, -size.height / 2, 0.0, 1.0)
        ..translateByDouble(_stretchPixels.dx, _stretchPixels.dy, 0.0, 1.0);
    }

    return matrix;
  }

  @internal
  Offset getScale({
    required Offset stretchPixels,
    required Size size,
  }) {
    if (size.isEmpty) {
      return const Offset(1, 1);
    }

    final stretchX = stretchPixels.dx.abs();
    final stretchY = stretchPixels.dy.abs();

    // Convert pixel stretch to relative stretch based on size
    final relativeStretchX = size.width > 0 ? stretchX / size.width : 0.0;
    final relativeStretchY = size.height > 0 ? stretchY / size.height : 0.0;

    // Use a consistent stretch factor for both dimensions
    const stretchFactor = 1.0;
    const volumeFactor = 0.5;

    final baseScaleX = 1 + relativeStretchX * stretchFactor;
    final baseScaleY = 1 + relativeStretchY * stretchFactor;

    // Calculate magnitude in relative space for volume preservation
    final magnitude = math.sqrt(
      relativeStretchX * relativeStretchX + relativeStretchY * relativeStretchY,
    );
    final targetVolume = 1 + magnitude * volumeFactor;
    final currentVolume = baseScaleX * baseScaleY;
    final volumeCorrection = math.sqrt(targetVolume / currentVolume);

    var finalScaleX = baseScaleX * volumeCorrection;
    var finalScaleY = baseScaleY * volumeCorrection;

    // If axis is constrained, don't affect the other dimension
    if (_axis == Axis.vertical) {
      finalScaleX = 1.0;
    } else if (_axis == Axis.horizontal) {
      finalScaleY = 1.0;
    }

    return Offset(finalScaleX, finalScaleY);
  }
}

/// Provides [withResistance] method to apply drag resistance to an [Offset].
extension OffsetResistanceExtension on Offset {
  /// Returns a new [Offset] with a given [resistance] applied, which will
  /// hold it back the further it deviates from [Offset.zero].
  ///
  /// Applies a non-linear damping effect that reduces the offset's magnitude
  /// while preserving its direction. Higher resistance values create stronger
  /// damping.
  /// Larger offsets are reduced more aggressively than smaller ones,
  /// creating a natural "stretch resistance" effect commonly used in scrolling.
  Offset withResistance(double resistance) {
    if (resistance == 0) return this;

    final magnitude = math.sqrt(dx * dx + dy * dy);
    if (magnitude == 0) return Offset.zero;

    final resistedMagnitude = magnitude / (1 + magnitude * resistance);
    final scale = resistedMagnitude / magnitude;

    return Offset(dx * scale, dy * scale);
  }
}
