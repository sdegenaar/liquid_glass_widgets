import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

const _lightFill = Color(0xFFFFFFFF);
const _darkFill = Color(0xFF1C1C1E);

/// Pumps [child] in a MaterialApp (brightness drives the Cupertino theme too).
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  bool glassLayer = true,
}) {
  return tester.pumpWidget(
    createTestApp(
      theme: ThemeData(brightness: brightness),
      child: glassLayer
          ? AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: child,
            )
          : child,
    ),
  );
}

/// The solid fill painted by a card, or null when no ShapeDecoration exists.
ShapeDecoration? _solidDecoration(WidgetTester tester, Finder within) {
  final boxes = tester.widgetList<DecoratedBox>(
    find.descendant(of: within, matching: find.byType(DecoratedBox)),
  );
  for (final b in boxes) {
    if (b.decoration is ShapeDecoration) {
      return b.decoration as ShapeDecoration;
    }
  }
  return null;
}

void main() {
  group('GlassSurfaceStyle', () {
    test('is exported from the package entry point with glass + solid', () {
      expect(
        GlassSurfaceStyle.values,
        equals([GlassSurfaceStyle.glass, GlassSurfaceStyle.solid]),
      );
    });
  });

  group('GlassContainer.card', () {
    test('glass defaults match the deprecated GlassCard (16 pad, 12 squircle)',
        () {
      const card = GlassContainer.card();

      expect(card.padding, equals(const EdgeInsets.all(16)));
      expect(card.useOwnLayer, isFalse);
      expect(card.quality, isNull);
      expect(card.clipBehavior, Clip.none);
      expect(
        card.shape,
        equals(const LiquidRoundedSuperellipse(borderRadius: 12)),
      );
    });

    test('solid defaults to a 26pt superellipse and 16 padding', () {
      const card = GlassContainer.card(surfaceStyle: GlassSurfaceStyle.solid);

      expect(card.padding, equals(const EdgeInsets.all(16)));
      expect(
        card.shape,
        equals(const LiquidRoundedSuperellipse(borderRadius: 26)),
      );
    });

    test('an explicit shape wins for both styles', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 8);
      for (final style in GlassSurfaceStyle.values) {
        expect(
          GlassContainer.card(shape: shape, surfaceStyle: style).shape,
          equals(shape),
        );
      }
    });

    testWidgets('default style is glass (AdaptiveGlass is used)',
        (tester) async {
      await _pump(
        tester,
        const GlassContainer.card(child: Text('hi')),
      );

      expect(find.byType(AdaptiveGlass), findsOneWidget);
      expect(_solidDecoration(tester, find.byType(GlassContainer)), isNull);
    });

    for (final entry in {
      Brightness.light: _lightFill,
      Brightness.dark: _darkFill,
    }.entries) {
      testWidgets(
          'solid fill is ${entry.key == Brightness.light ? '#FFFFFF' : '#1C1C1E'} in ${entry.key.name} mode',
          (tester) async {
        await _pump(
          tester,
          const GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            child: Text('hi'),
          ),
          brightness: entry.key,
        );

        final decoration =
            _solidDecoration(tester, find.byType(GlassContainer))!;
        expect(decoration.color!.toARGB32(), equals(entry.value.toARGB32()));
        expect(
          decoration.shape,
          equals(const LiquidRoundedSuperellipse(borderRadius: 26)),
        );
        // Flat: ShapeDecoration with no shadow or gradient.
        expect(decoration.shadows, isNull);
        expect(decoration.gradient, isNull);
        expect(find.text('hi'), findsOneWidget);
      });
    }

    testWidgets('solid never touches the glass pipeline', (tester) async {
      await _pump(
        tester,
        const GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          child: Text('hi'),
        ),
      );

      expect(find.byType(AdaptiveGlass), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('solid needs no ancestor glass layer, even with useOwnLayer',
        (tester) async {
      await _pump(
        tester,
        const GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          useOwnLayer: true,
          child: Text('standalone'),
        ),
        glassLayer: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('standalone'), findsOneWidget);
    });

    testWidgets('solid follows CupertinoTheme brightness in a CupertinoApp',
        (tester) async {
      Future<Color?> fillFor(Brightness b) async {
        await tester.pumpWidget(
          CupertinoApp(
            theme: CupertinoThemeData(brightness: b),
            home: const GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              child: Text('c'),
            ),
          ),
        );
        return _solidDecoration(tester, find.byType(GlassContainer))!.color;
      }

      expect(
          (await fillFor(Brightness.light))!.toARGB32(), _lightFill.toARGB32());
      expect(
          (await fillFor(Brightness.dark))!.toARGB32(), _darkFill.toARGB32());
    });

    for (final entry in {
      Brightness.dark: _darkFill,
      Brightness.light: _lightFill,
    }.entries) {
      testWidgets(
          'solid obeys a GlassTheme brightness override (${entry.key.name}) '
          'over the app theme', (tester) async {
        // App is the opposite brightness, so the override is what must win.
        final opposite =
            entry.key == Brightness.dark ? Brightness.light : Brightness.dark;
        await tester.pumpWidget(
          GlassTheme(
            data: GlassThemeData(brightness: entry.key),
            child: createTestApp(
              theme: ThemeData(brightness: opposite),
              child: const GlassContainer.card(
                surfaceStyle: GlassSurfaceStyle.solid,
                child: Text('t'),
              ),
            ),
          ),
        );

        final fill = _solidDecoration(tester, find.byType(GlassContainer))!
            .color!
            .toARGB32();
        expect(fill, entry.value.toARGB32());
      });
    }

    testWidgets('solid warns (debug) when glass-only settings are passed',
        (tester) async {
      final printed = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) printed.add(message);
      };
      // Flutter's test invariants run before tear-downs, so restore inline.
      try {
        await _pump(
          tester,
          GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            settings: defaultTestGlassSettings,
            child: const Text('w'),
          ),
        );
        expect(
          printed.where((m) => m.contains('have no effect')),
          isNotEmpty,
        );

        printed.clear();
        await _pump(
          tester,
          const GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            child: Text('w'),
          ),
        );
        expect(printed.where((m) => m.contains('have no effect')), isEmpty);
      } finally {
        debugPrint = original;
      }
    });

    testWidgets('solid applies padding, size and margin', (tester) async {
      await _pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            margin: EdgeInsets.all(10),
            width: 100,
            height: 60,
            child: SizedBox.expand(key: Key('content')),
          ),
        ),
      );

      // 100 x 60 card; content fills it minus 16 padding on each side.
      expect(
        tester.getSize(find.byKey(const Key('content'))),
        const Size(100 - 32, 60 - 32),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('content'))),
        const Offset(10 + 16, 10 + 16),
      );
    });

    testWidgets('solid clips content only when clipBehavior asks for it',
        (tester) async {
      Finder clip() => find.descendant(
            of: find.byType(GlassContainer),
            matching: find.byWidgetPredicate(
              (w) => w is ClipPath && w.clipper is ShapeBorderClipper,
            ),
          );

      await _pump(
        tester,
        const GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          child: Text('a'),
        ),
      );
      expect(clip(), findsNothing);

      await _pump(
        tester,
        const GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          clipBehavior: Clip.antiAlias,
          child: Text('a'),
        ),
      );
      expect(clip(), findsOneWidget);
    });
  });

  group('GlassGroupedSection.surfaceStyle', () {
    List<Widget> rows() => const [
          GlassListTile(title: Text('One')),
          GlassListTile(title: Text('Two')),
        ];

    testWidgets('defaults to glass', (tester) async {
      await _pump(tester, GlassGroupedSection(children: rows()));

      expect(find.byType(AdaptiveGlass), findsOneWidget);
      expect(
          _solidDecoration(tester, find.byType(GlassGroupedSection)), isNull);
    });

    for (final entry in {
      Brightness.light: _lightFill,
      Brightness.dark: _darkFill,
    }.entries) {
      testWidgets('solid renders a flat ${entry.key.name} card',
          (tester) async {
        await _pump(
          tester,
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            header: const Text('HEADER'),
            children: rows(),
          ),
          brightness: entry.key,
        );

        final decoration =
            _solidDecoration(tester, find.byType(GlassGroupedSection))!;
        expect(decoration.color!.toARGB32(), equals(entry.value.toARGB32()));
        expect(
          decoration.shape,
          equals(const LiquidRoundedSuperellipse(borderRadius: 26)),
        );
        expect(find.byType(AdaptiveGlass), findsNothing);
        expect(find.text('One'), findsOneWidget);
        expect(find.text('HEADER'), findsOneWidget);
        // Rows are clipped to the card's rounded corners like native lists.
        expect(
          find.descendant(
            of: find.byType(GlassGroupedSection),
            matching: find.byType(ClipPath),
          ),
          findsWidgets,
        );
      });
    }

    testWidgets('solid honours an explicit shape', (tester) async {
      await _pump(
        tester,
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          shape: const LiquidRoundedSuperellipse(borderRadius: 10),
          children: rows(),
        ),
      );

      expect(
        _solidDecoration(tester, find.byType(GlassGroupedSection))!.shape,
        equals(const LiquidRoundedSuperellipse(borderRadius: 10)),
      );
    });
  });

  group('GlassReorderableList.grouped.surfaceStyle', () {
    Widget list({GlassSurfaceStyle? style}) {
      Widget tile(BuildContext c, int i) => GlassListTile(
            key: ValueKey(i),
            title: Text('Item $i'),
          );
      return SizedBox(
        height: 300,
        child: style == null
            ? GlassReorderableList.grouped(
                itemCount: 3,
                itemBuilder: tile,
                onReorderItem: (_, __) {},
              )
            : GlassReorderableList.grouped(
                itemCount: 3,
                itemBuilder: tile,
                onReorderItem: (_, __) {},
                surfaceStyle: style,
              ),
      );
    }

    testWidgets('defaults to glass', (tester) async {
      await _pump(tester, list());

      expect(find.byType(AdaptiveGlass), findsOneWidget);
    });

    for (final entry in {
      Brightness.light: _lightFill,
      Brightness.dark: _darkFill,
    }.entries) {
      testWidgets('solid renders a flat ${entry.key.name} card',
          (tester) async {
        await _pump(
          tester,
          list(style: GlassSurfaceStyle.solid),
          brightness: entry.key,
        );

        final decoration =
            _solidDecoration(tester, find.byType(GlassReorderableList))!;
        expect(decoration.color!.toARGB32(), equals(entry.value.toARGB32()));
        expect(
          decoration.shape,
          equals(const LiquidRoundedSuperellipse(borderRadius: 26)),
        );
        expect(find.byType(AdaptiveGlass), findsNothing);
        expect(find.text('Item 0'), findsOneWidget);
      });
    }

    // Starts a long-press drag on the first row and returns the lifted proxy's
    // BoxDecoration (the default proxy decorator's shadowed container).
    Future<BoxDecoration> liftFirstRow(
      WidgetTester tester,
      GlassSurfaceStyle style,
    ) async {
      await _pump(
        tester,
        SizedBox(
          height: 300,
          child: GlassReorderableList.grouped(
            itemCount: 3,
            surfaceStyle: style,
            onReorderItem: (_, __) {},
            itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
              key: ValueKey(i),
              index: i,
              child: GlassListTile(title: Text('Item $i')),
            ),
          ),
        ),
        brightness: Brightness.dark,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Item 0')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 400));

      final lifted = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => (d.boxShadow ?? const []).isNotEmpty)
          .toList();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(lifted, isNotEmpty, reason: 'no lifted drag proxy found');
      return lifted.first;
    }

    testWidgets('solid: the lifted row is opaque (card fill)', (tester) async {
      final d = await liftFirstRow(tester, GlassSurfaceStyle.solid);
      expect(d.color!.toARGB32(), _darkFill.toARGB32());
    });

    testWidgets('glass: the lifted row keeps its previous (no fill) look',
        (tester) async {
      final d = await liftFirstRow(tester, GlassSurfaceStyle.glass);
      expect(d.color, isNull);
    });
  });

  group('GlassDatePicker / GlassMultiDatePicker surfaceStyle', () {
    final day = DateTime(2026, 3, 18);

    final variants = <String, Widget Function(GlassSurfaceStyle)>{
      'wheel': (s) =>
          GlassDatePicker.wheel(initialDateTime: day, surfaceStyle: s),
      'graphical': (s) =>
          GlassDatePicker.graphical(initialDateTime: day, surfaceStyle: s),
      'default constructor': (s) =>
          GlassDatePicker(initialDateTime: day, surfaceStyle: s),
      'multi-date': (s) => GlassMultiDatePicker(
            selectedDates: {day},
            displayedMonth: day,
            surfaceStyle: s,
          ),
    };

    for (final v in variants.entries) {
      testWidgets('${v.key}: defaults to a glass card', (tester) async {
        await _pump(tester,
            SingleChildScrollView(child: v.value(GlassSurfaceStyle.glass)));
        await tester.pump();

        expect(find.byType(AdaptiveGlass), findsOneWidget);
      });

      for (final b in Brightness.values) {
        testWidgets('${v.key}: solid card in ${b.name} mode', (tester) async {
          await _pump(
            tester,
            SingleChildScrollView(child: v.value(GlassSurfaceStyle.solid)),
            brightness: b,
          );
          await tester.pump();

          expect(find.byType(AdaptiveGlass), findsNothing);
          final decoration = _solidDecoration(
            tester,
            find.byWidgetPredicate(
              (w) => w is GlassDatePicker || w is GlassMultiDatePicker,
            ),
          )!;
          expect(
            decoration.color!.toARGB32(),
            (b == Brightness.light ? _lightFill : _darkFill).toARGB32(),
          );
          expect(
            decoration.shape,
            equals(const LiquidRoundedSuperellipse(borderRadius: 26)),
          );
        });
      }
    }

    testWidgets('solid honours an explicit shape', (tester) async {
      await _pump(
        tester,
        SingleChildScrollView(
          child: GlassDatePicker.wheel(
            initialDateTime: day,
            shape: const LiquidRoundedSuperellipse(borderRadius: 10),
            surfaceStyle: GlassSurfaceStyle.solid,
          ),
        ),
      );

      expect(
        _solidDecoration(tester, find.byType(GlassDatePicker))!.shape,
        equals(const LiquidRoundedSuperellipse(borderRadius: 10)),
      );
    });
  });
}
