import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // Required for SpringSimulation
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import 'glass_menu_item.dart';

/// A liquid glass context menu that morphs from its trigger button.
///
/// [GlassMenu] implements the iOS 26 "liquid glass" morphing pattern where
/// a button seamlessly transforms into a menu. The same glass container
/// transitions between button and menu states using spring physics.
///
/// ## Features
/// - **True morphing**: Button transforms into menu (not overlay)
/// - **Spring physics**: Critically damped motion (stiffness: 180, damping: 27) - no bounce
/// - **Snappy timing**: iOS 26-accurate speed with no sluggishness
/// - **Liquid swoop**: Subtle 8px downward curve with easeOutCubic timing
/// - **Seamless crossfade**: Button only appears at final 5% to preserve morph illusion
/// - **Dimension interpolation**: Width, height, and border radius morph smoothly
/// - **Position aware**: Menu expands from button position
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

  // iOS 26 Liquid Glass spring physics
  // - Damping: 27.0 for critically damped motion (no bounce/overshoot)
  // - Stiffness: 180.0 for snappy iOS-accurate speed
  // - Critical damping = 2 * sqrt(stiffness * mass) = ~26.83
  final _springDescription = const SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 27.0, // Slightly overdamped for silky-smooth motion
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
    // Capture geometry and screen position
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _triggerSize = renderBox.size;
      _triggerBorderRadius = _triggerSize!.height / 2;

      // Determine alignment based on horizontal screen position
      final position = renderBox.localToGlobal(Offset.zero);
      final screenWidth = MediaQuery.of(context).size.width;

      // If button is on the right half of the screen, align menu to top-right
      if (position.dx > screenWidth / 2) {
        _morphAlignment = Alignment.topRight;
      } else {
        _morphAlignment = Alignment.topLeft;
      }
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
    // No bounce: spring is critically damped
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
          // - Eased curve creates smooth, gravity-like drop when opening
          // - Subtle 8px vertical displacement at peak
          // - No linear interpolation - uses easeOutCubic for fluid motion
          offset: Offset(0, _calculateSwoopOffset(value)),
          child: _buildMorphingContainer(value),
        ),
      ],
    );
  }

  /// Calculates the vertical "swoop" offset for liquid glass morphing.
  ///
  /// Apple's iOS 26 liquid glass uses a subtle downward curve when morphing open,
  /// creating the illusion of liquid "drooping" under its own weight before settling.
  /// Uses easeOutCubic for smooth deceleration.
  double _calculateSwoopOffset(double t) {
    // easeOutCubic: 1 - (1-t)^3
    // Creates smooth deceleration (fast start, slow end)
    final easedValue = 1 - (1 - t) * (1 - t) * (1 - t);

    // 8px peak displacement - subtle but noticeable
    return easedValue * 8.0;
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

    // iOS 26 Crossfade Timing - Studied from actual implementation
    // Key insight: There's a "content gap" during morph where NEITHER content shows
    // This prevents any visual artifacts and keeps focus on the morphing shape

    // Button content: Only when container is nearly button-sized (value < 0.02)
    // This prevents button from flashing in oversized glass container
    final buttonOpacity = (1.0 - (value / 0.02)).clamp(0.0, 1.0);

    // Menu content: Fades in when container is nearly full width (0.7 -> 1.0)
    // iOS 26: Content waits for shape, then reveals quickly
    final menuOpacity = ((value - 0.7) / 0.3).clamp(0.0, 1.0);

    // Use efficient glass settings
    const defaultSettings = LiquidGlassSettings(
      blur: 20,
      thickness: 30,
    );

    // Performance optimization: RepaintBoundary isolates morphing animation
    // from parent widget rebuilds, reducing GPU overhead
    return RepaintBoundary(
      child: GlassContainer(
        useOwnLayer: true,
        settings: widget.glassSettings ?? defaultSettings,
        quality: widget.quality,
        width: currentWidth,
        height: currentHeight, // Constrained during morph, natural when open
        shape: LiquidRoundedSuperellipse(borderRadius: currentBorderRadius),
        clipBehavior: Clip.hardEdge, // Primary clipping layer
        child: Stack(
          alignment: _morphAlignment, // Align internal stack content
          clipBehavior: Clip.hardEdge, // Secondary safety net for overflow
          children: [
            // Button content - ONLY when container is nearly button-sized
            // iOS 26: button never visible during morph, only at absolute end
            if (value < 0.02)
              Opacity(
                opacity: buttonOpacity,
                child: SizedBox(
                  width: _triggerSize!.width, // Use trigger width
                  height: _triggerSize!.height,
                  child: Center(
                    child: widget.triggerBuilder != null
                        ? widget.triggerBuilder!(context, _toggleMenu)
                        : widget.trigger,
                  ),
                ),
              ),

            // Menu content - waits for container to be nearly full width
            // Width-constrained BEFORE layout to prevent overflow
            if (value > 0.65)
              Opacity(
                opacity: menuOpacity,
                child: SizedBox(
                  width: currentWidth, // Force exact container width
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
    );
  }
}
