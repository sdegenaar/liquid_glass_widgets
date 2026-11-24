// ignore_for_file: public_member_api_docs
// Internal: preserves user-authored subtree [GlassTheme] and [CupertinoTheme]
// overrides across modal route / overlay boundaries without freezing app-level
// themes that already live above the target [Navigator] or [Overlay].

import 'package:flutter/cupertino.dart';

import '../../../theme/glass_theme.dart';
import '../../../theme/glass_theme_data.dart';

/// Marks an internal [CupertinoTheme] wrapper created by the library itself
/// (such as `GlassScaffold`'s brightness sync, `GlassContentAwareScope`'s
/// luminance-adaptive bar theme, or [CapturedModalThemes]'s own live bridge)
/// so [CapturedModalThemes.capture] skips it when walking ancestors.
class GlassInternalCupertinoTheme extends StatelessWidget {
  const GlassInternalCupertinoTheme({
    super.key,
    required this.data,
    required this.child,
  });

  final CupertinoThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CupertinoTheme(data: data, child: child);
}

/// Marks an internal [GlassTheme] wrapper created by the library itself (such
/// as `GlassContentAwareScope`'s transient luminance-adaptive bar theme) so
/// [CapturedModalThemes.capture] skips it when walking ancestors.
class GlassInternalGlassTheme extends StatelessWidget {
  const GlassInternalGlassTheme({
    super.key,
    required this.data,
    required this.child,
  });

  final GlassThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) => GlassTheme(data: data, child: child);
}

/// Captures any user-authored [GlassTheme] or [CupertinoTheme] declared
/// strictly between `from` and `to` (typically a [NavigatorState.context] or
/// [OverlayState.context]).
///
/// Themes declared at or above `to` (such as an app-level `MaterialApp`,
/// `CupertinoApp`, or root `GlassTheme`) are intentionally **not** captured so
/// long-lived modals keep reacting live to OS brightness switches, `ThemeMode`
/// changes, and programmatic theme updates.
///
/// Unlike [InheritedTheme.capture], this only captures [GlassTheme] and
/// [CupertinoTheme], avoiding leaking trigger-local [DefaultTextStyle] or
/// [IconTheme] overrides (e.g. from a `GlassButton`) into the presented modal.
class CapturedModalThemes {
  const CapturedModalThemes({
    this.glassTheme,
    this.cupertinoTheme,
  });

  /// Captures user-authored themes between [context] and the target
  /// [Navigator] resolved with [useRootNavigator].
  factory CapturedModalThemes.forNavigator(
    BuildContext context, {
    bool useRootNavigator = false,
  }) {
    final target =
        Navigator.of(context, rootNavigator: useRootNavigator).context;
    return CapturedModalThemes.capture(from: context, to: target);
  }

  /// Captures user-authored themes between [context] and the target [Overlay].
  factory CapturedModalThemes.forOverlay(BuildContext context) {
    final target = Overlay.of(context).context;
    return CapturedModalThemes.capture(from: context, to: target);
  }

  /// Walks ancestors from [from] up to (but not including) [to] without
  /// registering inherited dependencies on either context.
  factory CapturedModalThemes.capture({
    required BuildContext from,
    required BuildContext to,
  }) {
    GlassThemeData? glassTheme;
    CupertinoThemeData? cupertinoTheme;
    GlassThemeData? pendingGlass;
    CupertinoThemeData? pendingCupertino;

    void flushPending() {
      glassTheme ??= pendingGlass;
      cupertinoTheme ??= pendingCupertino;
      pendingGlass = null;
      pendingCupertino = null;
    }

    bool visit(Element element) {
      final widget = element.widget;

      // Any pending theme from the immediate child element is synthetic if its
      // direct parent is one of our internal theme bridges; otherwise lock it.
      if (pendingGlass != null) {
        if (widget is GlassInternalGlassTheme) {
          pendingGlass = null;
        } else {
          glassTheme ??= pendingGlass;
          pendingGlass = null;
        }
      }
      if (pendingCupertino != null) {
        if (widget is GlassInternalCupertinoTheme) {
          pendingCupertino = null;
        } else {
          cupertinoTheme ??= pendingCupertino;
          pendingCupertino = null;
        }
      }

      if (identical(element, to)) return false;

      if (glassTheme != null && cupertinoTheme != null) return false;

      if (glassTheme == null && widget is GlassTheme) {
        pendingGlass = widget.data;
      } else if (cupertinoTheme == null && widget is CupertinoTheme) {
        pendingCupertino = widget.data;
      }
      return true;
    }

    if (!identical(from, to)) {
      if (from is Element) {
        if (visit(from)) {
          from.visitAncestorElements(visit);
        }
      } else {
        from.visitAncestorElements(visit);
      }
      flushPending();
    }

    return CapturedModalThemes(
      glassTheme: glassTheme,
      cupertinoTheme: cupertinoTheme,
    );
  }

  final GlassThemeData? glassTheme;
  final CupertinoThemeData? cupertinoTheme;

  /// Wraps [child] with any captured subtree-local themes plus a live
  /// brightness sync bridge so `CupertinoColors.*.resolveFrom(context)` stays
  /// in sync with [GlassTheme.brightnessOf] as system brightness or app theme
  /// changes while the modal is open.
  Widget wrap(Widget child) {
    Widget result = _LiveModalBrightnessScope(child: child);
    if (cupertinoTheme != null) {
      result = CupertinoTheme(data: cupertinoTheme!, child: result);
    }
    if (glassTheme != null) {
      result = GlassTheme(data: glassTheme!, child: result);
    }
    return result;
  }

  /// Convenience wrapper around [wrap] for modal bodies that read the resolved
  /// theme from a [Builder] context.
  Widget wrapBuilder(WidgetBuilder builder) => wrap(Builder(builder: builder));
}

/// Keeps descendant [CupertinoTheme] brightness synchronized live with
/// [GlassTheme.brightnessOf] without ever changing element tree depth.
///
/// Preserves `currentCupertino.brightness == null` when it already resolves to
/// the same brightness via `MediaQuery.platformBrightnessOf`, so local
/// `MediaQuery(platformBrightness: ...)` subtrees inside a modal keep working.
class _LiveModalBrightnessScope extends StatelessWidget {
  const _LiveModalBrightnessScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolvedBrightness = GlassTheme.brightnessOf(context);
    final currentCupertino = CupertinoTheme.of(context);
    final effectiveCupertinoBrightness =
        currentCupertino.brightness ?? MediaQuery.platformBrightnessOf(context);
    final effectiveCupertino =
        effectiveCupertinoBrightness == resolvedBrightness
            ? currentCupertino
            : currentCupertino.copyWith(brightness: resolvedBrightness);
    return GlassInternalCupertinoTheme(
      data: effectiveCupertino,
      child: child,
    );
  }
}
