import 'package:flutter/widgets.dart';

/// A scope that provides infrastructure for automatic glass refraction.
///
/// Place [LiquidGlassScope] at the root of a stack or page. It provides a
/// [GlobalKey] that descendant glass widgets can use to find their background.
///
/// Unlike the previous version, this scope **does not** wrap its child in a
/// [RepaintBoundary] by default. Instead, you must use [LiquidGlassBackground]
/// to mark the specific widget(s) you want to be available for refraction.
///
/// Usage:
/// ```dart
/// LiquidGlassScope(
///   child: Stack(
///     children: [
///       // 1. Mark the background as the refraction source
///       LiquidGlassBackground(
///         child: Image.asset('wallpaper.jpg'),
///       ),
///
///       // 2. Glass widgets will automatically see the background
///       Center(child: GlassSegmentedControl(...)),
///     ],
///   ),
/// )
/// ```
class LiquidGlassScope extends StatefulWidget {
  const LiquidGlassScope({
    required this.child,
    super.key,
  });

  final Widget child;

  /// Returns the background key from the nearest ancestor scope.
  static GlobalKey? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedLiquidGlassScope>()
        ?.backgroundKey;
  }

  @override
  State<LiquidGlassScope> createState() => _LiquidGlassScopeState();
}

class _LiquidGlassScopeState extends State<LiquidGlassScope> {
  // Create the key ONCE and keep it stable across rebuilds
  final GlobalKey _backgroundKey =
      GlobalKey(debugLabel: 'LiquidGlassBackground');

  @override
  Widget build(BuildContext context) {
    return _InheritedLiquidGlassScope(
      backgroundKey: _backgroundKey,
      child: widget.child,
    );
  }
}

/// Marks a descendant of [LiquidGlassScope] as the refraction source.
/// Only the content inside this widget will be captured for glass refraction.
class LiquidGlassBackground extends StatelessWidget {
  const LiquidGlassBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final key = LiquidGlassScope.of(context);

    // If no scope is found, we just return the child.
    // This allows the background to stay visible even if refraction is disabled.
    if (key == null) return child;

    return RepaintBoundary(
      key: key,
      child: child,
    );
  }
}

class _InheritedLiquidGlassScope extends InheritedWidget {
  const _InheritedLiquidGlassScope({
    required this.backgroundKey,
    required super.child,
  });

  final GlobalKey backgroundKey;

  @override
  bool updateShouldNotify(_InheritedLiquidGlassScope oldWidget) {
    return backgroundKey != oldWidget.backgroundKey;
  }
}
