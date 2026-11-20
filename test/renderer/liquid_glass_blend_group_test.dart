// Adapted from liquid_glass_renderer 0.2.0-dev.4
// Original: test/src/liquid_glass_blend_group_test.dart
// Changes:
//   - Import paths updated to liquid_glass_widgets internal paths
//   - Geometry golden image assertions removed (require Impeller; produce blank
//     images under the Skia test runner).
//   - Render-object tests skipped on Skia (ImageFilter.isShaderFilterSupported
//     is false in flutter test), since LiquidGlassBlendGroup now passes through
//     to its child without building _RawLiquidGlassBlendGroup on that backend.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass.dart';
import 'package:liquid_glass_widgets/src/engine/render_liquid_glass_geometry.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass_blend_group.dart';
import 'package:liquid_glass_widgets/src/engine/rendering/liquid_glass_render_object.dart';
import 'package:liquid_glass_widgets/src/renderer/glass_materialize_scope.dart';

void main() {
  group('LiquidGlassBlendGroup', () {
    const blendGroupKey = Key('blend-group');
    late GeometryRenderLink link;

    setUp(() {
      link = GeometryRenderLink();
    });

    tearDown(() {
      link.dispose();
    });

    Widget build(LiquidGlassSettings settings, double blend) {
      return CupertinoApp(
        home: LiquidGlassLayer(
          settings: settings,
          child: LiquidGlassBlendGroup(
            blend: blend,
            key: blendGroupKey,
            child: const Row(
              children: [
                LiquidGlass.grouped(
                  shape: LiquidOval(),
                  child: SizedBox.square(dimension: 100),
                ),
                LiquidGlass.grouped(
                  shape: LiquidRoundedSuperellipse(
                    borderRadius: 20,
                  ),
                  child: SizedBox.square(dimension: 100),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets(
        'widget tree builds without error for all settings combinations',
        (tester) async {
      // Smoke test: verifies no exception is thrown for any combination.
      // On Skia (test runner) the Impeller pipeline is skipped, so geometry is
      // never populated.  On Impeller the geometry cache should be present.
      final thicknesses = [10, 20, 30];
      final refractiveIndices = [1.0, 1.1, 1.2, 1.3];
      final blendValues = [0.0, 10, 20, 30, 300];

      Future<void> verifySettings(
        LiquidGlassSettings settings,
        double blend,
      ) async {
        await tester.pumpWidget(build(settings, blend));
        await tester.pumpAndSettle();

        expect(find.byKey(blendGroupKey), findsOneWidget);

        // Only assert geometry state when the Impeller pipeline ran.
        if (ImageFilter.isShaderFilterSupported) {
          final blendGroup = tester.firstWidget<LiquidGlassBlendGroup>(
            find.byKey(blendGroupKey),
          );
          final ro = tester.renderObject<RenderLiquidGlassBlendGroup>(
            find.byWidget(blendGroup),
          );
          if (ro.geometry != null) {
            expect(ro.geometry, isA<UnrenderedGeometryCache>());
          }
        }
      }

      // Zero thickness edge case
      await verifySettings(
        const LiquidGlassSettings(thickness: 0, refractiveIndex: 1.5),
        0,
      );

      for (final thickness in thicknesses) {
        for (final refractiveIndex in refractiveIndices) {
          for (final blend in blendValues) {
            await verifySettings(
              LiquidGlassSettings(
                thickness: thickness.toDouble(),
                refractiveIndex: refractiveIndex,
              ),
              blend.toDouble(),
            );
          }
        }
      }
    });

    testWidgets('blend group registers two grouped shapes', (tester) async {
      await tester.pumpWidget(
        build(const LiquidGlassSettings(thickness: 20), 20),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(blendGroupKey), findsOneWidget);

      // Render-object inspection only possible when Impeller pipeline ran.
      if (!ImageFilter.isShaderFilterSupported) return;

      final blendGroup = tester.firstWidget<LiquidGlassBlendGroup>(
        find.byKey(blendGroupKey),
      );
      final ro = tester.renderObject<RenderLiquidGlassBlendGroup>(
        find.byWidget(blendGroup),
      );

      expect(ro.link.shapeEntries.length, 2);
    });

    testWidgets('blend property update is reflected on render object',
        (tester) async {
      await tester.pumpWidget(
        build(const LiquidGlassSettings(thickness: 20), 10),
      );
      await tester.pumpAndSettle();

      if (!ImageFilter.isShaderFilterSupported) return;

      final blendGroup = tester.firstWidget<LiquidGlassBlendGroup>(
        find.byKey(blendGroupKey),
      );
      final ro = tester.renderObject<RenderLiquidGlassBlendGroup>(
        find.byWidget(blendGroup),
      );

      final geometryBefore = ro.geometry;

      await tester.pumpWidget(
        build(const LiquidGlassSettings(thickness: 20), 80),
      );
      await tester.pumpAndSettle();

      expect(ro.blend, 80);
      if (geometryBefore != null) {
        expect(ro.geometry, isNot(same(geometryBefore)));
      }
    });

    testWidgets('blend group disposes cleanly when removed from tree',
        (tester) async {
      await tester.pumpWidget(
        build(const LiquidGlassSettings(thickness: 20), 20),
      );
      await tester.pumpAndSettle();

      // Replace tree — blend group should be removed without crash.
      await tester.pumpWidget(const CupertinoApp(home: SizedBox()));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'inner GlassMaterializeScope unregisters dematerialized grouped shape without double-scaling outer scope (#504)',
        (tester) async {
      var innerGlassProgress = 1.0;
      late StateSetter updateScope;

      await tester.pumpWidget(
        CupertinoApp(
          home: GlassMaterializeScope(
            glassProgress: 0.5,
            contentOpacity: 1.0,
            contentSigma: 0.0,
            child: StatefulBuilder(
              builder: (context, setState) {
                updateScope = setState;
                return LiquidGlassLayer(
                  settings: const LiquidGlassSettings(thickness: 20),
                  child: LiquidGlassBlendGroup(
                    key: blendGroupKey,
                    blend: 20,
                    child: Row(
                      children: [
                        const LiquidGlass.grouped(
                          key: ValueKey('shape-a'),
                          shape: LiquidOval(),
                          child: SizedBox.square(dimension: 60),
                        ),
                        GlassMaterializeScope(
                          glassProgress: innerGlassProgress * 0.5,
                          contentOpacity: innerGlassProgress,
                          contentSigma: 0.0,
                          child: const LiquidGlass.grouped(
                            key: ValueKey('shape-b'),
                            shape: LiquidOval(),
                            child: SizedBox.square(dimension: 60),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (!ImageFilter.isShaderFilterSupported) return;

      final ro = tester.renderObject<RenderLiquidGlassBlendGroup>(
        find.byKey(blendGroupKey),
      );
      final shapeAChildOpacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byKey(const ValueKey('shape-a')),
          matching: find.byType(Opacity),
        ),
      );
      // Outer scope (0.5) applied once (not 0.25!).
      expect(shapeAChildOpacity.opacity, closeTo(0.5, 0.001));
      expect(ro.maybeRebuildGeometry()?.shapes.length, 2);

      // Dematerialize only shape-b via inner GlassMaterializeScope -> excluded from geometry matte!
      updateScope(() => innerGlassProgress = 0.0);
      await tester.pumpAndSettle();
      expect(ro.link.shapeEntries.length, 2);
      expect(ro.maybeRebuildGeometry()?.shapes.length, 1);

      // Restore shape-b -> rejoins geometry matte in original order!
      updateScope(() => innerGlassProgress = 1.0);
      await tester.pumpAndSettle();
      expect(ro.maybeRebuildGeometry()?.shapes.length, 2);
    });
  });
}
