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

  /// Convenience constructor for the common pattern of a background behind content.
  ///
  /// This eliminates the boilerplate of manually creating a Stack with Positioned.fill
  /// widgets. It's equivalent to:
  ///
  /// ```dart
  /// LiquidGlassScope(
  ///   child: Stack(
  ///     children: [
  ///       Positioned.fill(
  ///         child: LiquidGlassBackground(child: background),
  ///       ),
  ///       Positioned.fill(child: content),
  ///     ],
  ///   ),
  /// )
  /// ```
  ///
  /// Example:
  /// ```dart
  /// LiquidGlassScope.stack(
  ///   background: Image.asset('wallpaper.jpg', fit: BoxFit.cover),
  ///   content: Scaffold(
  ///     body: MyContent(),
  ///     bottomNavigationBar: GlassBottomBar(...),
  ///   ),
  /// )
  /// ```
  factory LiquidGlassScope.stack({
    Key? key,
    required Widget background,
    required Widget content,
  }) {
    return LiquidGlassScope(
      key: key,
      child: Stack(
        children: [
          Positioned.fill(
            child: LiquidGlassBackground(child: background),
          ),
          content, // Don't wrap in Positioned - let it naturally fill
        ],
      ),
    );
  }

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
    assert(() {
      // Warn if nesting scopes (usually unintentional)
      final parentScope = context
          .dependOnInheritedWidgetOfExactType<_InheritedLiquidGlassScope>();
      if (parentScope != null) {
        debugPrint(
          '⚠️ [LiquidGlassScope] Warning: Nested LiquidGlassScope detected.\n'
          '   Inner scope will override outer scope for descendant widgets.\n'
          '   This is usually intentional for isolated demos, but may be unexpected.\n'
          '   If you want a single shared background, use only one scope at the root.',
        );
      }
      return true;
    }());

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

    assert(() {
      // Inform developer if no scope is found
      if (key == null) {
        debugPrint(
          'ℹ️ [LiquidGlassBackground] Info: No LiquidGlassScope found.\n'
          '   Background will be visible but won\'t be available for refraction.\n'
          '   Wrap your widget tree with LiquidGlassScope to enable refraction.',
        );
      }
      return true;
    }());

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
