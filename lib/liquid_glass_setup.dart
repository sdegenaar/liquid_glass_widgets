import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'widgets/shared/lightweight_liquid_glass.dart';
import 'widgets/shared/glass_effect.dart';

/// Entry point and configuration for the Liquid Glass Widgets library.
///
/// Use this class to initialize global resources, such as precaching shaders
/// to prevent visual glitches during first-time rendering.
class LiquidGlassWidgets {
  LiquidGlassWidgets._();

  /// Initializes the Liquid Glass library.
  ///
  /// This should be called in your `main()` function:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await LiquidGlassWidgets.initialize();
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// Tasks performed:
  /// 1. Pre-warms/precaches the lightweight fragment shader.
  /// 2. Pre-warms the interactive indicator shader (for custom refraction).
  /// 3. (Future) Pre-warms Impeller pipelines if required.
  static Future<void> initialize() async {
    debugPrint('[LiquidGlass] Initializing library...');

    // 1. Pre-warm shaders
    // This is the most critical step to prevent the "white flash" on Skia/Web
    await Future.wait([
      LightweightLiquidGlass.preWarm(),
      GlassEffect.preWarm(),
    ]);

    debugPrint('[LiquidGlass] Initialization complete.');
  }

  /// Global settings override for the entire application.
  ///
  /// If provided, these settings will be used as the base for all glass widgets
  /// unless overridden at the individual widget or layer level.
  static LiquidGlassSettings? globalSettings;
}
