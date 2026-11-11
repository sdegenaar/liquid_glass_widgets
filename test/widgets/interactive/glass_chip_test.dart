// ignore: unnecessary_import
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassChip', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassChip(
              label: 'Test Chip',
            ),
          ),
        ),
      );

      expect(find.byType(GlassChip), findsOneWidget);
      expect(find.text('Test Chip'), findsOneWidget);
    });

    testWidgets('displays label correctly', (tester) async {
      const testLabel = 'Flutter';

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassChip(
              label: testLabel,
            ),
          ),
        ),
      );

      expect(find.text(testLabel), findsOneWidget);
    });

    testWidgets('displays leading icon when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassChip(
              label: 'Favorite',
              icon: Icon(CupertinoIcons.heart_fill),
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
    });

    testWidgets('displays delete button when onDeleted provided',
        (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassChip(
              label: 'Tag',
              onDeleted: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();

      expect(deleted, isTrue);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassChip(
              label: 'Filter',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassChip));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows selection state when selected', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassChip(
              label: 'Selected',
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassChip), findsOneWidget);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassChip(
            label: 'Standalone',
            useOwnLayer: true,
          ),
        ),
      );

      expect(find.byType(GlassChip), findsOneWidget);
    });

    test('defaults are correct', () {
      final chip = GlassChip(
        label: 'Test',
      );

      expect(chip.selected, isFalse);
      expect(chip.useOwnLayer, isFalse);
      expect(chip.quality, isNull);
      expect(chip.surfaceStyle, isNull);
      expect(chip.color, isNull);
      expect(chip.interactionScale, equals(1.03));
      expect(chip.stretch, equals(0.3));
      expect(chip.glowRadius, equals(0.8));
    });

    group('GlassSurfaceStyle.solid', () {
      testWidgets('bypasses GlassButton and AdaptiveGlass in solid mode',
          (tester) async {
        var tapped = false;
        var deleted = false;

        await tester.pumpWidget(
          createTestApp(
            child: GlassChip(
              label: 'Solid Filter',
              surfaceStyle: GlassSurfaceStyle.solid,
              onTap: () => tapped = true,
              onDeleted: () => deleted = true,
            ),
          ),
        );

        expect(find.byType(GlassChip), findsOneWidget);
        expect(find.byType(GlassButton), findsNothing);
        expect(find.byType(AdaptiveGlass), findsNothing);

        await tester.tap(find.text('Solid Filter'));
        await tester.pump();
        expect(tapped, isTrue);
        expect(deleted, isFalse);

        await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
        await tester.pump();
        expect(deleted, isTrue);
      });

      testWidgets('inherits GlassSurfaceStyle.solid inside solid card',
          (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              child: const GlassChip(
                label: 'Inherited Solid',
              ),
            ),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(GlassChip),
            matching: find.byType(GlassButton),
          ),
          findsNothing,
        );
      });

      testWidgets(
          'uses custom color when unselected and selectedColor when selected',
          (tester) async {
        const customFill = Color(0xFFEEEEEE);
        const customSelected = Color(0xFF7B2CBF);

        await tester.pumpWidget(
          createTestApp(
            child: const GlassChip(
              label: 'Stage 1',
              surfaceStyle: GlassSurfaceStyle.solid,
              color: customFill,
              selectedColor: customSelected,
              selected: false,
            ),
          ),
        );

        DecoratedBox pill = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassChip),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect((pill.decoration as ShapeDecoration).color, customFill);

        await tester.pumpWidget(
          createTestApp(
            child: const GlassChip(
              label: 'Stage 1',
              surfaceStyle: GlassSurfaceStyle.solid,
              color: customFill,
              selectedColor: customSelected,
              selected: true,
            ),
          ),
        );

        pill = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassChip),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect((pill.decoration as ShapeDecoration).color, customSelected);
      });

      testWidgets('Space key triggers onTap in solid mode', (tester) async {
        var tapped = false;
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(
          createTestApp(
            child: GlassChip(
              label: 'Solid Key',
              surfaceStyle: GlassSurfaceStyle.solid,
              onTap: () => tapped = true,
              focusNode: focusNode,
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('ellipsizes long labels without overflowing narrow parents',
          (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: SizedBox(
              width: 120,
              child: GlassChip(
                label: 'Waiting on hospital pricing and surgeon review',
                surfaceStyle: GlassSurfaceStyle.solid,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('keyboard focus & accessibility', () {
      testWidgets('Space key triggers onTap when focused', (tester) async {
        bool tapped = false;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassChip(
                label: 'Chip',
                onTap: () => tapped = true,
                focusNode: focusNode,
              ),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('Enter key triggers onTap when focused', (tester) async {
        bool tapped = false;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassChip(
                label: 'Chip',
                onTap: () => tapped = true,
                focusNode: focusNode,
              ),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('exposes chip semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            createTestApp(
              child: GlassChip(
                label: 'Test Chip',
                semanticLabel: 'Semantics Chip',
                onTap: () {},
              ),
            ),
          );

          final node =
              tester.getSemantics(find.bySemanticsLabel('Semantics Chip'));
          // ignore: deprecated_member_use
          expect(node.hasFlag(SemanticsFlag.isButton), true);
          // ignore: deprecated_member_use
          expect(node.hasFlag(SemanticsFlag.isEnabled), true);
          // ignore: deprecated_member_use
          expect(node.hasFlag(SemanticsFlag.isFocusable), true);
        } finally {
          handle.dispose();
        }
      });
    });
  });
}
