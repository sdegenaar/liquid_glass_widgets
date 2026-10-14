import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../utils/glass_spring.dart';
import '../shared/glass_accessibility_scope.dart';
import '../shared/glass_swipe_action_scope.dart';

/// The current visual and interaction state of a [GlassSwipeActions] row.
enum GlassSwipeState {
  /// Actions are fully closed; the primary child is resting.
  idle,

  /// The user is actively dragging the row.
  dragging,

  /// Leading actions are open and resting at their total reveal width.
  openLeading,

  /// Trailing actions are open and resting at their total reveal width.
  openTrailing,

  /// The row is pulled past the full-swipe threshold revealing leading actions.
  fullSwipeLeading,

  /// The row is pulled past the full-swipe threshold revealing trailing actions.
  fullSwipeTrailing,
}

/// Visual styling options for [GlassSwipeActions] buttons.
enum GlassSwipeActionStyle {
  /// Authentic iOS 26/27 liquid glass styling with subtle translucency,
  /// specular rim highlight, and surface gradient.
  tintedGlass,

  /// Vibrant solid system styling matching classic UIKit and SwiftUI table views.
  solidVibrancy,
}

/// A discrete swipeable action button in a [GlassSwipeActions] platter.
///
/// Defines the icon, label, background color, and behavior for a leading or
/// trailing action in a swipeable list row.
@immutable
class GlassSwipeAction {
  /// Creates a swipe action.
  const GlassSwipeAction({
    required this.icon,
    this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor = CupertinoColors.white,
    this.isDestructive = false,
    this.closeOnTap = true,
    this.flex = 1,
    this.semanticLabel,
  }) : assert(flex > 0, 'flex must be greater than 0');

  /// The icon widget displayed for this action.
  ///
  /// Typically a Cupertino [Icon].
  final Widget icon;

  /// Optional text label displayed beneath [icon].
  final Widget? label;

  /// Callback executed when the action is triggered by tap or full swipe.
  final VoidCallback onTap;

  /// Background color of the action platter.
  ///
  /// If null, defaults to [CupertinoColors.systemRed] when [isDestructive] is true,
  /// or [CupertinoColors.systemBlue] otherwise.
  final Color? backgroundColor;

  /// Color applied to [icon] and [label].
  ///
  /// Defaults to [CupertinoColors.white].
  final Color? foregroundColor;

  /// Whether this action represents a destructive action (e.g. Delete, Trash).
  ///
  /// When true, defaults [backgroundColor] to [CupertinoColors.systemRed] and
  /// configures accessibility semantics accordingly.
  final bool isDestructive;

  /// Whether the swipe platter should automatically spring closed when this
  /// action is tapped.
  ///
  /// Defaults to `true`.
  final bool closeOnTap;

  /// Proportional width share if multiple actions are shown.
  ///
  /// Defaults to 1.
  final int flex;

  /// Accessibility label announced by screen readers.
  ///
  /// If null, defaults to the text in [label] if [label] is a [Text] widget,
  /// or a localized description.
  final String? semanticLabel;
}

/// A controller to programmatically open, close, and inspect a [GlassSwipeActions] row.
class GlassSwipeController extends ChangeNotifier {
  GlassSwipeActionsState? _state;

  void _attach(GlassSwipeActionsState state) {
    _state = state;
  }

  void _detach(GlassSwipeActionsState state) {
    if (_state == state) {
      _state = null;
    }
  }

  /// Whether the actions row is currently open (leading or trailing).
  bool get isOpen => _state?.isOpen ?? false;

  /// Current swipe state.
  GlassSwipeState get swipeState => _state?.swipeState ?? GlassSwipeState.idle;

  /// Current horizontal offset of the primary child in logical pixels.
  double get offset => _state?.offset ?? 0.0;

  /// Programmatically opens the trailing actions.
  void openTrailing({bool animated = true}) {
    _state?.openTrailing(animated: animated);
  }

  /// Programmatically opens the leading actions.
  void openLeading({bool animated = true}) {
    _state?.openLeading(animated: animated);
  }

  /// Programmatically closes any open actions.
  void close({bool animated = true}) {
    _state?.close(animated: animated);
  }

  void _notify() {
    notifyListeners();
  }
}

/// A container widget that adds iOS-style swipe actions (`.swipeActions()`) to any child.
///
/// Swiping the child horizontally reveals leading or trailing action buttons with
/// authentic iOS physics:
/// - Smooth underdamped spring animations via [GlassSpring].
/// - Rubber-band damping when pulled beyond the action bounds.
/// - Full-swipe execution: dragging past [fullSwipeThreshold] (default 65% of width)
///   triggers a haptic tick and executes the outermost action automatically upon release.
/// - Mutual exclusivity and scroll dismissal when placed inside a [GlassSwipeActionScope].
/// - Full right-to-left (RTL) layout symmetry.
///
/// ## Usage
///
/// ```dart
/// GlassSwipeActions(
///   trailingActions: [
///     GlassSwipeAction(
///       icon: const Icon(CupertinoIcons.trash),
///       label: const Text('Delete'),
///       isDestructive: true,
///       onTap: () => handleDelete(),
///     ),
///     GlassSwipeAction(
///       icon: const Icon(CupertinoIcons.flag),
///       label: const Text('Flag'),
///       backgroundColor: CupertinoColors.systemOrange,
///       onTap: () => handleFlag(),
///     ),
///   ],
///   child: GlassListTile(
///     title: const Text('Swipeable Row'),
///   ),
/// )
/// ```
class GlassSwipeActions extends StatefulWidget {
  /// Creates a swipeable action container.
  const GlassSwipeActions({
    super.key,
    required this.child,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.allowsFullSwipe = true,
    this.fullSwipeThreshold = 0.65,
    this.actionWidth = 74.0,
    this.borderRadius,
    this.controller,
    this.onSwipeStateChanged,
    this.enableHaptics = true,
    this.clipBehavior = Clip.antiAlias,
    this.style = GlassSwipeActionStyle.tintedGlass,
    this.onDismissed,
  }) : assert(fullSwipeThreshold > 0.0 && fullSwipeThreshold <= 1.0,
            'fullSwipeThreshold must be between 0.0 and 1.0');

  /// The primary content widget displayed in the row.
  final Widget child;

  /// Actions revealed when swiping from the leading edge (left in LTR).
  final List<GlassSwipeAction> leadingActions;

  /// Actions revealed when swiping from the trailing edge (right in LTR).
  final List<GlassSwipeAction> trailingActions;

  /// Whether pulling past [fullSwipeThreshold] automatically executes the
  /// outermost action on release.
  ///
  /// Defaults to `true`, matching native iOS behavior.
  final bool allowsFullSwipe;

  /// Proportion of the row's total width required to prime full-swipe execution.
  ///
  /// Defaults to `0.65` (65%).
  final double fullSwipeThreshold;

  /// Base width allocated for each action button when resting open.
  ///
  /// Defaults to `74.0` logical pixels.
  final double actionWidth;

  /// Optional border radius used to clip the action platter and sliding child.
  ///
  /// Typically matches the parent container's superellipse or rounded corners.
  final BorderRadiusGeometry? borderRadius;

  /// Optional external controller for programmatic inspection and opening/closing.
  final GlassSwipeController? controller;

  /// Callback fired when the swipe state changes.
  final ValueChanged<GlassSwipeState>? onSwipeStateChanged;

  /// Whether to fire tactile haptic feedback when entering full-swipe mode.
  ///
  /// Defaults to `true`.
  final bool enableHaptics;

  /// Clip behavior applied when [borderRadius] is non-null.
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  /// Visual styling applied to the swipe action platter.
  ///
  /// Defaults to [GlassSwipeActionStyle.tintedGlass].
  final GlassSwipeActionStyle style;

  /// Optional callback executed when the row is dismissed via full swipe.
  ///
  /// When provided, a committed full-swipe animates the row off-screen and
  /// smoothly collapses its height down to zero with iOS ease curves before
  /// invoking this callback.
  final VoidCallback? onDismissed;

  @override
  State<GlassSwipeActions> createState() => GlassSwipeActionsState();
}

/// State for [GlassSwipeActions], accessible via [GlobalKey] or [GlassSwipeController].
class GlassSwipeActionsState extends State<GlassSwipeActions>
    with TickerProviderStateMixin
    implements GlassSwipeActionsControllerInterface {
  late final SingleSpringController _springController;
  late final AnimationController _dismissController;

  double _offset = 0.0;
  double _targetOffset = 0.0;
  bool _isDragging = false;
  bool _hasFiredHaptic = false;
  GlassSwipeState _swipeState = GlassSwipeState.idle;

  /// Current horizontal offset of the primary child in logical pixels.
  double get offset => _offset;

  /// Current swipe state.
  GlassSwipeState get swipeState => _swipeState;

  /// Whether the actions row is currently resting open.
  bool get isOpen =>
      _swipeState == GlassSwipeState.openLeading ||
      _swipeState == GlassSwipeState.openTrailing ||
      _targetOffset.abs() > 0.5 ||
      _offset.abs() > 0.5;

  @override
  void initState() {
    super.initState();
    _springController = SingleSpringController(
      vsync: this,
      spring: GlassSpring.snappy(),
      initialValue: 0.0,
    )..addListener(_onSpringUpdate);

    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    widget.controller?._attach(this);
  }

  GlassSwipeActionScopeState? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = GlassSwipeActionScope.of(context);
  }

  @override
  void didUpdateWidget(GlassSwipeActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _scope?.unregisterRow(this);
    _springController.removeListener(_onSpringUpdate);
    _springController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _onSpringUpdate() {
    if (!mounted) return;
    setState(() {
      _offset = _springController.value;
      if (!_isDragging) {
        if ((_offset - _targetOffset).abs() < 1.0) {
          _updateSettledState();
        }
      }
    });
  }

  void _updateSettledState() {
    if (!mounted) return;
    if (_targetOffset == 0.0) {
      _setSwipeState(GlassSwipeState.idle);
    } else {
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final directionalTarget = isRtl ? -_targetOffset : _targetOffset;
      if (directionalTarget > 0) {
        _setSwipeState(GlassSwipeState.openLeading);
      } else {
        _setSwipeState(GlassSwipeState.openTrailing);
      }
    }
  }

  void _setSwipeState(GlassSwipeState newState) {
    if (_swipeState != newState) {
      _swipeState = newState;
      widget.onSwipeStateChanged?.call(newState);
      widget.controller?._notify();
    }
  }

  /// Programmatically opens the trailing actions.
  void openTrailing({bool animated = true}) {
    if (!mounted || widget.trailingActions.isEmpty) return;
    final totalWidth = widget.trailingActions.length * widget.actionWidth;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final target = isRtl ? totalWidth : -totalWidth;
    _scope?.registerOpenRow(this);
    _animateTo(target, animated: animated);
  }

  /// Programmatically opens the leading actions.
  void openLeading({bool animated = true}) {
    if (!mounted || widget.leadingActions.isEmpty) return;
    final totalWidth = widget.leadingActions.length * widget.actionWidth;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final target = isRtl ? -totalWidth : totalWidth;
    _scope?.registerOpenRow(this);
    _animateTo(target, animated: animated);
  }

  @override
  void close({bool animated = true}) {
    if (!mounted) return;
    _scope?.unregisterRow(this);
    _animateTo(0.0, animated: animated);
  }

  void _animateTo(double target,
      {bool animated = true, double velocity = 0.0}) {
    if (!mounted) return;
    _targetOffset = target;
    final reduceMotion = GlassAccessibilityData.of(context).reduceMotion ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    if (!animated || reduceMotion) {
      _springController.setValue(target);
      if (mounted) {
        setState(() {
          _offset = target;
          _updateSettledState();
        });
      }
    } else {
      _springController.setValue(_offset);
      _springController.animateTo(target, fromVelocity: velocity);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (!mounted) return;
    _isDragging = true;
    _hasFiredHaptic = false;
    _setSwipeState(GlassSwipeState.dragging);
    _scope?.registerOpenRow(this);
    _springController.setValue(_offset);
  }

  void _handleDragUpdate(DragUpdateDetails details, double rowWidth) {
    if (!mounted || !_isDragging) return;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final delta = details.primaryDelta ?? 0.0;
    double newOffset = _offset + delta;
    double directionalOffset = isRtl ? -newOffset : newOffset;

    // Disallow swiping if no actions exist on that side
    if (directionalOffset > 0 && widget.leadingActions.isEmpty) {
      newOffset = 0.0;
      directionalOffset = 0.0;
    } else if (directionalOffset < 0 && widget.trailingActions.isEmpty) {
      newOffset = 0.0;
      directionalOffset = 0.0;
    }

    // Apply rubber-band damping if full swipe is disabled
    if (!widget.allowsFullSwipe) {
      if (directionalOffset > 0) {
        final maxLeading = widget.leadingActions.length * widget.actionWidth;
        if (directionalOffset > maxLeading) {
          final excess = directionalOffset - maxLeading;
          directionalOffset = maxLeading + excess * 0.25;
          newOffset = isRtl ? -directionalOffset : directionalOffset;
        }
      } else if (directionalOffset < 0) {
        final maxTrailing = widget.trailingActions.length * widget.actionWidth;
        if (directionalOffset.abs() > maxTrailing) {
          final excess = directionalOffset.abs() - maxTrailing;
          directionalOffset = -(maxTrailing + excess * 0.25);
          newOffset = isRtl ? -directionalOffset : directionalOffset;
        }
      }
    }

    final revealDistance = directionalOffset.abs();
    final thresholdDistance = widget.fullSwipeThreshold * rowWidth;

    if (widget.allowsFullSwipe && revealDistance >= thresholdDistance) {
      if (!_hasFiredHaptic && widget.enableHaptics) {
        _hasFiredHaptic = true;
        unawaited(HapticFeedback.mediumImpact());
      }
      _setSwipeState(directionalOffset > 0
          ? GlassSwipeState.fullSwipeLeading
          : GlassSwipeState.fullSwipeTrailing);
    } else {
      if (revealDistance < thresholdDistance) {
        _hasFiredHaptic = false;
      }
      _setSwipeState(GlassSwipeState.dragging);
    }

    setState(() {
      _offset = newOffset;
    });
  }

  void _handleDragEnd(DragEndDetails details, double rowWidth) {
    if (!mounted) return;
    _isDragging = false;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final velocity = details.primaryVelocity ?? 0.0;
    final directionalVelocity = isRtl ? -velocity : velocity;
    final directionalOffset = isRtl ? -_offset : _offset;
    final revealDistance = directionalOffset.abs();
    final thresholdDistance = widget.fullSwipeThreshold * rowWidth;

    if (widget.allowsFullSwipe && revealDistance >= thresholdDistance) {
      final isLeading = directionalOffset > 0;
      // In both leading and trailing, actions.first is the outermost action at the edge
      final action = isLeading
          ? widget.leadingActions.first
          : widget.trailingActions.first;

      action.onTap();

      if (widget.onDismissed != null) {
        final dismissTarget = isRtl
            ? (isLeading ? -rowWidth : rowWidth)
            : (isLeading ? rowWidth : -rowWidth);
        _animateTo(dismissTarget, velocity: velocity);
        unawaited(_dismissController.forward().then((_) {
          widget.onDismissed?.call();
        }));
      } else {
        close();
      }
      return;
    }

    // Determine resting settle target
    if (directionalOffset > 0 && widget.leadingActions.isNotEmpty) {
      final totalLeading = widget.leadingActions.length * widget.actionWidth;
      final shouldOpen =
          revealDistance > totalLeading * 0.4 || directionalVelocity > 300;
      if (shouldOpen) {
        final target = isRtl ? -totalLeading : totalLeading;
        _animateTo(target, velocity: velocity);
        _setSwipeState(GlassSwipeState.openLeading);
      } else {
        close();
      }
    } else if (directionalOffset < 0 && widget.trailingActions.isNotEmpty) {
      final totalTrailing = widget.trailingActions.length * widget.actionWidth;
      final shouldOpen =
          revealDistance > totalTrailing * 0.4 || directionalVelocity < -300;
      if (shouldOpen) {
        final target = isRtl ? totalTrailing : -totalTrailing;
        _animateTo(target, velocity: velocity);
        _setSwipeState(GlassSwipeState.openTrailing);
      } else {
        close();
      }
    } else {
      close();
    }
  }

  void _handleDragCancel() {
    if (_isDragging) {
      _isDragging = false;
      _animateTo(_targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final isRtl = direction == TextDirection.rtl;
    final directionalOffset = isRtl ? -_offset : _offset;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        Widget body = Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Background Action Platter (Revealed underneath)
            if (directionalOffset > 0 && widget.leadingActions.isNotEmpty)
              Positioned.directional(
                textDirection: direction,
                start: 0,
                top: 0,
                bottom: 0,
                width: directionalOffset,
                child:
                    _buildLeadingPlatter(context, directionalOffset, rowWidth),
              )
            else if (directionalOffset < 0 && widget.trailingActions.isNotEmpty)
              Positioned.directional(
                textDirection: direction,
                end: 0,
                top: 0,
                bottom: 0,
                width: directionalOffset.abs(),
                child: _buildTrailingPlatter(
                    context, directionalOffset.abs(), rowWidth),
              ),

            // Sliding Primary Child
            Transform.translate(
              offset: Offset(_offset, 0.0),
              child: widget.child,
            ),

            // Tap blocker over shifted child: tapping shifted child snaps it closed
            if (isOpen && !_isDragging)
              Positioned.directional(
                textDirection: direction,
                start: directionalOffset > 0 ? directionalOffset : 0,
                end: directionalOffset < 0 ? directionalOffset.abs() : 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => close(),
                ),
              ),
          ],
        );

        if (widget.borderRadius != null) {
          body = ClipRRect(
            borderRadius: widget.borderRadius!.resolve(direction),
            clipBehavior: widget.clipBehavior,
            child: body,
          );
        }

        body = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: (details) =>
              _handleDragUpdate(details, rowWidth),
          onHorizontalDragEnd: (details) => _handleDragEnd(details, rowWidth),
          onHorizontalDragCancel: _handleDragCancel,
          child: body,
        );

        if (widget.onDismissed != null) {
          body = SizeTransition(
            sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: _dismissController,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: body,
          );
        }

        return body;
      },
    );
  }

  Widget _buildLeadingPlatter(
      BuildContext context, double revealWidth, double rowWidth) {
    final actions = widget.leadingActions;
    final totalStandardWidth = actions.length * widget.actionWidth;
    final isFullSwipe = widget.allowsFullSwipe &&
        revealWidth >= widget.fullSwipeThreshold * rowWidth;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          _buildActionButton(
            context: context,
            action: actions[i],
            width: _computeLeadingActionWidth(
                i, actions.length, revealWidth, totalStandardWidth),
            isOutermost: i == 0,
            isFullSwipe: isFullSwipe && i == 0,
            isTrailing: false,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailingPlatter(
      BuildContext context, double revealWidth, double rowWidth) {
    final actions = widget.trailingActions;
    final totalStandardWidth = actions.length * widget.actionWidth;
    final isFullSwipe = widget.allowsFullSwipe &&
        revealWidth >= widget.fullSwipeThreshold * rowWidth;

    // In SwiftUI and UIKit, actions[0] is the primary outermost action at the edge.
    // In LTR, the platter's visual order from inner (left) to outer edge (right) is:
    // actions[count - 1], actions[count - 2], ..., actions[0].
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          () {
            final originalIndex = actions.length - 1 - i;
            final isOutermost = originalIndex == 0;
            return _buildActionButton(
              context: context,
              action: actions[originalIndex],
              width: _computeTrailingActionWidth(originalIndex, actions.length,
                  revealWidth, totalStandardWidth),
              isOutermost: isOutermost,
              isFullSwipe: isFullSwipe && isOutermost,
              isTrailing: true,
            );
          }(),
        ],
      ],
    );
  }

  double _computeLeadingActionWidth(
      int index, int count, double revealWidth, double totalStandardWidth) {
    if (revealWidth <= totalStandardWidth) {
      return revealWidth / count;
    }
    // Leading outermost is index 0: it absorbs extra stretch space
    if (index == 0) {
      return revealWidth - (count - 1) * widget.actionWidth;
    }
    return widget.actionWidth;
  }

  double _computeTrailingActionWidth(int originalIndex, int count,
      double revealWidth, double totalStandardWidth) {
    if (revealWidth <= totalStandardWidth) {
      return revealWidth / count;
    }
    // Trailing outermost is actions[0] (originalIndex == 0): it absorbs extra stretch space
    if (originalIndex == 0) {
      return revealWidth - (count - 1) * widget.actionWidth;
    }
    return widget.actionWidth;
  }

  Widget _buildActionButton({
    required BuildContext context,
    required GlassSwipeAction action,
    required double width,
    required bool isOutermost,
    required bool isFullSwipe,
    required bool isTrailing,
  }) {
    if (width <= 0.0) return const SizedBox.shrink();

    return _GlassSwipeActionButton(
      action: action,
      width: width,
      standardWidth: widget.actionWidth,
      isOutermost: isOutermost,
      isFullSwipe: isFullSwipe,
      isTrailing: isTrailing,
      style: widget.style,
      onPressed: () {
        action.onTap();
        if (action.closeOnTap) {
          close();
        }
      },
    );
  }
}

class _GlassSwipeActionButton extends StatefulWidget {
  const _GlassSwipeActionButton({
    required this.action,
    required this.width,
    required this.standardWidth,
    required this.onPressed,
    this.isOutermost = false,
    this.isFullSwipe = false,
    this.isTrailing = true,
    this.style = GlassSwipeActionStyle.tintedGlass,
  });

  final GlassSwipeAction action;
  final double width;
  final double standardWidth;
  final VoidCallback onPressed;
  final bool isOutermost;
  final bool isFullSwipe;
  final bool isTrailing;
  final GlassSwipeActionStyle style;

  @override
  State<_GlassSwipeActionButton> createState() =>
      _GlassSwipeActionButtonState();
}

class _GlassSwipeActionButtonState extends State<_GlassSwipeActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = widget.action.backgroundColor ??
        (widget.action.isDestructive
            ? CupertinoColors.systemRed.resolveFrom(context)
            : CupertinoColors.systemBlue.resolveFrom(context));

    final effectiveFgColor =
        widget.action.foregroundColor ?? CupertinoColors.white;

    final String? resolvedSemanticLabel = widget.action.semanticLabel ??
        (widget.action.label is Text
            ? (widget.action.label as Text).data
            : null);

    // NOTE: A BoxDecoration paints its `gradient` *instead of* its `color`
    // when both are set, so the tint and the specular sheen are two layers:
    // a solid tint underneath and the sheen decoration on top of it.
    final Color tint;
    final BoxDecoration sheen;
    if (widget.style == GlassSwipeActionStyle.tintedGlass) {
      tint = _isPressed
          ? effectiveBgColor.withValues(alpha: 0.76)
          : effectiveBgColor.withValues(alpha: 0.90);
      sheen = BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.white.withValues(alpha: 0.22),
            width: 0.75,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CupertinoColors.white.withValues(alpha: 0.16),
            CupertinoColors.white.withValues(alpha: 0.03),
            CupertinoColors.black.withValues(alpha: 0.12),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      );
    } else {
      tint = _isPressed
          ? effectiveBgColor.withValues(alpha: 0.82)
          : effectiveBgColor;
      sheen = const BoxDecoration();
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final Alignment effectiveAlignment;
    if (!widget.isOutermost) {
      effectiveAlignment = Alignment.center;
    } else if (widget.isTrailing) {
      effectiveAlignment = isRtl ? Alignment.centerLeft : Alignment.centerRight;
    } else {
      effectiveAlignment = isRtl ? Alignment.centerRight : Alignment.centerLeft;
    }

    return SizedBox(
      width: widget.width,
      child: Semantics(
        button: true,
        label: resolvedSemanticLabel,
        onTap: widget.onPressed,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          child: ColoredBox(
            color: tint,
            child: DecoratedBox(
              decoration: sheen,
              child: Container(
                alignment: effectiveAlignment,
                child: SizedBox(
                  width: widget.standardWidth,
                  child: AnimatedScale(
                    scale: widget.isFullSwipe ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: IconTheme(
                      data: IconThemeData(
                        color: effectiveFgColor,
                        size: 22,
                      ),
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: effectiveFgColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            widget.action.icon,
                            if (widget.action.label != null) ...[
                              const SizedBox(height: 3),
                              widget.action.label!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
