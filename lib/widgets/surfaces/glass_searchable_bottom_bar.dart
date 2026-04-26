// Using deprecated Colors.withOpacity for backwards compatibility.
// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../src/types/glass_interaction_behavior.dart';
import '../../types/glass_quality.dart';
import '../../theme/glass_theme_helpers.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import 'glass_bottom_bar.dart'
    show
        ExtraButtonPosition,
        GlassBottomBarExtraButton,
        GlassBottomBarTab,
        GlassTabPillAnchor,
        MaskingQuality;
import 'shared/bottom_bar_internal.dart';
import 'shared/glass_search_bar_config.dart';
import 'shared/searchable_bottom_bar_controller.dart';
import 'shared/searchable_bottom_bar_internal.dart';

export 'shared/glass_search_bar_config.dart';

// =============================================================================
// Public Widget — GlassSearchableBottomBar
// =============================================================================

/// A glass bottom navigation bar with a morphing search pill.
///
/// Visually identical to [GlassBottomBar] but adds a search pill that shares
/// the **same** [AdaptiveLiquidGlassLayer] as the tab pill. This means the
/// two pills correctly liquid-merge at their edges — the same organic blending
/// that makes the tab-bar + extra-button coupling feel native to iOS 26.
///
/// When [isSearchActive] is `false` the widget looks exactly like
/// [GlassBottomBar] with a compact search icon pill at the right edge.
///
/// When [isSearchActive] is `true`:
/// - The tab pill collapses to [GlassSearchBarConfig.collapsedTabWidth].
/// - The search pill expands to fill all remaining space.
/// - Both widths are calculated with [LayoutBuilder] — real pixel values — so
///   Both widths animate with iOS-accurate [SpringSimulation] physics — no null/intrinsic hacks.
///
/// All parameters mirror [GlassBottomBar] exactly, with the additions of
/// [isSearchActive] and [searchConfig].
class GlassSearchableBottomBar extends StatefulWidget {
  /// Creates a glass bottom bar with a morphing search pill.
  const GlassSearchableBottomBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.searchConfig,
    super.key,
    this.controller,
    this.isSearchActive = false,
    this.extraButton,
    this.spacing = 8,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.barHeight = 64,
    this.searchBarHeight = 50,
    this.barBorderRadius = _kDefaultBorderRadius,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.iconLabelSpacing = 4,
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
    this.interactionGlowColor,
    this.interactionGlowRadius = 1.5,
    this.quality,
    this.magnification = 1.0,
    this.innerBlur = 0.0,
    this.maskingQuality = MaskingQuality.high,
    this.backgroundKey,
    this.springDescription,
    this.tabPillAnchor = GlassTabPillAnchor.start,
    // ── Interaction ──────────────────────────────────────────────────────────
    this.interactionBehavior = GlassInteractionBehavior.full,
    this.pressScale = 1.04,
    this.indicatorBehindIcons = false,
  })  : assert(tabs.length > 0,
            'GlassSearchableBottomBar requires at least one tab'),
        assert(
          selectedIndex >= 0 && selectedIndex < tabs.length,
          'selectedIndex must be between 0 and tabs.length - 1',
        );

  // ignore: public_member_api_docs
  static const double _kDefaultBorderRadius = 32.0;

  /// iOS 26-style spring for the pill morph animations.
  /// mass=1 stiffness=350 damping=30 → ~380 ms natural settle, ~5% overshoot.
  static const _kSpring =
      SpringDescription(mass: 1.0, stiffness: 350.0, damping: 30.0);

  // ── Search ──────────────────────────────────────────────────────────────────
  /// Optional controller to manage the search bar state machine externally.
  ///
  /// When provided, the widget uses this controller's state instead of
  /// creating its own. Useful for programmatic open/close of search,
  /// or for unit testing the layout computation independently.
  ///
  /// The caller owns the controller's lifecycle — [dispose] it when done.
  final SearchableBottomBarController? controller;

  /// Configuration for the morphing search bar behaviour.
  final GlassSearchBarConfig searchConfig;

  /// Custom spring physics for the pill morph animation.
  ///
  /// When null, uses the built-in iOS 26-style spring (stiffness 350, damping 30).
  /// Override to create slower, faster, or more/less bouncy transitions:
  ///
  /// ```dart
  /// springDescription: const SpringDescription(
  ///   mass: 1, stiffness: 200, damping: 40, // slower, minimal overshoot
  /// ),
  /// ```
  final SpringDescription? springDescription;

  /// How the tab pill is anchored horizontally during the morph animation.
  ///
  /// - [GlassTabPillAnchor.start] (default) — the tab pill is pinned to the
  ///   leading edge; the right edge retracts as the pill collapses. This
  ///   matches the default iOS News / Safari behaviour.
  /// - [GlassTabPillAnchor.center] — the tab pill scales symmetrically from
  ///   its centre; both edges collapse inward and expand outward together,
  ///   giving a more balanced look. The search pill will be slightly narrower
  ///   while searching because it starts after the (now centred) collapsed tab.
  final GlassTabPillAnchor tabPillAnchor;

  /// Whether the search bar is currently expanded.
  ///
  /// When `true`, the tab pill collapses and the search pill expands.
  /// Animated using [AnimatedContainer] with iOS spring physics.
  final bool isSearchActive;

  // ── Tab configuration ────────────────────────────────────────────────────────
  /// List of tabs. At least one tab is required.
  final List<GlassBottomBarTab> tabs;

  /// Index of the currently selected tab (0-based).
  final int selectedIndex;

  /// Callback fired when a tab is selected or the draggable indicator is released.
  final ValueChanged<int> onTabSelected;

  // ── Extra button (optional) ──────────────────────────────────────────────────
  /// Optional extra action button shown between the tab pill and the search pill.
  final GlassBottomBarExtraButton? extraButton;

  // ── Layout ───────────────────────────────────────────────────────────────────
  /// Spacing between adjacent pills. Defaults to 8.
  final double spacing;

  /// Horizontal padding around the full bar content. Defaults to 20.
  final double horizontalPadding;

  /// Vertical padding (top + bottom) around the bar content. Defaults to 20.
  final double verticalPadding;

  /// Height of the tab pill and search pill. Defaults to 64.
  final double barHeight;

  /// Height of the pills when search is active. Defaults to `50.0`.
  ///
  /// In iOS 26 Apple News the search bar is noticeably shorter than the full
  /// tab bar (which must accommodate icon + label). This default of `50`
  /// replicates that compact, native feel. If you want the bar to remain
  /// the same height, explicitly set this to match your [barHeight].
  ///
  /// The transition is animated with the same easeOut curve used for all
  /// other bar morphs.
  final double searchBarHeight;

  /// Corner radius of both pills. Defaults to 32 (full pill shape).
  final double barBorderRadius;

  /// Internal padding within the tab pill. Defaults to 4 px horizontal.
  final EdgeInsetsGeometry tabPadding;

  /// Vertical spacing between icon and label. Defaults to 4.
  final double iconLabelSpacing;

  /// Liquid-glass blend amount for the shared [AdaptiveLiquidGlassLayer].
  ///
  /// Higher values increase the organic blending between adjacent pills.
  /// Defaults to 10.
  final double blendAmount;

  // ── Glass ────────────────────────────────────────────────────────────────────
  /// Custom glass settings. Falls back to identical defaults as [GlassBottomBar].
  final LiquidGlassSettings? glassSettings;

  /// Rendering quality. Inherits from parent or defaults to [GlassQuality.premium].
  final GlassQuality? quality;

  // ── Indicator ────────────────────────────────────────────────────────────────
  /// Whether to show the draggable indicator. Defaults to `true`.
  final bool showIndicator;

  /// Base color of the glass indicator. Falls back to theme or a translucent white.
  final Color? indicatorColor;

  /// Custom glass settings for the indicator element.
  final LiquidGlassSettings? indicatorSettings;

  // ── Tab style ────────────────────────────────────────────────────────────────
  /// Icon color when a tab is selected. Defaults to white.
  final Color selectedIconColor;

  /// Icon color when a tab is unselected. Defaults to white.
  final Color unselectedIconColor;

  /// Size of tab icons. Defaults to 24.
  final double iconSize;

  /// Font size for tab labels.
  ///
  /// Only applies when [textStyle] is null. Mirrors [iconSize] as a dedicated
  /// sizing knob so color and weight are still managed automatically.
  ///
  /// Defaults to 11. Reduce to 10 for bars with 4+ tabs or longer labels
  /// such as "Following".
  final double labelFontSize;

  /// Text style for tab labels. Uses 11 pt w600/w500 when null.
  final TextStyle? textStyle;

  // ── Glow ─────────────────────────────────────────────────────────────────────
  /// Duration of the tab glow animation. Defaults to 300 ms.
  final Duration glowDuration;

  /// Blur radius of the glow. Defaults to 32.
  final double glowBlurRadius;

  /// Spread radius of the glow. Defaults to 8.
  final double glowSpreadRadius;

  /// Opacity of the glow at full intensity. Defaults to 0.6.
  final double glowOpacity;

  /// The color of the directional glow effect when interacting with the bar.
  ///
  /// Set to [Colors.transparent] to disable the glow effect.
  final Color? interactionGlowColor;

  /// The radius spread of the directional glow effect when interacting with the bar.
  ///
  /// Defaults to 1.5.
  final double interactionGlowRadius;

  // ── Interaction ───────────────────────────────────────────────────────────────

  /// Controls which physical interaction effects are active when the user
  /// presses the bar.
  ///
  /// Defaults to [GlassInteractionBehavior.full] — directional glow + spring
  /// scale, matching native iOS 26 Apple News / Safari behaviour.
  final GlassInteractionBehavior interactionBehavior;

  /// Peak scale factor applied to the bar at maximum press depth.
  ///
  /// Only active when [interactionBehavior] includes scale
  /// (i.e. [GlassInteractionBehavior.scaleOnly] or [GlassInteractionBehavior.full]).
  ///
  /// Defaults to 1.04 (4% growth — matches iOS 26 Apple News pill).
  final double pressScale;

  /// Whether the moving glass indicator is drawn *behind* the tab icons
  /// instead of *on top* of them. Mirrors [GlassBottomBar.indicatorBehindIcons].
  ///
  /// Defaults to `false`, preserving the "magic lens" effect. Set to `true`
  /// to keep the active icon's colour at full saturation (the iOS-native
  /// pattern), at the cost of the lens refraction.
  final bool indicatorBehindIcons;

  // ── Advanced ─────────────────────────────────────────────────────────────────
  /// Magnification factor for the selected indicator lens effect. Defaults to 1.0.
  final double magnification;

  /// Blur amount inside the selected indicator. Defaults to 0.0.
  final double innerBlur;

  /// Rendering quality for the liquid masking effect. Defaults to [MaskingQuality.high].
  final MaskingQuality maskingQuality;

  /// Background key for Skia/web refraction. Optional.
  final GlobalKey? backgroundKey;

  // Note: interactionBehavior and pressScale fields are declared earlier in the Interaction section.

  @override
  State<GlassSearchableBottomBar> createState() =>
      _GlassSearchableBottomBarState();
}

// =============================================================================
// State
// =============================================================================

class _GlassSearchableBottomBarState extends State<GlassSearchableBottomBar>
    with TickerProviderStateMixin {
  /// Identical glass defaults to [GlassBottomBar] — ensures both widgets look
  /// the same when placed on the same screen.
  static const _defaultGlassColor = Color(0x3DFFFFFF);
  static const _defaultLightAngle = 0.75 * math.pi;
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

  // ── Layout state machine controller ─────────────────────────────────────
  // Owns focus state, spring target cache, and all layout computation.
  // The widget may supply an external controller (for programmatic control
  // or testing); if not, we create and own an internal one.
  late SearchableBottomBarController _controller;
  bool _ownsController = false;

  /// Named listener stored so [removeListener] can find the exact closure.
  /// Anonymous lambdas in [addListener]/[removeListener] create new objects
  /// each time and would never match, leaking the old subscription.
  void _onControllerChanged() => setState(() {});

  // ── Spring-simulation animation controllers ─────────────────────────────
  // Each drives one layout axis of the pill morph. Wide bounds allow the
  // spring to overshoot the target and snap back (the jelly effect).

  /// Animated current width of the tab-indicator pill.
  late AnimationController _tabWCtrl;

  /// Animated current left-edge of the search pill.
  late AnimationController _searchLeftCtrl;

  /// Animated current width of the search pill.
  late AnimationController _searchWCtrl;

  @override
  void initState() {
    super.initState();
    assert(
      widget.searchConfig.collapsedTabWidth == null ||
          widget.searchConfig.collapsedTabWidth! > 0,
      'GlassSearchBarConfig.collapsedTabWidth must be positive',
    );
    // Use the caller-supplied controller or create an internal one.
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = SearchableBottomBarController();
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);

    // Wide bounds allow the spring value to pass beyond [0, 1] for overshoot.
    _tabWCtrl = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(() => setState(() {}));
    _searchLeftCtrl = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(() => setState(() {}));
    _searchWCtrl = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant GlassSearchableBottomBar old) {
    super.didUpdateWidget(old);
    // Swap controller if the caller provides a new one.
    if (widget.controller != old.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = SearchableBottomBarController();
        _ownsController = true;
      }
      _controller.addListener(_onControllerChanged);
    }
    // Delegate focus-clear logic to the controller.
    _controller.onSearchActiveChanged(
      wasActive: old.isSearchActive,
      isActive: widget.isSearchActive,
    );
  }

  @override
  void dispose() {
    _tabWCtrl.dispose();
    _searchLeftCtrl.dispose();
    _searchWCtrl.dispose();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onFocusLost() {
    // Delegates to controller → triggers setState via listener.
    _controller.onFocusChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassQuality.premium,
    );
    final glassSettings = widget.glassSettings ?? _defaultGlassSettings;
    final searching = widget.isSearchActive;

    final barContent = TweenAnimationBuilder<double>(
      // Animate the pill height between full tab-bar height and compact
      // search-bar height — matching the iOS 26 Apple News morph where the
      // whole bar shrinks when search is active.
      tween: Tween<double>(
          end: searching ? widget.searchBarHeight : widget.barHeight),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, animH, child) {
        return AdaptiveLiquidGlassLayer(
          settings: glassSettings,
          quality: effectiveQuality,
          blendAmount: widget.blendAmount,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding,
              vertical: widget.verticalPadding,
            ),
            // LayoutBuilder provides real pixel widths so the spring
            // controllers can animate between explicit values.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalW = constraints.maxWidth;

                // ── Keyboard & dismiss state ──────────────────────────────────
                final keyboardH = MediaQuery.viewInsetsOf(context).bottom;
                final keyboardPresent = keyboardH > 0;
                final hasDismiss = widget.searchConfig.showsCancelButton;
                final isKeyboardActive =
                    _controller.searchFocused && keyboardPresent;
                final dismissVisible = searching &&
                    _controller.searchFocused &&
                    hasDismiss &&
                    keyboardPresent;

                final extraPos = widget.extraButton?.position ??
                    ExtraButtonPosition.beforeSearch;
                final extraFullW = widget.extraButton?.size ?? 0.0;
                final extraCollapsesOnSearch =
                    widget.extraButton?.collapseOnSearchFocus ?? true;

                // ── Delegate all layout math to the controller ────────────────
                final layout = _controller.computeLayout(
                  totalW: totalW,
                  searching: widget.isSearchActive,
                  expandWhenActive: widget.searchConfig.expandWhenActive,
                  barHeight: widget.barHeight,
                  searchBarHeight: widget.searchBarHeight,
                  spacing: widget.spacing,
                  hasDismiss: hasDismiss,
                  dismissVisible: dismissVisible,
                  collapsedTabWidth: widget.searchConfig.collapsedTabWidth,
                  tabPillAnchor: widget.tabPillAnchor,
                  extraFullW: extraFullW,
                  extraPos: extraPos,
                  extraCollapsesOnSearch: extraCollapsesOnSearch,
                  isKeyboardActive: isKeyboardActive,
                  keyboardH: keyboardH,
                );

                final targetTabW = layout.targetTabW;
                final targetSearchLeft = layout.targetSearchLeft;
                final targetSearchW = layout.targetSearchW;
                // Recompute per-position widths used for extra button Positioned
                // from the layout result (needed for rendering; not in layout type).
                final targetH =
                    searching ? widget.searchBarHeight : widget.barHeight;
                final extraTargetW = layout.extraTargetW;
                final extraWLeft = (extraFullW > 0 &&
                        extraPos == ExtraButtonPosition.beforeSearch)
                    ? (extraTargetW + widget.spacing)
                    : 0.0;
                final doCollapseLayout =
                    isKeyboardActive && extraCollapsesOnSearch;
                final targetDismissReserve = layout.dismissReserve;
                final centeredTab =
                    widget.tabPillAnchor == GlassTabPillAnchor.center;
                final maxTabW = totalW -
                    targetH -
                    widget.spacing -
                    (extraFullW > 0 &&
                            extraPos == ExtraButtonPosition.beforeSearch
                        ? extraFullW + widget.spacing
                        : 0.0) -
                    (extraFullW > 0 &&
                            extraPos == ExtraButtonPosition.afterSearch
                        ? extraFullW + widget.spacing
                        : 0.0);

                // ── Spring trigger (post-frame to stay outside build phase) ────
                if (!_controller.pillsInitialized &&
                    !_controller.pillsInitScheduled) {
                  _controller.markInitScheduled(totalW: totalW);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _tabWCtrl.value = targetTabW;
                    _searchLeftCtrl.value = targetSearchLeft;
                    _searchWCtrl.value = targetSearchW;
                    _controller.initializePills(
                      tabW: targetTabW,
                      searchLeft: targetSearchLeft,
                      searchW: targetSearchW,
                    );
                  });
                } else if (_controller.pillsInitialized) {
                  final retarget = _controller.checkRetarget(layout);
                  if (retarget.any) {
                    // Capture current spring positions before the post-frame delay.
                    final fromTabW = _tabWCtrl.value;
                    final fromLeft = _searchLeftCtrl.value;
                    final fromSearchW = _searchWCtrl.value;
                    final toTabW = targetTabW;
                    final toLeft = targetSearchLeft;
                    final toSearchW = targetSearchW;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final spring = widget.springDescription ??
                          GlassSearchableBottomBar._kSpring;
                      if (retarget.tabW) {
                        _tabWCtrl.animateWith(
                            SearchableBottomBarController.makeSpring(
                                spring: spring, from: fromTabW, to: toTabW));
                      }
                      if (retarget.searchLeft) {
                        _searchLeftCtrl.animateWith(
                            SearchableBottomBarController.makeSpring(
                                spring: spring, from: fromLeft, to: toLeft));
                      }
                      if (retarget.searchW) {
                        _searchWCtrl.animateWith(
                            SearchableBottomBarController.makeSpring(
                                spring: spring,
                                from: fromSearchW,
                                to: toSearchW));
                      }
                    });
                  }
                  if (totalW != _controller.cachedTotalW) {
                    _controller.cachedTotalW = totalW;
                  }
                }

                // Current animated positions (spring-driven or initialized target).
                // Clamped to [0, totalW] so spring overshoot never produces a
                // negative Positioned width — which would throw a RenderBox error.
                final curTabW = (_controller.pillsInitialized
                        ? _tabWCtrl.value
                        : targetTabW)
                    .clamp(0.0, totalW);

                // Horizontal anchor for the tab pill.
                // center mode: left = (maxTabW - curTabW) / 2.
                // Derived from the spring-driven curTabW — no extra controller
                // needed. When curTabW == maxTabW the result is 0 (no gap),
                // identical to start mode when the pill is fully expanded.
                final curTabLeft = centeredTab
                    ? ((maxTabW - curTabW) / 2).clamp(0.0, maxTabW)
                    : 0.0;

                final curSearchLeft = (_controller.pillsInitialized
                        ? _searchLeftCtrl.value
                        : targetSearchLeft)
                    .clamp(0.0, totalW);
                final curSearchW = (_controller.pillsInitialized
                        ? _searchWCtrl.value
                        : targetSearchW)
                    .clamp(0.0, totalW);

                // Y lift that moves pills above the keyboard.
                // The SizedBox height expands by floatY while the dismiss pill is
                // visible so that the pill stays inside the widget's hit-test region.
                // Consequence: Scaffold.bottomNavigationBar temporarily reports a
                // taller size to the Scaffold while the keyboard is open and the
                // dismiss pill is shown. With resizeToAvoidBottomInset:false and
                // extendBody:true this only affects body MediaQuery.padding.bottom.
                // For search-state body content that uses bottom padding, wrap with
                // MediaQuery.removePadding(removeBottom:true).
                // floatY is pre-computed by the controller (depends on
                // _searchFocused and keyboardH, both of which it owns).
                final floatY = layout.floatY;
                final totalH = animH + floatY;

                // ── Stack layout ──────────────────────────────────────────────────
                return SizedBox(
                  width: totalW,
                  height: totalH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── 1. Tab pill (spring-driven width, optional centre anchor) ─
                      Positioned(
                        left: curTabLeft,
                        bottom: 0,
                        width: math.max(0.01, curTabW),
                        height: animH,
                        child: SearchableTabIndicator(
                          quality: effectiveQuality,
                          visible: widget.showIndicator && !searching,
                          tabIndex: widget.selectedIndex,
                          tabCount: widget.tabs.length,
                          onTabChanged: widget.onTabSelected,
                          barHeight: animH,
                          barBorderRadius: widget.barBorderRadius,
                          tabPadding: widget.tabPadding,
                          maskingQuality: widget.maskingQuality,
                          magnification: widget.magnification,
                          innerBlur: widget.innerBlur,
                          indicatorColor: widget.indicatorColor,
                          indicatorSettings: widget.indicatorSettings,
                          backgroundKey: widget.backgroundKey,
                          isSearchActive: searching,
                          interactionGlowColor:
                              widget.interactionBehavior.hasGlow
                                  ? widget.interactionGlowColor
                                  : Colors.transparent,
                          interactionGlowRadius: widget.interactionGlowRadius,
                          enableBackgroundAnimation:
                              widget.interactionBehavior.hasScale,
                          backgroundPressScale: widget.pressScale,
                          indicatorBehindIcons: widget.indicatorBehindIcons,
                          collapsedLogoBuilder:
                              widget.searchConfig.collapsedLogoBuilder ??
                                  (context) {
                                    final currentTab =
                                        widget.tabs[widget.selectedIndex];
                                    return Center(
                                      child: IconTheme(
                                        data: IconThemeData(
                                          color: widget.unselectedIconColor,
                                          size: widget.iconSize,
                                        ),
                                        child: currentTab.activeIcon ??
                                            currentTab.icon,
                                      ),
                                    );
                                  },
                          onDismissSearch: () =>
                              widget.searchConfig.onSearchToggle(false),
                          childUnselected: _buildTabRow(selected: false),
                          selectedTabBuilder: (ctx, intensity, alignment) =>
                              _buildTabRow(
                            selected: true,
                            intensity: intensity,
                            alignment: alignment,
                          ),
                        ),
                      ),

                      // ── 2. Optional extra button ─────────────────────────────
                      if (widget.extraButton != null)
                        Positioned(
                          left: extraPos == ExtraButtonPosition.beforeSearch
                              ? curSearchLeft - extraWLeft
                              : null,
                          right: extraPos == ExtraButtonPosition.afterSearch
                              ? (dismissVisible ? targetDismissReserve : 0.0)
                              : null,
                          // When the button doesn't collapse it floats above the
                          // keyboard with the search pill (bottom: floatY).
                          // When it collapses it stays anchored at bottom: 0.
                          bottom: extraCollapsesOnSearch ? 0 : floatY,
                          // extraTargetW is min(size, targetH) when searching+collapsing,
                          // else full size. Rendered width must match layout reserve exactly.
                          width: doCollapseLayout
                              ? math.min(extraTargetW, animH)
                              : extraTargetW,
                          height: animH,
                          // Fade the extra button out when search is active.
                          // The layout space stays reserved so no pills jump.
                          // This matches collapsedTab which also hides its
                          // icons during the morph — consistent behaviour.
                          child: AnimatedOpacity(
                            opacity: (searching && extraCollapsesOnSearch)
                                ? 0.0
                                : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            child: IgnorePointer(
                              ignoring: searching && extraCollapsesOnSearch,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: BottomBarExtraBtn(
                                  config: widget.extraButton!,
                                  quality: effectiveQuality,
                                  iconColor: widget.extraButton!.iconColor ??
                                      widget.unselectedIconColor,
                                  borderRadius: widget.barBorderRadius ==
                                          GlassSearchableBottomBar
                                              ._kDefaultBorderRadius
                                      ? null
                                      : widget.barBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ── 3. Search pill (spring-driven left + width) ─────────────
                      // Positioned at bottom: floatY so the pill floats above the
                      // keyboard. Both pills share the parent AdaptiveLiquidGlassLayer
                      // so glass settings, colour, and liquid-stretch effects are
                      // perfectly matched — they render as one unified glass surface.
                      Positioned(
                        left: curSearchLeft,
                        bottom: floatY,
                        width: math.max(0.01, curSearchW),
                        height: animH,
                        child: SearchPill(
                          config: widget.searchConfig,
                          isActive: searching,
                          barBorderRadius: widget.barBorderRadius,
                          quality: effectiveQuality,
                          enableBackgroundAnimation:
                              widget.interactionBehavior.hasScale,
                          backgroundPressScale: widget.pressScale,
                          interactionGlowColor:
                              widget.interactionBehavior.hasGlow
                                  ? widget.interactionGlowColor
                                  : Colors.transparent,
                          interactionGlowRadius: widget.interactionGlowRadius,
                          onFocusChanged: (focused) {
                            if (focused) {
                              _controller.onFocusChanged(true);
                            } else {
                              _onFocusLost();
                            }
                            widget.searchConfig.onSearchFocusChanged
                                ?.call(focused);
                          },
                        ),
                      ),

                      // ── 4. Dismiss × pill (in-stack, shared glass layer) ────────
                      // Lives in the same AdaptiveLiquidGlassLayer as the search
                      // pill so glass colour, blur and lighting are identical.
                      // The SizedBox expansion above ensures this Positioned node
                      // is within the widget's hit-test bounds even when floating
                      // above the keyboard.
                      if (hasDismiss && dismissVisible)
                        Positioned(
                          right: 0,
                          bottom: floatY,
                          width: animH,
                          height: animH,
                          child: DismissPill(
                            onTap: () => FocusScope.of(context).unfocus(),
                            pillSize: animH,
                            barBorderRadius: widget.barBorderRadius,
                            quality: effectiveQuality,
                            indicatorColor: widget.indicatorColor,
                            glassSettings: widget.glassSettings,
                            cancelButtonColor:
                                widget.searchConfig.cancelButtonColor,
                          ),
                        ),
                    ],
                  ),
                ); // SizedBox
              },
            ),
          ),
        );
      },
    );

    return barContent;
  } // build()

  Widget _buildTabRow({
    required bool selected,
    double intensity = 0,
    Alignment alignment = Alignment.center,
  }) {
    if (selected) {
      final scale = ui.lerpDouble(1.0, widget.magnification, intensity) ?? 1.0;
      final currentTabFloat = ((alignment.x + 1) / 2) * widget.tabs.length;
      final aStart =
          (currentTabFloat - 1).floor().clamp(0, widget.tabs.length - 1);
      final aEnd =
          (currentTabFloat + 1).ceil().clamp(0, widget.tabs.length - 1);

      return Row(
        children: [
          for (var i = 0; i < widget.tabs.length; i++)
            Expanded(
              child: (i >= aStart && i <= aEnd)
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
                        // SearchableTabIndicator.onBarTapDown (prevents double-fire).
                        onTap: null,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      );
    }

    // Unselected row — no per-tab RepaintBoundary needed; the combined
    // icon layer in SearchableTabIndicator wraps the whole row.
    return Row(
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
              // SearchableTabIndicator.onBarTapDown (prevents double-fire).
              onTap: null,
            ),
          ),
      ],
    );
  }
}

// Private sub-widgets (_DismissPill, _SearchPill, _SearchableTabIndicator)
// have been extracted to:
//   lib/widgets/surfaces/shared/searchable_bottom_bar_internal.dart
// They are imported above as DismissPill, SearchPill, SearchableTabIndicator.
