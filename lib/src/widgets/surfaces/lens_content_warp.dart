// ignore_for_file: public_member_api_docs
// Content warp of the native tab-bar lens (see IndicatorLensOptics).
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../utils/indicator_lens.dart';

/// The lens inside a [LensContentWarp] of the given size: its rounded
/// rectangle and the jelly transform applied to it.
typedef LensGeometryResolver = ({RRect rrect, Matrix4 transform}) Function(
    Size size);

/// Clips [child] to the lifted lens and bends it the way UIKit's
/// `liftedContentWarpWrapper` bends the selected-colour tab items: displaced
/// inward near the rim, so whatever crosses the edge folds back on itself.
///
/// Runs `lens_content_warp.frag` through [ui.ImageFilter.shader], so it needs
/// Impeller. Without it, before the shader has loaded, or while the lens
/// rests, [child] is only clipped.
class LensContentWarp extends StatefulWidget {
  const LensContentWarp({
    required this.optics,
    required this.lift,
    required this.lensGeometry,
    required this.child,
    this.backdrop = const Color(0xFFF5F5F7),
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// The native lens optics; only the content values are used here.
  final IndicatorLensOptics optics;

  /// How far the lens has lifted, `0` at rest to `1`. Scales the warp.
  final double lift;

  /// Resolves the lens in this widget's own coordinates.
  final LensGeometryResolver lensGeometry;

  /// The colour the lens shows behind the content. The colour fringe is
  /// split across the content composited over it, so dark items on a light
  /// lens fringe in colour the way they do natively.
  final Color backdrop;

  final Clip clipBehavior;

  final Widget child;

  static const _assetPath =
      'packages/liquid_glass_widgets/shaders/lens_content_warp.frag';
  static const _testAssetPath = 'shaders/lens_content_warp.frag';

  static ui.FragmentProgram? _program;
  static Future<void>? _loading;

  /// Whether the shader program is loaded.
  static bool get isReady => _program != null;

  /// Loads the shader program. Safe to call more than once.
  static Future<void> preWarm() {
    if (_program != null) return Future.value();
    return _loading ??= () async {
      try {
        _program = await ui.FragmentProgram.fromAsset(_assetPath);
      } catch (_) {
        try {
          _program = await ui.FragmentProgram.fromAsset(_testAssetPath);
        } catch (e) {
          debugPrint('[LensContentWarp] Pre-warm failed: $e');
        }
      } finally {
        _loading = null;
      }
    }();
  }

  @visibleForTesting
  static void resetForTesting() {
    _program = null;
    _loading = null;
  }

  @override
  State<LensContentWarp> createState() => _LensContentWarpState();
}

class _LensContentWarpState extends State<LensContentWarp> {
  static final ui.ImageFilter _identity =
      ui.ImageFilter.matrix(Matrix4.identity().storage);

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (!LensContentWarp.isReady && ui.ImageFilter.isShaderFilterSupported) {
      LensContentWarp.preWarm().then((_) {
        if (mounted && LensContentWarp.isReady) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  bool get _warping =>
      LensContentWarp._program != null &&
      widget.optics.enabled &&
      widget.lift > 0.001 &&
      ui.ImageFilter.isShaderFilterSupported;

  ui.ImageFilter _filterFor(Size size) {
    final lens = widget.lensGeometry(size);
    final rect = lens.rrect.outerRect;
    final m = lens.transform.storage;
    final optics = widget.optics;
    final shader = _shader ??= LensContentWarp._program!.fragmentShader();
    shader
      ..setFloat(2, size.width)
      ..setFloat(3, size.height)
      ..setFloat(4, rect.center.dx)
      ..setFloat(5, rect.center.dy)
      ..setFloat(6, rect.width / 2)
      ..setFloat(7, rect.height / 2)
      ..setFloat(8, lens.rrect.tlRadiusX)
      ..setFloat(9, optics.contentDisplacement * widget.lift)
      ..setFloat(10, optics.contentBevel)
      ..setFloat(11, optics.ovalization)
      ..setFloat(12, optics.aberration * widget.lift)
      ..setFloat(13, optics.aberrationBand)
      ..setFloat(14, m[0])
      ..setFloat(15, m[1])
      ..setFloat(16, m[4])
      ..setFloat(17, m[5])
      ..setFloat(18, m[12])
      ..setFloat(19, m[13])
      ..setFloat(20, widget.backdrop.r)
      ..setFloat(21, widget.backdrop.g)
      ..setFloat(22, widget.backdrop.b);
    return ui.ImageFilter.shader(shader);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final warping = _warping && !size.isEmpty;
        // While warping, the shader masks to the lens itself and ClipRect
        // bounds the filter's input texture. Switch ClipPath to Clip.none while
        // warping so a parent Clip.antiAliasWithSaveLayer doesn't allocate a
        // redundant full-bar offscreen saveLayer on top of ImageFiltered's own
        // shader pass every 120 Hz drag frame.
        return ClipPath(
          clipBehavior: warping ? Clip.none : widget.clipBehavior,
          clipper: _LensClipper(widget.lensGeometry, clipToLens: !warping),
          child: ImageFiltered(
            enabled: warping,
            imageFilter: warping ? _filterFor(size) : _identity,
            // The filtered texture has to cover exactly this box so the
            // shader can map its pixels back to logical coordinates: the clip
            // stops content from widening it, and the near-transparent fill
            // stops sparse content (a few glyphs) from narrowing it. Keep the
            // slot occupied by SizedBox.shrink() at rest so widget.child never
            // shifts index or remounts when warping toggles, while avoiding
            // 1/255 alpha overdraw over the resting pill.
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  warping
                      ? const ColoredBox(color: Color(0x01000000))
                      : const SizedBox.shrink(),
                  widget.child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LensClipper extends CustomClipper<Path> {
  _LensClipper(this.lensGeometry, {required this.clipToLens});

  final LensGeometryResolver lensGeometry;
  final bool clipToLens;

  @override
  Path getClip(Size size) {
    if (!clipToLens) return Path()..addRect(Offset.zero & size);
    final lens = lensGeometry(size);
    return (Path()..addRRect(lens.rrect)).transform(lens.transform.storage);
  }

  // The resolver is rebuilt on every frame the lens moves, so reclip on
  // every new clipper.
  @override
  bool shouldReclip(_LensClipper oldClipper) => true;
}
