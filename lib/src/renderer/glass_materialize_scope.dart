import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../engine/liquid_glass_settings.dart';

/// Threads a materialize transition's per-frame state to the glass surfaces
/// below it, so they dissolve through the shader's own uniforms instead of
/// layer opacity.
///
/// An ancestor [Opacity] or [ImageFiltered] cannot fade glass: a backdrop
/// pass renders fully or not at all, so the glass pops while its child fades
/// (the same Impeller limitation [ProgressiveBlur] documents for ShaderMask).
/// Every uniform upload already reads the `effective*` getters on
/// [LiquidGlassSettings], which scale by [LiquidGlassSettings.visibility] —
/// at zero the refraction warp lerps to identity and the render object skips
/// the pass entirely. That is the legal fade channel, and this scope is how a
/// transition widget reaches it for every surface in its subtree at once.
///
/// Two channels ride on the scope:
///
/// * **Glass** — [glassProgress] scales `visibility`, the single input every
///   shader uniform and every widget-level decoration reads through its own
///   `effective*` getter. The configured blur is left alone: the shader
///   multiplies it by visibility, so a dissolving surface stops blurring its
///   backdrop as it goes. Driving the blur *up* to keep the surface looking
///   frosty smears whatever is behind a shape nobody can see any more.
/// * **Content** — [contentOpacity] and [contentSigma] fade and gaussian-blur
///   the glass *child*, which is ordinary painted content where those
///   compose fine. Kept separate from the glass channel so the transition can
///   lag one behind the other (glass resolves first, the icon sharpens last).
class GlassMaterializeScope extends InheritedWidget {
  /// Declares the materialize state for the glass surfaces below [child].
  const GlassMaterializeScope({
    required this.glassProgress,
    required this.contentOpacity,
    required this.contentSigma,
    required super.child,
    super.key,
  });

  /// How materialized the glass is: 0.0 = fully dematerialized, 1.0 = at
  /// rest. At 1.0 the scope is inert — [resolveSettings] returns its input
  /// unchanged and [wrapContent] adds nothing.
  final double glassProgress;

  /// Opacity applied to glass children, on top of the visibility fade the
  /// glass channel already applies through [LiquidGlassSettings].
  final double contentOpacity;

  /// Gaussian sigma applied to glass children, in logical pixels.
  final double contentSigma;

  /// The nearest scope above [context], or null when no transition is
  /// running anywhere above.
  static GlassMaterializeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassMaterializeScope>();

  /// Applies the nearest scope's glass channel to [base].
  ///
  /// Returns [base] itself — the same instance — when no scope is present or
  /// the scope is at rest, so resting glass pays nothing beyond the inherited
  /// lookup.
  static LiquidGlassSettings resolveSettings(
    BuildContext context,
    LiquidGlassSettings base,
  ) {
    final scope = maybeOf(context);
    if (scope == null || scope.glassProgress >= 1.0) return base;
    return scope._transform(base);
  }

  /// Applies the nearest scope's content channel around [child].
  ///
  /// Returns [child] untouched when no scope is present. When a scope is
  /// present, [Opacity] and [ImageFiltered] stay mounted at every progress
  /// (with `enabled: scope.contentSigma > 0.0` so resting content pushes zero
  /// compositing layers) — keeping the child's element depth constant across
  /// `0.0 ↔ 1.0` so stateful children (such as focused inputs or scrollables
  /// inside a materializing dialog) never remount when a transition starts or
  /// settles.
  static Widget wrapContent(BuildContext context, Widget child) {
    final scope = maybeOf(context);
    if (scope == null) {
      return child;
    }
    return GlassControlledOpacity(
      opacity: scope.contentOpacity,
      child: ImageFiltered(
        enabled: scope.contentSigma > 0.0,
        imageFilter: ui.ImageFilter.blur(
          sigmaX: scope.contentSigma,
          sigmaY: scope.contentSigma,
        ),
        child: child,
      ),
    );
  }

  /// Scales `visibility`, and nothing else.
  ///
  /// Every channel that has to fade with the glass — the shader uniforms, the
  /// shadow, the whitening veil, the backer pad — reads its own `effective*`
  /// getter, and each of those already multiplies by `visibility`. Scaling any
  /// of them here as well applied the progress twice: the built-in shadow
  /// faded as t², so it left roughly twice as fast as the glass it belonged
  /// to.
  LiquidGlassSettings _transform(LiquidGlassSettings base) => base.copyWith(
      visibility: base.visibility * glassProgress.clamp(0.0, 1.0));

  @override
  bool updateShouldNotify(GlassMaterializeScope oldWidget) =>
      glassProgress != oldWidget.glassProgress ||
      contentOpacity != oldWidget.contentOpacity ||
      contentSigma != oldWidget.contentSigma;
}

/// An opacity wrapper that stays mounted across `0.0 ↔ 1.0` for stable child
/// element identity, while setting `alwaysNeedsCompositing = false` (and thus
/// `isRepaintBoundary = false`) at both `alpha == 0` and `alpha == 255` (`1.0`).
///
/// Subclasses Flutter's [RenderOpacity] (`rendering/proxy_box.dart`), which
/// sets `alwaysNeedsCompositing => child != null && _alpha > 0` and keeps an
/// [OpacityLayer] + repaint boundary alive even at `opacity == 1.0` — forcing
/// `needsCompositing = true` on resting glass ancestors when `blur == 0` or
/// shaders are unloaded. Overriding [RenderOpacity.alwaysNeedsCompositing]
/// inherits all framework paint, layer-update, and semantics logic verbatim.
class GlassControlledOpacity extends SingleChildRenderObjectWidget {
  /// Creates an opacity wrapper that only requests compositing when fractional.
  const GlassControlledOpacity({
    required this.opacity,
    required super.child,
    super.key,
  });

  /// Target opacity, clamped to `[0.0, 1.0]`.
  final double opacity;

  @override
  RenderOpacity createRenderObject(BuildContext context) =>
      _RenderGlassControlledOpacity(opacity: opacity.clamp(0.0, 1.0));

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderOpacity renderObject,
  ) {
    renderObject.opacity = opacity.clamp(0.0, 1.0);
  }
}

class _RenderGlassControlledOpacity extends RenderOpacity {
  _RenderGlassControlledOpacity({required super.opacity});

  @override
  bool get alwaysNeedsCompositing =>
      super.alwaysNeedsCompositing &&
      ui.Color.getAlphaFromOpacity(opacity) < 255;
}
