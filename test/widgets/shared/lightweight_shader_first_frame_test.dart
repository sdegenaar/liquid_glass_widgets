// A Standard-quality surface mounted before the lightweight shader program has
// loaded paints the shader-less fallback: a flat wash of its glassColor at 15%.
// On native nothing rebuilt it once the program loaded, so it kept that wash
// until an unrelated rebuild. A tinted glass button (glassColor at 85%,
// GlassBodyMode.clear) read as untinted glass on an app's first screen, and
// every other Standard surface lost its blur and rim there.
//
// A second surface mounted while the program was loading had a separate
// problem: preWarm() returned at once instead of with the load in flight.
//
// alwaysNeedsCompositing is @protected on RenderObject; reading it tells
// whether the render object holds the shader (blur > 0, no ancestor blur).
// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_effect.dart';

const _tinted = LiquidGlassSettings(
  blur: 3,
  glassColor: Color(0xD94F5BD5),
  bodyMode: GlassBodyMode.clear,
);

/// [count] tinted surfaces, as on an app's first screen.
Widget _surfaces({int count = 1}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            const LightweightLiquidGlass(
              shape: LiquidOval(),
              settings: _tinted,
              child: SizedBox(width: 44, height: 44),
            ),
        ],
      ),
    ),
  );
}

/// The surfaces' render objects, which paint the fallback while they hold
/// no shader.
List<RenderObject> _glass(WidgetTester tester) {
  final found = <RenderObject>[];
  void visit(RenderObject ro) {
    if (ro.runtimeType.toString() == '_RenderLightweightGlass') found.add(ro);
    ro.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
  expect(found, isNotEmpty);
  return found;
}

/// Whether each surface paints with the shader rather than the fallback.
List<bool> _hasShader(WidgetTester tester) =>
    [for (final ro in _glass(tester)) ro.alwaysNeedsCompositing];

void main() {
  setUp(LightweightLiquidGlass.resetForTesting);
  tearDown(LightweightLiquidGlass.resetForTesting);

  group('LightweightLiquidGlass before the shader program loads', () {
    testWidgets('a surface built first takes the shader once it loads',
        (tester) async {
      await tester.pumpWidget(_surfaces());
      expect(_hasShader(tester), [false], reason: 'the program is loading');

      // Wait for the load the surface started, then let its own
      // continuation run. Nothing here rebuilds the surface.
      await tester.runAsync(LightweightLiquidGlass.preWarm);
      await tester.pump();

      expect(_hasShader(tester), [true]);
      expect(_glass(tester).single.needsCompositing, isTrue);
    });

    testWidgets('surfaces built in the same frame all take the shader',
        (tester) async {
      // The first starts the load; the others join it.
      await tester.pumpWidget(_surfaces(count: 3));
      expect(_hasShader(tester), [false, false, false]);

      await tester.runAsync(LightweightLiquidGlass.preWarm);
      await tester.pump();

      expect(_hasShader(tester), [true, true, true]);
    });

    testWidgets(
        'selected GlassToggle.button chips on the first screen take the shader',
        (tester) async {
      // An app's first screen in dark mode, without awaiting
      // LiquidGlassWidgets.initialize() before runApp.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (label, selected) in const [
                    ('Mon', true),
                    ('Tue', false),
                    ('Wed', true),
                  ])
                    GlassToggle.button(
                      value: selected,
                      onChanged: (_) {},
                      label: label,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(_hasShader(tester), everyElement(isFalse));

      await tester.runAsync(LightweightLiquidGlass.preWarm);
      await tester.pump();

      expect(_hasShader(tester), everyElement(isTrue));
    });

    testWidgets('a surface built after the load has the shader at once',
        (tester) async {
      await tester.runAsync(LightweightLiquidGlass.preWarm);
      await tester.pumpWidget(_surfaces());

      expect(_hasShader(tester), [true]);
    });
  });

  group('preWarm during a load', () {
    test('LightweightLiquidGlass.preWarm returns the load in flight', () async {
      final first = LightweightLiquidGlass.preWarm();
      expect(LightweightLiquidGlass.preWarm(), same(first));
      await first;
    });

    test('GlassEffect.preWarm returns the load in flight', () async {
      GlassEffect.resetForTesting();
      addTearDown(GlassEffect.resetForTesting);
      final first = GlassEffect.preWarm();
      expect(GlassEffect.preWarm(), same(first));
      await first;
    });
  });
}
