import 'dart:async';
import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../theme/glass_theme.dart';
import '../../theme/glass_theme_data.dart';
import '../../theme/glass_theme_helpers.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_style.dart';
import '../containers/glass_container.dart';
import '../shared/glass_focus_region.dart';
import '../shared/glass_interaction_state_mixin.dart';
import 'glass_menu_item.dart';

/// Position of the action icon relative to its label in a [GlassContextMenuAction].
enum GlassContextMenuIconPosition {
  /// Icon is positioned on the trailing edge (Apple iOS standard for context menus).
  trailing,

  /// Icon is positioned on the leading edge.
  leading,
}

/// An interactive context menu action with authentic iOS liquid glass styling,
/// providing direct parity with SwiftUI's `Button` within a `.contextMenu()`.
///
/// Features:
/// - Compact 42pt row height matching iOS 26 context menu platters.
/// - Trailing SF / Cupertino symbol alignment by default.
/// - Destructive styling with red text and subtle red highlight.
/// - Selected state with leading checkmark.
/// - Haptic feedback on tap and hover glide.
/// - Keyboard focus and screen reader accessibility via [GlassFocusRegion].
class GlassContextMenuAction extends StatefulWidget {
  /// Creates a [GlassContextMenuAction].
  const GlassContextMenuAction({
    super.key,
    required this.child,
    this.onPressed,
    this.icon,
    this.iconPosition = GlassContextMenuIconPosition.leading,
    this.isDestructive = false,
    this.isSelected = false,
    this.trailing,
    this.height = 42.0,
    this.enabled = true,
  });

  /// Primary label or content widget of the action.
  final Widget child;

  /// Callback executed when this action is tapped or selected via glide.
  final VoidCallback? onPressed;

  /// Optional icon displayed with the action.
  final Widget? icon;

  /// Position of the icon relative to [child] (defaults to [GlassContextMenuIconPosition.leading]).
  final GlassContextMenuIconPosition iconPosition;

  /// Whether this action performs a destructive operation (e.g. Delete, Remove).
  final bool isDestructive;

  /// Whether this action represents an active/selected choice.
  /// When true, renders a leading checkmark icon.
  final bool isSelected;

  /// Optional trailing accessory widget (e.g. keyboard shortcut or badge).
  final Widget? trailing;

  /// Height of the action row (defaults to 42.0).
  final double height;

  /// Whether the action is interactive.
  final bool enabled;

  @override
  State<GlassContextMenuAction> createState() => _GlassContextMenuActionState();
}

class _GlassContextMenuActionState extends State<GlassContextMenuAction>
    with GlassInteractionStateMixin {
  void _handleTap(BuildContext context) {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;

    final baseTextColor = widget.isDestructive
        ? CupertinoColors.destructiveRed
        : CupertinoColors.label.resolveFrom(context);

    final effectiveColor = widget.enabled
        ? baseTextColor
        : baseTextColor.withValues(alpha: 0.4);

    return GlassFocusRegion(
      enabled: widget.enabled,
      isFocusedNotifier: isFocused,
      isButton: true,
      semanticLabel: widget.child is Text ? (widget.child as Text).data : null,
      onKeyboardActivate: () => _handleTap(context),
      semanticOnTap: () => _handleTap(context),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        child: ListenableBuilder(
          listenable: pressedAndFocused,
          builder: (context, _) {
            final bool showHighlight = isPressed.value || isFocused.value;

            final highlightColor = widget.isDestructive
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.14)
                : (isDark ? CupertinoColors.white : CupertinoColors.black)
                      .withValues(alpha: 0.08);

            return AnimatedContainer(
              duration: isPressed.value
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: showHighlight ? highlightColor : const Color(0x00000000),
              child: Row(
                children: [
                  if (widget.isSelected) ...[
                    Icon(
                      CupertinoIcons.checkmark,
                      size: 16,
                      color: effectiveColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.icon != null &&
                      widget.iconPosition ==
                          GlassContextMenuIconPosition.leading) ...[
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(color: effectiveColor, size: 20),
                          child: widget.icon!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: effectiveColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.3,
                        fontFamily: theme.textTheme.textStyle.fontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: widget.child,
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                  if (widget.icon != null &&
                      widget.iconPosition ==
                          GlassContextMenuIconPosition.trailing) ...[
                    const SizedBox(width: 12),
                    IconTheme(
                      data: IconThemeData(color: effectiveColor, size: 19),
                      child: widget.icon!,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A liquid glass context menu following Apple iOS 26/27 and SwiftUI `.contextMenu()` design.
///
/// When long-pressed or secondary-tapped (right-clicked on desktop/web), the wrapped
/// [child] lifts above a defocused liquid glass backdrop with realistic elevation shadow,
/// while an adjacent liquid glass action platter springs open with snappy spring physics.
///
/// ## Features
/// - **Touch-and-Hold Surface Lift**: When pressed and held, the row lifts off the page
///   (about 1.036×) with a broad soft drop shadow, keeping its own corner shape.
/// - **Row-to-Preview Morph**: On commit the lifted row cross-dissolves and morphs into the
///   centred preview card in ~190ms while the page dims, and morphs back into the row on dismiss.
/// - **Haptic Surface Lift**: Fires `HapticFeedback.mediumImpact()` as the menu commits.
/// - **Native Backdrop**: A plain dimming scrim (no blur by default), matching iOS.
/// - **Elevated Specular Platter**: The action list renders in a rounded superellipse
///   liquid glass container with specular highlights.
/// - **Smart Positioning**: Automatically opens below or above the target based on available
///   screen space and clamps safely within screen edges.
/// - **Continuous Glide-to-Select**: Dragging from the long-press directly across menu items
///   highlights the hovered action with haptic ticks; releasing selects the action.
/// - **Custom Preview Support**: Supply [previewBuilder] to render custom content when lifted.
/// - **Secondary Tap Parity**: Right-click on desktop/macOS opens the menu immediately.
///
/// ## Usage
///
/// ```dart
/// GlassContextMenu(
///   actions: [
///     GlassContextMenuAction(
///       icon: const Icon(CupertinoIcons.share),
///       child: const Text('Share Contact'),
///       onPressed: () => shareContact(),
///     ),
///     GlassContextMenuAction(
///       icon: const Icon(CupertinoIcons.delete),
///       isDestructive: true,
///       child: const Text('Delete'),
///       onPressed: () => deleteContact(),
///     ),
///   ],
///   child: ContactCard(contact: contact),
/// )
/// ```
class GlassContextMenu extends StatefulWidget {
  /// Creates a [GlassContextMenu].
  const GlassContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.previewBuilder,
    this.enabled = true,
    this.enableHaptics = true,
    this.borderRadius = 32.0,
    this.previewBorderRadius,
    this.rowBorderRadius = 16.0,
    this.rowCorners,
    this.originSlotColor,
    this.backgroundColor,
    this.settings,
    this.quality,
    this.backdropBlur = 0.0,
    this.barrierColor,
    this.menuWidth = 250.0,
    this.onOpened,
    this.onDismissed,
    this.longPressDuration = const Duration(milliseconds: 700),
  });

  /// The widget that triggers the context menu.
  final Widget child;

  /// The list of actions displayed in the liquid glass action platter.
  final List<Widget> actions;

  /// Optional builder for a custom preview widget displayed when lifted.
  /// If null, [child] is displayed in the lifted preview.
  final WidgetBuilder? previewBuilder;

  /// Whether context menu interaction is enabled.
  final bool enabled;

  /// Whether to trigger haptic feedback on touch-down, lift, and action selection.
  final bool enableHaptics;

  /// Border radius of the action menu platter (defaults to 32.0, matching the
  /// continuous corners of iOS 26 context menus).
  final double borderRadius;

  /// Border radius of the preview card when opened. Defaults to 34.0 when
  /// [previewBuilder] is supplied, or [rowBorderRadius] otherwise.
  final double? previewBorderRadius;

  /// Border radius of the target row at rest and during touch-and-hold lift.
  /// Defaults to 16.0 pt matching iOS grouped section row corners.
  final double rowBorderRadius;

  /// Per-corner radii of the target row, overriding [rowBorderRadius].
  ///
  /// A row inside an inset-grouped section only rounds the corners it shares
  /// with the section card (the first row rounds its top corners, the last row
  /// its bottom corners, middle rows none). The lifted row keeps that shape
  /// exactly like a lifted `UITableViewCell`.
  final BorderRadius? rowCorners;

  /// Colour revealed in the row's slot while the row is lifted out of the page.
  ///
  /// When the row is lifted, iOS leaves an empty slot showing the page behind
  /// it. A row inside a solid section card cannot punch a hole through the
  /// card its parent paints, so supply the page colour here (for an inset
  /// grouped list that is the grouped background) and the slot is painted with
  /// it beneath the dimming scrim. Defaults to null (nothing is painted).
  final Color? originSlotColor;

  /// Optional background color of the row when lifted during touch-and-hold.
  /// Defaults to secondary system grouped background color (solid white in light mode).
  final Color? backgroundColor;

  /// Custom liquid glass shader settings for the action platter.
  final LiquidGlassSettings? settings;

  /// Glass quality tier for rendering the action platter.
  final GlassQuality? quality;

  /// Amount of gaussian blur applied to the backdrop when opened.
  final double backdropBlur;

  /// Dimming barrier color applied behind the lifted target and platter.
  final Color? barrierColor;

  /// Width of the action menu platter (defaults to 250.0).
  final double menuWidth;

  /// Optional callback invoked when the context menu is opened.
  final VoidCallback? onOpened;

  /// Optional callback invoked when the context menu is dismissed.
  final VoidCallback? onDismissed;

  /// The duration of the touch-and-hold gesture required to trigger the context menu.
  ///
  /// Defaults to 700 milliseconds, measured from touch-down on the native iOS
  /// 27 context menu (the row lifts after ~200ms and the menu commits at ~700ms).
  final Duration longPressDuration;

  @override
  State<GlassContextMenu> createState() => _GlassContextMenuState();
}

class _ContextMenuLongPressRecognizer extends LongPressGestureRecognizer {
  _ContextMenuLongPressRecognizer({
    super.debugOwner,
    super.duration,
    this.onRejected,
  });

  final VoidCallback? onRejected;

  @override
  void rejectGesture(int pointer) {
    onRejected?.call();
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    onRejected?.call();
    super.didStopTrackingLastPointer(pointer);
  }
}

class _GlassContextMenuState extends State<GlassContextMenu> {
  bool _isRouteOpen = false;
  GlobalKey<_GlassContextMenuRouteStaticState>? _routeStaticKey;

  void _openContextMenu({bool isInteractive = false}) {
    if (!widget.enabled || widget.actions.isEmpty || _isRouteOpen) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final targetRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    setState(() {
      _isRouteOpen = true;
    });
    widget.onOpened?.call();

    final staticKey = GlobalKey<_GlassContextMenuRouteStaticState>();
    _routeStaticKey = staticKey;

    final recognizerDuration =
        widget.longPressDuration < const Duration(milliseconds: 200)
        ? widget.longPressDuration
        : const Duration(milliseconds: 180);
    final commitDuration = widget.longPressDuration > recognizerDuration
        ? widget.longPressDuration - recognizerDuration
        : Duration.zero;

    showGlassContextMenu<void>(
      context: context,
      targetRect: targetRect,
      actions: widget.actions,
      previewBuilder: widget.previewBuilder,
      previewChild: widget.child,
      borderRadius: widget.borderRadius,
      previewBorderRadius: widget.previewBorderRadius,
      rowBorderRadius: widget.rowBorderRadius,
      rowCorners: widget.rowCorners,
      originSlotColor: widget.originSlotColor,
      backgroundColor: widget.backgroundColor,
      settings: widget.settings,
      quality: widget.quality,
      backdropBlur: widget.backdropBlur,
      barrierColor: widget.barrierColor,
      menuWidth: widget.menuWidth,
      enableHaptics: widget.enableHaptics,
      routeStaticKey: staticKey,
      isInteractive: isInteractive,
      commitDuration: commitDuration,
    ).then((_) {
      if (_routeStaticKey == staticKey) {
        _routeStaticKey = null;
      }
      if (mounted) {
        setState(() {
          _isRouteOpen = false;
        });
        widget.onDismissed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.actions.isEmpty) {
      return widget.child;
    }

    final recognizerDuration =
        widget.longPressDuration < const Duration(milliseconds: 200)
        ? widget.longPressDuration
        : const Duration(milliseconds: 180);

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _ContextMenuLongPressRecognizer:
            GestureRecognizerFactoryWithHandlers<
              _ContextMenuLongPressRecognizer
            >(
              () => _ContextMenuLongPressRecognizer(
                duration: recognizerDuration,
                debugOwner: this,
                onRejected: () {},
              ),
              (instance) {
                instance
                  ..onLongPressStart = (_) {
                    _openContextMenu(isInteractive: true);
                  }
                  ..onLongPressMoveUpdate = (details) {
                    if (_isRouteOpen && _routeStaticKey != null) {
                      _routeStaticKey!.currentState?.updateGlidePosition(
                        details.globalPosition,
                      );
                    }
                  }
                  ..onLongPressEnd = (_) {
                    if (_isRouteOpen && _routeStaticKey != null) {
                      _routeStaticKey!.currentState?.endGlide();
                    }
                  };
              },
            ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(debugOwner: this),
              (instance) {
                instance.onSecondaryTapUp = (_) {
                  _openContextMenu(isInteractive: false);
                };
              },
            ),
      },
      // While the menu is open the row is lifted out of the page: it is hidden
      // here and drawn by the route overlay, leaving an empty slot behind.
      child: Opacity(opacity: _isRouteOpen ? 0.0 : 1.0, child: widget.child),
    );
  }
}

/// Displays an iOS-style liquid glass context menu attached to a target rectangle.
///
/// Returns a [Future] that resolves when the context menu is dismissed.
Future<T?> showGlassContextMenu<T>({
  required BuildContext context,
  required Rect targetRect,
  required List<Widget> actions,
  WidgetBuilder? previewBuilder,
  Widget? previewChild,
  double borderRadius = 32.0,
  double? previewBorderRadius,
  double rowBorderRadius = 16.0,
  BorderRadius? rowCorners,
  Color? originSlotColor,
  Color? backgroundColor,
  LiquidGlassSettings? settings,
  GlassQuality? quality,
  double backdropBlur = 0.0,
  Color? barrierColor,
  double menuWidth = 250.0,
  bool enableHaptics = true,
  GlobalKey? routeStaticKey,
  bool isInteractive = false,
  Duration commitDuration = const Duration(milliseconds: 520),
}) {
  assert(actions.isNotEmpty, 'Context menu actions must not be empty.');
  final capturedGlassTheme = GlassTheme.maybeOf(context)?.data;
  final capturedCupertinoTheme = CupertinoTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    _GlassContextMenuRoute<T>(
      targetRect: targetRect,
      actions: actions,
      previewBuilder: previewBuilder,
      previewChild: previewChild,
      borderRadius: borderRadius,
      previewBorderRadius: previewBorderRadius,
      rowBorderRadius: rowBorderRadius,
      rowCorners: rowCorners,
      originSlotColor: originSlotColor,
      backgroundColor: backgroundColor,
      glassSettings: settings,
      quality: quality,
      backdropBlur: backdropBlur,
      scrimColor: barrierColor,
      menuWidth: menuWidth,
      enableHaptics: enableHaptics,
      routeStaticKey: routeStaticKey,
      isInteractive: isInteractive,
      commitDuration: commitDuration,
      capturedGlassTheme: capturedGlassTheme,
      capturedCupertinoTheme: capturedCupertinoTheme,
    ),
  );
}

/// Fraction of the route timeline occupied by the row "lift" before the morph
/// into the preview card begins.
const double _kLiftSplit = 0.4;

/// Scale the pressed row reaches at the end of the lift (native iOS ≈ 1.04×).
const double _kLiftScale = 1.038;

/// Vertical inset above/below the action rows inside the platter.
const double _kPlatterInset = 10.0;

class _GlassContextMenuRoute<T> extends PopupRoute<T> {
  _GlassContextMenuRoute({
    required this.targetRect,
    required this.actions,
    this.previewBuilder,
    this.previewChild,
    required this.borderRadius,
    this.previewBorderRadius,
    this.rowBorderRadius = 16.0,
    this.rowCorners,
    this.originSlotColor,
    this.backgroundColor,
    this.glassSettings,
    this.quality,
    required this.backdropBlur,
    this.scrimColor,
    required this.menuWidth,
    required this.enableHaptics,
    this.routeStaticKey,
    this.isInteractive = false,
    this.commitDuration = const Duration(milliseconds: 520),
    this.capturedGlassTheme,
    this.capturedCupertinoTheme,
  });

  final Rect targetRect;
  final List<Widget> actions;
  final WidgetBuilder? previewBuilder;
  final Widget? previewChild;
  final double borderRadius;
  final double? previewBorderRadius;
  final double rowBorderRadius;
  final BorderRadius? rowCorners;
  final Color? originSlotColor;
  final Color? backgroundColor;
  final LiquidGlassSettings? glassSettings;
  final GlassQuality? quality;
  final double backdropBlur;
  final GlassThemeData? capturedGlassTheme;
  final CupertinoThemeData? capturedCupertinoTheme;

  /// Optional override for the dimming scrim. When null the scrim adapts to
  /// the ambient brightness.
  final Color? scrimColor;

  // The page paints its own animated scrim; a route-level barrier colour would
  // be composited on top of it and double the dimming.
  @override
  Color? get barrierColor => null;

  final double menuWidth;
  final bool enableHaptics;
  final GlobalKey? routeStaticKey;
  final bool isInteractive;
  final Duration commitDuration;

  // Non-interactive presentations (secondary click) play the lift and morph
  // back to back: the lift occupies the first `_kLiftSplit` of the timeline
  // (~128ms) and the morph the rest (~192ms, matching native iOS).
  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  // The return morph from the open menu back into the row.
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 170);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss context menu';

  Timer? _commitTimer;
  bool _isCommitted = false;

  bool get isCommitted => _isCommitted;

  @override
  AnimationController createAnimationController() {
    return AnimationController(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      vsync: navigator!.overlay!,
    );
  }

  @override
  TickerFuture didPush() {
    super.didPush();
    if (isInteractive) {
      final ticker = controller!.animateTo(
        _kLiftSplit,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      if (commitDuration > Duration.zero) {
        _commitTimer = Timer(commitDuration, commitMenu);
      } else {
        commitMenu();
      }
      return ticker;
    } else {
      _isCommitted = true;
      return controller!.forward();
    }
  }

  void commitMenu() {
    if (_isCommitted || !isActive || controller == null) return;
    _isCommitted = true;
    _commitTimer?.cancel();
    _commitTimer = null;
    if (enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    controller!.animateTo(
      1.0,
      duration: const Duration(milliseconds: 190),
      curve: Curves.linear,
    );
  }

  void cancelInteractive() {
    if (_isCommitted) return;
    _commitTimer?.cancel();
    _commitTimer = null;
    if (isActive && navigator?.canPop() == true) {
      navigator?.pop();
    }
  }

  @override
  void dispose() {
    _commitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    Widget page = _GlassContextMenuRouteStatic(
      key: routeStaticKey,
      route: this,
      targetRect: targetRect,
      actions: actions,
      previewBuilder: previewBuilder,
      previewChild: previewChild,
      borderRadius: borderRadius,
      previewBorderRadius: previewBorderRadius,
      rowBorderRadius: rowBorderRadius,
      rowCorners: rowCorners,
      originSlotColor: originSlotColor,
      backgroundColor: backgroundColor,
      settings: glassSettings,
      quality: quality,
      backdropBlur: backdropBlur,
      scrimColor: scrimColor,
      menuWidth: menuWidth,
      enableHaptics: enableHaptics,
      animation: animation,
    );
    if (capturedCupertinoTheme != null) {
      page = CupertinoTheme(data: capturedCupertinoTheme!, child: page);
    }
    if (capturedGlassTheme != null) {
      page = GlassTheme(data: capturedGlassTheme!, child: page);
    }
    return page;
  }
}

class _GlassContextMenuRouteStatic extends StatefulWidget {
  const _GlassContextMenuRouteStatic({
    super.key,
    this.route,
    required this.targetRect,
    required this.actions,
    this.previewBuilder,
    this.previewChild,
    required this.borderRadius,
    this.previewBorderRadius,
    this.rowBorderRadius = 16.0,
    this.rowCorners,
    this.originSlotColor,
    this.backgroundColor,
    this.settings,
    this.quality,
    required this.backdropBlur,
    this.scrimColor,
    required this.menuWidth,
    required this.enableHaptics,
    required this.animation,
  });

  final _GlassContextMenuRoute? route;
  final Rect targetRect;
  final List<Widget> actions;
  final WidgetBuilder? previewBuilder;
  final Widget? previewChild;
  final double borderRadius;
  final double? previewBorderRadius;
  final double rowBorderRadius;
  final BorderRadius? rowCorners;
  final Color? originSlotColor;
  final Color? backgroundColor;
  final LiquidGlassSettings? settings;
  final GlassQuality? quality;
  final double backdropBlur;
  final Color? scrimColor;
  final double menuWidth;
  final bool enableHaptics;
  final Animation<double> animation;

  @override
  State<_GlassContextMenuRouteStatic> createState() =>
      _GlassContextMenuRouteStaticState();
}

class _GlassContextMenuRouteStaticState
    extends State<_GlassContextMenuRouteStatic> {
  late final List<GlobalKey> _actionKeys;
  final GlobalKey _previewMeasureKey = GlobalKey();
  final GlobalKey _platterMeasureKey = GlobalKey();
  Size? _measuredPreviewSize;
  Size? _measuredPlatterSize;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _actionKeys = List.generate(widget.actions.length, (_) => GlobalKey());
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointer);
    WidgetsBinding.instance.addPostFrameCallback(_measureSizes);
  }

  void _measureSizes(Duration _) {
    if (!mounted) return;
    final previewBox =
        _previewMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    final platterBox =
        _platterMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    bool changed = false;
    if (previewBox != null && previewBox.hasSize) {
      if (_measuredPreviewSize != previewBox.size) {
        _measuredPreviewSize = previewBox.size;
        changed = true;
      }
    }
    if (platterBox != null && platterBox.hasSize) {
      if (_measuredPlatterSize != platterBox.size) {
        _measuredPlatterSize = platterBox.size;
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointer,
    );
    super.dispose();
  }

  void _handleGlobalPointer(PointerEvent event) {
    if (!mounted) return;
    if (event is PointerMoveEvent) {
      if (widget.route != null && !widget.route!.isCommitted) {
        final distance = (event.position - widget.targetRect.center).distance;
        if (distance > widget.targetRect.width * 0.6) {
          widget.route!.cancelInteractive();
          return;
        }
      }
      updateGlidePosition(event.position);
    } else if (event is PointerUpEvent) {
      if (widget.route != null && !widget.route!.isCommitted) {
        widget.route!.cancelInteractive();
        return;
      }
      updateGlidePosition(event.position);
      endGlide();
    } else if (event is PointerCancelEvent) {
      if (widget.route != null && !widget.route!.isCommitted) {
        widget.route!.cancelInteractive();
        return;
      }
      if (_hoveredIndex != null) {
        setState(() => _hoveredIndex = null);
      }
    }
  }

  /// Updates hovered action index when gliding with finger.
  void updateGlidePosition(Offset globalPosition) {
    int? foundIndex;

    for (int i = 0; i < _actionKeys.length; i++) {
      final key = _actionKeys[i];
      final currentContext = key.currentContext;
      if (currentContext != null) {
        final box = currentContext.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final local = box.globalToLocal(globalPosition);
          if (box.paintBounds.contains(local)) {
            foundIndex = i;
            break;
          }
        }
      }
    }

    if (_hoveredIndex != foundIndex) {
      setState(() {
        _hoveredIndex = foundIndex;
      });
      if (foundIndex != null && widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Concludes glide gesture, executing the selected action if one is hovered.
  void endGlide() {
    if (_hoveredIndex != null && _hoveredIndex! < widget.actions.length) {
      final index = _hoveredIndex!;
      _hoveredIndex = null;
      final action = widget.actions[index];
      if (action is GlassContextMenuAction && action.enabled) {
        final navigator = Navigator.maybeOf(context, rootNavigator: true);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        }
        action.onPressed?.call();
      } else if (action is GlassMenuItem && action.enabled) {
        final navigator = Navigator.maybeOf(context, rootNavigator: true);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        }
        action.onTap();
      }
    } else {
      _hoveredIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    final bool isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final GlassStyle style =
        GlassTheme.maybeOf(context)?.data.style ?? GlassStyle.ios27;
    final Color scrim =
        widget.scrimColor ??
        (isDark ? const Color(0x40000000) : const Color(0x32000000));

    final LiquidGlassSettings classicFallback = isDark
        ? const LiquidGlassSettings(
            glassColor: Color(0xCC252528),
            thickness: 16,
            blur: 22,
            saturation: 1.2,
            lightIntensity: 0.28,
          )
        : const LiquidGlassSettings(
            glassColor: Color(0xCCF5F5F7),
            thickness: 16,
            blur: 22,
            saturation: 1.2,
            lightIntensity: 0.35,
          );
    final LiquidGlassSettings platterSettings =
        GlassThemeHelpers.resolveSettings(
          context,
          explicit: widget.settings,
          fallback: classicFallback,
          isOverlayPlatter: true,
        );

    final bool hasCustomPreview = widget.previewBuilder != null;
    final Widget previewWidget = hasCustomPreview
        ? widget.previewBuilder!(context)
        : (widget.previewChild ?? const SizedBox.shrink());

    final double effectivePreviewBorderRadius =
        widget.previewBorderRadius ??
        (hasCustomPreview ? 34.0 : widget.rowBorderRadius);
    final BorderRadius rowRadii =
        widget.rowCorners ?? BorderRadius.circular(widget.rowBorderRadius);
    final BorderRadius previewRadii = BorderRadius.circular(
      effectivePreviewBorderRadius,
    );

    final effectivePlatterQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassQuality.premium,
    );

    final bool shaderDrawsRim =
        style != GlassStyle.classic &&
        effectivePlatterQuality == GlassQuality.premium &&
        ImageFilter.isShaderFilterSupported;
    final Color platterBorder = shaderDrawsRim
        ? const Color(0x00000000)
        : (isDark ? const Color(0x33FFFFFF) : const Color(0x4D000000));

    Widget buildPlatter({bool isMeasurement = false}) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.08),
              blurRadius: 28.0,
              offset: const Offset(0, 8.0),
            ),
          ],
        ),
        child: GlassContainer.card(
          useOwnLayer: true,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          shape: LiquidRoundedSuperellipse(borderRadius: widget.borderRadius),
          settings: platterSettings,
          quality: effectivePlatterQuality,
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  side: BorderSide(color: platterBorder, width: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: _kPlatterInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < widget.actions.length; i++)
                      Padding(
                        key: isMeasurement ? null : _actionKeys[i],
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(21.0),
                            color: !isMeasurement && _hoveredIndex == i
                                ? (widget.actions[i]
                                              is GlassContextMenuAction &&
                                          (widget.actions[i]
                                                  as GlassContextMenuAction)
                                              .isDestructive
                                      ? CupertinoColors.destructiveRed
                                            .withValues(alpha: 0.16)
                                      : (isDark
                                                ? CupertinoColors.white
                                                : CupertinoColors.black)
                                            .withValues(
                                              alpha: isDark ? 0.12 : 0.08,
                                            ))
                                : const Color(0x00000000),
                          ),
                          child: widget.actions[i],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final double topSafe = padding.top + 16.0;
    final double bottomSafe = screenSize.height - padding.bottom - 16.0;
    const double gap = 16.0;

    final Size effectivePreviewSize =
        _measuredPreviewSize ??
        (hasCustomPreview ? const Size(240.0, 201.0) : widget.targetRect.size);

    final double estimatedPlatterHeight =
        widget.actions.length * 42.0 + _kPlatterInset * 2;
    final Size effectivePlatterSize =
        _measuredPlatterSize ?? Size(widget.menuWidth, estimatedPlatterHeight);

    final double previewWidth = effectivePreviewSize.width.clamp(
      100.0,
      screenSize.width - 32.0,
    );
    final double previewHeight = effectivePreviewSize.height;
    final double platterWidth = effectivePlatterSize.width.clamp(
      100.0,
      screenSize.width - 32.0,
    );
    final double platterHeight = effectivePlatterSize.height;

    final double totalHeight = previewHeight + gap + platterHeight;

    final double spaceBelow = bottomSafe - widget.targetRect.bottom;
    final double spaceAbove = widget.targetRect.top - topSafe;
    bool placeBelow =
        (spaceBelow >= platterHeight + gap) || (spaceBelow >= spaceAbove);

    double restingPreviewTop;
    if (hasCustomPreview) {
      // Native iOS centres the preview on the pressed row and stacks the
      // platter beneath it, shifting the pair only as far as needed to stay
      // on screen.
      final double maxTop = bottomSafe - totalHeight;
      if (maxTop >= topSafe) {
        placeBelow = true;
        restingPreviewTop = (widget.targetRect.center.dy - previewHeight / 2.0)
            .clamp(topSafe, maxTop);
      } else if (placeBelow) {
        restingPreviewTop = topSafe;
      } else {
        final double minTop = topSafe + platterHeight + gap;
        restingPreviewTop = (widget.targetRect.bottom - previewHeight).clamp(
          minTop,
          bottomSafe - previewHeight,
        );
      }
    } else {
      restingPreviewTop = widget.targetRect.top;
    }

    final double restingPreviewLeft = hasCustomPreview
        ? ((screenSize.width - previewWidth) / 2.0).clamp(
            16.0,
            screenSize.width - previewWidth - 16.0,
          )
        : widget.targetRect.left;

    final Rect restingPreviewRect = Rect.fromLTWH(
      restingPreviewLeft,
      restingPreviewTop,
      previewWidth,
      previewHeight,
    );

    final double restingPlatterTop = placeBelow
        ? restingPreviewTop + previewHeight + gap
        : restingPreviewTop - gap - platterHeight;
    final double idealPlatterLeft =
        widget.targetRect.center.dx - (platterWidth / 2.0);
    final double restingPlatterLeft = hasCustomPreview
        ? ((screenSize.width - platterWidth) / 2.0).clamp(
            16.0,
            screenSize.width - platterWidth - 16.0,
          )
        : idealPlatterLeft.clamp(16.0, screenSize.width - platterWidth - 16.0);

    final Rect restingPlatterRect = Rect.fromLTWH(
      restingPlatterLeft,
      restingPlatterTop,
      platterWidth,
      platterHeight,
    );

    final cardColor =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white);

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final double v = widget.animation.value;
        final bool committed = widget.route?.isCommitted ?? true;
        final bool dismissing =
            committed && widget.animation.status == AnimationStatus.reverse;
        final bool interactive = widget.route?.isInteractive ?? false;

        final Rect liftedRowRect = Rect.fromCenter(
          center: widget.targetRect.center,
          width: widget.targetRect.width * _kLiftScale,
          height: widget.targetRect.height * _kLiftScale,
        );

        Rect cardRect;
        BorderRadius cardRadii;
        double shadowFactor;
        double rowAlpha;
        double previewAlpha;
        double rowScale;
        double previewScale;
        double platterOpacity;
        double platterScale;
        double scrimAmount;

        if (dismissing) {
          // Return morph: the card collapses back into the row with the
          // platter ghosting out first and no shadow at the end (native iOS).
          // Native order: the platter ghosts out first (~35ms) while the card
          // holds, then the card eases back into the row (~110ms).
          final double w = (1.0 - v).clamp(0.0, 1.0);
          final double u = Curves.easeInOut.transform(
            ((w - 0.2) / 0.65).clamp(0.0, 1.0),
          );
          final double cf = Curves.easeInOut.transform(
            ((w - 0.18) / 0.55).clamp(0.0, 1.0),
          );
          cardRect = Rect.lerp(restingPreviewRect, widget.targetRect, u)!;
          cardRadii = BorderRadius.lerp(previewRadii, rowRadii, u)!;
          shadowFactor = (1.0 - u) * (1.0 - u);
          rowAlpha = hasCustomPreview ? cf : 1.0;
          previewAlpha = hasCustomPreview ? 1.0 - cf : 0.0;
          rowScale = 1.0;
          previewScale = lerpDouble(
            1.0,
            widget.targetRect.width / previewWidth,
            u,
          )!;
          platterOpacity = (1.0 - w / 0.25).clamp(0.0, 1.0);
          platterScale = 1.0 - 0.12 * (w / 0.25).clamp(0.0, 1.0);
          scrimAmount = v;
        } else if (v <= _kLiftSplit) {
          // Stage 1: the row lifts off the page with a broad soft shadow.
          final double raw = (v / _kLiftSplit).clamp(0.0, 1.0);
          final double p = interactive
              ? raw
              : Curves.easeOutCubic.transform(raw);
          final double scale = 1.0 + (_kLiftScale - 1.0) * p;
          cardRect = Rect.fromCenter(
            center: widget.targetRect.center,
            width: widget.targetRect.width * scale,
            height: widget.targetRect.height * scale,
          );
          cardRadii = rowRadii;
          shadowFactor = p;
          rowAlpha = 1.0;
          previewAlpha = 0.0;
          rowScale = scale;
          previewScale = 1.0;
          platterOpacity = 0.0;
          platterScale = 0.4;
          scrimAmount = 0.0;
        } else {
          // Stage 2: the lifted row morphs into the preview card while the
          // platter pops out beneath it.
          final double t = ((v - _kLiftSplit) / (1.0 - _kLiftSplit)).clamp(
            0.0,
            1.0,
          );
          final double m = Curves.easeOutCubic.transform(
            ((t - 0.15) / 0.85).clamp(0.0, 1.0),
          );
          final double c = Curves.easeInOut.transform(
            ((t - 0.05) / 0.75).clamp(0.0, 1.0),
          );
          cardRect = Rect.lerp(liftedRowRect, restingPreviewRect, m)!;
          cardRadii = BorderRadius.lerp(rowRadii, previewRadii, m)!;
          shadowFactor = 1.0;
          rowAlpha = hasCustomPreview ? 1.0 - c : 1.0;
          previewAlpha = hasCustomPreview ? c : 0.0;
          rowScale = hasCustomPreview
              ? _kLiftScale
              : lerpDouble(_kLiftScale, 1.0, m)!;
          previewScale = lerpDouble(
            liftedRowRect.width / previewWidth,
            1.0,
            m,
          )!;
          final double pt = ((t - 0.12) / 0.88).clamp(0.0, 1.0);
          final double pe = Curves.easeOutCubic.transform(pt);
          platterOpacity = (pt * 3.0).clamp(0.0, 1.0);
          platterScale = 0.4 + 0.6 * pe;
          scrimAmount = Curves.easeOut.transform((t / 0.25).clamp(0.0, 1.0));
        }

        final Widget scrimLayer = GestureDetector(
          onTap: () => Navigator.of(context, rootNavigator: true).pop(),
          behavior: HitTestBehavior.opaque,
          child: widget.backdropBlur > 0.0
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.backdropBlur * scrimAmount,
                    sigmaY: widget.backdropBlur * scrimAmount,
                  ),
                  child: Container(
                    color: scrim.withValues(alpha: scrim.a * scrimAmount),
                  ),
                )
              : Container(
                  color: scrim.withValues(alpha: scrim.a * scrimAmount),
                ),
        );

        final Alignment platterAnchor = placeBelow
            ? Alignment.topCenter
            : Alignment.bottomCenter;

        final List<BoxShadow>? cardShadows = shadowFactor <= 0.0
            ? null
            : [
                BoxShadow(
                  color: CupertinoColors.black.withValues(
                    alpha: (isDark ? 0.35 : 0.20) * shadowFactor,
                  ),
                  blurRadius: 40.0 * shadowFactor,
                  offset: Offset(0, 10.0 * shadowFactor),
                ),
                BoxShadow(
                  color: CupertinoColors.black.withValues(
                    alpha: (isDark ? 0.20 : 0.06) * shadowFactor,
                  ),
                  blurRadius: 8.0 * shadowFactor,
                  offset: Offset(0, 2.0 * shadowFactor),
                ),
              ];

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Origin slot: the page background showing where the row was
            // (native leaves the slot empty rather than white).
            if (widget.originSlotColor != null)
              Positioned.fromRect(
                rect: widget.targetRect,
                child: ColoredBox(color: widget.originSlotColor!),
              ),

            // 2. Backdrop scrim (dims the page, including the origin slot).
            Positioned.fill(child: scrimLayer),

            // 3. Hidden measurement pass (offstage)
            Offstage(
              offstage: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: _previewMeasureKey,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenSize.width - 32.0,
                      ),
                      child: previewWidget,
                    ),
                  ),
                  KeyedSubtree(
                    key: _platterMeasureKey,
                    child: SizedBox(
                      width: widget.menuWidth,
                      child: buildPlatter(isMeasurement: true),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Hero morphing card: the row layer fades out while the preview
            // layer fades in, each carrying its own opaque background.
            Positioned.fromRect(
              rect: cardRect,
              child: GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                behavior: HitTestBehavior.opaque,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(borderRadius: cardRadii),
                    shadows: cardShadows,
                  ),
                  child: ClipRSuperellipse(
                    borderRadius: cardRadii,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.previewChild != null && rowAlpha > 0.0)
                          Opacity(
                            opacity: rowAlpha,
                            child: ColoredBox(
                              color: cardColor,
                              child: Transform.scale(
                                scale: rowScale,
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  minWidth: widget.targetRect.width,
                                  maxWidth: widget.targetRect.width,
                                  minHeight: widget.targetRect.height,
                                  maxHeight: widget.targetRect.height,
                                  child: widget.previewChild!,
                                ),
                              ),
                            ),
                          ),
                        if (previewAlpha > 0.0)
                          Opacity(
                            opacity: previewAlpha,
                            child: ColoredBox(
                              color: cardColor,
                              child: Transform.scale(
                                scale: previewScale,
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  minWidth: restingPreviewRect.width,
                                  maxWidth: restingPreviewRect.width,
                                  minHeight: restingPreviewRect.height,
                                  maxHeight: restingPreviewRect.height,
                                  child: previewWidget,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 5. Action platter
            if (platterOpacity > 0.0)
              Positioned.fromRect(
                rect: restingPlatterRect,
                child: Transform.scale(
                  scale: platterScale,
                  alignment: platterAnchor,
                  child: Opacity(
                    opacity: platterOpacity,
                    child: buildPlatter(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Convenience extension providing `.glassContextMenu()` on any [Widget].
extension GlassContextMenuExtension on Widget {
  /// Wraps this widget in a [GlassContextMenu] displaying [actions] on long-press or right-click.
  Widget glassContextMenu({
    Key? key,
    required List<Widget> actions,
    WidgetBuilder? previewBuilder,
    bool enabled = true,
    bool enableHaptics = true,
    double borderRadius = 32.0,
    double? previewBorderRadius,
    double rowBorderRadius = 16.0,
    BorderRadius? rowCorners,
    Color? originSlotColor,
    Color? backgroundColor,
    LiquidGlassSettings? settings,
    GlassQuality? quality,
    double backdropBlur = 0.0,
    Color? barrierColor,
    double menuWidth = 250.0,
    VoidCallback? onOpened,
    VoidCallback? onDismissed,
    Duration longPressDuration = const Duration(milliseconds: 700),
  }) {
    return GlassContextMenu(
      key: key,
      actions: actions,
      previewBuilder: previewBuilder,
      enabled: enabled,
      enableHaptics: enableHaptics,
      borderRadius: borderRadius,
      previewBorderRadius: previewBorderRadius,
      rowBorderRadius: rowBorderRadius,
      rowCorners: rowCorners,
      originSlotColor: originSlotColor,
      backgroundColor: backgroundColor,
      settings: settings,
      quality: quality,
      backdropBlur: backdropBlur,
      barrierColor: barrierColor,
      menuWidth: menuWidth,
      onOpened: onOpened,
      onDismissed: onDismissed,
      longPressDuration: longPressDuration,
      child: this,
    );
  }
}
