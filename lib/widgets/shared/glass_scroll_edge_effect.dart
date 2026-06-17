import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../interactive/liquid_glass_scope.dart';
import 'glass_content_aware_scope.dart';

/// Edge effect style matching iOS 26's `.scrollEdgeEffectStyle`.
///
/// Controls how scroll content fades at the edges when it meets a glass
/// surface (navigation bar, bottom bar, etc.).
enum GlassScrollEdgeStyle {
  /// A rounded, diffused fade — content dissolves smoothly into the bar area.
  ///
  /// Matches iOS 26's `.soft` edge effect style. This is the default and is
  /// ideal for most list/scroll views with transparent navigation bars.
  soft,

  /// A crisp boundary — content has a sharper cutoff at the bar edge.
  ///
  /// Matches iOS 26's `.hard` edge effect style. Useful when you want a
  /// clear visual separation between the bar and content.
  hard,
}

/// A widget that fades scroll content at the top and/or bottom edges.
///
/// Matches iOS 26's `.scrollEdgeEffectStyle(_:for:)` modifier. Places gradient
/// overlays at the specified edges, creating the effect of content dissolving
/// into navigation bars or bottom bars rather than clipping sharply.
///
/// ## How it works
///
/// **Inside [GlassPage]** (recommended): Automatically captures the page's
/// background texture and paints it over the scroll edges with a gradient
/// alpha mask. This produces a pixel-perfect fade for ANY background —
/// images, patterns, mesh gradients, anything. No configuration needed.
///
/// **Outside [GlassPage]**: Falls back to a solid-colour gradient overlay
/// using [fadeColor] (or the scaffold background colour from the theme).
/// Works perfectly for solid-colour and simple gradient backgrounds.
///
/// ## Why not ShaderMask?
///
/// `ShaderMask(blendMode: BlendMode.dstIn)` creates a `saveLayer` that
/// breaks `BackdropFilterLayer` (premium glass) on Impeller — glass widgets
/// inside it render as opaque black because `BackdropFilterLayer` samples an
/// empty backdrop within the `saveLayer` boundary. This widget avoids that
/// by placing overlays ON TOP of the content rather than wrapping it.
///
/// ## Usage
///
/// ```dart
/// GlassScrollEdgeEffect(
///   topFadeHeight: 100,
///   bottomFadeHeight: 80,
///   child: ListView.builder(
///     itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
///   ),
/// )
/// ```
///
/// ## With GlassAppBar
///
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: GlassAppBar(title: Text('Messages')),
///   body: GlassScrollEdgeEffect(
///     topFadeHeight: MediaQuery.paddingOf(context).top + 44 + 50,
///     bottomFadeHeight: 60 + MediaQuery.paddingOf(context).bottom,
///     child: ListView(...),
///   ),
/// )
/// ```
///
/// The [topFadeHeight] should typically cover the safe area + app bar height
/// + a buffer zone so content fades before reaching the navigation buttons.
class GlassScrollEdgeEffect extends StatefulWidget {
  /// Creates a scroll edge effect that fades content at the edges.
  ///
  /// When used inside a [GlassPage] with a background widget, the fade
  /// automatically uses the page's background texture for a pixel-perfect
  /// effect. No [fadeColor] is needed.
  ///
  /// When used outside [GlassPage], provide [fadeColor] to match your
  /// background, or let it default to the scaffold background colour.
  const GlassScrollEdgeEffect({
    super.key,
    required this.child,
    this.topFadeHeight = 100.0,
    this.bottomFadeHeight = 60.0,
    this.fadeTop = true,
    this.fadeBottom = true,
    this.style = GlassScrollEdgeStyle.soft,
    this.fadeColor,
    this.contentAwareFade = false,
    this.darkFadeColor,
    this.luminanceDarkBelow = 0.45,
    this.luminanceLightAbove = 0.72,
    this.fadeDuration = const Duration(milliseconds: 280),
  }) : assert(
          luminanceDarkBelow < luminanceLightAbove,
          'luminanceDarkBelow must be below luminanceLightAbove',
        );

  /// The scrollable content to apply edge fading to.
  final Widget child;

  /// The height of the top fade zone in logical pixels.
  ///
  /// Content within this zone fades from fully transparent (at the top edge)
  /// to fully visible. Should cover the safe area + navigation bar height +
  /// a buffer zone.
  ///
  /// Defaults to 100.0.
  final double topFadeHeight;

  /// The height of the bottom fade zone in logical pixels.
  ///
  /// Content within this zone fades from fully visible to fully transparent
  /// (at the bottom edge). Should cover the bottom bar height + safe area.
  ///
  /// Defaults to 60.0.
  final double bottomFadeHeight;

  /// Whether to fade content at the top edge.
  ///
  /// Defaults to true.
  final bool fadeTop;

  /// Whether to fade content at the bottom edge.
  ///
  /// Defaults to true.
  final bool fadeBottom;

  /// The edge effect style.
  ///
  /// [GlassScrollEdgeStyle.soft] produces a gradual, diffused fade (default).
  /// [GlassScrollEdgeStyle.hard] produces a sharper cutoff.
  ///
  /// Matches iOS 26's `.scrollEdgeEffectStyle(.soft/.hard, for: .top)`.
  final GlassScrollEdgeStyle style;

  /// Fallback colour used when no background texture is available.
  ///
  /// This is only used outside [GlassPage] (i.e. when there is no
  /// [LiquidGlassScope] ancestor providing a background texture).
  ///
  /// When `null`, falls back to the scaffold background colour from the
  /// current theme.
  final Color? fadeColor;

  /// Whether each fade band darkens with the content scrolling beneath it.
  ///
  /// This is the continuous companion to the content-aware brightness
  /// verdict — the App Store-style scrim lever. Each enabled edge registers
  /// its own band with the enclosing [GlassContentAwareScope] and receives
  /// the band's **mean content luminance** per sample. As the content under
  /// a band moves through the medium range, a [darkFadeColor] gradient
  /// cross-fades in over the normal fade (fully dark at
  /// [luminanceDarkBelow], fully off at [luminanceLightAbove]) — so the
  /// scrim darkens *early* over medium content while the bars' contrast
  /// vote flips their appearance *late*, matching the native behavior.
  ///
  /// Requires an enclosing [GlassContentAwareScope] with the content wrapped
  /// in a `GlassContentAwareContent` (one flag on `GlassScaffold` wires all
  /// of it). Without a scope the bands keep their static appearance.
  ///
  /// Defaults to false.
  final bool contentAwareFade;

  /// The scrim colour the bands darken toward when [contentAwareFade] is on.
  ///
  /// Rendered as an additional gradient (same curve as the base fade) whose
  /// opacity follows the band's content darkness. Defaults to black.
  final Color? darkFadeColor;

  /// Mean band luminance at or below which the dark scrim is fully opaque.
  ///
  /// Must be below [luminanceLightAbove]. Defaults to 0.45 — medium-dark
  /// content already pulls the scrim fully dark, the early-darkening
  /// behavior of the native bottom scrim.
  final double luminanceDarkBelow;

  /// Mean band luminance at or above which the dark scrim is fully off.
  ///
  /// Must be above [luminanceDarkBelow]. Defaults to 0.72.
  final double luminanceLightAbove;

  /// Duration of the scrim darkness animation between sampled targets.
  ///
  /// Defaults to 280 ms with an ease-out curve.
  final Duration fadeDuration;

  @override
  State<GlassScrollEdgeEffect> createState() => _GlassScrollEdgeEffectState();
}

class _GlassScrollEdgeEffectState extends State<GlassScrollEdgeEffect>
    with TickerProviderStateMixin {
  GlobalKey? _backgroundKey;
  ui.Image? _backgroundImage;
  bool _hasAttemptedCapture = false;
  bool _capturePending = false;

  // ── Content-aware fade (the scrim lever) ──────────────────────────────────
  // Each enabled edge registers its own band rect with the enclosing
  // GlassContentAwareScope and animates a darkness value from the band's
  // sampled mean luminance. Independent per edge: the bottom band can sit
  // over dark content while the top band is over light content.
  final GlobalKey _topBandKey = GlobalKey();
  final GlobalKey _bottomBandKey = GlobalKey();
  // Created eagerly in initState — a lazy `late final` here would be
  // first touched in dispose() when the adaptive fade was never used,
  // and creating a vsync'd controller during teardown looks up TickerMode
  // on a deactivated element.
  late final AnimationController _topDarkness;
  late final AnimationController _bottomDarkness;
  GlassContentAwareScopeState? _scope;
  GlassContentAwareSubscription? _topSub;
  GlassContentAwareSubscription? _bottomSub;

  @override
  void initState() {
    super.initState();
    _topDarkness = AnimationController(vsync: this);
    _bottomDarkness = AnimationController(vsync: this);
  }

  /// Current darkness (0–1) of the top band's adaptive scrim.
  @visibleForTesting
  double get topDarkness => _topDarkness.value;

  /// Current darkness (0–1) of the bottom band's adaptive scrim.
  @visibleForTesting
  double get bottomDarkness => _bottomDarkness.value;

  /// Keeps the per-edge scope registrations in sync with the configuration.
  ///
  /// Runs at the top of build (inherited lookups are legal there and this is
  /// where dependencies must be registered anyway) and is idempotent.
  void _syncContentAware() {
    final want = widget.contentAwareFade
        ? GlassContentAwareScope.maybeOf(context)
        : null;
    final wantTop = want != null && widget.fadeTop;
    final wantBottom = want != null && widget.fadeBottom;
    if (_scope == want &&
        (_topSub != null) == wantTop &&
        (_bottomSub != null) == wantBottom) {
      return;
    }
    _topSub?.cancel();
    _bottomSub?.cancel();
    _topSub = null;
    _bottomSub = null;
    _scope = want;
    if (wantTop) {
      _topSub = want.register(
        controlBox: () => _bandBox(_topBandKey),
        onLuminanceChanged: (luminance) =>
            _onBandLuminance(_topDarkness, luminance),
        gridColumns: 4,
      );
    }
    if (wantBottom) {
      _bottomSub = want.register(
        controlBox: () => _bandBox(_bottomBandKey),
        onLuminanceChanged: (luminance) =>
            _onBandLuminance(_bottomDarkness, luminance),
        gridColumns: 4,
      );
    }
  }

  RenderBox? _bandBox(GlobalKey key) {
    if (!mounted) return null;
    final ro = key.currentContext?.findRenderObject();
    return ro is RenderBox ? ro : null;
  }

  void _onBandLuminance(AnimationController darkness, double luminance) {
    // Map mean luminance to scrim darkness: fully dark at/below
    // luminanceDarkBelow, fully off at/above luminanceLightAbove, smooth
    // crossfade in between — darkens EARLY over medium content, unlike the
    // late-flipping contrast vote.
    final target = 1.0 -
        ((luminance - widget.luminanceDarkBelow) /
                (widget.luminanceLightAbove - widget.luminanceDarkBelow))
            .clamp(0.0, 1.0);
    if ((target - darkness.value).abs() < 0.01) return;
    darkness.animateTo(
      target,
      duration: widget.fadeDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backgroundKey = LiquidGlassScope.of(context);

    // Defer capture to after paint. On first mount, toImage() requires a
    // composited OffsetLayer which isn't assigned until paint completes.
    // On subsequent calls (theme toggle, route change), the new background
    // won't paint until end-of-frame either. Both cases need deferral.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _captureBackground();
    });
  }

  void _captureBackground() {
    if (_backgroundKey == null) {
      _hasAttemptedCapture = true;
      return;
    }

    final boundary = _backgroundKey!.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary == null || !boundary.hasSize || boundary.size.isEmpty) {
      // Boundary not ready yet — retry after the first frame.
      if (!_hasAttemptedCapture) {
        _hasAttemptedCapture = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _captureBackground();
        });
      }
      return;
    }

    _hasAttemptedCapture = true;

    // In debug mode, toImageSync asserts if the boundary is marked as needing paint.
    // If it needs paint, wait for the next frame.
    bool needsPaint = false;
    assert(() {
      needsPaint = boundary.debugNeedsPaint;
      return true;
    }());

    if (needsPaint) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _captureBackground();
      });
      return;
    }

    if (_capturePending) return; // Already in-flight — don't stack captures.
    _capturePending = true;
    try {
      boundary.toImage(pixelRatio: 1.0).then((image) {
        _capturePending = false;
        if (!mounted) {
          image.dispose();
          return;
        }
        _backgroundImage?.dispose();
        _backgroundImage = image;
        setState(() {});
      }).catchError((_) {
        _capturePending = false;
      });
    } on Object {
      // toImage() can throw synchronously if `layer` is still null
      // (paint has not completed). Reset the flag and fall back to
      // the solid-colour gradient overlay.
      _capturePending = false;
    }
  }

  @override
  void dispose() {
    _topSub?.cancel();
    _bottomSub?.cancel();
    _topDarkness.dispose();
    _bottomDarkness.dispose();
    _backgroundImage?.dispose();
    _backgroundImage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncContentAware();

    // No fading needed — return child directly.
    if (!widget.fadeTop && !widget.fadeBottom) return widget.child;

    final screenSize = MediaQuery.sizeOf(context);
    final hasTexture = _backgroundImage != null;

    return Stack(
      children: [
        // 1. Scroll content — no compositing layer wrapping it.
        widget.child,

        // 2. Top fade overlay.
        if (widget.fadeTop)
          _buildOverlay(
            isTop: true,
            height: _effectiveHeight(widget.topFadeHeight, screenSize.height),
            screenSize: screenSize,
            hasTexture: hasTexture,
          ),

        // 3. Bottom fade overlay.
        if (widget.fadeBottom)
          _buildOverlay(
            isTop: false,
            height:
                _effectiveHeight(widget.bottomFadeHeight, screenSize.height),
            screenSize: screenSize,
            hasTexture: hasTexture,
          ),
      ],
    );
  }

  Widget _buildOverlay({
    required bool isTop,
    required double height,
    required Size screenSize,
    required bool hasTexture,
  }) {
    // Adaptive path: the fade's target darkens toward darkFadeColor by the
    // band's sampled content luminance, so over dark content it dissolves
    // toward dark (invisible against dark content) instead of always toward
    // the light page background. The band key marks the rect the scope samples
    // (the scope reads the CONTENT behind the fade, not the fade itself — the
    // GlassScaffold wrap order keeps the fade outside the captured region, so
    // there's no feedback loop).
    if (widget.contentAwareFade) {
      final darkness = isTop ? _topDarkness : _bottomDarkness;
      return Positioned(
        top: isTop ? 0 : null,
        bottom: isTop ? null : 0,
        left: 0,
        right: 0,
        height: height,
        child: IgnorePointer(
          key: isTop ? _topBandKey : _bottomBandKey,
          child: AnimatedBuilder(
            animation: darkness,
            builder: (context, _) => _fadeLayer(
              isTop: isTop,
              height: height,
              screenSize: screenSize,
              hasTexture: hasTexture,
              darkness: darkness.value,
            ),
          ),
        ),
      );
    }

    // Non-adaptive path — unchanged behaviour (darkness fixed at 0).
    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: _fadeLayer(
          isTop: isTop,
          height: height,
          screenSize: screenSize,
          hasTexture: hasTexture,
          darkness: 0.0,
        ),
      ),
    );
  }

  /// Builds one edge's fade layer: the captured-texture painter inside a
  /// [GlassPage], or the solid-colour gradient otherwise. [darkness] (0–1)
  /// drives content-aware darkening on both paths (0 = the plain fade).
  Widget _fadeLayer({
    required bool isTop,
    required double height,
    required Size screenSize,
    required bool hasTexture,
    required double darkness,
  }) {
    return hasTexture
        ? CustomPaint(
            size: Size(screenSize.width, height),
            painter: _TextureFadePainter(
              image: _backgroundImage!,
              isTop: isTop,
              screenHeight: screenSize.height,
              style: widget.style,
              darkness: darkness,
              darkColor: widget.darkFadeColor ?? const Color(0xFF000000),
            ),
          )
        : _buildColorOverlay(isTop: isTop, darkness: darkness);
  }

  /// Solid-colour gradient overlay (used outside [GlassPage], and for the
  /// adaptive path). When [darkness] > 0 the fade target is lerped toward
  /// [GlassScrollEdgeEffect.darkFadeColor], so the whole gradient — including
  /// the visible region above the bar — reflects the content's darkness.
  Widget _buildColorOverlay({required bool isTop, double darkness = 0.0}) {
    final base =
        widget.fadeColor ?? CupertinoTheme.of(context).scaffoldBackgroundColor;
    final color = darkness > 0
        ? Color.lerp(
            base, widget.darkFadeColor ?? const Color(0xFF000000), darkness)!
        : base;
    final curve = _kFadeCurves[widget.style]!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: curve.alphas
              .map((a) => color.withValues(alpha: color.a * a))
              .toList(),
          stops: curve.stops,
        ),
      ),
    );
  }

  double _effectiveHeight(double height, double boundsHeight) {
    // Hard style uses a tighter transition zone (half of soft) combined with
    // a steeper gradient curve — so it's a different *shape*, not just a
    // compressed version of soft.
    final adjusted =
        widget.style == GlassScrollEdgeStyle.hard ? height * 0.5 : height;
    // Clamp to 40% of available height to avoid overlapping zones.
    return adjusted.clamp(0.0, boundsHeight * 0.4);
  }
}

/// Pre-computed gradient curves for each [GlassScrollEdgeStyle].
///
/// Each curve defines the alpha values and corresponding stops for a
/// multi-stop gradient that produces a perceptually smooth fade. A simple
/// 2-stop linear ramp (the previous implementation) appears non-uniform to
/// the human eye — denser in the middle — and terminates with a visible seam.
///
/// These curves are modelled after iOS 26's scroll edge effect:
/// - **Soft**: gentle ease-in dissolve with a long transparent tail, producing
///   a diffused fade that dissolves content smoothly into the bar area.
/// - **Hard**: holds opacity longer then drops sharply, but still includes a
///   feathered tail to avoid the hard cutoff seam.
class _FadeCurve {
  const _FadeCurve(this.alphas, this.stops);

  /// Alpha multipliers from edge (1.0 = fully opaque) to content (0.0).
  final List<double> alphas;

  /// Corresponding gradient stop positions in [0, 1].
  final List<double> stops;
}

const Map<GlassScrollEdgeStyle, _FadeCurve> _kFadeCurves = {
  // Soft: gentle ease-in dissolve. Holds opacity briefly at the edge, then
  // accelerates through the mid-range, and includes a long low-alpha tail
  // that reaches fully transparent well before the overlay boundary —
  // eliminating the visible seam.
  GlassScrollEdgeStyle.soft: _FadeCurve(
    [1.0, 0.70, 0.30, 0.04, 0.0],
    [0.0, 0.15, 0.45, 0.75, 0.92],
  ),
  // Hard: crisp but feathered. Stays opaque for longer (the "hard" feel),
  // then drops more steeply, but still includes a tail to prevent seaming.
  // Combined with the 0.5× height multiplier in _effectiveHeight, this
  // produces a noticeably crisper boundary than soft without a sharp line.
  GlassScrollEdgeStyle.hard: _FadeCurve(
    [1.0, 0.90, 0.50, 0.04, 0.0],
    [0.0, 0.30, 0.60, 0.85, 0.95],
  ),
};

/// Paints a slice of the background texture with a gradient alpha mask.
///
/// This is the core of the texture overlay approach: it takes the background
/// image captured by [GlassBackgroundSource], extracts the top or bottom
/// strip, and paints it with a gradient from fully opaque (at the edge) to
/// fully transparent (towards the content). Visually, this is identical to
/// fading the content to transparent and revealing the background.
///
/// Uses [BlendMode.dstIn] inside a [Canvas.saveLayer] to apply the gradient
/// mask. Since this painter only draws a static image (no [BackdropFilterLayer]),
/// the `saveLayer` is safe and does not interfere with glass rendering.
class _TextureFadePainter extends CustomPainter {
  _TextureFadePainter({
    required this.image,
    required this.isTop,
    required this.screenHeight,
    required this.style,
    this.darkness = 0.0,
    this.darkColor = const Color(0xFF000000),
  });

  final ui.Image image;
  final bool isTop;
  final double screenHeight;
  final GlassScrollEdgeStyle style;

  /// Content-aware darkening, 0–1. When > 0 the captured strip is blended
  /// toward [darkColor] by this amount BEFORE the gradient mask, so the
  /// adaptive fade dissolves toward dark over dark content instead of
  /// revealing the (typically light) page background as a bright scrim.
  final double darkness;
  final Color darkColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // The image is captured at pixelRatio: 1.0, so its pixel dimensions
    // match logical dimensions. Calculate the source strip from the
    // corresponding edge of the background.
    final double scaleY = image.height / screenHeight;

    final Rect srcRect = isTop
        ? Rect.fromLTWH(0, 0, image.width.toDouble(), size.height * scaleY)
        : Rect.fromLTWH(
            0,
            image.height - size.height * scaleY,
            image.width.toDouble(),
            size.height * scaleY,
          );

    final Rect dstRect = Offset.zero & size;

    // Paint the background strip with gradient alpha.
    // saveLayer is safe here — no BackdropFilterLayer inside.
    canvas.saveLayer(dstRect, Paint());

    // Draw the background texture slice.
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    // Content-aware darkening: blend the whole strip toward darkColor by
    // [darkness] BEFORE the alpha mask. Applying it pre-mask (uniform over the
    // strip) means the darkening survives across the full visible band rather
    // than concentrating at the occluded edge — so over dark content the fade
    // reads dark, not as the light page background.
    if (darkness > 0) {
      canvas.drawRect(
        dstRect,
        Paint()..color = darkColor.withValues(alpha: darkness.clamp(0.0, 1.0)),
      );
    }

    // Apply gradient alpha mask: opaque at the edge, transparent towards
    // the content. Uses a multi-stop eased gradient to produce a
    // perceptually smooth fade without a visible seam at the boundary.
    final curve = _kFadeCurves[style]!;
    final gradientPaint = Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = LinearGradient(
        begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
        colors: curve.alphas
            .map((a) => Color.fromARGB((a * 255).round(), 0, 0, 0))
            .toList(),
        stops: curve.stops,
      ).createShader(dstRect);

    canvas.drawRect(dstRect, gradientPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TextureFadePainter oldDelegate) =>
      image != oldDelegate.image ||
      isTop != oldDelegate.isTop ||
      screenHeight != oldDelegate.screenHeight ||
      style != oldDelegate.style ||
      darkColor != oldDelegate.darkColor ||
      // darkness last: it changes every animation tick (other fields equal),
      // so this clause is the one always reached/evaluated.
      darkness != oldDelegate.darkness;
}
