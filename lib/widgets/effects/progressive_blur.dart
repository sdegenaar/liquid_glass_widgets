import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The edge a [ProgressiveBlur] is *strongest* at; it eases to perfectly sharp
/// at the opposite edge. Named after the direction the blur travels — e.g.
/// [topToBottom] is heavy at the top and dissolves downward (the classic
/// app-bar / status-bar look), [bottomToTop] is heavy at the bottom (e.g. a
/// bottom bar or a fade above a docked toolbar).
enum ProgressiveBlurDirection {
  /// Strong at the top edge, sharp at the bottom.
  topToBottom,

  /// Strong at the bottom edge, sharp at the top.
  bottomToTop,

  /// Strong at the left edge, sharp at the right.
  leftToRight,

  /// Strong at the right edge, sharp at the left.
  rightToLeft;

  /// The `uDirection` uniform value the shader expects (0 top, 1 bottom, 2 left,
  /// 3 right = where the blur is strongest).
  double get _uniform => index.toDouble();
}

/// A *progressive* (graduated) backdrop blur — the Signal / iOS-26 header look:
/// a clean gaussian frost that is strongest at one edge and eases to perfectly
/// sharp at the opposite edge. Stack it behind a translucent app bar so content
/// dissolves beneath it instead of ending on a hard cut-off.
///
/// This is the graduated-blur primitive the rest of the library does not
/// provide (glass surfaces apply a *uniform* blur). It is self-contained — it
/// needs no [LiquidGlassLayer] or glass ancestor — so it can back any bar.
///
/// ## How it works — a single GPU pass that samples the backdrop
///
/// The naive "blur then fade with a ShaderMask" recipe does NOT work: a
/// [BackdropFilter]'s captured backdrop is not included in an ancestor
/// [ShaderMask]'s layer on Impeller, so the mask reveals nothing and iOS shows
/// no blur at all. Instead this uses [ui.ImageFilter.shader]: a fragment shader
/// runs as the [ui.ImageFilter] of a [BackdropFilter], so the engine binds the
/// captured backdrop to the shader's sampler — sampling it reliably on every
/// backend. `shaders/progressive_blur.frag` reads that backdrop with an
/// importance-sampled gaussian whose sigma follows the gradient (normalised over
/// the widget's own device-pixel rectangle, since the bound texture is the whole
/// screen), giving a smooth, band-free dissolve in one backdrop capture + one
/// draw.
///
/// Drive [maxSigma] from a scroll offset to fade the blur in/out (0 → sharp).
///
/// ```dart
/// Stack(
///   children: [
///     const Positioned(top: 0, left: 0, right: 0, height: 96,
///       child: ProgressiveBlur(maxSigma: 20)),
///     // ... your translucent app bar on top ...
///   ],
/// )
/// ```
///
/// Call [preload] once from `main()` (after the binding is initialised) to
/// pre-compile the shader so the first bar paint already has it.
class ProgressiveBlur extends StatefulWidget {
  const ProgressiveBlur({
    super.key,
    this.maxSigma = 18,
    this.direction = ProgressiveBlurDirection.topToBottom,
    this.falloff = 1.2,
  });

  /// Blur sigma (logical px) at the strong edge. 0 ⇒ no blur (passthrough).
  /// Optional — defaults to a moderate 18.
  final double maxSigma;

  /// Which edge the blur is strongest at (it eases to sharp at the opposite
  /// edge). Defaults to [ProgressiveBlurDirection.topToBottom].
  final ProgressiveBlurDirection direction;

  /// Gradient gamma. >1 keeps the blur strong across the strong edge then eases
  /// to sharp near the opposite edge.
  final double falloff;

  // ── Shader program: compiled once, process-wide ───────────────────────────
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

  /// Pre-compiles the blur shader so the first bar paint already has it. Safe to
  /// call repeatedly (compiled once). Call from `main()` after the binding is
  /// initialized. Never throws — on failure the widget falls back to a uniform
  /// blur.
  static Future<void> preload() async {
    if (_program != null) return;
    // Package-qualified asset path (this shader ships with the package); the
    // bare path is the fallback for unit tests where the package prefix may not
    // resolve.
    const path = 'packages/liquid_glass_widgets/shaders/progressive_blur.frag';
    const testPath = 'shaders/progressive_blur.frag';
    try {
      _program = await (_loading ??= _loadProgram(path, testPath));
    } catch (e) {
      // Graceful degradation: the widget falls back to a uniform blur. (Also the
      // path taken in unit tests, where compiled shaders aren't bundled.)
      _loading = null;
      debugPrint(
        'progressive_blur.frag load failed, using uniform-blur fallback: $e',
      );
    }
  }

  static Future<ui.FragmentProgram> _loadProgram(
    String path,
    String testPath,
  ) async {
    try {
      return await ui.FragmentProgram.fromAsset(path);
    } catch (_) {
      return ui.FragmentProgram.fromAsset(testPath);
    }
  }

  @override
  State<ProgressiveBlur> createState() => _ProgressiveBlurState();
}

class _ProgressiveBlurState extends State<ProgressiveBlur> {
  // Two instances of the same program: one blurs along X, the other along Y.
  ui.FragmentShader? _hShader;
  ui.FragmentShader? _vShader;

  @override
  void initState() {
    super.initState();
    _makeShaders();
    if (_hShader == null) {
      // Not pre-compiled yet — load, then rebuild with the shaders.
      ProgressiveBlur.preload().then((_) {
        if (mounted) setState(_makeShaders);
      });
    }
  }

  void _makeShaders() {
    final p = ProgressiveBlur._program;
    if (p != null && _hShader == null) {
      _hShader = p.fragmentShader();
      _vShader = p.fragmentShader();
    }
  }

  @override
  void dispose() {
    _hShader?.dispose();
    _vShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.maxSigma <= 0) return const SizedBox.expand();

    final h = _hShader;
    final v = _vShader;
    // Fallback — the shaders aren't ready yet, or the backend can't run shader
    // filters (Skia / web: isShaderFilterSupported == false). A single uniform
    // backdrop blur is a cheap stand-in; the translucent scrim above the bar
    // hides the harder bottom edge. Web/desktop have the headroom for it.
    if (h == null || v == null || !ui.ImageFilter.isShaderFilterSupported) {
      return ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: widget.maxSigma * 0.6,
            sigmaY: widget.maxSigma * 0.6,
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    // The bound texture (and thus uSize, float indices 0,1) is the WHOLE
    // backdrop, not this widget — so we pass the widget's own device-pixel
    // rectangle to normalise the gradient over the bar (see the .frag header).
    // The bar is anchored at the top-left of the backdrop layer (true for top
    // app bars), so its origin is (0,0); LayoutBuilder gives its size.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wPx = constraints.maxWidth * dpr;
        final hPx = constraints.maxHeight * dpr;
        void configure(ui.FragmentShader s, double axis) {
          s
            ..setFloat(2, widget.maxSigma * dpr)
            ..setFloat(3, widget.falloff)
            ..setFloat(4, widget.direction._uniform)
            ..setFloat(5, axis) // 0 = horizontal, 1 = vertical
            ..setFloat(6, 0) // region origin x (device px)
            ..setFloat(7, 0) // region origin y (device px)
            ..setFloat(8, wPx) // region width (device px)
            ..setFloat(9, hPx); // region height (device px)
        }

        configure(h, 0);
        configure(v, 1);

        // Separable 2-pass: horizontal (inner) then vertical (outer) = a clean
        // 2-D gaussian.
        final filter = ui.ImageFilter.compose(
          outer: ui.ImageFilter.shader(v),
          inner: ui.ImageFilter.shader(h),
        );

        return ClipRect(
          child: BackdropFilter(
            filter: filter,
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
