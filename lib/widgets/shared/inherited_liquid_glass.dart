import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A custom inherited widget that provides [LiquidGlassSettings] to descendants.
///
/// This is used by [AdaptiveLiquidGlassLayer] to ensure that settings are
/// passed down to children even when the underlying renderer is using a
/// fallback implementation (like `LightweightLiquidGlass` on Skia/Web) that
/// might not have its own inherited widget provider exposed.
class InheritedLiquidGlass extends InheritedWidget {
  /// Creates an inherited widget that holds [LiquidGlassSettings].
  const InheritedLiquidGlass({
    required this.settings,
    required super.child,
    super.key,
  });

  /// The glass settings to share with the subtree.
  final LiquidGlassSettings settings;

  /// Retrieves the nearest [LiquidGlassSettings] from the ancestor tree.
  ///
  /// This checks for [InheritedLiquidGlass] first. If not found, it attempts
  /// to look up `LiquidGlassSettings.of(context)` from the renderer package
  /// to maintain compatibility with standard `LiquidGlassLayer` usage.
  static LiquidGlassSettings? of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>();
    if (inherited != null) {
      return inherited.settings;
    }

    // Fallback to the renderer's provider if available
    try {
      return LiquidGlassSettings.of(context);
    } catch (_) {
      // LiquidGlassSettings.of() might throw or return default if not found,
      // dependent on implementation. We return null if we can't find it.
      return null;
    }
  }

  /// Retrieves the [LiquidGlassSettings] from the ancestor tree, falling back to
  /// a default instance if none is found.
  static LiquidGlassSettings ofOrDefault(BuildContext context) {
    return of(context) ?? const LiquidGlassSettings();
  }

  @override
  bool updateShouldNotify(InheritedLiquidGlass oldWidget) {
    return settings != oldWidget.settings;
  }
}
