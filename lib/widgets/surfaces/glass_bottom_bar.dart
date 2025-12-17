// Using deprecated Colors.withOpacity for backwards compatibility with
// existing code patterns in the codebase.
// ignore_for_file: deprecated_member_use

// Implementation inspired by example code in the liquid_glass_renderer package
// by whynotmake-it team (https://github.com/whynotmake-it/flutter_liquid_glass).
// Used under MIT License.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';
import '../interactive/glass_button.dart';
import '../shared/glass_interactive_indicator.dart';

/// A glass morphism bottom navigation bar following Apple's design patterns.
///
/// [GlassBottomBar] provides a sophisticated bottom navigation bar with
/// draggable indicator, jelly physics, rubber band resistance, and seamless
/// glass blending. It supports iOS-style drag-to-switch tabs with
/// velocity-based snapping and organic squash/stretch animations.
///
/// ## Key Features
///
/// - **Draggable Indicator**: Swipe between tabs with smooth spring animations
/// - **Velocity-Based Snapping**: Flick quickly to jump multiple tabs
/// - **Rubber Band Resistance**: iOS-style overdrag behavior at edges
/// - **Jelly Physics**: Organic squash and stretch effects during movement
/// - **Per-Tab Glow Effects**: Customizable glow colors for each tab
/// - **Icon Thickness Effect**: Optional shadow halo around unselected icons
/// - **Seamless Glass Blending**: Uses [LiquidGlassBlendGroup] for smooth
/// transitions
///
/// ## Usage
///
/// ### Basic Usage
/// ```dart
/// LiquidGlassLayer(
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 3,
///     refractiveIndex: 1.59,
///   ),
///   child: Scaffold(
///     body: _pages[_selectedIndex],
///     bottomNavigationBar: GlassBottomBar(
///       tabs: [
///         GlassBottomBarTab(
///           label: 'Home',
///           icon: CupertinoIcons.home,
///           selectedIcon: CupertinoIcons.home_fill,
///           glowColor: Colors.blue,
///         ),
///         GlassBottomBarTab(
///           label: 'Search',
///           icon: CupertinoIcons.search,
///           glowColor: Colors.purple,
///         ),
///         GlassBottomBarTab(
///           label: 'Profile',
///           icon: CupertinoIcons.person,
///           selectedIcon: CupertinoIcons.person_fill,
///           glowColor: Colors.pink,
///         ),
///       ],
///       selectedIndex: _selectedIndex,
///       onTabSelected: (index) => setState(() => _selectedIndex = index),
///     ),
///   ),
/// )
/// ```
///
/// ### With Extra Button
/// ```dart
/// GlassBottomBar(
///   tabs: [...],
///   selectedIndex: _selectedIndex,
///   onTabSelected: (index) => setState(() => _selectedIndex = index),
///   extraButton: GlassBottomBarExtraButton(
///     icon: CupertinoIcons.add,
///     label: 'Create',
///     onTap: () => _showCreateDialog(),
///     size: 64,
///   ),
/// )
/// ```
///
/// ### Custom Styling
/// ```dart
/// GlassBottomBar(
///   tabs: [...],
///   selectedIndex: _selectedIndex,
///   onTabSelected: (index) => setState(() => _selectedIndex = index),
///   barHeight: 72,
///   spacing: 12,
///   horizontalPadding: 24,
///   selectedIconColor: Colors.white,
///   unselectedIconColor: Colors.white.withOpacity(0.6),
///   iconSize: 28,
///   textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
///   glassSettings: LiquidGlassSettings(
///     thickness: 40,
///     blur: 5,
///     refractiveIndex: 1.7,
///   ),
/// )
/// ```
///
/// ### Without Draggable Indicator
/// ```dart
/// GlassBottomBar(
///   tabs: [...],
///   selectedIndex: _selectedIndex,
///   onTabSelected: (index) => setState(() => _selectedIndex = index),
///   showIndicator: false,
/// )
/// ```
class GlassBottomBar extends StatefulWidget {
  /// Creates a glass bottom navigation bar.
  const GlassBottomBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    super.key,
    this.extraButton,
    this.spacing = 8,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.barHeight = 64,
    this.barBorderRadius = 32,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.blendAmount = 10,
    this.glassSettings,
    this.showIndicator = true,
    this.indicatorColor,
    this.indicatorSettings,
    this.selectedIconColor = Colors.white,
    this.unselectedIconColor = Colors.white,
    this.iconSize = 24,
    this.textStyle,
    this.glowDuration = const Duration(milliseconds: 300),
    this.glowBlurRadius = 32,
    this.glowSpreadRadius = 8,
    this.glowOpacity = 0.6,
    this.quality = GlassQuality.premium,
  });

  // ===========================================================================
  // Tab Configuration
  // ===========================================================================

  /// List of tabs to display in the bottom bar.
  ///
  /// Each tab requires a label and icon. Optionally specify a selectedIcon
  /// for a different appearance when selected, and a glowColor for the
  /// animated glow effect.
  final List<GlassBottomBarTab> tabs;

  /// Index of the currently selected tab.
  ///
  /// Must be between 0 and tabs.length - 1.
  final int selectedIndex;

  /// Called when a tab is selected.
  ///
  /// Provides the index of the newly selected tab. Use this to update
  /// your state and switch between pages.
  final ValueChanged<int> onTabSelected;

  /// Optional extra button displayed to the right of the tab bar.
  ///
  /// Typically used for a primary action like "Create", "Add", or "Compose".
  /// The button is rendered as a [GlassButton] and inherits the glass settings.
  final GlassBottomBarExtraButton? extraButton;

  // ===========================================================================
  // Layout Properties
  // ===========================================================================

  /// Spacing between the tab bar and extra button.
  ///
  /// Only applies when [extraButton] is provided.
  /// Defaults to 8.
  final double spacing;

  /// Horizontal padding around the entire bottom bar content.
  ///
  /// Defaults to 20.
  final double horizontalPadding;

  /// Vertical padding above and below the bottom bar content.
  ///
  /// Defaults to 20.
  final double verticalPadding;

  /// Height of the tab bar.
  ///
  /// Defaults to 64.
  final double barHeight;

  /// Border radius of the tab bar.
  ///
  /// Defaults to 32 for a pill-shaped appearance.
  final double barBorderRadius;

  /// Internal padding of the tab bar.
  ///
  /// Controls spacing between the bar edges and the tab icons.
  /// Defaults to 4px horizontal padding.
  final EdgeInsetsGeometry tabPadding;

  /// Blend amount for glass surfaces.
  ///
  /// Higher values create smoother blending between the tab bar and extra
  /// button.
  /// Passed to [LiquidGlassBlendGroup].
  /// Defaults to 10.
  final double blendAmount;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings for the bottom bar.
  ///
  /// If null, uses optimized defaults for bottom navigation bars:
  /// - thickness: 30
  /// - blur: 3
  /// - chromaticAberration: 0.3
  /// - lightIntensity: 0.6
  /// - refractiveIndex: 1.59
  /// - saturation: 0.7
  /// - ambientStrength: 1
  /// - lightAngle: 0.25 * π
  /// - glassColor: Colors.white24
  final LiquidGlassSettings? glassSettings;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.premium] since bottom bars are typically static
  /// surfaces at the bottom of the screen where premium quality looks best.
  ///
  /// Use [GlassQuality.standard] if the bottom bar will be used in a scrollable
  /// context.
  final GlassQuality quality;

  // ===========================================================================
  // Indicator Properties
  // ===========================================================================

  /// Whether to show the draggable indicator.
  ///
  /// When true, displays a glass indicator behind the selected tab that can
  /// be dragged to switch tabs. When false, only shows tab icons and labels.
  /// Defaults to true.
  final bool showIndicator;

  /// Color of the subtle indicator shown when not being dragged.
  ///
  /// If null, defaults to a semi-transparent color from the theme.
  final Color? indicatorColor;

  /// Glass settings for the draggable indicator.
  ///
  /// If null, uses optimized defaults for the indicator:
  /// - glassColor: Color.from(alpha: 0.1, red: 1, green: 1, blue: 1)
  /// - saturation: 1.5
  /// - refractiveIndex: 1.15
  /// - thickness: 20
  /// - lightIntensity: 2
  /// - chromaticAberration: 0.5
  /// - blur: 0
  final LiquidGlassSettings? indicatorSettings;

  // ===========================================================================
  // Tab Style Properties
  // ===========================================================================

  /// Color of the icon when a tab is selected.
  ///
  /// Defaults to [Colors.white].
  final Color selectedIconColor;

  /// Color of the icon when a tab is not selected.
  ///
  /// Defaults to [Colors.white].
  final Color unselectedIconColor;

  /// Size of the tab icons.
  ///
  /// Defaults to 24.
  final double iconSize;

  /// Text style for tab labels.
  ///
  /// If null, uses default style with fontSize 11, and fontWeight that
  /// changes based on selection (w600 for selected, w500 for unselected).
  final TextStyle? textStyle;

  // ===========================================================================
  // Glow Effect Properties
  // ===========================================================================

  /// Duration of the glow animation when selecting a tab.
  ///
  /// Defaults to 300 milliseconds.
  final Duration glowDuration;

  /// Blur radius of the glow effect.
  ///
  /// Larger values create a softer, more diffuse glow.
  /// Defaults to 32.
  final double glowBlurRadius;

  /// Spread radius of the glow effect.
  ///
  /// Controls how far the glow extends from the icon.
  /// Defaults to 8.
  final double glowSpreadRadius;

  /// Opacity of the glow effect when a tab is selected.
  ///
  /// Value between 0.0 (invisible) and 1.0 (fully opaque).
  /// Defaults to 0.6.
  final double glowOpacity;

  @override
  State<GlassBottomBar> createState() => _GlassBottomBarState();
}

class _GlassBottomBarState extends State<GlassBottomBar> {
  // Cache default glass color and settings to avoid allocations on every build
  static const _defaultGlassColor = Color(0x3DFFFFFF); // Colors.white24
  static const _defaultLightAngle = 0.7853981633974483; // 0.25 * pi
  static const _defaultGlassSettings = LiquidGlassSettings(
    thickness: 30,
    blur: 3,
    chromaticAberration: 0.3,
    lightIntensity: 0.6,
    refractiveIndex: 1.59,
    saturation: 0.7,
    ambientStrength: 1,
    lightAngle: _defaultLightAngle,
    glassColor: _defaultGlassColor,
  );

  @override
  Widget build(BuildContext context) {
    // Use custom glass settings or cached defaults for bottom bars
    final glassSettings = widget.glassSettings ?? _defaultGlassSettings;

    return LiquidGlassLayer(
      settings: glassSettings,
      fake: widget.quality.usesBackdropFilter,
      child: LiquidGlassBlendGroup(
        blend: widget.blendAmount,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: widget.verticalPadding,
          ),
          child: Row(
            spacing: widget.spacing,
            children: [
              // Main tab bar with draggable indicator
              Expanded(
                child: _TabIndicator(
                  quality: widget.quality,
                  visible: widget.showIndicator,
                  tabIndex: widget.selectedIndex,
                  tabCount: widget.tabs.length,
                  indicatorColor: widget.indicatorColor,
                  indicatorSettings: widget.indicatorSettings,
                  onTabChanged: widget.onTabSelected,
                  barHeight: widget.barHeight,
                  barBorderRadius: widget.barBorderRadius,
                  tabPadding: widget.tabPadding,
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.tabs.length; i++)
                        Expanded(
                          child: RepaintBoundary(
                            child: _BottomBarTab(
                              tab: widget.tabs[i],
                              selected: widget.selectedIndex == i,
                              selectedIconColor: widget.selectedIconColor,
                              unselectedIconColor: widget.unselectedIconColor,
                              iconSize: widget.iconSize,
                              textStyle: widget.textStyle,
                              glowDuration: widget.glowDuration,
                              glowBlurRadius: widget.glowBlurRadius,
                              glowSpreadRadius: widget.glowSpreadRadius,
                              glowOpacity: widget.glowOpacity,
                              onTap: () => widget.onTabSelected(i),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Optional extra button
              if (widget.extraButton != null)
                _ExtraButton(
                  config: widget.extraButton!,
                  quality: widget.quality,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration for a tab in [GlassBottomBar].
///
/// Each tab displays an icon and label. Optionally provide a different icon
/// for the selected state and a glow color for the selection animation.
class GlassBottomBarTab {
  /// Creates a bottom bar tab configuration.
  const GlassBottomBarTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.glowColor,
    this.thickness,
  });

  /// Label text displayed below the icon.
  final String label;

  /// Icon displayed when the tab is not selected.
  ///
  /// Also used when selected if [selectedIcon] is not provided.
  final IconData icon;

  /// Icon displayed when the tab is selected.
  ///
  /// If null, uses [icon] for both selected and unselected states.
  final IconData? selectedIcon;

  /// Color of the animated glow effect when this tab is selected.
  ///
  /// If null, no glow effect is shown for this tab.
  final Color? glowColor;

  /// Thickness of the icon shadow halo effect.
  ///
  /// When provided, creates a shadow halo around the icon for emphasis.
  /// Only visible on unselected tabs, or selected tabs without a
  /// [selectedIcon].
  /// Typical values are between 0.5 and 2.0.
  final double? thickness;
}

/// Configuration for the extra button in [GlassBottomBar].
///
/// The extra button is rendered as a [GlassButton] and typically used for
/// primary actions like creating new content.
class GlassBottomBarExtraButton {
  /// Creates an extra button configuration.
  const GlassBottomBarExtraButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.size = 64,
  });

  /// Icon displayed in the button.
  final IconData icon;

  /// Callback when the button is tapped.
  final VoidCallback onTap;

  /// Accessibility label for the button.
  final String label;

  /// Width and height of the button.
  ///
  /// Defaults to 64 to match the default bar height.
  final double size;
}

// =============================================================================
// Internal Widgets
// =============================================================================

/// Internal widget that renders a single tab.
class _BottomBarTab extends StatelessWidget {
  const _BottomBarTab({
    required this.tab,
    required this.selected,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.iconSize,
    required this.textStyle,
    required this.glowDuration,
    required this.glowBlurRadius,
    required this.glowSpreadRadius,
    required this.glowOpacity,
    required this.onTap,
  });

  final GlassBottomBarTab tab;
  final bool selected;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final double iconSize;
  final TextStyle? textStyle;
  final Duration glowDuration;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final double glowOpacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? selectedIconColor : unselectedIconColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: tab.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with optional glow effect
              ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Animated glow effect (if glowColor is provided)
                    if (tab.glowColor != null)
                      Positioned(
                        top: -24,
                        right: -24,
                        left: -24,
                        bottom: -24,
                        child: RepaintBoundary(
                          child: AnimatedContainer(
                            duration: glowDuration,
                            transformAlignment: Alignment.center,
                            curve: Curves.easeOutCirc,
                            transform: selected
                                ? Matrix4.identity()
                                : (Matrix4.identity()
                                  ..scale(0.4)
                                  ..rotateZ(-math.pi)),
                            child: AnimatedOpacity(
                              duration: glowDuration,
                              opacity: selected ? 1 : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tab.glowColor!.withOpacity(
                                        selected ? glowOpacity : 0,
                                      ),
                                      blurRadius: glowBlurRadius,
                                      spreadRadius: glowSpreadRadius,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Icon with optional thickness effect
                    AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        selected ? (tab.selectedIcon ?? tab.icon) : tab.icon,
                        color: iconColor,
                        size: iconSize,
                        shadows: _buildIconShadows(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Label text
              Text(
                tab.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: textStyle ??
                    TextStyle(
                      color: iconColor,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a circular shadow halo around the icon for emphasis.
  ///
  /// Only applied when `[tab.thickness]` is provided and the tab is unselected
  /// (or selected without a different selectedIcon).
  List<Shadow>? _buildIconShadows() {
    // Only show thickness effect when:
    // 1. thickness is provided
    // 2. Tab is unselected OR selected without a different icon
    if (tab.thickness == null || (selected && tab.selectedIcon != null)) {
      return null;
    }

    // Create circular shadow halo by placing shadows around the icon
    final shadows = <Shadow>[];
    const angleStep = math.pi / 4; // 8 shadows evenly distributed

    for (double angle = 0; angle < math.pi * 2; angle += angleStep) {
      shadows.add(
        Shadow(
          color: selected ? selectedIconColor : unselectedIconColor,
          offset: Offset.fromDirection(angle, tab.thickness!),
        ),
      );
    }

    return shadows;
  }
}

/// Internal widget that renders the extra button using [GlassButton].
class _ExtraButton extends StatelessWidget {
  const _ExtraButton({
    required this.config,
    required this.quality,
  });

  final GlassBottomBarExtraButton config;
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    // Compose with GlassButton following Apple's compositional pattern
    return GlassButton(
      icon: config.icon,
      onTap: config.onTap,
      label: config.label,
      width: config.size,
      height: config.size,
      quality: quality,
    );
  }
}

// =============================================================================
// Draggable Indicator
// =============================================================================

/// Internal widget that manages the draggable indicator with physics.
class _TabIndicator extends StatefulWidget {
  const _TabIndicator({
    required this.child,
    required this.tabIndex,
    required this.tabCount,
    required this.onTabChanged,
    required this.visible,
    required this.indicatorColor,
    required this.quality,
    required this.barHeight,
    required this.barBorderRadius,
    required this.tabPadding,
    this.indicatorSettings,
  });

  final int tabIndex;
  final int tabCount;
  final bool visible;
  final Widget child;
  final Color? indicatorColor;
  final LiquidGlassSettings? indicatorSettings;
  final ValueChanged<int> onTabChanged;
  final GlassQuality quality;
  final double barHeight;
  final double barBorderRadius;
  final EdgeInsetsGeometry tabPadding;

  @override
  State<_TabIndicator> createState() => _TabIndicatorState();
}

class _TabIndicatorState extends State<_TabIndicator> {
  // Cache fallback indicator color to avoid allocations
  static const _fallbackIndicatorColor =
      Color(0x1AFFFFFF); // white.withValues(alpha: 0.1)

  bool _isDown = false;
  bool _isDragging = false;

  // Current horizontal alignment of the indicator (-1 to 1)
  late double _xAlign = _computeXAlignmentForTab(widget.tabIndex);

  // Cached shape to avoid recreation on every animation frame
  late LiquidRoundedSuperellipse _barShape =
      LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);

  @override
  void didUpdateWidget(covariant _TabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update alignment when tab index or count changes
    if (oldWidget.tabIndex != widget.tabIndex ||
        oldWidget.tabCount != widget.tabCount) {
      setState(() {
        _xAlign = _computeXAlignmentForTab(widget.tabIndex);
      });
    }

    // Update cached shape if border radius changes
    if (oldWidget.barBorderRadius != widget.barBorderRadius) {
      _barShape =
          LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);
    }
  }

  /// Converts a tab index to horizontal alignment (-1 to 1).
  double _computeXAlignmentForTab(int tabIndex) {
    return DraggableIndicatorPhysics.computeAlignment(
      tabIndex,
      widget.tabCount,
    );
  }

  /// Converts a global drag position to horizontal alignment (-1 to 1).
  double _getAlignmentFromGlobalPosition(Offset globalPosition) {
    return DraggableIndicatorPhysics.getAlignmentFromGlobalPosition(
      globalPosition,
      context,
      widget.tabCount,
    );
  }

  void _onDragDown(DragDownDetails details) {
    setState(() {
      _isDown = true;
      _xAlign = _getAlignmentFromGlobalPosition(details.globalPosition);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _xAlign = _getAlignmentFromGlobalPosition(details.globalPosition);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _isDown = false;
    });

    final box = context.findRenderObject()! as RenderBox;

    // Convert alignment to 0-1 range
    final currentRelativeX = (_xAlign + 1) / 2;
    final tabWidth = 1.0 / widget.tabCount;

    // Calculate velocity in relative units
    final indicatorWidth = 1.0 / widget.tabCount;
    final draggableRange = 1.0 - indicatorWidth;
    final velocityX =
        (details.velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;

    // Determine target tab based on position and velocity
    final targetTabIndex = _computeTargetTab(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      tabWidth: tabWidth,
    );

    // Update alignment to target tab
    _xAlign = _computeXAlignmentForTab(targetTabIndex);

    // Notify parent if tab changed
    if (targetTabIndex != widget.tabIndex) {
      widget.onTabChanged(targetTabIndex);
    }
  }

  /// Computes the target tab index based on drag position and velocity.
  int _computeTargetTab({
    required double currentRelativeX,
    required double velocityX,
    required double tabWidth,
  }) {
    return DraggableIndicatorPhysics.computeTargetIndex(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      itemWidth: tabWidth,
      itemCount: widget.tabCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final indicatorColor = widget.indicatorColor ??
        theme.textTheme.textStyle.color?.withValues(alpha: .1) ??
        _fallbackIndicatorColor;
    final targetAlignment = _computeXAlignmentForTab(widget.tabIndex);

    // GlassInteractiveIndicator multiplies by 2 for the glass superellipse shape,
    // but uses the value directly for the background DecoratedBox.
    final backgroundRadius = widget.barBorderRadius * 2; // 64
    final glassRadius =
        widget.barBorderRadius; // 32 → becomes 64 after internal *2

    return GestureDetector(
      onHorizontalDragDown: _onDragDown,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => setState(() {
        _isDragging = false;
        _isDown = false;
      }),
      child: VelocityMotionBuilder(
        converter: const SingleMotionConverter(),
        value: _xAlign,
        // Use different spring physics based on drag state
        motion: _isDragging
            ? const Motion.interactiveSpring(snapToEnd: true)
            : const Motion.bouncySpring(snapToEnd: true),
        builder: (context, value, velocity, child) {
          final alignment = Alignment(value, 0);

          return SingleMotionBuilder(
            motion: const Motion.snappySpring(
              snapToEnd: true,
              duration: Duration(milliseconds: 300),
            ),
            // Show glass indicator when dragging or far from target
            value: widget.visible &&
                    (_isDown || (alignment.x - targetAlignment).abs() > 0.30)
                ? 1.0
                : 0.0,
            builder: (context, thickness, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Glass bar background (rendered FIRST to be at the bottom)
                  Positioned.fill(
                    child: LiquidGlass.grouped(
                      clipBehavior: Clip.none,
                      shape: _barShape,
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // Subtle background indicator (rendered SECOND)
                  if (thickness < 1)
                    GlassInteractiveIndicator(
                      velocity: velocity,
                      itemCount: widget.tabCount,
                      alignment: alignment,
                      thickness: thickness,
                      quality: widget.quality,
                      indicatorColor: indicatorColor,
                      isBackgroundIndicator: true,
                      borderRadius: backgroundRadius,
                      padding: const EdgeInsets.all(4),
                      expansion: 14,
                    ),

                  // Glass indicator (rendered THIRD)
                  if (thickness > 0)
                    GlassInteractiveIndicator(
                      velocity: velocity,
                      itemCount: widget.tabCount,
                      alignment: alignment,
                      thickness: thickness,
                      quality: widget.quality,
                      indicatorColor: indicatorColor,
                      isBackgroundIndicator: false,
                      borderRadius: glassRadius,
                      padding: const EdgeInsets.all(4),
                      expansion: 14,
                      glassSettings: widget.indicatorSettings,
                    ),

                  // Tab bar content (rendered LAST to appear on top)
                  Container(
                    padding: widget.tabPadding,
                    height: widget.barHeight,
                    child: child!,
                  ),
                ],
              );
            },
            child: widget.child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// Jelly Physics
// =============================================================================

/// Applies jelly transform with organic squash and stretch based on velocity.
///
/// This transform creates the satisfying "jelly" effect seen in iOS interfaces:
/// - Objects squash in the direction of movement
/// - Objects stretch perpendicular to movement
///
/// Used by [_IndicatorTransform] to animate the draggable indicator.
