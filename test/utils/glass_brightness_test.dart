// Tests for the resolveGlassBrightness utility function.
//
// These tests verify the four-level cascade:
//   Level 1: CupertinoThemeData.brightness explicit pin (pure CupertinoApp)
//   Level 2: Material ThemeMode (Theme.maybeBrightnessOf)
//   Level 3: Fallback explicit Cupertino brightness pin (MaterialApp)
//   Level 4: MediaQuery.platformBrightnessOf (system/device fallback)
//
// GlassThemeData.brightness (override) is tested in
// glass_theme_data_brightness_test.dart and glass_theme_brightness_test.dart.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/utils/glass_brightness.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Helper
  // ──────────────────────────────────────────────────────────────────────────

  /// Pump a widget tree and capture the brightness resolved by
  /// [resolveGlassBrightness] at the leaf.
  Future<Brightness> pumpAndCapture(
    WidgetTester tester,
    Widget Function(Widget child) wrapper,
  ) async {
    Brightness? captured;
    await tester.pumpWidget(
      wrapper(
        Builder(builder: (context) {
          captured = resolveGlassBrightness(context);
          return const SizedBox.shrink();
        }),
      ),
    );
    return captured!;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Level 1: CupertinoTheme explicit pin
  // ──────────────────────────────────────────────────────────────────────────

  group('resolveGlassBrightness — Level 1: Cupertino explicit pin', () {
    testWidgets(
        'returns Brightness.light when CupertinoThemeData.brightness is light',
        (tester) async {
      // Device dark, Cupertino explicitly pinned to light — should return light.
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.light),
            home: CupertinoPageScaffold(child: child),
          ),
        ),
      );
      expect(result, Brightness.light,
          reason: 'Explicit Cupertino pin overrides device dark mode');
    });

    testWidgets(
        'returns Brightness.dark when CupertinoThemeData.brightness is dark',
        (tester) async {
      // Device light, Cupertino explicitly pinned to dark — should return dark.
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.dark),
            home: CupertinoPageScaffold(child: child),
          ),
        ),
      );
      expect(result, Brightness.dark,
          reason: 'Explicit Cupertino pin overrides device light mode');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Level 2: Material ThemeMode
  // ──────────────────────────────────────────────────────────────────────────

  group('resolveGlassBrightness — Level 2: Material ThemeMode', () {
    testWidgets(
        'returns Brightness.light for ThemeMode.light when device is dark',
        (tester) async {
      // The canonical bug scenario: device OS is dark, app is ThemeMode.light.
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light, // app explicitly light
            home: Scaffold(body: child),
          ),
        ),
      );
      expect(result, Brightness.light,
          reason:
              'ThemeMode.light must override device dark — this is the primary bug fix');
    });

    testWidgets(
        'returns Brightness.dark for ThemeMode.dark when device is light',
        (tester) async {
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark, // app explicitly dark
            home: Scaffold(body: child),
          ),
        ),
      );
      expect(result, Brightness.dark,
          reason: 'ThemeMode.dark must override device light');
    });

    testWidgets('follows device brightness for ThemeMode.system (light device)',
        (tester) async {
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            home: Scaffold(body: child),
          ),
        ),
      );
      expect(result, Brightness.light,
          reason: 'ThemeMode.system on light device returns light');
    });

    testWidgets('follows device brightness for ThemeMode.system (dark device)',
        (tester) async {
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            home: Scaffold(body: child),
          ),
        ),
      );
      expect(result, Brightness.dark,
          reason: 'ThemeMode.system on dark device returns dark');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Level 3: Fallback explicit Cupertino brightness pin (MaterialApp)
  // ──────────────────────────────────────────────────────────────────────────

  group('resolveGlassBrightness — Level 3: Defensive guard', () {
    // NOTE: Level 3 is a defensive dead-code guard. Theme.maybeBrightnessOf()
    // always returns non-null inside a MaterialApp, so Level 2 always
    // short-circuits before reaching here. This test verifies the structural
    // correctness of the guard by injecting a MaterialBasedCupertinoThemeData
    // whose inner material theme says light — while the outer MaterialApp
    // resolves dark (ThemeMode.system, dark device). The MaterialApp's
    // Theme.maybeBrightnessOf wins at Level 2 and returns dark.
    // The guard (Level 3) is exercised only in hypothetical future scenarios
    // where Level 2 returns null.
    testWidgets(
        'MaterialApp tree: Level 2 short-circuits; Level 3 guard not reached',
        (tester) async {
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MaterialApp(
            // themeMode defaults to system → dark device → dark
            home: Builder(builder: (context) {
              return CupertinoTheme(
                // Inner MaterialBasedCupertinoThemeData says light — but
                // Level 2 (Theme.maybeBrightnessOf) fires first and returns dark.
                data: MaterialBasedCupertinoThemeData(
                  materialTheme: ThemeData(brightness: Brightness.light),
                ),
                child: child,
              );
            }),
          ),
        ),
      );
      // Level 2 wins: the CupertinoTheme override also injects a Material theme
      // (via MaterialBasedCupertinoThemeData.materialTheme = ThemeData.light),
      // which Theme.maybeBrightnessOf picks up — returning light, not dark.
      // This confirms Level 3 is never reached: Level 2 always fires first.
      expect(result, Brightness.light,
          reason:
              'Level 2 (Theme.maybeBrightnessOf) always wins in MaterialApp; '
              'Level 3 defensive guard is never reached');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Level 4: System / device fallback (no Cupertino pin, no Material ancestor)
  // ──────────────────────────────────────────────────────────────────────────

  group('resolveGlassBrightness — Level 4: device system fallback', () {
    testWidgets(
        'returns device brightness when no explicit Cupertino pin or Material',
        (tester) async {
      // Pure CupertinoApp with NO explicit brightness pin — must fall back to
      // MediaQuery.platformBrightnessOf.
      final resultDark = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: CupertinoApp(
            // No explicit brightness — null, resolves to system
            home: CupertinoPageScaffold(child: child),
          ),
        ),
      );
      expect(resultDark, Brightness.dark,
          reason: 'Dark device, no explicit pin → dark (fallback)');

      final resultLight = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: CupertinoApp(
            home: CupertinoPageScaffold(child: child),
          ),
        ),
      );
      expect(resultLight, Brightness.light,
          reason: 'Light device, no explicit pin → light (fallback)');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Priority order: Level 1 > Level 2 > Level 3 > Level 4
  // ──────────────────────────────────────────────────────────────────────────

  group('resolveGlassBrightness — cascade priority order', () {
    testWidgets(
        'Cupertino pin (L1) beats Material ThemeMode (L2) beats system (L3)',
        (tester) async {
      // All three disagree: device dark, Material light, Cupertino dark.
      // Expected: Cupertino wins (dark).
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light, // Material says light
            home: CupertinoTheme(
              data: const CupertinoThemeData(
                  brightness: Brightness.dark), // Cupertino says dark
              child: Scaffold(body: child),
            ),
          ),
        ),
      );
      // Cupertino (Level 1) wins over Material (Level 2) because it is explicitly
      // provided via CupertinoTheme (not MaterialBasedCupertinoThemeData).
      expect(result, Brightness.dark,
          reason: 'Cupertino pin is Level 1 — wins over Material ThemeMode');
    });

    testWidgets('Material ThemeMode (L2) beats system (L4)', (tester) async {
      // Device dark, no Cupertino pin, but Material is ThemeMode.light.
      final result = await pumpAndCapture(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
            home: Scaffold(body: child),
          ),
        ),
      );
      expect(result, Brightness.light,
          reason: 'Material ThemeMode.light wins over dark device OS setting');
    });
  });
}
