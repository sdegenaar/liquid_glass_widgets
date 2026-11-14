import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassPicker rendering', () {
    testWidgets('renders with a selected value', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassPicker(value: 'Option A', onTap: () {}),
        ),
      );
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('renders placeholder when value is null', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(value: null, placeholder: 'Choose one'),
        ),
      );
      expect(find.text('Choose one'), findsOneWidget);
    });

    testWidgets(
      'renders default placeholder when value is null and no placeholder given',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(child: const GlassPicker(value: null)),
        );
        expect(find.text('Select'), findsOneWidget);
      },
    );

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(
            value: 'A',
            icon: Icon(Icons.arrow_drop_down),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('renders default chevron icon when no icon given', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const GlassPicker(value: 'X')),
      );
      expect(
        find.byIcon(CupertinoIcons.chevron_up_chevron_down),
        findsOneWidget,
      );
    });

    testWidgets('custom height is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const GlassPicker(value: 'Y', height: 64)),
      );
      expect(find.byType(GlassPicker), findsOneWidget);
    });

    testWidgets('custom width is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const GlassPicker(value: 'Z', width: 200)),
      );
      expect(find.byType(GlassPicker), findsOneWidget);
    });

    testWidgets('custom textStyle is applied', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(
            value: 'Styled',
            textStyle: TextStyle(fontSize: 20, color: Colors.amber),
          ),
        ),
      );
      expect(find.text('Styled'), findsOneWidget);
    });

    testWidgets('custom placeholderStyle is applied', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(
            value: null,
            placeholder: 'Pick...',
            placeholderStyle: TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ),
      );
      expect(find.text('Pick...'), findsOneWidget);
    });
  });

  group('GlassPicker tap interaction', () {
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        createTestApp(
          child: GlassPicker(value: 'Tap me', onTap: () => tapped = true),
        ),
      );
      await tester.tap(find.byType(GlassPicker));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('onTap is null is safe (no crash)', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const GlassPicker(value: 'No tap')),
      );
      await tester.tap(find.byType(GlassPicker));
      await tester.pump();
      // No crash expected
      expect(find.byType(GlassPicker), findsOneWidget);
    });
  });

  group('GlassPicker layer and quality', () {
    testWidgets('renders with useOwnLayer=true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(value: 'Layered', useOwnLayer: true),
        ),
      );
      expect(find.byType(GlassPicker), findsOneWidget);
    });

    testWidgets('renders with custom quality', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(value: 'Q', quality: GlassQuality.standard),
        ),
      );
      expect(find.byType(GlassPicker), findsOneWidget);
    });

    testWidgets('renders with custom settings', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(
            value: 'G',
            settings: LiquidGlassSettings(thickness: 20),
          ),
        ),
      );
      expect(find.byType(GlassPicker), findsOneWidget);
    });

    testWidgets('renders with custom shape', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPicker(
            value: 'S',
            shape: LiquidRoundedSuperellipse(borderRadius: 16),
          ),
        ),
      );
      expect(find.byType(GlassPicker), findsOneWidget);
    });
  });

  group('GlassPicker.showSheet', () {
    testWidgets('showSheet with title renders sheet', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => GlassPicker.showSheet<String>(
                context: ctx,
                items: const ['A', 'B', 'C'],
                itemBuilder: (item) => Text(item),
                title: 'Pick Option',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pick Option'), findsOneWidget);
    });

    testWidgets('showSheet without title omits title row', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => GlassPicker.showSheet<String>(
                context: ctx,
                items: const ['X', 'Y'],
                itemBuilder: (item) => Text(item),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // No title, sheet is open; we just verify no crash
      expect(find.byType(CupertinoPicker), findsOneWidget);
    });

    testWidgets('showSheet renders items via itemBuilder', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => GlassPicker.showSheet<int>(
                context: ctx,
                items: const [1, 2, 3],
                itemBuilder: (item) => Text('Item $item'),
                title: 'Numbers',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Numbers'), findsOneWidget);
    });

    testWidgets(
      'showSheet propagates ambient GlassTheme and scrolls CupertinoPicker items',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: GlassTheme(
              data: const GlassThemeData.ios26(brightness: Brightness.dark),
              child: Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => GlassPicker.showSheet<int>(
                    context: ctx,
                    items: const [1, 2, 3],
                    itemBuilder: (item) => Text('Item $item'),
                    title: 'Numbers',
                  ),
                  child: const Text('Open Themed Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Themed Sheet'));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(CupertinoPicker), const Offset(0, -60));
        await tester.pumpAndSettle();

        expect(find.byType(CupertinoPicker), findsOneWidget);
      },
    );
  });

  group('GlassPicker.showSheet result', () {
    const fruits = ['Apple', 'Banana', 'Cherry'];

    /// Opens the sheet and returns the future [GlassPicker.showSheet] gave.
    Future<Future<String?>> openSheet(
      WidgetTester tester, {
      List<String> items = fruits,
      String? title = 'Fruit',
      TextDirection textDirection = TextDirection.ltr,
    }) async {
      late Future<String?> result;
      await tester.pumpWidget(
        CupertinoApp(
          builder: (context, child) =>
              Directionality(textDirection: textDirection, child: child!),
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => result = GlassPicker.showSheet<String>(
                context: context,
                items: items,
                itemBuilder: Text.new,
                title: title,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('Done without scrolling returns the first item', (
      tester,
    ) async {
      final result = await openSheet(tester);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(await result, 'Apple');
      expect(find.byType(CupertinoPicker), findsNothing);
    });

    testWidgets('Done returns the scrolled-to item', (tester) async {
      final result = await openSheet(tester);

      // itemExtent is 40, so two extents up lands on the third item.
      await tester.drag(find.byType(CupertinoPicker), const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(await result, 'Cherry');
    });

    testWidgets('Cancel returns null', (tester) async {
      final result = await openSheet(tester);

      await tester.drag(find.byType(CupertinoPicker), const Offset(0, -40));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await result, isNull);
      expect(find.byType(CupertinoPicker), findsNothing);
    });

    testWidgets('a barrier tap returns null', (tester) async {
      final result = await openSheet(tester);

      await tester.drag(find.byType(CupertinoPicker), const Offset(0, -40));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(await result, isNull);
      expect(find.byType(CupertinoPicker), findsNothing);
    });

    testWidgets('header shows Cancel and Done without a title', (tester) async {
      final result = await openSheet(tester, title: null);

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(await result, 'Apple');
    });

    testWidgets('empty items open without error and Done returns null', (
      tester,
    ) async {
      final result = await openSheet(tester, items: const []);

      expect(tester.takeException(), isNull);
      expect(find.byType(CupertinoPicker), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(await result, isNull);
      expect(find.byType(CupertinoPicker), findsNothing);
    });

    testWidgets(
      'shown from a MaterialApp, title does not inherit error text style',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => GlassPicker.showSheet<String>(
                  context: context,
                  items: fruits,
                  itemBuilder: Text.new,
                  title: 'Fruit',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final titleStyle = tester
            .renderObject<RenderParagraph>(find.text('Fruit'))
            .text
            .style!;
        expect(titleStyle.decoration, isNot(TextDecoration.underline));
        expect(titleStyle.fontFamily, isNot('monospace'));
      },
    );
  });

  group('GlassPicker.showSheet semantics', () {
    const fruits = ['Apple', 'Banana', 'Cherry'];

    Future<Future<String?>> openSheet(
      WidgetTester tester, {
      List<String> items = fruits,
      String? title = 'Fruit',
    }) async {
      late Future<String?> result;
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => result = GlassPicker.showSheet<String>(
                context: context,
                items: items,
                itemBuilder: Text.new,
                title: title,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('the picker is one adjustable node labelled with the title', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester);

      expect(
        tester.getSemantics(find.byType(CupertinoPicker)),
        isSemantics(
          label: 'Fruit',
          value: 'Apple',
          increasedValue: 'Banana',
          hasIncreaseAction: true,
          textDirection: TextDirection.ltr,
        ),
      );
      // The value is not repeated in a separate unlabelled node.
      expect(find.semantics.byValue('Apple'), findsOne);

      handle.dispose();
    });

    testWidgets('the label follows the selection as the wheel scrolls', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester);

      await tester.drag(find.byType(CupertinoPicker), const Offset(0, -40));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(CupertinoPicker)),
        isSemantics(
          label: 'Fruit',
          value: 'Banana',
          increasedValue: 'Cherry',
          decreasedValue: 'Apple',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          textDirection: TextDirection.ltr,
        ),
      );

      handle.dispose();
    });

    testWidgets('increase and decrease move the wheel and Done returns it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final result = await openSheet(tester);

      tester.semantics.increase(find.semantics.byValue('Apple'));
      await tester.pumpAndSettle();
      tester.semantics.increase(find.semantics.byValue('Banana'));
      await tester.pumpAndSettle();

      // The last item has nothing to increase to.
      expect(
        tester.getSemantics(find.byType(CupertinoPicker)),
        isSemantics(
          label: 'Fruit',
          value: 'Cherry',
          decreasedValue: 'Banana',
          hasDecreaseAction: true,
          hasIncreaseAction: false,
          textDirection: TextDirection.ltr,
        ),
      );

      tester.semantics.decrease(find.semantics.byValue('Cherry'));
      await tester.pumpAndSettle();
      tester.semantics.tap(find.semantics.byLabel('Done'));
      await tester.pumpAndSettle();

      expect(await result, 'Banana');
      handle.dispose();
    });

    testWidgets('Done and Cancel are buttons; Cancel returns null', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final result = await openSheet(tester);

      for (final label in ['Done', 'Cancel']) {
        expect(
          find.semantics.byLabel(label),
          isSemantics(isButton: true, hasTapAction: true),
        );
      }

      tester.semantics.tap(find.semantics.byLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(await result, isNull);
      expect(find.byType(CupertinoPicker), findsNothing);
      handle.dispose();
    });

    testWidgets(
      'the barrier exposes a Dismiss action that returns null',
      (tester) async {
        final handle = tester.ensureSemantics();
        final result = await openSheet(tester);

        expect(
          find.semantics.byLabel('Dismiss'),
          isSemantics(hasDismissAction: true),
        );

        tester.semantics.dismiss(find.semantics.byLabel('Dismiss'));
        await tester.pumpAndSettle();

        expect(await result, isNull);
        expect(find.byType(CupertinoPicker), findsNothing);
        handle.dispose();
      },
      // ModalBarrier only exposes its dismiss action on Apple platforms;
      // elsewhere the system back action closes the sheet.
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
    );

    testWidgets('without a title the picker node keeps no label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester, title: null);

      expect(
        find.semantics.byValue('Apple'),
        isSemantics(
          label: '',
          value: 'Apple',
          increasedValue: 'Banana',
          hasIncreaseAction: true,
          textDirection: TextDirection.ltr,
        ),
      );

      handle.dispose();
    });

    testWidgets('empty items keep the title label without a value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester, items: const []);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.byType(CupertinoPicker)),
        matchesSemantics(label: 'Fruit', textDirection: TextDirection.ltr),
      );

      handle.dispose();
    });

    testWidgets('the picker node follows a text direction change', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final direction = ValueNotifier(TextDirection.ltr);
      addTearDown(direction.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          builder: (context, child) => ValueListenableBuilder<TextDirection>(
            valueListenable: direction,
            builder: (context, value, _) =>
                Directionality(textDirection: value, child: child!),
          ),
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => GlassPicker.showSheet<String>(
                context: context,
                items: fruits,
                itemBuilder: Text.new,
                title: 'Fruit',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      direction.value = TextDirection.rtl;
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(CupertinoPicker)),
        isSemantics(
          label: 'Fruit',
          value: 'Apple',
          textDirection: TextDirection.rtl,
        ),
      );

      handle.dispose();
    });
  });

  group('GlassPicker defaults', () {
    test('default values are correct', () {
      const picker = GlassPicker(value: null);
      expect(picker.placeholder, 'Select');
      expect(picker.height, 48.0);
      expect(picker.width, isNull);
      expect(picker.useOwnLayer, isFalse);
      expect(picker.quality, isNull);
      expect(picker.icon, isNull);
    });
  });
}
