// ignore_for_file: deprecated_member_use
// Internal layout engine for [GlassTabBar] bottom placement.
//
// Extracted from the old _GlassBottomBarState so that [GlassTabBar] is the
// single owner of all rendering logic. The deprecated [GlassBottomBar] shim
// simply calls [GlassTabBar.bottom()] which dispatches here.
//
// Do NOT import this file directly — use [GlassTabBar.bottom()] instead.

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
    show GlassBottomBarExtraButton, GlassBottomBarTab, MaskingQuality;
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
  });

  static const double _kDefaultBorderRadius = 32.0;

  final List<GlassBottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final GlassBottomBarExtraButton? extraButton;
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

  @override
  State<TabBarBottomLayout> createState() => _TabBarBottomLayoutState();
}

class _TabBarBottomLayoutState extends State<TabBarBottomLayout> {
  // Delegate to the shared const — single source of truth in tab_bar_bottom_internal.dart.
  // Both bars reference kBottomBarGlassDefaults so their glass is guaranteed identical.
  static const _defaultGlassSettings = kBottomBarGlassDefaults;

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
            final extraBtnW = widget.extraButton != null
                ? widget.extraButton!.size + widget.spacing
                : 0.0;
            final maxTabW = constraints.maxWidth - extraBtnW;
            final tabPillW = resolveTabPillWidth(
              tabWidth: widget.tabWidth,
              tabCount: widget.tabs.length,
              maxAvailable: maxTabW,
            );

            return SizedBox(
              height: widget.barHeight,
              child: Builder(
                builder: (context) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Optional extra button — painted first (bottom of z-order).
                      // Pinned to the trailing edge. Painted before the tab pill
                      // so the jelly indicator's glass effect correctly overlaps and
                      // refracts the extra button during horizontal stretch physics.
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
                                  resolvedUnselectedIconColor,
                              enableBlend: widget.enableBlend,
                              borderRadius: widget.barBorderRadius ==
                                      TabBarBottomLayout._kDefaultBorderRadius
                                  ? null
                                  : widget.barBorderRadius,
                            ),
                          ),
                        ),

                      // 2. Tab pill — painted last (top of z-order).
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
                          indicatorPinchStrength: widget.indicatorPinchStrength,
                          onTabChanged: widget.onTabSelected,
                          barHeight: widget.barHeight,
                          barBorderRadius: widget.barBorderRadius,
                          indicatorBorderRadius: widget.indicatorBorderRadius,
                          tabPadding: widget.tabPadding,
                          backgroundKey: widget.backgroundKey,
                          maskingQuality: widget.maskingQuality,
                          indicatorExpansion: widget.indicatorExpansion,
                          platformViewBackdrop: widget.platformViewBackdrop,
                          interactionGlowColor:
                              widget.interactionBehavior.hasGlow
                                  ? effectiveInteractionGlowColor
                                  : const Color(0x00000000),
                          interactionGlowRadius: widget.interactionGlowRadius,
                          interactionGlowBlurRadius: effectiveGlowBlurRadius,
                          interactionGlowSpreadRadius:
                              effectiveGlowSpreadRadius,
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
                                    selectedIconColor:
                                        resolvedSelectedIconColor,
                                    unselectedIconColor:
                                        resolvedUnselectedIconColor,
                                    selectedLabelColor:
                                        widget.selectedLabelColor,
                                    unselectedLabelColor:
                                        widget.unselectedLabelColor,
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
                                ),
                            ],
                          ),
                          selectedTabBuilder: (context, intensity, alignment) =>
                              _buildSelectedTabs(
                                  intensity,
                                  alignment,
                                  resolvedSelectedIconColor,
                                  resolvedUnselectedIconColor),
                          magnification: widget.magnification,
                          innerBlur: widget.innerBlur,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedTabs(double intensity, Alignment alignment,
      Color resolvedSelectedIconColor, Color resolvedUnselectedIconColor) {
    final scale = ui.lerpDouble(1.0, widget.magnification, intensity) ?? 1.0;

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
                      selectedIconColor: resolvedSelectedIconColor,
                      unselectedIconColor: resolvedUnselectedIconColor,
                      selectedLabelColor: widget.selectedLabelColor,
                      unselectedLabelColor: widget.unselectedLabelColor,
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
    );
  }
}
