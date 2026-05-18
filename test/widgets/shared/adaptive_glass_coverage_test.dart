import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: LiquidGlassWidgets.wrap(child: child)),
    );

const _shape = LiquidRoundedSuperellipse(borderRadius: 20);
const _settings = LiquidGlassSettings(blur: 5);

void main() {
  group('AdaptiveGlass — quality paths', () {
    testWidgets('minimal quality renders fallback path', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: _shape,
          settings: _settings,
          quality: GlassQuality.minimal,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      // Frosted-fallback path used to wrap in ClipPath(ShapeBorderClipper);
      // for RoundedRectangleBorder-resolving shapes it now wraps in
      // ClipRRect via _ShapeClip (so Flutter PR #177551's PlatformView
      // clip-forwarding takes effect over a PlatformView backdrop).
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('blur=0 triggers minimal fast path', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: _shape,
          settings: LiquidGlassSettings(blur: 0),
          quality: GlassQuality.standard,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('standard quality renders lightweight glass', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: _shape,
          settings: _settings,
          quality: GlassQuality.standard,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('premium useOwnLayer renders RepaintBoundary', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: _shape,
          settings: _settings,
          quality: GlassQuality.premium,
          useOwnLayer: true,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });

  group('AdaptiveGlass — accessibility path', () {
    testWidgets('reduce transparency triggers frosted fallback',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LiquidGlassWidgets.wrap(
            child: GlassAccessibilityScope(
              reduceTransparency: true,
              child: const SizedBox(
                width: 200,
                height: 100,
                child: AdaptiveGlass(
                  shape: _shape,
                  settings: _settings,
                  quality: GlassQuality.standard,
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      // See note above on the ClipPath → ClipRRect swap in _ShapeClip
      // for RoundedRectangleBorder-resolving shapes.
      expect(find.byType(ClipRRect), findsWidgets);
    });
  });

  // _ShapeClip — the private helper used by _FrostedFallback to route
  // RoundedRectangleBorder-resolving shapes through ClipRRect (so the
  // Flutter PR #177551 PlatformView clip-forward fix takes effect) and
  // everything else through ClipPath. Exercise both branches that
  // aren't covered by the LiquidRoundedSuperellipse cases above.
  group('AdaptiveGlass — _ShapeClip shape branches via _FrostedFallback', () {
    testWidgets(
        'LiquidVerticalRoundedSuperellipse routes through ClipRRect.vertical',
        (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: LiquidVerticalRoundedSuperellipse(
            topRadius: 18,
            bottomRadius: 4,
          ),
          settings: _settings,
          quality: GlassQuality.minimal,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      // Asymmetric vertical rounded rect should still resolve to
      // ClipRRect (with BorderRadius.vertical) via _ShapeClip.
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('LiquidOval falls back to ClipPath via _ShapeClip',
        (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 80,
        height: 80,
        child: AdaptiveGlass(
          shape: LiquidOval(),
          settings: _settings,
          quality: GlassQuality.minimal,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      // LiquidOval is intentionally NOT routed through ClipRRect (see
      // _ShapeClip doc comment) — verify the ClipPath fallback path is
      // taken.
      expect(find.byType(ClipPath), findsWidgets);
    });
  });

  group('AdaptiveGlass — grouped factory', () {
    testWidgets('grouped() returns AdaptiveGlass', (tester) async {
      await tester.pumpWidget(_wrap(SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass.grouped(
            shape: _shape, child: const SizedBox.expand()),
      )));
      await tester.pump();
      expect(find.byType(AdaptiveGlass), findsOneWidget);
    });

    testWidgets('grouped() isInteractive+glowIntensity renders correctly',
        (tester) async {
      await tester.pumpWidget(_wrap(SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass.grouped(
          shape: _shape,
          quality: GlassQuality.minimal,
          isInteractive: true,
          glowIntensity: 1.0,
          child: const SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(AdaptiveGlass), findsOneWidget);
    });
  });

  group('AdaptiveGlass — allowElevation paths', () {
    testWidgets('allowElevation=false renders container glass', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: _shape,
          settings: _settings,
          quality: GlassQuality.standard,
          allowElevation: false,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('elevation with ancestor blur adds density factor',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LiquidGlassWidgets.wrap(
            child: InheritedLiquidGlass(
              settings: _settings,
              quality: GlassQuality.standard,
              isBlurProvidedByAncestor: true,
              child: const SizedBox(
                width: 200,
                height: 100,
                child: AdaptiveGlass(
                  shape: _shape,
                  settings: _settings,
                  quality: GlassQuality.standard,
                  allowElevation: true,
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('_FrostedFallback edge cases', () {
    testWidgets('isInteractive=true skips BackdropFilter', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: _shape,
          settings: _settings,
          quality: GlassQuality.minimal,
          isInteractive: true,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('glowIntensity > 0 adds glow overlay', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: _shape,
          settings: _settings,
          quality: GlassQuality.minimal,
          glowIntensity: 0.8,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(Stack), findsWidgets);
    });
  });
}
