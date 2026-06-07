import 'package:flutter/cupertino.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../types/glass_button_style.dart';
import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import 'glass_button.dart';
import '../../theme/glass_theme_helpers.dart';

/// A container that groups multiple buttons visually.
///
/// [GlassButtonGroup] resembles an iOS segmented control but for
/// continuous actions (e.g., Back/Forward, Text Formatting).
/// It wraps children in a single glass pill and adds dividers.
class GlassButtonGroup extends StatelessWidget {
  /// Creates a group of glass buttons.
  const GlassButtonGroup({
    required this.children,
    super.key,
    this.direction = Axis.horizontal,
    this.settings,
    this.quality,
    this.borderRadius = 16.0,
    this.borderColor,
    this.useOwnLayer = false,
    this.showDividers = true,
  });

  /// The buttons to display in the group.
  ///
  /// Ideally, these should be [GlassButton]s with [GlassButtonStyle.transparent].
  final List<Widget> children;

  /// Direction to arrange buttons (horizontal or vertical).
  final Axis direction;

  /// Custom glass settings.
  final LiquidGlassSettings? settings;

  /// Quality of glass effect.
  final GlassQuality? quality;

  /// Border radius of the group container.
  final double borderRadius;

  /// Color of the dividers between buttons.
  ///
  /// Defaults to a semi-transparent black or white depending on brightness.
  final Color? borderColor;

  /// Whether to create its own glass layer.
  final bool useOwnLayer;

  /// Whether to show dividers between buttons.
  ///
  /// Set to false to create a unified pill of buttons without separating lines.
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer if not explicitly set.
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
    );

    final effectiveBorderColor = borderColor ??
        (CupertinoTheme.brightnessOf(context) == Brightness.light
            ? CupertinoColors.black.withValues(alpha: 0.12)
            : CupertinoColors.white.withValues(alpha: 0.12));

    return GlassContainer(
      useOwnLayer: useOwnLayer,
      quality: effectiveQuality,
      settings: settings,
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Flex(
          direction: direction,
          mainAxisSize: MainAxisSize.min,
          children: _buildChildrenWithDividers(effectiveBorderColor),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(Color resolvedBorderColor) {
    if (!showDividers) {
      return children;
    }

    final List<Widget> items = [];
    for (int i = 0; i < children.length; i++) {
      // Add divider before item (excluding first)
      if (i > 0) {
        items.add(
          direction == Axis.horizontal
              ? Container(width: 1, color: resolvedBorderColor)
              : Container(height: 1, color: resolvedBorderColor),
        );
      }
      items.add(children[i]);
    }
    return items;
  }
}
