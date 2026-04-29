import 'dart:async';

import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../constants/glass_defaults.dart';
import '../../types/glass_quality.dart';
import '../shared/glass_effect.dart';
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
    this.thumbColor = Colors.white,
    this.width = 58.0,
    this.height = 26.0,
    this.settings,
    this.useOwnLayer = false,
    this.quality,
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
  /// If null, defaults to green color.
  final Color? activeColor;

  /// The color of the track when the switch is off.
  ///
  /// If null, defaults to a semi-transparent white.
  final Color? inactiveColor;

  /// The color of the thumb (circular knob).
  ///
  /// Defaults to white.
  final Color thumbColor;

  // ===========================================================================
  // Sizing Properties
  // ===========================================================================

  /// Width of the switch.
  ///
  /// Defaults to 62.0 (iOS 26 wide pill runway).
  final double width;

  /// Height of the switch.
  ///
  /// Defaults to 28.0.
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

  @override
  State<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<GlassSwitch>
    with TickerProviderStateMixin {
  // Cache default shadow color to avoid allocations
  // Shadow color for the thumb material
  static const _defaultThumbShadowColor = Color(0x33000000);

  late AnimationController _positionController;
  late AnimationController _thicknessController;
  late Animation<double> _positionAnimation;
  late Animation<double> _thicknessAnimation;
  bool _isMovingForward = true; // Track direction of animation

  // ---------------------------------------------------------------------------
  // Gesture state
  // ---------------------------------------------------------------------------
  bool _isDragging = false;
  double _dragStartX = 0.0;
  double _dragStartPosition = 0.0;
  bool _dragAbandonedExternally = false;
  bool _justEndedDrag = false;

  // Cache effectiveQuality at state level to make it accessible in _buildThumb
  GlassQuality? _effectiveQuality;

  @override
  void initState() {
    super.initState();

    // Unified tempo: Position jump and Liquid bloom now move together
    _positionController = AnimationController(
        duration: const Duration(milliseconds: 380), vsync: this);
    _thicknessController = AnimationController(
        duration: const Duration(milliseconds: 380), vsync: this);

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _positionController,
        curve: Curves.easeInOutCubic, // Match the growth momentum
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

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
      if (!_justEndedDrag) {
        if (_thicknessController.value == 1.0) {
          _thicknessController.value = 0.0;
        }
        unawaited(
            _thicknessController.forward(from: _thicknessController.value));
      }
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _thicknessController.dispose();
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
    if (_thicknessController.value == 1.0) {
      _thicknessController.value = 0.0;
    }
    _dragAbandonedExternally = false;
    _thicknessController.animateTo(
      0.45,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails details) {
    // A tap is confirmed only when no horizontal drag was registered.
    if (!_isDragging) {
      // Deflate the bloom — the tap animation in didUpdateWidget will
      // re-trigger it correctly with the full directional stretch.
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
    if (_thicknessController.value == 1.0) {
      _thicknessController.value = 0.0;
    }

    // If we're not at perfect plump (e.g., started deflating), animate back to 0.45
    if ((_thicknessController.value - 0.45).abs() > 0.01) {
      _thicknessController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 80),
      );
    } else {
      _thicknessController.value = 0.45;
    }
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

    // Animate thumb to its resting position.
    if (shouldBeOn) {
      unawaited(_positionController.forward());
    } else {
      unawaited(_positionController.reverse());
    }

    // Continue the settle bloom down to 0 so the landing feels weighty.
    unawaited(_thicknessController.forward(from: _thicknessController.value));

    // Notify parent only when the value actually changed.
    if (shouldBeOn != widget.value) {
      widget.onChanged(shouldBeOn);
    }

    // Reset flag in next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _justEndedDrag = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer or theme if not explicitly set
    _effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    final thumbSize = widget.height - 4.0;
    final thumbWidth = thumbSize * 1.6; // Match _buildThumb ratio
    final trackWidth = widget.width;
    // Fix: Use actual thumb width for travel distance calculation
    final thumbTravelDistance = trackWidth - thumbWidth - 4.0;

    // Performance: Cache color calculations as const to avoid allocation
    final inactiveTrackColor =
        widget.inactiveColor ?? const Color(0x33FFFFFF); // alpha: 0.2
    final activeTrackColor = widget.activeColor ?? Colors.green;

    return GestureDetector(
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
            final specularTop =
                Color.lerp(activeTrackColor, Colors.white, 0.25)!;

            final track = Container(
              width: trackWidth,
              height: widget.height,
              decoration: BoxDecoration(
                // Gradient blends in as position → 1: starts as a flat lerped
                // colour, gains the specular highlight progressively.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(blendedColor, specularTop, position)!,
                    blendedColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.height / 2),
                // Glow fades in smoothly from 0 → max alpha over full travel.
                // Kept subtle (0.35 max, 6dp blur) to avoid over-illumination.
                boxShadow: position > 0.01
                    ? [
                        BoxShadow(
                          color: activeTrackColor.withValues(
                            alpha: 0.35 * position,
                          ),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
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
                    leadStretch, anchorOffset),
              ),
            );

            const glassOverlay = SizedBox.shrink();

            return Semantics(
              label: 'Switch',
              toggled: widget.value,
              enabled: true,
              onTap: _handleTap,
              child: SizedBox(
                width: trackWidth,
                height: widget.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    track,
                    thumb,
                    glassOverlay, // Glass overlay appears ABOVE thumb
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumb(double size, double transition, double scale,
      double vExpand, double leadStretch, double anchorOffset) {
    // iOS 26: Unified Material Melt with Directional Anchoring
    final thumbWidth = size * 1.6;
    final thumbHeight = size;
    final totalWidth = thumbWidth + leadStretch;
    final totalHeight = thumbHeight + vExpand * 2;

    // iOS 26: Synchronized Biological Bloom
    // Restored perfect pill radius (no squareness)
    final thumbShape = LiquidRoundedSuperellipse(
      borderRadius: totalHeight / 2,
    );

    final materialContent = Opacity(
      opacity: (1.0 - transition * 1.2).clamp(0.0, 1.0),
      child: Container(
        width: thumbWidth,
        height: thumbHeight,
        decoration: BoxDecoration(
          color: widget.thumbColor.withValues(alpha: 1.0),
          borderRadius: BorderRadius.circular(thumbHeight / 2),
          boxShadow: [
            BoxShadow(
              color: _defaultThumbShadowColor.withValues(
                  alpha: 0.2 * (1.0 - transition)),
              blurRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: GlassEffect(
        shape: thumbShape,
        settings: (_effectiveQuality ?? GlassQuality.standard)
                .usesLightweightShader
            ? const LiquidGlassSettings(
                glassColor: Color.from(alpha: 0.1, red: 1, green: 1, blue: 1),
                refractiveIndex: 1.15,
                thickness: 20,
                lightIntensity: 2.0,
                blur: 0,
                lightAngle: GlassDefaults.lightAngle, // Apple iOS 26 standard
              )
            : const LiquidGlassSettings(
                glassColor: Color.from(alpha: 0.1, red: 1, green: 1, blue: 1),
                refractiveIndex: 1.15, // Premium sharpness boost
                thickness: 10,
                lightIntensity: 2, // Bold specular highlight
                blur: 0,
                lightAngle: GlassDefaults.lightAngle, // Apple iOS 26 standard
              ),
        quality: _effectiveQuality ?? GlassQuality.standard,
        interactionIntensity: transition,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glass shell footprint
            Positioned.fill(child: Container(color: Colors.transparent)),

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
          ],
        ),
      ),
    );
  }
}
