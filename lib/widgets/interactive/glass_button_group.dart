import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_button_style.dart';
import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import 'glass_button.dart';

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
    this.glassSettings,
    this.quality = GlassQuality.standard,
    this.borderRadius = 16.0,
    this.borderColor = Colors.white12,
    this.useOwnLayer = false,
  });

  /// The buttons to display in the group.
  ///
  /// Ideally, these should be [GlassButton]s with [GlassButtonStyle.transparent].
  final List<Widget> children;

  /// Direction to arrange buttons (horizontal or vertical).
  final Axis direction;

  /// Custom glass settings.
  final LiquidGlassSettings? glassSettings;

  /// Quality of glass effect.
  final GlassQuality quality;

  /// Border radius of the group container.
  final double borderRadius;

  /// Color of the dividers between buttons.
  final Color borderColor;

  /// Whether to create its own glass layer.
  final bool useOwnLayer;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      useOwnLayer: useOwnLayer,
      quality: quality,
      settings: glassSettings,
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Flex(
          direction: direction,
          mainAxisSize: MainAxisSize.min,
          children: _buildChildrenWithDividers(),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers() {
    final List<Widget> items = [];

    for (int i = 0; i < children.length; i++) {
      // Add divider before item (excluding first)
      if (i > 0) {
        items.add(
          direction == Axis.horizontal
              ? Container(width: 1, color: borderColor)
              : Container(height: 1, color: borderColor),
        );
      }

      // Ensure GlassButtons are transparent if they are indeed GlassButtons
      // (We can't forcefully mutate widgets, but we assume user follows pattern
      // or we accept what they pass. Documentation guides them to use transparent.)
      // Note: We could wrap in a Theme or provider if GlassButton supported it,
      // but style property is explicit.
      items.add(children[i]);
    }

    return items;
  }
}
