// ignore_for_file: avoid_setters_without_getters

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../liquid_glass_renderer.dart';
import '../internal/render_liquid_glass_geometry.dart';
import '../internal/transform_tracking_repaint_boundary_mixin.dart';
import '../liquid_glass_render_scope.dart';
import '../logging.dart';
import 'liquid_glass_render_object.dart';
import '../shaders.dart';
import 'package:meta/meta.dart';

/// Represents a layer of multiple [LiquidGlass] shapes or
/// [LiquidGlassBlendGroup]s that have shared [LiquidGlassSettings] and will be
/// rendered together.
///
/// If you create a [LiquidGlassLayer] with one or more [LiquidGlass] or
/// [LiquidGlassBlendGroup] widgets, the liquid glass effect will be rendered
/// where this layer is.
///
/// Make sure not to stack any other widgets between the [LiquidGlassLayer] and
/// the [LiquidGlass] widgets, otherwise the liquid glass effect will be behind
/// them.
///
/// ## Example
///
/// ```dart
/// Widget build(BuildContext context) {
///   return LiquidGlassLayer(
///     child: Column(
///       children: [
///         LiquidGlass(
///           shape: LiquidRoundedSuperellipse(
///             borderRadius: 10,
///           ),
///           child: const SizedBox.square(
///             dimension: 100,
///           ),
///         ),
///         const SizedBox(height: 100),
///         LiquidGlassBlendGroup(
///          blend: 20,
///          child: Row(
///             children: [
///               LiquidGlass.grouped(
///                 shape: const LiquidOval(),
///                 child: const SizedBox.square(
///                   dimension: 100,
///                 ),
///               ),
///               LiquidGlass.grouped(
///                 shape: const LiquidRoundedSuperellipse(
///                   borderRadius: 20,
///                 ),
///                 child: const SizedBox.square(
///                   dimension: 100,
///                 ),
///               ),
///             ],
///           ),
///         ),
///       ],
///     ),
///   );
/// }
class LiquidGlassLayer extends StatefulWidget {
  /// Creates a new [LiquidGlassLayer] with the given [child] and [settings].
  const LiquidGlassLayer({
    required this.child,
    this.settings = const LiquidGlassSettings(),
    this.clipExpansion = EdgeInsets.zero,
    super.key,
  });

  /// The subtree in which you should include at least one [LiquidGlass] widget.
  ///
  /// The [LiquidGlassLayer] will automatically register all [LiquidGlass]
  /// widgets in the subtree as shapes and render them.
  final Widget child;

  /// The settings for the liquid glass effect for all shapes in this layer.
  final LiquidGlassSettings settings;

  /// Extra space to add around the geometry bounding box before clipping the
  /// [BackdropFilterLayer] that runs the glass shader.
  ///
  /// The clip rect is normally tight to the glass shape's geometry.  Any
  /// ancestor [Transform] (e.g. jelly squash-and-stretch on an indicator)
  /// can push painted pixels outside that tight rect, producing a hard edge
  /// cutoff.  Set [clipExpansion] to a safe margin that covers the maximum
  /// expected deformation so the shader is applied over the full animated area.
  ///
  /// Defaults to [EdgeInsets.zero] — zero extra GPU cost for static glass.
  final EdgeInsets clipExpansion;

  @override
  State<LiquidGlassLayer> createState() => _LiquidGlassLayerState();
}

class _LiquidGlassLayerState extends State<LiquidGlassLayer>
    with SingleTickerProviderStateMixin {
  late final GeometryRenderLink _link = GeometryRenderLink();

  late final logger = Logger(LgrLogNames.layer);

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ImageFilter.isShaderFilterSupported) {
      logger.warning(
          'LiquidGlassLayer requires Impeller. No glass effect will be '
          'rendered on this platform.');
      return LiquidGlassRenderScope(
        settings: widget.settings,
        child: InheritedGeometryRenderLink(
          link: _link,
          child: widget.child,
        ),
      );
    }

    return BackdropGroup(
      child: RepaintBoundary(
        child: LiquidGlassRenderScope(
          settings: widget.settings,
          child: InheritedGeometryRenderLink(
            link: _link,
            child: ShaderBuilder(
              assetKey: ShaderKeys.liquidGlassRender,
              (context, shader, child) => _RawShapes(
                renderShader: shader,
                backdropKey: BackdropGroup.of(context)?.backdropKey,
                settings: widget.settings,
                link: _link,
                clipExpansion: widget.clipExpansion,
                child: child!,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _RawShapes extends SingleChildRenderObjectWidget {
  const _RawShapes({
    required this.renderShader,
    required this.backdropKey,
    required this.settings,
    required Widget super.child,
    required this.link,
    this.clipExpansion = EdgeInsets.zero,
  });

  final FragmentShader renderShader;
  final BackdropKey? backdropKey;
  final LiquidGlassSettings settings;
  final GeometryRenderLink link;
  final EdgeInsets clipExpansion;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlassLayer(
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      renderShader: renderShader,
      backdropKey: backdropKey,
      settings: settings,
      link: link,
      clipExpansion: clipExpansion,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlassLayer renderObject,
  ) {
    renderObject
      ..link = link
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..settings = settings
      ..backdropKey = backdropKey
      ..clipExpansion = clipExpansion;
  }
}

@internal
class RenderLiquidGlassLayer extends LiquidGlassRenderObject
    with TransformTrackingRenderObjectMixin {
  RenderLiquidGlassLayer({
    required super.renderShader,
    required super.devicePixelRatio,
    required super.settings,
    required super.link,
    super.backdropKey,
    EdgeInsets clipExpansion = EdgeInsets.zero,
  }) : _clipExpansion = clipExpansion;

  final _shaderHandle = LayerHandle<BackdropFilterLayer>();
  final _blurLayerHandle = LayerHandle<BackdropFilterLayer>();
  final _clipRectLayerHandle = LayerHandle<ClipRectLayer>();
  final _clipPathLayerHandle = LayerHandle<ClipPathLayer>();

  EdgeInsets _clipExpansion;
  set clipExpansion(EdgeInsets value) {
    if (_clipExpansion == value) return;
    _clipExpansion = value;
    markNeedsPaint();
  }

  @override
  Size get desiredMatteSize => switch (owner?.rootNode) {
        final RenderView rv => rv.size,
        final RenderBox rb => rb.size,
        _ => Size.zero,
      };

  @override
  Matrix4 get matteTransform => getTransformTo(null);

  @override
  void onTransformChanged() {
    // Transform changes (position, jelly scale, scroll) no longer require a
    // geometry rebuild. The geometry image is in LOCAL space; matteTransform is
    // applied synchronously at paint time so the screen position is always
    // exact with zero async lag.  Only layout() still sets needsGeometryUpdate.
    markNeedsPaint();
  }

  @override
  void paintLiquidGlass(
    PaintingContext context,
    Offset offset,
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes,
    Rect boundingBox,
  ) {
    if (!attached) return;

    // ── Pass 1: Blur ─────────────────────────────────────────────────────────
    // Use Flutter's native ImageFilter.blur for smooth, multi-pass Gaussian
    // quality (the inline 9-tap shader approximation was pixelated with text).
    // Clip tightly to the actual pill shape path — no expansion needed here.
    if (settings.effectiveBlur > 0) {
      final blurLayer = (_blurLayerHandle.layer ??= BackdropFilterLayer())
        ..backdropKey =
            backdropKey // Scoped to this LiquidGlassLayer's BackdropGroup
        ..filter = ImageFilter.blur(
          tileMode: TileMode.mirror,
          sigmaX: settings.effectiveBlur,
          sigmaY: settings.effectiveBlur,
        );

      final clipPath = Path();
      for (final geometry in shapes) {
        if (!geometry.$1.attached) continue;
        clipPath.addPath(
          geometry.$2.path,
          Offset.zero,
          matrix4: geometry.$3.storage,
        );
      }
      _clipPathLayerHandle.layer = context.pushClipPath(
        needsCompositing,
        offset,
        boundingBox,
        clipPath,
        (context, offset) {
          context.pushLayer(
            blurLayer,
            (context, offset) {
              paintShapeContents(context, offset, shapes, insideGlass: true);
            },
            offset,
          );
        },
        oldLayer: _clipPathLayerHandle.layer,
      );
    } else {
      _blurLayerHandle.layer = null;
      _clipPathLayerHandle.layer = null;
    }

    // ── Pass 2: Glass refraction + lighting shader ────────────────────────────
    // Inflate the clip rect by _clipExpansion so jelly squash-and-stretch can
    // push deformed pixels beyond the tight bounding box without a hard clip
    // edge. For static glass _clipExpansion == EdgeInsets.zero (no-op).
    final clipRect = _clipExpansion == EdgeInsets.zero
        ? boundingBox
        : Rect.fromLTRB(
            boundingBox.left - _clipExpansion.left,
            boundingBox.top - _clipExpansion.top,
            boundingBox.right + _clipExpansion.right,
            boundingBox.bottom + _clipExpansion.bottom,
          );

    final shaderLayer = (_shaderHandle.layer ??= BackdropFilterLayer())
      ..filter = ImageFilter.shader(renderShader);

    _clipRectLayerHandle.layer = context.pushClipRect(
      needsCompositing,
      offset,
      clipRect,
      (context, offset) {
        context.pushLayer(
          shaderLayer,
          (context, offset) {
            paintShapeContents(context, offset, shapes, insideGlass: false);
          },
          offset,
        );
      },
      oldLayer: _clipRectLayerHandle.layer,
    );
  }

  @override
  void dispose() {
    // Eagerly clear filter references on the backdrop layers before nulling
    // the handles. During isolate shutdown on Mali GPUs, GC finalization of
    // BackdropFilterLayer retains DlRuntimeEffectColorSource → TextureVK →
    // Vulkan mutex chains that outlive the GPU context (Crash 2). Clearing
    // the filter property breaks this retention chain immediately.
    _shaderHandle.layer?.filter = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
    _blurLayerHandle.layer?.filter = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
    _shaderHandle.layer = null;
    _blurLayerHandle.layer = null;
    _clipRectLayerHandle.layer = null;
    _clipPathLayerHandle.layer = null;
    super.dispose();
  }
}
