import 'package:liquid_glass_widgets/widgets/interactive/glass_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassSegmentedControl', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: const ['One', 'Two', 'Three'],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('displays all segments', (tester) async {
      const segments = ['Daily', 'Weekly', 'Monthly'];

      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: segments,
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      for (final segment in segments) {
        expect(find.text(segment), findsOneWidget);
      }
    });

    testWidgets('calls onSegmentSelected when tapping a segment',
        (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: const ['One', 'Two', 'Three'],
            selectedIndex: selectedIndex,
            onSegmentSelected: (index) => selectedIndex = index,
            useOwnLayer: true,
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
    });

    testWidgets('shows correct selected segment', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: const ['Option A', 'Option B', 'Option C'],
            selectedIndex: 1,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('respects custom height', (tester) async {
      const customHeight = 40.0;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: const ['One', 'Two'],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            height: customHeight,
            useOwnLayer: true,
          ),
        ),
      );

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('has proper semantics for each segment', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: const ['One', 'Two'],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      final semantics = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(GlassSegmentedControl),
          matching: find.byType(Semantics),
        ),
      );

      expect(semantics.length, greaterThan(0));
      expect(
        semantics.any((s) => s.properties.button == true),
        isTrue,
      );
    });

    test('defaults are correct', () {
      final control = GlassSegmentedControl(
        segments: const ['One', 'Two'],
        selectedIndex: 0,
        onSegmentSelected: (_) {},
      );

      expect(control.height, equals(32));
      expect(control.borderRadius, equals(16));
      expect(control.useOwnLayer, isFalse);
      expect(control.quality, isNull);
    });

    test('asserts minimum 2 segments', () {
      expect(
        () => GlassSegmentedControl(
          segments: const ['One'],
          selectedIndex: 0,
          onSegmentSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('asserts selectedIndex within bounds', () {
      expect(
        () => GlassSegmentedControl(
          segments: const ['One', 'Two'],
          selectedIndex: 5,
          onSegmentSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });
}
