import 'package:liquid_glass_widgets/widgets/overlays/glass_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassDialog', () {
    final testActions = [
      GlassDialogAction(label: 'Cancel', onPressed: () {}),
      GlassDialogAction(label: 'OK', onPressed: () {}),
    ];

    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: GlassDialog(actions: testActions)),
      );

      expect(find.byType(GlassDialog), findsOneWidget);
    });

    testWidgets('displays title when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(title: 'Alert', actions: testActions),
        ),
      );

      expect(find.text('Alert'), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            title: 'Confirm',
            message: 'Are you sure?',
            actions: testActions,
          ),
        ),
      );

      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('displays custom content when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            content: const Text('Custom Content'),
            actions: testActions,
          ),
        ),
      );

      expect(find.text('Custom Content'), findsOneWidget);
    });

    testWidgets('displays all action buttons', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: GlassDialog(actions: testActions)),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('action buttons call onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            actions: [
              GlassDialogAction(
                label: 'Press Me',
                onPressed: () => pressed = true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Press Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows dialog with static show method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  GlassDialog.show(
                    context: context,
                    title: 'Test Dialog',
                    actions: testActions,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
    });

    test('defaults are correct', () {
      final dialog = GlassDialog(actions: testActions);

      expect(
        dialog.maxWidth,
        isNull,
        reason: 'null follows the active style: 320 native, 280 classic',
      );
      expect(dialog.quality, isNull);
    });

    test('asserts 1-3 actions', () {
      expect(() => GlassDialog(actions: []), throwsAssertionError);

      expect(
        () => GlassDialog(
          actions: List.generate(
            4,
            (i) => GlassDialogAction(label: 'Action $i', onPressed: () {}),
          ),
        ),
        throwsAssertionError,
      );
    });
  });

  group('GlassDialogAction', () {
    test('can be instantiated', () {
      final action = GlassDialogAction(label: 'OK', onPressed: () {});

      expect(action.label, equals('OK'));
      expect(action.isPrimary, isFalse);
      expect(action.isDestructive, isFalse);
    });

    test('can be marked as primary', () {
      final action = GlassDialogAction(
        label: 'Save',
        onPressed: () {},
        isPrimary: true,
      );

      expect(action.isPrimary, isTrue);
    });

    test('can be marked as destructive', () {
      final action = GlassDialogAction(
        label: 'Delete',
        onPressed: () {},
        isDestructive: true,
      );

      expect(action.isDestructive, isTrue);
    });
  });

  group('GlassDialog action layout', () {
    List<GlassDialogAction> two(String a, String b) => [
      GlassDialogAction(label: a, onPressed: () {}),
      GlassDialogAction(label: b, onPressed: () {}, isPrimary: true),
    ];

    Future<void> pumpDialog(
      WidgetTester tester,
      List<GlassDialogAction> actions, {
      double textScale = 1.0,
    }) async {
      await tester.pumpWidget(
        createTestApp(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: GlassDialog(title: 'Title', actions: actions),
          ),
        ),
      );
    }

    final inRow = find.descendant(
      of: find.byType(GlassDialog),
      matching: find.byType(Row),
    );

    testWidgets('keeps two short labels side by side', (tester) async {
      // The test font draws every glyph a full em wide, so "short" here is
      // a few letters.
      await pumpDialog(tester, two('No', 'OK'));

      expect(inRow, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('No')).dy,
        tester.getTopLeft(find.text('OK')).dy,
      );
    });

    testWidgets('stacks two actions when a label is too long', (tester) async {
      await pumpDialog(
        tester,
        two('Cancel', 'Continue without saving changes'),
      );

      expect(inRow, findsNothing);
      expect(
        tester.getTopLeft(find.text('Continue without saving changes')).dy,
        greaterThan(tester.getTopLeft(find.text('Cancel')).dy),
      );
    });

    testWidgets('stacks two short labels at a large text scale', (
      tester,
    ) async {
      await pumpDialog(tester, two('No', 'OK'), textScale: 4.0);

      expect(inRow, findsNothing);
    });

    testWidgets('keeps a single long action in the horizontal row', (
      tester,
    ) async {
      await pumpDialog(tester, [
        GlassDialogAction(
          label: 'Continue without saving',
          onPressed: () {},
          isPrimary: true,
        ),
      ]);

      expect(inRow, findsOneWidget);
    });
  });
}
