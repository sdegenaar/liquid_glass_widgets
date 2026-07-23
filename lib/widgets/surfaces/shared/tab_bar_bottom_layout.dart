// ignore_for_file: deprecated_member_use
// Internal layout engine for [GlassTabBar] bottom placement.
//
// Extracted from the old _GlassBottomBarState so that [GlassTabBar] is the
// single owner of all rendering logic. The deprecated [GlassBottomBar] shim
// simply calls [GlassTabBar.bottom()] which dispatches here.
//
// Do NOT import this file directly — use [GlassTabBar.bottom()] instead.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import '../../../src/renderer/liquid_glass_renderer.dart';
import '../../../src/types/glass_interaction_behavior.dart';
import '../../../types/glass_quality.dart';
import '../../shared/adaptive_liquid_glass_layer.dart';
import '../../shared/glass_content_aware_scope.dart';
import '../../../theme/glass_theme_data.dart';
import '../../../theme/glass_theme_helpers.dart';
import '../glass_bottom_bar.dart'
    show
        GlassBottomBarCollapseConfig,
        GlassBottomBarCollapseDirection,
        GlassExtraButtonPlacement,
        GlassTabBarExtraButton,
        MaskingQuality;
import '../glass_tab_bar.dart' show GlassTab;
import 'tab_bar_bottom_internal.dart'
    show
        BottomBarExtraBtn,
        BottomBarTabItem,
        TabIndicator,
        kBottomBarGlassDefaults,
        resolveBarLabelColor;
import 'tab_bar_layout_utils.dart';

/// Internal [StatefulWidget] that owns the bottom-placement rendering engine.
///
/// Created by [GlassTabBar._buildBottom()] when [_GlassTabBarPlacement.bottom]
/// is active. Not part of the public API.
class TabBarBottomLayout extends StatefulWidget {
  const TabBarBottomLayout({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    super.key,
    this.extraButton,
    this.collapseConfig,
    this.spacing = 8,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.barHeight = 64,
    this.barBorderRadius = _kDefaultBorderRadius,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.iconLabelSpacing = 4,
    this.enableBlend = true,
    this.blendAmount = 10,
    this.settings,
    this.showIndicator = true,
    this.indicatorColor,
    this.indicatorSettings,
    this.indicatorPinchStrength = 0.4,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.selectedLabelColor,
    this.unselectedLabelColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.iconSize = 24,
    this.labelFontSize = 11,
    this.textStyle,
    this.glowDuration = const Duration(milliseconds: 300),
    this.glowBlurRadius = 32,
    this.glowSpreadRadius = 8,
    this.glowOpacity = 0.6,
    this.quality,
    this.magnification = 1.15,
    this.innerBlur = 0.0,
    this.maskingQuality = MaskingQuality.high,
    this.backgroundKey,
    this.tabWidth,
    this.indicatorBorderRadius,
    this.indicatorExpansion =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.interactionGlowColor,
    this.interactionGlowRadius = 1.5,
    this.interactionBehavior = GlassInteractionBehavior.full,
    this.pressScale = 1.04,
    this.platformViewBackdrop = false,
    this.adaptiveBrightness = false,
    this.onBrightnessChanged,
    this.brightnessOverride,
    this.scrollController,
    this.springDescription,
  });

  static const double _kDefaultBorderRadius = 32.0;

  final List<GlassTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final GlassTabBarExtraButton? extraButton;
  final GlassBottomBarCollapseConfig? collapseConfig;
  final double spacing;
  final double horizontalPadding;
  final double verticalPadding;
  final double barHeight;
  final double barBorderRadius;
  final EdgeInsetsGeometry tabPadding;
  final double iconLabelSpacing;
  final bool enableBlend;
  final double blendAmount;
  final LiquidGlassSettings? settings;
  final bool showIndicator;
  final Color? indicatorColor;
  final LiquidGlassSettings? indicatorSettings;
  final double indicatorPinchStrength;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final Color? selectedLabelColor;
  final Color? unselectedLabelColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final double iconSize;
  final double labelFontSize;
  final TextStyle? textStyle;
  final Duration glowDuration;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final double glowOpacity;
  final GlassQuality? quality;
  final double magnification;
  final double innerBlur;
  final MaskingQuality maskingQuality;
  final GlobalKey? backgroundKey;
  final double? tabWidth;
  final double? indicatorBorderRadius;
  final EdgeInsetsGeometry indicatorExpansion;
  final Color? interactionGlowColor;
  final double interactionGlowRadius;
  final GlassInteractionBehavior interactionBehavior;
  final double pressScale;
  final bool platformViewBackdrop;
  final bool adaptiveBrightness;
  final ValueChanged<Brightness>? onBrightnessChanged;
  final ValueListenable<Brightness>? brightnessOverride;
  final ScrollController? scrollController;
  final SpringDescription? springDescription;

  @override
  State<TabBarBottomLayout> createState() => _TabBarBottomLayoutState();
}

class _TabBarBottomLayoutState extends State<TabBarBottomLayout>
    with TickerProviderStateMixin {
  // Delegate to the shared const — single source of truth in tab_bar_bottom_internal.dart.
  // Both bars reference kBottomBarGlassDefaults so their glass is guaranteed identical.
  static const _defaultGlassSettings = kBottomBarGlassDefaults;
  static const _kCollapsedTabSize = 0.01;
  static const _kCollapseCurve = Curves.easeOutCubic;
  static const _kExpandCurve = Curves.easeOutBack;
  static const _kExtraButtonCollapseDelay = 0.08;
  static const _kSwipeVelocityThreshold = 250.0;
  static const _kGestureRegionKey = ValueKey<String>(
    'glass_bottom_bar_gesture_region',
  );
  static const _kTabPillKey = ValueKey<String>('glass_bottom_bar_tab_pill');
  static const _kExtraButtonScaleKey = ValueKey<String>(
    'glass_bottom_bar_extra_button_scale',
  );
  static const _kScrollDeltaThreshold = 12.0;

  bool _isCollapsed = false;
  double? _lastScrollPixels;
  late final AnimationController _collapseController;

  bool get _collapseEnabled =>
      widget.collapseConfig != null && widget.extraButton != null;
  bool get _scrollCollapseEnabled =>
      _collapseEnabled && widget.scrollController != null;
  Duration get _collapseDuration =>
      widget.collapseConfig?.animationDuration ??
      const Duration(milliseconds: 220);
  double get _collapsedExtraButtonScale =>
      widget.collapseConfig?.collapsedExtraButtonScale ?? 0.9;

  /// Lays out the tab [Row] in physical (LTR) order regardless of the ambient
  /// direction, so the first child is on the left — matching the indicator and
  /// gesture coordinate space. RTL ordering is carried by the reversed tab data
  /// in [_buildBar], not by the ambient direction of these Rows. Scoping the
  /// pin to the Rows keeps `Directionality.of(context)` intact for the rest of
  /// the subtree (notably [indicatorExpansion] / [tabPadding] resolution).
  static Widget _ltrTabRow({required List<Widget> children}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: children),
    );
  }

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      value: _isCollapsed ? 1.0 : 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    widget.scrollController?.addListener(_handleScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollBaseline());
  }

  @override
  void didUpdateWidget(covariant TabBarBottomLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_collapseEnabled && _isCollapsed) {
      _isCollapsed = false;
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScrollChanged);
      _lastScrollPixels = null;
      widget.scrollController?.addListener(_handleScrollChanged);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncScrollBaseline());
    }
  }

  @override
  void dispose() {
    _collapseController.dispose();
    widget.scrollController?.removeListener(_handleScrollChanged);
    super.dispose();
  }

  void _collapse() {
    if (!_collapseEnabled || _isCollapsed) return;
    setState(() => _isCollapsed = true);
    _collapseController.animateTo(
      1.0,
      duration: _collapseDuration,
      curve: Curves.linear,
    );
  }

  void _expand() {
    if (!_isCollapsed) return;
    setState(() => _isCollapsed = false);
    _collapseController.animateTo(
      0.0,
      duration: _collapseDuration,
      curve: Curves.linear,
    );
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!_collapseEnabled) return;
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity <= -_kSwipeVelocityThreshold) {
      _collapse();
    } else if (velocity >= _kSwipeVelocityThreshold) {
      _expand();
    }
  }

  void _syncScrollBaseline() {
    if (!mounted) return;
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    _lastScrollPixels = controller.position.pixels;
  }

  void _handleScrollChanged() {
    if (!_scrollCollapseEnabled) return;
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;
    final currentPixels = position.pixels;
    final previousPixels = _lastScrollPixels;
    _lastScrollPixels = currentPixels;

    if (previousPixels == null || position.outOfRange) return;

    final delta = currentPixels - previousPixels;
    if (delta >= _kScrollDeltaThreshold) {
      _collapse();
    } else if (delta <= -_kScrollDeltaThreshold) {
      _expand();
    }
  }

  double _collapsedTabLeft({
    required bool extraOnLeft,
    required double expandedLeft,
    required double expandedWidth,
  }) {
    final collapseTowardsRightEdge =
        _collapseTowardsRightEdge(extraOnLeft: extraOnLeft);
    if (!collapseTowardsRightEdge) return expandedLeft;
    return expandedLeft + math.max(0.0, expandedWidth - _kCollapsedTabSize);
  }

  bool _collapseTowardsRightEdge({required bool extraOnLeft}) {
    if (!_collapseEnabled) return false;
    final direction = widget.collapseConfig!.direction;
    return extraOnLeft
        ? direction == GlassBottomBarCollapseDirection.awayFromExtraButton
        : direction == GlassBottomBarCollapseDirection.towardsExtraButton;
  }

  Alignment _collapsedContentAlignment({required bool extraOnLeft}) {
    return _collapseTowardsRightEdge(extraOnLeft: extraOnLeft)
        ? Alignment.centerRight
        : Alignment.centerLeft;
  }

  double _pillCollapseProgress() {
    final raw = _collapseController.value;
    if (_isCollapsed) return _kCollapseCurve.transform(raw);
    final expandedT = _kExpandCurve.transform(1.0 - raw);
    return 1.0 - expandedT;
  }

  double _extraButtonCollapseProgress() {
    final raw = _collapseController.value;
    if (_isCollapsed) {
      final delayed = ((raw - _kExtraButtonCollapseDelay) /
              (1.0 - _kExtraButtonCollapseDelay))
          .clamp(0.0, 1.0)
          .toDouble();
      return _kCollapseCurve.transform(delayed);
    }
    final expandedT = _kCollapseCurve.transform(1.0 - raw);
    return 1.0 - expandedT;
  }

  GlassTabBarExtraButton _resolvedExtraButtonConfig() {
    final config = widget.extraButton!;
    if (!_isCollapsed || !(widget.collapseConfig?.expandOnTap ?? false)) {
      return config;
    }
    return GlassTabBarExtraButton(
      icon: config.icon,
      onTap: _expand,
      label: config.label,
      iconColor: config.iconColor,
      size: config.size,
      placement: config.placement,
      position: config.position,
      collapseOnSearchFocus: config.collapseOnSearchFocus,
    );
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

    // Glow appearance fields come from the theme; they cannot be set per-widget
    // because they are part of the theme palette.
    final effectiveGlowBlurRadius = resolvedGlowColors.glowBlurRadius;
    final effectiveGlowSpreadRadius = resolvedGlowColors.glowSpreadRadius;
    final effectiveGlowOpacity = resolvedGlowColors.glowOpacity;

    final effectiveSettings = widget.settings ?? _defaultGlassSettings;

    // RTL support.
    //
    // The indicator/gesture coordinate system and the [AnimatedGlassIndicator]
    // position both operate in physical, left-anchored alignment space (x == -1
    // is always the left edge), and the gesture math is derived from the render
    // box geometry — all direction-independent. The only direction-sensitive
    // part is the two tab [Row]s, which honour the ambient [Directionality] and
    // visually reverse under RTL. That reversal is what disagrees with the
    // physical coordinate space, so the pill — and the tap/drag hit-testing —
    // land on the mirror-image tab.
    //
    // Normalise by reversing the tab data and mirroring the selected index and
    // the tap callback, then pin *only* the tab Rows to LTR (see [_ltrTabRow])
    // so their physical order matches the coordinate space. Net effect under
    // RTL: correct ordering (the first tab sits on the trailing/right edge)
    // with the pill and hit-testing aligned to it. In LTR everything is a
    // no-op.
    //
    // The pin is deliberately scoped to the Rows: [TabIndicator] resolves
    // [indicatorExpansion] and [tabPadding] against `Directionality.of(context)`,
    // so wrapping the whole subtree would force those to LTR and silently ignore
    // any `EdgeInsetsDirectional` a consumer passes in an RTL app.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final tabs = isRtl ? widget.tabs.reversed.toList() : widget.tabs;
    final selectedIndex = isRtl
        ? widget.tabs.length - 1 - widget.selectedIndex
        : widget.selectedIndex;
    final onTabSelected = isRtl
        ? (int i) => widget.onTabSelected(widget.tabs.length - 1 - i)
        : widget.onTabSelected;

    return AdaptiveLiquidGlassLayer(
      clipExpansion:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      settings: effectiveSettings,
      quality: effectiveQuality,
      platformViewBackdrop: widget.platformViewBackdrop,
      blendAmount: widget.enableBlend ? widget.blendAmount : 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: widget.verticalPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resolvedExtraButton = widget.extraButton != null
                ? _resolvedExtraButtonConfig()
                : null;
            final extraPlacement = resolvedExtraButton?.placement ??
                GlassExtraButtonPlacement.right;
            final extraOnLeft =
                extraPlacement == GlassExtraButtonPlacement.left;
            final extraBtnW = resolvedExtraButton != null
                ? resolvedExtraButton.size + widget.spacing
                : 0.0;
            final maxTabW = constraints.maxWidth - extraBtnW;
            final tabPillW = resolveTabPillWidth(
              tabWidth: widget.tabWidth,
              tabCount: tabs.length,
              maxAvailable: maxTabW,
            );
            final expandedTabLeft = extraOnLeft ? extraBtnW : 0.0;
            final collapsedContentAlignment =
                _collapsedContentAlignment(extraOnLeft: extraOnLeft);

            final content = SizedBox(
              key: _kGestureRegionKey,
              height: widget.barHeight,
              child: AnimatedBuilder(
                animation: _collapseController,
                builder: (context, _) {
                  final collapsedTabLeft = _collapseEnabled
                      ? _collapsedTabLeft(
                          extraOnLeft: extraOnLeft,
                          expandedLeft: expandedTabLeft,
                          expandedWidth: tabPillW,
                        )
                      : expandedTabLeft;
                  final pillProgress = _pillCollapseProgress();
                  final extraProgress = _extraButtonCollapseProgress();
                  final tabLeft = ui.lerpDouble(
                      expandedTabLeft, collapsedTabLeft, pillProgress)!;
                  final tabWidth = ui.lerpDouble(
                      tabPillW, _kCollapsedTabSize, pillProgress)!;
                  final tabHeight = ui.lerpDouble(
                    widget.barHeight,
                    _kCollapsedTabSize,
                    pillProgress,
                  )!;
                  final tabTop = (widget.barHeight - tabHeight) / 2;
                  final extraScale = ui.lerpDouble(
                    1.0,
                    _collapsedExtraButtonScale,
                    extraProgress,
                  )!;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Optional extra button — painted first (bottom of z-order).
                      // Painted before the tab pill so the jelly indicator's
                      // glass effect correctly overlaps and refracts the extra
                      // button during horizontal stretch physics.
                      if (resolvedExtraButton != null)
                        Positioned(
                          left: extraOnLeft ? 0 : null,
                          right: extraOnLeft ? null : 0,
                          top: 0,
                          bottom: 0,
                          child: SizedBox(
                            width: resolvedExtraButton.size,
                            height: widget.barHeight,
                            child: ScaleTransition(
                              key: _kExtraButtonScaleKey,
                              scale: AlwaysStoppedAnimation<double>(extraScale),
                              child: BottomBarExtraBtn(
                                config: resolvedExtraButton,
                                quality: effectiveQuality,
                                iconColor: resolvedExtraButton.iconColor ??
                                    resolvedUnselectedIconColor,
                                enableBlend: widget.enableBlend,
                                borderRadius: widget.barBorderRadius ==
                                        TabBarBottomLayout._kDefaultBorderRadius
                                    ? null
                                    : widget.barBorderRadius,
                                platformViewBackdrop:
                                    widget.platformViewBackdrop,
                              ),
                            ),
                          ),
                        ),

                      // 2. Tab pill — painted last (top of z-order).
                      Positioned(
                        left: tabLeft,
                        top: tabTop,
                        width: tabWidth,
                        height: tabHeight,
                        child: KeyedSubtree(
                          key: _kTabPillKey,
                          child: IgnorePointer(
                            ignoring: _isCollapsed,
                            child: ClipRect(
                              child: FittedBox(
                                fit: BoxFit.fill,
                                alignment: collapsedContentAlignment,
                                child: SizedBox(
                                  width: tabPillW,
                                  height: widget.barHeight,
                                  child: TabIndicator(
                                    quality: effectiveQuality,
                                    springDescription: widget.springDescription,
                                    visible: widget.showIndicator,
                                    tabIndex: selectedIndex,
                                    tabCount: tabs.length,
                                    indicatorColor: widget.indicatorColor,
                                    indicatorSettings: widget.indicatorSettings,
                                    indicatorPinchStrength:
                                        widget.indicatorPinchStrength,
                                    onTabChanged: onTabSelected,
                                    barHeight: widget.barHeight,
                                    barBorderRadius: widget.barBorderRadius,
                                    indicatorBorderRadius:
                                        widget.indicatorBorderRadius,
                                    tabPadding: widget.tabPadding,
                                    backgroundKey: widget.backgroundKey,
                                    maskingQuality: widget.maskingQuality,
                                    indicatorExpansion:
                                        widget.indicatorExpansion,
                                    platformViewBackdrop:
                                        widget.platformViewBackdrop,
                                    interactionGlowColor:
                                        widget.interactionBehavior.hasGlow
                                            ? effectiveInteractionGlowColor
                                            : const Color(0x00000000),
                                    interactionGlowRadius:
                                        widget.interactionGlowRadius,
                                    interactionGlowBlurRadius:
                                        effectiveGlowBlurRadius,
                                    interactionGlowSpreadRadius:
                                        effectiveGlowSpreadRadius,
                                    interactionGlowOpacity:
                                        effectiveGlowOpacity,
                                    interactionScale:
                                        widget.interactionBehavior.hasScale
                                            ? widget.pressScale
                                            : 1.0,
                                    childUnselected: _ltrTabRow(
                                      children: [
                                        for (var i = 0; i < tabs.length; i++)
                                          Expanded(
                                            child: BottomBarTabItem(
                                              tab: tabs[i],
                                              selected: false,
                                              selectedIconColor:
                                                  resolvedSelectedIconColor,
                                              unselectedIconColor:
                                                  resolvedUnselectedIconColor,
                                              selectedLabelColor:
                                                  widget.selectedLabelColor,
                                              unselectedLabelColor:
                                                  widget.unselectedLabelColor,
                                              selectedLabelStyle:
                                                  widget.selectedLabelStyle,
                                              unselectedLabelStyle:
                                                  widget.unselectedLabelStyle,
                                              iconSize: widget.iconSize,
                                              labelFontSize:
                                                  widget.labelFontSize,
                                              textStyle: widget.textStyle,
                                              iconLabelSpacing:
                                                  widget.iconLabelSpacing,
                                              glowDuration: widget.glowDuration,
                                              glowBlurRadius:
                                                  widget.glowBlurRadius,
                                              glowSpreadRadius:
                                                  widget.glowSpreadRadius,
                                              glowOpacity: widget.glowOpacity,
                                              semanticsSelected:
                                                  i == selectedIndex,
                                              onTap: null,
                                            ),
                                          ),
                                      ],
                                    ),
                                    selectedTabBuilder:
                                        (context, intensity, alignment) =>
                                            _buildSelectedTabs(
                                                intensity,
                                                alignment,
                                                tabs,
                                                resolvedSelectedIconColor,
                                                resolvedUnselectedIconColor),
                                    magnification: widget.magnification,
                                    innerBlur: widget.innerBlur,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
            if (!_collapseEnabled) return content;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap:
                  _isCollapsed && (widget.collapseConfig?.expandOnTap ?? false)
                      ? _expand
                      : null,
              onVerticalDragEnd: _handleVerticalDragEnd,
              child: content,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedTabs(
      double intensity,
      Alignment alignment,
      List<GlassTab> tabs,
      Color resolvedSelectedIconColor,
      Color resolvedUnselectedIconColor) {
    final scale = ui.lerpDouble(1.0, widget.magnification, intensity) ?? 1.0;

    final currentTabFloat = ((alignment.x + 1) / 2) * tabs.length;
    final affectedStart =
        (currentTabFloat - 1).floor().clamp(0, tabs.length - 1);
    final affectedEnd = (currentTabFloat + 1).ceil().clamp(0, tabs.length - 1);

    return ExcludeSemantics(
      child: _ltrTabRow(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: (i >= affectedStart && i <= affectedEnd)
                  ? Transform.scale(
                      scale: scale,
                      child: BottomBarTabItem(
                        tab: tabs[i],
                        selected: true,
                        selectedIconColor: resolvedSelectedIconColor,
                        unselectedIconColor: resolvedUnselectedIconColor,
                        selectedLabelColor: widget.selectedLabelColor,
                        unselectedLabelColor: widget.unselectedLabelColor,
                        selectedLabelStyle: widget.selectedLabelStyle,
                        unselectedLabelStyle: widget.unselectedLabelStyle,
                        iconSize: widget.iconSize,
                        labelFontSize: widget.labelFontSize,
                        textStyle: widget.textStyle,
                        iconLabelSpacing: widget.iconLabelSpacing,
                        glowDuration: widget.glowDuration,
                        glowBlurRadius: widget.glowBlurRadius,
                        glowSpreadRadius: widget.glowSpreadRadius,
                        glowOpacity: widget.glowOpacity,
                        onTap: null,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
