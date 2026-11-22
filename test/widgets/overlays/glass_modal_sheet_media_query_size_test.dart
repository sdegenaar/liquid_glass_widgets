// A sheet lays out against its MediaQuery, which an ancestor may size
// differently from the window: an app that lays a page out at one phone's
// width and scales it to the screen, or one side of a half-folded display.
// The sheet must rest, judge its detents and follow the finger by that one
// layout. It used to rest by the MediaQuery's height and measure progress,
// snap targets and drags by the window's, so a half-only sheet with a pixel
// `halfSize` read as short of its own detent and refused to scroll its
// content.

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

const _content = Key('content');

/// The default test view: 800 × 600.
const _view = Size(800, 600);

/// How an ancestor sizes the sheet's MediaQuery.
enum _Layout {
  /// A MediaQuery taller than the window, with no transform — the sheet's
  /// layout and the window disagree on the height and nothing else.
  taller,

  /// A MediaQuery shorter than the window, with no transform — as for one
  /// side of a display folded across its height.
  shorter,

  /// The page laid out larger and scaled down to fit the screen: a
  /// MediaQuery of `window / 0.9` under a [FittedBox].
  scaledDown,
}

const _scale = 0.9;

Size _layoutSize(_Layout layout) => switch (layout) {
      _Layout.taller => Size(_view.width, _view.height * 1.12),
      _Layout.shorter => Size(_view.width, _view.height * 0.8),
      _Layout.scaledDown => _view / _scale,
    };

/// Window pixels per layout pixel.
double _pointerScale(_Layout layout) =>
    layout == _Layout.scaledDown ? _scale : 1.0;

Widget _app(_Layout layout, Widget sheet) => createTestApp(
      child: Builder(builder: (context) {
        final media = MediaQuery.of(context);
        final size = _layoutSize(layout);
        final page = MediaQuery(
          data: media.copyWith(size: size),
          child: Stack(children: [sheet]),
        );
        if (layout != _Layout.scaledDown) return page;
        return FittedBox(
          child: SizedBox.fromSize(size: size, child: page),
        );
      }),
    );

/// A long list wired to the sheet's scroll controller and physics.
Widget _list() => Builder(builder: (context) {
      final scroll = ScrollControllerProvider.of(context);
      return ListView.builder(
        controller: scroll?.controller,
        physics: scroll?.physics,
        itemCount: 120,
        itemBuilder: (context, index) =>
            SizedBox(height: 56, child: Text('Item $index')),
      );
    });

double _contentPixels(WidgetTester tester) => tester
    .stateList<ScrollableState>(find.byType(Scrollable))
    .firstWhere(
        (state) => axisDirectionToAxis(state.axisDirection) == Axis.vertical)
    .position
    .pixels;

/// Moves [gesture] by [dy] in small steps, pumping between them.
Future<void> _dragBy(WidgetTester tester, TestGesture gesture, double dy,
    {int steps = 12}) async {
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, dy / steps));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  group('GlassModalSheet under a MediaQuery that is not the window', () {
    for (final layout in [_Layout.taller, _Layout.scaledDown]) {
      testWidgets(
          'a resting half-only sheet scrolls its content (${layout.name})',
          (tester) async {
        final controller = GlassModalSheetController();
        await tester.pumpWidget(_app(
          layout,
          GlassModalSheet(
            controller: controller,
            detents: const {GlassSheetDetent.medium},
            halfSize: 300,
            quality: GlassQuality.minimal,
            child: _list(),
          ),
        ));
        await tester.pumpAndSettle();
        final rest = controller.value;
        expect(rest, closeTo(300 / _layoutSize(layout).height, 0.0001));

        // Inside the sheet, which covers the bottom 300 layout points.
        final gesture = await tester.startGesture(const Offset(400, 520));
        await tester.pump(const Duration(milliseconds: 16));
        await _dragBy(tester, gesture, -200);
        expect(_contentPixels(tester), greaterThan(100),
            reason: 'the sheet is at its only detent, so an upward drag '
                'belongs to the content');

        await gesture.up();
        await tester.pumpAndSettle();
        expect(controller.value, closeTo(rest, 0.0001));
        expect(controller.currentState, GlassSheetState.half);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a two-detent sheet reads 0 at half and 1 at full (shorter)',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(_app(
        _Layout.shorter,
        GlassModalSheet(
          controller: controller,
          detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
          halfSize: 240,
          quality: GlassQuality.minimal,
          child: _list(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(controller.currentState, GlassSheetState.half);
      expect(controller.progress, closeTo(0.0, 0.0001),
          reason: 'a sheet resting at half has not begun to expand');

      controller.snapToState(GlassSheetState.full);
      await tester.pumpAndSettle();
      expect(controller.progress, closeTo(1.0, 0.0001),
          reason: 'a sheet resting at full has finished expanding');

      // At full the content is free to scroll.
      final gesture = await tester.startGesture(const Offset(400, 400));
      await tester.pump(const Duration(milliseconds: 16));
      await _dragBy(tester, gesture, -200);
      expect(_contentPixels(tester), greaterThan(100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.currentState, GlassSheetState.full);
      expect(tester.takeException(), isNull);
    });

    for (final layout in [_Layout.shorter, _Layout.scaledDown]) {
      testWidgets('a drag keeps the sheet under the finger (${layout.name})',
          (tester) async {
        final controller = GlassModalSheetController();
        await tester.pumpWidget(_app(
          layout,
          GlassModalSheet(
            controller: controller,
            detents: const {GlassSheetDetent.medium},
            halfSize: 300,
            quality: GlassQuality.minimal,
            child: const SizedBox(key: _content, height: 300),
          ),
        ));
        await tester.pumpAndSettle();

        // The sheet's height on screen, in window pixels.
        double onScreen() =>
            controller.value *
            _layoutSize(layout).height *
            _pointerScale(layout);

        final gesture =
            await tester.startGesture(tester.getCenter(find.byKey(_content)));
        await tester.pump(const Duration(milliseconds: 16));
        // Past the drag threshold first, so the sheet has claimed the drag.
        await _dragBy(tester, gesture, 20, steps: 4);
        final before = onScreen();
        await _dragBy(tester, gesture, 60, steps: 6);
        expect(before - onScreen(), closeTo(60, 0.01),
            reason: 'the sheet should move exactly as far as the finger');

        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    // The package's own case: show() lays a sheet out in one side of a
    // half-folded display, with a MediaQuery of that side's size.
    testWidgets('show() into the top side of a display folded across it',
        (tester) async {
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(0, 300, 800, 300),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
      final controller = GlassModalSheetController();
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) => Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => GlassModalSheet.show<void>(
                context: context,
                controller: controller,
                initialState: GlassSheetState.full,
                quality: GlassQuality.minimal,
                builder: (_) => _list(),
              ),
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ));
      await tester.tapAt(const Offset(400, 300));
      await tester.pumpAndSettle();
      expect(controller.currentState, GlassSheetState.full);
      expect(controller.progress, closeTo(1.0, 0.0001));

      // A drag inside the sheet, in the top side, scrolls the content.
      final gesture = await tester.startGesture(const Offset(400, 200));
      await tester.pump(const Duration(milliseconds: 16));
      await _dragBy(tester, gesture, -120);
      expect(_contentPixels(tester), greaterThan(60));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.currentState, GlassSheetState.full);
      expect(tester.takeException(), isNull);
    });
  });
}
