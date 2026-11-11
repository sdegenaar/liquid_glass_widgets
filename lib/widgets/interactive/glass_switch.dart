import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../constants/glass_defaults.dart';
import '../../src/widgets/shared/lens_inner_shadow_painter.dart';
import '../../theme/glass_theme.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_style.dart';
import '../shared/glass_effect.dart';
import '../shared/glass_focus_region.dart';
import '../shared/glass_accessibility_scope.dart';
import '../../theme/glass_theme_helpers.dart';

// The On/Off Labels marks, measured on a 63x28 UISwitch (iOS 27.2
// simulator, 3x screenshots, from the track's top-left corner): a 1x10 `I`
// centered at x 14.5 and an `O` ring of 10pt outer diameter and a 1pt
// stroke centered 15pt in from the other end, both centered vertically.
// GlassSwitch's thumb is a pill of (height - 4) * (37 / 24) inset by 2, so
// the gap beside the resting thumb is (width - 2 - thumbWidth): 24.0pt at
// 63x28, centered 12.0pt in from the end. The `I` sits 2.5pt and the `O`
// 3.0pt past that center, toward the thumb, which lands them on UIKit's at
// 63x28. They keep that place in the gap at other sizes and scale with
// height / 28; the strokes stay 1pt wide.
const double _kUISwitchTrackHeight = 28.0;
const double _kOnLabelPastGapCenter = 2.5;
const double _kOffLabelPastGapCenter = 3.0;
const double _kOnLabelWidth = 1.0;
const double _kOnLabelHeight = 10.0;
const double _kOffLabelStrokeWidth = 1.0;
// The radius to the middle of the stroke: 10pt outer, 8pt inner diameter.
const double _kOffLabelRadius = 4.5;
// CupertinoSwitch's off label color (cupertino/switch.dart): the light grey
// ring a UISwitch draws, rgb(179,179,179) on its rgb(197,197,197) track.
const CupertinoDynamicColor _kOffLabelColor =
    CupertinoDynamicColor.withBrightnessAndContrast(
  color: Color.fromARGB(255, 179, 179, 179),
  darkColor: Color.fromARGB(255, 179, 179, 179),
  highContrastColor: Color.fromARGB(255, 255, 255, 255),
  darkHighContrastColor: Color.fromARGB(255, 255, 255, 255),
);

/// A glass toggle switch with Apple's signature jump animation.
///
/// [GlassSwitch] provides a toggle switch with glass morphism effect and
/// smooth spring-based animations, matching iOS toggle behavior with a
/// satisfying "jump" when switching states.
///
/// ## Usage Modes
///
/// ### Grouped Mode (default)
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: Column(
///     children: [
///       GlassSwitch(
///         value: isEnabled,
///         onChanged: (value) => setState(() => isEnabled = value),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassSwitch(
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(...),
///   value: darkMode,
///   onChanged: (value) => toggleDarkMode(value),
/// )
/// ```
///
/// ## Customization Examples
///
/// ### Custom colors:
/// ```dart
/// GlassSwitch(
///   value: isOn,
///   onChanged: (value) {},
///   activeColor: Colors.green,
///   inactiveColor: Colors.grey,
/// )
/// ```
///
/// ### Custom size:
/// ```dart
/// GlassSwitch(
///   value: isOn,
///   onChanged: (value) {},
///   width: 60,
///   height: 32,
/// )
/// ```
class GlassSwitch extends StatefulWidget {
  /// Creates a glass switch.
  const GlassSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor = CupertinoColors.white,
    this.thumbShadow,
    this.width = 58.0,
    this.height = 26.0,
    this.settings,
    this.useOwnLayer = false,
    this.quality,
    this.enableHaptics = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.onLabelColor,
    this.offLabelColor,
  });

  // ===========================================================================
  // Switch Properties
  // ===========================================================================

  /// Whether the switch is on or off.
  final bool value;

  /// Called when the user toggles the switch.
  final ValueChanged<bool> onChanged;

  /// The color of the track when the switch is on.
  ///
  /// If null, defaults to system green (`CupertinoColors.systemGreen`).
  final Color? activeColor;

  /// The color of the track when the switch is off.
  ///
  /// If null, defaults to a semi-transparent white.
  final Color? inactiveColor;

  /// The color of the thumb (circular knob).
  ///
  /// Defaults to white.
  final Color thumbColor;

  /// Shadows cast by the resting thumb, painted outside the glass clip.
  ///
  /// When null, uses a soft black shadow at 15% opacity with an 8 logical-pixel
  /// blur and a 2 logical-pixel downward offset (matching [GlassSlider]). An
  /// empty list disables it. Each shadow's color alpha is multiplied by the
  /// interaction/material fade so the shadow dissolves as the thumb lifts into
  /// a liquid glass lens.
  final List<BoxShadow>? thumbShadow;

  // ===========================================================================
  // Sizing Properties
  // ===========================================================================

  /// Width of the switch.
  ///
  /// Defaults to 58.0.
  final double width;

  /// Height of the switch.
  ///
  /// Defaults to 26.0.
  final double height;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings (only used when [useOwnLayer] is true).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass.
  final bool useOwnLayer;

  /// Rendering quality for the lifted liquid lens during press and drag.
  ///
  /// Defaults to [GlassQuality.premium] on [GlassStyle.ios27] / [GlassStyle.ios26]
  /// ([GlassStyle.classic] keeps [GlassQuality.standard]), which renders the
  /// calibrated 3D paraxial liquid lens when the thumb is pressed or dragged and
  /// mounts zero shader layers at rest. Falls back to [GlassQuality.standard]
  /// automatically on Skia/Web or when capped by [GlassAdaptiveScope].
  final GlassQuality? quality;

  /// Whether to emit haptic feedback on toggle.
  ///
  /// When `true` (the default), a [HapticFeedback.lightImpact] fires:
  /// - immediately when the switch is tapped,
  /// - when the thumb crosses the 50 % midpoint during a drag, and
  /// - on drag release if the thumb snaps to a new state and the midpoint
  ///   was never crossed (e.g. a fast flick).
  ///
  /// Set to `false` to suppress all haptics — useful when the parent widget
  /// already manages its own haptic layer.
  final bool enableHaptics;

  /// Externally provided focus node.
  final FocusNode? focusNode;

  /// Whether to request focus immediately.
  final bool autofocus;

  /// The semantic label for screen readers.
  final String? semanticLabel;

  /// The color of the on mark (the `I`) drawn on the track when the user
  /// turned on iOS's On/Off Labels setting
  /// ([MediaQueryData.onOffSwitchLabels]).
  ///
  /// Defaults to white, like [CupertinoSwitch.onLabelColor]. A
  /// [CupertinoDynamicColor] is resolved against the context.
  final Color? onLabelColor;

  /// The color of the off mark (the `O`) drawn on the track when the user
  /// turned on iOS's On/Off Labels setting
  /// ([MediaQueryData.onOffSwitchLabels]).
  ///
  /// Defaults to [CupertinoSwitch]'s off label grey, which turns white under
  /// Increase Contrast. A [CupertinoDynamicColor] is resolved against the
  /// context.
  final Color? offLabelColor;

  @override
  State<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<GlassSwitch>
    with TickerProviderStateMixin {
  static const _defaultThumbShadow = [
    BoxShadow(
      color: Color.from(alpha: 0.15, red: 0, green: 0, blue: 0),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  late AnimationController _positionController;
  late AnimationController _thicknessController;
  late AnimationController _overshootController;
  late Animation<double> _thicknessAnimation;

  // ---------------------------------------------------------------------------
  // Gesture state
  // ---------------------------------------------------------------------------
  bool _isDragging = false;
  bool _isPressed = false;
  bool _dragAbandonedExternally = false;
  bool _justEndedDrag = false;
  double _dragVirtualPx = 0.0;
  double _dragTotalDistancePx = 0.0;
  double _dragOvershootPx = 0.0;
  double _releaseOvershootStartPx = 0.0;

  // ---------------------------------------------------------------------------
  // Haptic state
  // ---------------------------------------------------------------------------
  // Tracks whether the thumb crossed the 50% midpoint during the current drag.
  // Prevents a double-fire on drag release when the midpoint was already felt.
  bool _dragMidpointHapticFired = false;
  // The side of the midpoint the thumb was on at the last _onDragUpdate call.
  // Used to detect a crossing without comparing raw floats.
  bool _dragWasAboveMidpoint = false;

  final ValueNotifier<bool> _isHovered = ValueNotifier(false);
  final ValueNotifier<bool> _isFocused = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    // Unified tempo: Position jump and Liquid bloom now move together
    _positionController = AnimationController(
        duration: const Duration(milliseconds: 380), vsync: this);
    _thicknessController = AnimationController(
        duration: const Duration(milliseconds: 380), vsync: this);
    _overshootController = AnimationController(
        duration: const Duration(milliseconds: 220), vsync: this);

    // Pulse animation (0 -> 1 -> 0)
    // Synchronized to grow and settle as the toggle jumps
    _thicknessAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 45, // Grow up as it gains speed
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 55, // Settle down as it lands
      ),
    ]).animate(_thicknessController);

    // Set initial state
    if (widget.value) {
      _positionController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GlassSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // If the user is mid-drag, an external value change wins — abandon the
      // drag cleanly so the animation takes over without a visual jump.
      if (_isDragging) {
        _isDragging = false;
        _dragAbandonedExternally = true;
        _settleOvershoot();
      }

      // Consume the drag-end flag before animating position so drag releases
      // keep their responsive ease-out settle curve instead of being
      // overwritten by the 380ms tap jump curve.
      final bool justEndedDrag = _justEndedDrag;
      _justEndedDrag = false;

      // Animate position
      _animatePositionTo(
        widget.value ? 1.0 : 0.0,
        fromDrag: justEndedDrag,
      );

      // Trigger the liquid pulse bloom (Grow up and then down)
      _isPressed = false;
      if (!justEndedDrag) {
        if (_thicknessController.value >= 0.99) {
          _thicknessController.value = 0.0;
        }

        final double posDist = widget.value
            ? (1.0 - _positionController.value)
            : _positionController.value;

        if (_thicknessController.value >= 0.45) {
          // User held the switch until full bloom before releasing: smoothly
          // deflate across the remaining horizontal travel.
          final int ms = (280 * posDist).round().clamp(140, 280);
          unawaited(_thicknessController.animateTo(
            1.0,
            duration: Duration(milliseconds: ms),
            curve: Curves.linear,
          ));
        } else {
          // Quick tap or programmatic toggle: advance linearly through the
          // TweenSequence so the pill reaches peak bloom mid-flight (~45% of
          // travel) and smoothly settles as it lands on the destination side.
          final int ms = (320 * posDist).round().clamp(180, 320);
          unawaited(_thicknessController.animateTo(
            1.0,
            duration: Duration(milliseconds: ms),
            curve: Curves.linear,
          ));
        }
      }
    } else if (!_isDragging) {
      final target = widget.value ? 1.0 : 0.0;
      if (_positionController.value != target) {
        _animatePositionTo(target);
      }
      if (!_isPressed &&
          _thicknessController.value > 0.0 &&
          !_thicknessController.isAnimating) {
        unawaited(
            _thicknessController.forward(from: _thicknessController.value));
      }
    }
  }

  void _animatePositionTo(double target, {bool fromDrag = false}) {
    final distance = (target - _positionController.value).abs();
    if (distance <= 0.001) {
      _positionController.value = target;
      return;
    }
    final durationMs = fromDrag
        ? (240 * distance).round().clamp(120, 240)
        : (300 * distance).round().clamp(180, 300);
    unawaited(_positionController.animateTo(
      target,
      duration: Duration(milliseconds: durationMs),
      curve: fromDrag ? Curves.easeOutCubic : Curves.ease,
    ));
  }

  double get _currentOvershootPx {
    if (_isDragging) return _dragOvershootPx;
    if (_overshootController.isAnimating) {
      final t = Curves.easeOutCubic.transform(_overshootController.value);
      return _releaseOvershootStartPx * (1.0 - t);
    }
    return 0.0;
  }

  void _settleOvershoot() {
    if (_dragOvershootPx.abs() <= 0.01) {
      _dragOvershootPx = 0.0;
      _releaseOvershootStartPx = 0.0;
      _overshootController.value = 0.0;
      return;
    }
    _releaseOvershootStartPx = _dragOvershootPx;
    _dragOvershootPx = 0.0;
    unawaited(_overshootController.forward(from: 0.0));
  }

  void _activateFromKeyboard() {
    if (!mounted) return;

    // Toggle the value
    final newValue = !widget.value;

    // Check reduce motion
    final reduceMotion = GlassAccessibilityData.of(context).reduceMotion;

    widget.onChanged(newValue);
    if (widget.enableHaptics && !reduceMotion) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _thicknessController.dispose();
    _overshootController.dispose();
    _isHovered.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onChanged(!widget.value);
  }

  /// Whether the switch is mirrored: in a right-to-left context the thumb
  /// rests on the left when on, as with UISwitch and [CupertinoSwitch].
  bool get _isRtl => Directionality.maybeOf(context) == TextDirection.rtl;

  // ---------------------------------------------------------------------------
  // Drag-to-toggle handlers
  // ---------------------------------------------------------------------------

  /// Resting knob width ratio matching native iOS 26 & 27 `UISwitchModernVisualElement`
  /// (`37.0 × 24.0 pt` knob inside `63.0 × 28.0 pt` track).
  static const double _kNativeKnobAspect = 37.0 / 24.0;

  /// Lifted liquid lens horizontal expansion ratio (`+21.0 pt` across both sides
  /// at `24.0 pt` knob height -> `58.0 pt` lifted lens width).
  static const double _kNativeLiftedWidthExpandRatio = 21.0 / 24.0;

  /// Lifted liquid lens vertical expansion ratio per side (`+7.1667 pt` top & bottom
  /// at `24.0 pt` knob height -> `38.33 pt` lifted lens height).
  static const double _kNativeLiftedVerticalExpandRatio = 7.1667 / 24.0;

  /// Pixel travel distance from the left edge to right edge of the thumb runway.
  double get _thumbTravelDistance {
    final thumbSize = widget.height - 4.0;
    final thumbWidth = thumbSize * _kNativeKnobAspect;
    return widget.width - thumbWidth - 4.0;
  }

  // ---------------------------------------------------------------------------
  // Gesture handlers
  // ---------------------------------------------------------------------------

  void _startPressBloom() {
    if (_isPressed) return;
    _isPressed = true;
    if (_thicknessController.value >= 0.99) {
      _thicknessController.value = 0.0;
    }
    _dragAbandonedExternally = false;
    _justEndedDrag = false;
    unawaited(_thicknessController.animateTo(
      0.45,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    ));
  }

  void _onDragDown(DragDownDetails details) {
    // Fires on frame 0 (without waiting for kPressTimeout) so the thumb blooms
    // the instant the finger touches the switch.
    _startPressBloom();
  }

  void _onTapDown(TapDownDetails details) {
    _startPressBloom();
  }

  void _onTapUp(TapUpDetails details) {
    _isPressed = false;
    // A tap is confirmed only when no horizontal drag was registered.
    if (!_isDragging) {
      // Fire haptic immediately — user feels the click the instant they lift.
      if (widget.enableHaptics) unawaited(HapticFeedback.lightImpact());
      unawaited(_thicknessController.forward(from: _thicknessController.value));
      _handleTap();
    }
  }

  void _onTapCancel() {
    _isPressed = false;
    // Do not deflate here if the finger is transitioning into a horizontal drag;
    // _onDragCancel or _onDragEnd will handle deflation when the pointer lifts.
  }

  void _onDragStart(DragStartDetails details) {
    _isPressed = false;
    // Flutter has confirmed horizontal movement — commit to drag mode.
    _positionController.stop();
    final currentOvershoot = _currentOvershootPx;
    _overshootController.stop();
    _dragOvershootPx = currentOvershoot;
    _dragVirtualPx =
        (_positionController.value * _thumbTravelDistance) + _dragOvershootPx;
    _dragTotalDistancePx = 0.0;
    _dragAbandonedExternally = false;
    setState(() => _isDragging = true);

    // Stop any deflation that might have started
    _thicknessController.stop();

    // Ensure bloom is at peak.
    if (_thicknessController.value >= 0.99) {
      _thicknessController.value = 0.0;
    }

    // If we're not at perfect plump (e.g., still inflating), animate to 0.45
    if ((_thicknessController.value - 0.45).abs() > 0.01) {
      unawaited(_thicknessController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 80),
      ));
    } else {
      _thicknessController.value = 0.45;
    }

    // Reset midpoint-haptic tracking for this new drag.
    _dragMidpointHapticFired = false;
    _dragWasAboveMidpoint = _positionController.value >= 0.5;
  }

  void _onDragCancel() {
    _isPressed = false;
    setState(() => _isDragging = false);
    _settleOvershoot();
    // Deflate bloom smoothly.
    unawaited(_thicknessController.forward(from: _thicknessController.value));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    // Apply incremental frame delta linearly (1:1 finger tracking across the
    // runway, plus native ±12 pt asymptotic rubber-band overhang past 0.0 and 1.0).
    final travel = _thumbTravelDistance;
    final rawDelta = details.primaryDelta ?? 0.0;
    final delta = _isRtl ? -rawDelta : rawDelta;
    _dragTotalDistancePx += delta.abs();
    _dragVirtualPx = (_dragVirtualPx + delta).clamp(-36.0, travel + 36.0);

    if (_dragVirtualPx < 0.0) {
      _positionController.value = 0.0;
      _dragOvershootPx = _dragVirtualPx;
    } else if (_dragVirtualPx > travel) {
      _positionController.value = 1.0;
      _dragOvershootPx = _dragVirtualPx - travel;
    } else {
      _positionController.value = _dragVirtualPx / travel;
      _dragOvershootPx = 0.0;
    }

    // Detect midpoint crossing and fire a single haptic tick.
    // iOS fires at the 50 % mark regardless of drag direction.
    if (widget.enableHaptics && !_dragMidpointHapticFired) {
      final nowAbove = _positionController.value >= 0.5;
      if (nowAbove != _dragWasAboveMidpoint) {
        unawaited(HapticFeedback.lightImpact());
        _dragMidpointHapticFired = true;
      }
      _dragWasAboveMidpoint = nowAbove;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isPressed = false;
    // No-op if an external value change has already taken ownership.
    if (_dragAbandonedExternally) {
      _dragAbandonedExternally = false;
      return;
    }
    if (!_isDragging) return;
    final position = _positionController.value;
    final velocity = details.primaryVelocity ?? 0.0;

    // If the pointer barely moved after clearing the 3 px touchSlop (e.g. a tap
    // with minor finger micro-movement), treat it as a tap toggle so taps never
    // get swallowed by HorizontalDragGestureRecognizer.
    if (_dragTotalDistancePx < 5.0 && velocity.abs() <= 200.0) {
      setState(() => _isDragging = false);
      _justEndedDrag = false;
      _settleOvershoot();
      if (widget.enableHaptics) unawaited(HapticFeedback.lightImpact());
      unawaited(_thicknessController.forward(from: _thicknessController.value));
      _handleTap();
      _dragMidpointHapticFired = false;
      return;
    }

    // A fast flick (> 200 px/s) wins over position; otherwise snap at 50 %.
    final bool shouldBeOn = velocity.abs() > 200.0
        ? (_isRtl ? velocity < 0 : velocity > 0)
        : position >= 0.5;

    setState(() => _isDragging = false);
    final bool valueChanging = shouldBeOn != widget.value;
    // Only set _justEndedDrag when widget.onChanged will actually fire and
    // trigger didUpdateWidget; otherwise a drag that snaps back to the starting
    // side would leave _justEndedDrag stuck at true and suppress the liquid
    // bloom on the next tap!
    _justEndedDrag = valueChanging;
    _settleOvershoot();

    // Smoothly settle thumb toward the target state from the exact release point.
    _animatePositionTo(shouldBeOn ? 1.0 : 0.0, fromDrag: true);

    // Notify parent only when the value actually changed.
    if (valueChanging) {
      widget.onChanged(shouldBeOn);
    }

    // Continue the settle bloom down to 0 so the landing feels weighty.
    unawaited(_thicknessController.forward(from: _thicknessController.value));

    // Haptic on snap — only if the state is changing AND the midpoint
    // crossing haptic didn't already fire (avoids a double-tap feel on
    // slow deliberate drags that naturally crossed the midpoint).
    if (widget.enableHaptics && !_dragMidpointHapticFired && valueChanging) {
      unawaited(HapticFeedback.lightImpact());
    }
    _dragMidpointHapticFired = false;
  }

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer or theme if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );

    final thumbSize = widget.height - 4.0;
    final thumbWidth = thumbSize * _kNativeKnobAspect;
    final trackWidth = widget.width;

    // Performance: Cache color calculations as const to avoid allocation
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    // Matches native UISwitchModernVisualElement off-track fill on iOS 26 & 27:
    // rgba(60, 60, 67, 0.30) in light mode, rgba(235, 235, 245, 0.30) in dark mode.
    final inactiveTrackColor = widget.inactiveColor ??
        (isDark ? const Color(0x4DEBEBF5) : const Color(0x4D3C3C43));
    final activeTrackColor =
        widget.activeColor ?? CupertinoColors.systemGreen.resolveFrom(context);
    final isRtl = _isRtl;

    // iOS Settings > Accessibility > Display & Text Size > On/Off Labels.
    final onOffLabelColors = MediaQuery.onOffSwitchLabelsOf(context)
        ? (
            CupertinoDynamicColor.resolve(
                widget.onLabelColor ?? CupertinoColors.white, context),
            CupertinoDynamicColor.resolve(
                widget.offLabelColor ?? _kOffLabelColor, context),
          )
        : null;

    final baseMediaQuery =
        MediaQuery.maybeOf(context) ?? const MediaQueryData();

    return GlassFocusRegion(
        enabled: true,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        semanticLabel: widget.semanticLabel ?? 'Switch',
        isButton: true,
        toggled: widget.value,
        semanticOnTap: _handleTap,
        shape: const StadiumBorder(),
        isFocusedNotifier: _isFocused,
        isHoveredNotifier: _isHovered,
        onKeyboardActivate: _activateFromKeyboard,
        child: MediaQuery(
          // Use a responsive 3 px horizontal drag slop (instead of Flutter's
          // default 18 px kTouchSlop, which is ~90% of the switch's 20 px
          // runway!) so horizontal drags engage immediately like native UISwitch.
          data: baseMediaQuery.copyWith(
            gestureSettings: const DeviceGestureSettings(touchSlop: 3.0),
          ),
          child: GestureDetector(
            excludeFromSemantics: true,
            // NOTE: We do NOT use onTap here. Having both onTap and onHorizontalDrag*
            // on the same GestureDetector creates a gesture arena conflict — Flutter
            // must choose one winner per touch, leading to missed interactions.
            // Instead, we detect taps manually: onTapDown starts the bloom, onTapUp
            // fires the toggle if no horizontal drag was confirmed.
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onHorizontalDragDown: _onDragDown,
            onHorizontalDragCancel: _onDragCancel,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            // Performance: RepaintBoundary isolates switch animation from parent
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _positionController,
                  _thicknessController,
                  _overshootController,
                ]),
                builder: (context, child) {
                  final position = _positionController.value;
                  final thickness = _thicknessAnimation.value;

                  final blendedColor = Color.lerp(
                      inactiveTrackColor, activeTrackColor, position)!;

                  final track = Container(
                    width: trackWidth,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: blendedColor,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  );

                  // Calibrated iOS 27 UISwitchModernVisualElement lifted lens
                  // geometry:
                  // - Resting knob (63×28): (2.00, 2.00, 37.00, 24.00) -> ON (24.00, 2.00, 37.00, 24.00)
                  // - Lifted lens (63×28): (-8.67, -5.33, 58.00, 38.33) -> ON (13.67, -5.33, 58.00, 38.33)
                  final vExpand = thickness *
                      (thumbSize * _kNativeLiftedVerticalExpandRatio);
                  final leadStretch =
                      thickness * (thumbSize * _kNativeLiftedWidthExpandRatio);

                  // Native pressed inset shifts outward by 0.1667 pt on each side
                  // when lifted (2.0 -> 1.8333 pt).
                  final pressedInset = 2.0 - (0.1667 * thickness);
                  final effectiveTravel =
                      trackWidth - thumbWidth - (pressedInset * 2.0);
                  // Mirrored in RTL: on is the left end of the track.
                  final visualPosition = isRtl ? 1.0 - position : position;
                  final thumbOffset =
                      pressedInset + (effectiveTravel * visualPosition);

                  // Symmetric expansion around the knob center ensures true 1:1
                  // finger tracking across the runway (no speed multiplication)
                  // while delivering -8.67 pt left overhang at OFF and +8.67 pt
                  // right overhang at ON.
                  final double anchorOffset = leadStretch / 2.0;

                  // Native UISwitchModernVisualElement ±12.0 pt asymptotic
                  // rubber-band overhang when dragging past 0.0 (left) or 1.0 (right),
                  // reaching ±15.6 pt total overhang at 30 pt over-drag.
                  final double overshootPx = _currentOvershootPx;
                  const double maxRubberBand = 12.0;
                  final double rawRubberBand = overshootPx == 0.0
                      ? 0.0
                      : overshootPx.sign *
                          maxRubberBand *
                          (1.0 -
                              1.0 /
                                  (1.0 +
                                      0.55 *
                                          (overshootPx.abs() / maxRubberBand)));
                  final double rubberBandOffset =
                      isRtl ? -rawRubberBand : rawRubberBand;

                  // Native _UIFlexInteraction subtle horizontal stretch &
                  // vertical squash during over-drag.
                  final double flexStretch =
                      (rubberBandOffset.abs() / maxRubberBand) *
                          0.03 *
                          thickness;
                  final double flexScaleX = 1.0 + flexStretch;
                  final double flexScaleY = 1.0 - flexStretch;

                  final thumbLeft =
                      thumbOffset - anchorOffset + rubberBandOffset;

                  final thumb = Positioned(
                    left: thumbLeft,
                    top: pressedInset - vExpand,
                    child: Transform.scale(
                      scaleX: flexScaleX,
                      scaleY: flexScaleY,
                      child: _buildThumb(thumbSize, thickness, vExpand,
                          leadStretch, anchorOffset, effectiveQuality, isDark),
                    ),
                  );

                  return SizedBox(
                    width: trackWidth,
                    height: widget.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        track,
                        // Painted over the track and under the thumb, so the
                        // thumb covers the mark on its side.
                        if (onOffLabelColors != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _OnOffLabelsPainter(
                                onColor: onOffLabelColors.$1,
                                offColor: onOffLabelColors.$2,
                                position: position,
                                reaction: thickness,
                                thumbWidth: thumbWidth,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                              ),
                            ),
                          ),
                        thumb,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ));
  }

  Widget _buildThumb(
      double size,
      double transition,
      double vExpand,
      double leadStretch,
      double anchorOffset,
      GlassQuality? effectiveQuality,
      bool isDark) {
    final thumbWidth = size * _kNativeKnobAspect;
    final thumbHeight = size;
    final totalWidth = thumbWidth + leadStretch;
    final totalHeight = thumbHeight + vExpand * 2;

    // Restored perfect pill radius with exact stadium SDF.
    final thumbShape = LiquidRoundedRectangle(
      borderRadius: totalHeight / 2,
    );
    // Standard path only — Premium values are unchanged.
    final isStdPath =
        (effectiveQuality ?? GlassQuality.standard) == GlassQuality.standard;

    final materialOpacity = (1.0 - transition * 1.4).clamp(0.0, 1.0);
    final thumbShadow = widget.thumbShadow ?? _defaultThumbShadow;
    final shadowOpacity = (1.0 - transition) * materialOpacity;
    // Matches native _UILiquidLensView's autoresize=W+H white fill layer
    // (CALayer bg=UIExtendedGrayColorSpace 1 1), which spans the full morphing
    // capsule bounds rather than leaving a small 37×24 pill floating inside the
    // expanding 58×38.33 glass lens.
    final materialContent = Opacity(
      opacity: materialOpacity,
      child: Container(
        width: totalWidth,
        height: totalHeight,
        decoration: BoxDecoration(
          color: widget.thumbColor.withValues(alpha: 1.0),
          borderRadius: BorderRadius.circular(totalHeight / 2),
        ),
      ),
    );

    final theme = GlassTheme.maybeOf(context)?.data;
    final style = theme?.style ?? GlassStyle.ios27;
    final thumbTint = isDark
        ? const Color.from(alpha: 0.08, red: 1, green: 1, blue: 1)
        : const Color.from(alpha: 0.12, red: 0.88, green: 0.88, blue: 0.90);
    final eraBase = switch (style) {
      GlassStyle.classic => LiquidGlassSettings(
          glassColor: thumbTint,
          refractiveIndex: isDark ? 1.12 : 1.22,
          thickness: isDark ? 10 : 14,
          lightIntensity: isStdPath ? 0.0 : 2.0,
          blur: 0,
          lightAngle: GlassDefaults.lightAngle,
        ),
      GlassStyle.ios26 => LiquidGlassSettings.ios26Indicator.copyWith(
          refractiveIndex: 1.38,
          rimShade: 1.0,
          rimShadeEnds: 0.56,
          rimLight: 1.0,
        ),
      GlassStyle.ios27 => LiquidGlassSettings.ios27Indicator.copyWith(
          refractiveIndex: 1.38,
        ),
    };
    final themedThumbSettings =
        theme?.indicatorSettingsFor(context)?.applyTo(eraBase) ?? eraBase;
    final fade = transition.clamp(0.0, 1.0);
    final stablePinchFade = 1.0 - (1.0 - fade) * (1.0 - fade);
    final rawThumbSettings = widget.settings ?? themedThumbSettings;
    final hasNativeRim =
        rawThumbSettings.rimLight > 0 || rawThumbSettings.rimShade > 0;
    final baseThumbSettings = rawThumbSettings.copyWith(
      blur: 0,
      frost: 0,
      glassColor: isStdPath &&
              rawThumbSettings.glassColor.a == 0 &&
              (isDark || !hasNativeRim)
          ? thumbTint
          : null,
    );
    final useIos27Lens = baseThumbSettings.lensModel == GlassLensModel.paraxial;
    final resolvedThumbSettings = useIos27Lens
        ? baseThumbSettings.copyWithPinch(stablePinchFade)
        : baseThumbSettings;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Paint outside GlassEffect's shape clip so the resting shadow is
          // never clipped to the thumb silhouette.
          if (thumbShadow.isNotEmpty)
            Positioned(
              left: anchorOffset,
              top: vExpand,
              child: SizedBox(
                width: thumbWidth,
                height: thumbHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(thumbHeight / 2),
                    boxShadow: [
                      for (final shadow in thumbShadow)
                        shadow.copyWith(
                          color: shadow.color.withValues(
                            alpha: shadow.color.a * shadowOpacity,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          GlassEffect(
            shape: thumbShape,
            settings: resolvedThumbSettings,
            rimThickness: isStdPath
                ? (isDark ? 0.5 : 0.7)
                : 0.5, // slightly thicker rim in light mode
            ambientRim: isStdPath
                ? (isDark ? 0.08 : 0.15)
                : 0.1, // stronger ambient ring in light mode
            baseAlphaMultiplier: isStdPath
                ? (isDark ? 0.0 : 0.04)
                : 0.2, // near-clear body — refraction provides visibility
            edgeAlphaMultiplier: isStdPath
                ? (isDark ? 0.15 : 0.28)
                : 0.4, // stronger edge contrast in light mode
            quality: effectiveQuality ?? GlassQuality.standard,
            interactionIntensity: transition,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Glass shell footprint
                Positioned.fill(
                    child: Container(color: const Color(0x00000000))),

                // Full-capsule morphing white fill (fades out as lens lifts)
                Positioned.fill(
                  child: materialContent,
                ),

                if (transition > 0.05)
                  Positioned(
                    left: anchorOffset,
                    child: Opacity(
                      opacity: transition,
                      child: GlassGlow(
                        glowColor: useIos27Lens
                            ? const Color(0x00000000)
                            : const Color(0x3DFFFFFF),
                        child: SizedBox(
                          width: thumbWidth,
                          height: thumbHeight,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (transition > 0.05)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: LensInnerShadowPainter(
                    borderRadius: totalHeight / 2,
                    opacity: transition,
                    shadowOpacity: resolvedThumbSettings.rimShade > 0.0
                        ? LensInnerShadowPainter.defaultShadowOpacity
                        : LensInnerShadowPainter.classicShadowOpacity,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints iOS's On/Off Labels marks on the track: an `I` on the side the
/// thumb leaves when on, an `O` on the side it leaves when off. Each fades
/// with the thumb's position and while the thumb blooms under a press, like
/// [CupertinoSwitch]'s.
class _OnOffLabelsPainter extends CustomPainter {
  _OnOffLabelsPainter({
    required this.onColor,
    required this.offColor,
    required this.position,
    required this.reaction,
    required this.thumbWidth,
    required this.textDirection,
  });

  final Color onColor;
  final Color offColor;
  final double position;
  final double reaction;
  final double thumbWidth;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / _kUISwitchTrackHeight;
    final gapCenter = (size.width - 2.0 - thumbWidth) / 2.0;
    final onInset = gapCenter + _kOnLabelPastGapCenter * scale;
    final offInset = gapCenter + _kOffLabelPastGapCenter * scale;
    final centerY = size.height / 2.0;
    final ltr = textDirection == TextDirection.ltr;

    final visible = (1.0 - reaction).clamp(0.0, 1.0);
    final onOpacity = (position * visible).clamp(0.0, 1.0);
    final offOpacity = ((1.0 - position) * visible).clamp(0.0, 1.0);

    // Each mark sits at the end of the track the thumb leaves for its state.
    final onCenter = Offset(ltr ? onInset : size.width - onInset, centerY);
    final offCenter = Offset(ltr ? size.width - offInset : offInset, centerY);

    if (onOpacity > 0.0) {
      canvas.drawRect(
        Rect.fromCenter(
          center: onCenter,
          width: _kOnLabelWidth,
          height: _kOnLabelHeight * scale,
        ),
        Paint()..color = onColor.withValues(alpha: onColor.a * onOpacity),
      );
    }
    if (offOpacity > 0.0) {
      canvas.drawCircle(
        offCenter,
        _kOffLabelRadius * scale,
        Paint()
          ..color = offColor.withValues(alpha: offColor.a * offOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _kOffLabelStrokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_OnOffLabelsPainter oldDelegate) =>
      oldDelegate.onColor != onColor ||
      oldDelegate.offColor != offColor ||
      oldDelegate.position != position ||
      oldDelegate.reaction != reaction ||
      oldDelegate.thumbWidth != thumbWidth ||
      oldDelegate.textDirection != textDirection;
}
