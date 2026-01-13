import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/animated_glass_indicator.dart';

/// A glass morphism tab bar following Apple's iOS design patterns.
///
/// [GlassTabBar] provides a horizontal tab navigation bar with glass effect,
/// smooth animations, draggable indicator, and jelly physics. It matches iOS's
/// modern tab bar designs with liquid glass aesthetics.
///
/// ## Key Features
///
/// - **Draggable Indicator**: Swipe between tabs with jelly physics
/// - **Smooth Animations**: Velocity-based snapping with organic motion
/// - **Icons + Labels**: Support for icons, labels, or both
/// - **Sharp Text**: Text renders clearly above glass effect
/// - **Scrollable Support**: Handles 2-20+ tabs with smooth scrolling
/// - **iOS Style**: Faithful to Apple's iOS 26 design guidelines
///
/// ## Usage
///
/// ### Basic Usage
/// ```dart
/// int selectedIndex = 0;
///
/// GlassTabBar(
///   tabs: [
///     GlassTab(label: 'Timeline'),
///     GlassTab(label: 'Mentions'),
///     GlassTab(label: 'Messages'),
///   ],
///   selectedIndex: selectedIndex,
///   onTabSelected: (index) {
///     setState(() => selectedIndex = index);
///   },
/// )
/// ```
///
/// ### With Icons and Labels
/// ```dart
/// GlassTabBar(
///   height: 56, // Taller for icon + label
///   tabs: [
///     GlassTab(icon: Icons.home, label: 'Home'),
///     GlassTab(icon: Icons.search, label: 'Search'),
///     GlassTab(icon: Icons.person, label: 'Profile'),
///   ],
///   selectedIndex: _selectedIndex,
///   onTabSelected: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
///
/// ### Within LiquidGlassLayer (Grouped Mode)
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(
///     thickness: 0.8,
///     blur: 12.0,
///   ),
///   child: Column(
///     children: [
///       GlassTabBar(
///         tabs: [
///           GlassTab(label: 'Photos'),
///           GlassTab(label: 'Albums'),
///           GlassTab(label: 'Search'),
///         ],
///         selectedIndex: _selectedIndex,
///         onTabSelected: (index) => setState(() => _selectedIndex = index),
///       ),
///       Expanded(
///         child: TabContent(index: _selectedIndex),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Scrollable with Many Tabs
/// ```dart
/// GlassTabBar(
///   isScrollable: true,
///   tabs: List.generate(
///     10,
///     (i) => GlassTab(label: 'Category ${i + 1}'),
///   ),
///   selectedIndex: _selectedIndex,
///   onTabSelected: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
class GlassTabBar extends StatefulWidget {
  /// Creates a glass tab bar.
  const GlassTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    super.key,
    this.height = 44.0,
    this.isScrollable = false,
    this.indicatorPadding = const EdgeInsets.all(2),
    this.indicatorColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.iconSize = 24.0,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.backgroundColor = Colors.transparent,
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    this.borderRadius,
    this.indicatorBorderRadius,
    this.indicatorSettings,
    this.backgroundKey,
  })  : assert(tabs.length >= 2, 'GlassTabBar requires at least 2 tabs'),
        assert(
          selectedIndex >= 0 && selectedIndex < tabs.length,
          'selectedIndex must be within bounds of tabs list',
        );

  /// List of tabs to display.
  final List<GlassTab> tabs;

  /// Index of the currently selected tab.
  final int selectedIndex;

  /// Called when a tab is selected.
  final ValueChanged<int> onTabSelected;

  /// Height of the tab bar.
  ///
  /// Defaults to 44.0 (iOS standard).
  /// Use 56.0 or higher when using icons + labels.
  final double height;

  /// Whether the tabs should be scrollable.
  final bool isScrollable;

  /// Padding around the indicator.
  final EdgeInsetsGeometry indicatorPadding;

  /// Color of the pill indicator.
  final Color? indicatorColor;

  /// Text style for selected tab label.
  final TextStyle? selectedLabelStyle;

  /// Text style for unselected tab labels.
  final TextStyle? unselectedLabelStyle;

  /// Icon color for selected tab.
  final Color? selectedIconColor;

  /// Icon color for unselected tabs.
  final Color? unselectedIconColor;

  /// Size of the icons.
  final double iconSize;

  /// Padding around each tab label.
  final EdgeInsetsGeometry labelPadding;

  /// Background color of the tab bar.
  final Color backgroundColor;

  /// Glass effect settings (only used when [useOwnLayer] is true).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  final GlassQuality quality;

  /// BorderRadius of the tab bar.
  final BorderRadius? borderRadius;

  /// BorderRadius of the sliding indicator.
  final BorderRadius? indicatorBorderRadius;

  /// Glass settings for the sliding indicator.
  final LiquidGlassSettings? indicatorSettings;

  /// Optional background key for Skia/Web refraction.
  final GlobalKey? backgroundKey;

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar> {
  // Cache default background color to avoid allocations
  static const _defaultBackgroundColor = Color(0x1FFFFFFF); // Colors.white12

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isScrollable &&
        oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToIndex(widget.selectedIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    final estimatedTabWidth = widget.isScrollable ? 120.0 : 100.0;
    final targetScroll = index * estimatedTabWidth;
    final viewportWidth = _scrollController.position.viewportDimension;
    final currentScroll = _scrollController.offset;

    if (targetScroll < currentScroll ||
        targetScroll > currentScroll + viewportWidth - estimatedTabWidth) {
      _scrollController.animateTo(
        targetScroll - (viewportWidth - estimatedTabWidth) / 2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassSettings = widget.settings ??
        const LiquidGlassSettings(
          thickness: 30,
          blur: 3,
          chromaticAberration: 0.5,
          lightIntensity: 2,
          refractiveIndex: 1.15,
        );

    final backgroundColor = widget.backgroundColor == Colors.transparent
        ? _defaultBackgroundColor
        : widget.backgroundColor;

    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2.2);

    final content = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      padding: widget.indicatorPadding,
      child: _TabBarContent(
        tabs: widget.tabs,
        selectedIndex: widget.selectedIndex,
        onTabSelected: widget.onTabSelected,
        isScrollable: widget.isScrollable,
        scrollController: _scrollController,
        indicatorColor: widget.indicatorColor,
        selectedLabelStyle: widget.selectedLabelStyle,
        unselectedLabelStyle: widget.unselectedLabelStyle,
        selectedIconColor: widget.selectedIconColor,
        unselectedIconColor: widget.unselectedIconColor,
        iconSize: widget.iconSize,
        labelPadding: widget.labelPadding,
        quality: widget.quality,
        // Pass new props
        indicatorBorderRadius: widget.indicatorBorderRadius,
        indicatorSettings: widget.indicatorSettings,
        backgroundKey: widget.backgroundKey,
      ),
    );

    if (widget.useOwnLayer) {
      return AdaptiveLiquidGlassLayer(
        settings: glassSettings,
        quality: widget.quality,
        child: content,
      );
    }

    return content;
  }
}

// =============================================================================
// Internal Content Widget
// =============================================================================

class _TabBarContent extends StatefulWidget {
  const _TabBarContent({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isScrollable,
    required this.scrollController,
    required this.indicatorColor,
    required this.selectedLabelStyle,
    required this.unselectedLabelStyle,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.iconSize,
    required this.labelPadding,
    required this.quality,
    this.indicatorBorderRadius,
    this.indicatorSettings,
    this.backgroundKey,
  });

  final List<GlassTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;
  final ScrollController scrollController;
  final Color? indicatorColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final double iconSize;
  final EdgeInsetsGeometry labelPadding;
  final GlassQuality quality;
  final BorderRadius? indicatorBorderRadius;
  final LiquidGlassSettings? indicatorSettings;
  final GlobalKey? backgroundKey;

  @override
  State<_TabBarContent> createState() => _TabBarContentState();
}

class _TabBarContentState extends State<_TabBarContent> {
  // Cache default colors to avoid allocations
  static const _defaultIndicatorColor =
      Color(0x33FFFFFF); // white.withValues(alpha: 0.2)
  static const _defaultUnselectedTextColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)
  static const _defaultUnselectedIconColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)

  bool _isDown = false;
  bool _isDragging = false;
  late double _xAlign = _computeXAlignmentForTab(widget.selectedIndex);

  @override
  void didUpdateWidget(_TabBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.tabs.length != widget.tabs.length) {
      setState(() {
        _xAlign = _computeXAlignmentForTab(widget.selectedIndex);
      });
    }
  }

  double _computeXAlignmentForTab(int tabIndex) {
    return DraggableIndicatorPhysics.computeAlignment(
      tabIndex,
      widget.tabs.length,
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
    final currentRelativeX = (_xAlign + 1) / 2;
    final tabWidth = 1.0 / widget.tabs.length;
    final indicatorWidth = 1.0 / widget.tabs.length;
    final draggableRange = 1.0 - indicatorWidth;
    final velocityX =
        (details.velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;

    final targetTabIndex = _computeTargetTab(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      tabWidth: tabWidth,
    );

    _xAlign = _computeXAlignmentForTab(targetTabIndex);

    if (targetTabIndex != widget.selectedIndex) {
      widget.onTabSelected(targetTabIndex);
    }
  }

  double _getAlignmentFromGlobalPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return _xAlign;

    final local = box.globalToLocal(globalPosition);
    final relativeX = (local.dx / box.size.width).clamp(0.0, 1.0);
    final indicatorWidth = 1.0 / widget.tabs.length;
    final draggableRange = 1.0 - indicatorWidth;

    if (draggableRange <= 0) return 0.0;
    final alignment = (relativeX / draggableRange - 0.5) * 2;
    return alignment.clamp(-1.0, 1.0);
  }

  int _computeTargetTab({
    required double currentRelativeX,
    required double velocityX,
    required double tabWidth,
  }) {
    return DraggableIndicatorPhysics.computeTargetIndex(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      itemWidth: tabWidth,
      itemCount: widget.tabs.length,
    );
  }

  void _onTabTap(int index) {
    if (index != widget.selectedIndex) {
      widget.onTabSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor = widget.indicatorColor ?? _defaultIndicatorColor;
    final targetAlignment = _computeXAlignmentForTab(widget.selectedIndex);

    final selectedLabelStyle = widget.selectedLabelStyle ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    final unselectedLabelStyle = widget.unselectedLabelStyle ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _defaultUnselectedTextColor,
        );

    final selectedIconColor = widget.selectedIconColor ?? Colors.white;
    final unselectedIconColor =
        widget.unselectedIconColor ?? _defaultUnselectedIconColor;

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
            value: _isDown || (alignment.x - targetAlignment).abs() > 0.15
                ? 1.0
                : 0.0,
            builder: (context, thickness, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Unified Glass Indicator with jelly physics
                  // The internal cross-fade in AnimatedGlassIndicator prevents flickering
                  AnimatedGlassIndicator(
                    velocity: velocity,
                    itemCount: widget.tabs.length,
                    alignment: alignment,
                    thickness: thickness,
                    quality: widget.quality,
                    indicatorColor: indicatorColor,
                    isBackgroundIndicator:
                        false, // Internal logic now handles both
                    borderRadius: widget.indicatorBorderRadius?.topLeft.x ?? 16,
                    glassSettings: widget.indicatorSettings,
                    backgroundKey: widget.backgroundKey,
                  ),

                  child!,
                ],
              );
            },
            child: _buildTabLabels(
              selectedLabelStyle,
              unselectedLabelStyle,
              selectedIconColor,
              unselectedIconColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabLabels(
    TextStyle selectedStyle,
    TextStyle unselectedStyle,
    Color selectedIconColor,
    Color unselectedIconColor,
  ) {
    final tabWidgets = List.generate(
      widget.tabs.length,
      (index) {
        final tab = widget.tabs[index];
        final isSelected = index == widget.selectedIndex;
        return RepaintBoundary(
          child: _TabItem(
            tab: tab,
            isSelected: isSelected,
            onTap: () => _onTabTap(index),
            labelStyle: isSelected ? selectedStyle : unselectedStyle,
            iconColor: isSelected ? selectedIconColor : unselectedIconColor,
            iconSize: widget.iconSize,
            padding: widget.labelPadding,
          ),
        );
      },
    );

    if (widget.isScrollable) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(children: tabWidgets),
      );
    }

    return Row(
      children: tabWidgets.map((tab) => Expanded(child: tab)).toList(),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.labelStyle,
    required this.iconColor,
    required this.iconSize,
    required this.padding,
  });

  final GlassTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final TextStyle labelStyle;
  final Color iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget? iconWidget;
    if (tab.icon != null) {
      iconWidget = Icon(
        tab.icon,
        size: iconSize,
        color: iconColor,
      );
    }

    Widget? labelWidget;
    if (tab.label != null) {
      labelWidget = Text(
        tab.label!,
        style: labelStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    Widget content;
    if (iconWidget != null && labelWidget != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          labelWidget,
        ],
      );
    } else if (iconWidget != null) {
      content = iconWidget;
    } else if (labelWidget != null) {
      content = labelWidget;
    } else {
      content = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: tab.semanticLabel ?? tab.label,
        child: Container(
          padding: padding,
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: labelStyle,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Configuration for a tab in [GlassTabBar].
class GlassTab {
  /// Creates a tab configuration.
  const GlassTab({
    this.icon,
    this.label,
    this.semanticLabel,
  }) : assert(
          icon != null || label != null,
          'GlassTab must have either an icon or label',
        );

  /// Icon to display in the tab.
  final IconData? icon;

  /// Label text to display in the tab.
  final String? label;

  /// Semantic label for accessibility.
  final String? semanticLabel;
}
