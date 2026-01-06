import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';
import '../shared/adaptive_glass.dart';
import '../shared/inherited_liquid_glass.dart';

/// A glass morphism slider following Apple's iOS 26 design patterns.
///
/// [GlassSlider] provides a sophisticated slider with glass track, draggable
/// thumb with jelly physics, and smooth animations. It matches iOS's UISlider
/// appearance and behavior with glass morphism effects.
///
/// ## Key Features
///
/// - **Glass Track**: Background track with glass effect
/// - **Active Track**: Colored portion showing current value
/// - **Jelly Thumb**: Draggable thumb with organic squash/stretch physics
/// - **Haptic Feedback**: Subtle feedback when reaching discrete values
/// - **Continuous or Discrete**: Support for continuous values or divisions
/// - **Customizable**: Full control over colors, sizes, and shapes
///
/// ## Usage
///
/// ### Basic Usage (Continuous)
/// ```dart
/// double volume = 0.5;
///
/// GlassSlider(
///   value: volume,
///   onChanged: (value) {
///     setState(() => volume = value);
///   },
/// )
/// ```
///
/// ### Discrete Values
/// ```dart
/// double brightness = 3.0;
///
/// GlassSlider(
///   value: brightness,
///   min: 0.0,
///   max: 5.0,
///   divisions: 5,
///   onChanged: (value) {
///     setState(() => brightness = value);
///   },
/// )
/// ```
///
/// ### Within LiquidGlassLayer (Grouped Mode)
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 3,
///     refractiveIndex: 1.59,
///   ),
///   child: Column(
///     children: [
///       GlassSlider(
///         value: volume,
///         onChanged: (value) => setVolume(value),
///         label: 'Volume',
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassSlider(
///   value: brightness,
///   onChanged: (value) => setBrightness(value),
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 3,
///   ),
/// )
/// ```
///
/// ### Custom Styling
/// ```dart
/// GlassSlider(
///   value: temperature,
///   min: 0,
///   max: 100,
///   onChanged: (value) => setTemperature(value),
///   activeColor: Colors.red,
///   thumbColor: Colors.red,
///   trackHeight: 6,
///   thumbRadius: 16,
/// )
/// ```
class GlassSlider extends StatefulWidget {
  /// Creates a glass slider.
  const GlassSlider({
    required this.value,
    required this.onChanged,
    super.key,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor = Colors.white,
    this.trackHeight = 4.0,
    this.thumbRadius = 15.0,
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
  });

  // ===========================================================================
  // Slider Properties
  // ===========================================================================

  /// The current value of the slider.
  ///
  /// Must be between [min] and [max].
  final double value;

  /// Called when the user is selecting a new value.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts dragging the slider.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user finishes dragging the slider.
  final ValueChanged<double>? onChangeEnd;

  /// The minimum value of the slider.
  ///
  /// Defaults to 0.0.
  final double min;

  /// The maximum value of the slider.
  ///
  /// Defaults to 1.0.
  final double max;

  /// The number of discrete divisions.
  ///
  /// If null, the slider is continuous. If provided, the slider will snap
  /// to discrete values.
  final int? divisions;

  /// Optional label shown above the thumb.
  final String? label;

  // ===========================================================================
  // Style Properties
  // ===========================================================================

  /// Color of the active track (left of thumb).
  ///
  /// If null, defaults to white with 80% opacity.
  final Color? activeColor;

  /// Color of the inactive track (right of thumb).
  ///
  /// If null, defaults to white with 20% opacity.
  final Color? inactiveColor;

  /// Color of the thumb.
  ///
  /// Defaults to white.
  final Color thumbColor;

  /// Height of the track.
  ///
  /// Defaults to 4.0.
  final double trackHeight;

  /// Radius of the thumb.
  ///
  /// Defaults to 14.0 (iOS standard).
  final double thumbRadius;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings (only used when [useOwnLayer] is true).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass.
  ///
  /// Defaults to false (grouped mode).
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses the lightweight fragment
  /// shader. This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for full-pipeline shader with texture capture
  /// and chromatic aberration (Impeller only) in static layouts.
  final GlassQuality quality;

  @override
  State<GlassSlider> createState() => _GlassSliderState();
}

class _GlassSliderState extends State<GlassSlider>
    with TickerProviderStateMixin {
  // Cache default colors to avoid allocations
  static const _defaultThumbShadowColor =
      Color(0x40000000); // black.withValues(alpha: 0.25)

  double? _dragValue;
  bool _isDragging = false;
  Offset _velocity = Offset.zero;
  late AnimationController _scaleController;
  late AnimationController _thicknessController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _thicknessAnimation;

  @override
  void initState() {
    super.initState();

    // Scale controller for thumb size change when dragging
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // iOS 26: Thumb "balloons in size" when dragging (1.25x = 25% larger)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.35, // More dramatic balloon effect
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack, // Slight overshoot for organic feel
        reverseCurve: Curves.easeInBack,
      ),
    );

    // Thickness controller for glass overlay visibility (iOS 26 liquid glass)
    _thicknessController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _thicknessAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _thicknessController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _thicknessController.dispose();
    super.dispose();
  }

  // double get _normalizedValue {
  //   return ((widget.value - widget.min) / (widget.max - widget.min))
  //       .clamp(0.0, 1.0);
  // }

  double _normalizedToValue(double normalized) {
    return widget.min + (normalized * (widget.max - widget.min));
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _velocity = Offset.zero;
    });
    // Scale up thumb when starting drag (iOS 26 liquid effect)
    unawaited(_scaleController.forward());

    // Show glass overlay (iOS 26 liquid glass effect)
    unawaited(_thicknessController.forward());

    widget.onChangeStart?.call(widget.value);
  }

  void _handleDragUpdate(
      DragUpdateDetails details, BoxConstraints constraints) {
    final box = context.findRenderObject()! as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // Calculate normalized position (0-1)
    final trackWidth = constraints.maxWidth - (widget.thumbRadius * 2);
    final normalizedX =
        ((localPosition.dx - widget.thumbRadius) / trackWidth).clamp(0.0, 1.0);

    // Update velocity for jelly effect
    setState(() {
      _velocity = Offset(details.primaryDelta ?? 0, 0);
    });

    // Convert to value
    var newValue = _normalizedToValue(normalizedX);

    // Snap to divisions if provided
    if (widget.divisions != null) {
      final stepSize = (widget.max - widget.min) / widget.divisions!;
      newValue = (newValue / stepSize).round() * stepSize + widget.min;
      newValue = newValue.clamp(widget.min, widget.max);

      // Haptic feedback on division change
      if (_dragValue != null && newValue != _dragValue) {
        unawaited(HapticFeedback.selectionClick());
      }
    }

    setState(() {
      _dragValue = newValue;
    });

    widget.onChanged?.call(newValue);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragValue = null;
      _velocity = Offset.zero;
    });

    // Scale down thumb when ending drag
    unawaited(_scaleController.reverse());

    // Hide glass overlay
    unawaited(_thicknessController.reverse());

    widget.onChangeEnd?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveValue = _dragValue ?? widget.value;
    final normalizedValue =
        ((effectiveValue - widget.min) / (widget.max - widget.min))
            .clamp(0.0, 1.0);

    // Performance: Cache color calculations - these allocate on every build
    final activeColor =
        widget.activeColor ?? const Color(0xCCFFFFFF); // alpha: 0.8
    final inactiveColor =
        widget.inactiveColor ?? const Color(0x33FFFFFF); // alpha: 0.2

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth - (widget.thumbRadius * 2);
        final thumbPosition =
            widget.thumbRadius + (trackWidth * normalizedValue);

        // Calculate step size for accessibility increase/decrease
        final step = (widget.max - widget.min) / (widget.divisions ?? 10);
        final increasedValue =
            (widget.value + step).clamp(widget.min, widget.max);
        final decreasedValue =
            (widget.value - step).clamp(widget.min, widget.max);

        // Calculate normalized percentages for semantics
        final normalizedIncreased =
            ((increasedValue - widget.min) / (widget.max - widget.min))
                .clamp(0.0, 1.0);
        final normalizedDecreased =
            ((decreasedValue - widget.min) / (widget.max - widget.min))
                .clamp(0.0, 1.0);

        return Semantics(
          label: widget.label ?? 'Slider',
          value: '${(normalizedValue * 100).round()}%',
          increasedValue: '${(normalizedIncreased * 100).round()}%',
          decreasedValue: '${(normalizedDecreased * 100).round()}%',
          onIncrease: widget.onChanged != null
              ? () {
                  widget.onChanged!(increasedValue);
                }
              : null,
          onDecrease: widget.onChanged != null
              ? () {
                  widget.onChanged!(decreasedValue);
                }
              : null,
          child: GestureDetector(
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: (details) =>
                _handleDragUpdate(details, constraints),
            onHorizontalDragEnd: _handleDragEnd,
            child: SizedBox(
              height: widget.thumbRadius * 2 + 16,
              width: constraints.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track (centered vertically)
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        height: widget.trackHeight,
                        child: Stack(
                          children: [
                            // Full inactive track (background)
                            Positioned.fill(
                              child: _buildTrackGlass(
                                borderRadius: BorderRadius.circular(
                                  widget.trackHeight / 2,
                                ),
                                color: inactiveColor,
                              ),
                            ),

                            // Active track (extends under thumb - visible
                            // through glass)
                            if (normalizedValue > 0)
                              Positioned(
                                left: 0,
                                right: constraints.maxWidth *
                                    (1 - normalizedValue),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(
                                        widget.trackHeight / 2,
                                      ),
                                      right: normalizedValue >= 1.0
                                          ? Radius.circular(
                                              widget.trackHeight / 2,
                                            )
                                          : Radius.zero,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Thumb (iOS 26: positioned slightly DOWN from track center)
                  // Performance: RepaintBoundary isolates thumb animations
                  Positioned(
                    left: thumbPosition - widget.thumbRadius,
                    top: 10.5,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _scaleController,
                          _thicknessController,
                        ]),
                        builder: (context, child) {
                          final scale = _scaleAnimation.value;
                          final thickness = _thicknessAnimation.value;

                          // iOS 26 liquid glass: more dramatic jelly when dragging
                          final jellyTransform = _isDragging
                              ? DraggableIndicatorPhysics.buildJellyTransform(
                                  velocity: _velocity,
                                  maxDistortion:
                                      0.25, // More dramatic than before
                                  velocityScale:
                                      30, // More sensitive to velocity
                                )
                              : Matrix4.identity();

                          return Transform(
                            alignment: Alignment.center,
                            transform: jellyTransform,
                            child: Transform.scale(
                              scale: scale,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Solid thumb
                                  _buildThumbGlass(),

                                  // Glass overlay (appears when dragging)
                                  if (thickness > 0)
                                    Positioned.fill(
                                      child: _buildGlassOverlay(thickness),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackGlass({
    required BorderRadius borderRadius,
    required Color color,
  }) {
    final trackWidget = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );

    final trackShape = LiquidRoundedRectangle(
      borderRadius: widget.trackHeight / 2,
    );
    final trackSettings =
        widget.settings ?? InheritedLiquidGlass.ofOrDefault(context);

    return AdaptiveGlass(
      shape: trackShape,
      settings: trackSettings,
      quality: widget.quality,
      useOwnLayer: widget.useOwnLayer,
      child: trackWidget,
    );
  }

  Widget _buildThumbGlass() {
    // iOS 26: Elongated pill-shaped thumb (wider, more rectangular)
    final thumbWidth = widget.thumbRadius * 2.6; // Very wide for elongated pill
    final thumbHeight = widget.thumbRadius * 1.6; // Shorter height
    final borderRadius = thumbHeight / 2 - 2;

    // iOS 26 behavior: Solid white pill → Transparent glass when dragging
    // At rest: subtle glass on bright white pill
    // When dragging: strong glass effects with transparency
    final glassColor = _isDragging
        ? const Color.from(alpha: 0.1, red: 1, green: 1, blue: 1) // transparent
        : const Color.from(
            alpha: 0.15, red: 1, green: 1, blue: 1); // very subtle tint at rest

    final lightWeightShader = widget.quality.usesLightweightShader;

    // Strong refraction when liquid
    // Skia fallback needs a higher multiplier to match the "pop" of real refraction
    final refractiveIndex = _isDragging
        ? (lightWeightShader ? 1.2 : 1.15)
        : 0.7; // Thin delicate rim at rest

    // Rainbow edges when liquid
    final chromaticAberration =
        _isDragging ? 0.5 : 0.0; // No aberration at rest

    // Thicker glass depth when liquid
    final thickness = _isDragging
        ? (lightWeightShader ? 20.0 : 10.0)
        : 5.0; // Minimal at rest

    // Bright highlights when liquid
    // Skia fallback needs punchier highlights to compensate for lack of backdrop sampling
    final lightIntensity = _isDragging
        ? (lightWeightShader ? 1.5 : 2.0)
        : 0.5; // Subtle lighting at rest

    // Less blur (sharper) when liquid
    final blur = _isDragging ? 0.0 : 2.0;

    final thumbContent = Container(
      width: thumbWidth,
      height: thumbHeight,
      decoration: BoxDecoration(
        // iOS 26: Start opaque white, become transparent when dragging
        // Match the glassColor for consistent appearance
        color: _isDragging
            ? Colors.transparent // invisible when dragging
            : Colors.white.withValues(alpha: 0.85), // Bright white at rest
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _isDragging
            ? null
            : const [
                // Subtle shadow at rest
                BoxShadow(
                  color: _defaultThumbShadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      // Strong glow effect when liquid glass (dragging)
      child: _isDragging
          ? const GlassGlow(
              child: SizedBox.expand(),
            )
          : null,
    );

    // Use liquid glass with dramatic animated properties
    final thumbShape = LiquidRoundedSuperellipse(
      borderRadius: borderRadius,
    );
    final thumbSettings = LiquidGlassSettings(
      glassColor: glassColor,
      refractiveIndex: refractiveIndex,
      thickness: thickness,
      lightIntensity: lightIntensity,
      chromaticAberration: chromaticAberration,
      blur: blur,
      lightAngle: 135,
      ambientStrength:
          _isDragging ? 0.3 : 0.8, // Bright at rest, darker when dragging
    );

    return AdaptiveGlass(
      shape: thumbShape,
      settings: thumbSettings,
      quality: widget.quality,
      useOwnLayer: true, // Thumb always uses its own layer
      allowElevation: false, // Don't darken thumb when inside containers
      child: thumbContent,
    );
  }

  /// Builds the liquid glass overlay that appears during dragging.
  ///
  /// This creates the signature iOS 26 "liquid glass" effect - a clear,
  /// refractive overlay that makes the thumb appear liquid and glassy.
  Widget _buildGlassOverlay(double thickness) {
    // Not used anymore - glass effect is now part of the thumb itself
    return const SizedBox.shrink();
  }
}
