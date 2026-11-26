import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _screen = Size(390, 844);
const _dpr = 3.0;
const _fill = Key('glass_modal_sheet_fill');
const _fitted = {GlassSheetDetent.fitted};
const _twoStop = {GlassSheetDetent.medium, GlassSheetDetent.large};

// The sheet's default fill colours.
const _defaultLight = Color(0xFFF2F2F7);
const _defaultDark = Color(0xFF1C1C1E);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = _screen * _dpr;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
}

Color _fillColor(WidgetTester tester) {
  final box =
      tester.widget<DecoratedBox>(find.byKey(_fill, skipOffstage: false));
  return (box.decoration as BoxDecoration).color!;
}

Rect _frame(WidgetTester tester) => tester.getRect(find.byKey(_fill));

/// [sheet] over an empty page, themed with [brightness] and [theme].
Widget _app(
  Widget sheet, {
  Brightness brightness = Brightness.light,
  GlassThemeData? theme,
}) =>
    MaterialApp(
      home: GlassTheme(
        data: theme ?? GlassThemeData(brightness: brightness),
        child: Stack(children: [sheet]),
      ),
    );

/// Content of a fixed height, so a fitted sheet has something to fit.
Widget _content([double height = 240]) => SizedBox(height: height);

/// Counts how often its State is created and disposed.
class _Probe extends StatefulWidget {
  const _Probe({required this.onInit, required this.onDispose});

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  group('glass (default)', () {
    testWidgets('is glass at medium and opaque at large', (tester) async {
      _phone(tester);
      final controller = GlassModalSheetController();
      await tester.pumpWidget(_app(GlassModalSheet(
        controller: controller,
        detents: _twoStop,
        child: _content(),
      )));
      await tester.pumpAndSettle();
      expect(_fillColor(tester).a, 0.0);

      controller.snapToState(GlassSheetState.full);
      await tester.pumpAndSettle();
      expect(_fillColor(tester), _defaultLight);
    });
  });

  group('solid fitted sheet', () {
    testWidgets('is opaque in the default colour for each brightness',
        (tester) async {
      _phone(tester);
      Widget sheet(Brightness brightness) => _app(
            GlassModalSheet(
              detents: _fitted,
              surfaceStyle: GlassSurfaceStyle.solid,
              child: _content(),
            ),
            brightness: brightness,
          );

      await tester.pumpWidget(sheet(Brightness.light));
      await tester.pumpAndSettle();
      expect(_fillColor(tester), _defaultLight);

      // An open sheet follows a light/dark switch and stays opaque.
      await tester.pumpWidget(sheet(Brightness.dark));
      await tester.pump();
      expect(_fillColor(tester), _defaultDark);
    });

    testWidgets('is white in the classic style', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        GlassModalSheet(
          detents: _fitted,
          surfaceStyle: GlassSurfaceStyle.solid,
          child: _content(),
        ),
        theme: const GlassThemeData.classic(brightness: Brightness.light),
      ));
      await tester.pumpAndSettle();
      expect(_fillColor(tester), Colors.white);
    });

    testWidgets('takes expandedColor and expandedDarkColor', (tester) async {
      _phone(tester);
      Widget sheet(Brightness brightness) => _app(
            GlassModalSheet(
              detents: _fitted,
              surfaceStyle: GlassSurfaceStyle.solid,
              expandedColor: const Color(0xFF123456),
              expandedDarkColor: const Color(0xFF654321),
              child: _content(),
            ),
            brightness: brightness,
          );

      await tester.pumpWidget(sheet(Brightness.light));
      await tester.pumpAndSettle();
      expect(_fillColor(tester), const Color(0xFF123456));

      await tester.pumpWidget(sheet(Brightness.dark));
      await tester.pump();
      expect(_fillColor(tester), const Color(0xFF654321));
    });

    testWidgets(
        'takes its colour from expandedColor, not from opaque halfSettings',
        (tester) async {
      _phone(tester);
      // Blur and frost 0 make a glass sheet use this colour as its fill.
      const opaqueHalf = LiquidGlassSettings(
        blur: 0,
        frost: 0,
        glassColor: Color(0xFFFF0000),
      );

      await tester.pumpWidget(_app(GlassModalSheet(
        detents: _fitted,
        halfSettings: opaqueHalf,
        child: _content(),
      )));
      await tester.pumpAndSettle();
      expect(_fillColor(tester), const Color(0xFFFF0000),
          reason: 'a glass sheet uses the halfSettings colour');

      await tester.pumpWidget(_app(GlassModalSheet(
        detents: _fitted,
        halfSettings: opaqueHalf,
        surfaceStyle: GlassSurfaceStyle.solid,
        child: _content(),
      )));
      await tester.pumpAndSettle();
      expect(_fillColor(tester), _defaultLight);
    });

    testWidgets('stays opaque while it slides away', (tester) async {
      _phone(tester);
      final controller = GlassModalSheetController();
      await tester.pumpWidget(_app(GlassModalSheet(
        controller: controller,
        detents: _fitted,
        surfaceStyle: GlassSurfaceStyle.solid,
        child: _content(),
      )));
      await tester.pumpAndSettle();

      controller.snapToState(GlassSheetState.hidden);
      var frames = 0;
      while (_frame(tester).top < _screen.height - 1) {
        expect(_fillColor(tester), _defaultLight);
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
        expect(frames, lessThan(200));
      }
      expect(frames, greaterThan(3));
    });

    testWidgets('stays opaque while it resizes to follow its content',
        (tester) async {
      _phone(tester);
      Widget sheet(double height) => _app(GlassModalSheet(
            detents: _fitted,
            surfaceStyle: GlassSurfaceStyle.solid,
            child: _content(height),
          ));
      await tester.pumpWidget(sheet(200));
      await tester.pumpAndSettle();
      final before = _frame(tester).top;

      await tester.pumpWidget(sheet(420));
      var sawBetween = false;
      for (var frames = 0; frames < 200; frames++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(_fillColor(tester), _defaultLight);
        final top = _frame(tester).top;
        if (top < before - 20 && top > before - 200) sawBetween = true;
        if (!tester.binding.hasScheduledFrame) break;
      }
      expect(sawBetween, isTrue, reason: 'the sheet moves to its new height');
      expect(_frame(tester).top, closeTo(before - 220, 0.5));
      expect(_fillColor(tester), _defaultLight);
    });

    testWidgets('switches its glass off, and no glass setting fades it',
        (tester) async {
      _phone(tester);
      // The glass fades its child, the fill included, with `visibility`.
      const faded = LiquidGlassSettings(visibility: 0.5);
      LiquidGlassSettings shell() => tester
          .widget<AdaptiveGlass>(find
              .ancestor(
                of: find.byKey(_fill),
                matching: find.byType(AdaptiveGlass),
              )
              .first)
          .settings;

      await tester.pumpWidget(_app(GlassModalSheet(
        detents: _fitted,
        halfSettings: faded,
        child: _content(),
      )));
      await tester.pumpAndSettle();
      expect(shell().visibility, 0.5, reason: 'a glass sheet fades with it');
      expect(shell().blur, greaterThan(0));

      for (final settings in [null, faded]) {
        await tester.pumpWidget(_app(GlassModalSheet(
          detents: _fitted,
          settings: settings,
          halfSettings: faded,
          surfaceStyle: GlassSurfaceStyle.solid,
          child: _content(),
        )));
        await tester.pumpAndSettle();
        expect(shell().visibility, 1.0);
        expect(shell().blur, 0.0);
        expect(shell().thickness, 0.0);
      }
    });

    testWidgets('keeps the drop shadow a glass sheet has', (tester) async {
      _phone(tester);
      List<BoxShadow> shadow() => tester
          .widget<AdaptiveGlass>(find
              .ancestor(
                of: find.byKey(_fill),
                matching: find.byType(AdaptiveGlass),
              )
              .first)
          .settings
          .effectiveShadow;

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_app(
          GlassModalSheet(detents: _fitted, child: _content()),
          brightness: brightness,
        ));
        await tester.pumpAndSettle();
        final glass = shadow();

        await tester.pumpWidget(_app(
          GlassModalSheet(
            detents: _fitted,
            surfaceStyle: GlassSurfaceStyle.solid,
            child: _content(),
          ),
          brightness: brightness,
        ));
        await tester.pumpAndSettle();
        expect(shadow(), glass, reason: '$brightness');
      }
      // The light theme is the one with a shadow to keep.
      expect(shadow(), isNotEmpty);
    });
  });

  group('solid two-stop sheet', () {
    testWidgets('keeps one opaque colour while dragged between detents',
        (tester) async {
      _phone(tester);
      final states = <GlassSheetState>[];
      await tester.pumpWidget(_app(GlassModalSheet(
        detents: _twoStop,
        surfaceStyle: GlassSurfaceStyle.solid,
        onStateChanged: states.add,
        child: _content(),
      )));
      await tester.pumpAndSettle();
      expect(_fillColor(tester), _defaultLight);

      Future<void> drag(double dy) async {
        final gesture = await tester
            .startGesture(_frame(tester).topCenter + const Offset(0, 20));
        for (var i = 0; i < 20; i++) {
          await gesture.moveBy(Offset(0, dy / 20));
          await tester.pump(const Duration(milliseconds: 16));
          expect(_fillColor(tester), _defaultLight);
        }
        await gesture.up();
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(_fillColor(tester), _defaultLight);
        }
        await tester.pumpAndSettle();
      }

      await drag(-400);
      expect(states.last, GlassSheetState.full);
      await drag(300);
      expect(states.last, GlassSheetState.half);
      expect(_fillColor(tester), _defaultLight);
    });

    testWidgets('stays opaque while it slides away', (tester) async {
      _phone(tester);
      final controller = GlassModalSheetController();
      await tester.pumpWidget(_app(GlassModalSheet(
        controller: controller,
        detents: _twoStop,
        surfaceStyle: GlassSurfaceStyle.solid,
        child: _content(),
      )));
      await tester.pumpAndSettle();

      controller.snapToState(GlassSheetState.hidden);
      var frames = 0;
      while (_frame(tester).top < _screen.height - 1) {
        expect(_fillColor(tester), _defaultLight);
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
        expect(frames, lessThan(200));
      }
      expect(frames, greaterThan(3));
    });
  });

  testWidgets('a persistent solid sheet is opaque at peek', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(GlassModalSheet(
      mode: GlassSheetMode.persistent,
      detents: const {
        GlassSheetDetent.small,
        GlassSheetDetent.medium,
        GlassSheetDetent.large,
      },
      initialState: GlassSheetState.peek,
      surfaceStyle: GlassSurfaceStyle.solid,
      child: _content(),
    )));
    await tester.pumpAndSettle();
    expect(_frame(tester).height, lessThan(200), reason: 'rests at peek');
    expect(_fillColor(tester), _defaultLight);
  });

  group('content', () {
    testWidgets('a solid sheet tells its content it is solid', (tester) async {
      _phone(tester);
      GlassSurfaceStyle? seen;
      Widget sheet(GlassSurfaceStyle style) => _app(GlassModalSheet(
            detents: _fitted,
            surfaceStyle: style,
            child: Builder(builder: (context) {
              seen = InheritedGlassSurfaceStyle.maybeOf(context);
              return _content();
            }),
          ));

      await tester.pumpWidget(sheet(GlassSurfaceStyle.solid));
      await tester.pumpAndSettle();
      expect(seen, GlassSurfaceStyle.solid);

      // A glass sheet publishes nothing, so widgets keep their own default.
      await tester.pumpWidget(sheet(GlassSurfaceStyle.glass));
      await tester.pumpAndSettle();
      expect(seen, isNull);
    });

    testWidgets('glass controls in a solid sheet get its real settings',
        (tester) async {
      _phone(tester);
      const settings = LiquidGlassSettings(blur: 12, thickness: 20);
      LiquidGlassSettings? seen;
      await tester.pumpWidget(_app(GlassModalSheet(
        detents: _fitted,
        settings: settings,
        surfaceStyle: GlassSurfaceStyle.solid,
        child: Builder(builder: (context) {
          seen = InheritedLiquidGlass.of(context);
          return _content();
        }),
      )));
      await tester.pumpAndSettle();
      // The sheet's own surface is dormant; what it passes on is not.
      expect(seen?.blur, settings.blur);
      expect(seen?.thickness, settings.thickness);
    });

    for (final (name, quality, platformViewBackdrop, topFade) in const [
      ('the default quality', null, false, false),
      ('GlassQuality.minimal', GlassQuality.minimal, false, false),
      ('platformViewBackdrop', null, true, false),
      ('the top fade at the large detent', null, false, true),
    ]) {
      testWidgets('keeps its State across glass → solid → glass with $name',
          (tester) async {
        _phone(tester);
        var inits = 0;
        var disposes = 0;
        Widget sheet(GlassSurfaceStyle style) => _app(GlassModalSheet(
              detents: _twoStop,
              initialState:
                  topFade ? GlassSheetState.full : GlassSheetState.half,
              enableTopFade: topFade,
              quality: quality,
              platformViewBackdrop: platformViewBackdrop,
              surfaceStyle: style,
              child: _Probe(
                onInit: () => inits++,
                onDispose: () => disposes++,
              ),
            ));

        await tester.pumpWidget(sheet(GlassSurfaceStyle.glass));
        await tester.pumpAndSettle();
        final state = tester.state(find.byType(_Probe));
        // The sheet's content zone, which holds its scroll wiring. It is
        // above the child, so it is checked on its own.
        final zone = tester.element(find.byType(ScrollControllerProvider));
        expect(inits, 1);

        await tester.pumpWidget(sheet(GlassSurfaceStyle.solid));
        await tester.pumpAndSettle();
        expect(_fillColor(tester), _defaultLight);

        await tester.pumpWidget(sheet(GlassSurfaceStyle.glass));
        await tester.pumpAndSettle();

        expect(inits, 1);
        expect(disposes, 0);
        expect(tester.state(find.byType(_Probe)), same(state));
        expect(
            tester.element(find.byType(ScrollControllerProvider)), same(zone));
      });
    }
  });

  group('entry points', () {
    testWidgets('GlassModalSheetScaffold passes surfaceStyle on',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(MaterialApp(
        home: GlassModalSheetScaffold(
          detents: const {GlassSheetDetent.medium},
          surfaceStyle: GlassSurfaceStyle.solid,
          body: const SizedBox.expand(),
          sheet: _content(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(_fillColor(tester), _defaultLight);
    });

    testWidgets('GlassModalSheet.show passes surfaceStyle on', (tester) async {
      _phone(tester);
      const home = Key('home');
      await tester
          .pumpWidget(const MaterialApp(home: SizedBox.expand(key: home)));
      GlassModalSheet.show<void>(
        context: tester.element(find.byKey(home)),
        detents: const {GlassSheetDetent.medium},
        surfaceStyle: GlassSurfaceStyle.solid,
        builder: (_) => _content(),
      );
      await tester.pumpAndSettle();
      expect(_fillColor(tester), _defaultLight);
    });

    for (final style in GlassSurfaceStyle.values) {
      testWidgets('a ${style.name} morph hands off without a flash',
          (tester) async {
        _phone(tester);
        GlassModalSheet.debugMorphSupportsBlending = true;
        addTearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);
        const fillColor = Color(0xFF123456);
        const home = Key('home');
        await tester
            .pumpWidget(const MaterialApp(home: SizedBox.expand(key: home)));
        GlassModalSheet.show<void>(
          context: tester.element(find.byKey(home)),
          detents: const {GlassSheetDetent.medium},
          surfaceStyle: style,
          expandedColor: fillColor,
          morphFromRect: const Rect.fromLTWH(175, 300, 40, 40),
          builder: (_) => _content(),
        );

        // The droplet's fill, while the droplet stands in for the sheet.
        double? dropletFill() {
          final boxes = tester
              .widgetList<ColoredBox>(find.byType(ColoredBox))
              .where((box) =>
                  box.color.withValues(alpha: 1.0) == fillColor &&
                  box.color.a > 0);
          return boxes.isEmpty ? null : boxes.first.color.a;
        }

        // Each frame's droplet fill and sheet fill, through the morph.
        final droplet = <double?>[];
        final sheet = <double>[];
        await tester.pump();
        for (var i = 0; i < 90; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          droplet.add(dropletFill());
          sheet.add(_fillColor(tester).a);
        }
        await tester.pumpAndSettle();

        final last = droplet.lastIndexWhere((fill) => fill != null);
        if (style == GlassSurfaceStyle.solid) {
          // The droplet lands opaque, and the sheet takes over opaque on the
          // next frame.
          expect(last, isNonNegative, reason: 'the droplet fills');
          expect(last, lessThan(droplet.length - 1));
          expect(droplet[last], 1.0);
          expect(sheet[last + 1], 1.0);
          expect(_fillColor(tester), fillColor);
        } else {
          // A glass medium sheet lands as glass, with no fill at all.
          expect(last, -1);
          expect(_fillColor(tester).a, 0.0);
        }
      });
    }
  });

  group('solid fitted sheet with no margins', () {
    Widget sheet() => _app(GlassModalSheet(
          detents: _fitted,
          surfaceStyle: GlassSurfaceStyle.solid,
          horizontalMargin: 0,
          bottomMargin: 0,
          bottomBorderRadius: 0,
          interactionScale: 1.0,
          stretch: 0,
          child: _content(),
        ));

    testWidgets('rests full width on the bottom edge', (tester) async {
      _phone(tester);
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      final frame = _frame(tester);
      expect(frame.left, closeTo(0.0, 0.01));
      expect(frame.right, closeTo(_screen.width, 0.01));
      expect(frame.bottom, closeTo(_screen.height, 0.01));
    });

    testWidgets('leaves no gap under it when over-dragged up', (tester) async {
      _phone(tester);
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      final resting = _frame(tester);

      final gesture =
          await tester.startGesture(resting.topCenter + const Offset(0, 20));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 16));
        final frame = _frame(tester);
        expect(frame.bottom, greaterThanOrEqualTo(_screen.height - 0.01));
        expect(frame.left, closeTo(0.0, 0.01));
        expect(frame.right, closeTo(_screen.width, 0.01));
        expect(_fillColor(tester), _defaultLight);
      }
      expect(_frame(tester).top, lessThan(resting.top),
          reason: 'the over-drag moves the top edge');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_frame(tester).top, closeTo(resting.top, 0.01));
    });

    testWidgets('can be swiped away', (tester) async {
      _phone(tester);
      final states = <GlassSheetState>[];
      await tester.pumpWidget(_app(GlassModalSheet(
        detents: _fitted,
        surfaceStyle: GlassSurfaceStyle.solid,
        horizontalMargin: 0,
        bottomMargin: 0,
        bottomBorderRadius: 0,
        interactionScale: 1.0,
        stretch: 0,
        onStateChanged: states.add,
        child: _content(),
      )));
      await tester.pumpAndSettle();

      await tester.flingFrom(
        _frame(tester).topCenter + const Offset(0, 20),
        const Offset(0, 300),
        1500,
      );
      await tester.pumpAndSettle();
      expect(states.last, GlassSheetState.hidden);
    });
  });
}
