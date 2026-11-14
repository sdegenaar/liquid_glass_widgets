// On-device verification that a progressive blur frosts only its own bounds.
//
// The blur is a backdrop filter, and a backdrop filter samples everything
// painted beneath it up to the nearest ancestor clip — so left unclipped it
// frosts far beyond the band it is meant to be. A route sliding away under a
// Cupertino pop is translated, not clipped, which is how a scroll-edge blur on
// the outgoing route ended up frosting the route being revealed (#278).
// Headless `flutter test` reports no shader filter support and takes the
// clipped uniform-blur fallback, so only a real backend can show the leak.
//
//   cd example && flutter test integration_test/progressive_blur_clip_test.dart -d <device>

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Share of mid-grey pixels down a column of 2 pt black-on-white stripes:
/// none where they are sharp, all of them where a blur has flattened them.
/// The thresholds sit far apart because the outcome is binary — the sigma at
/// every sampled row is several stripe periods wide.
const double _kSharp = 0.2;
const double _kFrosted = 0.8;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason:
          'This device reports no shader filter support, so the blur '
          'would render through the clipped fallback. Run it on Impeller.',
    );
  });

  testWidgets('a progressive blur frosts nothing outside its own rectangle', (
    tester,
  ) async {
    final root = GlobalKey();
    const band = Rect.fromLTWH(60, 200, 200, 120);
    runApp(
      RepaintBoundary(
        key: root,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              const Positioned.fill(child: _Stripes()),
              Positioned.fromRect(
                rect: band,
                child: const ProgressiveBlur(maxSigma: 18),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final frame = await _Frame.capture(tester, root);
    // Inside: frosted at the strong edge, easing to sharp at the far edge.
    expect(
      frame.midtones(
        x: band.center.dx,
        top: band.top + 4,
        bottom: band.top + 24,
      ),
      greaterThan(_kFrosted),
    );
    expect(
      frame.midtones(
        x: band.center.dx,
        top: band.bottom - 6,
        bottom: band.bottom,
      ),
      lessThan(_kSharp),
    );
    // Outside: the rows above the band, and the columns either side of it.
    expect(
      frame.midtones(
        x: band.center.dx,
        top: band.top - 40,
        bottom: band.top - 20,
      ),
      lessThan(_kSharp),
      reason: 'the rows above the band must stay sharp',
    );
    expect(
      frame.midtones(
        x: band.left - 30,
        top: band.top + 4,
        bottom: band.top + 24,
      ),
      lessThan(_kSharp),
      reason: 'the columns left of the band must stay sharp',
    );
    expect(
      frame.midtones(
        x: band.right + 30,
        top: band.top + 4,
        bottom: band.top + 24,
      ),
      lessThan(_kSharp),
      reason: 'the columns right of the band must stay sharp',
    );
  });

  testWidgets('a scroll-edge blur stays on its own route mid back-swipe', (
    tester,
  ) async {
    final root = GlobalKey();
    runApp(
      RepaintBoundary(
        key: root,
        child: LiquidGlassWidgets.wrap(
          child: const CupertinoApp(
            debugShowCheckedModeBanner: false,
            home: _Previous(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(CupertinoPageRoute<void>(builder: (_) => const _Frosted()));
    await tester.pumpAndSettle();

    // Sample the strong quarter of each band, where the eased sigma is still
    // several stripe periods wide, and mid-screen as the sharp reference.
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final effect = tester.widget<GlassScrollEdgeEffect>(
      find.byType(GlassScrollEdgeEffect),
    );
    final top = _Rows(effect.topFadeHeight * 0.05, effect.topFadeHeight * 0.25);
    final bottom = _Rows(
      size.height - effect.bottomFadeHeight * 0.25,
      size.height - effect.bottomFadeHeight * 0.05,
    );
    final middle = _Rows(size.height / 2 - 7, size.height / 2 + 7);

    // At rest both bands frost the pushed route and ease to sharp between.
    var frame = await _Frame.capture(tester, root);
    expect(
      frame.midtones(x: size.width / 2, top: top.top, bottom: top.bottom),
      greaterThan(_kFrosted),
    );
    expect(
      frame.midtones(x: size.width / 2, top: bottom.top, bottom: bottom.bottom),
      greaterThan(_kFrosted),
    );
    expect(
      frame.midtones(x: size.width / 2, top: middle.top, bottom: middle.bottom),
      lessThan(_kSharp),
    );

    // Hold an interactive pop part-way: the previous route fills the gap on
    // the left, the frosted one is still fully live on the right.
    final gesture = await tester.startGesture(Offset(8, size.height / 2));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(Offset(size.width * 0.5, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final split = tester.getTopLeft(find.byType(_Frosted)).dx;
    expect(split, greaterThan(size.width * 0.4), reason: 'the swipe took');

    frame = await _Frame.capture(tester, root);
    final revealed = split / 2;
    final outgoing = (split + size.width) / 2;
    expect(
      frame.midtones(x: revealed, top: top.top, bottom: top.bottom),
      lessThan(_kSharp),
      reason: 'the revealed route must stay sharp under the top band',
    );
    expect(
      frame.midtones(x: revealed, top: bottom.top, bottom: bottom.bottom),
      lessThan(_kSharp),
      reason: 'the revealed route must stay sharp under the bottom band',
    );
    expect(
      frame.midtones(x: outgoing, top: top.top, bottom: top.bottom),
      greaterThan(_kFrosted),
      reason: 'the outgoing route keeps its own frost while it slides',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}

/// A pair of logical rows to sample between.
class _Rows {
  const _Rows(this.top, this.bottom);
  final double top;
  final double bottom;
}

/// One captured frame, read back so a column of pixels can be inspected.
class _Frame {
  _Frame(this._bytes, this._width, this._dpr);

  final ByteData _bytes;
  final int _width;
  final double _dpr;

  static Future<_Frame> capture(WidgetTester tester, GlobalKey root) async {
    final boundary =
        root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final dpr = tester.view.devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: dpr);
    final bytes = (await image.toByteData())!;
    final frame = _Frame(bytes, image.width, dpr);
    image.dispose();
    return frame;
  }

  /// The share of pixels down column [x] between logical rows [top] and
  /// [bottom] whose red channel is neither near black nor near white.
  double midtones({
    required double x,
    required double top,
    required double bottom,
  }) {
    var mid = 0;
    var total = 0;
    final px = (x * _dpr).round();
    for (var py = (top * _dpr).round(); py < (bottom * _dpr).round(); py++) {
      final r = _bytes.getUint8((py * _width + px) * 4);
      if (r > 64 && r < 192) mid++;
      total++;
    }
    final share = mid / total;
    return share;
  }
}

/// The route underneath: nothing but stripes, so any frost on it is a leak.
class _Previous extends StatelessWidget {
  const _Previous();

  @override
  Widget build(BuildContext context) => const _Stripes();
}

/// The pushed route, configured as in the report, with a bottom band as well.
class _Frosted extends StatelessWidget {
  const _Frosted();

  @override
  Widget build(BuildContext context) => const GlassScaffold(
    edgeStyle: GlassScrollEdgeStyle.blur,
    bottomEdgeFade: true,
    appBar: GlassAppBar(title: Text('Screen B')),
    body: _Stripes(),
  );
}

/// 2 pt black stripes on white, every 4 pt — pixel-aligned at any integer
/// device pixel ratio, and flattened to grey by a sigma of a couple of points.
class _Stripes extends StatelessWidget {
  const _Stripes();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _StripePainter(), child: SizedBox.expand());
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final ink = Paint()..color = const Color(0xFF000000);
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), ink);
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}
