import 'dart:ui';
import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import '../../src/renderer/internal/interaction_notification.dart';

import '../../types/glass_quality.dart';
import '../shared/adaptive_glass.dart';
import '../../theme/glass_theme_helpers.dart';
import 'package:flutter/services.dart';
import 'shared/glass_sheet_defaults.dart';

/// A glass morphism bottom sheet following Apple's iOS 26 design patterns.
///
/// [GlassSheet] provides a modal bottom sheet with liquid glass effect,
/// drag indicator, and iOS-style dismiss behavior.
///
/// ## Key Features
///
/// - Liquid glass backdrop with blur effect
/// - Draggable dismissal
/// - Rounded top corners
/// - iOS-style drag indicator (pill)
/// - Safe area handling
/// - Customizable height and snap points
/// - Interaction suppression for child widgets (Smart Silence)
///
/// ## Usage
///
/// ### Basic Usage
/// ```dart
/// GlassSheet.show(
///   context: context,
///   builder: (context) => const Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       Text('Bottom Sheet Title'),
///       Text('Content goes here'),
///     ],
///   ),
/// );
/// ```
///
/// ### Smart Interaction (New)
/// To prevent the sheet from scaling when tapping internal buttons:
/// ```dart
/// GlassSheet.show(
///   context: context,
///   suppressInteractionOnChildren: true,
///   builder: (context) => Column(
///     children: [
///       GlassInteractionSilence(
///         child: GlassButton(
///           onTap: () => print('Button tapped without sheet scale!'),
///           child: Text('Silent Button'),
///         ),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// ### Advanced Interactivity & Styling
/// Customise the look and feel with glow effects, scaling, and specific glass settings:
/// ```dart
/// GlassSheet.show(
///   context: context,
///   borderRadius: 40,
///   margin: const EdgeInsets.all(12),
///   interactionScale: 1.05,
///   enableInteractionGlow: true, // Glint follows finger
///   enableSaturationGlow: true,  // Pulsation on touch
///   settings: const LiquidGlassSettings(
///     blur: 20,
///     saturation: 1.8,
///   ),
///   builder: (context) => const Column(
///     children: [
///       Text('High Fidelity Glass'),
///     ],
///   ),
/// );
/// ```
///
/// ### Solid Color Mode
/// Disable glass effect and use a solid background color:
/// ```dart
/// GlassSheet.show(
///   context: context,
///   settings: const LiquidGlassSettings(blur: 0),
///   backgroundColor: Colors.blue.withOpacity(0.9),
///   builder: (context) => const Text('Solid Background'),
/// );
/// ```

class GlassSheet extends StatefulWidget {
  /// Creates a glass sheet widget.
  ///
  /// Typically not instantiated directly - use [GlassSheet.show] instead.
  const GlassSheet({
    super.key,
    required this.child,
    this.settings,
    this.quality,
    this.showDragIndicator = true,
    this.dragIndicatorColor,
    this.padding,
    this.borderRadius,
    this.margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    this.isScrollable = true,
    this.interactionScale = 1.01,
    this.stretch = 0.5,
    this.resistance = 0.08,
    this.stretchAxis = Axis.vertical,
    this.allowPositiveStretch = false,
    this.allowNegativeStretch = true,
    this.enableInteractionGlow = true,
    this.glowColor,
    this.glowRadius = 1.5,
    this.enableSaturationGlow = true,
    this.suppressInteractionOnChildren = false,
  });

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The widget below this widget in the tree.
  final Widget child;

  /// Padding around the content (below the drag indicator).
  final EdgeInsetsGeometry? padding;

  // ===========================================================================
  // Drag Indicator Properties
  // ===========================================================================

  /// Whether to show the drag indicator at the top of the sheet.
  final bool showDragIndicator;

  /// Color of the drag indicator.
  final Color? dragIndicatorColor;

  // ===========================================================================
  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses backdrop filter rendering.
  /// This is recommended for sheets as they may be animated.
  ///
  /// [GlassQuality.premium] (shader-based) is not recommended for animated
  /// sheets but can be used for static sheets.
  final GlassQuality? quality;

  /// Border radius of the sheet corners.
  ///
  /// If null, it will be automatically resolved based on the device's
  /// physical geometry (adaptive radius).
  final double? borderRadius;

  /// External margin around the sheet.
  ///
  /// This allows the sheet to "float" above the screen edges.
  /// Defaults to `EdgeInsets.symmetric(horizontal: 8, vertical: 8)`.
  final EdgeInsetsGeometry margin;

  /// The scale factor to apply when the user is interacting with the sheet.
  ///
  /// A value of 1.0 means no scaling. Defaults to 1.01 (subtle scale).
  final double interactionScale;

  /// Whether to show glow/glare on touch for tactile feedback.
  ///
  /// Defaults to true.
  final bool enableInteractionGlow;

  /// Whether to show the whole-window saturation/lighting pulse on touch.
  ///
  /// Defaults to true.
  final bool enableSaturationGlow;

  /// The factor to multiply the drag offset by to determine the stretch amount.
  ///
  /// Defaults to 0.5.
  final double stretch;

  /// The resistance factor to apply to the drag offset.
  ///
  /// Lower values (0.01-0.1) provide subtle liquid feel. Defaults to 0.08.
  final double resistance;

  /// The axis to constrain the stretch to.
  ///
  /// Defaults to [Axis.vertical].
  final Axis? stretchAxis;

  /// Whether to allow stretch in the positive direction of the axis (Down).
  ///
  /// Defaults to false.
  final bool allowPositiveStretch;

  /// Whether to allow stretch in the negative direction of the axis (Up).
  ///
  /// Defaults to true.
  final bool allowNegativeStretch;

  /// Whether the content should be scrollable.
  ///
  /// Defaults to true.
  final bool isScrollable;

  /// The color of the interaction glow.
  ///
  /// If null, uses white at 15% opacity.
  final Color? glowColor;

  /// The radius of the interaction glow (relative to shortest side).
  ///
  /// Defaults to 1.5.
  final double glowRadius;

  /// Settings for the liquid glass effect.
  final LiquidGlassSettings? settings;

  /// Whether to suppress sheet interactions when a child is being touched.
  ///
  /// When enabled, any child wrapped in [GlassInteractionSilence] will prevent
  /// the sheet from scaling or glowing when tapped.
  ///
  /// Defaults to false.
  final bool suppressInteractionOnChildren;

  // ===========================================================================
  // Static Show Method
  // ===========================================================================

  /// Shows a glass bottom sheet.
  ///
  /// Returns a [Future] that resolves to the value (if any) passed to
  /// [Navigator.pop] when the sheet is dismissed.
  ///
  /// Parameters:
  /// - [context]: Build context for showing the sheet
  /// - [builder]: Builder function that creates the sheet content
  /// - [settings]: Glass effect settings (null uses defaults)
  /// - [quality]: Rendering quality (defaults to standard)
  /// - [showDragIndicator]: Whether to show the drag indicator (default: true)
  /// - [dragIndicatorColor]: Color of the drag indicator
  /// - [padding]: Padding around the content
  /// - [borderRadius]: Corner radius of the sheet (default: 54)
  /// - [margin]: External margin for the "floating" look (default: 8x8)
  /// - [isScrollable]: Whether the content should be scrollable (default: true)
  /// - [interactionScale]: Visual scale feedback on touch (default: 1.01)
  /// - [stretch]: Liquid stretch intensity (default: 0.5)
  /// - [resistance]: Drag resistance factor (default: 0.08)
  /// - [stretchAxis]: Axis for the liquid effect (default: vertical)
  /// - [allowPositiveStretch]: Enable stretch in positive direction (default: false)
  /// - [allowNegativeStretch]: Enable stretch in negative direction (default: true)
  /// - [enableInteractionGlow]: Whether to show tactile glare on touch (default: true)
  /// - [glowColor]: Color of the interaction glow
  /// - [glowRadius]: Radius of the interaction glow
  /// - [enableSaturationGlow]: Whether to pulse saturation/lighting on touch (default: true)
  /// - [suppressInteractionOnChildren]: Enable "Smart Silence" for child interactions
  /// - [isDismissible]: Whether tapping outside dismisses the sheet (default: true)
  /// - [enableDrag]: Whether the sheet can be dragged down (default: true)
  /// - [isScrollControlled]: Whether the sheet can occupy more than 50% screen height (default: true)
  /// - [backgroundColor]: Background color of the modal container (default: transparent)
  /// - [barrierColor]: Color of the modal barrier (defaults to black54)
  /// - [elevation]: Material elevation of the sheet (default: 0)
  /// - [shape]: Custom shape for the modal (defaults to rounded top corners)
  /// - [clipBehavior]: Clipping behavior for the modal (default: null)
  /// - [constraints]: Size constraints for the sheet
  /// - [useRootNavigator]: Whether to show the sheet in the root navigator (default: false)
  /// - [useSafeArea]: Whether to wrap the content in a safe area (default: true)
  ///
  /// Example:
  /// ```dart
  /// final result = await GlassSheet.show<String>(
  ///   context: context,
  ///   builder: (context) => /* content */,
  /// );
  /// ```
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    LiquidGlassSettings? settings,
    GlassQuality? quality,
    bool showDragIndicator = true,
    Color? dragIndicatorColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    bool isScrollable = true,
    double interactionScale = 1.01,
    double stretch = 0.5,
    double resistance = 0.08,
    Axis stretchAxis = Axis.vertical,
    bool allowPositiveStretch = false,
    bool allowNegativeStretch = true,
    bool enableInteractionGlow = true,
    Color? glowColor,
    double glowRadius = 1.5,
    bool suppressInteractionOnChildren = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    Color? backgroundColor,
    Color? barrierColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool useRootNavigator = false,
    bool useSafeArea = true,
    bool enableSaturationGlow = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation ?? 0,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      barrierColor: barrierColor,
      clipBehavior: Clip.none,
      builder: (context) {
        return GlassSheet(
          settings: settings,
          quality: quality,
          showDragIndicator: showDragIndicator,
          dragIndicatorColor: dragIndicatorColor,
          padding: padding,
          borderRadius: borderRadius,
          margin: margin,
          isScrollable: isScrollable,
          interactionScale: interactionScale,
          stretch: stretch,
          resistance: resistance,
          stretchAxis: stretchAxis,
          allowPositiveStretch: allowPositiveStretch,
          allowNegativeStretch: allowNegativeStretch,
          enableInteractionGlow: enableInteractionGlow,
          glowColor: glowColor,
          glowRadius: glowRadius,
          enableSaturationGlow: enableSaturationGlow,
          suppressInteractionOnChildren: suppressInteractionOnChildren,
          child: builder(context),
        );
      },
    );
  }

  @override
  State<GlassSheet> createState() => _GlassSheetState();
}

class _GlassSheetState extends State<GlassSheet> with TickerProviderStateMixin {
  late AnimationController _saturationController;
  late Animation<double> _saturationAnimation;
  bool _isInteractingWithChild = false;

  @override
  void initState() {
    super.initState();
    _saturationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _saturationAnimation = CurvedAnimation(
      parent: _saturationController,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() {
    _saturationController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_isInteractingWithChild) {
      // Reset flag and ignore this sheet interaction
      _isInteractingWithChild = false;
      return;
    }

    if (widget.enableInteractionGlow) {
      HapticFeedback.selectionClick();
    }

    if (widget.enableSaturationGlow) {
      _saturationController.forward();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _saturationController.reverse();
    _isInteractingWithChild = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _saturationController.reverse();
    _isInteractingWithChild = false;
  }

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassQuality.premium,
    );

    final effectiveSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: widget.settings,
      fallback: kDefaultSheetSettings,
    );

    final effectiveRadius =
        widget.borderRadius ?? GlassThemeHelpers.resolveAdaptiveRadius(context);

    return AnimatedBuilder(
      animation: _saturationAnimation,
      builder: (context, child) {
        final t = _saturationAnimation.value;
        final scaledRadius = effectiveRadius * 0.98;
        final currentRadius = lerpDouble(effectiveRadius, scaledRadius, t)!;
        final shape = LiquidRoundedSuperellipse(borderRadius: currentRadius);

        final pulsedSettings = effectiveSettings.copyWith(
          lightIntensity: lerpDouble(effectiveSettings.lightIntensity, 0.8, t)!,
          saturation: lerpDouble(effectiveSettings.saturation, 2.2, t)!,
        );

        // The core inner content of the sheet
        Widget innerContent = Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetHeader(
                  showIndicator: widget.showDragIndicator,
                  color: widget.dragIndicatorColor,
                ),
                if (widget.isScrollable)
                  Flexible(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification &&
                            notification.dragDetails != null) {
                          GlassGlowLayer.maybeOf(context)?.removeTouch();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: widget.padding,
                        child: RepaintBoundary(child: widget.child),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: widget.padding ?? EdgeInsets.zero,
                    child: RepaintBoundary(child: widget.child),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );

        Widget result = AdaptiveGlass(
          shape: shape,
          settings: pulsedSettings,
          quality: effectiveQuality,
          glowIntensity: 0.0,
          child: RepaintBoundary(child: innerContent),
        );

        if (widget.enableInteractionGlow && effectiveSettings.blur > 0.05) {
          result = GlassGlow(
            glowColor: widget.glowColor ?? Colors.white.withValues(alpha: 0.15),
            glowRadius: widget.glowRadius,
            clipper: ShapeBorderClipper(shape: shape),
            child: result,
          );
        }

        Widget sheetContent = Listener(
          onPointerDown: _handlePointerDown,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          behavior: HitTestBehavior.translucent,
          child: LiquidStretch(
            interactionScale: widget.interactionScale,
            stretch: widget.stretch,
            resistance: widget.resistance,
            axis: widget.stretchAxis,
            allowPositive: widget.allowPositiveStretch,
            allowNegative: widget.allowNegativeStretch,
            suppressInteractionOnChildren: widget.suppressInteractionOnChildren,
            anchorStretch: false, // Sheets use jelly-follow, not anchored
            child: result,
          ),
        );

        if (widget.suppressInteractionOnChildren) {
          sheetContent = NotificationListener<InteractionNotification>(
            onNotification: (notification) {
              _isInteractingWithChild = true;
              return false; // Let it bubble
            },
            child: sheetContent,
          );
        }

        return Padding(
          padding: widget.margin,
          child: sheetContent,
        );
      },
    );
  }
}

/// A private component for the sheet header to optimize rebuilds.
class _SheetHeader extends StatelessWidget {
  final bool showIndicator;
  final Color? color;

  const _SheetHeader({
    required this.showIndicator,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (showIndicator) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Center(child: _GlassDragIndicator(color: color)),
          const SizedBox(height: 8),
        ],
      );
    }
    return const SizedBox(height: 16);
  }
}

/// Drag indicator / grab handle widget for glass sheets.
///
/// A small pill-shaped bar that indicates the sheet can be dragged,
/// precisely matching iOS 26's `UISheetPresentationController` grabber:
/// 36×4dp, white at ~35% opacity.
class _GlassDragIndicator extends StatelessWidget {
  const _GlassDragIndicator({
    this.color,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // iOS 26: white at 35% in dark mode, black at 20% in light mode
    final defaultColor =
        isDark ? const Color(0x59FFFFFF) : const Color(0x33000000);

    return Semantics(
      // VoiceOver on iOS announces the grabber as "Drag to resize, double-tap
      // and hold, then drag up or down." We approximate this.
      label: 'Drag handle',
      hint: 'Swipe down to dismiss',
      child: Container(
        width: 36,
        height: 4, // iOS 26 spec: 4dp (not 5dp)
        decoration: BoxDecoration(
          color: color ?? defaultColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// A universal wrapper that silences [GlassSheet] interactions for its child.
///
/// Wrap any interactive widget (buttons, switches, list tiles) in this
/// to prevent the parent [GlassSheet] from scaling or glowing when the
/// child is tapped.
///
/// Note: [GlassSheet.suppressInteractionOnChildren] must be set to `true`
/// for this to have any effect.
class GlassInteractionSilence extends StatelessWidget {
  /// The widget that should silence the parent sheet.
  final Widget child;

  /// Creates a [GlassInteractionSilence].
  const GlassInteractionSilence({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        InteractionNotification(event).dispatch(context);
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
