// ignore_for_file: invalid_use_of_protected_member
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass_layer.dart';

// Regression coverage for the composite-time reconciliation in
// GeometryTransformTrackingLayer / RenderLiquidGlassLayer._updateAtComposite:
//
//  1. A glass layer that cannot reconcile at composite (no matte, capture
//     path, ...) must NOT keep requesting frames while nothing moves.
//  2. A nested glass layer must follow its enclosing backdrop pass when an
//     ancestor glass layer opens or closes that pass in the same paint flush
//     (the GlassModalSheet morph handoff: GlassIconButton inside the sheet).
//
// The glass needs ImageFilter.shader, which flutter_tester only has under
// Impeller:
//
//   flutter test --enable-impeller test/renderer/nested_pass_reconcile_test.dart
void main() {
  final skip = !ui.ImageFilter.isShaderFilterSupported;

  Future<void> initialize(WidgetTester tester) => tester.runAsync(
    () => LiquidGlassWidgets.initialize(
      enablePerformanceMonitor: false,
      warmUpMode: GlassWarmUpMode.always,
    ),
  );

  List<RenderLiquidGlassLayer> layersUnder(WidgetTester tester, Finder from) {
    final found = <RenderLiquidGlassLayer>[];
    void visit(RenderObject node) {
      if (node is RenderLiquidGlassLayer) found.add(node);
      node.visitChildren(visit);
    }

    visit(tester.renderObject(from));
    return found;
  }

  Widget host(Widget child) => LiquidGlassWidgets.wrap(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );

  const shape = LiquidRoundedSuperellipse(borderRadius: 24);

  testWidgets(
    'an idle glass layer that cannot reconcile requests no frames',
    skip: skip,
    (tester) async {
      await initialize(tester);
      // No blur and no thickness: the layer paints nothing and keeps no matte,
      // so _updateAtComposite has nothing to update and returns false.
      await tester.pumpWidget(
        host(
          GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.premium,
            settings: const LiquidGlassSettings(blur: 0, thickness: 0),
            width: 120,
            height: 48,
            shape: shape,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Precondition: this really is the "cannot reconcile" state.
      final layers = layersUnder(tester, find.byType(GlassContainer));
      expect(layers, hasLength(1));
      expect(layers.single.geometryImage, isNull);

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.binding.hasScheduledFrame,
          isFalse,
          reason: 'frame $i: an idle, unmoved layer must not repaint itself',
        );
      }
    },
  );

  testWidgets('an idle, ready glass layer requests no frames', skip: skip, (
    tester,
  ) async {
    await initialize(tester);
    await tester.pumpWidget(
      host(
        GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.premium,
          settings: const LiquidGlassSettings(blur: 8),
          width: 120,
          height: 48,
          shape: shape,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final layers = layersUnder(tester, find.byType(GlassContainer));
    expect(layers, hasLength(1));
    expect(layers.single.geometryImage, isNotNull);

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'frame $i: an idle, unmoved layer must not repaint itself',
      );
    }
  });

  testWidgets(
    'a nested glass layer follows its enclosing pass when the ancestor '
    'closes it',
    skip: skip,
    (tester) async {
      await initialize(tester);
      final outer = ValueNotifier(const LiquidGlassSettings(blur: 8));
      await tester.pumpWidget(
        host(
          ValueListenableBuilder<LiquidGlassSettings>(
            valueListenable: outer,
            builder: (context, settings, child) => GlassContainer(
              useOwnLayer: true,
              quality: GlassQuality.premium,
              settings: settings,
              width: 300,
              height: 300,
              shape: shape,
              child: child,
            ),
            child: Center(
              child: GlassContainer(
                useOwnLayer: true,
                quality: GlassQuality.premium,
                settings: const LiquidGlassSettings(blur: 8),
                width: 80,
                height: 48,
                shape: shape,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final layers = layersUnder(tester, find.byType(GlassContainer).first);
      expect(layers, hasLength(2), reason: 'outer and nested premium layers');
      final inner = layers.last;
      final openRect = inner.enclosingBackdropPassRect();
      expect(openRect, isNotNull, reason: 'nested inside the outer glass pass');
      expect(inner.debugUniformsPassRect, openRect);

      // The ancestor closes its pass (nothing left to render). The nested layer
      // is not itself dirtied by this; it must still end up on the root pass.
      outer.value = const LiquidGlassSettings(blur: 0, thickness: 0);
      await tester.pump();
      await tester.pump();
      expect(inner.enclosingBackdropPassRect(), isNull);
      expect(
        inner.debugUniformsPassRect,
        isNull,
        reason: 'uniforms were left written against the closed outer pass',
      );

      // ...and re-opens it.
      outer.value = const LiquidGlassSettings(blur: 8);
      await tester.pump();
      await tester.pump();
      expect(inner.debugUniformsPassRect, inner.enclosingBackdropPassRect());
      expect(inner.debugUniformsPassRect, isNotNull);
    },
  );
}
