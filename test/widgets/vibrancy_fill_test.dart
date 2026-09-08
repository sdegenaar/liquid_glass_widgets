import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/internal/glass_materialize_scope.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_effect.dart';

import '../shared/test_helpers.dart';

void main() {
  const shape = LiquidRoundedSuperellipse(borderRadius: 16);
  const settings = LiquidGlassSettings(
    thickness: 20,
    blur: 10,
    glassColor: Color(0x33FFFFFF),
  );

  group('AdaptiveGlass.vibrancy', () {
    testWidgets('renders child and shape decoration correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveGlass.vibrancy(
            shape: shape,
            settings: settings,
            child: const Text('Nested Vibrancy Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nested Vibrancy Content'), findsOneWidget);
      // Verify DecoratedBox with ShapeDecoration is present
      final decoratedBoxes =
          tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(
        decoratedBoxes.any((box) => box.decoration is ShapeDecoration),
        isTrue,
      );
    });

    testWidgets(
        'routes to vibrancy when avoidsRefraction is true in GlassContainer',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassContainer(
            child: AdaptiveGlass(
              shape: shape,
              settings: settings,
              quality: GlassQuality.premium,
              child: const Text('Inner Glass in Container'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inner Glass in Container'), findsOneWidget);
      // Verify no BackdropFilter was created for the inner AdaptiveGlass
      // (only the outer GlassContainer may have one)
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('routes GlassEffect to vibrancy when avoidsRefraction is true',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: InheritedLiquidGlass(
            settings: settings,
            avoidsRefraction: true,
            child: GlassEffect(
              shape: shape,
              settings: settings,
              quality: GlassQuality.premium,
              interactionIntensity: 0.0,
              child: const Text('Inner GlassEffect'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inner GlassEffect'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('honours GlassBodyMode.clear without clamping alpha',
        (tester) async {
      const clearSettings = LiquidGlassSettings(
        glassColor: Color(0x05FFFFFF), // alpha ~0.02
        bodyMode: GlassBodyMode.clear,
      );

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveGlass.vibrancy(
            shape: shape,
            settings: clearSettings,
            child: const Text('Clear Mode'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clear Mode'), findsOneWidget);
      final decoratedBoxes =
          tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final shapeBox =
          decoratedBoxes.firstWhere((box) => box.decoration is ShapeDecoration);
      final decoration = shapeBox.decoration as ShapeDecoration;
      expect((decoration.color?.a ?? 0) <= 0.05, isTrue);
    });

    testWidgets('respects GlassMaterializeScope visibility', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassMaterializeScope(
            glassProgress: 0.0,
            contentOpacity: 0.0,
            contentSigma: 0.0,
            child: AdaptiveGlass.vibrancy(
              shape: shape,
              settings: settings,
              child: const Text('Materializing Content'),
            ),
          ),
        ),
      );
      await tester.pump();

      // At glassProgress 0.0, visibility is 0 -> should render zero opacity
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacityWidgets.any((op) => op.opacity == 0.0), isTrue);
    });

    testWidgets(
        'GlassCard inside GlassContainer routes to vibrancy fill without nested BackdropFilter',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassContainer(
            child: GlassCard(
              child: Text('Nested Card Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nested Card Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      final decoratedBoxes =
          tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(
        decoratedBoxes.any((box) => box.decoration is ShapeDecoration),
        isTrue,
      );
    });

    testWidgets(
        'GlassButton inside GlassContainer routes to vibrancy fill without nested BackdropFilter',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        createTestApp(
          child: GlassContainer(
            child: GlassButton.custom(
              onTap: () => pressed = true,
              child: const Text('Action Button'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Action Button'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      await tester.tap(find.text('Action Button'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });
}
