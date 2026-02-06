import 'package:liquid_glass_widgets/widgets/interactive/glass_button.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/glass_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';

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
                  icon: Icons.menu,
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
                  GlassButton(icon: Icons.search, onTap: () {}),
                  GlassButton(icon: Icons.more_horiz, onTap: () {}),
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

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            appBar: GlassAppBar(
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
              title: Text('Standalone'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassAppBar), findsOneWidget);
    });

    testWidgets('implements PreferredSizeWidget', (tester) async {
      const appBar = GlassAppBar();
      expect(appBar, isA<PreferredSizeWidget>());
    });

    test('defaults are correct', () {
      const appBar = GlassAppBar();

      expect(appBar.centerTitle, isTrue);
      expect(appBar.backgroundColor, equals(Colors.transparent));
      expect(appBar.preferredSize, equals(const Size.fromHeight(44.0)));
      expect(appBar.useOwnLayer, isFalse);
      expect(appBar.quality, isNull);
    });
  });
}
