import 'package:flutter/widgets.dart';

/// An [InheritedWidget] that tells descendant glass widgets whether to use
/// their own independent glass rendering layer or share the nearest ancestor's.
///
/// This is a zero-cost scope marker — it doesn't create any glass rendering
/// context, shader, or compositing layer. It simply provides a signal that
/// descendant [AdaptiveGlass] widgets check to decide whether to use
/// `useOwnLayer: true`.
///
/// ## How nesting works
///
/// [GlassScaffold] wraps app bar and bottom bar in
/// `GlassIsolationScope(isolated: true)` — this prevents body glass cards
/// from compositing over the bar buttons in the shared page-level layer.
///
/// Each [AdaptiveLiquidGlassLayer] wraps its children in
/// `GlassIsolationScope(isolated: false)` — this tells glass widgets inside
/// the bar to participate in the bar's own grouped layer, not render
/// independently.
///
/// The nearest ancestor wins (standard [InheritedWidget] lookup), so:
/// ```
/// GlassPage → AdaptiveLiquidGlassLayer (isolated: false by default)
///   → GlassIsolationScope(isolated: true)   ← scaffold bar wrapper
///     → GlassBottomBar
///       → AdaptiveLiquidGlassLayer          ← bar de-isolates (false)
///         → tab items see isolated=false    ← use bar's grouped layer ✅
/// ```
class GlassIsolationScope extends InheritedWidget {
  /// Creates a glass isolation scope.
  ///
  /// When [isolated] is `true` (default), descendant glass widgets render
  /// with their own independent layer. When `false`, they participate in the
  /// nearest ancestor [AdaptiveLiquidGlassLayer]'s grouped rendering.
  const GlassIsolationScope({
    super.key,
    this.isolated = true,
    required super.child,
  });

  /// Whether descendants should be isolated from ancestor glass layers.
  final bool isolated;

  /// Returns `true` if the given [context] is inside an active
  /// [GlassIsolationScope] with `isolated: true`.
  ///
  /// Used by [AdaptiveGlass] to decide whether to force `useOwnLayer: true`.
  static bool isIsolated(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GlassIsolationScope>();
    return scope?.isolated ?? false;
  }

  @override
  bool updateShouldNotify(GlassIsolationScope oldWidget) =>
      isolated != oldWidget.isolated;
}

