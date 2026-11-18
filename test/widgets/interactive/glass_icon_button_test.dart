import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/liquid_glass_renderer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassIconButton', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.favorite),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.add),
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassIconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when null (disabled)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.add),
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassIconButton));
      await tester.pump();

      // Should not throw, just ignore tap
      expect(find.byType(GlassIconButton), findsOneWidget);
    });

    testWidgets('renders circle shape by default', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.star),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
    });

    testWidgets(
        'renders LiquidRoundedSuperellipse when roundedSquare shape is specified',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: const Icon(Icons.star),
              onPressed: () {},
              shape: GlassIconButtonShape.roundedSquare,
              borderRadius: 14,
            ),
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
      final innerButton = tester.widget<GlassButton>(find.byType(GlassButton));
      expect(innerButton.shape, isA<LiquidRoundedSuperellipse>());
      expect(
        (innerButton.shape as LiquidRoundedSuperellipse).borderRadius,
        equals(14),
      );
    });

    testWidgets('respects custom size', (tester) async {
      const customSize = 60.0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.star),
              onPressed: () {},
              size: customSize,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(GlassIconButton));

      expect(size.width, equals(customSize));
      expect(size.height, equals(customSize));
    });

    testWidgets('has proper semantics', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.add),
              onPressed: () {},
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.enabled, isTrue);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassIconButton(
            icon: Icon(Icons.star),
            onPressed: () {},
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
    });

    test('defaults are correct', () {
      final button = GlassIconButton(
        icon: Icon(Icons.star),
        onPressed: () {},
      );

      expect(button.size, equals(44));
      expect(button.shape, equals(GlassIconButtonShape.circle));
      expect(button.useOwnLayer, isFalse);
      expect(button.quality, isNull);
      expect(button.surfaceStyle, isNull);
      expect(button.color, isNull);
      expect(button.iconColor, isNull);
      expect(button.tintColor, isNull);
      expect(button.style, equals(GlassButtonStyle.filled));
      expect(button.interactionScale, equals(0.95));
      expect(button.anchorStretchSettings, isNull);
    });
  });

  // ── interaction resolution ────────────────────────────────────────────────
  // GlassIconButton always uses a fixed factor (0.95 shrink), never the native
  // point-based sizing path. These tests pin that contract so a future change
  // to the delegation in build() is caught immediately.
  group('GlassIconButton interaction resolution', () {
    /// The LiquidStretch the icon button delegates to via GlassButton.
    LiquidStretch stretchOf(WidgetTester tester) =>
        tester.widget<LiquidStretch>(
          find.descendant(
            of: find.byType(GlassIconButton),
            matching: find.byType(LiquidStretch),
          ),
        );

    testWidgets('always uses a fixed factor — never the native sizing path',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: const Icon(Icons.star),
              onPressed: () {},
            ),
          ),
        ),
      );

      final stretch = stretchOf(tester);
      // A fixed 0.95 factor: pressGrowth must be null so the button shrinks
      // uniformly rather than inflating by a point-growth amount.
      expect(stretch.interactionScale, equals(0.95));
      expect(stretch.pressGrowth, isNull,
          reason:
              'GlassIconButton must never use the native point-sizing path');
    });

    testWidgets('forwards explicit anchorStretchSettings to GlassButton',
        (tester) async {
      const settings = AnchorStretchSettings(intensity: 0.5);
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: const Icon(Icons.star),
              onPressed: () {},
              anchorStretchSettings: settings,
            ),
          ),
        ),
      );

      expect(stretchOf(tester).anchorStretchSettings.intensity, equals(0.5));
    });
  });

  group('GlassIconButton semantics (fixes #354)', () {
    testWidgets(
        'semanticLabel produces isolated button node with label and tap action',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: Semantics(
              container: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Title'),
                  GlassIconButton(
                    key: const Key('icon_btn'),
                    icon: const Icon(CupertinoIcons.gear_alt_fill),
                    semanticLabel: 'Settings',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Find the semantics node by its label — if the label merged with
      // 'Title' this finder returns nothing and the test fails.
      final settingsNode = find.bySemanticsLabel('Settings');
      expect(settingsNode, findsOneWidget);

      expect(
        tester.getSemantics(settingsNode),
        matchesSemantics(
          label: 'Settings',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true, // focus merges into the labelled node (#381)
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('label is not merged with sibling text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: Semantics(
              container: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Title'),
                  GlassIconButton(
                    icon: const Icon(CupertinoIcons.gear_alt_fill),
                    semanticLabel: 'Settings',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // There must be a 'Settings' node, and no node whose label contains
      // both 'Title' and 'Settings' merged together.
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'(Title.*Settings|Settings.*Title)')),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('disabled button omits tap action and reports isEnabled false',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: GlassIconButton(
              icon: const Icon(CupertinoIcons.gear_alt_fill),
              semanticLabel: 'Settings',
              onPressed: null, // disabled
            ),
          ),
        ),
      );

      final settingsNode = find.bySemanticsLabel('Settings');
      expect(settingsNode, findsOneWidget);

      expect(
        tester.getSemantics(settingsNode),
        matchesSemantics(
          label: 'Settings',
          isButton: true,
          hasTapAction: false,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('GlassIconButton GlassSurfaceStyle.solid & tintColor', () {
    Widget cupertinoHost({
      required Widget child,
      Brightness brightness = Brightness.light,
      Color primaryColor = CupertinoColors.activeBlue,
    }) {
      return GlassTheme(
        data: GlassThemeData(brightness: brightness),
        child: CupertinoApp(
          theme: CupertinoThemeData(
            brightness: brightness,
            primaryColor: primaryColor,
          ),
          home: CupertinoPageScaffold(
            child: Center(child: child),
          ),
        ),
      );
    }

    IconThemeData innerIconThemeOf(WidgetTester tester, [Finder? scope]) {
      return tester
          .widget<IconTheme>(
            find
                .descendant(
                  of: scope ?? find.byType(GlassIconButton),
                  matching: find.byType(IconTheme),
                )
                .last,
          )
          .data;
    }

    testWidgets(
        'solid mode renders zero shaders across filled, prominent, and transparent styles',
        (tester) async {
      var tapped = false;

      // 1. Filled solid with roundedSquare superellipse
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.light,
          child: GlassIconButton(
            icon: const Icon(CupertinoIcons.gear_alt_fill),
            shape: GlassIconButtonShape.roundedSquare,
            borderRadius: 12,
            surfaceStyle: GlassSurfaceStyle.solid,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(AdaptiveGlass),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(GlassGlow),
        ),
        findsNothing,
      );

      final filledDeco = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as ShapeDecoration;
      expect(filledDeco.color, equals(kGlassSolidWellLight));
      expect(filledDeco.shape, isA<LiquidRoundedSuperellipse>());
      expect(
        innerIconThemeOf(tester).color!.toARGB32(),
        equals(CupertinoColors.label.color.toARGB32()),
      );

      await tester.tap(find.byType(GlassIconButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // 2. Prominent solid defaults to primaryColor + white contrasting icon
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          child: GlassIconButton(
            icon: const Icon(CupertinoIcons.plus),
            style: GlassButtonStyle.prominent,
            surfaceStyle: GlassSurfaceStyle.solid,
            onPressed: () {},
          ),
        ),
      );

      final prominentDeco = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as ShapeDecoration;
      expect(
        prominentDeco.color,
        equals(CupertinoColors.systemBlue.darkColor),
      );
      expect(innerIconThemeOf(tester).color, equals(CupertinoColors.white));

      // 3. Disabled prominent solid keeps white icon and dims via 0.5 Opacity
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          child: const GlassIconButton(
            icon: Icon(CupertinoIcons.plus),
            style: GlassButtonStyle.prominent,
            surfaceStyle: GlassSurfaceStyle.solid,
            onPressed: null,
          ),
        ),
      );
      expect(innerIconThemeOf(tester).color, equals(CupertinoColors.white));
      final opacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacities.any((o) => o.opacity == 0.5), isTrue);

      // 4. Transparent solid mounts no resting DecoratedBox
      await tester.pumpWidget(
        cupertinoHost(
          child: GlassIconButton(
            icon: const Icon(CupertinoIcons.ellipsis),
            style: GlassButtonStyle.transparent,
            surfaceStyle: GlassSurfaceStyle.solid,
            onPressed: () {},
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets(
        'auto-inherits GlassSurfaceStyle.solid inside solid GlassContainer.card and GlassGroupedSection',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContainer.card(
                surfaceStyle: GlassSurfaceStyle.solid,
                child: GlassIconButton(
                  key: const Key('card_icon_btn'),
                  icon: const Icon(CupertinoIcons.bell_fill),
                  onPressed: () {},
                ),
              ),
              GlassGroupedSection(
                surfaceStyle: GlassSurfaceStyle.solid,
                children: [
                  GlassIconButton(
                    key: const Key('section_icon_btn'),
                    icon: const Icon(CupertinoIcons.star_fill),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      for (final key in [
        const Key('card_icon_btn'),
        const Key('section_icon_btn'),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(AdaptiveGlass),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(DecoratedBox),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets(
        'resolves explicit iconColor, contrast-aware bright/dark fills, and glass tintColor',
        (tester) async {
      // Bright solid fill -> black icon by default, explicit iconColor overrides
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.dark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassIconButton(
                key: const Key('bright_solid_icon'),
                icon: const Icon(CupertinoIcons.arrow_up),
                surfaceStyle: GlassSurfaceStyle.solid,
                color: const Color(0xFFFFFFFF),
                onPressed: () {},
              ),
              GlassIconButton(
                key: const Key('explicit_icon_color'),
                icon: const Icon(CupertinoIcons.heart_fill),
                surfaceStyle: GlassSurfaceStyle.solid,
                color: const Color(0xFFFFFFFF),
                iconColor: CupertinoColors.systemPink,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(
        innerIconThemeOf(tester, find.byKey(const Key('bright_solid_icon')))
            .color,
        equals(CupertinoColors.black),
      );
      expect(
        innerIconThemeOf(tester, find.byKey(const Key('explicit_icon_color')))
            .color!
            .toARGB32(),
        equals(CupertinoColors.systemPink.darkColor.toARGB32()),
      );

      // Glass mode + prominent + bright yellow tintColor -> GlassBodyMode.clear & black icon
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.dark,
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: const Icon(CupertinoIcons.sun_max_fill),
              style: GlassButtonStyle.prominent,
              tintColor: const Color(0xFFFFD60A),
              onPressed: () {},
            ),
          ),
        ),
      );

      final glass = tester.widget<AdaptiveGlass>(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(AdaptiveGlass),
        ),
      );
      expect(glass.useOwnLayer, isTrue);
      expect(glass.settings.bodyMode, equals(GlassBodyMode.clear));
      expect(glass.settings.glassColor.a, closeTo(0.85, 0.005));
      expect(innerIconThemeOf(tester).color, equals(CupertinoColors.black));
    });
  });
}
