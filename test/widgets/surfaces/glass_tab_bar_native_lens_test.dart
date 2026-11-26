import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/rendering/liquid_glass_render_object.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/lens_content_warp.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/tab_bar_bottom_internal.dart';

import '../../shared/test_helpers.dart';

const _tabs = [
  GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
  GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
  GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
];

Widget _bar({
  GlassQuality quality = GlassQuality.premium,
  IndicatorLensOptics? indicatorLens,
}) {
  return createTestApp(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: GlassTabBar.bottom(
        tabs: _tabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
        quality: quality,
        indicatorLens: indicatorLens,
      ),
    ),
  );
}

void main() {
  tearDown(() => TabIndicator.debugNativeLensSupported = null);

  group('TabIndicator.supportsNativeLens', () {
    test('needs premium quality, high masking and no platform view', () {
      TabIndicator.debugNativeLensSupported = true;
      expect(
        TabIndicator.supportsNativeLens(
          quality: GlassQuality.premium,
          platformViewBackdrop: false,
          maskingQuality: MaskingQuality.high,
        ),
        isTrue,
      );
      expect(
        TabIndicator.supportsNativeLens(
          quality: GlassQuality.standard,
          platformViewBackdrop: false,
          maskingQuality: MaskingQuality.high,
        ),
        isFalse,
      );
      expect(
        TabIndicator.supportsNativeLens(
          quality: GlassQuality.premium,
          platformViewBackdrop: true,
          maskingQuality: MaskingQuality.high,
        ),
        isFalse,
      );
      expect(
        TabIndicator.supportsNativeLens(
          quality: GlassQuality.premium,
          platformViewBackdrop: false,
          maskingQuality: MaskingQuality.off,
        ),
        isFalse,
      );
    });

    test('follows the shader image filter support', () {
      TabIndicator.debugNativeLensSupported = false;
      expect(
        TabIndicator.supportsNativeLens(
          quality: GlassQuality.premium,
          platformViewBackdrop: false,
          maskingQuality: MaskingQuality.high,
        ),
        isFalse,
      );
    });
  });

  group('GlassTabBar.bottom native lens', () {
    testWidgets('keeps the single-pass lens where it cannot run',
        (tester) async {
      TabIndicator.debugNativeLensSupported = false;
      await tester.pumpWidget(_bar());
      expect(find.byType(LensContentWarp), findsNothing);
    });

    testWidgets('draws the selected items through the content warp',
        (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(_bar());
      expect(find.byType(LensContentWarp), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LensContentWarp),
          matching: find.text('Home'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('IndicatorLensOptics.disabled opts out', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(
        _bar(indicatorLens: IndicatorLensOptics.disabled),
      );
      expect(find.byType(LensContentWarp), findsNothing);
    });

    testWidgets('standard quality keeps the single-pass lens', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(_bar(quality: GlassQuality.standard));
      expect(find.byType(LensContentWarp), findsNothing);
    });

    testWidgets('survives a drag across the bar', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(_bar());
      final bar = tester.getRect(find.byType(GlassTabBar));
      final gesture = await tester.startGesture(
        Offset(bar.left + bar.width / 6, bar.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveBy(Offset(bar.width / 3, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LensContentWarp), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('GlassTabBar.bottom native lens stability', () {
    Widget host({
      required int count,
      required int selected,
      TextDirection direction = TextDirection.ltr,
      bool show = true,
      ValueChanged<int>? onTap,
    }) {
      return createTestApp(
        child: Directionality(
          textDirection: direction,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: show
                ? GlassTabBar.bottom(
                    tabs: [
                      for (var i = 0; i < count; i++)
                        GlassTab(
                          label: 'Tab $i',
                          icon: const Icon(CupertinoIcons.circle),
                        ),
                    ],
                    selectedIndex: selected,
                    onTabSelected: onTap ?? (_) {},
                    quality: GlassQuality.premium,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
    }

    testWidgets('rapid taps across every tab settle cleanly', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      var selected = 0;
      await tester.pumpWidget(host(count: 5, selected: selected));
      final bar = tester.getRect(find.byType(GlassTabBar));
      for (var round = 0; round < 3; round++) {
        for (var i = 0; i < 5; i++) {
          await tester.tapAt(
            Offset(bar.left + bar.width * (i + 0.5) / 5, bar.center.dy),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LensContentWarp), findsOneWidget);
    });

    testWidgets('a cancelled drag drops the lens without errors',
        (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(host(count: 4, selected: 1));
      final bar = tester.getRect(find.byType(GlassTabBar));
      final gesture = await tester.startGesture(bar.center);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('works right-to-left', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      int? tapped;
      await tester.pumpWidget(host(
        count: 4,
        selected: 0,
        direction: TextDirection.rtl,
        onTap: (i) => tapped = i,
      ));
      final bar = tester.getRect(find.byType(GlassTabBar));
      final gesture = await tester.startGesture(
        Offset(bar.right - bar.width / 8, bar.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(Offset(-bar.width / 4, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LensContentWarp), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tapped, 1);
    });

    testWidgets('can be removed while the lens is lifted', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(host(count: 3, selected: 0));
      final bar = tester.getRect(find.byType(GlassTabBar));
      final gesture = await tester.startGesture(
        Offset(bar.left + bar.width / 6, bar.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(Offset(bar.width / 3, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(host(count: 3, selected: 0, show: false));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LensContentWarp), findsNothing);
    });

    testWidgets('tab count and selection can change mid-drag', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(host(count: 5, selected: 0));
      final bar = tester.getRect(find.byType(GlassTabBar));
      final gesture = await tester.startGesture(
        Offset(bar.left + bar.width / 10, bar.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(Offset(bar.width / 5, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(host(count: 3, selected: 2));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(Offset(-bar.width / 5, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('GlassTabBar.inline takes the native lens too', (tester) async {
      TabIndicator.debugNativeLensSupported = true;
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.inline(
            tabs: _tabs,
            selectedIndex: 1,
            onTabSelected: (_) {},
            quality: GlassQuality.premium,
          ),
        ),
      );
      expect(find.byType(LensContentWarp), findsOneWidget);
    });
  });

  group('JellyClipper.lensGeometry', () {
    test('is the geometry getClip clips to', () {
      final clipper = JellyClipper(
        itemCount: 5,
        alignment: const Alignment(-0.5, 0),
        thickness: 1,
        expansion: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        transform: Matrix4.identity(),
        borderRadius: 9999,
        jelly: const IndicatorJelly(scaleX: 1.1, scaleY: 0.95, offsetX: 0.02),
      );
      const size = Size(360, 62);
      final lens = clipper.lensGeometry(size);
      final bounds = MatrixUtils.transformRect(
        lens.transform,
        lens.rrect.outerRect,
      );
      final clip = clipper.getClip(size).getBounds();
      expect(bounds.left, closeTo(clip.left, 0.5));
      expect(bounds.top, closeTo(clip.top, 0.5));
      expect(bounds.right, closeTo(clip.right, 0.5));
      expect(bounds.bottom, closeTo(clip.bottom, 0.5));
      expect(lens.rrect.outerRect.height, 54 + 16);
    });
  });

  group('lens warp transport', () {
    test('public settings carry no lens warp', () {
      expect(const LiquidGlassSettings().lensWarp, isNull);
    });

    test('copyWithLensWarp keeps every other value', () {
      const base = LiquidGlassSettings(thickness: 28, refractiveIndex: 1.17);
      const warp = (
        displacement: 9.0,
        bevel: 36.0,
        ovalization: 0.5,
        aberration: 2.7,
        aberrationBand: 14.0,
      );
      final warped = base.copyWithPinch(0.3).copyWithLensWarp(warp);
      expect(warped.lensWarp, warp);
      expect(warped.thickness, 28);
      expect(warped.refractiveIndex, 1.17);
      expect(warped.pinchStrength, 0.3);
      expect(warped, isNot(base.copyWithPinch(0.3)));
      expect(warped.copyWith(thickness: 20).lensWarp, warp);
      expect(warped.copyWithPinch(0.1).lensWarp, warp);
      expect(warped.copyWithLensWarp(null).lensWarp, isNull);
    });

    test('packs into physical pixels for the render shader', () {
      expect(
        LiquidGlassRenderObject.lensWarpUniforms(null, 3),
        everyElement(0),
      );
      final uniforms = LiquidGlassRenderObject.lensWarpUniforms(
        (
          displacement: 9.0,
          bevel: 36.0,
          ovalization: 0.5,
          aberration: 2.7,
          aberrationBand: 14.0,
        ),
        3,
      );
      expect(uniforms, hasLength(8));
      expect(uniforms[0], closeTo(27, 1e-9));
      expect(uniforms[1], closeTo(108, 1e-9));
      expect(uniforms[2], 0.5);
      expect(uniforms[3], 1.0);
      expect(uniforms[4], closeTo(8.1, 1e-9));
      expect(uniforms[5], closeTo(42, 1e-9));
    });
  });
}
