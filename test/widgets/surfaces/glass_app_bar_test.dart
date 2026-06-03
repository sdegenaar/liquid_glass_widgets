import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassAppBar', () {
    testWidgets('can be instantiated with default parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(),
            ),
          ),
        ),
      );

      expect(find.byType(GlassAppBar), findsOneWidget);
    });

    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                title: Text('App Title'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('App Title'), findsOneWidget);
    });

    testWidgets('displays leading widget', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Scaffold(
              appBar: GlassAppBar(
                leading: GlassButton(
                  icon: Icon(Icons.menu),
                  onTap: () {},
                ),
                title: const Text('Title'),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('displays actions', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Scaffold(
              appBar: GlassAppBar(
                title: const Text('Title'),
                actions: [
                  GlassButton(icon: Icon(Icons.search), onTap: () {}),
                  GlassButton(icon: Icon(Icons.more_horiz), onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('centers title by default', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                title: Text('Centered'),
              ),
            ),
          ),
        ),
      );

      final center = tester.widget<Center>(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(Center),
        ),
      );

      expect(center, isNotNull);
    });

    testWidgets('left-aligns title when centerTitle is false', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                title: Text('Left'),
                centerTitle: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassAppBar), findsOneWidget);
    });

    testWidgets('applies background color', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                backgroundColor: Color(0xFF2C2C2E),
                title: Text('Solid'),
              ),
            ),
          ),
        ),
      );

      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, equals(const Color(0xFF2C2C2E)));
    });

    testWidgets('implements ObstructingPreferredSizeWidget', (tester) async {
      const appBar = GlassAppBar();
      expect(appBar, isA<PreferredSizeWidget>());
      expect(appBar, isA<ObstructingPreferredSizeWidget>());
    });

    testWidgets(
        'shouldFullyObstruct returns false for transparent background (default)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const Scaffold(appBar: GlassAppBar())),
      );

      final appBar = tester.widget<GlassAppBar>(find.byType(GlassAppBar));
      final context = tester.element(find.byType(GlassAppBar));
      expect(appBar.shouldFullyObstruct(context), isFalse);
    });

    testWidgets('shouldFullyObstruct returns true for fully opaque background',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            appBar: GlassAppBar(backgroundColor: Colors.black),
          ),
        ),
      );

      final appBar = tester.widget<GlassAppBar>(find.byType(GlassAppBar));
      final context = tester.element(find.byType(GlassAppBar));
      expect(appBar.shouldFullyObstruct(context), isTrue);
    });

    test('defaults are correct', () {
      const appBar = GlassAppBar();

      expect(appBar.centerTitle, isTrue);
      expect(appBar.backgroundColor, equals(Colors.transparent));
      expect(appBar.preferredSize, equals(const Size.fromHeight(44.0)));
    });

    testWidgets('renders as StatelessWidget (no glass rendering)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            appBar: GlassAppBar(
              title: Text('No Glass'),
            ),
          ),
        ),
      );

      // Should render without Opacity or Stack (no glass)
      expect(find.byType(GlassAppBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
    });

    testWidgets('wraps itself in GlassIsolationScope with isolated: true',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(title: Text('Test')),
            ),
          ),
        ),
      );

      // Find the GlassIsolationScope that is a descendant of GlassAppBar.
      final scope = tester.widget<GlassIsolationScope>(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(GlassIsolationScope),
        ),
      );
      expect(scope.isolated, isTrue,
          reason: 'GlassAppBar should self-isolate for Z-order correctness');
    });

    testWidgets('provides defaultQuality: premium via isolation scope',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(title: Text('Test')),
            ),
          ),
        ),
      );

      final scope = tester.widget<GlassIsolationScope>(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(GlassIsolationScope),
        ),
      );
      expect(scope.defaultQuality, equals(GlassQuality.premium),
          reason: 'App bar buttons should default to premium quality');
    });
  });
}
