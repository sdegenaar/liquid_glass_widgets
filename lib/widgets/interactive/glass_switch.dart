import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../shared/glass_effect.dart';
import '../shared/inherited_liquid_glass.dart';

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
  late Animation<double> _scaleAnimation;
  late Animation<double> _thicknessAnimation;
  bool _isMovingForward = true; // Track direction of animation
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

    // Subtle scale animation for thumb
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
    ]).animate(_positionController);

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
      // Track direction: true = moving forward (left to right)
      _isMovingForward = widget.value;

      // Animate position
      if (widget.value) {
        unawaited(_positionController.forward());
      } else {
        unawaited(_positionController.reverse());
      }

      // Trigger the liquid pulse bloom (Grow up and then down)
      unawaited(_thicknessController.forward(from: 0.0));
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
    // Inherit quality from parent layer if not explicitly set
    final inherited =
        context.dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>();
    _effectiveQuality =
        widget.quality ?? inherited?.quality ?? GlassQuality.standard;

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

            // Growth/Expansion offsets (Calibrated for proportional wide pill)
            // leadStretch: leads the movement as a high-velocity droplet
            final vExpand = thickness * 10.0;
            final leadStretch = thickness * 16.0;

            final thumbOffset = 2.0 + (thumbTravelDistance * position);

            // Anchor logic:
            // Positive -> Anchor Left, Grow Right.
            // Back -> Anchor Right, Grow Left.
            final thumbLeft =
                _isMovingForward ? thumbOffset : thumbOffset - leadStretch;

            final thumb = Positioned(
              left: thumbLeft,
              top: 2.0 - vExpand,
              child: Transform.scale(
                // Combined scale: Squash for jump + slight Grow for the liquid bloom
                scale: scale * (1.0 + thickness * 0.1),
                child: _buildThumb(
                    thumbSize, thickness, scale, vExpand, leadStretch),
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
      double vExpand, double leadStretch) {
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
                lightAngle: 135,
              )
            : const LiquidGlassSettings(
                glassColor: Color.from(alpha: 0.1, red: 1, green: 1, blue: 1),
                refractiveIndex: 1.15, // Premium sharpness boost
                thickness: 10,
                lightIntensity: 2, // Bold specular highlight
                blur: 0,
                lightAngle: 120, // Synchronized with movement
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
              left: _isMovingForward ? 0 : leadStretch,
              child: materialContent,
            ),

            if (transition > 0.05)
              Positioned(
                left: _isMovingForward ? 0 : leadStretch,
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
