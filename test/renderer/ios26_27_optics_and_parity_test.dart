import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/glass_face_optics.dart';
import 'package:liquid_glass_widgets/src/renderer/glass_backdrop_group_boundary.dart';

void main() {
  group('Phase 1 — Parity fixes & clear glass presets', () {
    testWidgets('LiquidGlassSettings.clear resolves ios26Clear vs ios27Clear',
        (tester) async {
      late LiquidGlassSettings resolved26;
      late LiquidGlassSettings resolved27;

      await tester.pumpWidget(
        GlassTheme(
          data: GlassThemeData.ios26(),
          child: CupertinoApp(
            home: Builder(
              builder: (context) {
                resolved26 = LiquidGlassSettings.clear(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved26, equals(LiquidGlassSettings.ios26Clear));
      expect(resolved26.blur, closeTo(1.8, 0.01));
      expect(resolved26.frost, equals(0.0));
      expect(resolved26.sizeAdaptive, isFalse);

      await tester.pumpWidget(
        GlassTheme(
          data: GlassThemeData.ios27(),
          child: CupertinoApp(
            home: Builder(
              builder: (context) {
                resolved27 = LiquidGlassSettings.clear(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved27, equals(LiquidGlassSettings.ios27Clear));
      expect(resolved27.blur, closeTo(0.75, 0.01));
      expect(resolved27.saturation, closeTo(1.06, 0.01));
      expect(resolved27.frost, equals(0.0));
    });

    testWidgets(
        'GlassSlider dims at 0.5 opacity when disabled (onChanged null)',
        (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: SizedBox(
              width: 240,
              child: GlassSlider(
                value: 0.5,
                onChanged: null,
              ),
            ),
          ),
        ),
      );

      final opacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(GlassSlider),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacities.any((o) => o.opacity == 0.5), isTrue);
    });

    testWidgets(
        'GlassSegmentedControl(enabled: false) blocks taps and dims in fixed & scrollable modes',
        (tester) async {
      var selected = 0;

      // Fixed mode
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              width: 260,
              child: GlassSegmentedControl(
                segments: const [
                  GlassSegment(label: 'One'),
                  GlassSegment(label: 'Two'),
                ],
                selectedIndex: selected,
                enabled: false,
                onSegmentSelected: (i) => selected = i,
              ),
            ),
          ),
        ),
      );

      final fixedOpacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(GlassSegmentedControl),
          matching: find.byType(Opacity),
        ),
      );
      expect(fixedOpacities.any((o) => o.opacity == 0.5), isTrue);

      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(selected, equals(0));

      // Scrollable mode
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              width: 260,
              child: GlassSegmentedControl.scrollable(
                segments: const [
                  GlassSegment(label: 'Alpha'),
                  GlassSegment(label: 'Beta'),
                  GlassSegment(label: 'Gamma'),
                ],
                selectedIndex: selected,
                enabled: false,
                onSegmentSelected: (i) => selected = i,
              ),
            ),
          ),
        ),
      );

      final scrollOpacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(GlassSegmentedControl),
          matching: find.byType(Opacity),
        ),
      );
      expect(scrollOpacities.any((o) => o.opacity == 0.5), isTrue);

      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(selected, equals(0));
    });

    testWidgets(
        'GlassIconButton prominent defaults to primaryColor contrast when enabled and neutral label when disabled',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: CupertinoColors.systemBlue,
          ),
          home: Center(
            child: GlassIconButton(
              icon: const Icon(CupertinoIcons.plus),
              style: GlassButtonStyle.prominent,
              onPressed: () {},
            ),
          ),
        ),
      );

      final enabledIcon = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(IconTheme),
            )
            .last,
      );
      expect(enabledIcon.data.color, equals(CupertinoColors.white));

      await tester.pumpWidget(
        const CupertinoApp(
          theme: CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: CupertinoColors.systemBlue,
          ),
          home: Center(
            child: GlassIconButton(
              icon: Icon(CupertinoIcons.plus),
              style: GlassButtonStyle.prominent,
              onPressed: null,
            ),
          ),
        ),
      );

      final disabledIcon = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(IconTheme),
            )
            .last,
      );
      expect(disabledIcon.data.color, isNot(equals(CupertinoColors.white)));
    });
  });

  group('Phase 2 — CoreAnimation glassFace & size-adaptive optics', () {
    test('iOS 27 dark matches live CoreAnimation maxLuma ramp (64..104 pt)',
        () {
      final small44 = resolveGlassFaceOptics(LiquidGlassSettings.ios27Dark, 44);
      final edge66 = resolveGlassFaceOptics(LiquidGlassSettings.ios27Dark, 66);
      final med100 = resolveGlassFaceOptics(LiquidGlassSettings.ios27Dark, 100);
      final large160 =
          resolveGlassFaceOptics(LiquidGlassSettings.ios27Dark, 160);

      expect(small44.isActive, isTrue);
      expect(small44.faceBlack, closeTo(0.125, 1e-4));
      expect(small44.faceWhite, closeTo(1.125, 1e-4));
      expect(small44.faceChroma, closeTo(1.30, 1e-4));
      expect(small44.faceMaxLuma, closeTo(0.60, 1e-4));
      expect(small44.bleedStrength, equals(0.0));

      expect(edge66.faceMaxLuma, closeTo(0.5875, 1e-4));
      expect(med100.faceMaxLuma, closeTo(0.375, 1e-4));
      expect(large160.faceMaxLuma, closeTo(0.35, 1e-4));
      expect(large160.bleedStrength, closeTo(0.80, 1e-4));
      expect(large160.bleedSign, equals(-1.0));
    });

    test('iOS 27 light matches live CoreAnimation glassBackground constants',
        () {
      final small44 =
          resolveGlassFaceOptics(LiquidGlassSettings.ios27Light, 44);
      final large160 =
          resolveGlassFaceOptics(LiquidGlassSettings.ios27Light, 160);

      expect(small44.isActive, isTrue);
      expect(small44.faceBlack, closeTo(0.40, 1e-4));
      expect(small44.faceWhite, closeTo(1.03, 1e-4));
      expect(small44.faceMaxLuma, closeTo(0.94, 1e-4));
      expect(small44.faceFillAlpha, closeTo(0.20, 1e-4));
      expect(small44.faceChroma, closeTo(1.20, 1e-4));
      expect(small44.bleedStrength, equals(0.0));

      expect(large160.bleedStrength, closeTo(0.50, 1e-4));
      expect(large160.bleedSign, equals(1.0));
    });

    test('iOS 26 dark darkens bright backdrops across small and large platters',
        () {
      final small44 = resolveGlassFaceOptics(LiquidGlassSettings.ios26Dark, 44);
      final large160 =
          resolveGlassFaceOptics(LiquidGlassSettings.ios26Dark, 160);

      expect(small44.isActive, isTrue);
      expect(small44.faceWhite, lessThan(0.75));
      expect(small44.faceFillAlpha, lessThan(0.0));
      expect(large160.faceWhite, lessThan(small44.faceWhite));
      expect(large160.faceFillAlpha, lessThan(small44.faceFillAlpha));
    });

    test('disabled for custom, classic, clear, and GlassBodyMode.clear', () {
      for (final s in [
        const LiquidGlassSettings(),
        LiquidGlassSettings.classicLight,
        LiquidGlassSettings.classicDark,
        LiquidGlassSettings.ios26Clear,
        LiquidGlassSettings.ios27Clear,
        LiquidGlassSettings.ios27Dark.copyWith(sizeAdaptive: false),
        LiquidGlassSettings.ios27Dark.copyWith(bodyMode: GlassBodyMode.clear),
      ]) {
        final r = resolveGlassFaceOptics(s, 100);
        expect(r.isActive, isFalse);
      }
    });

    test('visibility dissolves face optics smoothly and frost quantizes to 0.5',
        () {
      final half = resolveGlassFaceOptics(
        LiquidGlassSettings.ios27Dark.copyWith(visibility: 0.5),
        160,
      );
      expect(half.faceBlack, closeTo(0.0625, 1e-4));
      expect(half.faceMaxLuma, closeTo(0.675, 1e-4));

      final full27 = resolveGlassFaceOptics(LiquidGlassSettings.ios27Dark, 100);
      expect(full27.effectiveFrostSigma,
          equals(LiquidGlassSettings.ios27Dark.effectiveFrost));

      final full26 = resolveGlassFaceOptics(LiquidGlassSettings.ios26Dark, 160);
      expect(full26.effectiveFrostSigma,
          greaterThan(LiquidGlassSettings.ios26Dark.effectiveFrost));
      expect((full26.effectiveFrostSigma * 2.0) % 1.0, equals(0.0));
    });

    test(
        'GlassModalSheet fade-to-zero and custom achromatic glassColor overrides disable/dissolve uFace cleanly',
        () {
      // Dormant / fully expanded GlassModalSheet zeroes frost/blur/thickness/alpha
      // without changing visibility — uFace MUST deactivate completely.
      final dormantSheet = LiquidGlassSettings.ios27Light.copyWith(
        glassColor: LiquidGlassSettings.ios27Light.glassColor.withValues(
          alpha: 0.0,
        ),
        blur: 0.0,
        frost: 0.0,
        thickness: 0.0,
        rimShade: 0.0,
        rimLight: 0.0,
      );
      expect(resolveGlassFaceOptics(dormantSheet, 160).isActive, isFalse);

      // Mid-fade GlassModalSheet scales glassColor.a by 0.5 -> face dissolves 50%.
      final halfFadedDark = LiquidGlassSettings.ios27Dark.copyWith(
        glassColor: LiquidGlassSettings.ios27Dark.glassColor.withValues(
          alpha: LiquidGlassSettings.ios27Dark.glassColor.a * 0.5,
        ),
        frost: LiquidGlassSettings.ios27Dark.frost * 0.5,
        rimShade: LiquidGlassSettings.ios27Dark.rimShade * 0.5,
      );
      final halfResolved = resolveGlassFaceOptics(halfFadedDark, 160);
      expect(halfResolved.isActive, isTrue);
      expect(halfResolved.faceBlack, closeTo(0.0625, 1e-3));
      expect(halfResolved.faceMaxLuma, closeTo(0.675, 1e-3));

      // Explicit custom achromatic override (e.g. higher alpha white or dark grey)
      // disables uFace so user's custom glassColor is never silently ignored.
      final customWhite = LiquidGlassSettings.ios27Light.copyWith(
        glassColor: const Color(0xE0FFFFFF),
      );
      expect(resolveGlassFaceOptics(customWhite, 100).isActive, isFalse);

      final customDark = LiquidGlassSettings.ios27Dark.copyWith(
        glassColor: const Color(0x99111111),
      );
      expect(resolveGlassFaceOptics(customDark, 100).isActive, isFalse);

      // Chromatic tint layered on top of an era preset keeps uFace active
      // (so applyGlassColorBracketed blends cleanly on top of glassFace).
      final chromaticTint = LiquidGlassSettings.ios27Dark.copyWith(
        glassColor: const Color(0x66007AFF),
      );
      expect(resolveGlassFaceOptics(chromaticTint, 100).isActive, isTrue);
    });
  });

  group('Phase 3 — Hoist host & premultiplied content-aware luma', () {
    testWidgets(
        'GlassBackdropHoistOptOut opts out of hoisting without leaving GlassBackdropGroup',
        (tester) async {
      BackdropKey? keyInside;
      bool? optedOut;
      await tester.pumpWidget(
        GlassBackdropGroup(
          child: GlassBackdropHoistOptOut(
            child: Builder(
              builder: (context) {
                keyInside = GlassBackdropGroup.keyOf(context);
                optedOut = GlassBackdropHoistOptOut.isOptedOut(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(keyInside, isNotNull);
      expect(optedOut, isTrue);
    });
    testWidgets(
        'GlassBackdropHoistSlot attaches cleanly to RenderGlassBackdropGroupBoundary and cleans up on detach',
        (tester) async {
      await tester.pumpWidget(
        const GlassBackdropGroup(
          child: Stack(
            textDirection: TextDirection.ltr,
            children: [
              Positioned.fill(child: GlassBackdropHoistSlot()),
            ],
          ),
        ),
      );

      final boundary = tester.renderObject<RenderGlassBackdropGroupBoundary>(
        find.byType(GlassBackdropGroupBoundary),
      );
      expect(boundary.hasHoistHost, isTrue);
      expect(boundary.hoistedCount, equals(0));

      // Verify overlap tracking on boundary
      final layerA = OffsetLayer();
      final layerB = OffsetLayer();
      final tokenA = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(),
      );
      final tokenB = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(),
      );
      addTearDown(() {
        tokenA.dispose();
        tokenB.dispose();
      });

      boundary.setHoisted(tokenA, layerA, const Rect.fromLTWH(0, 0, 100, 44));
      expect(boundary.hoistedCount, equals(1));
      expect(
        boundary.overlapsOtherHoisted(
          tokenB,
          const Rect.fromLTWH(50, 0, 100, 44),
        ),
        isTrue,
      );
      expect(
        boundary.overlapsOtherHoisted(
          tokenB,
          const Rect.fromLTWH(0, 200, 100, 44),
        ),
        isFalse,
      );

      boundary.setHoisted(tokenB, layerB, const Rect.fromLTWH(0, 200, 100, 44));
      expect(boundary.hoistedCount, equals(2));

      boundary.removeHoisted(tokenA);
      expect(boundary.hoistedCount, equals(1));

      // Regression guard: repainting the hoist slot (e.g. when sibling body
      // content or scaffold state changes while a hoisted GlassTabBar sits
      // behind a clean RepaintBoundary) MUST preserve already-hoisted layers
      // rather than wiping them via PaintingContext.pushLayer.
      final slot = tester.renderObject<RenderGlassBackdropHoistSlot>(
        find.byType(GlassBackdropHoistSlot),
      );
      slot.markNeedsPaint();
      await tester.pump();
      expect(layerB.parent, isNotNull);
      expect(boundary.hoistedCount, equals(1));

      // Detaching removes all hoisted layers cleanly.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(boundary.hasHoistHost, isFalse);
      expect(boundary.hoistedCount, equals(0));
    });

    test(
        'GlassContentAwareScope.computeVerdict composites premultiplied alpha accurately over background',
        () {
      // 2x2 semi-transparent white overlay: premultiplied rgba = (128,128,128,128)
      final rgba = Uint8List.fromList(
        List.generate(16, (_) => 128),
      );
      final cells = [const Rect.fromLTWH(0, 0, 2, 2)];

      // Over a white background: 0.5 + 1.0 * 0.5 = 1.0 -> stays light!
      final overWhite = GlassContentAwareScope.computeVerdict(
        rgba: rgba,
        width: 2,
        height: 2,
        cellRects: cells,
        current: Brightness.dark,
        lightToDarkThreshold: 0.6,
        darkToLightThreshold: 0.6,
        background: const Color(0xFFFFFFFF),
      );
      expect(overWhite, equals(Brightness.light));

      // Fully transparent pixel (0,0,0,0) over black -> votes dark.
      final transparent = Uint8List(16);
      final overBlack = GlassContentAwareScope.computeVerdict(
        rgba: transparent,
        width: 2,
        height: 2,
        cellRects: cells,
        current: Brightness.light,
        lightToDarkThreshold: 0.6,
        darkToLightThreshold: 0.6,
        background: const Color(0xFF000000),
      );
      expect(overBlack, equals(Brightness.dark));
    });

    testWidgets(
        'GlassContentAwareScope(sampleOnFrame: true) pauses on lifecycle pause and disposes cleanly',
        (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: GlassContentAwareScope(
            sampleOnFrame: true,
            child: GlassContentAwareContent(
              child: ColoredBox(color: CupertinoColors.white),
            ),
          ),
        ),
      );

      final state = tester.state<GlassContentAwareScopeState>(
        find.byType(GlassContentAwareScope),
      );
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(state.isScrollSamplingActive, isFalse);

      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
    });

    test(
        'size-adaptive bevel thickness and large-platter shadow scaling follow CoreAnimation laws',
        () {
      // Standard buttons (h >= 44 pt) keep preset thickness untouched.
      expect(
        resolveEffectiveGlassThickness(LiquidGlassSettings.ios26Light, 44),
        equals(LiquidGlassSettings.ios26Light.effectiveThickness),
      );
      expect(
        resolveEffectiveGlassThickness(LiquidGlassSettings.ios27Light, 44),
        equals(LiquidGlassSettings.ios27Light.effectiveThickness),
      );

      // Compact pills (h < 44 pt) cap thickness smoothly to avoid over-bending.
      expect(
        resolveEffectiveGlassThickness(LiquidGlassSettings.ios26Light, 28),
        closeTo(21.0, 1e-4),
      );
      expect(
        resolveEffectiveGlassThickness(LiquidGlassSettings.ios27Light, 24),
        closeTo(18.0, 1e-4),
      );

      // Non-size-adaptive presets stay bit-exact unchanged at all sizes.
      const custom = LiquidGlassSettings(thickness: 32);
      expect(resolveEffectiveGlassThickness(custom, 24), equals(32.0));

      // Drop-shadow opacity stays 1.0 for controls <= 64 pt and attenuates to
      // 0.55 on large platters >= 160 pt.
      final small = resolveGlassFaceOptics(LiquidGlassSettings.ios27Light, 44);
      final mid = resolveGlassFaceOptics(LiquidGlassSettings.ios27Light, 112);
      final large = resolveGlassFaceOptics(LiquidGlassSettings.ios27Light, 160);
      expect(small.shadowOpacityScale, equals(1.0));
      expect(mid.shadowOpacityScale, closeTo(0.775, 1e-3));
      expect(large.shadowOpacityScale, closeTo(0.55, 1e-4));

      // iOS 27 live CoreAnimation frost calibration: 8 pt blur fill radius,
      // 0.50 light / 0.65 dark cloud opacity for controls <= 64 pt (buttons &
      // tab bars), ramping smoothly to 0.88 on large platters (160 pt) while
      // leaving explicit overrides (such as overlay platters at 1.0) untouched.
      expect(LiquidGlassSettings.ios27Light.frost, equals(8.0));
      expect(LiquidGlassSettings.ios27Light.frostOpacity, equals(0.50));
      expect(LiquidGlassSettings.ios27Dark.frost, equals(8.0));
      expect(LiquidGlassSettings.ios27Dark.frostOpacity, equals(0.65));

      final tabBarLight =
          resolveGlassFaceOptics(LiquidGlassSettings.ios27Light, 62);
      final tabBarDark =
          resolveGlassFaceOptics(LiquidGlassSettings.ios27Dark, 62);
      final overlayPlatter = resolveGlassFaceOptics(
        LiquidGlassSettings.ios27Light.copyWith(frostOpacity: 1.0),
        160,
      );
      expect(tabBarLight.effectiveFrostOpacity, closeTo(0.50, 1e-4));
      expect(tabBarDark.effectiveFrostOpacity, closeTo(0.65, 1e-4));
      expect(large.effectiveFrostOpacity, closeTo(0.88, 1e-4));
      expect(overlayPlatter.effectiveFrostOpacity, equals(1.0));
    });

    test(
        'shaders apply uFace.z maxLumaSDR cap before uFace.w fill mix to avoid '
        'flat-clipping light-mode text and card edges', () {
      for (final path in [
        'shaders/liquid_glass_render.frag',
        'shaders/lightweight_glass.frag',
      ]) {
        final src = File(path).readAsStringSync();
        final capIdx = src.indexOf('if (uFace.z > 0.001 && outL > uFace.z)');
        final fillIdx = src.indexOf('if (uFace.w > 0.001)');
        expect(capIdx, isNonNegative, reason: '$path missing maxLumaSDR cap');
        expect(fillIdx, isNonNegative, reason: '$path missing face fill mix');
        expect(
          capIdx,
          lessThan(fillIdx),
          reason: '$path must cap maxLumaSDR before adding white faceFillAlpha',
        );
      }
    });

    testWidgets(
        'GlassBackdropGroup.hoisted mounts hoist slot and isolates backdrop from overlay',
        (tester) async {
      BackdropKey? backdropKeyInBackdrop;
      BackdropKey? backdropKeyInOverlay;

      await tester.pumpWidget(
        CupertinoApp(
          home: GlassBackdropGroup.hoisted(
            backdrop: Builder(
              builder: (context) {
                backdropKeyInBackdrop = GlassBackdropGroup.keyOf(context);
                return const ColoredBox(color: CupertinoColors.white);
              },
            ),
            overlay: Align(
              alignment: Alignment.bottomCenter,
              child: Builder(
                builder: (context) {
                  backdropKeyInOverlay = GlassBackdropGroup.keyOf(context);
                  return const SizedBox(width: 120, height: 44);
                },
              ),
            ),
          ),
        ),
      );

      expect(backdropKeyInBackdrop, isNull);
      expect(backdropKeyInOverlay, isNotNull);

      final boundary = tester.renderObject<RenderGlassBackdropGroupBoundary>(
        find.byType(GlassBackdropGroupBoundary),
      );
      expect(boundary.hasHoistHost, isTrue);

      // Toggling enabled false preserves overlay element state (no remount).
      final overlayElementBefore = tester.element(find.byType(Align));
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassBackdropGroup.hoisted(
            enabled: false,
            backdrop: const ColoredBox(color: CupertinoColors.white),
            overlay: const Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(width: 120, height: 44),
            ),
          ),
        ),
      );
      expect(
        identical(tester.element(find.byType(Align)), overlayElementBefore),
        isTrue,
      );
      expect(boundary.hasHoistHost, isFalse);
    });

    testWidgets(
        'PR 2 native iOS 26/27 control metrics and primaryColor tab tinting',
        (tester) async {
      // Default control metrics match native iOS 26 / iOS 27 UIKit.
      final sw = GlassSwitch(value: true, onChanged: (_) {});
      expect(sw.width, equals(63.0));
      expect(sw.height, equals(28.0));

      final tabBar = GlassTabBar.bottom(
        tabs: const [
          GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
          GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
        ],
        selectedIndex: 0,
        onTabSelected: (_) {},
      );
      expect(tabBar.barHeight, equals(62.0));
      expect(tabBar.horizontalPadding, equals(21.0));

      final extra = GlassTabBarExtraButton(
        icon: const Icon(CupertinoIcons.add),
        label: 'Add',
        onTap: () {},
      );
      expect(extra.size, equals(62.0));
      expect(extra.menuWidth, equals(250.0));

      final menu = GlassMenu(
        trigger: const SizedBox(width: 44, height: 44),
        items: [GlassMenuItem(title: 'Copy', onTap: () {})],
      );
      expect(menu.menuWidth, equals(250.0));

      final sheet = GlassModalSheet(child: const SizedBox());
      expect(sheet.halfSize, equals(0.525));
      expect(sheet.showDragIndicator, isTrue);

      // GlassTabBar active tab tints icon & label with primaryColor on ios27/ios26,
      // stays monochrome on classic, and respects explicit selectedIconColor.
      const customBlue = Color(0xFF007AFF);

      Future<Color?> resolveSelectedIconColor({
        required GlassThemeData glassTheme,
        Color? explicitSelectedColor,
      }) async {
        await tester.pumpWidget(
          CupertinoApp(
            theme: const CupertinoThemeData(
              brightness: Brightness.light,
              primaryColor: customBlue,
            ),
            home: GlassTheme(
              data: glassTheme,
              child: GlassTabBar.bottom(
                tabs: const [
                  GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
                  GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
                ],
                selectedIndex: 0,
                selectedIconColor: explicitSelectedColor,
                onTabSelected: (_) {},
                quality: GlassQuality.minimal,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final iconTheme = tester.widget<IconTheme>(
          find
              .ancestor(
                of: find.byIcon(CupertinoIcons.home).last,
                matching: find.byType(IconTheme),
              )
              .first,
        );
        return iconTheme.data.color;
      }

      expect(
        await resolveSelectedIconColor(
          glassTheme: const GlassThemeData.ios27(),
        ),
        equals(customBlue),
      );
      expect(
        await resolveSelectedIconColor(
          glassTheme: const GlassThemeData.ios26(),
        ),
        equals(customBlue),
      );
      expect(
        await resolveSelectedIconColor(
          glassTheme: const GlassThemeData.classic(),
        ),
        isNot(equals(customBlue)),
      );
      const overrideColor = Color(0xFFFF3B30);
      expect(
        await resolveSelectedIconColor(
          glassTheme: const GlassThemeData.ios27(),
          explicitSelectedColor: overrideColor,
        ),
        equals(overrideColor),
      );
    });
  });
}
