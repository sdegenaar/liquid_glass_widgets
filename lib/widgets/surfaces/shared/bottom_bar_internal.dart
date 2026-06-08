// ignore_for_file: deprecated_member_use
// Shared internal widgets for GlassBottomBar and GlassSearchableBottomBar.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import '../../../src/renderer/liquid_glass_renderer.dart';
import '../../../types/glass_quality.dart';
import '../../../utils/draggable_indicator_physics.dart';
import 'tab_drag_gesture_mixin.dart';
import '../../../utils/glass_spring.dart';
import '../../interactive/glass_button.dart';
import '../../shared/adaptive_glass.dart';
import '../../shared/animated_glass_indicator.dart';
import '../../shared/inherited_liquid_glass.dart';
import '../glass_bottom_bar.dart'
    show
        GlassBottomBarExtraButton,
        GlassBottomBarTab,
        MaskingQuality,
        JellyClipper;

// =============================================================================
// kBottomBarGlassDefaults — shared glass preset
// =============================================================================

/// Default [LiquidGlassSettings] for both [GlassBottomBar] and
/// [GlassSearchableBottomBar].
///
/// Centralised here so that both bars are guaranteed to produce visually
/// identical glass when placed on the same screen — there is no risk of
/// the two copies drifting apart during maintenance.
///
/// Values are tuned to the iOS 26 Apple News / Safari tab bar aesthetic:
/// - `thickness: 30` — deep refraction without over-distorting icons.
/// - `blur: 3` — subtle frosted back-blur.
/// - `refractiveIndex: 1.59` — polycarbonate-grade refraction.
/// - `lightAngle: 0.75π` (135°) — Apple standard upper-left key light.
const kBottomBarGlassDefaults = LiquidGlassSettings(
  thickness: 30,
  blur: 3,
  chromaticAberration: 0.3,
  lightIntensity: 0.6,
  refractiveIndex: 1.59,
  saturation: 0.7,
  ambientStrength: 1,
  lightAngle: 0.75 * math.pi,
  glassColor: Color(0x3DFFFFFF),
);

// =============================================================================
// buildIconShadows — pure utility function (visibleForTesting for unit tests)
// =============================================================================

/// Builds multi-directional icon shadows that simulate a stroke/outline effect.
///
/// Returns `null` (no shadow) when:
/// - [thickness] is null (feature not requested), or
/// - [selected] is true AND [activeIcon] is non-null (distinct active icon
///   is used so outline shadow is not needed in that state).
///
/// Otherwise, generates 8 evenly-spaced [Shadow] offsets around the icon at
/// the given [thickness] radius using 45° increments.
///
/// Extracted from [BottomBarTabItem] to enable isolated unit testing.
@visibleForTesting
List<Shadow>? buildIconShadows({
  required Color iconColor,
  required double? thickness,
  required bool selected,
  required Widget? activeIcon,
}) {
  if (thickness == null || (selected && activeIcon != null)) return null;
  final shadows = <Shadow>[];
  const step = math.pi / 4;
  for (double a = 0; a < math.pi * 2; a += step) {
    shadows.add(Shadow(
      color: iconColor,
      offset: Offset.fromDirection(a, thickness),
    ));
  }
  return shadows;
}

// =============================================================================
// BottomBarTabItem — shared tab item widget
// =============================================================================

/// Renders a single tab item for [GlassBottomBar] and [GlassSearchableBottomBar].
///
/// Previously duplicated as `_BottomBarTab` and `_TabItem`. Single source of truth.
class BottomBarTabItem extends StatelessWidget {
  const BottomBarTabItem({
    required this.tab,
    required this.selected,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.iconSize,
    required this.textStyle,
    required this.labelFontSize,
    required this.iconLabelSpacing,
    required this.glowDuration,
    required this.glowBlurRadius,
    required this.glowSpreadRadius,
    required this.glowOpacity,
    required this.onTap,
    super.key,
  });

  final GlassBottomBarTab tab;
  final bool selected;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final double iconSize;
  final TextStyle? textStyle;

  /// Font size for tab labels when [textStyle] is null.
  ///
  /// Mirrors [iconSize] as an explicit sizing knob. Defaults to 11.
  /// Reduce to 10 for bars with 4+ tabs or long label text.
  final double labelFontSize;
  final double iconLabelSpacing;
  final Duration glowDuration;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final double glowOpacity;
  // Nullable: when null the GestureDetector does not handle taps.
  // Pass null in contexts where the outer TabIndicator owns selection via
  // onTapDown, and accessibility is handled by the indicator's own Semantics.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? selectedIconColor : unselectedIconColor;
    final iconWidget = selected ? (tab.activeIcon ?? tab.icon) : tab.icon;

    return GestureDetector(
      // onTap may be null when selection is owned by the outer TabIndicator
      // (visual path). When non-null it provides accessibility support for
      // VoiceOver / TalkBack which route through onTap, not onTapDown.
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: selected,
        label: tab.label ?? 'Tab',
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: iconLabelSpacing,
              children: [
                ExcludeSemantics(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
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
                      IconTheme(
                        data: IconThemeData(
                          color: iconColor,
                          size: iconSize,
                          // Use the extracted top-level function for testability
                          shadows: buildIconShadows(
                            iconColor: iconColor,
                            thickness: tab.thickness,
                            selected: selected,
                            activeIcon: tab.activeIcon,
                          ),
                        ),
                        child: DefaultTextStyle(
                          style: DefaultTextStyle.of(context)
                              .style
                              .copyWith(color: iconColor),
                          child: iconWidget,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tab.label != null)
                  Text(
                    tab.label!,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle ??
                        TextStyle(
                          color: iconColor,
                          fontSize: labelFontSize,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BottomBarExtraBtn — shared extra button widget
// =============================================================================

/// Renders the extra action button using [GlassButton].
///
/// Previously duplicated as `_ExtraButton` and `_ExtraBtn`. Single source of truth.
class BottomBarExtraBtn extends StatelessWidget {
  const BottomBarExtraBtn({
    required this.config,
    required this.quality,
    required this.iconColor,
    this.borderRadius,
    super.key,
  });

  final GlassBottomBarExtraButton config;
  final GlassQuality quality;
  final Color iconColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: config.icon,
      onTap: config.onTap,
      label: config.label,
      width: config.size,
      height: config.size,
      quality: quality,
      iconColor: iconColor,
      useOwnLayer: true, // Standalone pill — needs own shadow & compositing
      shape: borderRadius == null
          ? const LiquidOval()
          : LiquidRoundedRectangle(borderRadius: borderRadius!),
    );
  }
}

// =============================================================================
// TabIndicator — draggable pill indicator with spring physics
// =============================================================================

/// Internal widget that manages the draggable indicator with physics.
///
/// Extracted from [GlassBottomBar] to keep the public widget focused on layout
/// and configuration, while this widget owns all gesture, animation, and
/// rendering logic for the tab indicator pill.
///
/// Responsibilities:
/// - Horizontal drag gesture handling ([GestureDetector] + [Listener])
/// - Spring-based alignment animation ([VelocitySpringBuilder])
/// - Jelly deformation during drag ([SpringBuilder] + thickness)
/// - Dual rendering modes: [MaskingQuality.off] and [MaskingQuality.high]
class TabIndicator extends StatefulWidget {
  const TabIndicator({
    required this.childUnselected,
    required this.selectedTabBuilder,
    required this.tabIndex,
    required this.tabCount,
    required this.onTabChanged,
    required this.visible,
    required this.indicatorColor,
    required this.quality,
    required this.barHeight,
    required this.barBorderRadius,
    required this.tabPadding,
    required this.magnification,
    required this.innerBlur,
    required this.maskingQuality,
    this.indicatorSettings,
    this.backgroundKey,
    this.indicatorExpansion = 14,
    this.interactionGlowColor,
    this.interactionGlowRadius = 1.5,
    this.interactionGlowBlurRadius = 0,
    this.interactionGlowSpreadRadius = 0,
    this.interactionGlowOpacity = 1,
    this.interactionScale = 1.0,
    super.key,
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

  /// How far the jelly indicator's leading and trailing edges expand
  /// past the tab boundary as the indicator translates. Higher values
  /// give a more dramatic "puff" stretch; lower values produce a
  /// tighter, more iOS-native feel. Defaults to `14` to match the
  /// pre-existing visual.
  final double indicatorExpansion;

  final Color? interactionGlowColor;
  final double interactionGlowRadius;
  final double interactionGlowBlurRadius;
  final double interactionGlowSpreadRadius;
  final double interactionGlowOpacity;

  /// The scale factor applied by [LiquidStretch] on press.
  ///
  /// Pass `1.0` to disable scaling. Resolved by the parent widget from
  /// [GlassInteractionBehavior] before being forwarded here.
  final double interactionScale;

  @override
  State<TabIndicator> createState() => TabIndicatorState();
}

/// State for [TabIndicator]. Public for testing via `@visibleForTesting`.
@visibleForTesting
class TabIndicatorState extends State<TabIndicator>
    with TabDragGestureMixin<TabIndicator> {
  // ── Mixin interface ────────────────────────────────────────────────────────
  @override
  int get tabCount => widget.tabCount;
  @override
  int get tabIndex => widget.tabIndex;
  @override
  void notifyTabChanged(int index) => widget.onTabChanged(index);

  // Cache fallback indicator color to avoid allocations
  static const _fallbackIndicatorColor =
      Color(0x1AFFFFFF); // white.withValues(alpha: 0.1)

  // Cached shape to avoid recreation on every animation frame
  late LiquidRoundedSuperellipse _barShape =
      LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);

  @override
  void didUpdateWidget(covariant TabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateTabAlignIfNeeded(oldWidget.tabIndex, oldWidget.tabCount);

    // Update cached shape if border radius changes
    if (oldWidget.barBorderRadius != widget.barBorderRadius) {
      _barShape =
          LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final indicatorColor = widget.indicatorColor ??
        theme.textTheme.textStyle.color?.withValues(alpha: .1) ??
        _fallbackIndicatorColor;
    final targetAlignment = computeTabAlignment(widget.tabIndex);

    // AnimatedGlassIndicator multiplies by 2 for the glass superellipse shape,
    // but uses the value directly for the background DecoratedBox.
    final backgroundRadius = widget.barBorderRadius * 2; // 64
    final glassRadius =
        widget.barBorderRadius; // 32 → becomes 64 after internal *2

    return LiquidStretch(
        interactionScale: widget.interactionScale,
        stretch: 0.0,
        resistance: 0.08,
        anchorStretch: false, // Tab bars use jelly-follow, not anchored
        child: Listener(
          // Raw pointer events fire BEFORE gesture recognizers and never compete
          // in the gesture arena, so tabIsDown is always set on the very first event.
          onPointerDown: (_) {
            if (mounted) setState(() => tabIsDown = true);
          },
          // On finger/button lift, clear tabIsDown if not mid-drag.
          // Listener fires regardless of which gesture recognizer won the arena.
          onPointerUp: (_) {
            if (!tabIsDragging && mounted) {
              setState(() => tabIsDown = false);
            }
          },
          onPointerCancel: (_) {
            if (!tabIsDragging && mounted) {
              setState(() => tabIsDown = false);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragDown: onBarDragDown,
            onHorizontalDragStart: onBarDragStart,
            onHorizontalDragUpdate: onBarDragUpdate,
            onHorizontalDragEnd: onBarDragEnd,
            // On cancel (e.g. parent scroll steals the gesture or pointer goes
            // off-screen), tabIsDown is cleared by the Listener when pointer lifts.
            onHorizontalDragCancel: onBarDragCancel,
            onTapDown: onBarTapDown, // DX1: makes jelly visible on desktop taps
            child: VelocitySpringBuilder(
              value: tabXAlign,
              springWhenActive: GlassSpring.interactive(),
              springWhenReleased: GlassSpring.snappy(
                duration: const Duration(milliseconds: 350),
              ),
              active: tabIsDragging,
              builder: (context, value, velocity, child) {
                final alignment = Alignment(value, 0);

                return SpringBuilder(
                  spring: GlassSpring.snappy(
                    duration: const Duration(milliseconds: 300),
                  ),
                  // Keep thickness active while:
                  //  - tabIsDown (tap pressed, 420 ms window for spring travel), OR
                  //  - the spring still has meaningful separation from target.
                  // Threshold 0.05 (was 0.10) catches the full deceleration tail.
                  value: widget.visible &&
                          (tabIsDown ||
                              (alignment.x - targetAlignment).abs() > 0.05)
                      ? 1.0
                      : 0.0,
                  builder: (context, thickness, child) {
                    // Lazy evaluation optimization: skip expensive calculations when hidden
                    if (thickness < 0.01 &&
                        !widget.visible &&
                        widget.maskingQuality == MaskingQuality.high) {
                      // Fast path: indicator is hidden, render simple layout
                      return Container(
                        height: widget.barHeight,
                        decoration: ShapeDecoration(
                          shape: _barShape,
                        ),
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

                    // Calculate jelly transform for the clipper (only when needed)
                    final jellyTransform =
                        DraggableIndicatorPhysics.buildJellyTransform(
                      velocity: Offset(velocity, 0),
                      maxDistortion: 0.8,
                      velocityScale: 10,
                    );

                    // Switch rendering mode based on masking quality
                    switch (widget.maskingQuality) {
                      case MaskingQuality.off:
                        return _buildSimpleMode(
                          alignment: alignment,
                          targetAlignment: Alignment(targetAlignment, 0),
                          thickness: thickness,
                          velocity: velocity,
                          backgroundRadius: backgroundRadius,
                          glassRadius: glassRadius,
                          indicatorColor: indicatorColor,
                        );

                      case MaskingQuality.high:
                        return _buildHighQualityMode(
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
                ); // SpringBuilder
              }, // VelocitySpringBuilder builder
            ), // VelocitySpringBuilder
          ), // GestureDetector
        )); // Listener
  }

  /// Wraps the bar pill with a light-mode drop shadow using inverse clipping.
  ///
  /// The shadow is painted ON TOP of the glass content but inverse-clipped
  /// so it only appears outside the pill boundary. This prevents the glass
  /// BackdropFilter from sampling its own shadow (which would create a dirty
  /// dark rim). Skipped in dark mode where shadows are absorbed.
  Widget _wrapWithBarShadow(BuildContext context, Widget bar) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    if (isDark) return bar;

    // Resolve shadow from settings (inherited or global).
    final effectiveSettings = InheritedLiquidGlass.ofOrDefault(context);
    final shadows = effectiveSettings.effectiveShadow;
    if (shadows.isEmpty) return bar;

    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        bar,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipPath(
              clipBehavior: Clip.antiAlias,
              clipper: _InverseBarClipper(_barShape),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.barBorderRadius),
                  boxShadow: shadows,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Wraps [child] in a [GlassGlow] sensor if the resolved glow color is
  /// non-transparent. When [GlassInteractionBehavior.none] or [scaleOnly] is
  /// active, the parent passes [Colors.transparent] — we skip the wrapper
  /// entirely to avoid three extra widget/render-object allocations per frame.
  Widget _wrapWithGlow({required Widget child}) {
    final effectiveColor =
        widget.interactionGlowColor ?? const Color(0x1FFFFFFF);
    if (effectiveColor.a == 0) return child;
    return GlassGlow(
      clipper: ShapeBorderClipper(shape: _barShape),
      glowColor: effectiveColor,
      glowRadius: widget.interactionGlowRadius,
      glowBlurRadius: widget.interactionGlowBlurRadius,
      glowSpreadRadius: widget.interactionGlowSpreadRadius,
      glowOpacity: widget.interactionGlowOpacity,
      child: child,
    );
  }

  /// Builds simple rendering mode without masking (MaskingQuality.off).
  ///
  /// Only renders tabs once without dual-layer masking. Maximum performance.
  Widget _buildSimpleMode({
    required Alignment alignment,
    required Alignment targetAlignment,
    required double thickness,
    required double velocity,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    return _wrapWithBarShadow(
      context,
      SizedBox(
        height: widget.barHeight,
        child: _wrapWithGlow(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glass background (Cached to prevent blur re-rasterization on pill drag)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AdaptiveGlass.grouped(
                    quality: widget.quality,
                    shape: _barShape,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // Unselected icons — always visible, all tabs in unselected style.
              // The glass indicator refracts this layer as the pill moves over it.
              Positioned.fill(
                child: Container(
                  padding: widget.tabPadding,
                  child: widget.childUnselected,
                ),
              ),

              // Glass indicator — on top so it refracts the icon layer beneath.
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
                  expansion: widget.indicatorExpansion,
                  settings: widget.indicatorSettings,
                  backgroundKey: widget.backgroundKey,
                ),

              // Persistent selected-icon overlay — always rendered at the TARGET
              // (settled) tab position regardless of spring thickness. This ensures
              // the selected icon stays vibrant (selected style) at rest, not washed
              // out by the unselected-style icons in the layer below.
              if (widget.visible)
                Positioned.fill(
                  child: Align(
                    alignment: targetAlignment,
                    child: FractionallySizedBox(
                      widthFactor: 1 / widget.tabCount,
                      child: Container(
                        padding: widget.tabPadding,
                        height: widget.barHeight,
                        child: widget.selectedTabBuilder(
                            context, 1.0, targetAlignment),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds high quality rendering mode with jelly masking (MaskingQuality.high).
  ///
  /// Dual-layer rendering with ClipPath for "magic lens" effect.
  Widget _buildHighQualityMode({
    required Alignment alignment,
    required double thickness,
    required double velocity,
    required Matrix4 jellyTransform,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    return _wrapWithBarShadow(
      context,
      SizedBox(
        height: widget.barHeight,
        child: _wrapWithGlow(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Glass Background (Blur / Frosted Glass Layer — Cached)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AdaptiveGlass.grouped(
                    quality: widget.quality,
                    shape: _barShape,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // 1.5. Solid Indicator Background (drawn below icons so selected icons are vibrant)
              AnimatedGlassIndicator(
                velocity: velocity,
                itemCount: widget.tabCount,
                alignment: alignment,
                thickness: thickness,
                quality: widget.quality,
                indicatorColor: indicatorColor,
                isBackgroundIndicator: false,
                paintBackground: true,
                paintGlass: false,
                borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
                padding: const EdgeInsets.all(4),
                expansion: widget.indicatorExpansion,
                settings: widget.indicatorSettings,
                backgroundKey: widget.backgroundKey,
              ),

              // 2. Icon Content Layer (Unselected + Selected combined for refraction)
              // Both layers merged into a single RepaintBoundary BEFORE the glass
              // indicator so the glass lens correctly refracts both icon states
              // without white bleed-through.
              Positioned.fill(
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      // Unselected (inverse clipped — visible OUTSIDE pill)
                      ClipPath(
                        clipper: JellyClipper(
                          itemCount: widget.tabCount,
                          alignment: alignment,
                          thickness: thickness,
                          expansion: widget.indicatorExpansion,
                          transform: jellyTransform,
                          borderRadius:
                              thickness < 1 ? backgroundRadius : glassRadius,
                          inverse: true,
                        ),
                        child: Container(
                          padding: widget.tabPadding,
                          height: widget.barHeight,
                          child: widget.childUnselected,
                        ),
                      ),
                      // Selected (forward clipped — visible INSIDE pill)
                      ClipPath(
                        clipper: JellyClipper(
                          itemCount: widget.tabCount,
                          alignment: alignment,
                          thickness: thickness,
                          expansion: widget.indicatorExpansion,
                          transform: jellyTransform,
                          borderRadius:
                              thickness < 1 ? backgroundRadius : glassRadius,
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

              // 3. Moving Glass Indicator Layer — on top so it refracts
              // the merged icon RepaintBoundary beneath it.
              AnimatedGlassIndicator(
                velocity: velocity,
                itemCount: widget.tabCount,
                alignment: alignment,
                thickness: thickness,
                quality: widget.quality,
                indicatorColor: indicatorColor,
                isBackgroundIndicator: false,
                paintBackground: false,
                paintGlass: true,
                borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
                padding: const EdgeInsets.all(4),
                expansion: widget.indicatorExpansion,
                settings: widget.indicatorSettings,
                backgroundKey: widget.backgroundKey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips out the interior of a bar shape, leaving only the exterior.
/// Used to prevent bar drop shadows from bleeding under translucent glass.
class _InverseBarClipper extends CustomClipper<Path> {
  const _InverseBarClipper(this.shape);

  final LiquidRoundedSuperellipse shape;

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    final shapePath = shape.getOuterPath(rect);
    final outerRect = rect.inflate(50.0);
    final outerPath = Path()..addRect(outerRect);
    return Path.combine(PathOperation.difference, outerPath, shapePath);
  }

  @override
  bool shouldReclip(_InverseBarClipper oldClipper) => oldClipper.shape != shape;
}
