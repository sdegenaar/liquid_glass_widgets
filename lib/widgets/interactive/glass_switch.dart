import 'dart:async';

import 'package:flutter/cupertino.dart';
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

  /// Defaults to [GlassQuality.standard], which uses backdrop filter rendering.
  /// This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for shader-based glass in static layouts only.
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
  late CurvedAnimation _positionCurve;
  late Animation<double> _positionAnimation;
  late Animation<double> _thicknessAnimation;
  late bool _isMovingForward; // Track direction of animation

  // ---------------------------------------------------------------------------
  // Gesture state
  // ---------------------------------------------------------------------------
  bool _isDragging = false;
  double _dragStartX = 0.0;
  double _dragStartPosition = 0.0;
  bool _dragAbandonedExternally = false;
  bool _justEndedDrag = false;

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

    _positionCurve = CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeInOutCubic, // Match the growth momentum
      reverseCurve: Curves.easeInOutCubic,
    );
    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_positionCurve);

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
    _isMovingForward = widget.value;
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
      }

      // Track direction: true = moving forward (left to right)
      _isMovingForward = widget.value;

      // Animate position
      if (widget.value) {
        unawaited(_positionController.forward());
      } else {
        unawaited(_positionController.reverse());
      }

      // Trigger the liquid pulse bloom (Grow up and then down)
      final bool justEndedDrag = _justEndedDrag;
      _justEndedDrag = false;

      if (!justEndedDrag) {
        if (_thicknessController.value >= 0.99) {
          _thicknessController.value = 0.0;
        }

        // Sync the jump duration exactly to the remaining travel time so that
        // if the user held the switch (full bloom), it stays bloomed and deflates
        // cleanly across the entire horizontal movement.
        final double posDist = widget.value
            ? (1.0 - _positionController.value)
            : _positionController.value;
        final int ms = (380 * posDist).round();

        if (ms > 0) {
          unawaited(_thicknessController.animateTo(
            1.0,
            duration: Duration(milliseconds: ms),
            // Use an ease-in curve so that if the thumb is fully bloomed (held down),
            // it maintains its stretched shape for the majority of the travel,
            // and only deflates back to a circle as it lands on the other side.
            // This prevents the "jerky" deflation mid-flight.
            curve: Curves.easeIn,
          ));
        } else {
          _thicknessController.value = 1.0;
        }
      }
    } else if (!_isDragging) {
      final target = widget.value ? 1.0 : 0.0;
      if (_positionController.value != target) {
        _isMovingForward = widget.value;
        if (widget.value) {
          unawaited(_positionController.forward());
        } else {
          unawaited(_positionController.reverse());
        }
      }
      if (_thicknessController.value > 0.0 &&
          !_thicknessController.isAnimating) {
        unawaited(
            _thicknessController.forward(from: _thicknessController.value));
      }
    }
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
    _positionCurve.dispose();
    _positionController.dispose();
    _thicknessController.dispose();
    _isHovered.dispose();
    _isFocused.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onChanged(!widget.value);
  }

  // ---------------------------------------------------------------------------
  // Drag-to-toggle handlers
  // ---------------------------------------------------------------------------

  /// Pixel travel distance from the left edge to right edge of the thumb runway.
  double get _thumbTravelDistance {
    final thumbSize = widget.height - 4.0;
    final thumbWidth = thumbSize * 1.6;
    return widget.width - thumbWidth - 4.0;
  }

  // ---------------------------------------------------------------------------
  // Gesture handlers
  // ---------------------------------------------------------------------------

  void _onTapDown(TapDownDetails details) {
    // Finger is down: start the bloom immediately for instant feedback.
    if (_thicknessController.value >= 0.99) {
      _thicknessController.value = 0.0;
    }
    _dragAbandonedExternally = false;
    unawaited(_thicknessController.animateTo(
      0.45,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    ));
  }

  void _onTapUp(TapUpDetails details) {
    // A tap is confirmed only when no horizontal drag was registered.
    if (!_isDragging) {
      // Fire haptic immediately — user feels the click the instant they lift.
      if (widget.enableHaptics) unawaited(HapticFeedback.lightImpact());
      unawaited(_thicknessController.forward(from: _thicknessController.value));
      _handleTap();
    }
  }

  void _onTapCancel() {
    // Finger moved away without a tap or drag completing.
    if (!_isDragging) {
      unawaited(_thicknessController.forward(from: _thicknessController.value));
    }
  }

  void _onDragStart(DragStartDetails details) {
    // Flutter has confirmed horizontal movement — commit to drag mode.
    _positionController.stop();
    _dragStartX = details.localPosition.dx;
    _dragStartPosition = _positionController.value;
    _dragAbandonedExternally = false;
    setState(() => _isDragging = true);

    // Stop any deflation that onTapCancel might have started
    _thicknessController.stop();

    // Ensure bloom is at peak.
    if (_thicknessController.value >= 0.99) {
      _thicknessController.value = 0.0;
    }

    // If we're not at perfect plump (e.g., started deflating), animate back to 0.45
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
    setState(() => _isDragging = false);
    // Deflate bloom smoothly.
    unawaited(_thicknessController.forward(from: _thicknessController.value));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    // Map finger position → track position (0.0 – 1.0) and push it directly
    // into the controller so the AnimatedBuilder redraws this frame.
    final travel = _thumbTravelDistance;
    final dragDelta = details.localPosition.dx - _dragStartX;
    _positionController.value =
        (_dragStartPosition + dragDelta / travel).clamp(0.0, 1.0);

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
    // No-op if an external value change has already taken ownership.
    if (_dragAbandonedExternally) {
      _dragAbandonedExternally = false;
      return;
    }
    if (!_isDragging) return;
    final position = _positionController.value;
    final velocity = details.primaryVelocity ?? 0.0;

    // A fast flick (> 200 px/s) wins over position; otherwise snap at 50 %.
    final bool shouldBeOn =
        velocity.abs() > 200.0 ? velocity > 0 : position >= 0.5;

    _isMovingForward = shouldBeOn;
    setState(() => _isDragging = false);
    _justEndedDrag = true;

    // Notify parent only when the value actually changed.
    if (shouldBeOn != widget.value) {
      widget.onChanged(shouldBeOn);
    }

    // Animate thumb to its resting position based on authoritative widget.value.
    if (widget.value) {
      unawaited(_positionController.forward());
    } else {
      unawaited(_positionController.reverse());
    }

    // Continue the settle bloom down to 0 so the landing feels weighty.
    unawaited(_thicknessController.forward(from: _thicknessController.value));

    // Haptic on snap — only if the state is changing AND the midpoint
    // crossing haptic didn't already fire (avoids a double-tap feel on
    // slow deliberate drags that naturally crossed the midpoint).
    if (widget.enableHaptics &&
        !_dragMidpointHapticFired &&
        shouldBeOn != widget.value) {
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
    );

    final thumbSize = widget.height - 4.0;
    final thumbWidth = thumbSize * 1.6; // Match _buildThumb ratio
    final trackWidth = widget.width;
    // Fix: Use actual thumb width for travel distance calculation
    final thumbTravelDistance = trackWidth - thumbWidth - 4.0;

    // Performance: Cache color calculations as const to avoid allocation
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    // Matches native UISwitchModernVisualElement off-track fill on iOS 26 & 27:
    // rgba(60, 60, 67, 0.30) in light mode, rgba(235, 235, 245, 0.30) in dark mode.
    final inactiveTrackColor = widget.inactiveColor ??
        (isDark ? const Color(0x4DEBEBF5) : const Color(0x4D3C3C43));
    final activeTrackColor =
        widget.activeColor ?? CupertinoColors.systemGreen.resolveFrom(context);

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
          onHorizontalDragCancel: _onDragCancel,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          // Performance: RepaintBoundary isolates switch animation from parent
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_positionController, _thicknessController]),
              builder: (context, child) {
                final position = _positionAnimation.value;
                final thickness = _thicknessAnimation.value;
                // Tie squash directly to thickness so it doesn't fluctuate during drag
                final scale = 1.0 - (thickness * 0.08);

                // Build the track — plain Container driven entirely by `position`
                // from the single AnimatedBuilder above. Using AnimatedContainer
                // here previously caused a 200ms *second* animation to start after
                // the rebuild, making the track go green late. Now everything is
                // frame-locked to _positionAnimation.
                //
                // Color strategy:
                //   0.0 = fully inactive (inactiveTrackColor, no glow)
                //   1.0 = fully active   (activeTrackColor gradient, glow)
                // We lerp smoothly using `position` as the blend factor.
                final blendedColor =
                    Color.lerp(inactiveTrackColor, activeTrackColor, position)!;

                final track = Container(
                  width: trackWidth,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: blendedColor,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                );

                // Growth/Expansion offsets
                final vExpand = thickness * 10.0;
                final leadStretch = thickness * 16.0;

                final thumbOffset = 2.0 + (thumbTravelDistance * position);

                // Anchor logic:
                // Dragging -> Symmetric stretch (anchor center)
                // Jumping  -> Directional stretch (anchor left or right based on direction)
                final double anchorOffset = _isDragging
                    ? (leadStretch / 2.0)
                    : (_isMovingForward ? 0.0 : leadStretch);

                final thumbLeft = thumbOffset - anchorOffset;

                final thumb = Positioned(
                  left: thumbLeft,
                  top: 2.0 - vExpand,
                  child: Transform.scale(
                    // Combined scale: Squash for jump + slight Grow for the liquid bloom
                    scale: scale * (1.0 + thickness * 0.1),
                    child: _buildThumb(thumbSize, thickness, scale, vExpand,
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
                      thumb,
                    ],
                  ),
                );
              },
            ),
          ),
        ));
  }

  Widget _buildThumb(
      double size,
      double transition,
      double scale,
      double vExpand,
      double leadStretch,
      double anchorOffset,
      GlassQuality? effectiveQuality,
      bool isDark) {
    // iOS 26: Unified Material Melt with Directional Anchoring
    final thumbWidth = size * 1.6;
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

    final materialOpacity = (1.0 - transition * 1.2).clamp(0.0, 1.0);
    final thumbShadow = widget.thumbShadow ?? _defaultThumbShadow;
    final shadowOpacity = (1.0 - transition) * materialOpacity;
    final materialContent = Opacity(
      opacity: materialOpacity,
      child: Container(
        width: thumbWidth,
        height: thumbHeight,
        decoration: BoxDecoration(
          color: widget.thumbColor.withValues(alpha: 1.0),
          borderRadius: BorderRadius.circular(thumbHeight / 2),
        ),
      ),
    );

    final theme = GlassTheme.maybeOf(context)?.data;
    final style = theme?.style ?? GlassStyle.ios27;
    final thumbTint = isDark
        ? const Color.from(alpha: 0.08, red: 1, green: 1, blue: 1)
        : const Color.from(alpha: 0.12, red: 0.88, green: 0.88, blue: 0.90);
    final eraBase = (style == GlassStyle.classic)
        ? LiquidGlassSettings(
            glassColor: thumbTint,
            refractiveIndex: isDark ? 1.12 : 1.22,
            thickness: isDark ? 10 : 14,
            lightIntensity: isStdPath ? 0.0 : 2.0,
            blur: 0,
            lightAngle: GlassDefaults.lightAngle,
          )
        : LiquidGlassSettings.ios27Indicator.copyWith(
            glassColor: thumbTint,
            refractiveIndex: isDark ? 1.12 : 1.22,
            thickness: isDark ? 14 : 18,
          );
    final themedThumbSettings =
        theme?.indicatorSettingsFor(context)?.applyTo(eraBase) ?? eraBase;
    final resolvedThumbSettings =
        (widget.settings ?? themedThumbSettings).copyWith(blur: 0, frost: 0);
    final useIos27Lens =
        resolvedThumbSettings.lensModel == GlassLensModel.paraxial;

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

                // Physical thumb position based on anchor
                Positioned(
                  left: anchorOffset,
                  child: materialContent,
                ),

                if (transition > 0.05)
                  Positioned(
                    left: anchorOffset,
                    child: Opacity(
                      opacity: transition,
                      child: GlassGlow(
                        child: SizedBox(
                          width: thumbWidth,
                          height: thumbHeight,
                        ),
                      ),
                    ),
                  ),

                if (!isStdPath && transition > 0.05)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: LensInnerShadowPainter(
                          borderRadius: totalHeight / 2,
                          opacity: transition,
                          shadowOpacity: useIos27Lens
                              ? LensInnerShadowPainter.defaultShadowOpacity
                              : LensInnerShadowPainter.classicShadowOpacity,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
