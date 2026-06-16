// Using deprecated Colors.withOpacity for backwards compatibility.
// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/physics.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../src/types/glass_interaction_behavior.dart';
import '../../types/glass_quality.dart';
import '../../theme/glass_theme_data.dart';
import '../../theme/glass_theme_helpers.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/glass_content_aware_scope.dart';
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
    this.enableBlend = true,
    this.blendAmount = 10,
    this.settings,
    this.showIndicator = true,
    this.indicatorColor,
    this.indicatorSettings,
    this.indicatorPinchStrength = 1.0,
    this.selectedIconColor,
    this.unselectedIconColor,
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
    this.platformViewBackdrop = false,
    this.maskingQuality = MaskingQuality.high,
    this.backgroundKey,
    this.springDescription,
    this.tabPillAnchor = GlassTabPillAnchor.start,
    // ── Interaction ──────────────────────────────────────────────────────────
    this.interactionBehavior = GlassInteractionBehavior.full,
    this.pressScale = 1.04,
    this.tabWidth,
    this.indicatorExpansion = 14,
    this.onBarTap,
    // ── Whiten-at-bottom (light-mode legibility) ─────────────────────────────
    this.whitenAtBottom = true,
    this.whitenBottomThreshold = 45.0,
    this.whitenAtBottomTarget = 1.0,
    this.scrollController,
    // ── Content-aware brightness ─────────────────────────────────────────────
    this.adaptiveBrightness = false,
    this.onBrightnessChanged,
    this.brightnessOverride,
  })  : assert(tabs.length > 0,
            'GlassSearchableBottomBar requires at least one tab'),
        assert(
          selectedIndex >= 0 && selectedIndex < tabs.length,
          'selectedIndex must be between 0 and tabs.length - 1',
        ),
        assert(
          tabWidth == null || tabWidth > 0,
          'tabWidth must be positive, or null to use expand (full-width) mode.',
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

  /// Whether to enable organic liquid blending between the tab pill,
  /// search pill, and extra button.
  ///
  /// When `true` (default), adjacent glass surfaces merge organically —
  /// a premium "beyond native" effect. When `false`, each element renders
  /// as a fully independent glass surface, matching Apple's native iOS 26
  /// tab bar behavior.
  ///
  /// When disabled, [blendAmount] is ignored.
  final bool enableBlend;

  /// Liquid-glass blend amount for the shared [AdaptiveLiquidGlassLayer].
  ///
  /// Higher values increase the organic blending between adjacent pills.
  /// Only effective when [enableBlend] is `true`.
  /// Defaults to 10.
  final double blendAmount;

  // ── Glass ────────────────────────────────────────────────────────────────────
  /// Custom glass settings. Falls back to identical defaults as [GlassBottomBar].
  final LiquidGlassSettings? settings;

  // ── Whiten-at-bottom (light-mode legibility) ───────────────────────────────
  /// When true (default), the bar lifts its whitening toward
  /// [whitenAtBottomTarget] as the scrolled content nears the bottom of the
  /// page, so a light page stays readable through the bar. Light-mode only;
  /// set false to opt out.
  ///
  /// Inert unless a [scrollController] is provided (the bar needs a scroll
  /// position to watch), so the defaults change nothing for existing callers.
  final bool whitenAtBottom;

  /// Distance (logical px) from the scroll bottom within which the bar is
  /// considered "at the bottom" and whitens. Defaults to 45.
  final double whitenBottomThreshold;

  /// Whiten value the bar lifts to at the bottom. Defaults to 1.0
  /// (fully white).
  final double whitenAtBottomTarget;

  /// Scroll controller for the page beneath the bar. Null (the default)
  /// disables the whiten-at-bottom effect — there is no scroll position to
  /// watch.
  final ScrollController? scrollController;

  // ── Content-aware brightness ────────────────────────────────────────────────
  /// Whether the bar adapts its light/dark appearance to the content
  /// scrolling underneath it, like the iOS 26 system bars.
  ///
  /// Requires an enclosing [GlassContentAwareScope] with the scrolling
  /// content wrapped in a [GlassContentAwareContent]; without one the bar
  /// keeps its ambient appearance. When the scope's contrast vote flips the
  /// verdict, the bar cross-fades between the [GlassTheme] light and dark
  /// variants — themed glass settings, glow palette and the default
  /// icon/label colors all swap automatically.
  ///
  /// Defaults to false.
  final bool adaptiveBrightness;

  /// Called when the content-aware verdict flips (not for the initial
  /// value).
  ///
  /// Use this to restyle elements the bar cannot see — page scrims, status
  /// bar icons, custom-painted tab icons.
  final ValueChanged<Brightness>? onBrightnessChanged;

  /// External brightness source that bypasses the content sampler entirely.
  ///
  /// When non-null, the bar follows this listenable instead of registering
  /// with the [GlassContentAwareScope] — the escape hatch for bars floating
  /// over content that cannot be captured (iOS PlatformViews such as maps;
  /// see [platformViewBackdrop]). Drive it from your own signal, e.g. the
  /// active map style. Implies the adaptive behavior regardless of
  /// [adaptiveBrightness].
  final ValueListenable<Brightness>? brightnessOverride;

  /// Rendering quality. Inherits from parent or defaults to [GlassQuality.premium].
  final GlassQuality? quality;

  // ── Indicator ────────────────────────────────────────────────────────────────
  /// Whether to show the draggable indicator. Defaults to `true`.
  final bool showIndicator;

  /// Base color of the glass indicator. Falls back to theme or a translucent white.
  final Color? indicatorColor;

  /// Custom glass settings for the indicator element.
  final LiquidGlassSettings? indicatorSettings;

  /// Maximum concave lens pinch strength for the draggable indicator pill.
  ///
  /// - `1.0` (default) — full Apple-calibrated pinch
  /// - `0.0` — pinch fully disabled
  final double indicatorPinchStrength;

  // ── Tab style ────────────────────────────────────────────────────────────────
  /// Icon color when a tab is selected. Defaults to dynamic label color.
  final Color? selectedIconColor;

  /// Icon color when a tab is unselected. Defaults to dynamic label color.
  final Color? unselectedIconColor;

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

  // ── Advanced ─────────────────────────────────────────────────────────────────
  /// Magnification factor for the selected indicator lens effect. Defaults to 1.0.
  final double magnification;

  /// Blur amount inside the selected indicator. Defaults to 0.0.
  final double innerBlur;

  /// Set true when the bar sits over an iOS PlatformView (e.g. a map). The bar
  /// background renders via live `BackdropFilter` (the premium shader can't
  /// capture a PlatformView), while the premium indicator refracts the bar's
  /// own icons — so premium animations survive over the PlatformView with no
  /// quality swap. Defaults to false.
  ///
  /// Known limitation: the premium indicator refracts the icon layer via
  /// `toImageSync`, which asserts the captured boundary is clean. While the
  /// indicator animates, that layer repaints every frame, so a mid-animation
  /// capture can fail and the indicator briefly flashes dark. Negligible at
  /// [magnification] ~1.0 (the default) but grows with magnification. Keep
  /// magnification near 1.0 over a PlatformView. (The PlatformView itself
  /// can't be captured, so it can't be refracted directly.)
  final bool platformViewBackdrop;

  /// Rendering quality for the liquid masking effect. Defaults to [MaskingQuality.high].
  final MaskingQuality maskingQuality;

  /// Background key for Skia/web refraction. Optional.
  final GlobalKey? backgroundKey;

  // Note: interactionBehavior and pressScale fields are declared earlier in the Interaction section.

  // ── Tab sizing ───────────────────────────────────────────────────────────────

  /// Width of each tab slot in the tab pill.
  ///
  /// Controls the total width of the tab pill:
  /// `pill width = tabWidth × tab count`, clamped to the maximum
  /// available space.
  ///
  /// **Default: `88.0`** — matches the iOS 26 compact tab slot that
  /// comfortably fits an icon + short label. This gives a 2-tab bar a
  /// 176 px pill and a 3-tab bar a 264 px pill, leaving the rest of the
  /// available width for the search pill to animate into.
  ///
  /// Set to `null` to expand the tab pill across all available space
  /// (the legacy behaviour). Useful when you always have 4–5 tabs and
  /// want them to fill the bar.
  ///
  /// ```dart
  /// // Compact (default) — 2 tabs = 176 px pill
  /// tabWidth: 88.0,
  ///
  /// // Wider slots for longer labels ("Following", "Discover")
  /// tabWidth: 110.0,
  ///
  /// // Legacy expand — fills all space left of the search button
  /// tabWidth: null,
  /// ```
  final double? tabWidth;

  /// How far the jelly indicator's leading and trailing edges expand
  /// past the tab boundary as the indicator translates between tabs.
  /// Higher values give a more dramatic "puff" stretch; lower values
  /// produce a tighter, more iOS-native feel. Defaults to `14` —
  /// matches the pre-existing visual.
  final double indicatorExpansion;

  /// Called when the user taps anywhere on the bar.
  ///
  /// Fires via a translucent [GestureDetector] that wraps the entire bar,
  /// so internal tap handlers (tab selection, search toggle, indicator drag)
  /// all continue to work normally.
  ///
  /// **Primary use-case — tap-to-restore after scroll-to-hide:**
  /// ```dart
  /// GlassSearchableBottomBar(
  ///   onBarTap: () => setState(() => _barVisible = true),
  ///   ...
  /// )
  /// ```
  final VoidCallback? onBarTap;

  @override
  State<GlassSearchableBottomBar> createState() =>
      _GlassSearchableBottomBarState();
}

// =============================================================================
// State
// =============================================================================

class _GlassSearchableBottomBarState extends State<GlassSearchableBottomBar>
    with TickerProviderStateMixin {
  /// Identical to [GlassBottomBar]'s defaults \u2014 centralised in
  /// [kBottomBarGlassDefaults] (bottom_bar_internal.dart) so both bars are
  /// guaranteed to produce the same glass when placed on the same screen.
  static const _defaultGlassSettings = kBottomBarGlassDefaults;

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

  /// Shared listener for all three spring controllers. Multiple controllers
  /// may tick in the same frame but Flutter coalesces setState into one rebuild.
  /// Using a named method (instead of three anonymous lambdas) also lets
  /// removeListener work correctly during dispose.
  void _onSpringTick() => setState(() {});

  // ── Spring-simulation animation controllers ─────────────────────────────
  // Each drives one layout axis of the pill morph. Wide bounds allow the
  // spring to overshoot the target and snap back (the jelly effect).

  /// Animated current width of the tab-indicator pill.
  late AnimationController _tabWCtrl;

  /// Animated current left-edge of the search pill.
  late AnimationController _searchLeftCtrl;

  /// Animated current width of the search pill.
  late AnimationController _searchWCtrl;

  // ── Whiten-at-bottom ───────────────────────────────────────────────────────
  /// Animates the whiten lift: 0 = recipe whiten, 1 = lifted to
  /// [GlassSearchableBottomBar.whitenAtBottomTarget]. Smoothed so the bar
  /// doesn't snap when the page reaches/leaves the bottom.
  late AnimationController _whitenBoostCtrl;

  /// The destination the whiten boost is currently animating toward.
  double _whitenTarget = 0.0;

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
    // All three controllers share a single listener so that simultaneous
    // spring ticks produce only one setState per frame, not three.
    _tabWCtrl = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(_onSpringTick);
    _searchLeftCtrl = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(_onSpringTick);
    _searchWCtrl = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(_onSpringTick);
    // Whiten-at-bottom boost: 0..1, rebuilds the bar as it animates.
    _whitenBoostCtrl = AnimationController(vsync: this)
      ..addListener(_onSpringTick);
    widget.scrollController?.addListener(_onScrollMaybeWhiten);
    // Evaluate once after the first frame so a page that starts at the
    // bottom (e.g. short content) pins immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScrollMaybeWhiten();
    });
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
    // Re-subscribe the whiten watcher if the scroll source changed, and
    // re-evaluate immediately so the boost re-pins to the new page's position.
    if (widget.scrollController != old.scrollController) {
      old.scrollController?.removeListener(_onScrollMaybeWhiten);
      widget.scrollController?.addListener(_onScrollMaybeWhiten);
      _onScrollMaybeWhiten();
    }
    // Re-evaluate when the feature itself is toggled while the page sits at
    // the bottom — no scroll event fires in that case, so without this the
    // boost stays stale (off after re-enable, or lingering after disable)
    // until the next scroll.
    if (widget.whitenAtBottom != old.whitenAtBottom) {
      _onScrollMaybeWhiten();
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
    widget.scrollController?.removeListener(_onScrollMaybeWhiten);
    _whitenBoostCtrl.dispose();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onFocusLost() {
    // Delegates to controller → triggers setState via listener.
    _controller.onFocusChanged(false);
  }

  /// Re-evaluate bottom proximity whenever the watched scroll position moves.
  void _onScrollMaybeWhiten() {
    final c = widget.scrollController;
    final atBottom = widget.whitenAtBottom &&
        c != null &&
        c.hasClients &&
        c.position.maxScrollExtent > 0 &&
        (c.position.maxScrollExtent - c.position.pixels) <=
            widget.whitenBottomThreshold;
    final target = atBottom ? 1.0 : 0.0;
    if (_whitenTarget != target) {
      _whitenTarget = target;
      _whitenBoostCtrl.animateTo(target,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  /// Applies the (possibly boosted) whiten to [s]. Every quality tier consumes
  /// `whitenStrength` directly — the veil is rendered in the shared render
  /// paths (premium: render object + shader; standard: lightweight glass;
  /// minimal: the frosted fallback in adaptive_glass.dart), so the one knob
  /// whitens the whole bar.
  ///
  /// The whiten-at-bottom lift is light-mode only: it keeps a light page
  /// readable through the bar, but in dark mode it would just bloom a white
  /// slab at the bottom — so [isLight] gates the boost off there. The
  /// recipe's base whitenStrength still applies in both modes; only the
  /// at-bottom lift is gated.
  LiquidGlassSettings _applyWhiten(LiquidGlassSettings s, bool isLight) {
    final base = s.whitenStrength;
    final t = (widget.whitenAtBottom && isLight) ? _whitenBoostCtrl.value : 0.0;
    final eff = (base + (widget.whitenAtBottomTarget - base) * t)
        .clamp(0.0, 1.0)
        .toDouble();
    return s.copyWith(whitenStrength: eff);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.adaptiveBrightness && widget.brightnessOverride == null) {
      return _buildBar(context, null);
    }
    return GlassContentAwareBrightness(
      brightnessOverride: widget.brightnessOverride,
      onBrightnessChanged: widget.onBrightnessChanged,
      builder: (context, brightness, darkAmount) =>
          _buildBar(context, darkAmount),
    );
  }

  /// Builds the bar. [darkAmount] is the animated light→dark cross-fade
  /// position when the adaptive brightness machinery is active, or null in
  /// the classic (ambient-brightness) path.
  Widget _buildBar(BuildContext context, double? darkAmount) {
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

    final dynamicLabelColor = resolveBarLabelColor(context, darkAmount);
    final resolvedSelectedIconColor =
        widget.selectedIconColor ?? dynamicLabelColor;
    final resolvedUnselectedIconColor =
        widget.unselectedIconColor ?? dynamicLabelColor;

    // Glow appearance fields come from the theme palette.
    final effectiveGlowBlurRadius = resolvedGlowColors.glowBlurRadius;
    final effectiveGlowSpreadRadius = resolvedGlowColors.glowSpreadRadius;
    final effectiveGlowOpacity = resolvedGlowColors.glowOpacity;

    // CupertinoTheme.brightnessOf falls back to the platform brightness, so
    // this resolves correctly in both Material and pure-Cupertino apps.
    final bool isLight =
        CupertinoTheme.brightnessOf(context) == Brightness.light;
    final effectiveSettings =
        _applyWhiten(widget.settings ?? _defaultGlassSettings, isLight);
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
          settings: effectiveSettings,
          quality: effectiveQuality,
          platformViewBackdrop: widget.platformViewBackdrop,
          blendAmount: widget.enableBlend ? widget.blendAmount : 0,
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
                  tabCount: widget.tabs.length,
                  perTabWidth: widget.tabWidth,
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
                      // ── 1. Search pill (spring-driven left + width) ─────────────
                      // Painted first (bottom of stack) so the tab pill's glass
                      // indicator can render on top when it overlaps. Both pills
                      // share the parent AdaptiveLiquidGlassLayer so glass
                      // settings, colour, and liquid-stretch effects are
                      // perfectly matched — they render as one unified glass
                      // surface. Each pill's internal refraction is
                      // self-contained (its own AdaptiveGlass.grouped), so
                      // paint order between them doesn't affect icon rendering.
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
                          platformViewBackdrop: widget.platformViewBackdrop,
                          enableBackgroundAnimation:
                              widget.interactionBehavior.hasScale,
                          backgroundPressScale: widget.pressScale,
                          interactionGlowColor:
                              widget.interactionBehavior.hasGlow
                                  ? effectiveInteractionGlowColor
                                  : const Color(0x00000000),
                          interactionGlowRadius: widget.interactionGlowRadius,
                          interactionGlowBlurRadius: effectiveGlowBlurRadius,
                          interactionGlowSpreadRadius:
                              effectiveGlowSpreadRadius,
                          interactionGlowOpacity: effectiveGlowOpacity,
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
                                      resolvedUnselectedIconColor,
                                  enableBlend: widget.enableBlend,
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

                      // ── 3. Tab pill (spring-driven width, optional centre anchor) ─
                      // Painted after the search pill so the glass indicator
                      // renders on top when it overlaps (e.g. rightmost tab).
                      // Internal refraction layers (unselected icons → indicator
                      // → selected icons) are self-contained within the
                      // SearchableTabIndicator — unaffected by Stack order.
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
                          indicatorExpansion: widget.indicatorExpansion,
                          indicatorSettings: widget.indicatorSettings,
                          indicatorPinchStrength: widget.indicatorPinchStrength,
                          backgroundKey: widget.backgroundKey,
                          platformViewBackdrop: widget.platformViewBackdrop,
                          isSearchActive: searching,
                          interactionGlowColor:
                              widget.interactionBehavior.hasGlow
                                  ? effectiveInteractionGlowColor
                                  : const Color(0x00000000),
                          interactionGlowRadius: widget.interactionGlowRadius,
                          interactionGlowBlurRadius: effectiveGlowBlurRadius,
                          interactionGlowSpreadRadius:
                              effectiveGlowSpreadRadius,
                          interactionGlowOpacity: effectiveGlowOpacity,
                          enableBackgroundAnimation:
                              widget.interactionBehavior.hasScale,
                          backgroundPressScale: widget.pressScale,
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
                          childUnselected: _buildTabRow(
                            selected: false,
                            resolvedSelectedIconColor:
                                resolvedSelectedIconColor,
                            resolvedUnselectedIconColor:
                                resolvedUnselectedIconColor,
                          ),
                          selectedTabBuilder: (ctx, intensity, alignment) =>
                              _buildTabRow(
                            selected: true,
                            intensity: intensity,
                            alignment: alignment,
                            resolvedSelectedIconColor:
                                resolvedSelectedIconColor,
                            resolvedUnselectedIconColor:
                                resolvedUnselectedIconColor,
                          ),
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
                            onTap: () {
                              // onCancelTap fires first so callers can react
                              // before focus is released (e.g. clear results).
                              widget.searchConfig.onCancelTap?.call();
                              // Dismiss keyboard only. The search bar stays
                              // visible (unfocused) — this is the correct
                              // "search ready" state. The caller collapses
                              // the search via onSearchToggle when they choose
                              // (e.g. tapping the home pill or switching tabs).
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            pillSize: animH,
                            barBorderRadius: widget.barBorderRadius,
                            quality: effectiveQuality,
                            indicatorColor: widget.indicatorColor,
                            settings: widget.settings,
                            cancelButtonColor:
                                widget.searchConfig.cancelButtonColor,
                            cancelIcon: widget.searchConfig.cancelIcon,
                            cancelIconSize: widget.searchConfig.cancelIconSize,
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

    // Wrap with a translucent GestureDetector so onBarTap fires on any tap
    // of the bar (including on internal pills) without swallowing those taps.
    if (widget.onBarTap == null) return barContent;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onBarTap,
      child: barContent,
    );
  } // build()

  Widget _buildTabRow({
    required bool selected,
    required Color resolvedSelectedIconColor,
    required Color resolvedUnselectedIconColor,
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
                        selectedIconColor: resolvedSelectedIconColor,
                        unselectedIconColor: resolvedUnselectedIconColor,
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
              selectedIconColor: resolvedSelectedIconColor,
              unselectedIconColor: resolvedUnselectedIconColor,
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
