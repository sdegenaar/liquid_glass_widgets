import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _screen = Size(390, 844);
const _dpr = 3.0;
const _safeBottom = 34.0;
const _margin = 8.0; // the sheet's default side and bottom margins
const _limit = 844.0 - 90.0; // the default fullSize, which caps the sheet
const _halfHeight = 0.525 * 844.0; // the default halfSize
const _headerHeight = 56.0;
const _actionsHeight = 50.0;
const _expandedColor = Color(0xFF123456);
const _fitted = {GlassSheetDetent.fitted};

const _header = Key('header');
const _body = Key('body');
const _actions = Key('actions');
const _barrier = Key('barrier');
const _fill = Key('glass_modal_sheet_fill');

/// The content's height for a scroll body of [body] at rest: header, body,
/// actions and the content's own bottom safe-area padding.
double _contentHeight(double body) =>
    _headerHeight + body + _actionsHeight + _safeBottom;

/// The sheet's height above the bottom of the screen for content [height]
/// tall: the content and the bottom margin below the sheet.
double _fittedHeight(double height) => height + _margin;

/// The shape of content the sheet is meant for: a shrink-wrapped column of a
/// header, a flexible scroll view on the sheet's controller and physics, and
/// an actions row, padded for the keyboard or else the bottom safe area.
class _Content extends StatelessWidget {
  const _Content({
    required this.bodyHeight,
    this.onAction,
    this.padsForKeyboard = true,
  });

  final double Function(double width) bodyHeight;
  final VoidCallback? onAction;
  final bool padsForKeyboard;

  @override
  Widget build(BuildContext context) {
    final provider = ScrollControllerProvider.of(context)!;
    final keyboard =
        padsForKeyboard ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard > 0 ? keyboard : safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(key: _header, height: _headerHeight),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                controller: provider.controller,
                physics: provider.physics,
                child: SizedBox(
                  key: _body,
                  height: bodyHeight(constraints.maxWidth),
                ),
              ),
            ),
          ),
          GestureDetector(
            key: _actions,
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: const SizedBox(
              height: _actionsHeight,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}

class _Harness {
  final controller = GlassModalSheetController();
  final states = <GlassSheetState>[];
  int barrierTaps = 0;
  int actionTaps = 0;

  /// Vetoes dismissal the way the app's route does: snaps back to half.
  bool veto = false;

  Widget sheet({
    required Widget child,
    bool fit = true,
    GlassSheetState initialState = GlassSheetState.half,
    bool showDragIndicator = true,
    bool dismissible = true,
    double? fullSize,
    bool pressFeedback = true,
  }) =>
      GlassModalSheet(
        controller: controller,
        // The sheet swells a little under a finger. Tests that measure
        // a held frame turn that off.
        interactionScale: pressFeedback ? 1.01 : 1.0,
        stretch: pressFeedback ? 0.5 : 0.0,
        initialState: initialState,
        detents: fit ? _fitted : const {GlassSheetDetent.medium},
        fullSize: fullSize,
        dismissible: dismissible,
        expandedColor: _expandedColor,
        fillTransition: GlassFillTransition.instant,
        showDragIndicator: showDragIndicator,
        onStateChanged: (state) {
          states.add(state);
          if (veto && state == GlassSheetState.hidden) {
            controller.snapToState(GlassSheetState.half);
          }
        },
        child: child,
      );

  Widget app(Widget sheet) => MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: _barrier,
                behavior: HitTestBehavior.opaque,
                onTap: () => barrierTaps++,
              ),
            ),
            sheet,
          ],
        ),
      );

  Widget content({
    double body = 200,
    double Function(double width)? bodyHeight,
    bool padsForKeyboard = true,
  }) =>
      _Content(
        bodyHeight: bodyHeight ?? (_) => body,
        onAction: () => actionTaps++,
        padsForKeyboard: padsForKeyboard,
      );
}

void _phone(WidgetTester tester, {Size size = _screen}) {
  tester.view.physicalSize = size * _dpr;
  tester.view.devicePixelRatio = _dpr;
  tester.view.padding = const FakeViewPadding(bottom: _safeBottom * _dpr);
  addTearDown(tester.view.reset);
}

double _screenHeight(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio;

/// The sheet's height above the bottom of the screen.
double _visibleHeight(WidgetTester tester) =>
    _screenHeight(tester) - tester.getRect(find.byKey(_fill)).top;

Color _fillColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(find.byKey(_fill));
  return (box.decoration as BoxDecoration).color!;
}

/// Expects the look of the half state: the side and bottom margins around
/// the sheet, and no opaque fill.
void _expectHalfLook(WidgetTester tester) {
  final fill = tester.getRect(find.byKey(_fill));
  expect(fill.left, closeTo(_margin, 0.01));
  expect(fill.right, closeTo(_screen.width - _margin, 0.01));
  expect(fill.bottom, closeTo(_screen.height - _margin, 0.01));
  expect(_fillColor(tester).a, 0.0);
}

Rect _morphPortal(WidgetTester tester) {
  final clip = tester.widget<ClipPath>(find
      .ancestor(
          of: find.byKey(_fill, skipOffstage: false),
          matching: find.byWidgetPredicate(
              (widget) => widget is ClipPath && widget.child is Transform))
      .first);
  return clip.clipper!.getClip(_screen).getBounds();
}

Rect _frame(WidgetTester tester) => tester.getRect(find.byKey(_fill));

/// Drags the sheet 40 logical pixels down by its handle and holds it there
/// long enough that the release is not a fling.
Future<TestGesture> _dragDownAndHold(WidgetTester tester) async {
  final gesture =
      await tester.startGesture(_frame(tester).topCenter + const Offset(0, 20));
  for (var i = 0; i < 4; i++) {
    await gesture.moveBy(const Offset(0, 10));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 400));
  return gesture;
}

/// Shows a fitted sheet whose content is as tall as [height], embedded in a
/// stack or presented by `show` with a liquid morph.
Future<void> _present(
  WidgetTester tester, {
  required ValueNotifier<double> height,
  bool morph = false,
  GlassModalSheetController? controller,
  GlassSheetState initialState = GlassSheetState.half,
  ValueChanged<GlassSheetState>? onStateChanged,
}) async {
  _phone(tester);
  Widget content(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: height,
        builder: (context, value, child) => SizedBox(height: value),
      );
  if (!morph) {
    await tester.pumpWidget(MaterialApp(
      home: Stack(children: [
        GlassModalSheet(
          controller: controller,
          detents: _fitted,
          initialState: initialState,
          onStateChanged: onStateChanged,
          child: Builder(builder: content),
        ),
      ]),
    ));
  } else {
    GlassModalSheet.debugMorphSupportsBlending = true;
    addTearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);
    const home = Key('home');
    await tester
        .pumpWidget(const MaterialApp(home: SizedBox.expand(key: home)));
    GlassModalSheet.show<void>(
      context: tester.element(find.byKey(home)),
      detents: _fitted,
      morphFromRect: const Rect.fromLTWH(175, 300, 40, 40),
      builder: content,
    );
  }
  await tester.pumpAndSettle();
}

/// The sets of detents that hold [GlassSheetDetent.fitted] but break its
/// rule, with the mode each is shown in.
const _invalidFittedConfigurations = [
  (
    GlassSheetMode.dismissible,
    {GlassSheetDetent.fitted, GlassSheetDetent.medium}
  ),
  (
    GlassSheetMode.dismissible,
    {GlassSheetDetent.fitted, GlassSheetDetent.large}
  ),
  (
    GlassSheetMode.dismissible,
    {GlassSheetDetent.small, GlassSheetDetent.fitted}
  ),
  (GlassSheetMode.persistent, {GlassSheetDetent.fitted}),
];

void main() {
  group('GlassSheetDetent.fitted', () {
    testWidgets(
        'rests at the height of short content, below half, with the half '
        'look', (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester.pumpWidget(h.app(h.sheet(child: h.content())));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(h.controller.currentState, GlassSheetState.half);
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(200)), 0.01));
      expect(_fittedHeight(_contentHeight(200)), lessThan(_halfHeight));
      _expectHalfLook(tester);
      // The content, its safe-area padding included, ends at the sheet's
      // bottom edge: nothing is hidden below it.
      expect(tester.getRect(find.byKey(_actions)).bottom,
          closeTo(_screen.height - _margin - _safeBottom, 0.01));
      expect(tester.getRect(find.byKey(_header)).top,
          closeTo(_screen.height - _fittedHeight(_contentHeight(200)), 0.01));
    });

    testWidgets(
        'rests above halfSize with content at 80% of the screen, still '
        'with the half look', (tester) async {
      _phone(tester);
      final h = _Harness();
      const height = 0.8 * 844.0;
      await tester
          .pumpWidget(h.app(h.sheet(child: const SizedBox(height: height))));
      await tester.pumpAndSettle();

      expect(_visibleHeight(tester), closeTo(_fittedHeight(height), 0.01));
      expect(_visibleHeight(tester), greaterThan(_halfHeight));
      _expectHalfLook(tester);
      expect(h.controller.currentState, GlassSheetState.half);
      expect(h.controller.progress, 0.0);
      expect(h.states, isEmpty);
    });

    testWidgets('keeps the half look on the way out', (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester.pumpWidget(h.app(h.sheet(child: h.content())));
      await tester.pumpAndSettle();

      h.controller.snapToState(GlassSheetState.hidden);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final fill = tester.getRect(find.byKey(_fill));
        expect(fill.left, closeTo(_margin, 0.01));
        expect(fill.right, closeTo(_screen.width - _margin, 0.01));
        expect(_fillColor(tester).a, 0.0);
        expect(h.controller.progress, 0.0);
      }
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(0, 0.01));
    });

    for (final shown in [false, true]) {
      final how = shown ? 'through show()' : 'embedded';
      for (final initial in GlassSheetState.values) {
        testWidgets('initialState $initial opens $how', (tester) async {
          _phone(tester);
          final controller = GlassModalSheetController();
          final states = <GlassSheetState>[];
          Widget content(BuildContext _) => const SizedBox(height: 200);
          if (shown) {
            const home = Key('home');
            await tester.pumpWidget(
                const MaterialApp(home: SizedBox.expand(key: home)));
            GlassModalSheet.show<void>(
              context: tester.element(find.byKey(home)),
              controller: controller,
              detents: _fitted,
              initialState: initial,
              onStateChanged: states.add,
              builder: content,
            );
          } else {
            await tester.pumpWidget(MaterialApp(
              home: Stack(children: [
                GlassModalSheet(
                  controller: controller,
                  detents: _fitted,
                  initialState: initial,
                  onStateChanged: states.add,
                  child: Builder(builder: content),
                ),
              ]),
            ));
          }
          await tester.pumpAndSettle();

          if (initial == GlassSheetState.hidden) {
            // Stays hidden until the controller shows it.
            expect(controller.currentState, GlassSheetState.hidden);
            expect(_visibleHeight(tester), closeTo(0, 0.01));
            expect(states, isEmpty);
            controller.snapToState(GlassSheetState.full);
            await tester.pumpAndSettle();
            expect(states, [GlassSheetState.half]);
          } else {
            expect(states, isEmpty);
          }
          expect(controller.currentState, GlassSheetState.half);
          expect(_visibleHeight(tester), closeTo(_fittedHeight(200), 0.01));
          _expectHalfLook(tester);
        });
      }
    }

    testWidgets('shrinking between handle moves preserves a short drag',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      final height = ValueNotifier(600.0);
      addTearDown(height.dispose);
      await tester.pumpWidget(h.app(h.sheet(
          child: ValueListenableBuilder<double>(
        valueListenable: height,
        builder: (context, value, child) => SizedBox(height: value),
      ))));
      await tester.pumpAndSettle();
      final handle =
          tester.getTopLeft(find.byKey(_fill)) + const Offset(100, 20);
      final pointer = await tester.startGesture(handle);
      await pointer.moveBy(const Offset(0, 5));
      await tester.pump(const Duration(milliseconds: 100));
      height.value = 200;
      await tester.pump();
      await pointer.moveBy(const Offset(0, 5));
      await tester.pump(const Duration(milliseconds: 200));
      await pointer.up();
      await tester.pumpAndSettle();
      expect(h.states, isEmpty);
      expect(_visibleHeight(tester), closeTo(_fittedHeight(200), 0.01));
    });

    testWidgets('the sheet moves while its child animates every frame',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      final height = ValueNotifier(200.0);
      addTearDown(height.dispose);
      await tester.pumpWidget(h.app(h.sheet(
          child: ValueListenableBuilder<double>(
        valueListenable: height,
        builder: (context, value, child) => SizedBox(height: value),
      ))));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 30; i++) {
        height.value = 200 + i * 10;
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(_visibleHeight(tester),
          inExclusiveRange(_fittedHeight(350), _fittedHeight(501)));
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(500), 0.01));
    });

    testWidgets('a handle tap during growth keeps the sheet open',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester
          .pumpWidget(h.app(h.sheet(child: const SizedBox(height: 120))));
      await tester.pumpAndSettle();
      await tester
          .pumpWidget(h.app(h.sheet(child: const SizedBox(height: 600))));
      await tester.pump(const Duration(milliseconds: 16));
      await tester
          .tapAt(tester.getTopLeft(find.byKey(_fill)) + const Offset(100, 20));
      await tester.pumpAndSettle();
      expect(h.states, isEmpty);
      expect(_visibleHeight(tester), closeTo(_fittedHeight(600), 0.01));
    });

    testWidgets('a touch on a closing fitted sheet lets it finish dismissing',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester
          .pumpWidget(h.app(h.sheet(child: const SizedBox(height: 300))));
      await tester.pumpAndSettle();
      h.controller.snapToState(GlassSheetState.hidden);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester
          .tapAt(tester.getTopLeft(find.byKey(_fill)) + const Offset(100, 70));
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(0, 0.01));
      expect(h.states, [GlassSheetState.hidden]);
    });

    testWidgets('a body touch holds the sheet before the first drag move',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester.pumpWidget(h.app(
          h.sheet(pressFeedback: false, child: const SizedBox(height: 200))));
      await tester.pumpAndSettle();
      final touch = await tester.startGesture(
          tester.getTopLeft(find.byKey(_fill)) + const Offset(100, 100));
      await tester.pumpWidget(h.app(
          h.sheet(pressFeedback: false, child: const SizedBox(height: 600))));
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(200), 0.01));
      await touch.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(180), 0.01));
      await touch.up();
      await tester.pumpAndSettle();
      expect(h.states, isEmpty);
      expect(_visibleHeight(tester), closeTo(_fittedHeight(600), 0.01));
    });

    testWidgets('switching from the default detents stays at half',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      const child = SizedBox(height: 180);
      await tester.pumpWidget(
          h.app(GlassModalSheet(controller: h.controller, child: child)));
      await tester.pumpAndSettle();
      expect(h.controller.currentState, GlassSheetState.half);
      await tester.pumpWidget(h.app(h.sheet(child: child)));
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(180), 0.01));
      expect(h.controller.currentState, GlassSheetState.half);
      expect(h.states, isEmpty);
    });

    testWidgets('switching sizing preserves editable text and focus',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      const field = Material(
          child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: TextField(),
      ));
      await tester.pumpWidget(h.app(h.sheet(child: field, fit: false)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep this draft');
      final editable =
          tester.state<EditableTextState>(find.byType(EditableText));
      for (final fitted in [true, false]) {
        await tester.pumpWidget(h.app(h.sheet(child: field, fit: fitted)));
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(EditableText)), same(editable));
        expect(editable.widget.focusNode.hasFocus, isTrue);
        expect(editable.widget.controller.text, 'Keep this draft');
      }
    });

    testWidgets('morphs to fitted content and closes from its resized frame',
        (tester) async {
      _phone(tester);
      GlassModalSheet.debugMorphSupportsBlending = true;
      addTearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);
      final height = ValueNotifier(200.0);
      addTearDown(height.dispose);
      const homeKey = Key('home');
      await tester
          .pumpWidget(const MaterialApp(home: SizedBox.expand(key: homeKey)));
      final context = tester.element(find.byKey(homeKey));
      GlassModalSheet.show<void>(
        context: context,
        detents: _fitted,
        morphFromRect: const Rect.fromLTWH(175, 600, 40, 40),
        builder: (_) => ValueListenableBuilder<double>(
            valueListenable: height,
            builder: (context, value, child) => SizedBox(height: value)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // The sheet fills the morph's portal. A destination calculated from
      // automatic sizing would place the short sheet below the blob's top.
      expect(_morphPortal(tester).height, greaterThan(1));
      expect(tester.getRect(find.byKey(_fill, skipOffstage: false)).top,
          closeTo(_morphPortal(tester).top, 1));
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(200), 0.01));
      height.value = 360;
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(360), 0.01));
      // Interrupt a second resize. The first closing frame must match the
      // live sheet, even though its new resting height is already known.
      height.value = 480;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 65));
      final resting = tester.getRect(find.byKey(_fill));
      expect(_screen.height - resting.top,
          inExclusiveRange(_fittedHeight(360), _fittedHeight(480)));
      Navigator.of(context).pop();
      await tester.pump();
      expect(_morphPortal(tester).top, closeTo(resting.top, 1));
      expect(_morphPortal(tester).height, closeTo(resting.height, 1));
      height.value = 700;
      for (var frame = 0; frame < 7; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final sheet = tester.getRect(find.byKey(_fill, skipOffstage: false));
        final portal = _morphPortal(tester);
        expect(sheet.top, closeTo(portal.top, 1));
        expect(sheet.height, closeTo(portal.height, 1));
      }
      await tester.pumpAndSettle();
    });

    testWidgets(
        'content that grows during the opening morph keeps the droplet on '
        'the sheet, then resizes it', (tester) async {
      _phone(tester);
      GlassModalSheet.debugMorphSupportsBlending = true;
      addTearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);
      final height = ValueNotifier(200.0);
      addTearDown(height.dispose);
      const homeKey = Key('home');
      await tester
          .pumpWidget(const MaterialApp(home: SizedBox.expand(key: homeKey)));
      GlassModalSheet.show<void>(
        context: tester.element(find.byKey(homeKey)),
        detents: _fitted,
        morphFromRect: const Rect.fromLTWH(175, 300, 40, 40),
        builder: (_) => ValueListenableBuilder<double>(
            valueListenable: height,
            builder: (context, value, child) => SizedBox(height: value)),
      );
      await tester.pump();
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      height.value = 550;
      // The droplet draws the sheet's glass until the handoff. It must keep
      // to the sheet, or the glass jumps when the sheet takes over.
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final sheet = tester.getRect(find.byKey(_fill, skipOffstage: false));
        final portal = _morphPortal(tester);
        expect(sheet.top, closeTo(portal.top, 1));
        expect(sheet.height, closeTo(portal.height, 1));
      }
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(550), 0.01));
    });

    testWidgets('a dismissing swipe morphs from the frame the finger held',
        (tester) async {
      _phone(tester);
      GlassModalSheet.debugMorphSupportsBlending = true;
      addTearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);
      final height = ValueNotifier(200.0);
      addTearDown(height.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
          MaterialApp(navigatorKey: navigator, home: const SizedBox()));
      GlassModalSheet.show<void>(
        context: navigator.currentContext!,
        detents: _fitted,
        // Without the sheet's press feedback, so the held frame is the
        // sheet's own.
        interactionScale: 1.0,
        stretch: 0.0,
        morphFromRect: const Rect.fromLTWH(175, 600, 40, 40),
        builder: (_) => ValueListenableBuilder<double>(
          valueListenable: height,
          builder: (context, value, child) => SizedBox(height: value),
        ),
      );
      await tester.pumpAndSettle();
      final finger = await tester.startGesture(
          tester.getTopLeft(find.byKey(_fill)) + const Offset(100, 20));
      await finger.moveBy(const Offset(0, 120));
      height.value = 500;
      await tester.pumpAndSettle();
      final released = tester.getRect(find.byKey(_fill));
      await finger.up();
      await tester.pump();
      final portal = _morphPortal(tester);
      expect(portal.top, closeTo(released.top, 1));
      expect(portal.height, closeTo(released.height, 1));
      await tester.pumpAndSettle();
      expect(navigator.currentState!.canPop(), isFalse);
    });

    testWidgets('reports the fitted sheet truthfully', (tester) async {
      _phone(tester);
      final h = _Harness();
      SheetStateInfo? info;
      await tester.pumpWidget(h.app(h.sheet(
        child: Builder(builder: (context) {
          info = GlassModalSheetStateProvider.of(context);
          return h.content();
        }),
      )));
      await tester.pumpAndSettle();

      expect(info!.state, GlassSheetState.half);
      expect(info!.progress, 0.0);
      expect(info!.isExpanded, isFalse);
      expect(h.controller.progress, 0.0);
      h.controller.snapToState(GlassSheetState.hidden);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // The sheet is sliding below the screen's edge. Content that padded by
      // that distance would change the height the sheet measures.
      expect(_frame(tester).bottom, greaterThan(_screen.height));
      expect(info!.submergedBottom, 0.0);
      expect(info!.progress, 0.0);
      await tester.pumpAndSettle();
      expect(info!.state, GlassSheetState.hidden);
      expect(info!.isExpanded, isFalse);
      expect(info!.submergedBottom, 0.0);
    });

    for (final (fullSize, limit) in [
      (null, _limit),
      (0.6, 0.6 * 844.0),
      (500.0, 500.0),
    ]) {
      testWidgets(
          'never grows taller than fullSize $fullSize; taller content scrolls',
          (tester) async {
        _phone(tester);
        final h = _Harness();
        await tester.pumpWidget(
            h.app(h.sheet(fullSize: fullSize, child: h.content(body: 2000))));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_visibleHeight(tester), closeTo(limit, 0.01));
        _expectHalfLook(tester);
        expect(tester.getRect(find.byKey(_header)).top,
            closeTo(_screen.height - limit, 0.01));
        expect(tester.getRect(find.byKey(_actions)).bottom,
            closeTo(_screen.height - _margin - _safeBottom, 0.01));

        final header = tester.getRect(find.byKey(_header));
        final actions = tester.getRect(find.byKey(_actions));
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();

        final scrollable =
            tester.state<ScrollableState>(find.byType(Scrollable));
        expect(scrollable.position.pixels, greaterThan(0));
        expect(h.controller.currentState, GlassSheetState.half);
        expect(tester.getRect(find.byKey(_header)), header);
        expect(tester.getRect(find.byKey(_actions)), actions);
      });
    }

    testWidgets('a medium sheet keeps its halfSize height', (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester.pumpWidget(h.app(h.sheet(child: h.content(), fit: false)));
      await tester.pumpAndSettle();

      expect(_visibleHeight(tester), closeTo(_halfHeight, 0.01));
    });

    testWidgets('content that fills its space rests at the limit',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester.pumpWidget(h.app(h.sheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Builder(
                builder: (context) => ListView(
                  controller: ScrollControllerProvider.of(context)!.controller,
                  children: const [SizedBox(height: 40)],
                ),
              ),
            ),
          ],
        ),
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_visibleHeight(tester), closeTo(_limit, 0.01));
    });

    for (final (minHeight, expected) in [
      (400.0, _fittedHeight(400)),
      (900.0, _limit),
    ]) {
      testWidgets('a ConstrainedBox sets a ${minHeight}pt minimum height',
          (tester) async {
        _phone(tester);
        final h = _Harness();
        await tester.pumpWidget(h.app(h.sheet(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: const SizedBox(height: 100),
          ),
        )));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_visibleHeight(tester), closeTo(expected, 0.01));
        _expectHalfLook(tester);
      });
    }

    testWidgets('is at its fitted height from the first frame it shows',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        home: const SizedBox.expand(),
      ));

      GlassModalSheet.show<void>(
        context: navigator.currentContext!,
        detents: _fitted,
        builder: (_) => h.content(),
      );

      final frames = <Rect>[];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.byKey(_fill).evaluate().isNotEmpty) {
          frames.add(tester.getRect(find.byKey(_fill)));
        }
      }
      await tester.pumpAndSettle();
      final settled = tester.getRect(find.byKey(_fill));
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(200)), 0.01));

      final shown = frames.where((r) => r.top < _screen.height - 0.5);
      expect(shown, isNotEmpty);
      for (final frame in shown) {
        expect(frame.height, closeTo(settled.height, 0.01));
      }
    });

    for (final fit in [true, false]) {
      testWidgets(
          'an embedded ${fit ? 'fitted' : 'medium'} sheet has no negative '
          'height on its first frame', (tester) async {
        _phone(tester);
        final h = _Harness();
        await tester.pumpWidget(
            h.app(h.sheet(fit: fit, child: const SizedBox(height: 200))));

        // The frame's Positioned has the sheet's height; the ones inside it
        // fill it.
        final heights = tester
            .widgetList<Positioned>(find.ancestor(
                of: find.byKey(_fill), matching: find.byType(Positioned)))
            .map((positioned) => positioned.height)
            .whereType<double>();
        expect(heights, isNotEmpty);
        for (final height in heights) {
          expect(height, greaterThanOrEqualTo(0));
        }
        await tester.pumpAndSettle();
        if (fit) {
          expect(_visibleHeight(tester), closeTo(_fittedHeight(200), 0.01));
        }
      });
    }

    testWidgets('header follows growth, shrink and over-drag', (tester) async {
      _phone(tester);
      final h = _Harness();
      final height = ValueNotifier(200.0);
      addTearDown(height.dispose);
      const cap = 500.0;
      await tester.pumpWidget(h.app(GlassModalSheet(
        controller: h.controller,
        detents: _fitted,
        fullSize: cap,
        child: ValueListenableBuilder<double>(
          valueListenable: height,
          builder: (_, value, __) => SizedBox(key: _header, height: value),
        ),
      )));
      await tester.pumpAndSettle();
      Rect frame() => tester.getRect(find.byKey(_fill));
      void expectAttached() => expect(
          tester.getTopLeft(find.byKey(_header)).dy, closeTo(frame().top, 0.1));
      expect(frame().left, closeTo(_margin, 0.01));
      expect(h.controller.progress, 0.0);
      expect(_fillColor(tester).a, 0.0);
      for (final target in [600.0, 200.0]) {
        height.value = target;
        for (var i = 0; i < 35; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expectAttached();
          expect(frame().bottom, closeTo(_screen.height - _margin, 0.1));
        }
        await tester.pumpAndSettle();
        expect(_visibleHeight(tester),
            closeTo(math.min(_fittedHeight(target), cap), 0.01));
      }
      final restingTop = frame().top;
      final gesture = await tester.startGesture(Offset(195, restingTop + 15));
      await gesture.moveBy(const Offset(0, -300));
      await tester.pump();
      expect(frame().top, lessThan(restingTop));
      expectAttached();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(frame().top, closeTo(restingTop, 0.01));
      expect(h.controller.currentState, GlassSheetState.half);
    });

    testWidgets('content that changes during a drag settles at the new height',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      final body = ValueNotifier<double>(200);
      addTearDown(body.dispose);
      await tester.pumpWidget(h.app(h.sheet(
        child: ValueListenableBuilder<double>(
          valueListenable: body,
          builder: (context, value, _) => h.content(body: value),
        ),
      )));
      await tester.pumpAndSettle();

      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(_body)));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump(const Duration(milliseconds: 50));
      }
      body.value = 450;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(h.controller.currentState, GlassSheetState.half);
      expect(h.states, isNot(contains(GlassSheetState.hidden)));
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(450)), 0.01));
    });

    testWidgets('content that changes during a scroll settles on release',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      final body = ValueNotifier<double>(2000);
      addTearDown(body.dispose);
      await tester.pumpWidget(h.app(h.sheet(
        child: ValueListenableBuilder<double>(
          valueListenable: body,
          builder: (context, value, _) => h.content(body: value),
        ),
      )));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_header)) + const Offset(0, 200));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 50));
      }
      body.value = 200;
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(h.controller.currentState, GlassSheetState.half);
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(200)), 0.01));
    });

    testWidgets(
        'a vetoed dismissal returns to the fitted height and takes taps',
        (tester) async {
      _phone(tester);
      final h = _Harness()..veto = true;
      await tester.pumpWidget(h.app(h.sheet(child: h.content())));
      await tester.pumpAndSettle();

      await tester.flingFrom(
          tester.getCenter(find.byKey(_body)), const Offset(0, 300), 2000);
      await tester.pumpAndSettle();

      expect(h.states.where((s) => s == GlassSheetState.hidden), hasLength(1));
      expect(h.controller.currentState, GlassSheetState.half);
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(200)), 0.01));

      await tester.tap(find.byKey(_actions));
      expect(h.actionTaps, 1);
      expect(h.barrierTaps, 0);
    });

    testWidgets(
        'cannot be swiped away with dismissible false, and follows '
        'its content', (tester) async {
      _phone(tester);
      final h = _Harness();
      final height = ValueNotifier(300.0);
      addTearDown(height.dispose);
      await tester.pumpWidget(h.app(h.sheet(
        dismissible: false,
        child: ValueListenableBuilder<double>(
          valueListenable: height,
          builder: (context, value, child) => SizedBox(height: value),
        ),
      )));
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(300), 0.01));
      _expectHalfLook(tester);

      await tester.flingFrom(_frame(tester).topCenter + const Offset(0, 20),
          const Offset(0, 300), 2000);
      await tester.pumpAndSettle();
      expect(h.states, isEmpty);
      expect(h.controller.currentState, GlassSheetState.half);
      expect(_visibleHeight(tester), closeTo(_fittedHeight(300), 0.01));

      height.value = 400;
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(400), 0.01));
    });

    testWidgets('taps above and beside the sheet reach what is behind it',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester.pumpWidget(h.app(h.sheet(child: h.content())));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.tapAt(
          Offset(5, _screen.height - _fittedHeight(_contentHeight(200)) - 5));
      // In the side margin, level with the sheet.
      await tester.tapAt(Offset(_margin / 2, _screen.height - 100));
      expect(h.barrierTaps, 3);
    });

    testWidgets(
        'grows with the keyboard up to the limit, keeps the actions above it, '
        'and returns when it closes', (tester) async {
      _phone(tester);
      final h = _Harness();
      final body = ValueNotifier<double>(200);
      addTearDown(body.dispose);
      await tester.pumpWidget(h.app(h.sheet(
        child: ValueListenableBuilder<double>(
          valueListenable: body,
          builder: (context, value, _) => h.content(body: value),
        ),
      )));
      await tester.pumpAndSettle();

      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * _dpr);
      await tester.pumpAndSettle();
      const grown = _headerHeight + 200 + _actionsHeight + keyboard;
      expect(_visibleHeight(tester), closeTo(_fittedHeight(grown), 0.01));
      // The keyboard pushes the sheet above halfSize, and it keeps the half
      // look.
      expect(_visibleHeight(tester), greaterThan(_halfHeight));
      _expectHalfLook(tester);
      expect(tester.getRect(find.byKey(_actions)).bottom,
          lessThanOrEqualTo(_screen.height - keyboard + 0.01));

      // Taller content: the sheet stops at the limit and the scroll view
      // gives way, keeping the actions above the keyboard.
      body.value = 500;
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_limit, 0.01));
      expect(tester.getRect(find.byKey(_actions)).bottom,
          lessThanOrEqualTo(_screen.height - keyboard + 0.01));
      expect(tester.getRect(find.byKey(_header)).top,
          closeTo(_screen.height - _limit, 0.01));

      body.value = 200;
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(200)), 0.01));
      expect(h.controller.currentState, GlassSheetState.half);
      expect(h.states, isNot(contains(GlassSheetState.hidden)));
    });

    testWidgets('content that ignores the keyboard does not move',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester
          .pumpWidget(h.app(h.sheet(child: h.content(padsForKeyboard: false))));
      await tester.pumpAndSettle();
      final actions = tester.getRect(find.byKey(_actions));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * _dpr);
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(_actions)), actions);
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(200)), 0.01));
    });

    for (final (portrait, landscape, expected) in [
      (200.0, 80.0, _fittedHeight(_contentHeight(80))),
      (120.0, 120.0, _fittedHeight(_contentHeight(120))),
      (2000.0, 2000.0, _screen.width - 90),
    ]) {
      testWidgets('rotation remeasures a ${portrait}pt body', (tester) async {
        _phone(tester);
        final h = _Harness();
        await tester.pumpWidget(h.app(h.sheet(
            child: h.content(
                bodyHeight: (width) => width < 600 ? portrait : landscape))));
        await tester.pumpAndSettle();
        final original =
            math.min(_limit, _fittedHeight(_contentHeight(portrait)));
        expect(_visibleHeight(tester), closeTo(original, 0.01));
        tester.view.physicalSize = _screen.flipped * _dpr;
        await tester.pumpAndSettle();
        expect(_visibleHeight(tester), closeTo(expected, 0.01));
        tester.view.physicalSize = _screen * _dpr;
        await tester.pumpAndSettle();
        expect(_visibleHeight(tester), closeTo(original, 0.01));
        expect(h.controller.currentState, GlassSheetState.half);
      });
    }

    for (final height in [0.0, 24.0]) {
      testWidgets('${height}pt content mounts and flicks closed',
          (tester) async {
        _phone(tester);
        final h = _Harness();
        await tester
            .pumpWidget(h.app(h.sheet(child: SizedBox(height: height))));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Never shorter than the drag handle's touch zone.
        expect(_visibleHeight(tester),
            closeTo(_fittedHeight(math.max(height, 44)), 0.01));

        await tester.flingFrom(
          Offset(_screen.width / 2, _screen.height - 20),
          const Offset(0, 200),
          2000,
        );
        await tester.pumpAndSettle();
        expect(h.states, [GlassSheetState.hidden]);
      });
    }

    testWidgets('without the drag handle, fits even tiny content',
        (tester) async {
      _phone(tester);
      final h = _Harness();
      await tester.pumpWidget(h.app(h.sheet(
        showDragIndicator: false,
        child: const SizedBox(height: 1),
      )));
      await tester.pumpAndSettle();

      expect(_visibleHeight(tester), closeTo(_fittedHeight(1), 0.01));
      h.controller.snapToState(GlassSheetState.hidden);
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(0, 0.01));
    });

    testWidgets('survives being built on a zero-size view', (tester) async {
      tester.view.physicalSize = Size.zero;
      tester.view.devicePixelRatio = _dpr;
      addTearDown(tester.view.reset);
      final h = _Harness();
      await tester.pumpWidget(h.app(h.sheet(
        showDragIndicator: false,
        child: const SizedBox(height: 0),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);

      _phone(tester);
      await tester.pumpWidget(h.app(h.sheet(child: h.content())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_visibleHeight(tester),
          closeTo(_fittedHeight(_contentHeight(200)), 0.01));
    });

    for (final morph in [false, true]) {
      final how = morph ? 'morphed' : 'embedded';

      testWidgets(
          'a $how sheet slides back from a short drag without a jump, then '
          'follows its content', (tester) async {
        final height = ValueNotifier(350.0);
        addTearDown(height.dispose);
        await _present(tester, height: height, morph: morph);
        final rest = _frame(tester);

        final gesture = await _dragDownAndHold(tester);
        var previous = _frame(tester);
        expect(previous.top, greaterThan(rest.top + 20));
        await gesture.up();
        await tester.pump();
        // The frame the finger held is the frame that springs back: its
        // bottom edge and its height carry on from where they were.
        for (var i = 0; i < 6; i++) {
          final frame = _frame(tester);
          expect(frame.bottom, closeTo(previous.bottom, 4));
          expect(frame.height, closeTo(previous.height, 4));
          previous = frame;
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();
        expect(_frame(tester), rectMoreOrLessEquals(rest, epsilon: 0.01));

        height.value = 300;
        await tester.pumpAndSettle();
        expect(_frame(tester).top, closeTo(rest.top + 50, 0.01));
      });

      testWidgets(
          'a $how sheet takes a content change made during its slide back '
          'when the slide ends', (tester) async {
        final height = ValueNotifier(350.0);
        addTearDown(height.dispose);
        await _present(tester, height: height, morph: morph);
        final rest = _frame(tester);

        final gesture = await _dragDownAndHold(tester);
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        var previous = _frame(tester);
        height.value = 450;
        var resized = false;
        for (var i = 0; i < 120; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          final frame = _frame(tester);
          // Never a jump, in the slide or in the resize after it.
          expect(frame.height, closeTo(previous.height, 12));
          if (frame.height > rest.height + 6) {
            // The resize runs at rest: no swipe transform is left on it.
            resized = true;
            expect(frame.width, closeTo(rest.width, 0.5));
            expect(frame.bottom, closeTo(rest.bottom, 0.5));
          }
          previous = frame;
        }
        await tester.pumpAndSettle();
        expect(resized, isTrue);
        expect(_frame(tester).top, closeTo(rest.top - 100, 0.01));
        expect(_frame(tester).bottom, closeTo(rest.bottom, 0.01));
      });
    }

    // The handle takes the touch as a drag at once; the body takes it as a
    // tap. Both must carry the interrupted slide on.
    for (final (where, offset) in [('handle', 20.0), ('body', 120.0)]) {
      testWidgets(
          'a sheet grabbed by its $where during its slide back keeps its '
          'frame, and letting go lets it finish', (tester) async {
        final height = ValueNotifier(350.0);
        addTearDown(height.dispose);
        await _present(tester, height: height);
        final rest = _frame(tester);

        final gesture = await _dragDownAndHold(tester);
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 32));
        final sliding = _frame(tester);
        expect(sliding.top, greaterThan(rest.top + 10));

        final grab =
            await tester.startGesture(sliding.topCenter + Offset(0, offset));
        await tester.pump();
        expect(_frame(tester).bottom, closeTo(sliding.bottom, 2));
        expect(_frame(tester).height, closeTo(sliding.height, 2));
        await grab.up();
        await tester.pumpAndSettle();
        expect(_frame(tester), rectMoreOrLessEquals(rest, epsilon: 0.01));

        height.value = 300;
        await tester.pumpAndSettle();
        expect(_frame(tester).height, closeTo(300, 0.01));
      });
    }

    testWidgets('a cancelled drag slides back, then follows its content',
        (tester) async {
      final height = ValueNotifier(350.0);
      addTearDown(height.dispose);
      await _present(tester, height: height);
      final rest = _frame(tester);

      final gesture = await _dragDownAndHold(tester);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(_frame(tester), rectMoreOrLessEquals(rest, epsilon: 0.01));

      height.value = 300;
      await tester.pumpAndSettle();
      expect(_frame(tester).height, closeTo(300, 0.01));
    });

    testWidgets(
        'a slide stopped by the controller still follows the next content '
        'change', (tester) async {
      final height = ValueNotifier(350.0);
      addTearDown(height.dispose);
      final controller = GlassModalSheetController();
      await _present(tester, height: height, controller: controller);
      final rest = _frame(tester);

      final gesture = await _dragDownAndHold(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      controller.value = controller.value;
      await tester.pumpAndSettle();
      expect(_frame(tester).top, greaterThan(rest.top + 10));

      height.value = 300;
      await tester.pumpAndSettle();
      expect(_frame(tester).height, closeTo(300, 0.01));
      expect(_frame(tester).bottom, closeTo(rest.bottom, 0.01));
    });

    testWidgets(
        'a sheet opened from hidden slides in at its fitted height, then '
        'follows its content', (tester) async {
      final height = ValueNotifier(350.0);
      addTearDown(height.dispose);
      final controller = GlassModalSheetController();
      await _present(
        tester,
        height: height,
        controller: controller,
        initialState: GlassSheetState.hidden,
      );

      controller.snapToState(GlassSheetState.half);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final sliding = _frame(tester);
      // A whole frame on its way up: its bottom edge is still below the
      // screen, where a sheet growing from the bottom edge would rest it.
      expect(sliding.height, closeTo(350, 0.01));
      expect(sliding.bottom, greaterThan(_screen.height + 50));
      await tester.pumpAndSettle();
      expect(_frame(tester).height, closeTo(350, 0.01));
      expect(_frame(tester).bottom, lessThan(_screen.height));

      height.value = 300;
      await tester.pumpAndSettle();
      expect(_frame(tester).height, closeTo(300, 0.01));
    });

    testWidgets(
        'an instant snap during a slide out takes the content height that '
        'changed meanwhile', (tester) async {
      final height = ValueNotifier(200.0);
      addTearDown(height.dispose);
      final controller = GlassModalSheetController();
      await _present(tester, height: height, controller: controller);

      controller.snapToState(GlassSheetState.hidden);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      height.value = 350;
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      controller.snapToState(GlassSheetState.half, animate: false);
      await tester.pumpAndSettle();
      expect(controller.currentState, GlassSheetState.half);
      expect(_frame(tester).height, closeTo(350, 0.01));
    });

    for (final value in [0.3, 0.2]) {
      testWidgets(
          'controller.value = $value slides the whole resting sheet, which a '
          'drag brings back', (tester) async {
        final height = ValueNotifier(350.0);
        addTearDown(height.dispose);
        final controller = GlassModalSheetController();
        await _present(tester, height: height, controller: controller);
        final rest = _frame(tester);

        controller.value = value;
        await tester.pumpAndSettle();
        expect(_frame(tester).height, closeTo(rest.height, 0.01));
        expect(_frame(tester).top, closeTo(_screen.height * (1 - value), 0.01));

        final gesture = await tester
            .startGesture(_frame(tester).topCenter + const Offset(0, 20));
        for (var i = 0; i < 5; i++) {
          await gesture.moveBy(const Offset(0, -20));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expect(controller.currentState, GlassSheetState.half);
        expect(_frame(tester), rectMoreOrLessEquals(rest, epsilon: 0.01));

        height.value = 300;
        await tester.pumpAndSettle();
        expect(_frame(tester).height, closeTo(300, 0.01));
      });
    }

    testWidgets('controller.value from hidden slides in the whole sheet',
        (tester) async {
      final height = ValueNotifier(350.0);
      addTearDown(height.dispose);
      final controller = GlassModalSheetController();
      await _present(
        tester,
        height: height,
        controller: controller,
        initialState: GlassSheetState.hidden,
      );

      for (final value in [0.1, 0.2, 0.3]) {
        controller.value = value;
        await tester.pump();
        expect(_frame(tester).height, closeTo(350, 0.01));
        expect(_frame(tester).top, closeTo(_screen.height * (1 - value), 0.01));
      }
    });

    testWidgets('follows its content after a vetoed dismissal', (tester) async {
      _phone(tester);
      final h = _Harness()..veto = true;
      final height = ValueNotifier(350.0);
      addTearDown(height.dispose);
      await tester.pumpWidget(h.app(h.sheet(
        child: ValueListenableBuilder<double>(
          valueListenable: height,
          builder: (context, value, child) => SizedBox(height: value),
        ),
      )));
      await tester.pumpAndSettle();

      await tester.flingFrom(_frame(tester).topCenter + const Offset(0, 20),
          const Offset(0, 300), 2000);
      await tester.pumpAndSettle();
      expect(h.states, contains(GlassSheetState.hidden));
      expect(h.controller.currentState, GlassSheetState.half);
      expect(_visibleHeight(tester), closeTo(_fittedHeight(350), 0.01));

      height.value = 300;
      await tester.pumpAndSettle();
      expect(_visibleHeight(tester), closeTo(_fittedHeight(300), 0.01));
    });

    testWidgets('the controller keeps a fitted sheet on its one stop',
        (tester) async {
      final height = ValueNotifier(350.0);
      addTearDown(height.dispose);
      final controller = GlassModalSheetController();
      final states = <GlassSheetState>[];
      await _present(
        tester,
        height: height,
        controller: controller,
        onStateChanged: states.add,
      );
      final rest = _frame(tester);

      for (final asked in [GlassSheetState.full, GlassSheetState.peek]) {
        controller.snapToState(asked);
        await tester.pumpAndSettle();
        expect(controller.currentState, GlassSheetState.half);
        expect(_frame(tester), rectMoreOrLessEquals(rest, epsilon: 0.01));
      }
      expect(states, isEmpty);
    });

    testWidgets('show rejects fitted with other detents or in persistent mode',
        (tester) async {
      const home = Key('home');
      await tester.pumpWidget(const MaterialApp(home: SizedBox(key: home)));
      final context = tester.element(find.byKey(home));
      for (final (mode, detents) in _invalidFittedConfigurations) {
        expect(
            () => GlassModalSheet.show<void>(
                  context: context,
                  mode: mode,
                  detents: detents,
                  builder: (_) => const SizedBox(),
                ),
            throwsA(isAssertionError.having((error) => error.message, 'message',
                contains('must be the only detent'))));
        expect(Navigator.of(context).canPop(), isFalse);
      }
    });

    for (final (mode, detents) in _invalidFittedConfigurations) {
      testWidgets('an embedded sheet rejects $detents in $mode',
          (tester) async {
        _phone(tester);
        await tester.pumpWidget(MaterialApp(
          home: Stack(
            children: [
              GlassModalSheet(
                mode: mode,
                detents: detents,
                child: const SizedBox(height: 100),
              ),
            ],
          ),
        ));
        expect(
            tester.takeException(),
            isAssertionError.having((error) => error.message, 'message',
                contains('must be the only detent')));

        // The rejected sheet leaves no observer behind for a later change of
        // the view to reach.
        tester.view.physicalSize = _screen.flipped * _dpr;
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
