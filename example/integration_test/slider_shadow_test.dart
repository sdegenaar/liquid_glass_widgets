// Run on an Impeller device to verify the resting thumb remains visible on
// white and its premium press/drag/release path still works:
//   cd example && flutter test integration_test/slider_shadow_test.dart -d <device>
// To save screenshots under build/slider-shadow, use flutter drive with
// --driver=test_driver/slider_shadow_driver.dart --target=integration_test/slider_shadow_test.dart.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('premium thumb: rest, press, drag, release', (tester) async {
    await LiquidGlassWidgets.initialize();
    final boundaryKey = GlobalKey();
    var value = 0.5;
    int? restingShadowRed;
    for (final brightness in [Brightness.light, Brightness.dark]) {
      value = 0.5;
      await tester.pumpWidget(LiquidGlassWidgets.wrap(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: brightness),
          home: RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              backgroundColor:
                  brightness == Brightness.light ? Colors.white : Colors.black,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Premium slider — ${brightness.name}'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 300,
                      child: StatefulBuilder(builder: (context, setState) {
                        return GlassSlider(
                          value: value,
                          quality: GlassQuality.premium,
                          onChanged: (next) => setState(() => value = next),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      Future<ui.Image> snapshot(String phase) async {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        await binding.takeScreenshot('slider-${brightness.name}-$phase');
        return image;
      }

      final rest = await snapshot('rest');
      if (brightness == Brightness.light) {
        final slider = tester.widget<GlassSlider>(find.byType(GlassSlider));
        final rect = tester.getRect(find.byType(GlassSlider));
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final center = boundary.globalToLocal(rect.center);
        // Two logical pixels below the opaque pill: these pixels are outside
        // the glass clip, and should contain the thumb's soft shadow.
        final data = await rest.toByteData(format: ui.ImageByteFormat.rawRgba);
        final x = (center.dx * 3).round();
        final y = ((center.dy + slider.thumbRadius * 0.8 + 2) * 3).round();
        restingShadowRed = data!.getUint8((y * rest.width + x) * 4);
      }
      rest.dispose();

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(GlassSlider)));
      await tester.pumpAndSettle();
      (await snapshot('pressed')).dispose();
      for (var step = 0; step < 12; step++) {
        await gesture.moveBy(const Offset(5, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(value, greaterThan(0.5));
      (await snapshot('dragged')).dispose();
      await gesture.up();
      await tester.pumpAndSettle();
      (await snapshot('released')).dispose();
      expect(tester.takeException(), isNull);
    }
    expect(restingShadowRed, lessThan(245),
        reason: 'resting shadow extends beyond glass');
  });
}
