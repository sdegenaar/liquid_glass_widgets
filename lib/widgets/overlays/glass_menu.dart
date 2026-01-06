import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // Required for SpringSimulation
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import '../shared/inherited_liquid_glass.dart';
import 'glass_menu_item.dart';

/// A liquid glass context menu that morphs from its trigger button.
///
/// [GlassMenu] implements the iOS 26 "liquid glass" morphing pattern where
/// a button seamlessly transforms into a menu. The same glass container
/// transitions between button and menu states using spring physics.
///
/// ## Features
/// - **True morphing**: Button transforms into menu (not overlay)
/// - **Smooth spring physics**: Gentle settle with no harsh bounces (stiffness: 300, damping: 24)
/// - **Liquid swoop**: Subtle 5px parabolic arc for seamless down-and-up motion
/// - **Seamless crossfade**: Button only appears at final 5% to preserve morph illusion
/// - **Dimension interpolation**: Width, height, and border radius morph smoothly
/// - **Position aware**: Menu expands from button position
/// - **Settings inheritance**: Inherits parent layer settings like GlassCard (thin rim by default)
/// - **No button animation**: Trigger button remains static, only shape morphs
class GlassMenu extends StatefulWidget {
  /// The widget that triggers the menu.
  ///
  /// If provided, this widget will be wrapped in a [GestureDetector] to handle
  /// taps. Use this for simple, non-interactive triggers like Icons or Text.
  ///
  /// If your trigger is interactive (like a [GlassButton]), use [triggerBuilder]
  /// instead to manually handle the tap event.
  final Widget? trigger;

  /// A builder for the trigger widget that provides access to the menu toggle callback.
  ///
  /// Use this when your trigger widget handles its own interactions (e.g., a [GlassButton]
  /// or [IconButton]).
  ///
  /// Example:
  /// ```dart
  /// GlassMenu(
  ///   triggerBuilder: (context, toggle) => GlassButton(
  ///     onTap: toggle,
  ///     child: Text('Open'),
  ///   ),
  ///   ...
  /// )
  /// ```
  final Widget Function(BuildContext context, VoidCallback toggleMenu)?
      triggerBuilder;

  /// The list of items to display in the menu.
  final List<GlassMenuItem> items;

  /// Width of the expanded menu.
  final double menuWidth;

  /// Border radius of the expanded menu.
  ///
  /// Defaults to 16.0 to match iOS 26 liquid glass menus.
  final double menuBorderRadius;

  /// Custom glass settings for the menu container.
  final LiquidGlassSettings? glassSettings;

  /// Rendering quality for the glass effect.
  final GlassQuality quality;

  /// Creates a liquid glass menu.
  const GlassMenu({
    super.key,
    this.trigger,
    this.triggerBuilder,
    required this.items,
    this.menuWidth = 200,
    this.menuBorderRadius = 16.0,
    this.glassSettings,
    this.quality = GlassQuality.standard,
  }) : assert(trigger != null || triggerBuilder != null,
            'Either trigger or triggerBuilder must be provided');

  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends State<GlassMenu>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final AnimationController _animationController;
  Size? _triggerSize;
  double? _triggerBorderRadius;

  // iOS 26 Liquid Glass smooth spring physics
  // Gentle, fluid motion with subtle overshoot - NOT harsh bounces
  //
  // Response: ~0.35s (smooth, not too fast)
  // DampingFraction: 0.7 (slightly underdamped = gentle settle, no harsh bounce)
  // Result: Seamless liquid feel that complements the swoop curve
  //
  // Conversion to Flutter SpringSimulation:
  // - stiffness: 300 (smooth, not too snappy)
  // - damping: 2 * 0.7 * sqrt(300) ≈ 24.2
  final _springDescription = const SpringDescription(
    mass: 1.0,
    stiffness: 300.0, // Smooth motion (not too fast)
    damping: 24.0, // Gentle settle (no harsh bounce)
  );

  Alignment _morphAlignment = Alignment.topLeft;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this);
    _animationController.addListener(() {
      // Rebuild on each spring physics tick
      if (mounted) setState(() {});

      // Auto-hide when spring settles back to closed state
      if (_overlayController.isShowing &&
          _animationController.value <= 0.001 &&
          _animationController.status != AnimationStatus.forward) {
        _overlayController.hide();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMenuOpen =
        _overlayController.isShowing && _animationController.value > 0.05;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Stack(
        children: [
          // Original trigger button (hidden when menu is morphing)
          Opacity(
            opacity: isMenuOpen ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: isMenuOpen,
              child: widget.triggerBuilder != null
                  ? widget.triggerBuilder!(context, _toggleMenu)
                  : GestureDetector(
                      onTap: _toggleMenu,
                      child: widget.trigger,
                    ),
            ),
          ),

          // Overlay portal for morphing animation
          OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: _buildMorphingOverlay,
          ),
        ],
      ),
    );
  }

  void _runSpring(double target) {
    final simulation = SpringSimulation(
      _springDescription,
      _animationController.value,
      target,
      0.0, // Initial velocity (could add velocity for swipe gestures)
    );
    _animationController.animateWith(simulation);
  }

  void _toggleMenu() {
    if (_overlayController.isShowing && _animationController.value > 0.1) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    // Capture geometry and screen position for morphing
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // Safety: Cannot open menu if render box is not ready
      return;
    }

    _triggerSize = renderBox.size;
    _triggerBorderRadius = _triggerSize!.height / 2;

    // Determine alignment based on horizontal screen position
    // This ensures menu doesn't overflow screen edges
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth =
        MediaQuery.maybeOf(context)?.size.width ?? double.infinity;

    // If button is on the right half of the screen, align menu to top-right
    // Otherwise align to top-left (default)
    if (screenWidth.isFinite && position.dx > screenWidth / 2) {
      _morphAlignment = Alignment.topRight;
    } else {
      _morphAlignment = Alignment.topLeft;
    }

    _overlayController.show();
    _runSpring(1.0);
  }

  void _closeMenu() {
    _runSpring(0.0);
  }

  Widget _buildMorphingOverlay(BuildContext context) {
    if (_triggerSize == null) return const SizedBox.shrink();

    // Clamp animation value to prevent overshoot artifacts
    final value = _animationController.value.clamp(0.0, 1.0);

    return Stack(
      children: [
        // Backdrop barrier (only active when menu is significantly open)
        if (value > 0.3)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeMenu,
              child: Container(
                color: Colors.black
                    .withValues(alpha: 0.0), // Invisible but tappable
              ),
            ),
          ),

        // Morphing glass container
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          // anchor based on calculated alignment
          targetAnchor: _morphAlignment,
          followerAnchor: _morphAlignment,
          // iOS 26 "liquid swoop" offset:
          // - Parabolic curve creates smooth, gravity-like arc
          // - Subtle 5px vertical displacement at peak (t=0.5)
          // - Seamless in both directions (opening and closing)
          offset: Offset(0, _calculateSwoopOffset(value)),
          child: _buildMorphingContainer(value),
        ),
      ],
    );
  }

  /// Calculates the vertical "swoop" offset for liquid glass morphing.
  ///
  /// iOS 26 uses a gentle parabolic curve that creates a subtle "liquid droop"
  /// effect during morphing. This is NOT a bounce - it's a smooth arc that
  /// complements the spring physics for a seamless feel.
  ///
  /// The curve peaks at mid-animation (t=0.5) and smoothly returns to zero
  /// at both ends, creating a natural "swoop down and up" motion.
  double _calculateSwoopOffset(double t) {
    // Parabolic curve: peaks at t=0.5, zero at t=0 and t=1
    // This creates a smooth down-and-up arc without harsh direction changes
    // Formula: -4 * (t - 0.5)² + 1, scaled by amplitude
    final parabola = 1.0 - 4.0 * (t - 0.5) * (t - 0.5);

    // Gentle 5px peak displacement for subtle liquid feel
    // Opening: swoops down then up (parabola is always positive)
    // Closing: same smooth curve in reverse (no jarring direction change)
    return parabola * 5.0;
  }

  /// Calculates the total height of the menu content.
  ///
  /// Sums up all menu item heights plus padding to determine the target height
  /// for the morphing animation.
  double _calculateMenuHeight() {
    // Sum all menu item heights (each defaults to 44.0)
    final itemHeights = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + item.height,
    );

    // Add vertical padding (8px top + 8px bottom = 16px total)
    return itemHeights + 16.0;
  }

  Widget _buildMorphingContainer(double value) {
    // Calculate menu height by measuring its natural size
    // This is necessary for proper height interpolation during morph
    final menuHeight = _calculateMenuHeight();

    // iOS 26: Width always interpolates smoothly throughout animation
    // Height goes natural at 85% to prevent any overflow from content
    final currentWidth =
        lerpDouble(_triggerSize!.width, widget.menuWidth, value)!;

    final currentHeight = value < 0.85
        ? lerpDouble(_triggerSize!.height, menuHeight, value)!
        : null; // Natural height when nearly expanded (prevents overflow)

    // Interpolate border radius: circular button -> rounded menu
    final currentBorderRadius = lerpDouble(
      _triggerBorderRadius ?? 16.0,
      widget.menuBorderRadius,
      value,
    )!;

    // iOS 26 Crossfade Timing + Material Fade
    // Problem: Empty morphing container still visible (glowing blob) during closing
    // Solution: Fade glass material opacity as container shrinks
    //
    // Menu content: Fades in 0.7→1.0 opening, exits cleanly when closing
    final menuOpacity = ((value - 0.7) / 0.3).clamp(0.0, 1.0);

    // Glass container opacity: Fully visible when menu open, fades during closing
    // - value > 0.3: Fully visible (1.0)
    // - value 0.3→0: Fades out to transparent
    // - Result: No "empty glowing blob" - seamless fade to real button
    final containerOpacity = (value / 0.3).clamp(0.0, 1.0);

    // Inherit settings from context (like GlassCard/GlassContainer)
    // If user provides custom settings, use those. Otherwise, check for inherited
    // settings from parent layer. If none, use subtle overlay defaults.
    // This matches the pattern used by all other glass widgets.
    final inheritedSettings = InheritedLiquidGlass.of(context);
    final effectiveSettings = widget.glassSettings ??
        inheritedSettings ??
        const LiquidGlassSettings(
          blur: 10,
          thickness: 10,
          glassColor: Color.fromRGBO(255, 255, 255, 0.12),
          lightAngle: 135,
          lightIntensity: 0.7,
          ambientStrength: 0.4,
          saturation: 1.2,
          refractiveIndex: 0.7, // Thin rim - iOS 26 delicate aesthetic
          chromaticAberration: 0.0,
        );

    // Performance optimization: RepaintBoundary isolates morphing animation
    // from parent widget rebuilds, reducing GPU overhead
    return RepaintBoundary(
      child: Opacity(
        opacity: containerOpacity, // Fade entire container during closing
        child: ClipRRect(
          borderRadius: BorderRadius.circular(currentBorderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: effectiveSettings.blur,
              sigmaY: effectiveSettings.blur,
            ),
            child: GlassContainer(
              useOwnLayer: true,
              settings: effectiveSettings,
              quality: widget.quality,
              allowElevation:
                  false, // Menu is overlay - don't darken when outside parent
              width: currentWidth,
              height:
                  currentHeight, // Constrained during morph, natural when open
              shape:
                  LiquidRoundedSuperellipse(borderRadius: currentBorderRadius),
              clipBehavior: Clip.antiAlias, // Smooth anti-aliased edges
              child: Stack(
                alignment: _morphAlignment, // Align internal stack content
                clipBehavior:
                    Clip.antiAlias, // Smooth clipping for overflow protection
                children: [
                  // Menu content - waits for container to be nearly full width
                  // Width-constrained BEFORE layout to prevent overflow
                  //
                  // NOTE: We do NOT render the button inside this container during closing
                  // because it would create double-glass (container glass + button glass).
                  // The real trigger button (outside overlay) becomes visible at value < 0.05
                  if (value > 0.65)
                    Opacity(
                      opacity: menuOpacity,
                      child: SizedBox(
                        width: currentWidth, // Force exact container width
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          child: SingleChildScrollView(
                            physics:
                                const ClampingScrollPhysics(), // iOS-style scrolling
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.items.map((item) {
                                return GlassMenuItem(
                                  key: item.key,
                                  title: item.title,
                                  icon: item.icon,
                                  isDestructive: item.isDestructive,
                                  trailing: item.trailing,
                                  height: item.height,
                                  onTap: () {
                                    item.onTap();
                                    _closeMenu();
                                  },
                                );
                              }).toList(),
                            ),
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
    );
  }
}
