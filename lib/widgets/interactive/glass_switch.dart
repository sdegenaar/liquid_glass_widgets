import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../shared/adaptive_glass.dart';
import '../shared/lightweight_liquid_glass.dart';

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
    this.width = 56.0,
    this.height = 26.0,
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
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
  /// Defaults to 58.0 (iOS 26 pill shape - wider).
  final double width;

  /// Height of the switch.
  ///
  /// Defaults to 32.0 (iOS 26 pill shape).
  final double height;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings (only used when [useOwnLayer] is true).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses backdrop filter rendering.
  /// This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for shader-based glass in static layouts only.
  final GlassQuality quality;

  @override
  State<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<GlassSwitch>
    with TickerProviderStateMixin {
  // Cache default shadow color to avoid allocations
  static const _defaultThumbShadowColor =
      Color(0x33000000); // black.withValues(alpha: 0.2)

  late AnimationController _positionController;
  late AnimationController _thicknessController;
  late Animation<double> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _thicknessAnimation;
  bool _isMovingForward = true; // Track direction of animation

  @override
  void initState() {
    super.initState();

    // Position controller - moves thumb across track
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _positionController,
        curve: Curves.easeInOut,
      ),
    );

    // Subtle scale animation for thumb
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
    ]).animate(_positionController);

    // Thickness controller - controls glass overlay visibility
    // (like glass_bottom_bar)
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

    // Set initial state
    if (widget.value) {
      _positionController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GlassSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // Track direction: true = moving forward (left to right)
      _isMovingForward = widget.value;

      // Animate position
      if (widget.value) {
        unawaited(_positionController.forward());
      } else {
        unawaited(_positionController.reverse());
      }

      // Show glass overlay (like glass_bottom_bar)
      unawaited(
        _thicknessController.forward().then((_) {
          // Auto-hide after animation
          unawaited(_thicknessController.reverse());
        }),
      );
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

  @override
  Widget build(BuildContext context) {
    final thumbSize = widget.height - 4.0;
    final thumbWidth = thumbSize * 1.5; // Actual thumb width
    final trackWidth = widget.width;
    // Fix: Use actual thumb width for travel distance calculation
    final thumbTravelDistance = trackWidth - thumbWidth - 4.0;

    // Performance: Cache color calculations as const to avoid allocation
    final inactiveTrackColor =
        widget.inactiveColor ?? const Color(0x33FFFFFF); // alpha: 0.2
    final activeTrackColor = widget.activeColor ?? Colors.green;

    return GestureDetector(
      onTap: _handleTap,
      // Performance: RepaintBoundary isolates switch animation from parent
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_positionController, _thicknessController]),
          builder: (context, child) {
            final position = _positionAnimation.value;
            final scale = _scaleAnimation.value;
            final thickness = _thicknessAnimation.value;

            // Animate track color between inactive and active
            final trackColor = Color.lerp(
              inactiveTrackColor,
              activeTrackColor,
              position,
            )!;

            // Build the track (pill-shaped, animated color)
            final track = Container(
              width: trackWidth,
              height: widget.height,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            );

            // Build the thumb (stays constant color)
            final thumbOffset = 2.0 + (thumbTravelDistance * position);

            final thumb = Positioned(
              left: thumbOffset,
              top: 2.0,
              child: Transform.scale(
                scale: scale,
                child: _buildThumb(thumbSize),
              ),
            );

            // Build glass overlay (glass_bottom_bar style)
            final overlayWidth = thumbSize * 1.6;
            final overlayHeight = widget.height - 4.0;

            // Expand bounds during animation (like glass_bottom_bar)
            final rect = RelativeRect.lerp(
                  RelativeRect.fill,
                  const RelativeRect.fromLTRB(-8, -8, -8, -8),
                  thickness,
                ) ??
                RelativeRect.fill;

            // Position overlay based on direction:
            // - Moving forward (→): anchor on left edge (trails behind)
            // - Moving backward (←): anchor on right edge (trails behind)
            final overlayLeft = _isMovingForward
                ? thumbOffset // Anchor on left for forward movement
                : thumbOffset +
                    thumbWidth -
                    overlayWidth; // Anchor on right for backward

            final glassOverlay = Positioned(
              left: overlayLeft,
              top: 2.0,
              child: Opacity(
                opacity: thickness > 0 ? 1.0 : 0.0, // Stable mounting
                child: SizedBox(
                  width: overlayWidth,
                  height: overlayHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fromRelativeRect(
                        rect: rect,
                        child: _buildGlassOverlay(
                          overlayWidth,
                          overlayHeight,
                          thickness,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

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

  Widget _buildThumb(double size) {
    // iOS 26: thumb is pill-shaped (wider than tall)
    // Simple knob - no glass effect needed
    final thumbWidth = size * 1.5;
    final thumbHeight = size;

    return Container(
      width: thumbWidth,
      height: thumbHeight,
      decoration: BoxDecoration(
        color: widget.thumbColor,
        borderRadius: BorderRadius.circular(thumbHeight / 2),
        boxShadow: const [
          BoxShadow(
            color: _defaultThumbShadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  /// Builds the glass overlay that appears during switch transitions.
  ///
  /// This overlay creates the signature "liquid glass" effect similar
  /// to Apple's iOS 26 toggle and glass_bottom_bar.
  /// Very clear, white glass that goes above and below the thumb nicely.
  Widget _buildGlassOverlay(double width, double height, double thickness) {
    // Use glass_bottom_bar's exact approach: visibility controlled by thickness
    final overlayShape = LiquidRoundedSuperellipse(
      borderRadius: widget.height,
    );

    final overlayContent = GlassGlow(
      child: SizedBox(
        width: width,
        height: height,
      ),
    );

    if (widget.quality.usesLightweightShader) {
      // Lightweight shader settings (Skia renderer)
      // refractiveIndex controls rim prominence: 0.7 = thin/delicate, 2.0 = bold/heavy
      final lightweightSettings = LiquidGlassSettings(
        visibility: thickness,
        glassColor: const Color.from(
          alpha: .1,
          red: 1,
          green: 1,
          blue: 1,
        ),
        refractiveIndex: 1.2, // Thin delicate rim (iOS 26 aesthetic)
        thickness: 20,
        lightAngle: 135, //
        lightIntensity: 2, // Same as Impeller (calibrated shader)
        blur: 0,
      );

      return LightweightLiquidGlass(
        shape: overlayShape,
        settings: lightweightSettings,
        child: overlayContent,
      );
    } else {
      // Premium shader settings (Impeller renderer)
      // refractiveIndex is used for actual light refraction
      final premiumSettings = LiquidGlassSettings(
        visibility: thickness,
        glassColor: const Color.from(
          alpha: .1,
          red: 1,
          green: 1,
          blue: 1,
        ),
        refractiveIndex: 1.15, // Actual refraction (subtle)
        thickness: 10,
        lightAngle: 120,
        lightIntensity: 2,
        chromaticAberration: .5,
        blur: 0,
      );

      return AdaptiveGlass(
        shape: overlayShape,
        settings: premiumSettings,
        quality: GlassQuality.premium,
        useOwnLayer: true,
        child: overlayContent,
      );
    }
  }
}
