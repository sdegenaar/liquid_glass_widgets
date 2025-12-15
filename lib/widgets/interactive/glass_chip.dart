import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import 'glass_button.dart';

/// A glass morphism chip following Apple's iOS 26 design patterns.
///
/// [GlassChip] provides a compact, pill-shaped chip with glass effect, perfect
/// for tags, filters, selections, and dismissible elements. It composes
/// [GlassButton] internally for consistent interaction behavior.
///
/// ## Key Features
///
/// - **Pill-Shaped Glass**: Rounded chip with glass morphism effect
/// - **Optional Leading Icon**: Icon before the label
/// - **Optional Delete Button**: Dismissible variant with X button
/// - **Selected State**: Highlight state for filter chips
/// - **Press Effects**: Inherits squash/stretch and glow from GlassButton
/// - **Flexible Sizing**: Automatically sizes to content
///
/// ## Usage
///
/// ### Basic Chip
/// ```dart
/// GlassChip(
///   label: 'Technology',
///   onTap: () => print('Tapped'),
/// )
/// ```
///
/// ### With Leading Icon
/// ```dart
/// GlassChip(
///   label: 'Favorite',
///   icon: CupertinoIcons.heart_fill,
///   onTap: () => toggleFavorite(),
/// )
/// ```
///
/// ### Dismissible Chip
/// ```dart
/// GlassChip(
///   label: 'Selected Tag',
///   onDeleted: () => removeTag(),
/// )
/// ```
///
/// ### Selected State (Filter Chips)
/// ```dart
/// GlassChip(
///   label: 'Active',
///   selected: true,
///   selectedColor: Colors.blue,
///   onTap: () => toggleFilter(),
/// )
/// ```
///
/// ### Within LiquidGlassLayer (Grouped Mode)
/// ```dart
/// LiquidGlassLayer(
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 3,
///   ),
///   child: Wrap(
///     spacing: 8,
///     children: [
///       GlassChip(label: 'Flutter', onTap: () {}),
///       GlassChip(label: 'Dart', onTap: () {}),
///       GlassChip(label: 'iOS', onTap: () {}),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassChip(
///   label: 'Technology',
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 8,
///   ),
/// )
/// ```
class GlassChip extends StatelessWidget {
  /// Creates a glass chip.
  const GlassChip({
    required this.label,
    super.key,
    this.icon,
    this.onTap,
    this.onDeleted,
    this.selected = false,
    this.selectedColor,
    this.deleteIcon = CupertinoIcons.xmark_circle_fill,
    this.deleteIconSize = 16.0,
    this.iconSize = 16.0,
    this.iconColor,
    this.labelStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.spacing = 6.0,
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    // GlassButton properties
    this.interactionScale = 1.03,
    this.stretch = 0.3,
    this.glowRadius = 0.8,
  });

  // ===========================================================================
  // Chip Properties
  // ===========================================================================

  /// The label text displayed in the chip.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Called when the chip is tapped.
  ///
  /// If both [onTap] and [onDeleted] are null, the chip will be
  /// non-interactive.
  final VoidCallback? onTap;

  /// Called when the delete button is tapped.
  ///
  /// When provided, a delete button (X icon) will be shown on the right side.
  /// The chip becomes dismissible.
  final VoidCallback? onDeleted;

  /// Whether the chip is in selected state.
  ///
  /// When true, the chip will be highlighted with [selectedColor].
  /// Useful for filter chips.
  ///
  /// Defaults to false.
  final bool selected;

  /// Color used when the chip is selected.
  ///
  /// If null and [selected] is true, defaults to white with 30% opacity.
  final Color? selectedColor;

  /// Icon used for the delete button.
  ///
  /// Defaults to [CupertinoIcons.xmark_circle_fill].
  final IconData deleteIcon;

  /// Size of the delete icon.
  ///
  /// Defaults to 16.0.
  final double deleteIconSize;

  // ===========================================================================
  // Style Properties
  // ===========================================================================

  /// Size of the leading icon.
  ///
  /// Defaults to 16.0.
  final double iconSize;

  /// Color of the leading icon.
  ///
  /// If null, defaults to white with 90% opacity.
  final Color? iconColor;

  /// Style for the label text.
  ///
  /// If null, defaults to 14px white text with 90% opacity.
  final TextStyle? labelStyle;

  /// Padding inside the chip.
  ///
  /// Defaults to 12px horizontal, 8px vertical.
  final EdgeInsetsGeometry padding;

  /// Spacing between icon and label, and label and delete button.
  ///
  /// Defaults to 6.0.
  final double spacing;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings (only used when [useOwnLayer] is true).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass.
  ///
  /// Defaults to false (grouped mode).
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses backdrop filter rendering.
  /// This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for shader-based glass in static layouts only.
  final GlassQuality quality;

  // ===========================================================================
  // Interaction Properties (from GlassButton)
  // ===========================================================================

  /// Scale factor when pressed.
  ///
  /// Values > 1.0 grow the chip, < 1.0 shrink it.
  /// Defaults to 1.03 (3% growth, subtle for chips).
  final double interactionScale;

  /// Stretch intensity during animation (0-1).
  ///
  /// Defaults to 0.3 (subtle stretch for chips).
  final double stretch;

  /// Glow radius multiplier.
  ///
  /// Defaults to 0.8 (subtle glow for chips).
  final double glowRadius;

  static const _chipShape = LiquidRoundedSuperellipse(borderRadius: 100);

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.white.withValues(alpha: 0.9);
    final effectiveLabelStyle = labelStyle ??
        TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        );

    // Build chip content
    final chipContent = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Leading icon
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: effectiveIconColor,
            ),
            SizedBox(width: spacing),
          ],

          // Label
          Text(
            label,
            style: effectiveLabelStyle,
          ),

          // Delete button
          if (onDeleted != null) ...[
            SizedBox(width: spacing),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                deleteIcon,
                size: deleteIconSize,
                color: effectiveIconColor,
              ),
            ),
          ],
        ],
      ),
    );

    // Determine if chip should be interactive
    final isInteractive = onTap != null || onDeleted != null;

    // Apply selected state color overlay
    final contentWithSelection = selected
        ? Container(
            decoration: BoxDecoration(
              color: selectedColor ?? Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
            ),
            child: chipContent,
          )
        : chipContent;

    // Use GlassButton.custom for consistent interaction behavior
    // Wrap in IntrinsicWidth/Height to auto-size to content
    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: GlassButton.custom(
          onTap: onTap ?? (onDeleted != null ? () {} : () {}),
          shape: _chipShape,
          settings: settings,
          useOwnLayer: useOwnLayer,
          quality: quality,
          interactionScale: interactionScale,
          stretch: stretch,
          glowRadius: glowRadius,
          glowColor: selected
              ? (selectedColor ?? Colors.white).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.2),
          enabled: isInteractive,
          width: double.infinity, // Expand to intrinsic width
          height: double.infinity, // Expand to intrinsic height
          child: contentWithSelection,
        ),
      ),
    );
  }
}
