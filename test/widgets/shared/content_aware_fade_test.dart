// ignore_for_file: require_trailing_commas
// Tests for the content-luminance scrim lever:
//   - GlassContentAwareScope.computeMeanLuminance (perceptual mean,
//     transparency substitution, degenerate inputs)
//   - luminance delivery through register(onLuminanceChanged:) with the
//     delta threshold, and brightness-callback-less registrations
//   - GlassScrollEdgeEffect.contentAwareFade: per-band darkness over dark /
//     light / medium content, inertness without a scope, sub lifecycle
//   - GlassScaffold: contentAwareEdgeFade forwarding and the capture
//     wrap-order (fade overlays must stay OUTSIDE the sampled region)

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Uint8List _rowOf(int width, Color color, {int alpha = 255}) {
  final bytes = Uint8List(width * 4);
  final r = ((color.r * 255).round()) & 0xFF;
  final g = ((color.g * 255).round()) & 0xFF;
  final b = ((color.b * 255).round()) & 0xFF;
  for (var x = 0; x < width; x++) {
    bytes[x * 4] = r;
    bytes[x * 4 + 1] = g;
    bytes[x * 4 + 2] = b;
    bytes[x * 4 + 3] = alpha;
  }
  return bytes;
}

double _meanLuma(
  Uint8List rgba,
  int width, {
  Color background = const Color(0xFFFFFFFF),
  List<Rect>? cells,
}) {
  return GlassContentAwareScope.computeMeanLuminance(
    rgba: rgba,
    width: width,
    height: 1,
    cellRects: cells ??
        <Rect>[
          for (var i = 0; i < width; i++) Rect.fromLTWH(i.toDouble(), 0, 1, 1)
        ],
    background: background,
  );
}

/// Runs one deterministic sample to completion (captures only complete
/// inside runAsync; an in-flight registration sample holds the
/// single-flight latch, so let it finish first).
Future<void> _settleSample(
  WidgetTester tester,
  GlassContentAwareScopeState scope,
) {
  return tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await scope.sampleNow();
  });
}

void main() {
  group('computeMeanLuminance', () {
    test('black is 0, white is 1, mid-gray is mid', () {
      expect(
          _meanLuma(_rowOf(4, const Color(0xFF000000)), 4), closeTo(0, 1e-6));
      expect(
          _meanLuma(_rowOf(4, const Color(0xFFFFFFFF)), 4), closeTo(1, 1e-6));
      expect(
        _meanLuma(_rowOf(4, const Color(0xFF808080)), 4),
        closeTo(0.5, 0.01),
      );
    });

    test('mixed content averages across cells', () {
      final rgba = Uint8List.fromList([
        ..._rowOf(2, const Color(0xFF000000)),
        ..._rowOf(2, const Color(0xFFFFFFFF)),
      ]);
      expect(_meanLuma(rgba, 4), closeTo(0.5, 0.01));
    });

    test('transparent pixels read as the background', () {
      final rgba = _rowOf(4, const Color(0xFFFFFFFF), alpha: 0);
      expect(
        _meanLuma(rgba, 4, background: const Color(0xFF000000)),
        closeTo(0, 1e-6),
      );
      expect(
        _meanLuma(rgba, 4, background: const Color(0xFFFFFFFF)),
        closeTo(1, 1e-6),
      );
    });

    test('degenerate inputs return 1.0 (light)', () {
      expect(
        GlassContentAwareScope.computeMeanLuminance(
          rgba: Uint8List(0),
          width: 0,
          height: 0,
          cellRects: const [Rect.fromLTWH(0, 0, 1, 1)],
          background: const Color(0xFFFFFFFF),
        ),
        1.0,
      );
      expect(_meanLuma(_rowOf(4, const Color(0xFF000000)), 4, cells: const []),
          1.0);
    });
  });

  group('scope luminance delivery', () {
    Widget host({required Color content}) => MaterialApp(
          home: GlassContentAwareScope(
            child: GlassContentAwareContent(
              child: ColoredBox(color: content),
            ),
          ),
        );

    testWidgets('delivers mean luminance without a brightness callback',
        (tester) async {
      await tester.pumpWidget(host(content: const Color(0xFF000000)));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      final box = tester.renderObject(find.byType(GlassContentAwareContent))
          as RenderBox;
      final received = <double>[];
      final sub = scope.register(
        controlBox: () => box,
        onLuminanceChanged: received.add,
      );
      expect(sub.meanLuminance, isNull);
      await _settleSample(tester, scope);
      expect(received, hasLength(1));
      expect(received.single, lessThan(0.05));
      expect(sub.meanLuminance, received.single);

      // Re-sampling identical content stays inside the delta threshold —
      // no churn delivery.
      await _settleSample(tester, scope);
      expect(received, hasLength(1));
      sub.cancel();
    });

    testWidgets('verdict still flips when both callbacks are registered',
        (tester) async {
      await tester.pumpWidget(host(content: const Color(0xFF000000)));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      final box = tester.renderObject(find.byType(GlassContentAwareContent))
          as RenderBox;
      Brightness? verdict;
      double? luminance;
      final sub = scope.register(
        controlBox: () => box,
        onBrightnessChanged: (b) => verdict = b,
        onLuminanceChanged: (l) => luminance = l,
      );
      await _settleSample(tester, scope);
      expect(verdict, Brightness.dark);
      expect(luminance, lessThan(0.05));
      sub.cancel();
    });
  });

  group('GlassScrollEdgeEffect.contentAwareFade', () {
    Widget host({
      required Color content,
      bool contentAware = true,
      bool fadeTop = true,
      bool fadeBottom = true,
      bool withScope = true,
    }) {
      final effect = GlassScrollEdgeEffect(
        contentAwareFade: contentAware,
        fadeTop: fadeTop,
        fadeBottom: fadeBottom,
        child: GlassContentAwareContent(
          child: ColoredBox(color: content, child: const SizedBox.expand()),
        ),
      );
      return MaterialApp(
        home: withScope ? GlassContentAwareScope(child: effect) : effect,
      );
    }

    testWidgets('bands darken over dark content and animate there',
        (tester) async {
      await tester.pumpWidget(host(content: const Color(0xFF000000)));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      final effectState =
          tester.state(find.byType(GlassScrollEdgeEffect)) as dynamic;
      expect(effectState.bottomDarkness, 0.0);

      await _settleSample(tester, scope);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-animation: strictly between the endpoints.
      final mid = effectState.bottomDarkness as double;
      expect(mid, greaterThan(0.0));
      expect(mid, lessThan(1.0));
      await tester.pump(const Duration(milliseconds: 250));
      expect(effectState.bottomDarkness, closeTo(1.0, 0.01));
      expect(effectState.topDarkness, closeTo(1.0, 0.01));
    });

    testWidgets('bands stay light over light content', (tester) async {
      await tester.pumpWidget(host(content: const Color(0xFFFFFFFF)));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      final effectState =
          tester.state(find.byType(GlassScrollEdgeEffect)) as dynamic;
      await _settleSample(tester, scope);
      await tester.pump(const Duration(milliseconds: 350));
      expect(effectState.bottomDarkness, 0.0);
    });

    testWidgets(
        'medium content pulls the scrim mostly dark — early '
        'darkening', (tester) async {
      // Mid-gray ≈ 0.5 perceptual luminance → darkness ≈
      // 1 - (0.5 - 0.45)/(0.72 - 0.45) ≈ 0.81: the scrim darkens over
      // content the brightness vote would still call "light".
      await tester.pumpWidget(host(content: const Color(0xFF808080)));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      final effectState =
          tester.state(find.byType(GlassScrollEdgeEffect)) as dynamic;
      await _settleSample(tester, scope);
      await tester.pump(); // first tick anchors the ticker's start time
      await tester.pump(const Duration(milliseconds: 350));
      expect(effectState.bottomDarkness, closeTo(0.81, 0.06));
    });

    testWidgets('inert without a scope', (tester) async {
      await tester
          .pumpWidget(host(content: const Color(0xFF000000), withScope: false));
      final effectState =
          tester.state(find.byType(GlassScrollEdgeEffect)) as dynamic;
      await tester.pump(const Duration(milliseconds: 350));
      expect(effectState.bottomDarkness, 0.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('inert when contentAwareFade is off', (tester) async {
      await tester.pumpWidget(
          host(content: const Color(0xFF000000), contentAware: false));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      final effectState =
          tester.state(find.byType(GlassScrollEdgeEffect)) as dynamic;
      await _settleSample(tester, scope);
      await tester.pump(const Duration(milliseconds: 350));
      expect(effectState.bottomDarkness, 0.0);
    });

    testWidgets('single-edge config registers a single band', (tester) async {
      await tester.pumpWidget(host(
        content: const Color(0xFF000000),
        fadeTop: false,
      ));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      final effectState =
          tester.state(find.byType(GlassScrollEdgeEffect)) as dynamic;
      await _settleSample(tester, scope);
      await tester.pump(); // first tick anchors the ticker's start time
      await tester.pump(const Duration(milliseconds: 350));
      expect(effectState.bottomDarkness, closeTo(1.0, 0.01));
      expect(effectState.topDarkness, 0.0);
    });

    testWidgets('toggling contentAwareFade off cancels the registrations',
        (tester) async {
      await tester.pumpWidget(host(content: const Color(0xFF000000)));
      await tester.pumpWidget(
          host(content: const Color(0xFF000000), contentAware: false));
      // And tearing the whole tree down disposes cleanly mid-flight.
      await tester.pumpWidget(Container());
      expect(tester.takeException(), isNull);
    });
  });

  group('texture-backed fade path', () {
    testWidgets('adaptive scrim layers over the captured-texture fade',
        (tester) async {
      // Inside GlassPage the fade paints a slice of the captured background
      // texture; the adaptive scrim must layer over that path too.
      await tester.pumpWidget(MaterialApp(
        home: GlassPage(
          background: const ColoredBox(color: Color(0xFF101010)),
          child: GlassContentAwareScope(
            child: GlassScrollEdgeEffect(
              contentAwareFade: true,
              child: GlassContentAwareContent(
                child: const ColoredBox(
                  color: Color(0xFF101010),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ));
      final scope = tester.state<GlassContentAwareScopeState>(
          find.byType(GlassContentAwareScope));
      // Let the page's background capture (toImage) complete, then sample.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await scope.sampleNow();
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      // Texture path rendered with the dark scrim layered on top.
      expect(find.byType(CustomPaint), findsWidgets);
      final effectState =
          tester.state(find.byType(GlassScrollEdgeEffect)) as dynamic;
      expect(effectState.bottomDarkness, greaterThan(0.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('GlassScaffold integration', () {
    testWidgets(
        'contentAwareEdgeFade forwards and the fade overlays stay outside '
        'the sampled region', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: GlassScaffold(
          contentAwareBrightness: true,
          contentAwareEdgeFade: true,
          bottomBar: const SizedBox(height: 60),
          body: ListView(children: [Container(height: 2000)]),
        ),
      ));
      await tester.pump();

      final effect = tester
          .widget<GlassScrollEdgeEffect>(find.byType(GlassScrollEdgeEffect));
      expect(effect.contentAwareFade, isTrue);

      // Wrap order: the sampled region must NOT contain the edge effect
      // (the scrim cannot be allowed to feed back into its own sampling
      // input), and the edge effect must contain the sampled region.
      expect(
        find.descendant(
          of: find.byType(GlassContentAwareContent),
          matching: find.byType(GlassScrollEdgeEffect),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassScrollEdgeEffect),
          matching: find.byType(GlassContentAwareContent),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
