// ignore_for_file: invalid_use_of_protected_member
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass_layer.dart';

// Glass that layout only moves is drawn at its new place in the same frame by
// RenderLiquidGlassLayer.updateAtComposite. Everything the glass is made of
// moved along with it, so nothing else is owed: no further frame, and no new
// geometry matte. These pin that down, and that a shape or a group that really
// moved relative to its layer still gets its matte rebuilt.
//
// The glass needs ImageFilter.shader, which flutter_tester only has under
// Impeller:
//
//   flutter test --enable-impeller test/renderer/layout_move_no_repaint_test.dart
void main() {
  final skip = !ui.ImageFilter.isShaderFilterSupported;

  Future<void> initialize(WidgetTester tester) => tester.runAsync(
    () => LiquidGlassWidgets.initialize(
      enablePerformanceMonitor: false,
      warmUpMode: GlassWarmUpMode.always,
    ),
  );

  RenderLiquidGlassLayer glassLayerIn(WidgetTester tester, Finder from) {
    final found = <RenderLiquidGlassLayer>[];
    void visit(RenderObject node) {
      if (node is RenderLiquidGlassLayer) found.add(node);
      node.visitChildren(visit);
    }

    visit(tester.renderObject(from));
    expect(found, hasLength(1));
    return found.single;
  }

  Widget moving(ValueNotifier<Offset> position, Widget child) =>
      ValueListenableBuilder<Offset>(
        valueListenable: position,
        // Built once, so moving it only re-lays out the Positioned.
        child: child,
        builder: (context, value, child) => Stack(
          children: [Positioned(left: value.dx, top: value.dy, child: child!)],
        ),
      );

  Widget host(Widget child) => LiquidGlassWidgets.wrap(
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );

  const shape = LiquidRoundedSuperellipse(borderRadius: 24);

  for (final settings in [
    LiquidGlassSettings.ios27Dark, // frost rows
    const LiquidGlassSettings(blur: 8), // no frost
  ]) {
    testWidgets(
      'glass that layout only moves schedules no frame and keeps its matte '
      '(frost ${settings.frost})',
      skip: skip,
      (tester) async {
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await initialize(tester);
        final position = ValueNotifier(const Offset(20, 21));
        await tester.pumpWidget(
          host(
            moving(
              position,
              GlassContainer(
                useOwnLayer: true,
                quality: GlassQuality.premium,
                settings: settings,
                width: 120,
                height: 48,
                shape: shape,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final layer = glassLayerIn(tester, find.byType(GlassContainer));
        final matte = layer.geometryImage;
        expect(matte, isNotNull);

        // Odd physical rows down, so the frost rows change phase too.
        position.value = const Offset(57, 22);
        await tester.pump();
        expect(
          tester.binding.hasScheduledFrame,
          isFalse,
          reason: 'a move the layer follows at composite owes no repaint',
        );
        await tester.pump();
        expect(
          identical(layer.geometryImage, matte),
          isTrue,
          reason: 'the matte is in local space and did not change',
        );
      },
    );
  }

  for (final boundaryBetween in [false, true]) {
    final suffix = boundaryBetween ? ' across a RepaintBoundary' : '';

    testWidgets(
      'a group that moved within its layer still rebuilds the matte$suffix',
      skip: skip,
      (tester) async {
        await initialize(tester);
        final position = ValueNotifier(const Offset(20, 21));
        Widget moved = moving(
          position,
          const LiquidGlass(
            shape: shape,
            child: SizedBox(width: 120, height: 48),
          ),
        );
        if (boundaryBetween) moved = RepaintBoundary(child: moved);
        await tester.pumpWidget(
          host(
            LiquidGlassLayer(
              settings: const LiquidGlassSettings(blur: 8),
              // A plain LiquidGlass is a group of its own, so the whole group moves.
              child: moved,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final layer = glassLayerIn(tester, find.byType(LiquidGlassLayer));
        final matte = layer.geometryImage;
        expect(matte, isNotNull);

        position.value = const Offset(57, 22);
        await tester.pump();
        if (!boundaryBetween) {
          expect(
            identical(layer.geometryImage, matte),
            isFalse,
            reason: 'rebuilt in the same frame when the layer paints',
          );
          expect(
            tester.binding.hasScheduledFrame,
            isFalse,
            reason: 'no second frame needed once the matte is already current',
          );
        } else {
          await tester.pump();
          expect(
            identical(layer.geometryImage, matte),
            isFalse,
            reason: 'wakes the enclosing glass layer across a RepaintBoundary',
          );
        }
      },
    );

    testWidgets(
      'a shape that moved within its group still rebuilds the matte$suffix',
      skip: skip,
      (tester) async {
        await initialize(tester);
        final position = ValueNotifier(const Offset(20, 21));
        Widget moved = moving(
          position,
          const LiquidGlass.grouped(
            shape: shape,
            child: SizedBox(width: 120, height: 48),
          ),
        );
        if (boundaryBetween) moved = RepaintBoundary(child: moved);
        await tester.pumpWidget(
          host(
            LiquidGlassLayer(
              settings: const LiquidGlassSettings(blur: 8),
              child: LiquidGlassBlendGroup(
                // Only the shape moves; the group stays where it is.
                child: moved,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final layer = glassLayerIn(tester, find.byType(LiquidGlassLayer));
        final matte = layer.geometryImage;
        expect(matte, isNotNull);

        position.value = const Offset(57, 22);
        await tester.pump();
        if (!boundaryBetween) {
          expect(
            identical(layer.geometryImage, matte),
            isFalse,
            reason: 'rebuilt in the same frame when the layer paints',
          );
          expect(
            tester.binding.hasScheduledFrame,
            isFalse,
            reason: 'no second frame needed once the matte is already current',
          );
        } else {
          await tester.pump();
          expect(
            identical(layer.geometryImage, matte),
            isFalse,
            reason: 'wakes the enclosing glass layer across a RepaintBoundary',
          );
        }
      },
    );
  }
}
