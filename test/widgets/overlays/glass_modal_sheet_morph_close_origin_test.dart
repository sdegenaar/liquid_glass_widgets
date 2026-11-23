import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/overlays/glass_modal_sheet.dart';

void main() {
  const screenSize = Size(400, 800);
  const bottomInset = 34.0;
  const triggerKey = Key('trigger');
  const closeButtonKey = Key('close-button');

  setUp(() => GlassModalSheet.debugMorphSupportsBlending = true);
  tearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);

  /// Reads Blob B's frame, corner radii, and solid fill opacity from the active
  /// morph droplet layer on the current frame.
  ({
    Rect rect,
    double topRadius,
    double bottomRadius,
    double fillAlpha,
  }) inspectDropletBlobB(WidgetTester tester) {
    final dropletLayer = find.byType(AdaptiveLiquidGlassLayer);
    expect(dropletLayer, findsOneWidget);

    final blobBGlassFinder = find.descendant(
      of: dropletLayer,
      matching: find.byWidgetPredicate(
        (w) =>
            w is AdaptiveGlass && w.shape is LiquidVerticalRoundedSuperellipse,
      ),
    );
    expect(blobBGlassFinder, findsOneWidget);

    final blobBGlass = tester.widget<AdaptiveGlass>(blobBGlassFinder);
    final shape = blobBGlass.shape as LiquidVerticalRoundedSuperellipse;

    final positioned = tester.widget<Positioned>(
      find
          .ancestor(
            of: blobBGlassFinder,
            matching: find.byType(Positioned),
          )
          .first,
    );
    final sizedBox = tester.widget<SizedBox>(
      find
          .descendant(
            of: blobBGlassFinder,
            matching: find.byType(SizedBox),
          )
          .first,
    );

    final fillBoxes = find.descendant(
      of: blobBGlassFinder,
      matching: find.byType(ColoredBox),
    );
    final double fillAlpha = fillBoxes.evaluate().isEmpty
        ? 0.0
        : tester.widget<ColoredBox>(fillBoxes.first).color.a;

    return (
      rect: Rect.fromLTWH(
        positioned.left!,
        positioned.top!,
        sizedBox.width!,
        sizedBox.height!,
      ),
      topRadius: shape.topRadius,
      bottomRadius: shape.bottomRadius,
      fillAlpha: fillAlpha,
    );
  }

  double triggerOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(triggerKey),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  Future<void> pumpSheetApp(
    WidgetTester tester, {
    required Future<void> Function(
      BuildContext context,
      GlassMorphAnchor anchor,
    ) onOpen,
  }) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: bottomInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassMorphTrigger(
                builder: (context, anchor) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onOpen(context, anchor),
                  child: const SizedBox(
                    key: triggerKey,
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GlassMorphTrigger));
    await tester.pumpAndSettle();
  }

  group('GlassModalSheet close-morph origin after detent change (#507)', () {
    testWidgets(
      'half -> full drag dismissed via barrier tap starts close morph from full geometry',
      (tester) async {
        const horizontalMargin = 12.0;
        const bottomMargin = 10.0;
        const topRadius = 38.0;
        const bottomRadius = 34.0;
        const fullTopRadius = 24.0;
        const fullBottomRadius = 18.0;

        await pumpSheetApp(
          tester,
          onOpen: (context, anchor) => GlassModalSheet.show<void>(
            context: context,
            morphFrom: anchor,
            halfSize: 0.45,
            horizontalMargin: horizontalMargin,
            bottomMargin: bottomMargin,
            topBorderRadius: topRadius,
            bottomBorderRadius: bottomRadius,
            fullTopBorderRadius: fullTopRadius,
            fullBottomBorderRadius: fullBottomRadius,
            builder: (_) => const SizedBox.expand(
              child: Center(child: Text('Sheet Body')),
            ),
          ),
        );

        // Drag from half up to full and let the snap settle.
        await tester.dragFrom(const Offset(200, 500), const Offset(0, -350));
        await tester.pumpAndSettle();

        // Tap the modal barrier above the default 90pt full-detent top inset.
        await tester.tapAt(const Offset(200, 30));
        await tester.pump();

        final blob = inspectDropletBlobB(tester);
        // Full detent is edge-to-edge (left == 0, width == 400), top == 90,
        // and sunk below the bottom by bottomInset (34) + bottomRadius (34).
        expect(blob.rect.left, closeTo(0.0, 0.5));
        expect(blob.rect.top, closeTo(90.0, 0.5));
        expect(blob.rect.width, closeTo(screenSize.width, 0.5));
        expect(
          blob.rect.bottom,
          closeTo(screenSize.height + bottomInset + bottomRadius, 0.5),
        );
        expect(blob.topRadius, closeTo(fullTopRadius, 0.5));
        expect(blob.bottomRadius, closeTo(fullBottomRadius, 0.5));
        // Full detent is opaque, unlike the translucent glass half detent.
        expect(blob.fillAlpha, closeTo(1.0, 0.01));

        await tester.pumpAndSettle();
        expect(find.byType(GlassSheetMorphPresenter), findsNothing);
        expect(triggerOpacity(tester), 1.0);
      },
    );

    testWidgets(
      'half -> full drag dismissed via close button (Navigator.pop) starts close morph from full geometry',
      (tester) async {
        const bottomRadius = 32.0;
        const fullTopRadius = 22.0;
        const fullBottomRadius = 16.0;

        await pumpSheetApp(
          tester,
          onOpen: (context, anchor) => GlassModalSheet.show<void>(
            context: context,
            morphFrom: anchor,
            halfSize: 0.45,
            horizontalMargin: 14.0,
            bottomMargin: 12.0,
            topBorderRadius: 40.0,
            bottomBorderRadius: bottomRadius,
            fullTopBorderRadius: fullTopRadius,
            fullBottomBorderRadius: fullBottomRadius,
            builder: (sheetCtx) => Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 56, right: 16),
                child: GestureDetector(
                  key: closeButtonKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(sheetCtx).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Text('Close'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.dragFrom(const Offset(200, 520), const Offset(0, -350));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(closeButtonKey));
        await tester.pump();

        final blob = inspectDropletBlobB(tester);
        expect(blob.rect.left, closeTo(0.0, 0.5));
        expect(blob.rect.top, closeTo(90.0, 0.5));
        expect(blob.rect.width, closeTo(screenSize.width, 0.5));
        expect(
          blob.rect.bottom,
          closeTo(screenSize.height + bottomInset + bottomRadius, 0.5),
        );
        expect(blob.topRadius, closeTo(fullTopRadius, 0.5));
        expect(blob.bottomRadius, closeTo(fullBottomRadius, 0.5));
        expect(blob.fillAlpha, closeTo(1.0, 0.01));

        await tester.pumpAndSettle();
        expect(find.byType(GlassSheetMorphPresenter), findsNothing);
        expect(triggerOpacity(tester), 1.0);
      },
    );

    testWidgets(
      'half -> peek drag dismissed via barrier tap starts close morph from peek geometry and margins',
      (tester) async {
        const peekSize = 120.0;
        const peekHorizontalMargin = 24.0;
        const peekBottomMargin = 18.0;
        const peekTopRadius = 28.0;
        const peekBottomRadius = 22.0;

        await pumpSheetApp(
          tester,
          onOpen: (context, anchor) => GlassModalSheet.show<void>(
            context: context,
            morphFrom: anchor,
            detents: const {
              GlassSheetDetent.small,
              GlassSheetDetent.medium,
              GlassSheetDetent.large,
            },
            halfSize: 0.5,
            peekSize: peekSize,
            horizontalMargin: 8.0,
            bottomMargin: 8.0,
            topBorderRadius: 38.0,
            bottomBorderRadius: 34.0,
            peekHorizontalMargin: peekHorizontalMargin,
            peekBottomMargin: peekBottomMargin,
            peekTopBorderRadius: peekTopRadius,
            peekBottomRadius: peekBottomRadius,
            builder: (_) => const SizedBox.expand(
              child: Center(child: Text('Peekable Sheet')),
            ),
          ),
        );

        // Drag down from half (top=400) to peek (top=680) and settle.
        await tester.dragFrom(const Offset(200, 440), const Offset(0, 260));
        await tester.pumpAndSettle();

        // Tap the barrier above the peek sheet to dismiss at rest.
        await tester.tapAt(const Offset(200, 200));
        await tester.pump();

        final blob = inspectDropletBlobB(tester);
        expect(blob.rect.left, closeTo(peekHorizontalMargin, 0.5));
        expect(blob.rect.top, closeTo(screenSize.height - peekSize, 0.5));
        expect(
          blob.rect.width,
          closeTo(screenSize.width - 2 * peekHorizontalMargin, 0.5),
        );
        expect(
          blob.rect.bottom,
          closeTo(screenSize.height - peekBottomMargin, 0.5),
        );
        expect(blob.topRadius, closeTo(peekTopRadius, 0.5));
        expect(blob.bottomRadius, closeTo(peekBottomRadius, 0.5));

        await tester.pumpAndSettle();
        expect(find.byType(GlassSheetMorphPresenter), findsNothing);
        expect(triggerOpacity(tester), 1.0);
      },
    );

    testWidgets(
      'half -> peek drag with peekWidth dismissed via Navigator.pop starts close morph from centred peek floor',
      (tester) async {
        const peekSize = 110.0;
        const peekWidth = 260.0;
        const peekBottomMargin = 20.0;
        const peekTopRadius = 26.0;
        const peekBottomRadius = 26.0;

        late BuildContext sheetContext;
        await pumpSheetApp(
          tester,
          onOpen: (context, anchor) => GlassModalSheet.show<void>(
            context: context,
            morphFrom: anchor,
            detents: const {
              GlassSheetDetent.small,
              GlassSheetDetent.medium,
              GlassSheetDetent.large,
            },
            halfSize: 0.5,
            peekSize: peekSize,
            peekWidth: peekWidth,
            peekBottomMargin: peekBottomMargin,
            peekTopBorderRadius: peekTopRadius,
            peekBottomRadius: peekBottomRadius,
            builder: (ctx) {
              sheetContext = ctx;
              return const SizedBox.expand(
                child: Center(child: Text('Fixed-width Peek')),
              );
            },
          ),
        );

        await tester.dragFrom(const Offset(200, 440), const Offset(0, 260));
        await tester.pumpAndSettle();

        Navigator.of(sheetContext).pop();
        await tester.pump();

        final blob = inspectDropletBlobB(tester);
        expect(
            blob.rect.left, closeTo((screenSize.width - peekWidth) / 2, 0.5));
        expect(blob.rect.top, closeTo(screenSize.height - peekSize, 0.5));
        expect(blob.rect.width, closeTo(peekWidth, 0.5));
        expect(
          blob.rect.bottom,
          closeTo(screenSize.height - peekBottomMargin, 0.5),
        );
        expect(blob.topRadius, closeTo(peekTopRadius, 0.5));
        expect(blob.bottomRadius, closeTo(peekBottomRadius, 0.5));

        await tester.pumpAndSettle();
        expect(find.byType(GlassSheetMorphPresenter), findsNothing);
        expect(triggerOpacity(tester), 1.0);
      },
    );
  });
}
