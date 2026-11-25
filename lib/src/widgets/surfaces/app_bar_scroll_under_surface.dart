// ignore_for_file: public_member_api_docs
// Internal: iOS 27 scroll-under blurred surface and GlassScaffold coordination
// for [GlassAppBar] and [GlassAppBar.pinned].
//
// Calibrated against live iOS 27.0 and iOS 26.0 simulators (`UIKit`
// `UINavigationController` and `SwiftUI` `NavigationStack`):
//
// - On iOS 26.0, `.automatic` resolves to `.soft` (`_UIScrollPocket`, graduated
//   variable blur extending ~65 pt below the bar, no bottom border).
// - On iOS 27.0, `.automatic` resolves to `.hard` (`UIKit.ScrollEdgeEffectView`,
//   spanning exact status-bar + nav-bar bounds, `alpha = 0` at scroll offset 0,
//   full-width backdrop blur with a subtle airy frost veil that preserves vivid
//   wallpapers, and a 1-physical-pixel (`1 / devicePixelRatio`) hairline bottom
//   border at `#000000 @ 0.10` in light mode and `#FFFFFF @ 0.10` in dark mode).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../../../theme/glass_theme.dart';
import '../../../types/glass_style.dart';
import '../../../widgets/shared/glass_accessibility_scope.dart';
import '../../../widgets/surfaces/glass_app_bar.dart'
    show GlassAppBarSurfaceStyle;

/// Default scroll distance (in logical pixels) over which the scroll-under
/// surface fades from transparent to full strength, matching
/// `CupertinoNavigationBar.automaticBackgroundVisibility`.
const double kGlassAppBarSurfaceAppearanceExtent = 10.0;

/// Default Gaussian blur sigma (in logical pixels) for
/// [GlassAppBarSurfaceStyle.fullBlur] when fully scrolled under.
const double kGlassAppBarBackdropBlurSigma = 20.0;

/// Light-mode translucent frost tint for [GlassAppBarSurfaceStyle.fullBlur].
///
/// Airy enough to preserve vivid wallpapers (matching iOS 27's
/// `ScrollEdgeEffectView`) while producing crisp frosted separation over light
/// pages when paired with the Gaussian blur.
const Color kGlassAppBarBlurTintLight = Color(0x38FFFFFF);

/// Dark-mode translucent frost tint for [GlassAppBarSurfaceStyle.fullBlur].
const Color kGlassAppBarBlurTintDark = Color(0x4D1C1C1E);

/// High-opacity light fallback fill when Reduce Transparency is active.
const Color kGlassAppBarReduceTransparencyTintLight = Color(0xF5F8F8F8);

/// High-opacity dark fallback fill when Reduce Transparency is active.
const Color kGlassAppBarReduceTransparencyTintDark = Color(0xF51C1C1E);

/// Light-mode hairline bottom border colour measured from iOS 27.0
/// `UIKit.ScrollEdgeEffectView` (`#000000 @ 0.10`).
const Color kGlassAppBarHairlineLight = Color(0x1A000000);

/// Dark-mode hairline bottom border colour measured from iOS 27.0
/// `UIKit.ScrollEdgeEffectView` (`#FFFFFF @ 0.10`).
const Color kGlassAppBarHairlineDark = Color(0x1AFFFFFF);

/// Higher-contrast light hairline colour used under Reduce Transparency.
const Color kGlassAppBarHairlineHighContrastLight = Color(0x40000000);

/// Higher-contrast dark hairline colour used under Reduce Transparency.
const Color kGlassAppBarHairlineHighContrastDark = Color(0x40FFFFFF);

/// Resolves whether a [GlassAppBar] should render the iOS 27 scroll-under
/// full-blur surface.
///
/// Shared between [GlassScaffold] (to suppress its default `.soft` top edge
/// fade and avoid double-edge artifacts) and [GlassAppBar] (to decide whether
/// to mount [GlassAppBarScrollUnderSurface]).
bool resolveGlassAppBarUsesFullBlur({
  required GlassAppBarSurfaceStyle surfaceStyle,
  required Color backgroundColor,
  required GlassStyle glassStyle,
  required bool inDuoStripOrStatusRow,
  required bool scaffoldExplicitTopEdge,
}) {
  if (inDuoStripOrStatusRow) return false;
  return switch (surfaceStyle) {
    GlassAppBarSurfaceStyle.transparent => false,
    GlassAppBarSurfaceStyle.fullBlur => true,
    GlassAppBarSurfaceStyle.automatic => backgroundColor.a == 0.0 &&
        glassStyle == GlassStyle.ios27 &&
        !scaffoldExplicitTopEdge,
  };
}

/// Internal scope published by [GlassScaffold] around its `appBar` slot so
/// [GlassAppBarSurfaceStyle.automatic] yields whenever the caller explicitly
/// customized [GlassScaffold]'s top scroll-edge effect or disabled
/// [GlassScaffold.extendBody] (so content never scrolls behind the bar).
class GlassScaffoldTopEdgePolicy extends InheritedWidget {
  const GlassScaffoldTopEdgePolicy({
    super.key,
    required this.suppressAutomaticFullBlur,
    required super.child,
  });

  final bool suppressAutomaticFullBlur;

  static bool suppressesAutomaticFullBlurOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<GlassScaffoldTopEdgePolicy>()
            ?.suppressAutomaticFullBlur ??
        false;
  }

  @override
  bool updateShouldNotify(GlassScaffoldTopEdgePolicy oldWidget) =>
      suppressAutomaticFullBlur != oldWidget.suppressAutomaticFullBlur;
}

Color _resolveColorForBrightness(
  Color color,
  BuildContext context, {
  required Brightness brightness,
}) {
  if (color is! CupertinoDynamicColor) return color;
  final cupertinoBrightness = CupertinoTheme.maybeBrightnessOf(context);
  if (cupertinoBrightness == brightness) {
    return CupertinoDynamicColor.resolve(color, context);
  }
  final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
  final elevated = CupertinoUserInterfaceLevel.maybeOf(context) ==
      CupertinoUserInterfaceLevelData.elevated;
  final isDark = brightness == Brightness.dark;
  return switch ((isDark, highContrast, elevated)) {
    (false, false, false) => color.color,
    (true, false, false) => color.darkColor,
    (false, true, false) => color.highContrastColor,
    (true, true, false) => color.darkHighContrastColor,
    (false, false, true) => color.elevatedColor,
    (true, false, true) => color.darkElevatedColor,
    (false, true, true) => color.highContrastElevatedColor,
    (true, true, true) => color.darkHighContrastElevatedColor,
  };
}

/// Sibling background surface painted behind [GlassAppBar]'s content and glass
/// buttons when [GlassAppBarSurfaceStyle.fullBlur] is active.
///
/// Subscribes to the enclosing [ScrollNotificationObserver] and updates only
/// its own [ValueListenableBuilder] during the `0..appearanceExtent` scroll
/// ramp — zero rebuilds on [GlassAppBar] itself, zero `BackdropFilter` mounted
/// at scroll offset 0, and zero rebuilds once fully scrolled under.
class GlassAppBarScrollUnderSurface extends StatefulWidget {
  const GlassAppBarScrollUnderSurface({
    super.key,
    required this.automaticVisibility,
    required this.appearanceExtent,
    required this.blurSigma,
    required this.tint,
    required this.bottomBorder,
    required this.notificationPredicate,
  });

  final bool automaticVisibility;
  final double appearanceExtent;
  final double blurSigma;
  final Color? tint;
  final BorderSide? bottomBorder;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<GlassAppBarScrollUnderSurface> createState() =>
      _GlassAppBarScrollUnderSurfaceState();
}

class _GlassAppBarScrollUnderSurfaceState
    extends State<GlassAppBarScrollUnderSurface> {
  ScrollNotificationObserverState? _scrollNotificationObserver;
  late final ValueNotifier<double> _visibility = ValueNotifier<double>(
    widget.automaticVisibility ? 0.0 : 1.0,
  );
  double _lastExtentUnderBar = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncScrollObserver();
  }

  @override
  void didUpdateWidget(GlassAppBarScrollUnderSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.automaticVisibility != oldWidget.automaticVisibility) {
      _syncScrollObserver();
    }
    if (widget.automaticVisibility != oldWidget.automaticVisibility ||
        widget.appearanceExtent != oldWidget.appearanceExtent) {
      _recomputeVisibility();
    }
  }

  void _syncScrollObserver() {
    final ScrollNotificationObserverState? nextObserver =
        widget.automaticVisibility
            ? ScrollNotificationObserver.maybeOf(context)
            : null;
    if (nextObserver == _scrollNotificationObserver) return;
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = nextObserver;
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (!widget.automaticVisibility) return;
    if (!widget.notificationPredicate(notification)) return;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollMetricsNotification) {
      return;
    }
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;

    final double extentUnderBar = switch (metrics.axisDirection) {
      AxisDirection.down => metrics.extentBefore,
      AxisDirection.up => metrics.extentAfter,
      AxisDirection.left || AxisDirection.right => 0.0,
    };
    _lastExtentUnderBar = extentUnderBar > 0.0 ? extentUnderBar : 0.0;
    _recomputeVisibility();
  }

  void _recomputeVisibility() {
    final double next;
    if (!widget.automaticVisibility) {
      next = 1.0;
    } else if (widget.appearanceExtent <= 0.0) {
      next = _lastExtentUnderBar > 0.0 ? 1.0 : 0.0;
    } else {
      next = (_lastExtentUnderBar / widget.appearanceExtent).clamp(0.0, 1.0);
    }
    final double current = _visibility.value;
    if ((next - current).abs() > 1e-4 ||
        (next == 0.0 && current != 0.0) ||
        (next == 1.0 && current != 1.0)) {
      _visibility.value = next;
    }
  }

  @override
  void dispose() {
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
    _visibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = GlassTheme.brightnessOf(context);
    final bool isDark = brightness == Brightness.dark;
    final bool reduceTransparency =
        GlassAccessibilityData.of(context).reduceTransparency;
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final double hairlineWidth = dpr > 0.0 ? 1.0 / dpr : 0.5;

    final Color? explicitTint = widget.tint == null
        ? null
        : _resolveColorForBrightness(
            widget.tint!,
            context,
            brightness: brightness,
          );
    final Color baseTint;
    if (reduceTransparency) {
      if (explicitTint != null) {
        baseTint = explicitTint.withValues(
          alpha: math.max(explicitTint.a, 0.96),
        );
      } else {
        baseTint = isDark
            ? kGlassAppBarReduceTransparencyTintDark
            : kGlassAppBarReduceTransparencyTintLight;
      }
    } else {
      baseTint = explicitTint ??
          (isDark ? kGlassAppBarBlurTintDark : kGlassAppBarBlurTintLight);
    }

    final BorderSide? explicitBorder = widget.bottomBorder;
    final BorderSide resolvedBorderSide;
    if (explicitBorder != null && explicitBorder.style == BorderStyle.none) {
      resolvedBorderSide = BorderSide.none;
    } else if (explicitBorder != null) {
      resolvedBorderSide = explicitBorder.copyWith(
        color: _resolveColorForBrightness(
          explicitBorder.color,
          context,
          brightness: brightness,
        ),
        width:
            explicitBorder.width == 0.0 ? hairlineWidth : explicitBorder.width,
      );
    } else {
      final Color hairlineColor = reduceTransparency
          ? (isDark
              ? kGlassAppBarHairlineHighContrastDark
              : kGlassAppBarHairlineHighContrastLight)
          : (isDark ? kGlassAppBarHairlineDark : kGlassAppBarHairlineLight);
      resolvedBorderSide = BorderSide(
        color: hairlineColor,
        width: hairlineWidth,
      );
    }

    return IgnorePointer(
      child: ValueListenableBuilder<double>(
        valueListenable: _visibility,
        builder: (context, visibility, _) {
          if (visibility <= 0.0) return const SizedBox.shrink();

          final Color effectiveTint = baseTint.withValues(
            alpha: baseTint.a * visibility,
          );
          final Border? effectiveBorder = resolvedBorderSide == BorderSide.none
              ? null
              : Border(
                  bottom: resolvedBorderSide.copyWith(
                    color: resolvedBorderSide.color.withValues(
                      alpha: resolvedBorderSide.color.a * visibility,
                    ),
                  ),
                );

          final Widget decorated = DecoratedBox(
            decoration: BoxDecoration(
              color: effectiveTint,
              border: effectiveBorder,
            ),
            child: const SizedBox.expand(),
          );

          final double sigma =
              reduceTransparency ? 0.0 : widget.blurSigma * visibility;
          if (sigma <= 0.0) {
            return decorated;
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: ui.TileMode.clamp,
              ),
              child: decorated,
            ),
          );
        },
      ),
    );
  }
}
