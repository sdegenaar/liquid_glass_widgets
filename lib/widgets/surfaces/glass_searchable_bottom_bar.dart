// Using deprecated Colors.withOpacity for backwards compatibility.
// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';
import '../../utils/glass_spring.dart';
import '../interactive/glass_button.dart';
import '../shared/adaptive_glass.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/animated_glass_indicator.dart';
import '../shared/inherited_liquid_glass.dart';
import 'glass_bottom_bar.dart'
    show
        GlassBottomBarExtraButton,
        GlassBottomBarTab,
        MaskingQuality,
        JellyClipper;
import 'shared/bottom_bar_internal.dart';

// =============================================================================
// Public API — GlassSearchBarConfig
// =============================================================================

/// Configuration for the morphing search bar in [GlassSearchableBottomBar].
///
/// When the user taps the collapsed search pill, [onSearchToggle] is called
/// with `true`. Set [GlassSearchableBottomBar.isSearchActive] to `true` to
/// expand the search bar and collapse the tab pill.
///
/// ## Example
/// ```dart
/// GlassSearchableBottomBar(
///   tabs: [...],
///   selectedIndex: _tab,
///   onTabSelected: (i) => setState(() => _tab = i),
///   isSearchActive: _searching,
///   searchConfig: GlassSearchBarConfig(
///     onSearchToggle: (v) => setState(() => _searching = v),
///     hintText: 'Apple News',
///     collapsedLogoBuilder: (ctx) => ..., // N logo shown when searching
///   ),
/// )
/// ```
class GlassSearchBarConfig {
  /// Creates a search bar configuration.
  const GlassSearchBarConfig({
    required this.onSearchToggle,
    this.hintText = 'Search',
    this.collapsedTabWidth = 64.0,
    this.collapsedLogoBuilder,
    this.searchIconColor,
    this.micIconColor,
    this.hintStyle,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onMicTap,
    this.textColor,
    this.trailingBuilder,
    this.textInputAction,
    this.keyboardType,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onTapOutside,
    this.autoFocusOnExpand = false,
    this.showsCancelButton = false,
    this.cancelButtonText = 'Cancel',
    this.cancelButtonColor,
    this.onSearchFocusChanged,
  });

  /// Called with `true` when search is activated, `false` when dismissed.
  final ValueChanged<bool> onSearchToggle;

  /// Placeholder text in the expanded search bar. Defaults to `'Search'`.
  final String hintText;

  /// Width of the collapsed tab pill when search is active. Defaults to 64.
  final double collapsedTabWidth;

  /// Widget shown inside the collapsed tab pill when search is active.
  ///
  /// Typically an app logo mark. If null the pill is an empty glass surface.
  final WidgetBuilder? collapsedLogoBuilder;

  /// Color for the 🔍 and 🎙️ icons. Defaults to `Colors.white60`.
  final Color? searchIconColor;

  /// Color for the microphone icon specifically. Falls back to [searchIconColor].
  ///
  /// Ignored when [trailingBuilder] is provided.
  final Color? micIconColor;

  /// Text style for the hint text. Uses a sensible default when null.
  final TextStyle? hintStyle;

  /// Optional controller for the search text field.
  ///
  /// If null, the widget manages its own internal controller.
  final TextEditingController? controller;

  /// Called on every keystroke as the user types in the search field.
  ///
  /// Use this for live/incremental search filtering. For submit-only
  /// behaviour (e.g. triggering a network request on Enter) use [onSubmitted].
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search (keyboard action).
  final ValueChanged<String>? onSubmitted;

  /// Called when the user taps the microphone icon.
  ///
  /// When null the microphone icon is hidden. Ignored when [trailingBuilder]
  /// is provided (the builder is responsible for its own tap handling).
  final VoidCallback? onMicTap;

  /// Color of the typed text. Defaults to white.
  final Color? textColor;

  // ── SearchBar parity ────────────────────────────────────────────────────────

  /// Custom widget builder for the trailing section of the expanded search bar.
  ///
  /// When provided, **completely replaces** the microphone icon and [onMicTap]
  /// behaviour. Use this to show a "Clear" button, voice-action indicator, or
  /// any other widget in the trailing position — matching Flutter's own
  /// [SearchBar.trailing] API.
  ///
  /// The builder receives a [BuildContext] that is a descendant of the
  /// expanded glass pill. If null, the standard mic icon / empty logic applies.
  ///
  /// ## Example — clear button
  /// ```dart
  /// trailingBuilder: (ctx) => GestureDetector(
  ///   onTap: () => searchController.clear(),
  ///   child: Icon(CupertinoIcons.clear_circled_solid,
  ///       color: Colors.white54, size: 18),
  /// ),
  /// ```
  final WidgetBuilder? trailingBuilder;

  /// The keyboard action button label for the search [TextField].
  ///
  /// Common values: [TextInputAction.search], [TextInputAction.done],
  /// [TextInputAction.go]. Defaults to null (system / platform default).
  final TextInputAction? textInputAction;

  /// The type of keyboard to display for the search [TextField].
  ///
  /// Defaults to null, which uses [TextInputType.text]. Pass
  /// [TextInputType.url] or [TextInputType.emailAddress] for specialised
  /// search contexts.
  final TextInputType? keyboardType;

  /// Whether to enable autocorrection for the search [TextField].
  ///
  /// Defaults to `true`. Set to `false` for search bars where autocorrection
  /// would interfere (e.g. product codes, usernames).
  final bool autocorrect;

  /// Whether to show input suggestions (QuickType bar on iOS) for the search
  /// [TextField].
  ///
  /// Defaults to `true`. Mirrors [TextField.enableSuggestions].
  final bool enableSuggestions;

  /// Called when the user taps outside the expanded search [TextField].
  ///
  /// Passed directly to [TextField.onTapOutside]. A common use-case is
  /// unfocusing the field so the keyboard dismisses when the user taps the
  /// page content above the bar:
  ///
  /// ```dart
  /// onTapOutside: (_) => FocusScope.of(context).unfocus(),
  /// ```
  final TapRegionCallback? onTapOutside;

  /// Whether the search [TextField] should automatically receive keyboard focus
  /// when the search bar expands.
  ///
  /// - `false` (default): the bar expands without triggering the keyboard;
  ///   the user taps inside the pill to start typing. Matches the behaviour
  ///   of the real iOS 26 Apple News search bar and looks more polished.
  /// - `true`: the keyboard opens automatically as soon as the bar expands —
  ///   useful for modal or dedicated search screens where typing is the
  ///   immediate next action.
  final bool autoFocusOnExpand;

  /// Whether to show a "Cancel" button that slides in from the right when the
  /// search field is focused, matching iOS UISearchBar behaviour.
  ///
  /// Tapping Cancel clears the field, dismisses the keyboard, and calls
  /// [onSearchToggle] with `false` to collapse the search bar.
  ///
  /// Defaults to `false`.
  final bool showsCancelButton;

  /// Label for the slide-in cancel button.
  ///
  /// Defaults to `'Cancel'`.
  final String cancelButtonText;

  /// Color of the cancel button text.
  ///
  /// Defaults to white with 90 % opacity, matching iOS system style.
  final Color? cancelButtonColor;

  /// Called whenever the search field gains or loses keyboard focus.
  ///
  /// `true`  — keyboard is visible, field is active.
  /// `false` — keyboard dismissed, field is unfocused.
  ///
  /// Use this to switch the body content between a focused search state
  /// (e.g. "No Recent Searches") and an unfocused search state (e.g. a topic
  /// browse grid), without fully closing the search bar.
  final ValueChanged<bool>? onSearchFocusChanged;
}

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
    this.isSearchActive = false,
    this.extraButton,
    this.spacing = 8,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.barHeight = 64,
    this.searchBarHeight,
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
    this.quality,
    this.magnification = 1.0,
    this.innerBlur = 0.0,
    this.maskingQuality = MaskingQuality.high,
    this.backgroundKey,
    this.springDescription,
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

  /// Height of the pills when search is active. Defaults to `barHeight`.
  ///
  /// In iOS 26 Apple News the search bar is noticeably shorter than the full
  /// tab bar (which must accommodate icon + label). Set this to e.g. `50`
  /// to replicate that compact feel. The transition is animated with the
  /// same 300 ms easeInOutCubic curve used for all other bar morphs.
  final double? searchBarHeight;

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

  // ── Advanced ─────────────────────────────────────────────────────────────────
  /// Magnification factor for the selected indicator lens effect. Defaults to 1.0.
  final double magnification;

  /// Blur amount inside the selected indicator. Defaults to 0.0.
  final double innerBlur;

  /// Rendering quality for the liquid masking effect. Defaults to [MaskingQuality.high].
  final MaskingQuality maskingQuality;

  /// Background key for Skia/web refraction. Optional.
  final GlobalKey? backgroundKey;

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

  /// Whether the search text field is currently focused (keyboard visible).
  bool _searchFocused = false;

  // ── Spring-simulation animation controllers ─────────────────────────────
  // Each drives one layout axis of the pill morph. Wide bounds allow the
  // spring to overshoot the target and snap back (the jelly effect).

  /// Animated current width of the tab-indicator pill.
  late AnimationController _tabWCtrl;

  /// Animated current left-edge of the search pill.
  late AnimationController _searchLeftCtrl;

  /// Animated current width of the search pill.
  late AnimationController _searchWCtrl;

  /// False until the first LayoutBuilder pass has run and the controllers
  /// have been initialized to their correct starting positions.
  bool _pillsInitialized = false;

  /// Guard: prevents scheduling multiple init callbacks before the first
  /// post-frame fires (handles rapid rebuilds at startup / hot reload).
  bool _pillsInitScheduled = false;

  // Cached spring targets — spring is only re-triggered when target changes.
  double _prevTabWTarget = double.nan;
  double _prevSearchLeftTarget = double.nan;
  double _prevSearchWTarget = double.nan;
  double _cachedTotalW = 0;

  @override
  void initState() {
    super.initState();
    assert(
      widget.searchConfig.collapsedTabWidth > 0,
      'GlassSearchBarConfig.collapsedTabWidth must be positive',
    );
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
  void dispose() {
    _tabWCtrl.dispose();
    _searchLeftCtrl.dispose();
    _searchWCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GlassSearchableBottomBar old) {
    super.didUpdateWidget(old);
    // When search is deactivated from outside, clear focus flag.
    if (old.isSearchActive && !widget.isSearchActive && _searchFocused) {
      _searchFocused = false;
    }
  }

  void _onFocusLost() {
    // Clears _searchFocused → next build has dismissVisible=false →
    // the LayoutBuilder detects the transition and schedules unmount.
    setState(() => _searchFocused = false);
  }

  @override
  Widget build(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>();
    final effectiveQuality =
        widget.quality ?? inherited?.quality ?? GlassQuality.premium;
    final glassSettings = widget.glassSettings ?? _defaultGlassSettings;
    final searching = widget.isSearchActive;
    final effectiveSearchH = widget.searchBarHeight ?? widget.barHeight;

    return TweenAnimationBuilder<double>(
      // Animate the pill height between full tab-bar height and compact
      // search-bar height — matching the iOS 26 Apple News morph where the
      // whole bar shrinks when search is active.
      tween:
          Tween<double>(end: searching ? effectiveSearchH : widget.barHeight),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (_, animH, __) {
        return AdaptiveLiquidGlassLayer(
          settings: glassSettings,
          quality: effectiveQuality,
          blendAmount: widget.blendAmount,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding,
              vertical: widget.verticalPadding,
            ),
            // LayoutBuilder provides real pixel widths so AnimatedContainer
            // can spring between explicit values — no null-width hacks.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalW = constraints.maxWidth;
                final extraW = widget.extraButton != null
                    ? (widget.extraButton!.size + widget.spacing)
                    : 0.0;

                // ── Keyboard & dismiss state ──────────────────────────────────
                final keyboardH = MediaQuery.viewInsetsOf(context).bottom;
                final keyboardPresent = keyboardH > 0;
                final hasDismiss = widget.searchConfig.showsCancelButton;
                final dismissVisible = searching &&
                    _searchFocused &&
                    hasDismiss &&
                    keyboardPresent;

                // ── Spring target computation ─────────────────────────────────────
                // Targets use the FINAL stable heights (widget.barHeight /
                // effectiveSearchH) rather than the in-flight animH, so the spring
                // is not re-triggered on every frame of the height animation.
                final targetH = searching ? effectiveSearchH : widget.barHeight;
                final targetCompactW = targetH;
                final targetDismissW = hasDismiss ? targetH : 0.0;
                final targetDismissReserve =
                    hasDismiss ? (targetDismissW + widget.spacing) : 0.0;

                final targetTabW = !searching
                    ? (totalW - targetCompactW - extraW - widget.spacing)
                    : math.min(widget.searchConfig.collapsedTabWidth, targetH);

                final targetSearchLeft = !searching
                    ? totalW - targetCompactW
                    : (_searchFocused && keyboardPresent)
                        ? 0.0
                        : (targetTabW + extraW + widget.spacing);

                final targetSearchW = !searching
                    ? targetCompactW
                    : (hasDismiss && _searchFocused && keyboardPresent)
                        ? totalW - targetDismissReserve
                        : totalW - targetSearchLeft;

                // ── Spring trigger (post-frame to stay outside build phase) ────────
                if (!_pillsInitialized && !_pillsInitScheduled) {
                  // First layout pass: initialize controllers to target values.
                  // Guard _pillsInitScheduled prevents duplicate callbacks when
                  // the parent rebuilds multiple times before first post-frame.
                  _pillsInitScheduled = true;
                  _cachedTotalW = totalW;
                  _prevTabWTarget = targetTabW;
                  _prevSearchLeftTarget = targetSearchLeft;
                  _prevSearchWTarget = targetSearchW;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _tabWCtrl.value = targetTabW;
                    _searchLeftCtrl.value = targetSearchLeft;
                    _searchWCtrl.value = targetSearchW;
                    setState(() {
                      _pillsInitialized = true;
                      _pillsInitScheduled = false;
                    });
                  });
                } else if (_pillsInitialized) {
                  // Retarget only when the destination actually changes.
                  if (targetTabW != _prevTabWTarget) {
                    final from = _tabWCtrl.value;
                    final to = targetTabW;
                    _prevTabWTarget = to;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _tabWCtrl.animateWith(SpringSimulation(
                            (widget.springDescription ??
                                GlassSearchableBottomBar._kSpring),
                            from,
                            to,
                            0.0));
                      }
                    });
                  }
                  if (targetSearchLeft != _prevSearchLeftTarget) {
                    final from = _searchLeftCtrl.value;
                    final to = targetSearchLeft;
                    _prevSearchLeftTarget = to;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _searchLeftCtrl.animateWith(SpringSimulation(
                            (widget.springDescription ??
                                GlassSearchableBottomBar._kSpring),
                            from,
                            to,
                            0.0));
                      }
                    });
                  }
                  if (targetSearchW != _prevSearchWTarget) {
                    final from = _searchWCtrl.value;
                    final to = targetSearchW;
                    _prevSearchWTarget = to;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _searchWCtrl.animateWith(SpringSimulation(
                            (widget.springDescription ??
                                GlassSearchableBottomBar._kSpring),
                            from,
                            to,
                            0.0));
                      }
                    });
                  }
                  if (totalW != _cachedTotalW) _cachedTotalW = totalW;
                }

                // Current animated positions (spring-driven or initialized target).
                // Clamped to [0, totalW] so spring overshoot never produces a
                // negative Positioned width — which would throw a RenderBox error.
                final curTabW =
                    (_pillsInitialized ? _tabWCtrl.value : targetTabW)
                        .clamp(0.0, totalW);
                final curSearchLeft = (_pillsInitialized
                        ? _searchLeftCtrl.value
                        : targetSearchLeft)
                    .clamp(0.0, totalW);
                final curSearchW =
                    (_pillsInitialized ? _searchWCtrl.value : targetSearchW)
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
                final floatY = dismissVisible ? keyboardH : 0.0;
                final totalH = animH + floatY;

                // ── Stack layout ──────────────────────────────────────────────────
                return SizedBox(
                  width: totalW,
                  height: totalH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── 1. Tab pill (spring-driven width) ────────────────────────
                      Positioned(
                        left: 0,
                        bottom: 0,
                        width: curTabW,
                        height: animH,
                        child: _SearchableTabIndicator(
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
                          collapsedLogoBuilder:
                              widget.searchConfig.collapsedLogoBuilder,
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

                      // ── 2. Optional extra button (tracks tab pill spring) ────────
                      if (widget.extraButton != null)
                        Positioned(
                          left: curTabW + widget.spacing,
                          bottom: 0,
                          width: widget.extraButton!.size,
                          height: animH,
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

                      // ── 3. Search pill (spring-driven left + width) ─────────────
                      // Positioned at bottom: floatY so the pill floats above the
                      // keyboard. Both pills share the parent AdaptiveLiquidGlassLayer
                      // so glass settings, colour, and liquid-stretch effects are
                      // perfectly matched — they render as one unified glass surface.
                      Positioned(
                        left: curSearchLeft,
                        bottom: floatY,
                        width: curSearchW,
                        height: animH,
                        child: _SearchPill(
                          config: widget.searchConfig,
                          isActive: searching,
                          barBorderRadius: widget.barBorderRadius,
                          quality: effectiveQuality,
                          onFocusChanged: (focused) {
                            if (focused) {
                              setState(() => _searchFocused = true);
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
                          child: _DismissPill(
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
                );
              },
            ),
          ),
        ); // AdaptiveLiquidGlassLayer
      }, // TweenAnimationBuilder.builder
    ); // TweenAnimationBuilder
  }

  Widget _buildTabRow({
    required bool selected,
    double intensity = 0,
    Alignment alignment = Alignment.center,
  }) {
    if (selected) {
      final scale = ui.lerpDouble(1.0, widget.magnification, intensity) ?? 1.0;
      final blur = ui.lerpDouble(0.0, widget.innerBlur, intensity) ?? 0.0;
      final currentTabFloat = ((alignment.x + 1) / 2) * widget.tabs.length;
      final aStart =
          (currentTabFloat - 1).floor().clamp(0, widget.tabs.length - 1);
      final aEnd =
          (currentTabFloat + 1).ceil().clamp(0, widget.tabs.length - 1);

      Widget row = Row(
        children: [
          for (var i = 0; i < widget.tabs.length; i++)
            Expanded(
              child: (i >= aStart && i <= aEnd)
                  ? RepaintBoundary(
                      child: Transform.scale(
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
                          onTap: () => widget.onTabSelected(i),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      );
      if (blur > 0) {
        row = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: row);
      }
      return row;
    }

    // Unselected row
    return Row(
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          Expanded(
            child: RepaintBoundary(
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
                onTap: () => widget.onTabSelected(i),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// _DismissPill
// =============================================================================
// Rendered inside the parent [AdaptiveLiquidGlassLayer] (same layer as the
// search pill and tab pill) so that all three glass surfaces share the identical
// shader context. This gives perfect colour, blur, and lighting parity with no
// additional configuration required.
//
// Hit-testing works because the parent [SizedBox] expands its height by
// [keyboardH] while the pill is visible, keeping the pill inside the widget's
// layout bounds even when it floats above the keyboard.

class _DismissPill extends StatelessWidget {
  const _DismissPill({
    required this.onTap,
    required this.pillSize,
    required this.barBorderRadius,
    required this.quality,
    this.cancelButtonColor,
    this.indicatorColor,
    this.glassSettings,
  });

  final VoidCallback onTap;
  final double pillSize;
  final double barBorderRadius;
  final GlassQuality quality;
  final Color? cancelButtonColor;
  final Color? indicatorColor;
  final LiquidGlassSettings? glassSettings;

  @override
  Widget build(BuildContext context) {
    final safeColor = indicatorColor;
    return GlassButton(
      onTap: onTap,
      width: pillSize,
      height: pillSize,
      quality: quality,
      // useOwnLayer defaults to false — the pill participates in the parent
      // AdaptiveLiquidGlassLayer so glass colour, blur and lighting are
      // identical to the adjacent search pill.
      settings: glassSettings?.copyWith(
              glassColor: safeColor ?? glassSettings?.glassColor) ??
          (safeColor != null
              ? LiquidGlassSettings(glassColor: safeColor)
              : null),
      shape: LiquidRoundedSuperellipse(borderRadius: barBorderRadius),
      icon: Icon(
        CupertinoIcons.xmark,
        color: cancelButtonColor ?? const Color(0xE6FFFFFF),
        size: 16,
      ),
      iconColor: cancelButtonColor ?? const Color(0xE6FFFFFF),
    );
  }
}

// =============================================================================
// _SearchableTabIndicator
// =============================================================================

/// Draggable glass indicator for [GlassSearchableBottomBar].
///
/// Uses identical spring physics and masking to [GlassBottomBar]'s internal
/// `_TabIndicator`. When [isSearchActive] is `true`, it collapses to show only
/// the [collapsedLogoBuilder] and a tap dismisses search.
class _SearchableTabIndicator extends StatefulWidget {
  const _SearchableTabIndicator({
    required this.childUnselected,
    required this.selectedTabBuilder,
    required this.tabIndex,
    required this.tabCount,
    required this.onTabChanged,
    required this.visible,
    required this.quality,
    required this.barHeight,
    required this.barBorderRadius,
    required this.tabPadding,
    required this.magnification,
    required this.innerBlur,
    required this.maskingQuality,
    required this.isSearchActive,
    required this.onDismissSearch,
    this.indicatorColor,
    this.indicatorSettings,
    this.backgroundKey,
    this.collapsedLogoBuilder,
  });

  final int tabIndex;
  final int tabCount;
  final bool visible;
  final Widget childUnselected;
  final Widget Function(BuildContext, double, Alignment) selectedTabBuilder;
  final Color? indicatorColor;
  final LiquidGlassSettings? indicatorSettings;
  final ValueChanged<int> onTabChanged;
  final GlassQuality quality;
  final double barHeight;
  final double barBorderRadius;
  final EdgeInsetsGeometry tabPadding;
  final double magnification;
  final double innerBlur;
  final MaskingQuality maskingQuality;
  final GlobalKey? backgroundKey;
  final bool isSearchActive;
  final VoidCallback onDismissSearch;
  final WidgetBuilder? collapsedLogoBuilder;

  @override
  State<_SearchableTabIndicator> createState() =>
      _SearchableTabIndicatorState();
}

class _SearchableTabIndicatorState extends State<_SearchableTabIndicator> {
  static const _fallbackIndicatorColor = Color(0x1AFFFFFF);

  bool _isDown = false;
  bool _isDragging = false;
  late double _xAlign = _alignFor(widget.tabIndex);
  late LiquidRoundedSuperellipse _barShape =
      LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);

  @override
  void didUpdateWidget(covariant _SearchableTabIndicator old) {
    super.didUpdateWidget(old);
    if (old.tabIndex != widget.tabIndex || old.tabCount != widget.tabCount) {
      setState(() => _xAlign = _alignFor(widget.tabIndex));
    }
    if (old.barBorderRadius != widget.barBorderRadius) {
      _barShape =
          LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);
    }
  }

  double _alignFor(int i) =>
      DraggableIndicatorPhysics.computeAlignment(i, widget.tabCount);

  double _alignFromGlobal(Offset g) =>
      DraggableIndicatorPhysics.getAlignmentFromGlobalPosition(
          g, context, widget.tabCount);

  void _onDragDown(DragDownDetails d) {
    setState(() => _isDown = true);
  }

  void _onBarTapDown(TapDownDetails d) {
    final relX = (_alignFromGlobal(d.globalPosition) + 1) / 2;
    final idx = (relX * widget.tabCount).floor().clamp(0, widget.tabCount - 1);
    if (idx != widget.tabIndex) widget.onTabChanged(idx);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _isDragging = true;
      _xAlign = _alignFromGlobal(d.globalPosition);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    setState(() {
      _isDragging = false;
      _isDown = false;
    });
    final box = context.findRenderObject()! as RenderBox;
    final relX = (_xAlign + 1) / 2;
    final tabW = 1.0 / widget.tabCount;
    final draggableRange = 1.0 - tabW;
    final velX =
        (d.velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;
    final target = DraggableIndicatorPhysics.computeTargetIndex(
      currentRelativeX: relX,
      velocityX: velX,
      itemWidth: tabW,
      itemCount: widget.tabCount,
    );
    setState(() => _xAlign = _alignFor(target));
    if (target != widget.tabIndex) widget.onTabChanged(target);
  }

  void _onDragCancel() {
    if (_isDragging) {
      final relX = (_xAlign + 1) / 2;
      final tabW = 1.0 / widget.tabCount;
      final target = DraggableIndicatorPhysics.computeTargetIndex(
        currentRelativeX: relX,
        velocityX: 0,
        itemWidth: tabW,
        itemCount: widget.tabCount,
      );
      setState(() {
        _isDragging = false;
        _isDown = false;
        _xAlign = _alignFor(target);
      });
      if (target != widget.tabIndex) widget.onTabChanged(target);
    } else {
      setState(() => _xAlign = _alignFor(widget.tabIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Collapsed / search-active state ─────────────────────────────────────
    if (widget.isSearchActive) {
      return GlassButton(
        onTap: widget.onDismissSearch,
        width: double.infinity,
        height: widget.barHeight,
        quality: widget.quality,
        shape: _barShape,
        // Logo or empty — shown inside the glass button body.
        icon: widget.collapsedLogoBuilder != null
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: c),
                child: SizedBox.expand(
                  key: const ValueKey('logo'),
                  child: widget.collapsedLogoBuilder!(context),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      );
    }

    // ── Normal draggable tab bar — identical logic to GlassBottomBar ─────────
    final theme = CupertinoTheme.of(context);
    final indicatorColor = widget.indicatorColor ??
        theme.textTheme.textStyle.color?.withValues(alpha: .1) ??
        _fallbackIndicatorColor;
    final targetAlignment = _alignFor(widget.tabIndex);
    final backgroundRadius = widget.barBorderRadius * 2;
    final glassRadius = widget.barBorderRadius;

    return Listener(
      onPointerDown: (_) {
        setState(() => _isDown = true);
      },
      onPointerUp: (_) {
        if (!_isDragging) {
          setState(() => _isDown = false);
        }
      },
      onPointerCancel: (_) {
        if (!_isDragging) {
          setState(() => _isDown = false);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragDown: _onDragDown,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _onDragCancel,
        onTapDown: _onBarTapDown,
        child: VelocitySpringBuilder(
          value: _xAlign,
          springWhenActive: GlassSpring.interactive(),
          springWhenReleased: GlassSpring.snappy(
            duration: const Duration(milliseconds: 350),
          ),
          active: _isDragging,
          builder: (context, value, velocity, child) {
            final alignment = Alignment(value, 0);
            return SpringBuilder(
              spring: GlassSpring.snappy(
                duration: const Duration(milliseconds: 300),
              ),
              value: widget.visible &&
                      (_isDown || (alignment.x - targetAlignment).abs() > 0.05)
                  ? 1.0
                  : 0.0,
              builder: (context, thickness, _) {
                if (thickness < 0.01 &&
                    !widget.visible &&
                    widget.maskingQuality == MaskingQuality.high) {
                  return Container(
                    height: widget.barHeight,
                    decoration: ShapeDecoration(shape: _barShape),
                    child: AdaptiveGlass.grouped(
                      quality: widget.quality,
                      shape: _barShape,
                      child: Container(
                        padding: widget.tabPadding,
                        child: widget.childUnselected,
                      ),
                    ),
                  );
                }

                final jellyTransform =
                    DraggableIndicatorPhysics.buildJellyTransform(
                  velocity: Offset(velocity, 0),
                  maxDistortion: 0.8,
                  velocityScale: 10,
                );

                switch (widget.maskingQuality) {
                  case MaskingQuality.off:
                    return _buildSimple(
                      alignment: alignment,
                      thickness: thickness,
                      velocity: velocity,
                      backgroundRadius: backgroundRadius,
                      glassRadius: glassRadius,
                      indicatorColor: indicatorColor,
                    );
                  case MaskingQuality.high:
                    return _buildHighQuality(
                      alignment: alignment,
                      thickness: thickness,
                      velocity: velocity,
                      jellyTransform: jellyTransform,
                      backgroundRadius: backgroundRadius,
                      glassRadius: glassRadius,
                      indicatorColor: indicatorColor,
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSimple({
    required Alignment alignment,
    required double thickness,
    required double velocity,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    return SizedBox(
      height: widget.barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AdaptiveGlass.grouped(
              quality: widget.quality,
              shape: _barShape,
              child: Container(
                  padding: widget.tabPadding, child: widget.childUnselected),
            ),
          ),
          if (widget.visible && thickness > 0.05)
            AnimatedGlassIndicator(
              velocity: velocity,
              itemCount: widget.tabCount,
              alignment: alignment,
              thickness: thickness,
              quality: widget.quality,
              indicatorColor: indicatorColor,
              isBackgroundIndicator: false,
              borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
              padding: const EdgeInsets.all(4),
              expansion: 14,
              glassSettings: widget.indicatorSettings,
              backgroundKey: widget.backgroundKey,
            ),
        ],
      ),
    );
  }

  Widget _buildHighQuality({
    required Alignment alignment,
    required double thickness,
    required double velocity,
    required Matrix4 jellyTransform,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    final effRadius = thickness < 1 ? backgroundRadius : glassRadius;
    return SizedBox(
      height: widget.barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AdaptiveGlass.grouped(
              quality: widget.quality,
              shape: _barShape,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: JellyClipper(
                      itemCount: widget.tabCount,
                      alignment: alignment,
                      thickness: thickness,
                      expansion: 14,
                      transform: jellyTransform,
                      borderRadius: effRadius,
                      inverse: true,
                    ),
                    child: Container(
                      padding: widget.tabPadding,
                      height: widget.barHeight,
                      child: widget.childUnselected,
                    ),
                  ),
                  if (thickness > 0.05 || widget.visible)
                    ClipPath(
                      clipper: JellyClipper(
                        itemCount: widget.tabCount,
                        alignment: alignment,
                        thickness: thickness,
                        expansion: 14,
                        transform: jellyTransform,
                        borderRadius: effRadius,
                      ),
                      child: Container(
                        padding: widget.tabPadding,
                        height: widget.barHeight,
                        child: widget.selectedTabBuilder(
                            context, thickness, alignment),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedGlassIndicator(
            velocity: velocity,
            itemCount: widget.tabCount,
            alignment: alignment,
            thickness: thickness,
            quality: widget.quality,
            indicatorColor: indicatorColor,
            isBackgroundIndicator: false,
            borderRadius: effRadius,
            padding: const EdgeInsets.all(4),
            expansion: 14,
            glassSettings: widget.indicatorSettings,
            backgroundKey: widget.backgroundKey,
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: JellyClipper(
                    itemCount: widget.tabCount,
                    alignment: alignment,
                    thickness: thickness,
                    expansion: 14,
                    transform: jellyTransform,
                    borderRadius: effRadius,
                  ),
                  child: Container(
                    padding: widget.tabPadding,
                    height: widget.barHeight,
                    child: widget.selectedTabBuilder(
                        context, thickness, alignment),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _SearchPill
// =============================================================================

/// The morphing search pill. Collapses to a square icon; expands to a
/// real [TextField] with autofocus. Lives inside the parent
/// [AdaptiveLiquidGlassLayer] so its glass rendering blends with the tab pill.
class _SearchPill extends StatefulWidget {
  const _SearchPill({
    required this.config,
    required this.isActive,
    required this.barBorderRadius,
    required this.quality,
    this.onFocusChanged,
  });

  final GlassSearchBarConfig config;
  final bool isActive;
  final double barBorderRadius;
  final GlassQuality quality;

  /// Called when the search field gains or loses focus.
  /// Used by the parent bar to drive the dismiss pill visibility.
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;

  // Tracks whether the × clear button should be visible.
  bool _hasText = false;
  // Tracks focus so the outer bar can show/hide the dismiss pill.
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.config.controller != null) {
      _controller = widget.config.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _focusNode = FocusNode();

    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.isActive && widget.config.autoFocusOnExpand) {
      // Already active on first build — request focus after one frame so the
      // AnimatedContainer has committed its initial expanded layout.
      // 60 ms is enough for a single vsync cycle at 60-120 Hz while still
      // feeling instant to the user (well under the ~100 ms perception threshold).
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted && widget.isActive) _focusNode.requestFocus();
      });
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void didUpdateWidget(covariant _SearchPill old) {
    super.didUpdateWidget(old);
    if (!old.isActive && widget.isActive && widget.config.autoFocusOnExpand) {
      // Became active and auto-focus is enabled — request focus after one
      // render frame so the pill has committed its first expanded layout
      // before the IME is attached.
      //
      // 60 ms sits comfortably above a single 120 Hz vsync (~8 ms) and is
      // well below the ~100 ms human-perception threshold for "immediate".
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted && widget.isActive) _focusNode.requestFocus();
      });
    } else if (old.isActive && !widget.isActive) {
      // Dismissed — unfocus and clear.
      _focusNode.unfocus();
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _hasFocus) {
      setState(() => _hasFocus = hasFocus);
      widget.onFocusChanged?.call(hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.config.searchIconColor ?? Colors.white60;
    final micColor = widget.config.micIconColor ?? iconColor;
    final shape =
        LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);

    // LayoutBuilder reads the ACTUAL rendered width on every frame.
    // When isActive flips true, AnimatedContainer starts at compact width
    // (barHeight ≈ 64 px) and animates outward. The expanded Row needs at
    // least 84 px (padding 32 + icons 52). We gate on 90 px so the Row is
    // never built at compact width → no layout overflow, no content bleed.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const kExpandThreshold = 90.0;

        if (!widget.isActive || w < kExpandThreshold) {
          return Stack(
            fit: StackFit.expand,
            children: [
              GlassButton(
                key: const ValueKey('pill-collapsed'),
                icon: Icon(CupertinoIcons.search, color: iconColor),
                // No-op while mid-animation to avoid double-toggling.
                onTap: widget.isActive
                    ? () {}
                    : () => widget.config.onSearchToggle(true),
                width: double.infinity,
                height: double.infinity,
                quality: widget.quality,
                iconColor: iconColor,
                shape: shape,
              ),
              // IgnorePointer+Opacity(0): forces Dart to JIT-compile the
              // expanded widget tree on first frame. Unlike Offstage, this
              // does NOT interact with the focus/IME system so there is no
              // risk of hidden TextFields stealing keyboard input.
              IgnorePointer(
                child: Opacity(
                  opacity: 0,
                  child: _buildExpanded(iconColor, micColor),
                ),
              ),
            ],
          );
        }

        // Wrap with an opaque GestureDetector so taps anywhere inside the
        // glass pill — including the 16 px horizontal padding zones — focus
        // the search field instead of passing through to background content.
        // Without this, AdaptiveGlass.grouped defers hit-testing to its
        // children, leaving the padding area as a transparent pass-through.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusNode.requestFocus,
          child: AdaptiveGlass.grouped(
            shape: shape,
            quality: widget.quality,
            child: _buildExpanded(iconColor, micColor),
          ),
        );
      },
    );
  }

  void _handleClear() {
    _controller.clear();
    widget.config.onChanged?.call('');
  }

  Widget _buildExpanded(Color iconColor, Color micColor) {
    final config = widget.config;
    final textColor = config.textColor ?? Colors.white;

    // Trailing slot priority:
    //   1. trailingBuilder — caller has full control.
    //   2. Animated × clear when _hasText (iOS 26 pattern — clears without dismissing).
    //   3. Default mic icon.
    // Note: the dismiss (close-search) × is a SEPARATE sibling pill in the
    // outer bar Row — it is NOT rendered here. This matches the real iOS 26
    // Apple News layout where the × is its own glass button outside the search pill.
    Widget trailing;
    if (config.trailingBuilder != null) {
      trailing = config.trailingBuilder!(context);
    } else {
      trailing = AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: _hasText
            ? GestureDetector(
                key: const ValueKey('clear'),
                behavior: HitTestBehavior.opaque,
                onTap: _handleClear,
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: iconColor,
                  size: 18,
                ),
              )
            : GestureDetector(
                key: const ValueKey('mic'),
                behavior: HitTestBehavior.opaque,
                onTap: config.onMicTap,
                child: config.onMicTap != null
                    ? Icon(CupertinoIcons.mic_fill, color: micColor, size: 18)
                    : const SizedBox.shrink(),
              ),
      );
    }

    // The expanded pill content.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: false,
              onChanged: config.onChanged,
              onSubmitted: config.onSubmitted,
              onTapOutside: config.onTapOutside,
              textInputAction: config.textInputAction,
              keyboardType: config.keyboardType,
              autocorrect: config.autocorrect,
              enableSuggestions: config.enableSuggestions,
              style: config.hintStyle ??
                  TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
              cursorColor: textColor,
              decoration: InputDecoration(
                hintText: config.hintText,
                hintStyle: (config.hintStyle ??
                        const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w400))
                    .copyWith(color: iconColor),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
