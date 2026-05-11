import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/inherited_liquid_glass.dart';
import '../../theme/glass_theme_helpers.dart';
import 'glass_bottom_bar.dart' show MaskingQuality;
import 'shared/tab_bar_internal.dart';

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
///     GlassTab(icon: Icon(Icons.home), label: 'Home'),
///     GlassTab(icon: Icon(Icons.search), label: 'Search'),
///     GlassTab(icon: Icon(Icons.person), label: 'Profile'),
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
    this.quality,
    this.borderRadius,
    this.indicatorBorderRadius,
    this.indicatorSettings,
    this.backgroundKey,
    this.maskingQuality = MaskingQuality.high,
    this.dividerSettings,
    this.indicatorShadow,
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
  ///
  /// If null, inherits from parent [InheritedLiquidGlass] or defaults to
  /// [GlassQuality.standard].
  final GlassQuality? quality;

  /// Controls indicator clipping quality.
  ///
  /// - [MaskingQuality.high] (default): Full jelly-bloom physics — the
  ///   indicator expands 8 px beyond its pill bounds for the iOS 26 spring
  ///   effect. Uses a dual-layer [GlassBottomBarClipper] path.
  /// - [MaskingQuality.off]: Simple clipping with no jelly expansion.
  ///   Cheaper on GPU; useful for low-end devices or accessibility modes.
  ///
  /// Mirrors the same parameter on [GlassBottomBar] for a consistent API.
  final MaskingQuality maskingQuality;

  /// BorderRadius of the tab bar.
  final BorderRadius? borderRadius;

  /// BorderRadius of the sliding indicator.
  final BorderRadius? indicatorBorderRadius;

  /// Glass settings for the sliding indicator.
  final LiquidGlassSettings? indicatorSettings;

  /// Optional background key for Skia/Web refraction.
  final GlobalKey? backgroundKey;

  /// Settings for the vertical dividers between segments.
  final DividerSettings? dividerSettings;

  /// Optional shadows for the active indicator pill.
  ///
  /// Applied only when the pill is idle (solid color) — automatically
  /// suppressed during the liquid glass drag animation so it does not
  /// interact with the BackdropFilter blur. Useful for improving contrast
  /// in light-mode themes where the pill and track share similar colours.
  ///
  /// Example:
  /// ```dart
  /// indicatorShadow: [
  ///   BoxShadow(
  ///     color: Colors.black.withOpacity(0.12),
  ///     blurRadius: 4,
  ///     offset: Offset(0, 1),
  ///   ),
  /// ]
  /// ```
  final List<BoxShadow>? indicatorShadow;

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
  }

  // Cache default glass settings to avoid allocations on every build
  static const _defaultGlassSettings = LiquidGlassSettings(
    thickness: 30,
    blur: 3,
    chromaticAberration: 0.5,
    lightIntensity: 2,
    refractiveIndex: 1.15,
  );

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    final glassSettings = widget.settings ?? _defaultGlassSettings;

    final backgroundColor = widget.backgroundColor == Colors.transparent
        ? _defaultBackgroundColor
        : widget.backgroundColor;

    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2.2);

    final content = Container(
      height: widget.height,
      // No clipBehavior: the glass indicator's 8px expansion must not be
      // clipped. Scroll content is already clipped by SingleChildScrollView's
      // own Clip.hardEdge viewport — the Container clip is not needed for that.
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      padding: widget.indicatorPadding,
      child: TabBarContent(
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
        quality: effectiveQuality,
        indicatorBorderRadius: widget.indicatorBorderRadius,
        indicatorSettings: widget.indicatorSettings,
        backgroundKey: widget.backgroundKey,
        maskingQuality: widget.maskingQuality,
        dividerSettings: widget.dividerSettings,
        indicatorShadow: widget.indicatorShadow,
        tabBarBorderRadius: borderRadius,
      ),
    );

    if (widget.useOwnLayer) {
      return AdaptiveLiquidGlassLayer(
        settings: glassSettings,
        quality: effectiveQuality,
        child: content,
      );
    }

    return content;
  }
}

// =============================================================================
// GlassTab — public configuration type
// =============================================================================

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

  /// Icon widget to display in the tab.
  final Widget? icon;

  /// Label text to display in the tab.
  final String? label;

  /// Semantic label for accessibility.
  final String? semanticLabel;
}

// =============================================================================
// DividerSettings — configuration for inter-tab dividers
// =============================================================================

/// Configuration for optional vertical dividers between tabs in [GlassTabBar].
///
/// Dividers are rendered as thin vertical lines between tab items and can
/// automatically hide themselves adjacent to the active tab.
class DividerSettings {
  /// Top indent of the divider line.
  final double indent;

  /// Bottom indent of the divider line.
  final double endIndent;

  /// Width (thickness) of the divider line.
  final double thickness;

  /// Optional custom decoration. Defaults to a white 20% opacity line.
  final BoxDecoration? decoration;

  /// Duration of the show/hide animation. Defaults to 200ms.
  final Duration? duration;

  /// Curve of the show/hide animation. Defaults to [Curves.easeInOut].
  final Curve? curve;

  /// When true, dividers adjacent to the selected tab are hidden automatically.
  final bool isHideAutomatically;

  const DividerSettings({
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 1,
    this.decoration,
    this.duration,
    this.curve,
    this.isHideAutomatically = true,
  });

  @override
  bool operator ==(Object other) {
    return other is DividerSettings &&
        indent == other.indent &&
        endIndent == other.endIndent &&
        thickness == other.thickness &&
        decoration == other.decoration &&
        duration == other.duration &&
        curve == other.curve &&
        isHideAutomatically == other.isHideAutomatically;
  }

  @override
  int get hashCode => Object.hashAll([
        indent,
        endIndent,
        thickness,
        decoration,
        duration,
        curve,
        isHideAutomatically,
      ]);

  /// Returns a copy of this [DividerSettings] with the given fields replaced.
  DividerSettings copyWith({
    double? indent,
    double? endIndent,
    double? thickness,
    BoxDecoration? decoration,
    Duration? duration,
    Curve? curve,
    bool? isHideAutomatically,
  }) {
    return DividerSettings(
      indent: indent ?? this.indent,
      endIndent: endIndent ?? this.endIndent,
      thickness: thickness ?? this.thickness,
      decoration: decoration ?? this.decoration,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      isHideAutomatically: isHideAutomatically ?? this.isHideAutomatically,
    );
  }
}
