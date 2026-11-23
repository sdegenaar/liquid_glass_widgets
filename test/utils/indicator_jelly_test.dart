import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/utils/indicator_jelly.dart'
    show IndicatorJellyBuilder;

double _right(IndicatorJelly j) => j.offsetX + (j.scaleX - 1) / 2;
double _left(IndicatorJelly j) => j.offsetX - (j.scaleX - 1) / 2;

void main() {
  group('IndicatorJelly.resolve', () {
    test('is identity at rest', () {
      final j = IndicatorJelly.resolve(
        lead: 0.5,
        trail: 0.5,
        itemCount: 5,
        travelDirection: 1,
        dragging: false,
      );
      expect(j.isIdentity, isTrue);
    });

    test('travel stretch pulls only the edge facing the destination', () {
      final j = IndicatorJelly.resolve(
        lead: 0,
        trail: -0.4,
        itemCount: 5,
        travelDirection: 1,
        dragging: false,
        stretch: 0.12,
      );
      expect(_right(j), closeTo(0.12, 1e-9));
      expect(_left(j), closeTo(0, 1e-9));
      expect(
        j.scaleY,
        closeTo(1 - IndicatorJellyPhysics.native.travelThinning * 0.12, 1e-9),
      );
    });

    test('a leftward travel stretch moves the left edge', () {
      final j = IndicatorJelly.resolve(
        lead: 0,
        trail: 0,
        itemCount: 5,
        travelDirection: -1,
        dragging: false,
        stretch: -0.1,
      );
      expect(_left(j), closeTo(-0.1, 1e-9));
      expect(_right(j), closeTo(0, 1e-9));
    });

    test('the landing squish comes from the trailing edge and bulges', () {
      const physics = IndicatorJellyPhysics.native;
      final j = IndicatorJelly.resolve(
        lead: 1.0,
        trail: 1.05,
        itemCount: 5,
        travelDirection: 1,
        dragging: false,
      );
      expect(j.scaleX, closeTo(0.9, 1e-9));
      expect(_left(j), closeTo(0.1 * (1 + physics.squishAnchor) / 2, 1e-9));
      expect(_right(j), closeTo(-0.1 * (1 - physics.squishAnchor) / 2, 1e-9));
      expect(j.scaleY, closeTo(1 + physics.compressionBulge * 0.1, 1e-9));
    });

    test('the landing squish is clamped to maxCompression', () {
      final j = IndicatorJelly.resolve(
        lead: -1.0,
        trail: -1.5,
        itemCount: 5,
        travelDirection: -1,
        dragging: false,
      );
      expect(
        j.scaleX,
        closeTo(1 - IndicatorJellyPhysics.native.maxCompression, 1e-9),
      );
    });

    test('while dragging the trailing edge lags and never squishes', () {
      final lagging = IndicatorJelly.resolve(
        lead: 0.2,
        trail: -0.2,
        itemCount: 5,
        travelDirection: 1,
        dragging: true,
      );
      expect(_right(lagging), closeTo(0, 1e-9));
      expect(_left(lagging), lessThan(0));
      expect(
        lagging.scaleX,
        lessThanOrEqualTo(1 + IndicatorJellyPhysics.native.maxDragStretch),
      );
      // Even at maximum drag stretch, vertical thinning stays above ~0.91 so a
      // lifted 70 pt tab-bar lens never shrinks inside the 62 pt bar platter
      // and loses its top/bottom pinch moat.
      final maxDrag = IndicatorJelly.resolve(
        lead: 1.0,
        trail: -1.0,
        itemCount: 4,
        travelDirection: 1,
        dragging: true,
      );
      expect(maxDrag.scaleY, greaterThanOrEqualTo(0.91));

      final overshooting = IndicatorJelly.resolve(
        lead: 0.2,
        trail: 0.3,
        itemCount: 5,
        travelDirection: 1,
        dragging: true,
      );
      expect(overshooting.scaleX, greaterThanOrEqualTo(1));
    });

    test('disabled physics never deforms', () {
      final j = IndicatorJelly.resolve(
        lead: 1,
        trail: 1.2,
        itemCount: 5,
        travelDirection: 1,
        dragging: false,
        stretch: 0.1,
        physics: IndicatorJellyPhysics.disabled,
      );
      expect(j.isIdentity, isTrue);
    });
  });

  group('IndicatorJelly geometry', () {
    test('matrixFor scales about the centre and shifts by offsetX', () {
      const rect = Rect.fromLTWH(100, 10, 80, 40);
      const j = IndicatorJelly(scaleX: 0.75, scaleY: 1.1, offsetX: 0.1);
      final m = j.matrixFor(rect);
      final left = MatrixUtils.transformPoint(m, rect.centerLeft);
      final right = MatrixUtils.transformPoint(m, rect.centerRight);
      final top = MatrixUtils.transformPoint(m, rect.topCenter);
      expect(right.dx - left.dx, closeTo(60, 1e-9));
      expect((left.dx + right.dx) / 2, closeTo(rect.center.dx + 8, 1e-9));
      expect(top.dy, closeTo(rect.center.dy - 22, 1e-9));
    });

    test('mirrored reflects the shift', () {
      const j = IndicatorJelly(scaleX: 1.2, scaleY: 0.9, offsetX: 0.1);
      expect(j.mirrored.offsetX, -0.1);
      expect(j.mirrored.scaleX, 1.2);
      expect(j.mirrored.scaleY, 0.9);
    });
  });

  group('JellyClipper track clamp', () {
    Rect bounds({required bool clamp, required double alignment}) =>
        JellyClipper(
          itemCount: 5,
          alignment: Alignment(alignment, 0),
          thickness: 1,
          expansion: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          transform: Matrix4.identity(),
          borderRadius: 999,
          clampExpansionToTrack: clamp,
        ).getClip(const Size(360, 62)).getBounds();

    test('the lifted mask reaches the bar edge but never passes it', () {
      expect(bounds(clamp: true, alignment: 1).right, closeTo(360, 1e-3));
      expect(bounds(clamp: true, alignment: -1).left, closeTo(0, 1e-3));
      expect(bounds(clamp: false, alignment: 1).right, closeTo(362, 1e-3));
    });

    test('cells away from the ends keep the full lift', () {
      final middle = bounds(clamp: true, alignment: 0);
      expect(middle.width, closeTo(352 / 5 + 12, 1e-3));
    });
  });

  group('IndicatorJellyPhysics', () {
    test('copyWith replaces only the given values', () {
      final tuned = IndicatorJellyPhysics.native.copyWith(trailingBounce: 0.2);
      expect(tuned.trailingBounce, 0.2);
      expect(tuned.travelStretch, IndicatorJellyPhysics.native.travelStretch);
      expect(tuned, isNot(IndicatorJellyPhysics.native));
      expect(
        IndicatorJellyPhysics.native.copyWith(),
        IndicatorJellyPhysics.native,
      );
    });

    test('disabled turns the jelly off', () {
      expect(IndicatorJellyPhysics.disabled.enabled, isFalse);
      expect(IndicatorJellyPhysics.native.enabled, isTrue);
    });
  });

  group('IndicatorJellyBuilder', () {
    // The lead is the package's released position spring (snappy 350 ms,
    // bounce 0.15) sampled at 120 fps. Targets come from a native UITabBar
    // (iOS 27.2 simulator, 5 tabs, real XCUITest taps): the edge facing the
    // destination is pulled ≈12 % ahead ≈0.15 s into the travel, then the
    // pill squishes from the trailing side, tuned a little deeper than the
    // measured 0.958× / 0.928× / 0.85× (1 / 2 / 4 tabs) for feel, ≈0.45 s
    // after the tap, bulging vertically, and is
    // back within 1 % ≈0.67–0.75 s after the tap with no visible rebound.
    testWidgets('4-tab jump matches the native stretch, squish and settle',
        (tester) async {
      final run = await _runJump(tester, from: -1, to: 1, label: '4-tab');
      expect(run.maxScaleX, inInclusiveRange(1.10, 1.13));
      expect(run.maxAt, inInclusiveRange(0.11, 0.18));
      expect(run.trailingNeverLags, isTrue);
      expect(run.minScaleX, inInclusiveRange(0.78, 0.83));
      expect(run.minAt, inInclusiveRange(0.40, 0.52));
      expect(run.scaleYAtMin, inInclusiveRange(1.15, 1.26));
      expect(run.leadingStaysInTrack, isTrue);
      expect(run.reboundScaleX, lessThanOrEqualTo(1.01));
      expect(run.settledAt, inInclusiveRange(0.62, 0.82));
    });

    testWidgets('2-tab jump squishes in proportion', (tester) async {
      final run = await _runJump(tester, from: -1, to: 0, label: '2-tab');
      expect(run.maxScaleX, inInclusiveRange(1.10, 1.13));
      expect(run.minScaleX, inInclusiveRange(0.89, 0.92));
      expect(run.minAt, inInclusiveRange(0.40, 0.52));
      expect(run.reboundScaleX, lessThanOrEqualTo(1.01));
      expect(run.settledAt, inInclusiveRange(0.55, 0.80));
    });

    testWidgets('1-tab hop squishes lightly and settles', (tester) async {
      final run = await _runJump(tester, from: 1, to: 0.5, label: '1-tab');
      expect(run.maxScaleX, inInclusiveRange(1.10, 1.13));
      expect(run.trailingNeverLags, isTrue);
      expect(run.minScaleX, inInclusiveRange(0.94, 0.965));
      expect(run.minAt, inInclusiveRange(0.38, 0.52));
      expect(run.settledAt, inInclusiveRange(0.45, 0.75));
      expect(run.offsetSigns, {-1.0});
    });

    testWidgets('reversing mid-flight never squishes before landing',
        (tester) async {
      final run = await _runJump(
        tester,
        from: -1,
        to: 1,
        reverseTo: -1,
        reverseAt: 0.1,
        label: 'reverse',
      );
      final beforeLanding = run.samples.where((s) => s.t <= run.landing);
      expect(beforeLanding.every((s) => s.jelly.scaleX >= 1 - 1e-9), isTrue);
      expect(run.minScaleX, greaterThan(0.8));
    });

    testWidgets('reduce motion snaps without any deformation', (tester) async {
      final run = await _runJump(tester, from: -1, to: 1, reduceMotion: true);
      expect(run.samples.every((s) => s.jelly.isIdentity), isTrue);
    });

    testWidgets('disabled physics never deforms', (tester) async {
      final run = await _runJump(
        tester,
        from: -1,
        to: 1,
        physics: IndicatorJellyPhysics.disabled,
      );
      expect(run.samples.every((s) => s.jelly.isIdentity), isTrue);
    });

    testWidgets(
        'dragging stretches on acceleration, relaxes at steady speed, and '
        'bulges vertically on deceleration/reversal (native iOS 27 oscillator)',
        (tester) async {
      final jellies = <IndicatorJelly>[];
      Widget build(double target, double lead, bool dragging) => Directionality(
            textDirection: TextDirection.ltr,
            child: IndicatorJellyBuilder(
              target: target,
              lead: lead,
              itemCount: 4,
              dragging: dragging,
              builder: (context, jelly, _) {
                jellies.add(jelly);
                return const SizedBox();
              },
            ),
          );

      await tester.pumpWidget(build(-1, -1, false));
      // Prime drag start
      await tester.pumpWidget(build(-1, -1, true), duration: _frame);

      // 1. Accelerate sharply rightwards (20 frames ≈ 167 ms) -> stretches wide,
      //    stays above 0.91 vertically so the top/bottom pinch never drops out.
      double x = -1.0;
      double maxStretchX = 1.0;
      double minStretchY = 1.0;
      for (var i = 1; i <= 20; i++) {
        x = (-1.0 + i * 0.07).clamp(-1.0, 1.0);
        await tester.pumpWidget(build(x, x, true), duration: _frame);
        final j = jellies.last;
        if (j.scaleX > maxStretchX) maxStretchX = j.scaleX;
        if (j.scaleY < minStretchY) minStretchY = j.scaleY;
      }
      expect(maxStretchX, greaterThan(1.04));
      expect(minStretchY, greaterThanOrEqualTo(0.91));

      // 2. Decelerate / hold finger still mid-drag -> squishes narrower &
      //    bulges taller (scaleX < 1, scaleY > 1), matching real iOS 27.
      double minSquishX = 1.0;
      double maxBulgeY = 1.0;
      for (var i = 0; i < 30; i++) {
        await tester.pumpWidget(build(x, x, true), duration: _frame);
        final j = jellies.last;
        if (j.scaleX < minSquishX) minSquishX = j.scaleX;
        if (j.scaleY > maxBulgeY) maxBulgeY = j.scaleY;
      }
      expect(minSquishX, lessThan(0.97));
      expect(maxBulgeY, greaterThan(1.04));

      // 3. Release and settle -> ticker stops with zero idle scheduled frames.
      await tester.pumpWidget(build(x, x, false), duration: _frame);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(jellies.last.isIdentity, isTrue);
    });

    testWidgets('stops ticking and rebuilding once the shape has settled',
        (tester) async {
      var builds = 0;
      Widget build(double target) => Directionality(
            textDirection: TextDirection.ltr,
            child: IndicatorJellyBuilder(
              target: target,
              lead: target,
              itemCount: 5,
              dragging: false,
              builder: (context, jelly, _) {
                builds++;
                return const SizedBox();
              },
            ),
          );

      await tester.pumpWidget(build(-1));
      await tester.pumpWidget(build(1));
      var lastBuildAt = Duration.zero;
      var elapsed = Duration.zero;
      while (elapsed < const Duration(seconds: 2)) {
        final before = builds;
        await tester.pump(_frame);
        elapsed += _frame;
        if (builds != before) lastBuildAt = elapsed;
      }
      expect(lastBuildAt, lessThan(const Duration(milliseconds: 1100)));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('clamps scaleX to a positive floor under extreme compression',
        (tester) async {
      final j = IndicatorJelly.resolve(
        lead: 1.5,
        trail: 2.5,
        itemCount: 5,
        travelDirection: 1,
        dragging: false,
        physics: const IndicatorJellyPhysics(maxCompression: 0.9),
      );
      expect(j.scaleX, greaterThanOrEqualTo(0.05));
    });

    test('IndicatorJellyPhysics asserts valid numeric ranges', () {
      expect(
        () => IndicatorJellyPhysics(travelStretchBounce: 1.0),
        throwsAssertionError,
      );
      expect(
        () => IndicatorJellyPhysics(trailingBounce: 1.0),
        throwsAssertionError,
      );
      expect(
        () => IndicatorJellyPhysics(squishAnchor: 1.5),
        throwsAssertionError,
      );
      expect(
        () => IndicatorJellyPhysics(maxCompression: 1.0),
        throwsAssertionError,
      );
      expect(
        () => IndicatorJellyPhysics(maxDragStretch: -0.1),
        throwsAssertionError,
      );
    });

    testWidgets('mid-flight reduceMotion toggle snaps immediately and stops',
        (tester) async {
      final reduceMotion = ValueNotifier<bool>(false);
      addTearDown(reduceMotion.dispose);
      late IndicatorJelly latest;

      Widget build(double target, double lead) => ValueListenableBuilder<bool>(
            valueListenable: reduceMotion,
            builder: (context, reduced, child) => MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: child!,
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: IndicatorJellyBuilder(
                target: target,
                lead: lead,
                itemCount: 5,
                dragging: false,
                builder: (context, jelly, _) {
                  latest = jelly;
                  return const SizedBox();
                },
              ),
            ),
          );

      await tester.pumpWidget(build(-1, -1));
      await tester.pumpWidget(build(1, -1));
      await tester.pump(const Duration(milliseconds: 80));
      expect(latest.isIdentity, isFalse);

      // Flip reduceMotion on mid-flight without changing widget props.
      reduceMotion.value = true;
      await tester.pump();
      expect(latest.isIdentity, isTrue);
      // Drain any already-queued frame and verify the ticker stays stopped.
      await tester.pump(_frame);
      expect(latest.isIdentity, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('passes child through without rebuilding it on jelly ticks',
        (tester) async {
      var childBuilds = 0;
      Widget build(double target) => Directionality(
            textDirection: TextDirection.ltr,
            child: IndicatorJellyBuilder(
              target: target,
              lead: target,
              itemCount: 5,
              dragging: false,
              child: Builder(
                builder: (context) {
                  childBuilds++;
                  return const SizedBox();
                },
              ),
              builder: (context, jelly, child) => child!,
            ),
          );

      await tester.pumpWidget(build(-1));
      await tester.pumpWidget(build(1));
      final afterTargetChange = childBuilds;
      for (var i = 0; i < 30; i++) {
        await tester.pump(_frame);
      }
      expect(childBuilds, afterTargetChange);
    });
  });

  group('Widget integration (GlassTabBar & GlassSegmentedControl)', () {
    const tabs = <GlassTab>[
      GlassTab(icon: Icon(CupertinoIcons.home), label: 'Home'),
      GlassTab(icon: Icon(CupertinoIcons.search), label: 'Search'),
      GlassTab(icon: Icon(CupertinoIcons.person), label: 'Profile'),
    ];

    testWidgets('GlassTabBar.bottom supports default and disabled jelly',
        (tester) async {
      for (final physics in <IndicatorJellyPhysics?>[
        null,
        IndicatorJellyPhysics.disabled,
      ]) {
        var selected = 0;
        await tester.pumpWidget(
          CupertinoApp(
            home: StatefulBuilder(
              builder: (context, setState) => Align(
                alignment: Alignment.bottomCenter,
                child: GlassTabBar.bottom(
                  tabs: tabs,
                  selectedIndex: selected,
                  quality: GlassQuality.minimal,
                  indicatorJelly: physics,
                  onTabSelected: (i) => setState(() => selected = i),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'GlassSegmentedControl supports default, disabled, and RTL jelly',
        (tester) async {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        for (final physics in <IndicatorJellyPhysics?>[
          null,
          IndicatorJellyPhysics.disabled,
        ]) {
          var selected = 0;
          await tester.pumpWidget(
            CupertinoApp(
              home: Directionality(
                textDirection: direction,
                child: StatefulBuilder(
                  builder: (context, setState) => Center(
                    child: GlassSegmentedControl(
                      segments: const [
                        GlassSegment(label: 'One'),
                        GlassSegment(label: 'Two'),
                        GlassSegment(label: 'Three'),
                      ],
                      selectedIndex: selected,
                      quality: GlassQuality.minimal,
                      indicatorJelly: physics,
                      onSegmentSelected: (i) => setState(() => selected = i),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Three'));
          await tester.pumpAndSettle();
          expect(selected, 2);
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets(
        'GlassTabBar.bottom and .searchable allow outer edge overhang '
        '(matching native iOS 27 _UILiquidLensView)', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.bottomCenter,
            child: GlassTabBar.bottom(
              tabs: const [
                GlassTab(label: 'One', icon: Icon(CupertinoIcons.home)),
                GlassTab(label: 'Two', icon: Icon(CupertinoIcons.search)),
                GlassTab(label: 'Three', icon: Icon(CupertinoIcons.person)),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bottomIndicators = tester.widgetList<AnimatedGlassIndicator>(
        find.byType(AnimatedGlassIndicator),
      );
      expect(bottomIndicators, isNotEmpty);
      expect(
        bottomIndicators.every((i) => !i.clampExpansionToTrack),
        isTrue,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.bottomCenter,
            child: GlassTabBar.searchable(
              tabs: const [
                GlassTab(label: 'One', icon: Icon(CupertinoIcons.home)),
                GlassTab(label: 'Two', icon: Icon(CupertinoIcons.search)),
                GlassTab(label: 'Three', icon: Icon(CupertinoIcons.person)),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              searchConfig: GlassSearchBarConfig(
                onSearchToggle: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchableIndicators = tester.widgetList<AnimatedGlassIndicator>(
        find.byType(AnimatedGlassIndicator),
      );
      expect(searchableIndicators, isNotEmpty);
      expect(
        searchableIndicators.every((i) => !i.clampExpansionToTrack),
        isTrue,
      );
    });
  });
}

const _frame = Duration(microseconds: 8333);
const _trace = bool.fromEnvironment('JELLY_TRACE');

typedef _Sample = ({double t, double lead, IndicatorJelly jelly});

class _Jump {
  _Jump(
    this.samples,
    this.to, {
    required this.travelFrom,
    required this.travelStart,
  });

  final List<_Sample> samples;
  final double to;

  /// Where and when the last travel toward [to] started.
  final double travelFrom;
  final double travelStart;

  double get _dt => _frame.inMicroseconds / Duration.microsecondsPerSecond;

  double get _direction => to >= travelFrom ? 1.0 : -1.0;

  /// First frame where the leading edge is within 1 % of the travel.
  double get landing {
    final travel = (to - travelFrom).abs();
    return samples
        .firstWhere(
          (s) => s.t >= travelStart && (s.lead - to).abs() <= 0.01 * travel,
        )
        .t;
  }

  _Sample get _min =>
      samples.reduce((a, b) => b.jelly.scaleX < a.jelly.scaleX ? b : a);

  _Sample get _max =>
      samples.reduce((a, b) => b.jelly.scaleX > a.jelly.scaleX ? b : a);

  double get minScaleX => _min.jelly.scaleX;

  double get minAt => _min.t;

  double get scaleYAtMin => _min.jelly.scaleY;

  double get maxScaleX => _max.jelly.scaleX;

  double get maxAt => _max.t;

  /// Whether the trailing edge stays put while the pill travels: the travel
  /// stretch only pulls the leading edge ahead.
  bool get trailingNeverLags =>
      samples.where((s) => s.t <= landing).every((s) =>
          _direction * (_direction > 0 ? _left(s.jelly) : _right(s.jelly)) >=
          -1e-9);

  /// Whether the leading edge stays inside the track once the pill reaches
  /// an end cell (position overshoot and stretch become squish instead).
  bool get leadingStaysInTrack => samples.where((s) => s.t >= landing).every(
        (s) => _direction > 0
            ? (s.lead - 1) * 2 + _right(s.jelly) <= 1e-9
            : (-1 - s.lead) * 2 - _left(s.jelly) <= 1e-9,
      );

  double get reboundScaleX => samples
      .where((s) => s.t > minAt)
      .map((s) => s.jelly.scaleX)
      .reduce(math.max);

  /// Time from which scaleX stays within 0.01 of rest.
  double get settledAt {
    final last = samples.lastWhere(
      (s) => (s.jelly.scaleX - 1).abs() > 0.01,
      orElse: () => samples.first,
    );
    return last.t + _dt;
  }

  Set<double> get offsetSigns => {
        for (final s in samples)
          if (s.jelly.offsetX.abs() > 1e-6) s.jelly.offsetX.sign,
      };
}

/// Taps from [from] to [to] (alignment units, 5 cells) and records the jelly
/// every frame, with the lead on the real released position spring. Both
/// springs start in the same frame, as in the tab bar.
Future<_Jump> _runJump(
  WidgetTester tester, {
  required double from,
  required double to,
  double? reverseTo,
  double reverseAt = 0,
  bool reduceMotion = false,
  IndicatorJellyPhysics physics = IndicatorJellyPhysics.native,
  String label = '',
}) async {
  late IndicatorJelly latest;
  Widget build(double target, double lead) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: IndicatorJellyBuilder(
            target: target,
            lead: lead,
            itemCount: 5,
            dragging: false,
            physics: physics,
            builder: (context, jelly, _) {
              latest = jelly;
              return const SizedBox();
            },
          ),
        ),
      );

  final released = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 350),
    bounce: 0.15,
  );
  await tester.pumpWidget(build(from, from));
  await tester.pumpWidget(build(to, reduceMotion ? to : from));

  final dt = _frame.inMicroseconds / Duration.microsecondsPerSecond;
  var target = to;
  var lead = SpringSimulation(released, from, to, 0);
  var leadStart = 0.0;
  var travelFrom = from;
  var travelStart = 0.0;
  final samples = <_Sample>[
    (t: 0.0, lead: reduceMotion ? to : from, jelly: latest),
  ];
  for (var t = dt; t <= 1.5; t += dt) {
    if (reverseTo != null && target != reverseTo && t >= reverseAt) {
      final local = t - leadStart;
      lead =
          SpringSimulation(released, lead.x(local), reverseTo, lead.dx(local));
      leadStart = t;
      target = reverseTo;
      travelFrom = lead.x(0);
      travelStart = t;
    }
    final x = reduceMotion ? target : lead.x(t - leadStart);
    await tester.pumpWidget(build(target, x), duration: _frame);
    samples.add((t: t, lead: x, jelly: latest));
  }

  final run = _Jump(
    samples,
    target,
    travelFrom: travelFrom,
    travelStart: travelStart,
  );
  if (_trace) {
    debugPrint('── $label: t(ms)  lead  scaleX  scaleY  offsetX');
    for (final s in samples) {
      debugPrint('${(s.t * 1000).toStringAsFixed(2).padLeft(8)}  '
          '${s.lead.toStringAsFixed(4).padLeft(7)}  '
          '${s.jelly.scaleX.toStringAsFixed(4)}  '
          '${s.jelly.scaleY.toStringAsFixed(4)}  '
          '${s.jelly.offsetX.toStringAsFixed(4)}');
    }
    if (!reduceMotion && physics.enabled) {
      debugPrint('── $label summary: landing ${run.landing.toStringAsFixed(3)} '
          's, max scaleX ${run.maxScaleX.toStringAsFixed(3)} at '
          '${run.maxAt.toStringAsFixed(3)} s, min scaleX '
          '${run.minScaleX.toStringAsFixed(3)} (scaleY '
          '${run.scaleYAtMin.toStringAsFixed(3)}) at '
          '${run.minAt.toStringAsFixed(3)} s, rebound '
          '${run.reboundScaleX.toStringAsFixed(4)}, settled at '
          '${run.settledAt.toStringAsFixed(3)} s');
    }
  }
  return run;
}
