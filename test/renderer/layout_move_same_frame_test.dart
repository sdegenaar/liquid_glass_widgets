import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass_layer.dart';

// Glass that layout only moves keeps its layers: its repaint boundary (or an
// ancestor's, a list item's say) is reused without a paint, so the shader's
// screen-space uniforms have to follow it while the frame is composited, or
// the glass is drawn at its previous position for one frame (#418).
//
// Premium glass needs ImageFilter.shader, which flutter_tester only has under
// Impeller:
//
//   flutter test --enable-impeller test/renderer/layout_move_same_frame_test.dart
void main() {
  for (final settings in [
    LiquidGlassSettings.ios27Dark, // frost rows
    const LiquidGlassSettings(blur: 8), // no frost
  ]) {
    for (final ancestorBoundary in [false, true]) {
      testWidgets(
        'glass that layout only moves draws at its new place in the same '
        'frame (frost ${settings.frost}, '
        '${ancestorBoundary ? 'in a RepaintBoundary' : 'alone'})',
        skip: !ui.ImageFilter.isShaderFilterSupported,
        (tester) async {
          // The odd number of physical rows the glass moves below depends on it.
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.runAsync(
            () => LiquidGlassWidgets.initialize(
              enablePerformanceMonitor: false,
              warmUpMode: GlassWarmUpMode.always,
            ),
          );
          final position = ValueNotifier<Offset>(const Offset(20, 21));
          final boundary = GlobalKey();
          // Built once: moving it relayouts the Positioned, it doesn't rebuild
          // or repaint the glass, so the layers it painted are reused.
          Widget glass = GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.premium,
            settings: settings,
            width: 120,
            height: 48,
            shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          );
          if (ancestorBoundary) glass = RepaintBoundary(child: glass);
          await tester.pumpWidget(
            LiquidGlassWidgets.wrap(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: RepaintBoundary(
                  key: boundary,
                  child: CustomPaint(
                    painter: _Stripes(),
                    child: ValueListenableBuilder<Offset>(
                      valueListenable: position,
                      builder: (context, value, child) => Stack(
                        children: [
                          Positioned(
                            left: value.dx,
                            top: value.dy,
                            child: child!,
                          ),
                        ],
                      ),
                      child: glass,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          Future<Uint8List> snapshot() async {
            final ro =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final bytes = await tester.runAsync(() async {
              final image = await ro.toImage();
              final data = await image.toByteData();
              image.dispose();
              return data!.buffer.asUint8List();
            });
            return bytes!;
          }

          // Repaints the glass at rest, so the reference doesn't rely on some
          // other change repainting it. Twice: the first paint after the glass
          // is built or moved draws its shadows live, up to 2/255 off the baked
          // image the paints after it draw.
          Future<void> repaint() async {
            for (var i = 0; i < 2; i++) {
              for (final glassLayer
                  in tester.allRenderObjects
                      .whereType<RenderLiquidGlassLayer>()) {
                glassLayer.markNeedsPaint();
              }
              await tester.pumpAndSettle();
            }
          }

          await repaint();
          // An odd number of physical rows down (dpr 3), so the frost rows
          // change phase too.
          position.value = const Offset(57, 22);
          await tester.pump(); // the frame that moves the glass
          // Everything that changed was added to that frame's scene: no layer
          // is left waiting under a parent the frame retained as is. (A
          // snapshot rebuilds the scene and would hide that, so check before
          // taking one.)
          final root =
              (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .debugLayer!;
          expect(_notAddedToScene(root), isEmpty);
          final moved = await snapshot();
          await repaint();
          final settled = await snapshot();

          var differing = 0;
          for (var i = 0; i < moved.length; i++) {
            if (moved[i] != settled[i]) differing++;
          }
          expect(moved.length, settled.length);
          expect(
            differing,
            0,
            reason:
                'bytes of the moved frame that differ from a repaint '
                'at rest',
          );
        },
      );
    }
  }
}

/// Layers whose changes the last composited frame did not add to its scene.
List<Layer> _notAddedToScene(Layer layer) => [
  if (layer.debugSubtreeNeedsAddToScene ?? false) layer,
  if (layer is ContainerLayer)
    for (
      Layer? child = layer.firstChild;
      child != null;
      child = child.nextSibling
    )
      ..._notAddedToScene(child),
];

/// A backdrop with enough contrast that a shifted refraction shows.
class _Stripes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 6;
    for (var i = 0; i < 40; i++) {
      paint.color = i.isEven
          ? const Color(0xFF0E4A5C)
          : const Color(0xFF8FC9D9);
      canvas.drawLine(
        Offset(i * 24.0, 0),
        Offset(i * 24.0 + 120, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Stripes oldDelegate) => false;
}
