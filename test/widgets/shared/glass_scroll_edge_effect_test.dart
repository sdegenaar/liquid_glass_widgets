import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassScrollEdgeEffect', () {
    testWidgets('renders children and overlays', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 500,
              width: 300,
              child: GlassScrollEdgeEffect(
                topFadeHeight: 100,
                bottomFadeHeight: 60,
                // Use a non-scrollable child to prevent scrollbar widgets from messing up counts
                child: const SizedBox(key: Key('child')),
              ),
            ),
          ),
        ),
      );

      // Verify child is rendered
      expect(find.byKey(const Key('child')), findsOneWidget);

      final effectFinder = find.byType(GlassScrollEdgeEffect);

      // Verify the two fade overlays are created
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(of: effectFinder, matching: find.byType(DecoratedBox)),
      );
      expect(decoratedBoxes.length, 2);

      // Verify they are positioned correctly
      final positionedWidgets = tester.widgetList<Positioned>(
        find.descendant(of: effectFinder, matching: find.byType(Positioned)),
      );
      expect(positionedWidgets.length, 2);

      final topOverlay = positionedWidgets.firstWhere((p) => p.top == 0);
      final bottomOverlay = positionedWidgets.firstWhere((p) => p.bottom == 0);

      expect(topOverlay.height, 100);
      expect(bottomOverlay.height, 60);
    });

    testWidgets('respects fadeTop and fadeBottom flags', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              height: 500,
              width: 300,
              child: GlassScrollEdgeEffect(
                topFadeHeight: 100,
                bottomFadeHeight: 60,
                fadeTop: false,
                fadeBottom: false,
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      final effectFinder = find.byType(GlassScrollEdgeEffect);
      expect(
        find.descendant(of: effectFinder, matching: find.byType(Positioned)),
        findsNothing,
      );
    });

    testWidgets('clamps overlay height to 40% of screen height',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassScrollEdgeEffect(
            topFadeHeight: 500, // greater than 600 * 0.4 (240)
            bottomFadeHeight: 500,
            child: const SizedBox(),
          ),
        ),
      );

      final effectFinder = find.byType(GlassScrollEdgeEffect);
      final positionedWidgets = tester.widgetList<Positioned>(
        find.descendant(of: effectFinder, matching: find.byType(Positioned)),
      );
      final topOverlay = positionedWidgets.firstWhere((p) => p.top == 0);

      expect(topOverlay.height, 240); // 600 * 0.4
    });

    testWidgets('applies hard style height adjustment (0.5x)', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassScrollEdgeEffect(
            topFadeHeight: 100,
            style: GlassScrollEdgeStyle.hard,
            fadeBottom: false,
            child: const SizedBox(),
          ),
        ),
      );

      final effectFinder = find.byType(GlassScrollEdgeEffect);
      final positionedWidgets = tester.widgetList<Positioned>(
        find.descendant(of: effectFinder, matching: find.byType(Positioned)),
      );
      final topOverlay = positionedWidgets.firstWhere((p) => p.top == 0);

      // 100 * 0.5 = 50
      expect(topOverlay.height, 50);
    });

    testWidgets('uses provided fadeColor', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassScrollEdgeEffect(
            fadeColor: const Color(0xFFFF0000),
            child: const SizedBox(),
          ),
        ),
      );

      final effectFinder = find.byType(GlassScrollEdgeEffect);
      final decoratedBox = tester.firstWidget<DecoratedBox>(
        find.descendant(of: effectFinder, matching: find.byType(DecoratedBox)),
      );
      final gradient = decoratedBox.decoration as BoxDecoration;
      final linearGradient = gradient.gradient as LinearGradient;

      expect(linearGradient.colors.first.r, 1.0);
      expect(linearGradient.colors.first.g, 0.0);
      expect(linearGradient.colors.first.b, 0.0);
    });

    testWidgets('attempts background capture within LiquidGlassScope',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Scaffold(
            body: LiquidGlassScope(
              child: Stack(
                children: [
                  GlassBackgroundSource(
                    child: SizedBox(
                        width: 800,
                        height: 600,
                        child: ColoredBox(color: Colors.red)),
                  ),
                  GlassScrollEdgeEffect(
                    child: const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Wait for post-frame callbacks to execute
      await tester.pumpAndSettle();

      expect(find.byType(GlassScrollEdgeEffect), findsOneWidget);
    });
  });
}
