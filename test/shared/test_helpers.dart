import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';

/// Standard constraints for golden test scenarios
final testScenarioConstraints = BoxConstraints.tight(const Size(500, 500));

/// Glass settings without lighting effects for predictable golden tests
const settingsWithoutLighting = LiquidGlassSettings(
  chromaticAberration: 0,
  lightIntensity: 0,
  blur: 0,
);

/// Default glass settings for widget tests
/// Note: Tests should use fake: true on LiquidGlassLayer to avoid shader loading
const defaultTestGlassSettings = LiquidGlassSettings(
  thickness: 30,
  blur: 3,
  refractiveIndex: 1.59,
);

/// Wraps a widget with grid paper background for visual reference in golden tests
Widget buildWithGridPaper(Widget child) {
  return ColoredBox(
    color: Colors.white,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          const Positioned.fill(
            child: GridPaper(
              color: Colors.black,
            ),
          ),
          Center(
            child: child,
          ),
        ],
      ),
    ),
  );
}

/// Wraps a widget with a colorful gradient background for contrast
/// For golden tests: automatically wraps LiquidGlassLayer children with fake: true
Widget buildWithGradientBackground(Widget child) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
          Color(0xFFEC4899),
        ],
      ),
    ),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// Wraps a widget with gradient background AND a glass layer for golden tests
/// Uses backdrop filter mode to avoid shader asset issues
Widget buildWithGradientAndGlass(Widget child,
    {LiquidGlassSettings? settings}) {
  return buildWithGradientBackground(
    AdaptiveLiquidGlassLayer(
      // Use backdrop filter for tests
      settings: settings ?? defaultTestGlassSettings,
      child: child,
    ),
  );
}

/// Creates a standard test wrapper with MaterialApp for widget tests
Widget createTestApp({
  required Widget child,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ??
        ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.transparent,
        ),
    home: Scaffold(
      backgroundColor: Colors.transparent,
      body: child,
    ),
  );
}

/// Creates a test wrapper with a LiquidGlassLayer configured for testing
/// Uses backdrop filter mode to avoid shader loading issues
Widget createTestAppWithGlassLayer({
  required Widget child,
  LiquidGlassSettings? settings,
  ThemeData? theme,
}) {
  return createTestApp(
    theme: theme,
    child: AdaptiveLiquidGlassLayer(
      // Use backdrop filter to avoid shader issues in tests
      settings: settings ?? defaultTestGlassSettings,
      child: child,
    ),
  );
}
