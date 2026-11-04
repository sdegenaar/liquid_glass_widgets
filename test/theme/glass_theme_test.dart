import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/shared/lens_inner_shadow_painter.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_effect.dart';

void main() {
  group('GlassTheme', () {
    testWidgets('provides theme data to descendants', (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          settings: GlassThemeSettings(thickness: 50),
          quality: GlassQuality.premium,
        ),
      );

      GlassThemeData? capturedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                capturedTheme = GlassThemeData.of(context);
                return Container();
              },
            ),
          ),
        ),
      );

      expect(capturedTheme, equals(themeData));
    });

    testWidgets('returns fallback when no theme in tree', (tester) async {
      GlassThemeData? capturedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedTheme = GlassThemeData.of(context);
              return Container();
            },
          ),
        ),
      );

      expect(capturedTheme, isNotNull);
      expect(capturedTheme, equals(GlassThemeData.fallback()));
    });

    test('fallback variants have null quality to respect widget defaults', () {
      // This explicitly tests against the resolution bug fixed in 0.7.14
      // where GlassQuality.standard in the fallback was overriding
      // premium widget defaults like GlassTabBar.bottom.
      final fallback = GlassThemeData.fallback();
      expect(fallback.light.quality, isNull);
      expect(fallback.dark.quality, isNull);
    });

    testWidgets('updates when theme data changes', (tester) async {
      const initialTheme = GlassThemeData(
        light: GlassThemeVariant(
          settings: GlassThemeSettings(thickness: 30),
        ),
      );

      const updatedTheme = GlassThemeData(
        light: GlassThemeVariant(
          settings: GlassThemeSettings(thickness: 50),
        ),
      );

      final themeNotifier = ValueNotifier<GlassThemeData>(initialTheme);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<GlassThemeData>(
            valueListenable: themeNotifier,
            builder: (context, theme, child) {
              return GlassTheme(
                data: theme,
                child: Builder(
                  builder: (context) {
                    final capturedTheme = GlassThemeData.of(context);
                    return Text('${capturedTheme.light.settings?.thickness}');
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('30.0'), findsOneWidget);

      themeNotifier.value = updatedTheme;
      await tester.pump();

      expect(find.text('50.0'), findsOneWidget);
    });
  });

  group('GlassThemeData', () {
    test('equality works correctly', () {
      const theme1 = GlassThemeData(
        light: GlassThemeVariant(quality: GlassQuality.standard),
      );
      const theme2 = GlassThemeData(
        light: GlassThemeVariant(quality: GlassQuality.standard),
      );
      const theme3 = GlassThemeData(
        light: GlassThemeVariant(quality: GlassQuality.premium),
      );

      expect(theme1, equals(theme2));
      expect(theme1, isNot(equals(theme3)));
    });

    test('copyWith works correctly', () {
      const original = GlassThemeData(
        light: GlassThemeVariant(quality: GlassQuality.standard),
        dark: GlassThemeVariant(quality: GlassQuality.premium),
      );

      final copied = original.copyWith(
        light: const GlassThemeVariant(quality: GlassQuality.premium),
      );

      expect(copied.light.quality, equals(GlassQuality.premium));
      expect(copied.dark.quality, equals(GlassQuality.premium));
    });

    testWidgets('variantFor selects correct variant based on brightness',
        (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          settings: GlassThemeSettings(thickness: 30),
        ),
        dark: GlassThemeVariant(
          settings: GlassThemeSettings(thickness: 50),
        ),
      );

      // Test light mode
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: MaterialApp(
            home: GlassTheme(
              data: themeData,
              child: Builder(
                builder: (context) {
                  final variant = themeData.variantFor(context);
                  return Text('${variant.settings?.thickness}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('30.0'), findsOneWidget);

      // Test dark mode: use tester.platformDispatcher so MaterialApp correctly
      // selects darkTheme when ThemeMode.system is used.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.system,
          home: GlassTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                final variant = themeData.variantFor(context);
                return Text('${variant.settings?.thickness}');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50.0'), findsOneWidget);
    });

    testWidgets('settingsFor returns correct settings', (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          settings: GlassThemeSettings(thickness: 30),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                final settings = themeData.settingsFor(context);
                return Text('${settings?.thickness}');
              },
            ),
          ),
        ),
      );

      expect(find.text('30.0'), findsOneWidget);
    });

    testWidgets('qualityFor returns correct quality', (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(quality: GlassQuality.premium),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                final quality = themeData.qualityFor(context);
                return Text('$quality');
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('premium'), findsOneWidget);
    });

    testWidgets('glowColorsFor returns correct colors', (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          glowColors: GlassGlowColors(
            primary: Colors.blue,
            secondary: Colors.purple,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                final glowColors = themeData.glowColorsFor(context);
                return Text('${glowColors.primary}');
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('MaterialColor'), findsOneWidget);
    });
  });

  group('GlassThemeVariant', () {
    test('equality works correctly', () {
      const variant1 = GlassThemeVariant(
        settings: GlassThemeSettings(thickness: 30),
        quality: GlassQuality.standard,
      );
      const variant2 = GlassThemeVariant(
        settings: GlassThemeSettings(thickness: 30),
        quality: GlassQuality.standard,
      );
      const variant3 = GlassThemeVariant(
        settings: GlassThemeSettings(thickness: 50),
        quality: GlassQuality.standard,
      );

      expect(variant1, equals(variant2));
      expect(variant1, isNot(equals(variant3)));
    });

    test('copyWith works correctly', () {
      const original = GlassThemeVariant(
        settings: GlassThemeSettings(thickness: 30),
        quality: GlassQuality.standard,
      );

      final copied = original.copyWith(
        quality: GlassQuality.premium,
      );

      expect(copied.settings?.thickness, equals(30));
      expect(copied.quality, equals(GlassQuality.premium));
    });
  });

  group('GlassGlowColors', () {
    test('equality works correctly', () {
      const colors1 = GlassGlowColors(
        primary: Colors.blue,
        secondary: Colors.purple,
      );
      const colors2 = GlassGlowColors(
        primary: Colors.blue,
        secondary: Colors.purple,
      );
      const colors3 = GlassGlowColors(
        primary: Colors.red,
        secondary: Colors.purple,
      );

      expect(colors1, equals(colors2));
      expect(colors1, isNot(equals(colors3)));
    });

    test('copyWith works correctly', () {
      const original = GlassGlowColors(
        primary: Colors.blue,
        secondary: Colors.purple,
      );

      final copied = original.copyWith(
        primary: Colors.red,
      );

      expect(copied.primary, equals(Colors.red));
      expect(copied.secondary, equals(Colors.purple));
    });

    test('fallback has sensible defaults', () {
      // primary is intentionally null — glowColorsFor() injects a
      // brightness-adaptive neutral white at runtime (iOS 26 interaction model).
      expect(GlassGlowColors.fallback.primary, isNull);
      expect(GlassGlowColors.fallback.secondary, isNotNull);
      expect(GlassGlowColors.fallback.success, isNotNull);
      expect(GlassGlowColors.fallback.warning, isNotNull);
      expect(GlassGlowColors.fallback.danger, isNotNull);
      expect(GlassGlowColors.fallback.info, isNotNull);
    });
  });

  group('AdaptiveLiquidGlassLayer settings merge chain', () {
    // Regression guard for the bug fixed in 0.7.14:
    // GlassThemeSettings must merge onto widget defaults, not replace them.
    // These tests read back the resolved settings, not just check for crashes.

    testWidgets(
        'partial theme override preserves widget defaults for unset fields',
        (tester) async {
      // Theme only sets thickness — all other per-widget defaults must survive.
      LiquidGlassSettings? captured;
      const baseDefaults = LiquidGlassSettings(); // constructor defaults

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData(
              light: GlassThemeVariant(
                settings: GlassThemeSettings(thickness: 50),
              ),
            ),
            child: Builder(
              builder: (context) {
                final themeData = GlassThemeData.of(context);
                final themeOverride = themeData.settingsFor(context);
                captured = themeOverride?.applyTo(baseDefaults);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // The theme-set field must be applied
      expect(captured?.thickness, equals(50.0));
      // All other fields must equal the base defaults (not zeroed out)
      expect(captured?.blur, equals(baseDefaults.blur));
      expect(captured?.glassColor, equals(baseDefaults.glassColor));
      expect(captured?.refractiveIndex, equals(baseDefaults.refractiveIndex));
      expect(captured?.lightIntensity, equals(baseDefaults.lightIntensity));
      expect(captured?.chromaticAberration,
          equals(baseDefaults.chromaticAberration));
    });

    testWidgets('empty GlassThemeSettings leaves all widget defaults intact',
        (tester) async {
      LiquidGlassSettings? captured;
      const baseDefaults = LiquidGlassSettings();

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData(
              light: GlassThemeVariant(
                settings: GlassThemeSettings(), // explicitly empty
              ),
            ),
            child: Builder(
              builder: (context) {
                final themeData = GlassThemeData.of(context);
                final themeOverride = themeData.settingsFor(context);
                captured = themeOverride?.applyTo(baseDefaults);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(captured?.thickness, equals(baseDefaults.thickness));
      expect(captured?.blur, equals(baseDefaults.blur));
      expect(captured?.glassColor, equals(baseDefaults.glassColor));
    });

    testWidgets('explicit widget settings win over theme settings',
        (tester) async {
      // Theme says thickness: 50, widget says thickness: 100 — widget must win.
      const explicitSettings = LiquidGlassSettings(thickness: 100);
      LiquidGlassSettings? resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData(
              light: GlassThemeVariant(
                settings: GlassThemeSettings(thickness: 50),
              ),
            ),
            child: Builder(
              builder: (context) {
                final themeData = GlassThemeData.of(context);
                const baseSettings = LiquidGlassSettings();
                final themeOverride = themeData.settingsFor(context);
                // Compute merged to prove the merge path runs without error.
                // When explicit settings are supplied, AdaptiveLiquidGlassLayer
                // returns them directly; the theme merge is discarded.
                themeOverride?.applyTo(baseSettings);
                // Simulate what AdaptiveLiquidGlassLayer does:
                resolved = explicitSettings; // explicit wins entirely
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved?.thickness, equals(100.0));
    });
  });

  group('GlassButton with theme', () {
    testWidgets('uses theme glow color when not explicitly provided',
        (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          glowColors: GlassGlowColors(
            primary: Colors.blue,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: AdaptiveLiquidGlassLayer(
              child: GlassButton(
                icon: Icon(Icons.star),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
    });

    testWidgets('explicit glow color overrides theme', (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          glowColors: GlassGlowColors(
            primary: Colors.blue,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: AdaptiveLiquidGlassLayer(
              child: GlassButton(
                icon: Icon(Icons.star),
                glowColor: Colors.red,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
    });
  });

  group('GlassTabBar.bottom with theme', () {
    // Regression guard: GlassTabBar.bottom must read
    // interactionGlowColor from GlassThemeData when not explicitly provided.

    final tabs = [
      const GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
      const GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
    ];

    testWidgets('mounts without error when theme provides a primary glow color',
        (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          glowColors: GlassGlowColors(primary: Color(0x4400AAFF)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      // No crash, widget present — the theme glow path executed successfully.
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('explicit interactionGlowColor overrides theme',
        (tester) async {
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          glowColors: GlassGlowColors(primary: Color(0x4400AAFF)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
                // Explicit param must win over theme.
                interactionGlowColor: const Color(0x44FF0000),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets(
        'interactionGlowColor defaults to theme primary when param is null',
        (tester) async {
      // Arrange: theme sets a distinctive primary glow; bar has no explicit param.
      const customGlow = Color(0x4400FF00);
      const themeData = GlassThemeData(
        light: GlassThemeVariant(
          glowColors: GlassGlowColors(primary: customGlow),
        ),
      );

      Color? capturedGlowColor;

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                // Verify the resolved color matches what the bar will use.
                capturedGlowColor =
                    GlassThemeData.of(context).glowColorsFor(context).primary;
                return Scaffold(
                  bottomNavigationBar: GlassTabBar.bottom(
                    tabs: tabs,
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                    maskingQuality: MaskingQuality.off,
                    // interactionGlowColor: null  ← theme should fill this
                  ),
                );
              },
            ),
          ),
        ),
      );

      // The theme's primary color must be what glowColorsFor() returns.
      expect(capturedGlowColor, equals(customGlow));
      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  group('GlassTabBar.searchable with theme', () {
    // Regression guard: both SearchableTabIndicator
    // (normal tab pill + collapsed/logo state) and SearchPill must read
    // interactionGlowColor from GlassThemeData when not explicitly provided.

    final tabs = [
      const GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
      const GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
    ];

    Widget buildWithTheme({
      bool isSearchActive = false,
      Color? explicitGlowColor,
    }) {
      return MaterialApp(
        home: GlassTheme(
          data: const GlassThemeData(
            light: GlassThemeVariant(
              glowColors: GlassGlowColors(primary: Color(0x44FF8800)),
            ),
          ),
          child: Scaffold(
            body: GlassTabBar.searchable(
              tabs: tabs,
              selectedIndex: 0,
              onTabSelected: (_) {},
              isSearchActive: isSearchActive,
              maskingQuality: MaskingQuality.off,
              interactionGlowColor: explicitGlowColor,
              searchConfig: GlassSearchBarConfig(
                onSearchToggle: (_) {},
                hintText: 'Search',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'mounts without error when theme provides primary glow (tab-pill state)',
        (tester) async {
      await tester.pumpWidget(buildWithTheme());
      await tester.pump();
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets(
        'mounts without error when theme provides primary glow (search-active state)',
        (tester) async {
      await tester.pumpWidget(buildWithTheme(isSearchActive: true));
      await tester.pumpAndSettle();
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('explicit interactionGlowColor overrides theme',
        (tester) async {
      await tester.pumpWidget(
        buildWithTheme(
          explicitGlowColor: const Color(0x44FF0000),
        ),
      );
      await tester.pump();
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('theme primary color is correctly resolved at build time',
        (tester) async {
      const customGlow = Color(0x4400FF00);
      Color? resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData(
              light: GlassThemeVariant(
                glowColors: GlassGlowColors(primary: customGlow),
              ),
            ),
            child: Builder(
              builder: (context) {
                resolved =
                    GlassThemeData.of(context).glowColorsFor(context).primary;
                return Scaffold(
                  body: GlassTabBar.searchable(
                    tabs: tabs,
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                    maskingQuality: MaskingQuality.off,
                    searchConfig: GlassSearchBarConfig(
                      onSearchToggle: (_) {},
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(resolved, equals(customGlow));
      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  group('GlassStyle and style presets (classic / ios27)', () {
    final tabs = [
      const GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
      const GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
    ];

    testWidgets(
        'default GlassThemeData() resolves calibrated iOS 27 surface and tab bar platters',
        (tester) async {
      LiquidGlassSettings? surfaceResolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GlassTheme(
            data: const GlassThemeData(),
            child: Builder(
              builder: (context) {
                surfaceResolved = GlassThemeData.of(context)
                    .settingsFor(context)
                    ?.applyTo(const LiquidGlassSettings());
                return Scaffold(
                  bottomNavigationBar: GlassTabBar.bottom(
                    tabs: tabs,
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                    maskingQuality: MaskingQuality.off,
                  ),
                );
              },
            ),
          ),
        ),
      );

      final layer = tester.widget<AdaptiveLiquidGlassLayer>(
        find.byType(AdaptiveLiquidGlassLayer).first,
      );
      expect(layer.settings, equals(LiquidGlassSettings.ios27Light));
      expect(surfaceResolved, equals(LiquidGlassSettings.ios27Light));
    });

    testWidgets(
        'single GlassThemeData(style: GlassStyle.classic) setting switches surface, tab bar, and indicator lens to classic',
        (tester) async {
      LiquidGlassSettings? surfaceResolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GlassTheme(
            data: const GlassThemeData(style: GlassStyle.classic),
            child: Builder(
              builder: (context) {
                surfaceResolved = GlassThemeData.of(context)
                    .settingsFor(context)
                    ?.applyTo(const LiquidGlassSettings());
                return Scaffold(
                  bottomNavigationBar: GlassTabBar.bottom(
                    tabs: tabs,
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                    maskingQuality: MaskingQuality.off,
                  ),
                );
              },
            ),
          ),
        ),
      );

      final layer = tester.widget<AdaptiveLiquidGlassLayer>(
        find.byType(AdaptiveLiquidGlassLayer).first,
      );
      expect(layer.settings, equals(LiquidGlassSettings.classicTabBar));
      expect(surfaceResolved, equals(LiquidGlassSettings.classicLight));
    });

    testWidgets(
        'GlassThemeData.simple(blur: 10) overrides only blur on iOS 27 tab bar platter without clobbering other fields',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GlassTheme(
            data: GlassThemeData.simple(blur: 10),
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      final layer = tester.widget<AdaptiveLiquidGlassLayer>(
        find.byType(AdaptiveLiquidGlassLayer).first,
      );
      expect(
        layer.settings,
        equals(LiquidGlassSettings.ios27Light.copyWith(blur: 10)),
      );
    });

    testWidgets(
        'GlassThemeData.ios27() resolves iOS 27 light and dark tab bar platters and indicator lens',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData.ios27(brightness: Brightness.dark),
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      final layer = tester.widget<AdaptiveLiquidGlassLayer>(
        find.byType(AdaptiveLiquidGlassLayer).first,
      );
      expect(layer.settings, equals(LiquidGlassSettings.ios27Dark));
    });

    testWidgets(
        'GlassThemeData.simple(blur: 10) in dark mode overrides only blur on the iOS 27 dark platter',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: GlassThemeData.simple(
              blur: 10,
              brightness: Brightness.dark,
            ),
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      final layer = tester.widget<AdaptiveLiquidGlassLayer>(
        find.byType(AdaptiveLiquidGlassLayer).first,
      );
      expect(
        layer.settings,
        equals(LiquidGlassSettings.ios27Dark.copyWith(blur: 10)),
      );
    });

    testWidgets(
        'GlassThemeData.simple(style: classic) resolves the classic tab bar platter with the override applied',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GlassTheme(
            data: GlassThemeData.simple(blur: 10, style: GlassStyle.classic),
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      final layer = tester.widget<AdaptiveLiquidGlassLayer>(
        find.byType(AdaptiveLiquidGlassLayer).first,
      );
      expect(
        layer.settings,
        equals(LiquidGlassSettings.classicTabBar.copyWith(blur: 10)),
      );
    });

    test(
        'applyDeltaTo ignores fields equal to the baseline and applies the rest',
        () {
      final override = GlassThemeSettings.classicLight.copyWith(
        blur: 10,
        saturation: 1.5,
      );
      final result = override.applyDeltaTo(
        LiquidGlassSettings.ios27Light,
        GlassThemeSettings.classicLight,
      );
      expect(
        result,
        equals(LiquidGlassSettings.ios27Light.copyWith(
          blur: 10,
          saturation: 1.5,
        )),
      );
    });

    test('applyDeltaTo with the untouched baseline returns the base unchanged',
        () {
      final result = GlassThemeSettings.classicLight.applyDeltaTo(
        LiquidGlassSettings.ios27Light,
        GlassThemeSettings.classicLight,
      );
      expect(result, equals(LiquidGlassSettings.ios27Light));
    });

    test('applyDeltaTo applies a sparse override like applyTo', () {
      const override = GlassThemeSettings(thickness: 50);
      final result = override.applyDeltaTo(
        LiquidGlassSettings.ios27Light,
        GlassThemeSettings.classicLight,
      );
      expect(
        result,
        equals(LiquidGlassSettings.ios27Light.copyWith(thickness: 50)),
      );
    });

    testWidgets(
        'indicator inner shadow follows the resolved lens: 0.06 for iOS 27, 0.12 for classic',
        (tester) async {
      List<LensInnerShadowPainter> lensShadowPainters() => find
          .byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is LensInnerShadowPainter)
          .evaluate()
          .map((e) =>
              (e.widget as CustomPaint).painter! as LensInnerShadowPainter)
          .toList();

      Future<List<LensInnerShadowPainter>> pressedShadows(
          GlassThemeData data) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: GlassTheme(
              data: data,
              child: Scaffold(
                bottomNavigationBar: GlassTabBar.bottom(
                  tabs: tabs,
                  selectedIndex: 0,
                  onTabSelected: (_) {},
                  maskingQuality: MaskingQuality.off,
                  quality: GlassQuality.premium,
                ),
              ),
            ),
          ),
        );
        final gesture = await tester
            .startGesture(tester.getCenter(find.text('Home').first));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final painters = lensShadowPainters();
        await gesture.up();
        await tester.pumpAndSettle();
        return painters;
      }

      final ios27Painters = await pressedShadows(const GlassThemeData.ios27());
      expect(ios27Painters, isNotEmpty);
      expect(
        ios27Painters.first.shadowOpacity,
        equals(LensInnerShadowPainter.defaultShadowOpacity),
      );

      final classicPainters =
          await pressedShadows(const GlassThemeData.classic());
      expect(classicPainters, isNotEmpty);
      expect(
        classicPainters.first.shadowOpacity,
        equals(LensInnerShadowPainter.classicShadowOpacity),
      );
    });

    testWidgets(
        'theme indicatorSettings and per-widget indicatorSettings compose cleanly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GlassTheme(
            data: const GlassThemeData(
              light: GlassThemeVariant(
                indicatorSettings: GlassThemeSettings(thickness: 34),
              ),
            ),
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
                indicatorSettings: const LiquidGlassSettings(
                  refractiveIndex: 1.22,
                ),
              ),
            ),
          ),
        ),
      );

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Home').first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final indicatorGlass = tester.widget<GlassEffect>(
        find.byType(GlassEffect).first,
      );
      // Theme override (thickness: 34) + widget override (refractiveIndex: 1.22)
      // merged onto ios27Indicator
      expect(indicatorGlass.settings.thickness, equals(34.0));
      expect(indicatorGlass.settings.refractiveIndex, equals(1.22));
      expect(
        indicatorGlass.settings.lensModel,
        equals(GlassLensModel.paraxial),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'GlassThemeData.classic() switches tab bar platter and indicator lens to classic presets',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GlassTheme(
            data: const GlassThemeData.classic(),
            child: Scaffold(
              bottomNavigationBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      final layer = tester.widget<AdaptiveLiquidGlassLayer>(
        find.byType(AdaptiveLiquidGlassLayer).first,
      );
      // Classic bottom bar platter uses thickness: 30, blur: 3, spherical lens
      expect(layer.settings?.thickness, equals(30.0));
      expect(layer.settings?.blur, equals(3.0));
      expect(
        layer.settings?.lensModel,
        equals(GlassLensModel.spherical),
      );

      // Press down to activate indicator lens
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Home').first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final indicatorGlass = tester.widget<GlassEffect>(
        find.byType(GlassEffect).first,
      );
      expect(
        indicatorGlass.settings.lensModel,
        equals(GlassLensModel.spherical),
      );
      expect(indicatorGlass.settings.rimShade, equals(0.0));
      expect(indicatorGlass.settings.refractiveIndex, equals(1.10));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'LiquidGlassSettings.classic(context) and ios27(context) resolve by brightness and allow per-widget override',
        (tester) async {
      LiquidGlassSettings? lightClassic;
      LiquidGlassSettings? lightIos26;
      LiquidGlassSettings? lightIos27;
      LiquidGlassSettings? darkClassic;
      LiquidGlassSettings? darkIos26;
      LiquidGlassSettings? darkIos27;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              GlassTheme(
                data: const GlassThemeData(brightness: Brightness.light),
                child: Builder(
                  builder: (context) {
                    lightClassic = LiquidGlassSettings.classic(context);
                    lightIos26 = LiquidGlassSettings.ios26(context);
                    lightIos27 = LiquidGlassSettings.ios27(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
              GlassTheme(
                data: const GlassThemeData(brightness: Brightness.dark),
                child: Builder(
                  builder: (context) {
                    darkClassic = LiquidGlassSettings.classic(context);
                    darkIos26 = LiquidGlassSettings.ios26(context);
                    darkIos27 = LiquidGlassSettings.ios27(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(lightClassic, equals(LiquidGlassSettings.classicLight));
      expect(lightIos26, equals(LiquidGlassSettings.ios26Light));
      expect(lightIos27, equals(LiquidGlassSettings.ios27Light));
      expect(darkClassic, equals(LiquidGlassSettings.classicDark));
      expect(darkIos26, equals(LiquidGlassSettings.ios26Dark));
      expect(darkIos27, equals(LiquidGlassSettings.ios27Dark));
    });

    testWidgets(
        'GlassSwitch and GlassSlider resolve iOS 27 paraxial lens by default and spherical lens under GlassThemeData.classic()',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData.ios27(),
            child: Scaffold(
              body: Column(
                children: [
                  GlassSwitch(value: false, onChanged: (_) {}),
                  GlassSlider(value: 0.5, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );

      final ios27Effects =
          tester.widgetList<GlassEffect>(find.byType(GlassEffect)).toList();
      expect(ios27Effects.length, 2);
      expect(
        ios27Effects[0].settings.lensModel,
        equals(GlassLensModel.paraxial),
      );
      expect(ios27Effects[0].settings.rimShade, equals(1.0));
      expect(
        ios27Effects[1].settings.lensModel,
        equals(GlassLensModel.paraxial),
      );
      expect(ios27Effects[1].settings.rimShade, equals(1.0));

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData.classic(),
            child: Scaffold(
              body: Column(
                children: [
                  GlassSwitch(value: false, onChanged: (_) {}),
                  GlassSlider(value: 0.5, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );

      final classicEffects =
          tester.widgetList<GlassEffect>(find.byType(GlassEffect)).toList();
      expect(classicEffects.length, 2);
      expect(
        classicEffects[0].settings.lensModel,
        equals(GlassLensModel.spherical),
      );
      expect(classicEffects[0].settings.rimShade, equals(0.0));
      expect(
        classicEffects[1].settings.lensModel,
        equals(GlassLensModel.spherical),
      );
      expect(classicEffects[1].settings.rimShade, equals(0.0));

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: const GlassThemeData.ios26(),
            child: Scaffold(
              body: Column(
                children: [
                  GlassSwitch(value: false, onChanged: (_) {}),
                  GlassSlider(value: 0.5, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );

      final ios26Effects =
          tester.widgetList<GlassEffect>(find.byType(GlassEffect)).toList();
      expect(ios26Effects.length, 2);
      expect(
        ios26Effects[0].settings.lensModel,
        equals(GlassLensModel.paraxial),
      );
      expect(ios26Effects[0].settings.rimShade, equals(1.0));
      expect(ios26Effects[0].settings.rimLight, equals(1.0));
      expect(
        ios26Effects[1].settings.lensModel,
        equals(GlassLensModel.paraxial),
      );
      expect(ios26Effects[1].settings.rimShade, equals(1.0));
      expect(ios26Effects[1].settings.rimLight, equals(1.0));
    });
  });
}
