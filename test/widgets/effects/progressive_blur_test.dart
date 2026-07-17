import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Tests for [ProgressiveBlur].
///
/// The real graduated blur is a GPU fragment shader, which the headless test
/// backend does not compile — so `isShaderFilterSupported` is false here and the
/// widget takes its documented **uniform-blur fallback** (`ClipRect` >
/// `BackdropFilter`). These tests therefore assert the backend-independent
/// contract: passthrough at `maxSigma <= 0`, a backdrop filter when blurring,
/// no glass ancestor required, and an idempotent, non-throwing [preload].
void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.blue)),
              Positioned(top: 0, left: 0, right: 0, height: 96, child: child),
            ],
          ),
        ),
      );

  testWidgets('renders a backdrop filter when blurring', (tester) async {
    await tester.pumpWidget(host(const ProgressiveBlur(maxSigma: 20)));
    await tester.pump();

    expect(find.byType(ProgressiveBlur), findsOneWidget);
    // Either the shader filter or the uniform fallback — both draw through a
    // single BackdropFilter inside a ClipRect.
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRect), findsWidgets);
  });

  testWidgets('maxSigma <= 0 is a passthrough (no backdrop filter)',
      (tester) async {
    await tester.pumpWidget(host(const ProgressiveBlur(maxSigma: 0)));
    await tester.pump();

    expect(find.byType(ProgressiveBlur), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('dropping maxSigma to 0 removes the backdrop filter',
      (tester) async {
    await tester.pumpWidget(host(const ProgressiveBlur(maxSigma: 20)));
    await tester.pump();
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.pumpWidget(host(const ProgressiveBlur(maxSigma: 0)));
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('needs no LiquidGlassLayer / glass ancestor', (tester) async {
    // Deliberately mounted bare — no wrap(), no LiquidGlassLayer.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          height: 96,
          child: ProgressiveBlur(maxSigma: 16),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProgressiveBlur), findsOneWidget);
  });

  testWidgets('honours the direction without throwing', (tester) async {
    for (final dir in ProgressiveBlurDirection.values) {
      await tester
          .pumpWidget(host(ProgressiveBlur(maxSigma: 18, direction: dir)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    // All four edges are exposed.
    expect(ProgressiveBlurDirection.values, hasLength(4));
  });

  test('preload is idempotent and never throws', () async {
    // Safe to await repeatedly; in tests the shader isn't bundled, so this
    // exercises the graceful-degradation branch and must still complete.
    await ProgressiveBlur.preload();
    await ProgressiveBlur.preload();
  });
}
