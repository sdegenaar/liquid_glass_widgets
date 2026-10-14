import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import '../interactive/glass_button.dart';

/// Alignment position for the standard close button in [GlassFullScreenCoverBar].
enum GlassFullScreenCoverClosePosition {
  /// Position the close button on the trailing (top-right in LTR) edge.
  trailing,

  /// Position the close button on the leading (top-left in LTR) edge.
  leading,

  /// Do not show an automatic close button.
  none,
}

/// An authentic iOS 26/27 full-screen modal top bar with liquid glass materials,
/// supporting centered titles, circular frosted close pills, and text actions.
class GlassFullScreenCoverBar extends StatelessWidget {
  /// Creates a [GlassFullScreenCoverBar].
  const GlassFullScreenCoverBar({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.closeButtonPosition = GlassFullScreenCoverClosePosition.trailing,
    this.onClose,
    this.closeButtonLabel,
    this.showDragHandle = false,
    this.backgroundColor,
    this.settings,
    this.quality,
    this.height = 44.0,
  });

  /// Primary title widget or text.
  final Widget? title;

  /// Custom widget positioned on the leading edge.
  final Widget? leading;

  /// Custom widget positioned on the trailing edge.
  final Widget? trailing;

  /// Position of the automatic close button (defaults to [GlassFullScreenCoverClosePosition.trailing]).
  final GlassFullScreenCoverClosePosition closeButtonPosition;

  /// Callback executed when the close button is pressed.
  /// If null, defaults to `Navigator.of(context).maybePop()`.
  final VoidCallback? onClose;

  /// Optional text label for the close button (e.g. "Done" or "Cancel").
  /// When set, rendered as a bold liquid glass capsule button (like the
  /// native "Done" toolbar button). If null, renders a circular liquid glass
  /// button with a close `xmark`.
  final String? closeButtonLabel;

  /// Whether to render a subtle centered drag indicator handle at the top.
  ///
  /// Defaults to `false`: the native iOS 26 `.fullScreenCover` navigation bar
  /// has no drag handle.
  final bool showDragHandle;

  /// Optional custom background color for the bar.
  final Color? backgroundColor;

  /// Liquid glass renderer settings for the bar.
  final LiquidGlassSettings? settings;

  /// Rendering quality tier.
  final GlassQuality? quality;

  /// Height of the bar excluding safe area insets (defaults to 44.0).
  final double height;

  Widget _buildCloseButton(BuildContext context) {
    final effectiveOnClose = onClose ?? () => Navigator.of(context).maybePop();

    if (closeButtonLabel != null) {
      return GlassFullScreenCoverBarButton(
        label: closeButtonLabel!,
        isPrimary: true,
        onPressed: effectiveOnClose,
        settings: settings,
        quality: quality,
      );
    }

    return GlassButton(
      icon: const Icon(CupertinoIcons.xmark),
      iconSize: 16,
      width: 44,
      height: 44,
      label: 'Close full-screen cover',
      useOwnLayer: true,
      settings: settings,
      quality: quality,
      stretch: 0.15,
      onTap: effectiveOnClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null &&
        closeButtonPosition == GlassFullScreenCoverClosePosition.leading) {
      effectiveLeading = _buildCloseButton(context);
    }

    Widget? effectiveTrailing = trailing;
    if (effectiveTrailing == null &&
        closeButtonPosition == GlassFullScreenCoverClosePosition.trailing) {
      effectiveTrailing = _buildCloseButton(context);
    }

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    // iOS 26: the navigation bar background is transparent — only the toolbar
    // buttons are glass. [backgroundColor] remains available as an opt-in.
    return Container(
      padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
      height: height + topPadding,
      color: backgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showDragHandle)
            Positioned(
              top: 6,
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.5),
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.22)
                      : CupertinoColors.black.withValues(alpha: 0.18),
                ),
              ),
            ),
          if (title != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: title!,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: effectiveLeading ?? const SizedBox.shrink(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: effectiveTrailing ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// A native-style liquid glass capsule toolbar button for
/// [GlassFullScreenCoverBar] ("Cancel" / "Done").
///
/// Mirrors SwiftUI's glass `ToolbarItem` text buttons on iOS 26: a 44pt tall
/// capsule with a black label. Set [isPrimary] for the bold "Done" style.
class GlassFullScreenCoverBarButton extends StatelessWidget {
  /// Creates a [GlassFullScreenCoverBarButton].
  const GlassFullScreenCoverBarButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.settings,
    this.quality,
  });

  /// Text shown inside the capsule.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// Renders the label bold (native confirmation action, e.g. "Done").
  final bool isPrimary;

  /// Liquid glass renderer settings for the capsule.
  final LiquidGlassSettings? settings;

  /// Rendering quality tier.
  final GlassQuality? quality;

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      label: label,
      height: 44,
      useOwnLayer: true,
      shape: const LiquidRoundedSuperellipse(borderRadius: 22),
      settings: settings,
      quality: quality,
      stretch: 0.15,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

/// A full-viewport modal container providing 1:1 parity with SwiftUI's `.fullScreenCover()`.
///
/// Features:
/// - Fills the entire screen/viewport edge-to-edge.
/// - Curve-animated vertical slide-up transition from the bottom edge.
/// - Interactive swipe-to-dismiss gesture with velocity threshold and elastic resistance.
/// - Top corners round adaptively during downward drag mirroring iOS card sheet behavior.
/// - Integrated [GlassFullScreenCoverBar] with circular close button and drag handle.
class GlassFullScreenCover extends StatefulWidget {
  /// Creates a [GlassFullScreenCover].
  const GlassFullScreenCover({
    super.key,
    required this.child,
    this.topBar,
    this.title,
    this.leading,
    this.trailing,
    this.showCloseButton = true,
    this.closeButtonPosition = GlassFullScreenCoverClosePosition.trailing,
    this.closeButtonLabel,
    this.onDismiss,
    this.enableSwipeToDismiss = true,
    this.dismissThreshold = 140.0,
    this.velocityThreshold = 700.0,
    this.cornerRadius = 44.0,
    this.backgroundColor,
    this.settings,
    this.quality,
    this.enableHaptics = true,
  });

  /// Primary content widget displayed inside the full-screen cover.
  final Widget child;

  /// Custom top bar. If null and [title] or [showCloseButton] is provided,
  /// a default [GlassFullScreenCoverBar] is built automatically.
  final Widget? topBar;

  /// Title displayed in the default top bar.
  final Widget? title;

  /// Leading accessory widget for the default top bar.
  final Widget? leading;

  /// Trailing accessory widget for the default top bar.
  final Widget? trailing;

  /// Whether to show the standard close button if building the default top bar.
  final bool showCloseButton;

  /// Position of the close button.
  final GlassFullScreenCoverClosePosition closeButtonPosition;

  /// Optional text label for the close button (e.g. "Done").
  final String? closeButtonLabel;

  /// Callback executed when the cover is dismissed via gesture or close button.
  final VoidCallback? onDismiss;

  /// Whether dragging downward interactively pulls down and dismisses the cover.
  final bool enableSwipeToDismiss;

  /// Minimum vertical displacement in pixels required to trigger dismissal on release.
  final double dismissThreshold;

  /// Minimum fling velocity in pixels/second required to dismiss regardless of position.
  final double velocityThreshold;

  /// Maximum top corner radius applied dynamically as the sheet is pulled down.
  final double cornerRadius;

  /// Background color of the cover surface.
  final Color? backgroundColor;

  /// Liquid glass settings.
  final LiquidGlassSettings? settings;

  /// Rendering quality tier.
  final GlassQuality? quality;

  /// Whether to fire tactile haptic clicks when crossing the dismissal threshold.
  final bool enableHaptics;

  @override
  State<GlassFullScreenCover> createState() => _GlassFullScreenCoverState();
}

class _GlassFullScreenCoverState extends State<GlassFullScreenCover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dragController;
  double _dragOffset = 0.0;
  bool _thresholdCrossed = false;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipeToDismiss) return;

    final dy = details.delta.dy;
    double newOffset = _dragOffset + dy;

    if (newOffset < 0) {
      // Rubber-band resistance when dragging upward past the top edge
      final overscroll = -newOffset;
      final damped = (overscroll * 0.3) / (1.0 + (overscroll / 200.0));
      newOffset = -damped;
    } else {
      if (widget.enableHaptics) {
        if (newOffset >= widget.dismissThreshold && !_thresholdCrossed) {
          _thresholdCrossed = true;
          HapticFeedback.selectionClick();
        } else if (newOffset < widget.dismissThreshold && _thresholdCrossed) {
          _thresholdCrossed = false;
        }
      }
    }

    setState(() {
      _dragOffset = newOffset;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!widget.enableSwipeToDismiss) return;

    final velocity = details.primaryVelocity ?? 0.0;
    final shouldDismiss = velocity > widget.velocityThreshold ||
        _dragOffset >= widget.dismissThreshold;

    if (shouldDismiss) {
      _dismissWithAnimation(velocity);
    } else {
      _springBack();
    }
  }

  void _springBack() {
    _thresholdCrossed = false;
    final startY = _dragOffset;
    if (startY == 0.0) return;

    final animation = Tween<double>(begin: startY, end: 0.0).animate(
      CurvedAnimation(
        parent: _dragController,
        curve: Curves.easeOutCubic,
      ),
    );

    void listener() {
      setState(() {
        _dragOffset = animation.value;
      });
    }

    animation.addListener(listener);
    _dragController.forward(from: 0.0).then((_) {
      animation.removeListener(listener);
      setState(() {
        _dragOffset = 0.0;
      });
    });
  }

  void _dismissWithAnimation(double velocity) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final remainingDistance = screenHeight - _dragOffset;

    final durationMs = velocity > 0
        ? (remainingDistance / velocity * 1000).clamp(120.0, 320.0).toInt()
        : 250;

    final animation =
        Tween<double>(begin: _dragOffset, end: screenHeight).animate(
      CurvedAnimation(
        parent: _dragController,
        curve: Curves.easeInCubic,
      ),
    );

    void listener() {
      setState(() {
        _dragOffset = animation.value;
      });
    }

    animation.addListener(listener);
    _dragController.duration = Duration(milliseconds: durationMs);
    _dragController.forward(from: 0.0).then((_) {
      animation.removeListener(listener);
      widget.onDismiss?.call();
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark
            ? CupertinoColors.systemBackground.darkColor
            : CupertinoColors.systemBackground.color);

    Widget? topBar = widget.topBar;
    if (topBar == null && (widget.title != null || widget.showCloseButton)) {
      topBar = GlassFullScreenCoverBar(
        title: widget.title,
        leading: widget.leading,
        trailing: widget.trailing,
        closeButtonPosition: widget.showCloseButton
            ? widget.closeButtonPosition
            : GlassFullScreenCoverClosePosition.none,
        closeButtonLabel: widget.closeButtonLabel,
        onClose: () {
          widget.onDismiss?.call();
          Navigator.of(context).maybePop();
        },
        settings: widget.settings,
        quality: widget.quality,
      );
    }

    // Dynamic top corner rounding based on drag pull-down distance
    final currentCornerRadius = _dragOffset > 0
        ? math.min(widget.cornerRadius, _dragOffset * 0.45)
        : 0.0;

    // Subtle scale reduction during drag pull-down (iOS card feel)
    final currentScale =
        _dragOffset > 0 ? math.max(0.92, 1.0 - (_dragOffset / 2000.0)) : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: Transform.translate(
        offset: Offset(0, math.max(0, _dragOffset)),
        child: Transform.scale(
          scale: currentScale,
          alignment: Alignment.topCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(currentCornerRadius),
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: bgColor,
              child: Column(
                children: [
                  if (topBar != null) topBar,
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom [PageRoute] that displays a full-viewport modal cover matching
/// SwiftUI's `.fullScreenCover()`.
class _GlassFullScreenCoverRoute<T> extends PageRoute<T> {
  _GlassFullScreenCoverRoute({
    required this.builder,
    super.settings,
    this.barrierColor = const Color(0x66000000),
    this.barrierDismissible = false,
    this.transitionDuration = const Duration(milliseconds: 380),
    this.reverseTransitionDuration = const Duration(milliseconds: 320),
  });

  final WidgetBuilder builder;

  @override
  final Color barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  String? get barrierLabel => 'Full-Screen Cover';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    );
  }
}

/// Imperatively presents a full-viewport liquid glass modal cover.
///
/// Direct 1:1 parity with SwiftUI's `.fullScreenCover()` and UIKit's
/// `.overFullScreen` presentation style.
///
/// Example:
/// ```dart
/// showGlassFullScreenCover(
///   context: context,
///   builder: (context) => GlassFullScreenCover(
///     title: const Text('Account Details'),
///     child: MyAccountView(),
///   ),
/// );
/// ```
Future<T?> showGlassFullScreenCover<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color barrierColor = const Color(0x66000000),
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _GlassFullScreenCoverRoute<T>(
      builder: builder,
      settings: routeSettings,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
    ),
  );
}

/// Declarative host widget for managing `.glassFullScreenCover(...)` presentations.
class _GlassFullScreenCoverHost extends StatefulWidget {
  const _GlassFullScreenCoverHost({
    required this.child,
    required this.isPresented,
    this.onDismiss,
    required this.content,
    this.enableSwipeToDismiss = true,
    this.dismissThreshold = 140.0,
    this.settings,
    this.quality,
  });

  final Widget child;
  final bool isPresented;
  final VoidCallback? onDismiss;
  final WidgetBuilder content;
  final bool enableSwipeToDismiss;
  final double dismissThreshold;
  final LiquidGlassSettings? settings;
  final GlassQuality? quality;

  @override
  State<_GlassFullScreenCoverHost> createState() =>
      _GlassFullScreenCoverHostState();
}

class _GlassFullScreenCoverHostState extends State<_GlassFullScreenCoverHost> {
  Route<dynamic>? _activeRoute;

  @override
  void initState() {
    super.initState();
    if (widget.isPresented) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _present());
    }
  }

  @override
  void didUpdateWidget(covariant _GlassFullScreenCoverHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPresented && widget.isPresented) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _present());
    } else if (oldWidget.isPresented && !widget.isPresented) {
      _dismiss();
    }
  }

  void _present() {
    if (!mounted || _activeRoute != null) return;

    final route = _GlassFullScreenCoverRoute<void>(
      builder: (context) {
        final contentWidget = widget.content(context);
        if (contentWidget is GlassFullScreenCover) {
          return contentWidget;
        }
        return GlassFullScreenCover(
          enableSwipeToDismiss: widget.enableSwipeToDismiss,
          dismissThreshold: widget.dismissThreshold,
          settings: widget.settings,
          quality: widget.quality,
          onDismiss: () {
            widget.onDismiss?.call();
          },
          child: contentWidget,
        );
      },
    );

    _activeRoute = route;
    Navigator.of(context, rootNavigator: true).push(route).then((_) {
      if (_activeRoute == route) {
        _activeRoute = null;
        widget.onDismiss?.call();
      }
    });
  }

  void _dismiss() {
    if (_activeRoute != null && _activeRoute!.isActive) {
      Navigator.of(context, rootNavigator: true).removeRoute(_activeRoute!);
      _activeRoute = null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Convenient extension on [Widget] providing declarative parity with SwiftUI's
/// `.fullScreenCover(isPresented:onDismiss:content:)`.
extension GlassFullScreenCoverExtension on Widget {
  /// Presents a full-viewport modal cover whenever [isPresented] is true.
  Widget glassFullScreenCover({
    required bool isPresented,
    VoidCallback? onDismiss,
    required WidgetBuilder content,
    bool enableSwipeToDismiss = true,
    double dismissThreshold = 140.0,
    LiquidGlassSettings? settings,
    GlassQuality? quality,
  }) {
    return _GlassFullScreenCoverHost(
      isPresented: isPresented,
      onDismiss: onDismiss,
      content: content,
      enableSwipeToDismiss: enableSwipeToDismiss,
      dismissThreshold: dismissThreshold,
      settings: settings,
      quality: quality,
      child: this,
    );
  }
}
