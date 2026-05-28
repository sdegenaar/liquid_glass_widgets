import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../liquid_glass_renderer.dart';
import '../internal/render_liquid_glass_geometry.dart';
import '../internal/snap_rect_to_pixels.dart';
import '../logging.dart';
import 'package:meta/meta.dart';

/// A render object that can assemble [RenderLiquidGlassGeometry] shapes and
/// render them to the screen with the liquid glass effect.
@internal
abstract class LiquidGlassRenderObject extends RenderProxyBox {
  LiquidGlassRenderObject({
    required GeometryRenderLink link,
    required this.renderShader,
    required LiquidGlassSettings settings,
    required double devicePixelRatio,
    BackdropKey? backdropKey,
  })  : _settings = settings,
        _devicePixelRatio = devicePixelRatio,
        _backdropKey = backdropKey,
        _link = link,
        _cachedLightDir = Offset(
          cos(settings.lightAngle),
          -sin(settings.lightAngle),
        ) {
    _updateShaderSettings();
  }

  static final logger = Logger(LgrLogNames.render);

  final FragmentShader renderShader;

  /// Cached light direction vector — updated only when [settings.lightAngle]
  /// changes. Avoids recomputing cos/sin on every _updateShaderSettings() call
  /// (which fires for any property change: visibility, blur, color, etc.).
  Offset _cachedLightDir;

  /// The size that the geometry texture should have.
  Size get desiredMatteSize;

  Matrix4 get matteTransform;

  late GeometryRenderLink _link;
  GeometryRenderLink get link => _link;
  set link(GeometryRenderLink value) {
    if (_link == value) return;
    markNeedsPaint();
    _link = value;
  }

  LiquidGlassSettings? _settings;
  LiquidGlassSettings get settings => _settings!;
  set settings(LiquidGlassSettings value) {
    if (_settings == value) return;
    // Only recompute the trig if lightAngle actually changed.
    if (value.lightAngle != _settings?.lightAngle) {
      _cachedLightDir = Offset(
        cos(value.lightAngle),
        -sin(value.lightAngle),
      );
    }
    _settings = value;
    _updateShaderSettings();
    markNeedsPaint();
  }

  double _devicePixelRatio;
  double get devicePixelRatio => _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    _updateShaderSettings();
    markNeedsPaint();
  }

  /// The [BackdropKey] for blur-sharing via a [BackdropGroup] ancestor.
  /// Set to [BackdropGroup.of(context)?.backdropKey] when a [GlassBackdropScope]
  /// (or [BackdropGroup]) exists in the tree; null otherwise (no-op).
  BackdropKey? _backdropKey;
  BackdropKey? get backdropKey => _backdropKey;
  set backdropKey(BackdropKey? value) {
    if (_backdropKey == value) return;
    _backdropKey = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => _geometryImage != null;

  /// Pre-rendered geometry texture in the render object's LOCAL coordinate space.
  /// Because the geometry is recorded without `matteTransform`, its screen-space
  /// position is always derived synchronously at paint time — zero async lag.
  ui.Image? _geometryImage;

  /// Bounding box of [_geometryImage] in the render object's LOCAL logical-pixel
  /// coordinate space (snapped to physical pixels).
  /// Apply `matteTransform` at paint time to get the current screen-space bounds.
  Rect _geometryLocalBounds = Rect.zero;

  @override
  @mustCallSuper
  void attach(PipelineOwner owner) {
    super.attach(owner);
  }

  @override
  @mustCallSuper
  void detach() {
    super.detach();
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    needsGeometryUpdate = true;
    super.layout(constraints, parentUsesSize: parentUsesSize);
  }

  void _updateShaderSettings() {
    renderShader.setFloatUniforms(initialIndex: 6, (value) {
      value
        ..setColor(settings.effectiveGlassColor)
        ..setFloats([
          settings.effectiveRefractiveIndex,
          settings.effectiveChromaticAberration,
          settings.effectiveThickness,
          settings.effectiveLightIntensity,
          settings.effectiveAmbientStrength,
          settings.effectiveSaturation,
        ])
        // Use pre-cached direction — cos/sin only recomputed when lightAngle changes,
        // not on every visibility, blur, or color animation frame.
        ..setOffset(_cachedLightDir);
    });
  }

  ui.Rect _paintBounds = ui.Rect.zero;

  @override
  ui.Rect get paintBounds => _paintBounds;

  // MARK: Painting

  @override
  @nonVirtual
  void paint(PaintingContext context, Offset offset) {
    // Guard: if this render object has been detached mid-frame (e.g. rapid
    // widget removal during isolate shutdown), skip all GPU operations to
    // prevent use-after-free on Mali GPU Vulkan resources.
    if (!attached) return;

    if (LgrLogs.isLogActive(logger)) {
      logger.finest(
        '$hashCode Painting liquid glass with '
        '${link._shapeGeometries.length} shapes.',
      );
    }

    final shapesWithGeometry =
        <(RenderLiquidGlassGeometry, GeometryCache, Matrix4)>[];

    Rect? boundingBox;

    for (final geometryRo in link.shapes) {
      final geometry = geometryRo.maybeRebuildGeometry();

      if (geometry == null) continue;

      final transform = geometryRo.getTransformTo(this);
      shapesWithGeometry.add((geometryRo, geometry, transform));

      final geoBounds = MatrixUtils.transformRect(
        transform,
        geometry.bounds,
      );
      boundingBox = boundingBox == null
          ? geoBounds
          : boundingBox.expandToInclude(geoBounds);
    }

    if (boundingBox == null) {
      _clearGeometryImage();

      super.paint(context, offset);
      return;
    }

    _paintBounds = boundingBox;

    // Fast-path: if there is no geometric thickness AND no blur, there is
    // nothing to render — skip the expensive async geometry build entirely.
    // If blur > 0 but thickness == 0, we must still run paintLiquidGlass so
    // the BackdropFilterLayer blur pass fires in liquid_glass_layer.dart.
    if (settings.effectiveThickness <= 0 && settings.effectiveBlur <= 0) {
      _clearGeometryImage();
      paintShapeContents(
        context,
        offset,
        shapesWithGeometry,
        insideGlass: true,
      );
      paintShapeContents(
        context,
        offset,
        shapesWithGeometry,
        insideGlass: false,
      );
      super.paint(context, offset);
      return;
    }

    if (needsGeometryUpdate || _geometryImage == null || link._dirty) {
      link.updateAllGeometries();
      link._dirty = false;
      needsGeometryUpdate = false;

      // Synchronous rasterization (toImageSync) eliminates 1-frame jitter
      // during size animations (like modal sheet expansion).
      _updateGeometrySync(shapesWithGeometry, boundingBox);

      // The image is now current — no latency. On the very first frame there
      // is no previous image — fall through to the early-return below via the
      // null check on _geometryImage.
    }

    if (debugPaintLiquidGlassGeometry) {
      _debugPaintGeometry(context, offset);
      paintShapeContents(
        context,
        offset,
        shapesWithGeometry,
        insideGlass: true,
      );
      paintShapeContents(
        context,
        offset,
        shapesWithGeometry,
        insideGlass: false,
      );
    } else {
      if (_geometryImage case final geometryImage?) {
        // Map the texture to exactly the bounds it was originally built for
        // (_geometryLocalBounds) rather than the newly expanding current frame
        // bounds (_paintBounds).
        //
        // Map the texture to exactly the bounds it was originally built for
        // (_geometryLocalBounds) rather than the newly expanding current frame
        // bounds (_paintBounds).
        //
        // Using _paintBounds causes severe multi-button jitter during animations:
        // as one button scales, _paintBounds expands/shifts to contain it. Since
        // the asynchronous texture lags 1 frame behind, rendering the old texture
        // using the new origin visually shifted entire group of buttons on the
        // screen until the next texture arrived.
        //
        // Locking the shader mapping to the precise bounds the texture was built
        // with ensures stable pixel positioning for the life of the texture.
        final activeBounds = MatrixUtils.transformRect(
          matteTransform,
          _geometryLocalBounds,
        ).snapToPixels(devicePixelRatio);
        renderShader
          // Slot 0-1: uSize — physical-pixel size of the backdrop layer.
          // Must be set before painting so the shader can derive correct screen UVs.
          ..setFloatUniforms(initialIndex: 0, (value) {
            value.setSize(desiredMatteSize * devicePixelRatio);
          })
          // Slots 2-5: uGeometryOffset + uGeometrySize in physical pixels.
          ..setFloatUniforms(initialIndex: 2, (value) {
            value
              ..setOffset(activeBounds.topLeft * devicePixelRatio)
              ..setSize(activeBounds.size * devicePixelRatio);
          })
          ..setImageSampler(1, geometryImage);
        paintLiquidGlass(
          context,
          offset,
          shapesWithGeometry,
          _paintBounds,
        );
      }
    }

    super.paint(context, offset);
  }

  void _clearGeometryImage() {
    _geometryImage?.dispose();
    _geometryImage = null;
  }

  /// Subclasses implement the actual glass rendering
  /// (e.g., with backdrop filters)
  void paintLiquidGlass(
    PaintingContext context,
    Offset offset,
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes,
    Rect boundingBox,
  );

  @protected
  void paintShapeContents(
    PaintingContext context,
    Offset offset,
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes, {
    required bool insideGlass,
  }) {
    for (final (geometryRenderObject, _, _) in shapes) {
      geometryRenderObject.paintShapeContents(
        this,
        context,
        offset,
        insideGlass: insideGlass,
      );
    }
  }

  void _debugPaintGeometry(PaintingContext context, Offset offset) {
    if (_geometryImage case final geometryImage?) {
      // The geometry image is in local space. Draw it at the local bounds
      // position so it overlays the glass content at the correct on-screen
      // location (the rendering canvas already applies the correct transform).
      context.canvas
        ..save()
        ..translate(_geometryLocalBounds.left, _geometryLocalBounds.top)
        ..scale(1 / devicePixelRatio)
        ..drawImage(
          geometryImage,
          Offset.zero,
          Paint()..blendMode = BlendMode.src,
        )
        ..restore();
    }
  }

  /// Synchronously rasterizes the geometry picture using [ui.Picture.toImageSync].
  /// This eliminates the 1-frame async lag that caused visible ghosting during
  /// modal sheet and button-group animations. For the small pill-shape geometry
  /// used here, synchronous GPU upload is sub-millisecond and safe.
  void _updateGeometrySync(
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> geometries,
    Rect bounds,
  ) {
    // Record canvas commands synchronously — pure CPU work.
    final (picture, localBounds, imageSize) =
        _recordGeometryPicture(geometries, bounds);

    try {
      // Synchronous GPU rasterization — no async lag.
      // Clamp to ≥1: jelly squash can push geometry to near-zero size and
      // toImageSync(0, n) throws "Invalid image dimensions".
      final image = picture.toImageSync(
        max(1, imageSize.width.ceil()),
        max(1, imageSize.height.ceil()),
      );

      _clearGeometryImage();
      _geometryImage = image;
      _geometryLocalBounds = localBounds;
      // No markNeedsPaint() needed — we are already inside paint().
    } finally {
      picture.dispose();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _clearGeometryImage();
    // Break reference chains to prevent stale GPU resource retention during
    // isolate shutdown. The render shader holds a DlRuntimeEffectColorSource
    // that retains Vulkan textures — nulling _settings ensures no closure
    // retains a path back to the shader's GPU resources past the Vulkan
    // context lifetime (Crash 2 in Mali GPU crash analysis).
    _settings = null;
    super.dispose();
  }

  // MARK: Geometry

  @protected
  bool needsGeometryUpdate = true;

  /// Records all geometry drawing commands into a [ui.Picture] synchronously.
  /// Returns the picture, the LOCAL-SPACE bounding rect, and the physical
  /// pixel size needed for rasterization. The caller is responsible for
  /// disposing the picture after rasterization.
  ///
  /// ## Local-space rasterization (A3)
  ///
  /// The geometry is recorded WITHOUT applying [matteTransform] (position,
  /// jelly scale, global screen offset). This means:
  ///
  /// - The image represents the pill SDF purely in the render object's own
  ///   coordinate space, at its current LOCAL size.
  /// - [matteTransform] is applied SYNCHRONOUSLY at paint time to derive the
  ///   screen-space [uGeometryOffset] / [uGeometrySize] uniforms — no 1-2
  ///   frame async lag, no correction needed.
  /// - Geometry rebuilds are only needed when the LOCAL shape changes
  ///   (layout/style), not for every position or jelly-scale animation frame.
  (ui.Picture, Rect, Size) _recordGeometryPicture(
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> geometries,
    Rect bounds,
  ) {
    // Work in local coordinate space — no matteTransform applied.
    final localBounds = bounds.snapToPixels(devicePixelRatio);
    final size = localBounds.size * devicePixelRatio;

    final logging = LgrLogs.isLogActive(logger);
    final buffer = logging
        ? StringBuffer(
            '$hashCode Recording geometry picture (local space) with '
            '${geometries.length} shapes at size '
            '${size.width}x${size.height}:\n',
          )
        : null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    for (final (_, geometry, transform) in geometries) {
      canvas
        ..save()
        ..scale(devicePixelRatio)
        // Shift so localBounds.topLeft is the texture origin.
        ..translate(-localBounds.left, -localBounds.top)
        // Apply geometry-local → glass-local transform only (no matteTransform).
        ..transform(transform.storage)
        ..scale(1 / devicePixelRatio)
        ..translate(
          geometry.matteBounds.topLeft.dx,
          geometry.matteBounds.topLeft.dy,
        );

      switch (geometry) {
        case UnrenderedGeometryCache(matte: final picture):
          buffer?.writeln('\t- Unrendered @ ${geometry.bounds}');
          canvas.drawPicture(picture);
        case RenderedGeometryCache(matte: final image):
          buffer?.writeln('\t- Rendered @ ${geometry.bounds}');
          canvas.drawImage(image, Offset.zero, Paint());
      }

      canvas.restore();
    }

    if (buffer != null) logger.fine(buffer.toString());
    return (recorder.endRecording(), localBounds, size);
  }
}

@internal
class GeometryRenderLink {
  final List<RenderLiquidGlassGeometry> _shapeGeometries = [];

  UnmodifiableListView<RenderLiquidGlassGeometry> get shapes =>
      UnmodifiableListView(_shapeGeometries);

  bool _dirty = false;

  void updateAllGeometries() {
    for (final renderObject in _shapeGeometries) {
      renderObject.maybeRebuildGeometry();
    }
  }

  void registerGeometry(
    RenderLiquidGlassGeometry renderObject,
  ) {
    _dirty = true;
    _shapeGeometries.add(renderObject);
  }

  /// Signals that a geometry object has completed a rebuild and the render
  /// layer should integrate the updated result on the next paint.
  void notifyGeometryChanged(RenderLiquidGlassGeometry renderObject) {
    _dirty = true;
  }

  void unregisterGeometry(RenderLiquidGlassGeometry renderObject) {
    _shapeGeometries.remove(renderObject);
  }

  void dispose() {
    _shapeGeometries.clear();
  }
}

@internal
class InheritedGeometryRenderLink extends InheritedWidget {
  const InheritedGeometryRenderLink({
    required this.link,
    required super.child,
    super.key,
  });

  final GeometryRenderLink link;

  static GeometryRenderLink? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedGeometryRenderLink>()
        ?.link;
  }

  @override
  bool updateShouldNotify(covariant InheritedGeometryRenderLink oldWidget) {
    return oldWidget.link != link;
  }
}
