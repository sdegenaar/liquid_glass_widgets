import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../theme/glass_theme.dart';
import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import '../containers/glass_divider.dart';
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
/// - Standard iOS 44pt touch target height.
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
    this.iconPosition = GlassContextMenuIconPosition.trailing,
    this.isDestructive = false,
    this.isSelected = false,
    this.trailing,
    this.height = 44.0,
    this.enabled = true,
  });

  /// Primary label or content widget of the action.
  final Widget child;

  /// Callback executed when this action is tapped or selected via glide.
  final VoidCallback? onPressed;

  /// Optional icon displayed with the action.
  final Widget? icon;

  /// Position of the icon relative to [child] (defaults to [GlassContextMenuIconPosition.trailing]).
  final GlassContextMenuIconPosition iconPosition;

  /// Whether this action performs a destructive operation (e.g. Delete, Remove).
  final bool isDestructive;

  /// Whether this action represents an active/selected choice.
  /// When true, renders a leading checkmark icon.
  final bool isSelected;

  /// Optional trailing accessory widget (e.g. keyboard shortcut or badge).
  final Widget? trailing;

  /// Height of the action row (defaults to 44.0).
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

    final effectiveColor =
        widget.enabled ? baseTextColor : baseTextColor.withValues(alpha: 0.4);

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
                    IconTheme(
                      data: IconThemeData(color: effectiveColor, size: 19),
                      child: widget.icon!,
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
/// - **Authentic Touch Compression**: On touch-down, the child gently compresses to 0.96x.
/// - **Haptic Surface Lift**: Fires `HapticFeedback.mediumImpact()` as the child lifts.
/// - **Liquid Glass Backdrop**: Progressive gaussian blur and subtle dimming.
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
    this.borderRadius = 16.0,
    this.settings,
    this.quality,
    this.backdropBlur = 20.0,
    this.barrierColor,
    this.menuWidth = 250.0,
    this.onOpened,
    this.onDismissed,
    this.longPressDuration = const Duration(milliseconds: 320),
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

  /// Border radius of the lifted preview and action menu platter.
  final double borderRadius;

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
  /// Defaults to 320 milliseconds, matching iOS 26/27 haptic lift dynamics.
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

class _GlassContextMenuState extends State<GlassContextMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;
  bool _isRouteOpen = false;
  GlobalKey<_GlassContextMenuRouteStaticState>? _routeStaticKey;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _openContextMenu() {
    if (!widget.enabled || widget.actions.isEmpty || _isRouteOpen) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final targetRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _isRouteOpen = true;
    });
    _pressController.reverse();
    widget.onOpened?.call();

    final staticKey = GlobalKey<_GlassContextMenuRouteStaticState>();
    _routeStaticKey = staticKey;

    showGlassContextMenu<void>(
      context: context,
      targetRect: targetRect,
      actions: widget.actions,
      previewBuilder: widget.previewBuilder,
      previewChild: widget.child,
      borderRadius: widget.borderRadius,
      settings: widget.settings,
      quality: widget.quality,
      backdropBlur: widget.backdropBlur,
      barrierColor: widget.barrierColor,
      menuWidth: widget.menuWidth,
      enableHaptics: widget.enableHaptics,
      routeStaticKey: staticKey,
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

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _ContextMenuLongPressRecognizer: GestureRecognizerFactoryWithHandlers<
            _ContextMenuLongPressRecognizer>(
          () => _ContextMenuLongPressRecognizer(
            duration: widget.longPressDuration,
            debugOwner: this,
            onRejected: () {
              if (!_isRouteOpen && mounted) {
                _pressController.reverse();
              }
            },
          ),
          (instance) {
            instance
              ..onLongPressDown = (_) {
                if (!_isRouteOpen) {
                  _pressController.forward();
                }
              }
              ..onLongPressCancel = () {
                if (!_isRouteOpen && mounted) {
                  _pressController.reverse();
                }
              }
              ..onLongPressStart = (_) {
                _openContextMenu();
              }
              ..onLongPressUp = () {
                if (!_isRouteOpen && mounted) {
                  _pressController.reverse();
                }
              }
              ..onLongPressMoveUpdate = (details) {
                if (_isRouteOpen && _routeStaticKey != null) {
                  _routeStaticKey!.currentState
                      ?.updateGlidePosition(details.globalPosition);
                }
              }
              ..onLongPressEnd = (_) {
                if (_isRouteOpen && _routeStaticKey != null) {
                  _routeStaticKey!.currentState?.endGlide();
                } else if (!_isRouteOpen && mounted) {
                  _pressController.reverse();
                }
              };
          },
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(debugOwner: this),
          (instance) {
            instance.onSecondaryTapUp = (_) {
              _openContextMenu();
            };
          },
        ),
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _isRouteOpen ? 0.0 : 1.0,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
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
  double borderRadius = 16.0,
  LiquidGlassSettings? settings,
  GlassQuality? quality,
  double backdropBlur = 20.0,
  Color? barrierColor,
  double menuWidth = 250.0,
  bool enableHaptics = true,
  GlobalKey? routeStaticKey,
}) {
  assert(actions.isNotEmpty, 'Context menu actions must not be empty.');
  return Navigator.of(context, rootNavigator: true).push<T>(
    _GlassContextMenuRoute<T>(
      targetRect: targetRect,
      actions: actions,
      previewBuilder: previewBuilder,
      previewChild: previewChild,
      borderRadius: borderRadius,
      glassSettings: settings,
      quality: quality,
      backdropBlur: backdropBlur,
      scrimColor: barrierColor,
      menuWidth: menuWidth,
      enableHaptics: enableHaptics,
      routeStaticKey: routeStaticKey,
    ),
  );
}

class _GlassContextMenuRoute<T> extends PopupRoute<T> {
  _GlassContextMenuRoute({
    required this.targetRect,
    required this.actions,
    this.previewBuilder,
    this.previewChild,
    required this.borderRadius,
    this.glassSettings,
    this.quality,
    required this.backdropBlur,
    this.scrimColor,
    required this.menuWidth,
    required this.enableHaptics,
    this.routeStaticKey,
  });

  final Rect targetRect;
  final List<Widget> actions;
  final WidgetBuilder? previewBuilder;
  final Widget? previewChild;
  final double borderRadius;
  final LiquidGlassSettings? glassSettings;
  final GlassQuality? quality;
  final double backdropBlur;

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

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss context menu';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _GlassContextMenuRouteStatic(
      key: routeStaticKey,
      targetRect: targetRect,
      actions: actions,
      previewBuilder: previewBuilder,
      previewChild: previewChild,
      borderRadius: borderRadius,
      settings: glassSettings,
      quality: quality,
      backdropBlur: backdropBlur,
      scrimColor: scrimColor,
      menuWidth: menuWidth,
      enableHaptics: enableHaptics,
      animation: animation,
    );
  }
}

class _GlassContextMenuRouteStatic extends StatefulWidget {
  const _GlassContextMenuRouteStatic({
    super.key,
    required this.targetRect,
    required this.actions,
    this.previewBuilder,
    this.previewChild,
    required this.borderRadius,
    this.settings,
    this.quality,
    required this.backdropBlur,
    this.scrimColor,
    required this.menuWidth,
    required this.enableHaptics,
    required this.animation,
  });

  final Rect targetRect;
  final List<Widget> actions;
  final WidgetBuilder? previewBuilder;
  final Widget? previewChild;
  final double borderRadius;
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
  late final CurvedAnimation _curved;
  final GlobalKey _previewKey = GlobalKey();
  Offset? _measuredRestingCenter;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _actionKeys = List.generate(widget.actions.length, (_) => GlobalKey());
    _curved = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointer);
    WidgetsBinding.instance.addPostFrameCallback(_measureRestingCenter);
  }

  void _measureRestingCenter(Duration _) {
    if (!mounted) return;
    final box = _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final pos = box.localToGlobal(Offset.zero);
      final center = pos + Offset(box.size.width / 2.0, box.size.height / 2.0);
      if (_measuredRestingCenter != center) {
        setState(() {
          _measuredRestingCenter = center;
        });
      }
    }
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handleGlobalPointer);
    _curved.dispose();
    super.dispose();
  }

  void _handleGlobalPointer(PointerEvent event) {
    if (!mounted) return;
    if (event is PointerMoveEvent) {
      updateGlidePosition(event.position);
    } else if (event is PointerUpEvent) {
      updateGlidePosition(event.position);
      endGlide();
    } else if (event is PointerCancelEvent) {
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

    // Calculate vertical placement (above vs below)
    final double spaceBelow =
        screenSize.height - padding.bottom - widget.targetRect.bottom - 12.0;
    final double spaceAbove = widget.targetRect.top - padding.top - 12.0;

    final bool placeBelow = spaceBelow >= 200.0 || spaceBelow >= spaceAbove;

    // Calculate horizontal clamping
    final double idealLeft =
        widget.targetRect.center.dx - (widget.menuWidth / 2.0);
    final double menuLeft = idealLeft.clamp(
      16.0,
      screenSize.width - widget.menuWidth - 16.0,
    );

    // Alignment anchor for spring scale
    final Alignment menuAlignment = placeBelow
        ? (menuLeft <= 20.0
            ? Alignment.topLeft
            : (menuLeft >= screenSize.width - widget.menuWidth - 20.0
                ? Alignment.topRight
                : Alignment.topCenter))
        : (menuLeft <= 20.0
            ? Alignment.bottomLeft
            : (menuLeft >= screenSize.width - widget.menuWidth - 20.0
                ? Alignment.bottomRight
                : Alignment.bottomCenter));

    final bool isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final Color scrim = widget.scrimColor ??
        (isDark ? const Color(0x66000000) : const Color(0x33000000));
    // Light mode: a bright, milky platter (iOS 26 context menus are light
    // glass over a dimmed backdrop). Dark mode keeps the package defaults.
    final LiquidGlassSettings? platterSettings = widget.settings ??
        (isDark
            ? null
            : const LiquidGlassSettings(
                glassColor: Color(0xCCF5F5F7),
                thickness: 16,
                blur: 22,
                saturation: 1.2,
                lightIntensity: 0.35,
              ));
    final bool hasCustomPreview = widget.previewBuilder != null;

    final Widget previewWidget = hasCustomPreview
        ? widget.previewBuilder!(context)
        : (widget.previewChild ?? const SizedBox.shrink());

    Widget buildPlatter() {
      return GlassContainer.card(
        useOwnLayer: true,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        shape: LiquidRoundedSuperellipse(borderRadius: widget.borderRadius),
        settings: platterSettings,
        quality: widget.quality,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < widget.actions.length; i++) ...[
                Container(
                  key: _actionKeys[i],
                  color: _hoveredIndex == i
                      ? (widget.actions[i] is GlassContextMenuAction &&
                              (widget.actions[i] as GlassContextMenuAction)
                                  .isDestructive
                          ? CupertinoColors.destructiveRed
                              .withValues(alpha: 0.16)
                          : CupertinoColors.activeBlue.withValues(alpha: 0.12))
                      : const Color(0x00000000),
                  child: widget.actions[i],
                ),
                if (i < widget.actions.length - 1)
                  const GlassDivider(indent: 16.0),
              ],
            ],
          ),
        ),
      );
    }

    Widget liftedPreview(double animValue, Widget child) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.28 * animValue),
              blurRadius: 28.0 * animValue,
              offset: Offset(0, 10.0 * animValue),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: child,
        ),
      );
    }

    Widget liftedTargetPreview(double animValue, Widget child) {
      return Transform.scale(
        scale: 1.0 + (0.02 * animValue),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(widget.borderRadius * animValue),
            boxShadow: [
              BoxShadow(
                color:
                    CupertinoColors.black.withValues(alpha: 0.28 * animValue),
                blurRadius: 28.0 * animValue,
                offset: Offset(0, 10.0 * animValue),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(widget.borderRadius * animValue),
            child: child,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final double animValue = _curved.value;

        final Widget scrimLayer = GestureDetector(
          onTap: () => Navigator.of(context, rootNavigator: true).pop(),
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.backdropBlur * animValue,
              sigmaY: widget.backdropBlur * animValue,
            ),
            child: Container(
              color: scrim.withValues(alpha: scrim.a * animValue),
            ),
          ),
        );

        final double platterProgress =
            ((animValue - 0.22) / 0.78).clamp(0.0, 1.0);
        final double platterOpacity = platterProgress;
        final double platterScale = 0.85 + (0.15 * platterProgress);

        if (hasCustomPreview) {
          final Offset fallbackRestingCenter = Offset(
            screenSize.width / 2.0,
            (screenSize.height / 2.0) - 76.0,
          );
          final Offset restingCenter =
              _measuredRestingCenter ?? fallbackRestingCenter;
          final Offset targetCenter = widget.targetRect.center;
          final Offset translationDelta = targetCenter - restingCenter;
          final Offset currentTranslation =
              translationDelta * (1.0 - animValue);

          final double targetScale =
              (widget.targetRect.height / 160.0).clamp(0.65, 0.95);
          final double currentScale =
              targetScale + (1.0 - targetScale) * animValue;

          final double previewOpacity = (animValue / 0.15).clamp(0.0, 1.0);
          final double targetRowOpacity =
              (1.0 - (animValue / 0.25)).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              scrimLayer,
              if (widget.previewChild != null)
                Positioned(
                  left: widget.targetRect.left,
                  top: widget.targetRect.top,
                  width: widget.targetRect.width,
                  height: widget.targetRect.height,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: targetRowOpacity,
                      child: widget.previewChild!,
                    ),
                  ),
                ),
              Positioned.fill(
                child: SafeArea(
                  minimum: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenSize.width - 32.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              key: _previewKey,
                              child: Transform.translate(
                                offset: currentTranslation,
                                child: Transform.scale(
                                  scale: currentScale,
                                  child: Opacity(
                                    opacity: previewOpacity,
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context,
                                              rootNavigator: true)
                                          .pop(),
                                      child: liftedPreview(
                                          animValue, previewWidget),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            SizedBox(
                              width: widget.menuWidth,
                              child: Transform.scale(
                                scale: platterScale,
                                alignment: Alignment.topCenter,
                                child: Opacity(
                                  opacity: platterOpacity,
                                  child: buildPlatter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            scrimLayer,

            // Lifted target preview
            Positioned(
              left: widget.targetRect.left,
              top: widget.targetRect.top,
              width: widget.targetRect.width,
              height: widget.targetRect.height,
              child: GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                child: liftedTargetPreview(animValue, previewWidget),
              ),
            ),

            // Action platter
            Positioned(
              left: menuLeft,
              top: placeBelow ? widget.targetRect.bottom + 12.0 : null,
              bottom: placeBelow
                  ? null
                  : (screenSize.height - widget.targetRect.top + 12.0),
              width: widget.menuWidth,
              child: Transform.scale(
                scale: platterScale,
                alignment: menuAlignment,
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
    double borderRadius = 16.0,
    LiquidGlassSettings? settings,
    GlassQuality? quality,
    double backdropBlur = 20.0,
    Color? barrierColor,
    double menuWidth = 250.0,
    VoidCallback? onOpened,
    VoidCallback? onDismissed,
    Duration longPressDuration = const Duration(milliseconds: 320),
  }) {
    return GlassContextMenu(
      key: key,
      actions: actions,
      previewBuilder: previewBuilder,
      enabled: enabled,
      enableHaptics: enableHaptics,
      borderRadius: borderRadius,
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
