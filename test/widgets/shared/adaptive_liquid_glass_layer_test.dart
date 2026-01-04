import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';
import 'package:liquid_glass_widgets/widgets/shared/inherited_liquid_glass.dart';

void main() {
  testWidgets('AdaptiveLiquidGlassLayer provides settings to descendants',
      (WidgetTester tester) async {
    const double expectedBlur = 25.0;
    const double expectedThickness = 50.0;

    LiquidGlassSettings? receivedSettings;

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveLiquidGlassLayer(
          settings: const LiquidGlassSettings(
            blur: expectedBlur,
            thickness: expectedThickness,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 0),
          child: Builder(
            builder: (context) {
              // Capture the settings available in the context
              receivedSettings = InheritedLiquidGlass.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(receivedSettings, isNotNull);
    expect(receivedSettings!.blur, equals(expectedBlur));
    expect(receivedSettings!.thickness, equals(expectedThickness));
  });

  testWidgets('AdaptiveLiquidGlassLayer fallback works with ofOrDefault',
      (WidgetTester tester) async {
    const double expectedBlur = 15.0;

    late LiquidGlassSettings settings;

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveLiquidGlassLayer(
          settings: const LiquidGlassSettings(blur: expectedBlur),
          shape: const LiquidRoundedSuperellipse(borderRadius: 0),
          child: Builder(
            builder: (context) {
              // This is what LightweightLiquidGlass uses
              settings = InheritedLiquidGlass.ofOrDefault(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(settings.blur, equals(expectedBlur));
  });

  testWidgets('AdaptiveLiquidGlassLayer works without shape parameter',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdaptiveLiquidGlassLayer(
          child: SizedBox(),
        ),
      ),
    );

    expect(find.byType(AdaptiveLiquidGlassLayer), findsOneWidget);
  });
}
