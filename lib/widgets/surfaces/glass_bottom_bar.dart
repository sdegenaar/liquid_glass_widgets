// Using deprecated Colors.withOpacity for backwards compatibility with
// existing code patterns in the codebase.
// ignore_for_file: deprecated_member_use

// Implementation inspired by example code in the liquid_glass_renderer package
// by whynotmake-it team (https://github.com/whynotmake-it/flutter_liquid_glass).
// Used under MIT License.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../interactive/glass_button.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/inherited_liquid_glass.dart';
import '../../theme/glass_theme_data.dart';
import '../../theme/glass_theme_helpers.dart';
import '../../src/types/glass_interaction_behavior.dart';
import 'shared/bottom_bar_internal.dart'
    show
        BottomBarExtraBtn,
        BottomBarTabItem,
        TabIndicator,
        kBottomBarGlassDefaults;
import 'shared/bar_layout_utils.dart';

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
/// ## Placement
///
/// **Always use [GlassBottomBar] as [Scaffold.bottomNavigationBar].** The
/// Scaffold sizes and anchors that slot to the bottom of the screen. Placing
/// the bar inside `body:`, `Center()`, or a `Column` without explicit
/// bottom-pinning will cause it to float or appear centered rather than
/// staying fixed at the screen's bottom edge.
///
/// ```dart
/// // ✅ Correct
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: GlassBottomBar(...),
/// )
///
/// // ❌ Wrong — bar will float / center
/// Scaffold(
///   body: Center(child: GlassBottomBar(...)),
/// )
/// ```
///
/// ## Usage
///
/// ### Basic Usage
/// ```dart
/// AdaptiveLiquidGlassLayer(
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
///           icon: Icon(CupertinoIcons.home),
///           activeIcon: Icon(CupertinoIcons.home_fill),
///           glowColor: Colors.blue,
///         ),
///         GlassBottomBarTab(
///           label: 'Search',
///           icon: Icon(CupertinoIcons.search),
///           glowColor: Colors.purple,
///         ),
///         GlassBottomBarTab(
///           label: 'Profile',
///           icon: Icon(CupertinoIcons.person),
///           activeIcon: Icon(CupertinoIcons.person_fill),
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

/// Rendering quality for the liquid glass masking effect in [GlassBottomBar].
///
/// Controls the complexity of the masking effect that creates the "magic lens"
/// appearance where selected tab content appears to glow through the glass indicator.
enum MaskingQuality {
  /// No masking effect, simple icon color change (fastest).
  ///
  /// Uses the traditional approach where tabs simply change color when selected.
  /// No dual-layer rendering or clipping. Best performance, but less visual polish.
  ///
  /// **Recommended for:**
  /// - Apps targeting older devices (iPhone X or older)
  /// - Maximum performance requirements
  /// - 7+ tabs
  off,

  /// Full jelly physics clip path with dual-layer rendering (best quality, default).
  ///
  /// Creates a "magic lens" effect where selected tabs appear to glow through
  /// the glass indicator as it moves. Content is magnified and the clip path
  /// follows the jelly physics for perfect synchronization.
  ///
  /// **Recommended for:**
  /// - Modern devices (iPhone 12+, Pixel 5+)
  /// - 3-5 tabs (typical use case)
  /// - Premium/polished apps
  /// - When visual quality is a priority
  ///
  /// **Performance:** Renders tabs twice with ClipPath operations. Maintains
  /// 60fps on modern devices with typical 3-5 tab configurations.
  high,
}

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
    this.barBorderRadius = _defaultBarBorderRadius,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.iconLabelSpacing = 4,
    this.enableBlend = true,
    this.blendAmount = 10,
    this.glassSettings,
    this.showIndicator = true,
    this.indicatorColor,
    this.indicatorSettings,
    this.selectedIconColor = Colors.white,
    this.unselectedIconColor = Colors.white,
    this.iconSize = 24,
    this.labelFontSize = 11,
    this.textStyle,
    this.glowDuration = const Duration(milliseconds: 300),
    this.glowBlurRadius = 32,
    this.glowSpreadRadius = 8,
    this.glowOpacity = 0.6,
    this.quality,
    this.magnification = 1.0,
    this.innerBlur = 0.0,
    this.maskingQuality = MaskingQuality.high,
    this.backgroundKey,
    this.tabWidth,
    this.indicatorExpansion = 14,
    this.interactionGlowColor,
    this.interactionGlowRadius = 1.5,
    this.interactionBehavior = GlassInteractionBehavior.full,
    this.pressScale = 1.04,
  })  : assert(tabs.length > 0, 'GlassBottomBar requires at least one tab'),
        assert(
          selectedIndex >= 0 && selectedIndex < tabs.length,
          'selectedIndex must be between 0 and tabs.length - 1',
        ),
        assert(
          tabWidth == null || tabWidth > 0,
          'tabWidth must be positive, or null to use expand (full-width) mode.',
        );

  /// Magnification factor for the content inside the selected indicator.
  ///
  /// Values > 1.0 will zoom in the content, creating a lens effect.
  ///
  /// **Recommended range:** 1.0-1.3
  /// - 1.0: No magnification (default)
  /// - 1.1-1.2: Subtle emphasis
  /// - 1.3+: Dramatic effect (may look aggressive)
  ///
  /// Only applies when [maskingQuality] is [MaskingQuality.high].
  final double magnification;

  /// Blur amount in logical pixels applied to content inside the indicator.
  ///
  /// Creates a frosted glass effect on the selected content.
  ///
  /// **Recommended range:** 0.0-3.0
  /// - 0.0: No blur (default, sharp content)
  /// - 1.0-2.0: Subtle frosted effect
  /// - 3.0+: Heavy blur (may make content unreadable)
  ///
  /// Only applies when [maskingQuality] is [MaskingQuality.high].
  final double innerBlur;

  /// Quality of the liquid glass masking effect.
  ///
  /// Controls the rendering strategy for the "magic lens" effect where
  /// selected content appears to glow through the glass indicator.
  ///
  /// - [MaskingQuality.high]: Full jelly physics with dual-layer rendering (default)
  ///   Best visual quality, recommended for 3-5 tabs on modern devices.
  ///
  /// - [MaskingQuality.off]: Simple color change, no masking
  ///   Maximum performance, recommended for 7+ tabs or older devices.
  ///
  /// Defaults to [MaskingQuality.high].
  final MaskingQuality maskingQuality;

  /// Optional background key for Skia/Web refraction.
  final GlobalKey? backgroundKey;

  /// The color of the directional glow effect when interacting with the bar.
  ///
  /// Only active when [interactionBehavior] includes glow
  /// (i.e. [GlassInteractionBehavior.glowOnly] or [GlassInteractionBehavior.full]).
  ///
  /// Defaults to a subtle translucent white (`0x1FFFFFFF`) when null.
  final Color? interactionGlowColor;

  /// The radius spread of the directional glow effect when interacting with the bar.
  ///
  /// Defaults to 1.5.
  final double interactionGlowRadius;

  /// Controls which physical interaction effects are active when the user
  /// presses the bar.
  ///
  /// Defaults to [GlassInteractionBehavior.full] — directional glow + spring scale,
  /// matching native iOS 26 Apple News / Safari behaviour.
  final GlassInteractionBehavior interactionBehavior;

  /// Peak scale factor applied to the bar at maximum press depth.
  ///
  /// Only active when [interactionBehavior] includes scale
  /// (i.e. [GlassInteractionBehavior.scaleOnly] or [GlassInteractionBehavior.full]).
  ///
  /// Defaults to 1.04 (4% growth — matches iOS 26 Apple News pill).
  final double pressScale;

  // ===========================================================================
  // Tab Configuration
  // ===========================================================================

  /// Width of each tab slot in logical pixels.
  ///
  /// Controls the total width of the tab pill via `tabWidth × tabs.length`,
  /// giving each tab a fixed allocation regardless of the bar's full width.
  ///
  /// **Compact sizing (default `88.0`)** — iOS 26 Apple-style proportional tabs:
  /// - 2 tabs → 176 px pill
  /// - 3 tabs → 264 px pill
  /// - 4 tabs → 352 px pill (clamped if wider than available space)
  ///
  /// **Expand (`null`)** — legacy fill-all-space behaviour. The tab pill
  /// stretches to occupy all horizontal space not taken by [extraButton].
  /// Use this when you explicitly want the bar to span the full available width.
  ///
  /// When the natural width (`tabWidth × tabs.length`) exceeds the available
  /// space the pill is automatically clamped — it will never overflow.
  ///
  /// See also:
  ///   * [GlassSearchableBottomBar.tabWidth], the equivalent parameter on the
  ///     searchable variant which uses the same default and clamping logic.
  final double? tabWidth;

  /// How far the jelly indicator's leading and trailing edges expand
  /// past the tab boundary as the indicator translates between tabs.
  /// Higher values give a more dramatic "puff" stretch; lower values
  /// produce a tighter, more iOS-native feel. Defaults to `14` —
  /// matches the pre-existing visual.
  final double indicatorExpansion;

  /// List of tabs to display in the bottom bar.
  ///
  /// Each tab requires an icon. Optionally specify a label (for text below icon),
  /// selectedIcon for a different appearance when selected, and glowColor for the
  /// animated glow effect. Tabs with null labels will center the icon vertically.
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
  static const _defaultBarBorderRadius = 32.0;
  final double barBorderRadius;

  /// Internal padding of the tab bar.
  ///
  /// Controls spacing between the bar edges and the tab icons.
  /// Defaults to 4px horizontal padding.
  final EdgeInsetsGeometry tabPadding;

  /// Internal spacing of the tab bar.
  ///
  /// Controls spacing between the tab icon and the tab label.
  /// Defaults to 4px.
  final double iconLabelSpacing;

  /// Whether to enable organic liquid blending between the tab pill and
  /// the extra button.
  ///
  /// When `true` (default), adjacent glass surfaces merge organically —
  /// a premium "beyond native" effect. When `false`, the extra button
  /// renders as a fully independent glass element, matching Apple's
  /// native iOS 26 tab bar behavior.
  ///
  /// When disabled, [blendAmount] is ignored.
  final bool enableBlend;

  /// Blend amount for glass surfaces.
  ///
  /// Higher values create smoother blending between the tab bar and extra
  /// button. Only effective when [enableBlend] is `true`.
  /// Passed to [AdaptiveLiquidGlassLayer].
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
  /// - lightAngle: 0.75 * π (135°, Apple standard — upper-left)
  /// - glassColor: Colors.white24
  final LiquidGlassSettings? glassSettings;

  /// Rendering quality for the glass effect.
  ///
  /// If null, inherits from parent [InheritedLiquidGlass] or defaults to
  /// [GlassQuality.premium] since bottom bars are typically static surfaces at
  /// the bottom of the screen where premium quality looks best.
  ///
  /// Use [GlassQuality.standard] if the bottom bar will be used in a scrollable
  /// context.
  final GlassQuality? quality;

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

  /// Font size for tab labels.
  ///
  /// Only applies when [textStyle] is null. Mirrors [iconSize] as a dedicated
  /// sizing knob so color and weight are still managed automatically.
  ///
  /// Defaults to 11. Reduce to 10 for bars with 4+ tabs or longer labels
  /// such as "Following".
  final double labelFontSize;

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
  // Delegate to the shared const — single source of truth in bottom_bar_internal.dart.
  // Both bars reference kBottomBarGlassDefaults so their glass is guaranteed identical.
  static const _defaultGlassSettings = kBottomBarGlassDefaults;

  @override
  Widget build(BuildContext context) {
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassQuality.premium,
    );

    // Resolve interaction glow color: explicit param → GlassThemeData.primary → null
    // (null lets the internal widget use its own hardcoded fallback).
    final resolvedGlowColors =
        GlassThemeData.of(context).glowColorsFor(context);
    final effectiveInteractionGlowColor =
        widget.interactionGlowColor ?? resolvedGlowColors.primary;

    // Glow appearance fields come from the theme; they cannot be set per-widget
    // because they are part of the theme palette. Widgets that need custom
    // values should supply a custom GlassGlowColors via GlassTheme.
    final effectiveGlowBlurRadius = resolvedGlowColors.glowBlurRadius;
    final effectiveGlowSpreadRadius = resolvedGlowColors.glowSpreadRadius;
    final effectiveGlowOpacity = resolvedGlowColors.glowOpacity;

    // Use custom glass settings or cached defaults for bottom bars
    final glassSettings = widget.glassSettings ?? _defaultGlassSettings;

    return AdaptiveLiquidGlassLayer(
      settings: glassSettings,
      quality: effectiveQuality,
      blendAmount: widget.enableBlend
          ? widget.blendAmount
          : 0, // Impeller-only (gracefully ignored on Skia)
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: widget.verticalPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Compute how much width the extra button consumes, if present.
            final extraBtnW = widget.extraButton != null
                ? widget.extraButton!.size + widget.spacing
                : 0.0;
            // Available width for the tab pill inside the padded row.
            final maxTabW = constraints.maxWidth - extraBtnW;
            // Resolve the pill width: compact (tabWidth × count) or fill (null).
            final tabPillW = resolveTabPillWidth(
              tabWidth: widget.tabWidth,
              tabCount: widget.tabs.length,
              maxAvailable: maxTabW,
            );

            return SizedBox(
              height: widget.barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Optional extra button — painted first (bottom of z-order).
                  // Pinned to the trailing edge. Painted before the tab pill
                  // so the jelly indicator's glass effect correctly overlaps and
                  // refracts the extra button during horizontal stretch physics.
                  // This matches the z-order pattern in GlassSearchableBottomBar.
                  if (widget.extraButton != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: widget.extraButton!.size,
                        height: widget.barHeight,
                        child: BottomBarExtraBtn(
                          config: widget.extraButton!,
                          quality: effectiveQuality,
                          iconColor: widget.extraButton!.iconColor ??
                              widget.unselectedIconColor,
                          borderRadius: widget.barBorderRadius ==
                                  GlassBottomBar._defaultBarBorderRadius
                              ? null
                              : widget.barBorderRadius,
                        ),
                      ),
                    ),

                  // 2. Tab pill — painted last (top of z-order).
                  // The jelly indicator uses Stack(clipBehavior: Clip.none)
                  // internally, so it can overflow past the pill bounds.
                  Positioned(
                    left: 0,
                    top: 0,
                    width: tabPillW,
                    height: widget.barHeight,
                    child: TabIndicator(
                      quality: effectiveQuality,
                      visible: widget.showIndicator,
                      tabIndex: widget.selectedIndex,
                      tabCount: widget.tabs.length,
                      indicatorColor: widget.indicatorColor,
                      indicatorSettings: widget.indicatorSettings,
                      onTabChanged: widget.onTabSelected,
                      barHeight: widget.barHeight,
                      barBorderRadius: widget.barBorderRadius,
                      tabPadding: widget.tabPadding,
                      backgroundKey: widget.backgroundKey,
                      maskingQuality: widget.maskingQuality,
                      indicatorExpansion: widget.indicatorExpansion,
                      interactionGlowColor: widget.interactionBehavior.hasGlow
                          ? effectiveInteractionGlowColor
                          : Colors.transparent,
                      interactionGlowRadius: widget.interactionGlowRadius,
                      interactionGlowBlurRadius: effectiveGlowBlurRadius,
                      interactionGlowSpreadRadius: effectiveGlowSpreadRadius,
                      interactionGlowOpacity: effectiveGlowOpacity,
                      interactionScale: widget.interactionBehavior.hasScale
                          ? widget.pressScale
                          : 1.0,
                      childUnselected: Row(
                        children: [
                          for (var i = 0; i < widget.tabs.length; i++)
                            Expanded(
                              child: BottomBarTabItem(
                                tab: widget.tabs[i],
                                selected: false,
                                selectedIconColor: widget.selectedIconColor,
                                unselectedIconColor: widget.unselectedIconColor,
                                iconSize: widget.iconSize,
                                labelFontSize: widget.labelFontSize,
                                textStyle: widget.textStyle,
                                iconLabelSpacing: widget.iconLabelSpacing,
                                glowDuration: widget.glowDuration,
                                glowBlurRadius: widget.glowBlurRadius,
                                glowSpreadRadius: widget.glowSpreadRadius,
                                glowOpacity: widget.glowOpacity,
                                // onTap is null: all tap selection goes through
                                // TabIndicator.onBarTapDown (prevents double-fire).
                                onTap: null,
                              ),
                            ),
                        ],
                      ),
                      // Pass selected tabs (foreground/masked layer)
                      selectedTabBuilder: (context, intensity, alignment) =>
                          _buildSelectedTabs(intensity, alignment),
                      magnification: widget.magnification,
                      innerBlur: widget.innerBlur,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedTabs(double intensity, Alignment alignment) {
    // Lerp magnification: 1.0 -> widget.magnification
    final scale = ui.lerpDouble(1.0, widget.magnification, intensity) ?? 1.0;

    // Selective rendering: only render tabs near the indicator (within +/- 1 tab).
    final currentTabFloat = ((alignment.x + 1) / 2) * widget.tabs.length;
    final affectedStart =
        (currentTabFloat - 1).floor().clamp(0, widget.tabs.length - 1);
    final affectedEnd =
        (currentTabFloat + 1).ceil().clamp(0, widget.tabs.length - 1);

    return Row(
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          Expanded(
            child: (i >= affectedStart && i <= affectedEnd)
                ? Transform.scale(
                    scale: scale,
                    child: BottomBarTabItem(
                      tab: widget.tabs[i],
                      selected: true,
                      selectedIconColor: widget.selectedIconColor,
                      unselectedIconColor: widget.unselectedIconColor,
                      iconSize: widget.iconSize,
                      labelFontSize: widget.labelFontSize,
                      textStyle: widget.textStyle,
                      iconLabelSpacing: widget.iconLabelSpacing,
                      glowDuration: widget.glowDuration,
                      glowBlurRadius: widget.glowBlurRadius,
                      glowSpreadRadius: widget.glowSpreadRadius,
                      glowOpacity: widget.glowOpacity,
                      // onTap is null: all tap selection goes through
                      // TabIndicator.onBarTapDown (prevents double-fire).
                      onTap: null,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

/// Configuration for a tab in [GlassBottomBar].
///
/// Each tab displays an icon and label. Optionally provide a different widget
/// for the selected state and a glow color for the selection animation.
///
/// ## Icon widgets
///
/// Pass any widget as [icon] and [activeIcon]. Standard [Icon] widgets will
/// automatically inherit the correct color, size, and shadow halo from the
/// bar's [IconTheme]. Custom widgets (SVG, PNG, etc.) are responsible for
/// their own tinting.
///
/// ```dart
/// // Standard Icon — inherits color/size automatically
/// GlassBottomBarTab(
///   label: 'Home',
///   icon: Icon(CupertinoIcons.home),
///   activeIcon: Icon(CupertinoIcons.home_fill),
/// )
///
/// // Custom SVG — color handled by the caller
/// GlassBottomBarTab(
///   label: 'Settings',
///   icon: SvgPicture.asset('assets/settings.svg', colorFilter: ...),
/// )
/// ```
class GlassBottomBarTab {
  /// Creates a bottom bar tab configuration.
  const GlassBottomBarTab({
    this.label,
    required this.icon,
    this.activeIcon,
    this.glowColor,
    this.thickness,
  });

  /// Label text displayed below the icon.
  final String? label;

  /// Widget displayed when the tab is not selected.
  ///
  /// Also used when selected if [activeIcon] is not provided.
  /// Standard [Icon] widgets automatically pick up the correct color and size
  /// from the parent [IconTheme].
  final Widget icon;

  /// Widget displayed when the tab is selected.
  ///
  /// If null, [icon] is used for both selected and unselected states.
  /// Standard [Icon] widgets automatically pick up the correct color and size
  /// from the parent [IconTheme].
  final Widget? activeIcon;

  /// Color of the animated glow effect when this tab is selected.
  ///
  /// If null, no glow effect is shown for this tab.
  final Color? glowColor;

  /// Thickness of the icon shadow halo effect.
  ///
  /// When provided, creates a shadow halo around the icon for emphasis.
  /// Only visible on unselected tabs, or selected tabs without a
  /// different [activeIcon].
  /// Typical values are between 0.5 and 2.0.
  ///
  /// This is applied via [IconTheme], so it only takes effect on
  /// standard [Icon] widgets. Custom widgets must handle shadows themselves.
  final double? thickness;
}

/// Where a [GlassBottomBarExtraButton] appears relative to the search pill
/// in a [GlassSearchableBottomBar].
///
/// Has no effect in [GlassBottomBar], where the extra button always sits
/// between the tab content and the right edge.
enum ExtraButtonPosition {
  /// Place the button **before** the search pill — between the tab pill and
  /// the search pill. This is the default and matches the classic iOS
  /// "compose" button position seen in Mail and Messages.
  beforeSearch,

  /// Place the button **after** the search pill — pinned to the trailing
  /// (right) edge of the bar. Use this when you want a persistent action
  /// button that stays visible at the far right even while search is expanded.
  /// The search pill's spring calculations automatically reserve the required
  /// space so no RenderFlex overflow occurs during transitions.
  afterSearch,
}

/// Controls how the tab pill is anchored **horizontally** during the morph
/// animation in [GlassSearchableBottomBar].
///
/// This only affects the tab pill's position. The search pill position is
/// always computed from the trailing edge.
enum GlassTabPillAnchor {
  /// The tab pill is pinned to the **leading (left) edge** — the right edge
  /// retracts as the pill collapses. This is the default and matches the
  /// classic iOS News / Safari behaviour.
  start,

  /// The tab pill scales **from its centre** — both edges collapse inward
  /// symmetrically as the pill morphs into the collapsed search state, and
  /// expand outward symmetrically when search closes.
  ///
  /// Use this when you want a more balanced, symmetrical animation. Note that
  /// while searching, the search pill will be slightly narrower than in
  /// [start] mode because it starts after the centred collapsed tab pill.
  center,
}

/// Configuration for the extra button in [GlassBottomBar] and
/// [GlassSearchableBottomBar].
///
/// The extra button is rendered as a [GlassButton] and typically used for
/// primary actions like creating new content.
class GlassBottomBarExtraButton {
  /// Creates an extra button configuration.
  const GlassBottomBarExtraButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.iconColor,
    this.size = 64,
    this.position = ExtraButtonPosition.beforeSearch,
    this.collapseOnSearchFocus = true,
  });

  /// Icon widget displayed in the button.
  final Widget icon;

  /// Callback when the button is tapped.
  final VoidCallback onTap;

  /// Accessibility label for the button.
  final String label;

  /// Color used for the button's icon.
  ///
  /// Defaults to GlassBottomBar.unselectedIconColor.
  final Color? iconColor;

  /// Width and height of the button.
  ///
  /// Defaults to 64 to match the default bar height.
  final double size;

  /// Where this button is placed relative to the search pill in a
  /// [GlassSearchableBottomBar].
  ///
  /// - [ExtraButtonPosition.beforeSearch] (default) — between the tab pill
  ///   and the search pill. Classic iOS pattern (Mail compose button).
  /// - [ExtraButtonPosition.afterSearch] — pinned to the right edge, after
  ///   the search pill. The search pill's spring calculations automatically
  ///   reserve space so no RenderFlex overflow occurs during transitions.
  ///
  /// Has no effect in [GlassBottomBar].
  final ExtraButtonPosition position;

  /// Whether this button collapses (hides + frees layout space) when the
  /// search field is focused (i.e. the keyboard is visible).
  ///
  /// When `true` (default), the button fades out and its horizontal layout
  /// space spring-animates to zero on keyboard appearance, giving the search
  /// input the full available width — matching native iOS system apps
  /// (Weather, App Store, Apple News).
  ///
  /// When `false`, the button remains fully visible and tappable alongside
  /// the search input. Use this for buttons with contextual relevance during
  /// active search (e.g. a "Filter" action that applies to search results).
  ///
  /// Has no effect in [GlassBottomBar].
  final bool collapseOnSearchFocus;
}

// TabIndicator and TabIndicatorState live in shared/bottom_bar_internal.dart.
// JellyClipper is defined below — kept here because bottom_bar_internal.dart
// and searchable_bottom_bar_internal.dart import it via `show JellyClipper`.

/// Clipper that matches the shape and physics of the jelly indicator.
class JellyClipper extends CustomClipper<Path> {
  JellyClipper({
    required this.itemCount,
    required this.alignment,
    required this.thickness,
    required this.expansion,
    required this.transform,
    required this.borderRadius,
    this.inverse = false,
  });

  final int itemCount;
  final Alignment alignment;
  final double thickness;
  final double expansion;
  final Matrix4 transform;
  final double borderRadius;
  final bool inverse;

  /// Threshold for clip recalculation optimization.
  ///
  /// When changes in alignment or thickness are below this threshold,
  /// the cached clip path is reused instead of recalculating.
  /// This is below human perception threshold (sub-pixel).
  static const double _recalcThreshold = 0.001;

  @override
  Path getClip(Size size) {
    // Calculate the base rect of the indicator (same logic as FractionallySizedBox)
    final tabWidth = size.width / itemCount;
    final availableWidth = size.width - tabWidth;

    // Map alignment (-1 to 1) to horizontal offset
    final left = (alignment.x + 1) / 2 * availableWidth;

    // Create the base rect
    // Note: We need to account for the padding applied to AnimatedGlassIndicator
    // AnimatedGlassIndicator has padding: const EdgeInsets.all(4)
    // So the rect should be inset by 4 on all sides, then inflated by expansion * thickness

    final baseRect = Rect.fromLTWH(left, 0, tabWidth, size.height);
    final paddedRect = Rect.fromLTRB(
      baseRect.left + 4.0, // Left padding
      baseRect.top + 4.0, // Top padding
      baseRect.right - 4.0, // Right padding
      baseRect.bottom - 4.0, // Bottom padding
    );

    // Apply expansion based on thickness (drag state)
    final inflatedRect = paddedRect.inflate(expansion * thickness);

    // Create rounded rect path
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        inflatedRect,
        Radius.circular(borderRadius),
      ));

    // Apply jelly physics transform around the center
    final center = inflatedRect.center;
    final centeredTransform = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..multiply(transform)
      ..translate(-center.dx, -center.dy);

    final indicatorPath = path.transform(centeredTransform.storage);

    if (inverse) {
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addPath(indicatorPath, Offset.zero);
    }

    return indicatorPath;
  }

  @override
  bool shouldReclip(JellyClipper oldClipper) {
    // Optimization: skip reclip for sub-pixel changes
    // This reduces clip path recalculations by ~20-30% during slow drags
    if (itemCount == oldClipper.itemCount &&
        inverse == oldClipper.inverse &&
        borderRadius == oldClipper.borderRadius &&
        expansion == oldClipper.expansion &&
        transform == oldClipper.transform &&
        (alignment.x - oldClipper.alignment.x).abs() < _recalcThreshold &&
        (thickness - oldClipper.thickness).abs() < _recalcThreshold) {
      return false; // Reuse cached clip path
    }

    // Full check for significant changes
    return itemCount != oldClipper.itemCount ||
        alignment != oldClipper.alignment ||
        thickness != oldClipper.thickness ||
        expansion != oldClipper.expansion ||
        transform != oldClipper.transform ||
        borderRadius != oldClipper.borderRadius ||
        inverse != oldClipper.inverse;
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
/// Used by [_TabIndicator] to animate the draggable indicator.
