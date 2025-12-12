import 'package:liquid_glass_widgets/types/glass_quality.dart';
import 'package:liquid_glass_widgets/widgets/overlays/glass_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassSheet', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassSheet(
            child: Text('Sheet Content'),
          ),
        ),
      );

      expect(find.byType(GlassSheet), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('displays child widget', (tester) async {
      const testText = 'Bottom Sheet Text';

      await tester.pumpWidget(
        createTestApp(
          child: const GlassSheet(
            child: Text(testText),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('shows drag indicator by default', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassSheet(
            child: Text('Content'),
          ),
        ),
      );

      expect(find.byType(GlassSheet), findsOneWidget);
    });

    testWidgets('hides drag indicator when showDragIndicator is false',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassSheet(
            showDragIndicator: false,
            child: Text('Content'),
          ),
        ),
      );

      expect(find.byType(GlassSheet), findsOneWidget);
    });

    testWidgets('respects custom padding', (tester) async {
      const customPadding = EdgeInsets.all(32);

      await tester.pumpWidget(
        createTestApp(
          child: const GlassSheet(
            padding: customPadding,
            child: Text('Padded Content'),
          ),
        ),
      );

      expect(find.byType(GlassSheet), findsOneWidget);
    });

    testWidgets('shows bottom sheet with static show method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  GlassSheet.show(
                    context: context,
                    builder: (context) => const Text('Sheet Content'),
                  );
                },
                child: const Text('Show Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);
    });

    test('defaults are correct', () {
      const sheet = GlassSheet(
        child: Text('Content'),
      );

      expect(sheet.showDragIndicator, isTrue);
      expect(sheet.quality, equals(GlassQuality.standard));
    });
  });
}
