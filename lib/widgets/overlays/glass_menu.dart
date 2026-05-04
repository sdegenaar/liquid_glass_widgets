import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // Required for SpringSimulation
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../constants/glass_defaults.dart';
import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import '../shared/inherited_liquid_glass.dart';
import 'glass_menu_item.dart';
import '../../theme/glass_theme_helpers.dart';

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
  ///
  /// Typically contains [GlassMenuItem] and [GlassMenuDivider].
  final List<Widget> items;

  /// Width of the expanded menu.
  final double menuWidth;

  /// Border radius of the expanded menu.
  ///
  /// Defaults to 28.0 for a modern rounded look.
  final double menuBorderRadius;

  /// Custom glass settings for the menu container.
  final LiquidGlassSettings? glassSettings;

  /// Rendering quality for the glass effect.
  final GlassQuality? quality;

  /// Liquid stretch factor. Default: 0.5.
  final double stretch;

  /// Scale factor applied on touch. Default: 1.02.
  final double interactionScale;

  /// The resistance factor to apply to the drag offset.
  /// Higher values make the drag feel "stickier". Default: 0.08.
  final double stretchResistance;

  /// The axis to constrain the stretch to. If null, stretches in both axes.
  final Axis? stretchAxis;

  /// Whether to allow stretch in the positive X direction (Right).
  /// If null, automatically determined by menu position.
  final bool? allowPositiveXStretch;

  /// Whether to allow stretch in the negative X direction (Left).
  /// If null, automatically determined by menu position.
  final bool? allowNegativeXStretch;

  /// Whether to allow stretch in the positive Y direction (Down).
  /// If null, automatically determined by menu position.
  final bool? allowPositiveYStretch;

  /// Whether to allow stretch in the negative Y direction (Up).
  /// If null, automatically determined by menu position.
  final bool? allowNegativeYStretch;

  /// Whether to show glow/glare on touch for tactile feedback. Default: true.
  final bool enableInteractionGlow;

  /// Custom color for the touch interaction glow.
  final Color? glowColor;

  /// Radius of the touch interaction glow. Default: 0.6.
  final double glowRadius;

  /// Creates a liquid glass menu.
  const GlassMenu({
    super.key,
    this.trigger,
    this.triggerBuilder,
    required this.items,
    this.menuWidth = 200,
    this.menuBorderRadius = 32.0,
    this.glassSettings,
    this.quality,
    this.stretch = 0.5,
    this.interactionScale = 1.02,
    this.stretchResistance = 0.08,
    this.stretchAxis,
    this.allowPositiveXStretch,
    this.allowNegativeXStretch,
    this.allowPositiveYStretch,
    this.allowNegativeYStretch,
    this.enableInteractionGlow = true,
    this.glowColor,
    this.glowRadius = 0.6,
  }) : assert(trigger != null || triggerBuilder != null,
            'Either trigger or triggerBuilder must be provided');

  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends State<GlassMenu>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final AnimationController _animationController;
  late final ScrollController _scrollController;
  Size? _triggerSize;
  double? _triggerBorderRadius;
  int? _hoveredIndex;
  bool _isDragging = false;

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
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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

    // Determine alignment based on screen position
    // This ensures menu doesn't overflow screen edges
    final position = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? double.infinity;
    final screenHeight = mediaQuery?.size.height ?? double.infinity;

    // Calculate menu height for vertical boundary check
    final menuHeight = _calculateMenuHeight();

    // Horizontal alignment: left vs right half
    final isRightHalf = screenWidth.isFinite && position.dx > screenWidth / 2;

    // Vertical alignment: check if menu would overflow bottom
    final spaceBelow = screenHeight.isFinite
        ? screenHeight - (position.dy + _triggerSize!.height)
        : double.infinity;
    final spaceAbove = screenHeight.isFinite ? position.dy : double.infinity;

    // Prefer downward opening unless insufficient space
    final shouldFlipVertical =
        spaceBelow < menuHeight && spaceAbove > menuHeight;

    // Determine final alignment based on both axes
    if (shouldFlipVertical) {
      _morphAlignment =
          isRightHalf ? Alignment.bottomRight : Alignment.bottomLeft;
    } else {
      _morphAlignment = isRightHalf ? Alignment.topRight : Alignment.topLeft;
    }

    _overlayController.show();
    _runSpring(1.0);
  }

  void _closeMenu() {
    setState(() {
      _hoveredIndex = null;
      _isDragging = false;
    });
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
      (sum, item) => sum + _getItemHeight(item),
    );

    // Add vertical padding (8px top + 8px bottom = 16px total)
    // plus vertical gaps between items (2px each)
    final gaps = (widget.items.length - 1) * 2.0;
    return itemHeights + 16.0 + gaps;
  }

  Widget _buildMorphingContainer(double value) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

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
          lightAngle: GlassDefaults.lightAngle, // Apple iOS 26 standard
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
        child: LiquidStretch(
          stretch: widget.stretch,
          interactionScale: widget.interactionScale,
          resistance: widget.stretchResistance,
          axis: widget.stretchAxis,
          suppressInteractionOnChildren: false,
          // Constrain stretch to 'Down' and 'Away from screen edge' by default,
          // but allow explicit user overrides.
          allowPositiveX:
              widget.allowPositiveXStretch ?? (_morphAlignment.x < 0),
          allowNegativeX:
              widget.allowNegativeXStretch ?? (_morphAlignment.x > 0),
          allowPositiveY:
              widget.allowPositiveYStretch ?? (_morphAlignment.y < 0),
          allowNegativeY:
              widget.allowNegativeYStretch ?? (_morphAlignment.y > 0),
          child: GlassGlow(
            enabled: widget.enableInteractionGlow,
            glowColor: widget.glowColor ?? Colors.white.withValues(alpha: 0.15),
            glowRadius: widget.glowRadius,
            glowBlurRadius: 40,
            clipper: ShapeBorderClipper(
              shape:
                  LiquidRoundedSuperellipse(borderRadius: currentBorderRadius),
            ),
            child: GlassContainer(
              useOwnLayer: true,
              settings: effectiveSettings,
              quality: effectiveQuality,
              allowElevation:
                  false, // Menu is overlay - don't darken when outside parent
              width: currentWidth,
              height:
                  currentHeight, // Constrained during morph, natural when open
              shape:
                  LiquidRoundedSuperellipse(borderRadius: currentBorderRadius),
              clipBehavior:
                  Clip.none, // High-fidelity clipping handled by AdaptiveGlass
              child: Stack(
                alignment: _morphAlignment, // Align internal stack content
                clipBehavior:
                    Clip.none, // Prevent double-clip artifacts during stretch
                children: [
                  // Menu content - waits for container to be nearly full width
                  if (value > 0.65)
                    Opacity(
                      opacity: menuOpacity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Sliding selection pill (background)
                          if (_hoveredIndex != null)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutCubic,
                              left: 12,
                              right: 12,
                              top: _getItemOffset(_hoveredIndex!),
                              height:
                                  _getItemHeight(widget.items[_hoveredIndex!]),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0x3DFFFFFF), // ~24% white
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(
                                        0x0DFFFFFF), // 5% white border
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          Listener(
                            onPointerDown: (event) {
                              setState(() {
                                _isDragging = true;
                                _updateHoveredIndex(event.localPosition);
                              });
                            },
                            onPointerMove: (event) {
                              if (_isDragging) {
                                setState(() =>
                                    _updateHoveredIndex(event.localPosition));
                              }
                            },
                            onPointerUp: (event) {
                              if (_isDragging && _hoveredIndex != null) {
                                final item = widget.items[_hoveredIndex!];
                                if (item is GlassMenuItem) {
                                  item.onTap();
                                }
                                _closeMenu();
                              }
                              setState(() {
                                _isDragging = false;
                                _hoveredIndex = null;
                              });
                            },
                            onPointerCancel: (_) {
                              setState(() {
                                _isDragging = false;
                                _hoveredIndex = null;
                              });
                            },
                            child: SizedBox(
                              width:
                                  currentWidth, // Force exact container width
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  physics:
                                      const ClampingScrollPhysics(), // iOS-style scrolling
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (var i = 0;
                                          i < widget.items.length;
                                          i++) ...[
                                        _buildItem(i),
                                        if (i < widget.items.length - 1)
                                          const SizedBox(height: 2),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  double _getItemHeight(Widget item) {
    if (item is GlassMenuItem) return item.height;
    if (item is GlassMenuDivider) return item.height;
    return 44.0;
  }

  double _getItemOffset(int index) {
    double offset = 12.0; // Top padding
    for (int i = 0; i < index; i++) {
      offset += _getItemHeight(widget.items[i]) + 2.0; // height + 2px gap
    }
    return offset;
  }

  Widget _buildItem(int i) {
    final item = widget.items[i];
    if (item is GlassMenuItem) {
      return GlassMenuItem(
        key: item.key,
        title: item.title,
        subtitle: item.subtitle,
        icon: item.icon,
        isDestructive: item.isDestructive,
        trailing: item.trailing,
        height: item.height,
        isSelected: _hoveredIndex == i,
        isPressed: _isDragging && _hoveredIndex == i,
        enabled: false, // Parent handles interaction
        onTap: item.onTap,
      );
    }
    return item;
  }

  void _updateHoveredIndex(Offset localPosition) {
    final y = localPosition.dy + _scrollController.offset;

    double currentOffset = 8.0;
    int? detectedIndex;

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final itemHeight = _getItemHeight(item);

      if (y >= currentOffset && y <= currentOffset + itemHeight) {
        // Only select interactive items
        if (item is GlassMenuItem) {
          detectedIndex = i;
        }
        break;
      }
      currentOffset += itemHeight + 2.0; // height + 2px gap
    }

    _hoveredIndex = detectedIndex;
  }
}
