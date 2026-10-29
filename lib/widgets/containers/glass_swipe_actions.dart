import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../theme/glass_theme.dart';
import '../../types/glass_surface_style.dart';
import '../../utils/glass_spring.dart';
import '../shared/glass_accessibility_scope.dart';
import '../shared/glass_solid_surface.dart';
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

  /// Programmatically animates to a specific horizontal offset in logical pixels.
  void animateToOffset(double target, {bool animated = true}) {
    _state?.animateToOffset(target, animated: animated);
  }

  /// Programmatically triggers the full-swipe dismiss animation and invokes [GlassSwipeActions.onDismissed].
  void dismiss({bool animated = true, bool fromLeading = false}) {
    _state?.dismiss(animated: animated, fromLeading: fromLeading);
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
    this.actionWidth,
    this.buttonDiameter = 50.0,
    this.buttonSpacing = 12.0,
    this.horizontalPadding = 12.0,
    this.borderRadius,
    this.controller,
    this.onSwipeStateChanged,
    this.enableHaptics = true,
    this.closeOnTapOutside = true,
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
  /// When the open actions are wider than this (long labels), a full swipe
  /// instead takes pulling the row a short distance past their open width.
  ///
  /// Defaults to `0.65` (65%).
  final double fullSwipeThreshold;

  /// Optional base width allocated for each action button when resting open.
  ///
  /// When null, defaults to authentic iOS 26/27 circular action button geometry
  /// ([buttonDiameter] + [buttonSpacing] + insets).
  final double? actionWidth;

  /// Diameter of the circular swipe action button.
  ///
  /// Defaults to `50.0` logical pixels, matching native iOS 26/27.
  final double buttonDiameter;

  /// Space between adjacent swipe action buttons.
  ///
  /// Defaults to `12.0` logical pixels, matching native iOS 26/27.
  final double buttonSpacing;

  /// Horizontal padding between the platter outer edge and the buttons.
  ///
  /// Defaults to `12.0` logical pixels, matching native iOS 26/27.
  final double horizontalPadding;

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

  /// Whether tapping or clicking anywhere outside this row while it is open
  /// automatically closes it.
  ///
  /// Defaults to `true`, matching native iOS behavior.
  final bool closeOnTapOutside;

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
  double _closingFromSign = 0.0;
  int _dragStartSide = 0;
  bool _isDragging = false;
  bool _isSnappingToZero = false;
  bool _hasFiredHaptic = false;
  bool _isDismissing = false;
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
  bool containsGlobalPoint(Offset globalPosition) {
    if (!mounted) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox &&
        renderObject.hasSize &&
        renderObject.attached) {
      final localPosition = renderObject.globalToLocal(globalPosition);
      return renderObject.size.contains(localPosition);
    }
    return false;
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    if (!mounted ||
        !widget.closeOnTapOutside ||
        !isOpen ||
        _isDragging ||
        _isDismissing) {
      return;
    }
    if (!containsGlobalPoint(event.position)) {
      close();
    }
  }

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
      duration: const Duration(milliseconds: 320),
    );

    GestureBinding.instance.pointerRouter
        .addGlobalRoute(_handleGlobalPointerEvent);
    widget.controller?._attach(this);
  }

  GlassSwipeActionScopeState? _scope;

  /// The row width of the last layout, which sets how wide the buttons can be.
  double? _rowWidth;

  /// The row height of the last layout, which sets the button diameter.
  double? _rowHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = GlassSwipeActionScope.of(context);
  }

  @override
  void didUpdateWidget(GlassSwipeActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;
    if (controllerChanged) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (_isDismissing &&
        (_dismissController.isCompleted || controllerChanged)) {
      _isDismissing = false;
      _dismissController.value = 0.0;
      _isSnappingToZero = true;
      _springController.setValue(0.0);
      _isSnappingToZero = false;
      _offset = 0.0;
      _targetOffset = 0.0;
      _closingFromSign = 0.0;
      _hasFiredHaptic = false;
      _setSwipeState(GlassSwipeState.idle);
    }
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handleGlobalPointerEvent);
    widget.controller?._detach(this);
    _scope?.unregisterRow(this);
    _springController.removeListener(_onSpringUpdate);
    _springController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _onSpringUpdate() {
    if (!mounted || _isSnappingToZero) return;
    setState(() {
      final rawValue = _springController.value;
      if (!_isDragging && _targetOffset == 0.0) {
        final crossedZero =
            _closingFromSign != 0.0 && (rawValue * _closingFromSign <= 0.0);
        if (rawValue.abs() < 0.5 || crossedZero) {
          _isSnappingToZero = true;
          _springController.setValue(0.0);
          _isSnappingToZero = false;
          _offset = 0.0;
          _closingFromSign = 0.0;
          _updateSettledState();
          return;
        }
      }
      _offset = rawValue;
      if (!_isDragging && (_offset - _targetOffset).abs() < 1.0) {
        _updateSettledState();
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

  double _totalStandardWidth(List<GlassSwipeAction> actions) {
    if (actions.isEmpty) return 0.0;
    if (widget.actionWidth != null) {
      return actions.length * widget.actionWidth!;
    }
    return _totalButtonsWidth(_buttonWidths(
        actions,
        _circleDiameter(_rowHeight ?? double.infinity),
        _rowWidth ?? MediaQuery.sizeOf(context).width));
  }

  /// The diameter of the button circles in a row of [availableHeight].
  double _circleDiameter(double availableHeight) =>
      widget.actionWidth ??
      (availableHeight - 8.0).clamp(24.0, widget.buttonDiameter);

  /// How far the row must be pulled to prime a full swipe: past
  /// [GlassSwipeActions.fullSwipeThreshold], or [_fullSwipeExtraDistance] past
  /// the open width of the actions when they are wider than that.
  double _fullSwipeDistance(double totalStandardWidth, double rowWidth) {
    final threshold = widget.fullSwipeThreshold * rowWidth;
    return totalStandardWidth < threshold
        ? threshold
        : totalStandardWidth + _fullSwipeExtraDistance;
  }

  double _totalButtonsWidth(List<double> widths) {
    return 2 * widget.horizontalPadding +
        widths.fold(0.0, (sum, width) => sum + width) +
        (widths.length - 1) * widget.buttonSpacing;
  }

  /// The resting width of each button: its circle, stretched into a capsule
  /// as wide as its [Text] label, within the share of the row allowed by
  /// [_maxActionsWidthFraction].
  List<double> _buttonWidths(
      List<GlassSwipeAction> actions, double circleDiameter, double rowWidth) {
    final labelStyle = _swipeActionLabelStyle(circleDiameter);
    final natural = [
      for (final action in actions)
        math.max(_labelWidth(action.label, labelStyle), circleDiameter),
    ];

    final budget = rowWidth * _maxActionsWidthFraction -
        2 * widget.horizontalPadding -
        (actions.length - 1) * widget.buttonSpacing;
    if (natural.fold(0.0, (sum, width) => sum + width) <= budget) {
      return natural;
    }

    // Cap the widest buttons to the same width, so that all of them fit the
    // budget: the narrower ones keep their natural width.
    final ascending = [...natural]..sort();
    var remaining = budget;
    var cap = circleDiameter;
    for (var i = 0; i < ascending.length; i++) {
      final share = remaining / (ascending.length - i);
      if (ascending[i] >= share) {
        cap = math.max(share, circleDiameter);
        break;
      }
      remaining -= ascending[i];
    }
    return [for (final width in natural) math.min(width, cap)];
  }

  /// The width of [label] on one line, laid out as [Text] lays it out below
  /// its button, or `0.0` when it is not a plain [Text].
  double _labelWidth(Widget? label, TextStyle labelStyle) {
    if (label is! Text || label.data == null) return 0.0;
    var style = labelStyle.merge(label.style);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final painter = TextPainter(
      text: TextSpan(text: label.data, style: style),
      textDirection: Directionality.of(context),
      textScaler: label.textScaler ?? MediaQuery.textScalerOf(context),
      maxLines: 1,
      locale: label.locale ?? Localizations.maybeLocaleOf(context),
      strutStyle: label.strutStyle,
      textWidthBasis: label.textWidthBasis ?? TextWidthBasis.parent,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  /// Programmatically opens the trailing actions.
  void openTrailing({bool animated = true}) {
    if (!mounted || widget.trailingActions.isEmpty) return;
    final totalWidth = _totalStandardWidth(widget.trailingActions);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final target = isRtl ? totalWidth : -totalWidth;
    _scope?.registerOpenRow(this);
    _animateTo(target, animated: animated);
  }

  /// Programmatically opens the leading actions.
  void openLeading({bool animated = true}) {
    if (!mounted || widget.leadingActions.isEmpty) return;
    final totalWidth = _totalStandardWidth(widget.leadingActions);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final target = isRtl ? -totalWidth : totalWidth;
    _scope?.registerOpenRow(this);
    _animateTo(target, animated: animated);
  }

  @override
  void close({bool animated = true}) {
    _closeWithVelocity(0.0, animated: animated);
  }

  void _closeWithVelocity(double velocity, {bool animated = true}) {
    if (!mounted) return;
    _scope?.unregisterRow(this);
    _animateTo(0.0, animated: animated, velocity: velocity);
  }

  /// Programmatically animates to a specific horizontal offset in logical pixels.
  void animateToOffset(double target, {bool animated = true}) {
    if (!mounted) return;
    if (target != 0.0) {
      _scope?.registerOpenRow(this);
    } else {
      _scope?.unregisterRow(this);
    }
    _animateTo(target, animated: animated);
  }

  /// Programmatically dismisses the row via full swipe and invokes [GlassSwipeActions.onDismissed].
  void dismiss({bool animated = true, bool fromLeading = false}) {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    _scope?.unregisterRow(this);
    final rowWidth = context.size?.width ?? 390.0;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dismissTarget = isRtl
        ? (fromLeading ? -rowWidth : rowWidth)
        : (fromLeading ? rowWidth : -rowWidth);

    final action = fromLeading
        ? (widget.leadingActions.isNotEmpty
            ? widget.leadingActions.first
            : null)
        : (widget.trailingActions.isNotEmpty
            ? widget.trailingActions.first
            : null);
    action?.onTap();

    final dismissCallback = widget.onDismissed;
    if (dismissCallback != null) {
      final reduceMotion = GlassAccessibilityData.of(context).reduceMotion ||
          (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
      if (!animated || reduceMotion) {
        _dismissController.value = 1.0;
        dismissCallback();
      } else {
        _animateTo(dismissTarget);
        _dismissController.forward().then((_) {
          if (mounted) {
            dismissCallback();
          }
        });
      }
    } else {
      _isDismissing = false;
      close(animated: animated);
    }
  }

  void _animateTo(double target,
      {bool animated = true, double velocity = 0.0}) {
    if (!mounted) return;
    _targetOffset = target;
    _closingFromSign = target == 0.0 ? _offset.sign : 0.0;
    final reduceMotion = GlassAccessibilityData.of(context).reduceMotion ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    if (!animated || reduceMotion || (_offset - target).abs() < 0.5) {
      _closingFromSign = 0.0;
      _isSnappingToZero = true;
      _springController.setValue(target);
      _isSnappingToZero = false;
      if (mounted) {
        setState(() {
          _offset = target;
          _updateSettledState();
        });
      }
    } else {
      _springController.spring = target == 0.0
          ? GlassSpring.smooth(duration: const Duration(milliseconds: 300))
          : GlassSpring.snappy();
      _isSnappingToZero = true;
      _springController.setValue(_offset);
      _isSnappingToZero = false;
      _springController.animateTo(target, fromVelocity: velocity);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (!mounted) return;
    _isDragging = true;
    _hasFiredHaptic = false;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final startDirectionalOffset = isRtl ? -_offset : _offset;
    if (startDirectionalOffset > 1.0) {
      _dragStartSide = 1;
    } else if (startDirectionalOffset < -1.0) {
      _dragStartSide = -1;
    } else {
      _dragStartSide = 0;
    }
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

    // If the gesture started while one side was already open, prevent a
    // single closing swipe from crossing zero into the opposite side's actions.
    if (_dragStartSide == 1 && directionalOffset < 0) {
      newOffset = 0.0;
      directionalOffset = 0.0;
    } else if (_dragStartSide == -1 && directionalOffset > 0) {
      newOffset = 0.0;
      directionalOffset = 0.0;
    }

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
        final maxLeading = _totalStandardWidth(widget.leadingActions);
        if (directionalOffset > maxLeading) {
          final excess = directionalOffset - maxLeading;
          directionalOffset = maxLeading + excess * 0.25;
          newOffset = isRtl ? -directionalOffset : directionalOffset;
        }
      } else if (directionalOffset < 0) {
        final maxTrailing = _totalStandardWidth(widget.trailingActions);
        if (directionalOffset.abs() > maxTrailing) {
          final excess = directionalOffset.abs() - maxTrailing;
          directionalOffset = -(maxTrailing + excess * 0.25);
          newOffset = isRtl ? -directionalOffset : directionalOffset;
        }
      }
    }

    final revealDistance = directionalOffset.abs();
    final thresholdDistance = _fullSwipeDistance(
        _totalStandardWidth(directionalOffset > 0
            ? widget.leadingActions
            : widget.trailingActions),
        rowWidth);

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
    final thresholdDistance = _fullSwipeDistance(
        _totalStandardWidth(directionalOffset > 0
            ? widget.leadingActions
            : widget.trailingActions),
        rowWidth);

    if (widget.allowsFullSwipe && revealDistance >= thresholdDistance) {
      if (_isDismissing) return;
      _isDismissing = true;
      final isLeading = directionalOffset > 0;
      // In both leading and trailing, actions.first is the outermost action at the edge
      final action = isLeading
          ? widget.leadingActions.first
          : widget.trailingActions.first;

      action.onTap();

      final dismissCallback = widget.onDismissed;
      final hasAnyDestructive =
          widget.leadingActions.any((a) => a.isDestructive) ||
              widget.trailingActions.any((a) => a.isDestructive);
      final shouldDismiss = dismissCallback != null &&
          (action.isDestructive || !hasAnyDestructive);
      if (shouldDismiss) {
        _scope?.unregisterRow(this);
        final dismissTarget = isRtl
            ? (isLeading ? -rowWidth : rowWidth)
            : (isLeading ? rowWidth : -rowWidth);
        _animateTo(dismissTarget, velocity: velocity);
        final reduceMotion = GlassAccessibilityData.of(context).reduceMotion ||
            (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
        if (reduceMotion) {
          _dismissController.value = 1.0;
          dismissCallback();
        } else {
          _dismissController.forward().then((_) {
            if (mounted) {
              dismissCallback();
            }
          });
        }
      } else {
        _isDismissing = false;
        close();
      }
      return;
    }

    // Determine resting settle target
    if (directionalOffset > 0 && widget.leadingActions.isNotEmpty) {
      final totalLeading = _totalStandardWidth(widget.leadingActions);
      final isClosingFlick = directionalVelocity < -250;
      final shouldOpen = !isClosingFlick &&
          (_dragStartSide == 1
              ? revealDistance > totalLeading * 0.7
              : (revealDistance > totalLeading * 0.4 ||
                  directionalVelocity > 300));
      if (shouldOpen) {
        final target = isRtl ? -totalLeading : totalLeading;
        _animateTo(target, velocity: velocity);
        _setSwipeState(GlassSwipeState.openLeading);
      } else {
        _closeWithVelocity(velocity);
      }
    } else if (directionalOffset < 0 && widget.trailingActions.isNotEmpty) {
      final totalTrailing = _totalStandardWidth(widget.trailingActions);
      final isClosingFlick = directionalVelocity > 250;
      final shouldOpen = !isClosingFlick &&
          (_dragStartSide == -1
              ? revealDistance > totalTrailing * 0.7
              : (revealDistance > totalTrailing * 0.4 ||
                  directionalVelocity < -300));
      if (shouldOpen) {
        final target = isRtl ? totalTrailing : -totalTrailing;
        _animateTo(target, velocity: velocity);
        _setSwipeState(GlassSwipeState.openTrailing);
      } else {
        _closeWithVelocity(velocity);
      }
    } else {
      _closeWithVelocity(velocity);
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
        _rowWidth = rowWidth;

        final isLeading = directionalOffset > 0;
        final isTrailing = directionalOffset < 0;
        final revealWidth = directionalOffset.abs();

        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 70.0;
        _rowHeight = availableHeight;
        final isVisuallyOpen = _offset.abs() >= 0.5;
        final greyProgress = (_offset.abs() / 24.0).clamp(0.0, 1.0);
        final inSolidSurface = InheritedGlassSurfaceStyle.maybeOf(context) ==
            GlassSurfaceStyle.solid;
        final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
        final pageColor =
            isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
        final swipedHighlightColor =
            isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
        final Color swipedRowColor = inSolidSurface
            ? Color.lerp(
                resolveGlassSolidSurfaceColor(context),
                swipedHighlightColor,
                greyProgress,
              )!
            : swipedHighlightColor.withValues(alpha: 0.35 * greyProgress);

        Widget body = Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Base background behind swiped row slot in solid cards: prevents
            // solid card background from bleeding into the sliding child's
            // rounded corners while keeping the sliding row itself opaque.
            if (isVisuallyOpen && inSolidSurface)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: pageColor,
                  ),
                ),
              ),

            // Background Action Platter (Revealed underneath)
            if (isLeading && widget.leadingActions.isNotEmpty)
              Positioned.directional(
                textDirection: direction,
                start: 0,
                top: 0,
                bottom: 0,
                width: revealWidth,
                child: _buildLeadingPlatter(context, revealWidth, rowWidth,
                    availableHeight, inSolidSurface, pageColor),
              )
            else if (isTrailing && widget.trailingActions.isNotEmpty)
              Positioned.directional(
                textDirection: direction,
                end: 0,
                top: 0,
                bottom: 0,
                width: revealWidth,
                child: _buildTrailingPlatter(context, revealWidth, rowWidth,
                    availableHeight, inSolidSurface, pageColor),
              ),

            // Sliding Primary Child
            Transform.translate(
              offset: Offset(_offset, 0.0),
              child: ClipRRect(
                borderRadius: isVisuallyOpen
                    ? BorderRadiusDirectional.horizontal(
                        start: isLeading
                            ? Radius.circular(16.0 * greyProgress)
                            : Radius.zero,
                        end: isTrailing
                            ? Radius.circular(16.0 * greyProgress)
                            : Radius.zero,
                      ).resolve(direction)
                    : BorderRadius.zero,
                child: Stack(
                  children: [
                    if (isVisuallyOpen)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: swipedRowColor,
                          ),
                        ),
                      ),
                    widget.child,
                  ],
                ),
              ),
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
                curve: Curves.easeInOutCubic,
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
    BuildContext context,
    double revealWidth,
    double rowWidth,
    double availableHeight,
    bool inSolidSurface,
    Color pageColor,
  ) {
    final actions = widget.leadingActions;
    final circleDiameter = _circleDiameter(availableHeight);
    final spacing = widget.buttonSpacing;
    final padding = widget.horizontalPadding;
    final widths = widget.actionWidth != null
        ? [for (final _ in actions) circleDiameter]
        : _buttonWidths(actions, circleDiameter, rowWidth);

    final totalStandardWidth = widget.actionWidth != null
        ? _totalStandardWidth(actions)
        : _totalButtonsWidth(widths);
    final excess =
        (revealWidth - totalStandardWidth).clamp(0.0, double.infinity);
    final isFullSwipe = widget.allowsFullSwipe &&
        revealWidth >= _fullSwipeDistance(totalStandardWidth, rowWidth);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: inSolidSurface ? pageColor : const Color(0x00000000),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => close(),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            () {
              final isOutermost = i == 0;
              final double buttonWidth;
              final double startOffset;
              if (isOutermost) {
                buttonWidth = widths[0] + excess;
                startOffset = padding;
              } else {
                buttonWidth = widths[i];
                startOffset = padding +
                    excess +
                    widths.take(i).fold(0.0, (sum, w) => sum + w + spacing);
              }

              final revealProgress = _computeActionRevealProgress(
                  i, totalStandardWidth, revealWidth, widths, spacing);

              return Positioned.directional(
                textDirection: Directionality.of(context),
                start: startOffset,
                top: 0,
                bottom: 0,
                width: buttonWidth,
                child: _GlassSwipeActionButton(
                  action: actions[i],
                  circleDiameter: circleDiameter,
                  restingWidth: widths[i],
                  width: buttonWidth,
                  isOutermost: isOutermost,
                  isFullSwipe: isFullSwipe && isOutermost,
                  isTrailing: false,
                  style: widget.style,
                  revealProgress: revealProgress,
                  onPressed: () {
                    actions[i].onTap();
                    if (actions[i].closeOnTap && !_isDismissing) {
                      close();
                    }
                  },
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildTrailingPlatter(
    BuildContext context,
    double revealWidth,
    double rowWidth,
    double availableHeight,
    bool inSolidSurface,
    Color pageColor,
  ) {
    final actions = widget.trailingActions;
    final circleDiameter = _circleDiameter(availableHeight);
    final spacing = widget.buttonSpacing;
    final padding = widget.horizontalPadding;
    final widths = widget.actionWidth != null
        ? [for (final _ in actions) circleDiameter]
        : _buttonWidths(actions, circleDiameter, rowWidth);

    final totalStandardWidth = widget.actionWidth != null
        ? _totalStandardWidth(actions)
        : _totalButtonsWidth(widths);
    final excess =
        (revealWidth - totalStandardWidth).clamp(0.0, double.infinity);
    final isFullSwipe = widget.allowsFullSwipe &&
        revealWidth >= _fullSwipeDistance(totalStandardWidth, rowWidth);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: inSolidSurface ? pageColor : const Color(0x00000000),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => close(),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            () {
              final isOutermost = i == 0;
              final double buttonWidth;
              final double endOffset;
              if (isOutermost) {
                buttonWidth = widths[0] + excess;
                endOffset = padding;
              } else {
                buttonWidth = widths[i];
                endOffset = padding +
                    excess +
                    widths.take(i).fold(0.0, (sum, w) => sum + w + spacing);
              }

              final revealProgress = _computeActionRevealProgress(
                  i, totalStandardWidth, revealWidth, widths, spacing);

              return Positioned.directional(
                textDirection: Directionality.of(context),
                end: endOffset,
                top: 0,
                bottom: 0,
                width: buttonWidth,
                child: _GlassSwipeActionButton(
                  action: actions[i],
                  circleDiameter: circleDiameter,
                  restingWidth: widths[i],
                  width: buttonWidth,
                  isOutermost: isOutermost,
                  isFullSwipe: isFullSwipe && isOutermost,
                  isTrailing: true,
                  style: widget.style,
                  revealProgress: revealProgress,
                  onPressed: () {
                    actions[i].onTap();
                    if (actions[i].closeOnTap && !_isDismissing) {
                      close();
                    }
                  },
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }

  double _computeActionRevealProgress(int index, double totalStandardWidth,
      double revealWidth, List<double> widths, double spacing) {
    if (revealWidth <= 0.0) return 0.0;
    if (revealWidth >= totalStandardWidth) return 1.0;

    // Slower, progressive reveal: outermost button (index 0) starts early,
    // subsequent buttons reveal sequentially as row is pulled open.
    final before = widths.take(index).fold(0.0, (sum, w) => sum + w + spacing);
    final start = 6.0 + before * 0.7;
    final end = (start + (widths[index] + spacing) * 0.9)
        .clamp(start + 1.0, totalStandardWidth);
    if (revealWidth <= start) return 0.0;
    return ((revealWidth - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class _GlassSwipeActionButton extends StatefulWidget {
  const _GlassSwipeActionButton({
    required this.action,
    required this.circleDiameter,
    required this.onPressed,
    this.restingWidth,
    this.width,
    this.isOutermost = false,
    this.isFullSwipe = false,
    this.isTrailing = true,
    this.style = GlassSwipeActionStyle.tintedGlass,
    this.revealProgress = 1.0,
  });

  final GlassSwipeAction action;
  final double circleDiameter;

  /// The width of the button when its row rests open: [circleDiameter], or
  /// wider to fit its label.
  final double? restingWidth;
  final double? width;
  final VoidCallback onPressed;
  final bool isOutermost;
  final bool isFullSwipe;
  final bool isTrailing;
  final GlassSwipeActionStyle style;
  final double revealProgress;

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

    final double circleDiameter = widget.circleDiameter;
    final double buttonHeight = circleDiameter;
    final double buttonWidth = widget.width ?? circleDiameter;
    final double restingWidth = widget.restingWidth ?? circleDiameter;
    final borderRadius = BorderRadius.circular(buttonHeight / 2);

    final Color tint;
    final BoxDecoration sheen;
    if (widget.style == GlassSwipeActionStyle.tintedGlass) {
      tint = _isPressed
          ? effectiveBgColor.withValues(alpha: 0.76)
          : effectiveBgColor.withValues(alpha: 0.90);
      sheen = BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.25),
          width: 0.75,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CupertinoColors.white.withValues(alpha: 0.20),
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
      sheen = BoxDecoration(borderRadius: borderRadius);
    }

    // Grow (scale) and fade-in (opacity) driven by revealProgress
    // Slower, smooth reveal growth: gentle progressive scaling so the user sees it grow in gradually
    final double progress = widget.revealProgress;
    if (progress <= 0.001) {
      return const SizedBox.shrink();
    }

    final double baseScale = progress.clamp(0.0, 1.0);
    final double fullSwipeScale = widget.isFullSwipe ? 1.08 : 1.0;
    final double pressScale = _isPressed ? 0.92 : 1.0;
    final double effectiveScale = baseScale * fullSwipeScale * pressScale;
    final double effectiveOpacity = (progress * 1.05).clamp(0.0, 1.0);

    final iconSize = (circleDiameter * 0.40).clamp(16.0, 22.0);

    // In native iOS, as the outermost action stretches into a capsule and primes
    // full swipe, its text label fades away and the icon flicks toward the inner
    // edge (leading for trailing swipe, trailing for leading swipe).
    final bool hideLabel = widget.isFullSwipe ||
        (widget.isOutermost && buttonWidth > restingWidth + 8.0);
    final double labelOpacity = hideLabel ? 0.0 : effectiveOpacity;

    final targetAlignment = (widget.isFullSwipe && widget.isOutermost)
        ? (widget.isTrailing
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd)
        : AlignmentDirectional.center;

    return SizedBox(
      width: buttonWidth,
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
          child: Center(
            child: Transform.scale(
              scale: effectiveScale,
              child: Opacity(
                opacity: effectiveOpacity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: borderRadius,
                          ),
                          child: DecoratedBox(
                            decoration: sheen,
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              alignment: targetAlignment,
                              child: SizedBox(
                                width: circleDiameter,
                                height: buttonHeight,
                                child: Center(
                                  child: IconTheme(
                                    data: IconThemeData(
                                      color: effectiveFgColor,
                                      size: iconSize,
                                    ),
                                    child: widget.action.icon,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.action.label != null) ...[
                        const SizedBox(height: 3.0),
                        // Laid out at the resting button width, so that the
                        // FittedBox never scales the button down for a label
                        // truncated to fit [_maxActionsWidthFraction].
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          opacity: labelOpacity,
                          child: SizedBox(
                            width: restingWidth,
                            child: DefaultTextStyle(
                              style: _swipeActionLabelStyle(circleDiameter)
                                  .copyWith(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: widget.action.label!,
                            ),
                          ),
                        ),
                      ],
                    ],
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

/// Maximum fraction of the row width taken by the open actions, including
/// their padding and spacing, when [GlassSwipeActions.actionWidth] is not set.
///
/// When the labels do not all fit, the longest ones are truncated with an
/// ellipsis, to the same width.
const double _maxActionsWidthFraction = 0.75;

/// How far past the open width of actions wider than
/// [GlassSwipeActions.fullSwipeThreshold] the row must be pulled to prime a
/// full swipe.
const double _fullSwipeExtraDistance = 25.0;

/// The text style of a swipe action label below a button of [circleDiameter].
TextStyle _swipeActionLabelStyle(double circleDiameter) => TextStyle(
      fontSize: (circleDiameter * 0.22).clamp(10.0, 12.0),
      fontWeight: FontWeight.normal,
      letterSpacing: -0.2,
    );
