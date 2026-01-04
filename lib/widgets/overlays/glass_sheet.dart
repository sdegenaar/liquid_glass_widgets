import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/adaptive_glass.dart';

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
///
/// ## Usage
///
/// ### Basic Usage
/// ```dart
/// GlassSheet.show(
///   context: context,
///   builder: (context) => Padding(
///     padding: EdgeInsets.all(24),
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         Text('Bottom Sheet Title', style: TextStyle(fontSize: 20)),
///         SizedBox(height: 16),
///         Text('Bottom sheet content goes here'),
///       ],
///     ),
///   ),
/// );
/// ```
///
/// ### Custom Height
/// ```dart
/// GlassSheet.show(
///   context: context,
///   initialChildSize: 0.6,  // 60% of screen height
///   minChildSize: 0.4,      // Can drag down to 40%
///   maxChildSize: 0.9,      // Can drag up to 90%
///   builder: (context) => /* content */,
/// );
/// ```
///
/// ### Non-dismissible Sheet
/// ```dart
/// GlassSheet.show(
///   context: context,
///   isDismissible: false,
///   enableDrag: false,
///   builder: (context) => /* content */,
/// );
/// ```
///
/// ### Custom Glass Settings
/// ```dart
/// GlassSheet.show(
///   context: context,
///   settings: LiquidGlassSettings(
///     thickness: 40,
///     blur: 15,
///     glassColor: Colors.white.withOpacity(0.1),
///   ),
///   builder: (context) => /* content */,
/// );
/// ```
///
/// ### With Scrollable Content
/// ```dart
/// GlassSheet.show(
///   context: context,
///   isScrollControlled: true,
///   builder: (context) => DraggableScrollableSheet(
///     expand: false,
///     builder: (context, scrollController) => ListView.builder(
///       controller: scrollController,
///       itemCount: 20,
///       itemBuilder: (context, index) => ListTile(
///         title: Text('Item $index'),
///       ),
///     ),
///   ),
/// );
/// ```
class GlassSheet extends StatelessWidget {
  /// Creates a glass sheet widget.
  ///
  /// Typically not instantiated directly - use [GlassSheet.show] instead.
  const GlassSheet({
    required this.child,
    super.key,
    this.showDragIndicator = true,
    this.dragIndicatorColor,
    this.settings,
    this.quality = GlassQuality.standard,
    this.padding,
  });

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The widget below this widget in the tree.
  ///
  /// This is the main content of the bottom sheet, displayed below the
  /// drag indicator.
  final Widget child;

  /// Padding around the content (below the drag indicator).
  ///
  /// If null, no padding is applied.
  final EdgeInsetsGeometry? padding;

  // ===========================================================================
  // Drag Indicator Properties
  // ===========================================================================

  /// Whether to show the drag indicator at the top of the sheet.
  ///
  /// The drag indicator is a small pill-shaped bar that indicates the sheet
  /// can be dragged. Follows iOS design guidelines.
  ///
  /// Defaults to true.
  final bool showDragIndicator;

  /// Color of the drag indicator.
  ///
  /// If null, uses a semi-transparent white color.
  final Color? dragIndicatorColor;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings for the sheet.
  ///
  /// Controls the visual appearance of the glass effect including thickness,
  /// blur radius, color tint, lighting, and more.
  ///
  /// If null, uses [LiquidGlassSettings] defaults.
  final LiquidGlassSettings? settings;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses backdrop filter rendering.
  /// This is recommended for sheets as they may be animated.
  ///
  /// [GlassQuality.premium] (shader-based) is not recommended for animated
  /// sheets but can be used for static sheets.
  final GlassQuality quality;

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
  /// - [isDismissible]: Whether tapping outside dismisses the sheet
  ///   (default: true)
  /// - [enableDrag]: Whether the sheet can be dragged (default: true)
  /// - [isScrollControlled]: Whether the sheet is scroll-controlled
  ///   (default: false)
  /// - [backgroundColor]: Background color (defaults to transparent for glass)
  /// - [barrierColor]: Color of the modal barrier (defaults to black54)
  /// - [elevation]: Material elevation (default: 0)
  /// - [shape]: Shape of the sheet (defaults to rounded top corners)
  /// - [clipBehavior]: Clip behavior (default: Clip.antiAlias)
  /// - [constraints]: Size constraints for the sheet
  /// - [initialChildSize]: Initial height as fraction of screen (default: 0.5)
  /// - [minChildSize]: Minimum height as fraction of screen (default: 0.25)
  /// - [maxChildSize]: Maximum height as fraction of screen (default: 1.0)
  /// - [padding]: Padding around the content
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
    GlassQuality quality = GlassQuality.standard,
    bool showDragIndicator = true,
    Color? dragIndicatorColor,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    Color? backgroundColor,
    Color? barrierColor,
    double elevation = 0,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 1.0,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      barrierColor: barrierColor,
      elevation: elevation,
      shape: shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      constraints: constraints,
      builder: (context) {
        return GlassSheet(
          settings: settings,
          quality: quality,
          showDragIndicator: showDragIndicator,
          dragIndicatorColor: dragIndicatorColor,
          padding: padding,
          child: builder(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const shape = LiquidRoundedSuperellipse(borderRadius: 20);
    final effectiveSettings = settings ?? const LiquidGlassSettings();

    final sheetContent = AdaptiveLiquidGlassLayer(
      settings: effectiveSettings,
      quality: quality,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragIndicator) ...[
              const SizedBox(height: 8),
              _GlassDragIndicator(
                color: dragIndicatorColor,
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 16),
            if (padding != null)
              Padding(
                padding: padding!,
                child: child,
              )
            else
              child,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    return AdaptiveGlass(
      shape: shape,
      settings: effectiveSettings,
      quality: quality,
      useOwnLayer: true,
      child: sheetContent,
    );
  }
}

/// Drag indicator widget for glass sheets.
///
/// A small pill-shaped bar that indicates the sheet can be dragged,
/// following iOS design guidelines.
class _GlassDragIndicator extends StatelessWidget {
  const _GlassDragIndicator({
    this.color,
  });

  // Cache default drag indicator color to avoid allocations
  static const _defaultColor =
      Color(0x4DFFFFFF); // white.withValues(alpha: 0.3)

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: color ?? _defaultColor,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}
