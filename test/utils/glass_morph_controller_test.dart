import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/utils/liquid_morph_physics.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: mounts a minimal widget that owns a GlassMorphController.
// ─────────────────────────────────────────────────────────────────────────────

class _Harness extends StatefulWidget {
  const _Harness({
    required this.ref,
    this.speed = MorphSpeed.normal,
    this.style = MorphStyle.teardrop,
  });

  final void Function(GlassMorphController) ref;
  final MorphSpeed speed;
  final MorphStyle style;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> with TickerProviderStateMixin {
  late final GlassMorphController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = GlassMorphController(
      vsync: this,
      speed: widget.speed,
      style: widget.style,
    );
    widget.ref(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Mounts the harness and returns the controller.
Future<GlassMorphController> _mount(
  WidgetTester tester, {
  MorphSpeed speed = MorphSpeed.normal,
  MorphStyle style = MorphStyle.teardrop,
}) async {
  late GlassMorphController ctrl;
  await tester.pumpWidget(
    MaterialApp(
      home: _Harness(ref: (c) => ctrl = c, speed: speed, style: style),
    ),
  );
  return ctrl;
}

Future<void> _pumpFrame(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 16));

void main() {
  // ── Construction ──────────────────────────────────────────────────────────

  group('GlassMorphController — construction', () {
    testWidgets('creates without throwing', (tester) async {
      expect(() => _mount(tester), returnsNormally);
    });

    testWidgets('speed property is stored', (tester) async {
      final ctrl = await _mount(tester, speed: MorphSpeed.fast);
      expect(ctrl.speed, equals(MorphSpeed.fast));
    });

    testWidgets('style property is stored', (tester) async {
      final ctrl = await _mount(tester, style: MorphStyle.bloom);
      expect(ctrl.style, equals(MorphStyle.bloom));
    });

    testWidgets('value is 0.0 at construction', (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.value, equals(0.0));
    });

    testWidgets('isClosing is false at construction', (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.isClosing, isFalse);
    });

    testWidgets('hasHandedOff is false at construction', (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.hasHandedOff, isFalse);
    });

    testWidgets('isShowing is false at construction', (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.isShowing, isFalse);
    });

    testWidgets('animation getter is non-null', (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.animation, isNotNull);
    });

    testWidgets('velocity is 0.0 at construction', (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.velocity, equals(0.0));
    });
  });

  // ── open() ────────────────────────────────────────────────────────────────

  group('GlassMorphController — open()', () {
    testWidgets('sets isClosing to false', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      expect(ctrl.isClosing, isFalse);
    });

    testWidgets('resets hasHandedOff to false', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();
      ctrl.close();
      await tester.pumpAndSettle();
      ctrl.open();
      expect(ctrl.hasHandedOff, isFalse);
    });

    testWidgets('value advances above 0 after one engine frame',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await _pumpFrame(tester);
      await _pumpFrame(tester);
      expect(ctrl.value, greaterThan(0.0));
    });

    testWidgets('isShowing becomes true after open() advances', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await _pumpFrame(tester);
      await _pumpFrame(tester);
      expect(ctrl.isShowing, isTrue);
    });

    testWidgets('value approaches 1.0 and triggerWidthProgress reaches 0.0',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();
      expect(ctrl.value, closeTo(1.0, 0.01));
      final state = ctrl.computeState(finalDx: 0, finalDy: 120);
      expect(state.triggerWidthProgress, equals(0.0));
      expect(state.isPlatterActive, isTrue);
      expect(state.platterOpacity, equals(1.0));
    });
  });

  // ── close() & parallel iOS 27 timeline ────────────────────────────────────

  group('GlassMorphController — close()', () {
    testWidgets('sets isClosing to true', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();
      ctrl.close();
      expect(ctrl.isClosing, isTrue);
    });

    testWidgets('value returns toward 0.0 after close() settles',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();
      ctrl.close();
      await tester.pumpAndSettle();
      expect(ctrl.value, closeTo(0.0, 0.02));
      final settled = ctrl.computeState(finalDx: 0, finalDy: 120);
      expect(settled.triggerWidthProgress, equals(1.0));
      expect(settled.triggerPushDy, equals(0.0));
      expect(settled.isPlatterActive, isFalse);
    });

    testWidgets(
        'parallel recoil peaks near ~183 ms while platter vanishes near ~285 ms and controller stays showing through ~400 ms width splash',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();

      ctrl.close();
      await tester.pump(); // start ticker at t = 0
      await tester.pump(const Duration(milliseconds: 183));
      final at183 = ctrl.computeState(finalDx: 0.0, finalDy: 125.0);
      expect(at183.triggerPushDy.abs(), greaterThan(9.0),
          reason: 'Trigger recoil must peak near ~183 ms');
      expect(at183.isPlatterActive, isTrue);

      // Advance past ~300 ms: platter has vanished (hasHandedOff == true),
      // while controller is STILL showing to finish width splash (~400 ms).
      await tester.pump(const Duration(milliseconds: 217)); // t = 400 ms
      final at400 = ctrl.computeState(finalDx: 0.0, finalDy: 125.0);
      expect(ctrl.hasHandedOff, isTrue);
      expect(at400.isPlatterActive, isFalse);
      expect(at400.platterOpacity, equals(0.0));
      expect(ctrl.isShowing, isTrue,
          reason: 'isShowing remains true while trigger splash finishes');
      expect(at400.triggerWidthProgress, greaterThan(1.01),
          reason: 'Wide trigger splashes +1.5%..2.5% past rest around 400 ms');

      await tester.pumpAndSettle();
      expect(ctrl.isShowing, isFalse);
    });

    testWidgets('hasHandedOff latches true after close animation',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();
      ctrl.close();
      await tester.pumpAndSettle();
      expect(ctrl.hasHandedOff, isTrue);
    });

    testWidgets('close() can be called before open() without crashing',
        (tester) async {
      final ctrl = await _mount(tester);
      expect(() => ctrl.close(), returnsNormally);
    });

    testWidgets('isClosing is false at construction (never closed)',
        (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.isClosing, isFalse);
    });
  });

  // ── hasHandedOff latch ────────────────────────────────────────────────────

  group('GlassMorphController — hasHandedOff latch', () {
    testWidgets('latch does not fire during open animation', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await _pumpFrame(tester);
      await _pumpFrame(tester);
      expect(ctrl.hasHandedOff, isFalse);
    });

    testWidgets('open() after close resets latch to false', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();
      ctrl.close();
      await tester.pumpAndSettle();
      expect(ctrl.hasHandedOff, isTrue);
      ctrl.open();
      expect(ctrl.hasHandedOff, isFalse);
    });

    testWidgets('latch only fires once per close cycle', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pumpAndSettle();
      ctrl.close();
      await tester.pumpAndSettle();
      final afterFirstClose = ctrl.hasHandedOff;
      await _pumpFrame(tester);
      await _pumpFrame(tester);
      expect(ctrl.hasHandedOff, equals(afterFirstClose));
    });
  });

  // ── MorphSpeed variants ───────────────────────────────────────────────────

  group('GlassMorphController — MorphSpeed variants', () {
    for (final speed in MorphSpeed.values) {
      testWidgets('$speed speed opens and settles without crashing',
          (tester) async {
        final ctrl = await _mount(tester, speed: speed);
        ctrl.open();
        await tester.pumpAndSettle();
        expect(ctrl.value, closeTo(1.0, 0.01));
      });
    }

    testWidgets('speedMultiplier orders slow < normal < fast < instant',
        (tester) async {
      final ctrl = await _mount(tester, speed: MorphSpeed.slow);
      final slowMul = ctrl.speedMultiplier;
      ctrl.speed = MorphSpeed.normal;
      final normalMul = ctrl.speedMultiplier;
      ctrl.speed = MorphSpeed.fast;
      final fastMul = ctrl.speedMultiplier;
      ctrl.speed = MorphSpeed.instant;
      final instantMul = ctrl.speedMultiplier;

      expect(normalMul, greaterThan(slowMul));
      expect(fastMul, greaterThan(normalMul));
      expect(instantMul, greaterThan(fastMul));
    });
  });

  // ── computeState integration ──────────────────────────────────────────────

  group('GlassMorphController — computeState', () {
    testWidgets('returns a valid LiquidMorphState at rest', (tester) async {
      final ctrl = await _mount(tester);
      final state = ctrl.computeState(finalDx: 80.0, finalDy: 160.0);
      expect(state.pathT, equals(0.0));
      expect(state.sizeT, equals(0.0));
      expect(state.anchorScale, equals(1.0));
      expect(state.containerScale, equals(1.0));
      expect(state.triggerWidthProgress, equals(1.0));
      expect(state.phase, equals(MorphPhase.idle));
    });

    testWidgets('currentDx > 0 after animation settles to halfway',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      while (ctrl.value < 0.5) {
        await _pumpFrame(tester);
      }
      final state = ctrl.computeState(finalDx: 80.0, finalDy: 160.0);
      expect(state.currentDx, greaterThan(0.0));
    });

    testWidgets('anchorScale decreases below 1.0 during early open',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final state = ctrl.computeState(finalDx: 80.0, finalDy: 160.0);
      expect(state.anchorScale, lessThan(1.0));
    });

    testWidgets('horizontalOffset and verticalOffset are forwarded correctly',
        (tester) async {
      final ctrl = await _mount(tester);
      expect(
        () => ctrl.computeState(
          finalDx: 80.0,
          finalDy: 160.0,
          horizontalOffset: 12.0,
          verticalOffset: 8.0,
        ),
        returnsNormally,
      );
    });
  });

  // ── ChangeNotifier / listener ─────────────────────────────────────────────

  group('GlassMorphController — ChangeNotifier', () {
    testWidgets('notifies listeners on each tick', (tester) async {
      final ctrl = await _mount(tester);
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      ctrl.open();
      await tester.pump(const Duration(milliseconds: 100));
      expect(notifyCount, greaterThan(0));
    });

    testWidgets('dispose removes listeners without crashing', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await _pumpFrame(tester);
      expect(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: SizedBox.shrink()),
          );
        },
        returnsNormally,
      );
    });
  });

  // ── velocity ─────────────────────────────────────────────────────────────

  group('GlassMorphController — velocity', () {
    testWidgets('velocity is non-zero mid-animation', (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 16));
      expect(ctrl.velocity.abs(), greaterThan(0.0));
    });
  });

  // ── Enum completeness ─────────────────────────────────────────────────────

  group('MorphPhase / MorphSpeed / MorphStyle enums', () {
    test('MorphPhase has all expected values', () {
      expect(
        MorphPhase.values,
        containsAll([
          MorphPhase.idle,
          MorphPhase.detaching,
          MorphPhase.travelling,
          MorphPhase.arriving,
          MorphPhase.settled,
        ]),
      );
    });

    test('MorphSpeed has all expected values', () {
      expect(
        MorphSpeed.values,
        containsAll([
          MorphSpeed.slow,
          MorphSpeed.normal,
          MorphSpeed.fast,
          MorphSpeed.instant,
        ]),
      );
    });

    test('MorphStyle has all expected values', () {
      expect(
        MorphStyle.values,
        containsAll([
          MorphStyle.teardrop,
          MorphStyle.bloom,
        ]),
      );
    });
  });

  // ── disableAnimations / reduced-motion ────────────────────────────────────

  group('GlassMorphController — disableAnimations', () {
    testWidgets('defaults to false', (tester) async {
      final ctrl = await _mount(tester);
      expect(ctrl.disableAnimations, isFalse);
    });

    testWidgets('setDisableAnimations(true/false) toggles flag idempotently',
        (tester) async {
      final ctrl = await _mount(tester);
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      ctrl.setDisableAnimations(false);
      expect(notifyCount, equals(0));

      ctrl.setDisableAnimations(true);
      expect(ctrl.disableAnimations, isTrue);
      ctrl.setDisableAnimations(false);
      expect(ctrl.disableAnimations, isFalse);
    });

    testWidgets('open() and close() with disableAnimations=true settle fast',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.setDisableAnimations(true);
      ctrl.open();
      await tester.pumpAndSettle();
      expect(ctrl.value, closeTo(1.0, 0.01));
      expect(ctrl.phaseElapsedSeconds, equals(0.0));

      ctrl.close();
      await tester.pumpAndSettle();
      expect(ctrl.value, closeTo(0.0, 0.01));
    });

    testWidgets('disableAnimations uses instant speedMultiplier (2.5)',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.setDisableAnimations(true);
      expect(ctrl.speedMultiplier, equals(2.5));
      expect(ctrl.value, equals(0.0));
    });
  });

  // ── Settling ──────────────────────────────────────────────────────────────

  group('GlassMorphController — settling', () {
    Future<int> runUntilStill(
        WidgetTester tester, GlassMorphController c) async {
      var elapsed = 0;
      await tester.pump();
      while (c.animation.isAnimating && elapsed < 3000) {
        await tester.pump(const Duration(microseconds: 8333));
        elapsed += 8;
      }
      return elapsed;
    }

    testWidgets('an open stops promptly (~420 ms) without spinning 22 frames',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      final ms = await runUntilStill(tester, ctrl);

      expect(ms, lessThan(500));
      expect(ctrl.value, 1.0);
      expect(ctrl.velocity, 0.0);
    });

    testWidgets('a close stops near ~550 ms on 0 and reports itself settled',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await runUntilStill(tester, ctrl);
      ctrl.close();
      final ms = await runUntilStill(tester, ctrl);

      expect(ms, inInclusiveRange(480, 620));
      expect(ctrl.value, 0.0);
      expect(ctrl.hasHandedOff, isTrue);
      expect(ctrl.isShowing, isFalse);
    });

    testWidgets(
        'a spring interrupted by another does not snap to the old target',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      ctrl.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(ctrl.value, lessThan(1.0));
      await runUntilStill(tester, ctrl);
      expect(ctrl.value, 0.0);
    });

    testWidgets(
        'settling keeps the status at completed, with no event after it',
        (tester) async {
      final ctrl = await _mount(tester);
      final statuses = <AnimationStatus>[];
      ctrl.animation.addStatusListener(statuses.add);

      ctrl.open();
      await runUntilStill(tester, ctrl);
      await tester.pump(const Duration(milliseconds: 50));

      expect(ctrl.value, 1.0);
      expect(ctrl.status, AnimationStatus.completed);
      expect(ctrl.animation.isCompleted, isTrue);
      expect(statuses, [AnimationStatus.forward, AnimationStatus.completed]);

      statuses.clear();
      ctrl.close();
      await runUntilStill(tester, ctrl);
      await tester.pump(const Duration(milliseconds: 50));

      expect(ctrl.value, 0.0);
      expect(ctrl.status, AnimationStatus.completed);
      expect(statuses.last, AnimationStatus.completed);
    });

    testWidgets(
        'single slow frame past spring settle still advances phaseElapsedSeconds (#522)',
        (tester) async {
      final ctrl = await _mount(tester);
      ctrl.open();
      // First ticker callback sets the baseline (0 ms).
      await tester.pump();
      // Simulate a cold shader-compile stall (600 ms > ~420 ms open settle):
      // AnimationController._tick calls stop() (nulling lastElapsedDuration)
      // before notifyListeners(). phaseElapsedSeconds must NOT remain 0.0.
      await tester.pump(const Duration(milliseconds: 600));

      expect(ctrl.value, 1.0);
      expect(ctrl.animation.isAnimating, isFalse);
      expect(ctrl.phaseElapsedSeconds, greaterThanOrEqualTo(1.0));
      expect(
        LiquidMorphPhysics.computeOpenContentOpacity(
          elapsedSeconds: ctrl.phaseElapsedSeconds,
        ),
        1.0,
      );
      expect(
        LiquidMorphPhysics.computeOpenContentBlur(
          elapsedSeconds: ctrl.phaseElapsedSeconds,
        ),
        0.0,
      );
      expect(
        LiquidMorphPhysics.computeOpenCornerRadius(
          currentSize: const Size(240, 260),
          restingSize: const Size(240, 260),
          targetRadius: 24.0,
          elapsedSeconds: ctrl.phaseElapsedSeconds,
        ),
        closeTo(24.0, 0.01),
      );

      // Same single-frame stall during close() must also settle cleanly.
      ctrl.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(ctrl.value, 0.0);
      expect(ctrl.animation.isAnimating, isFalse);
      expect(ctrl.hasHandedOff, isTrue);
      expect(ctrl.phaseElapsedSeconds, greaterThanOrEqualTo(1.0));
    });

    testWidgets(
        'GlassMenu settles rows and corner radius after a single-frame open stall (#522)',
        (tester) async {
      final controller = GlassMenuController();
      await tester.pumpWidget(
        LiquidGlassWidgets.wrap(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: GlassMenu(
                  controller: controller,
                  quality: GlassQuality.premium,
                  menuWidth: 240,
                  menuBorderRadius: 24,
                  trigger: const SizedBox(width: 150, height: 40),
                  items: [
                    const GlassMenuLabel(title: 'Agent'),
                    GlassMenuItem(title: 'build', onTap: () {}),
                    GlassMenuItem(title: 'plan', onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      controller.open();
      await tester.pump();
      // Single 600 ms stall jumps directly across the ~420 ms open spring.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      // Rows must be visible at full opacity (not stuck at 0.0 in a round bubble).
      expect(find.text('build'), findsOneWidget);
      final buildElement = tester.element(find.text('build'));
      final opacities = <double>[];
      buildElement.visitAncestorElements((ancestor) {
        final w = ancestor.widget;
        if (w is Opacity) opacities.add(w.opacity);
        return true;
      });
      for (final opacity in opacities) {
        expect(opacity, closeTo(1.0, 0.01),
            reason:
                'menu rows must settle to full opacity after a frame stall');
      }

      // Menu platter shape must have relaxed to menuBorderRadius (24), not
      // remained stuck at the initial bubble radius (~120).
      final containers = tester
          .widgetList<GlassContainer>(find.byType(GlassContainer))
          .where((c) => c.width == 240)
          .toList();
      expect(containers, isNotEmpty);
      final shape = containers.first.shape as LiquidRoundedSuperellipse;
      expect(shape.borderRadius, closeTo(24.0, 0.5));
    });
  });
}
