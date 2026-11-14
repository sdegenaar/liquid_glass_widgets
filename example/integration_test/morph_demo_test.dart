// On-device verification for GlassModalSheet's morph presentation.
//
// The morph needs the Impeller metaball blend, which a headless `flutter test`
// run does not have — so this drives the real demo on a simulator/device, where
// the capability probe actually passes, and proves the morph route is taken
// rather than the slide fallback.
//
//   cd example && flutter test integration_test/morph_demo_test.dart -d <device>

import 'dart:ui' as ui;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/widgets/overlays/glass_modal_sheet.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_glass.dart'
    show AdaptiveGlass;

import 'package:liquid_glass_widgets_example/demos/glass_modal_sheet_demo.dart'
    as demo;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GlassModalSheet morphs from its trigger on a real renderer', (
    tester,
  ) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason:
          'This device reports no shader filter support, so the morph '
          'would correctly fall back to the slide. Run it on Impeller.',
    );

    demo.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    final trigger = find.byIcon(CupertinoIcons.add);
    expect(trigger, findsOneWidget, reason: 'the morph demo trigger');

    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Mid-morph: the droplet is presenting, and the route did not wrap the
    // page in the slide it replaces. (Scoped to the sheet's own route — the
    // demo's home CupertinoPageRoute has a SlideTransition of its own.)
    expect(find.byType(GlassSheetMorphPresenter), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(GlassSheetMorphPresenter),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(find.text('Morph from trigger'), findsWidgets);

    // Let the landed sheet sit for the recording.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Barrier tap — the dismissal that morphs back into the trigger.
    await tester.tapAt(const Offset(200, 80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(GlassSheetMorphPresenter), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(GlassSheetMorphPresenter), findsNothing);

    await Future<void>.delayed(const Duration(milliseconds: 500));
  });

  testWidgets('a swipe shrinks the sheet and morphs it back from the release', (
    tester,
  ) async {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason:
          'This device reports no shader filter support, so the morph '
          'would correctly fall back to the slide. Run it on Impeller.',
    );

    demo.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();

    // A widget *inside* the sheet. The shrink is a transform over the whole
    // subtree, so this text's painted width is a direct read of the sheet's
    // scale — the same thing the iOS capture was measured on.
    final content = find.text('Morph from trigger').last;
    final restingWidth = tester.getRect(content).width;
    final restingTop = tester.getRect(content).top;

    final view = tester.view;
    final screenHeight = view.physicalSize.height / view.devicePixelRatio;

    // The whole dismiss curve is normalised by the card's own height — read it
    // off the sheet's glass surface, whose frame is the card. The outermost
    // AdaptiveGlass under the presenter is that surface (glass widgets inside
    // the sheet's content come later in traversal order).
    final glassCard = find
        .descendant(
          of: find.byType(GlassSheetMorphPresenter),
          matching: find.byType(AdaptiveGlass),
        )
        .first;
    final cardFraction = tester.getRect(glassCard).height / screenHeight;

    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Drag handle')),
    );

    // Walked down in steps rather than one jump: it exercises the curve at
    // every intermediate position instead of a single point, and it makes a
    // screen recording of the run show the real gesture.
    const partway = 120.0;
    const steps = 12;
    var travelled = 0.0;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(const Offset(0, partway / steps));
      await tester.pump(const Duration(milliseconds: 16));
      travelled += partway / steps;

      expect(
        tester.getRect(content).width / restingWidth,
        closeTo(
          SheetMorphGeometry.dismissScale(
            travelled / screenHeight,
            cardFraction: cardFraction,
          ),
          0.02,
        ),
        reason:
            'the sheet shrinks on the measured iOS curve for the whole '
            'drag, not just at its end',
      );
      expect(
        tester.getRect(content).top,
        greaterThan(restingTop),
        reason: 'and follows the finger down while it does',
      );
    }

    // Sideways, while it is falling: iOS lets the card be pushed around the
    // screen, and the shrink ignores the horizontal axis entirely.
    final beforeSweep = tester.getRect(content);
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(const Offset(60 / steps, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final movedBy = tester.getRect(content).center.dx - beforeSweep.center.dx;
    expect(movedBy, greaterThan(0.0), reason: 'it follows the finger sideways');
    expect(
      movedBy,
      lessThan(60.0),
      reason:
          'but rubber-banded — the axis has friction, and it stiffens as '
          'the card shrinks',
    );

    // Released short of the threshold: springs back to the detent, at full
    // size and centred, without dismissing. The scale is derived from the
    // sheet position, so only the sideways offset needs its own spring.
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(GlassSheetMorphPresenter), findsOneWidget);
    expect(tester.getRect(content).width, closeTo(restingWidth, 0.5));
    expect(tester.getRect(content).top, closeTo(restingTop, 0.5));

    // Now past the threshold, and let go mid-swipe. Long enough to be well
    // past the damping knee (0.48 of the card's height).
    final dismiss = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Drag handle')),
    );
    const hardDrag = 400.0;
    for (var i = 0; i < steps * 2; i++) {
      await dismiss.moveBy(const Offset(0, hardDrag / (steps * 2)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    final releasedWidth = tester.getRect(content).width;
    expect(releasedWidth, lessThan(restingWidth * 0.65));

    // Past the knee both the shrink and the fall ease off. Measured through
    // the scale, which is the axis a widget rect reports cleanly — the card's
    // top edge moves under the shrink as well as the fall, so it cannot
    // isolate either. The card should sit meaningfully above where an
    // undamped gain would leave it, and land on the damped curve.
    final undamped =
        1.0 -
        SheetMorphGeometry.dismissScaleGain *
            (hardDrag / (cardFraction * screenHeight));
    expect(
      releasedWidth / restingWidth,
      greaterThan(undamped + 0.05),
      reason: 'the easing is doing real work by this point in the drag',
    );
    expect(
      releasedWidth / restingWidth,
      closeTo(
        SheetMorphGeometry.dismissScale(
          hardDrag / screenHeight,
          cardFraction: cardFraction,
        ),
        0.02,
      ),
      reason: 'and it lands on the damped curve, not the linear one',
    );

    await dismiss.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // The droplet has taken over from the shrunken sheet — the swipe morphs
    // back into the trigger rather than sliding away.
    expect(
      tester
          .widget<Visibility>(
            find
                .descendant(
                  of: find.byType(GlassSheetMorphPresenter),
                  matching: find.byType(Visibility),
                )
                .first,
          )
          .visible,
      isFalse,
      reason:
          'a swipe-dismissal hands off to the morph, like every other '
          'dismissal does',
    );

    await tester.pumpAndSettle();
    expect(find.byType(GlassSheetMorphPresenter), findsNothing);

    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
}
