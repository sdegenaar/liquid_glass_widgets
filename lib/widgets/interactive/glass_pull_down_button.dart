import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../types/glass_quality.dart';
import '../overlays/glass_menu.dart';
import '../overlays/glass_menu_item.dart';
import 'glass_button.dart';

/// A toolbar button that opens a liquid glass pull-down menu.
///
/// This widget combines [GlassButton] and [GlassMenu] to create a standard
/// "pull-down" interaction pattern commonly used in toolbars and navigation bars.
class GlassPullDownButton extends StatelessWidget {
  /// Creates a glass pull-down button.
  const GlassPullDownButton({
    required this.items,
    this.icon = CupertinoIcons.ellipsis_circle,
    this.label,
    super.key,
    this.buttonWidth = 44,
    this.buttonHeight = 44,
    this.menuWidth = 200,
    this.quality = GlassQuality.standard,
    this.onSelected,
  });

  /// The icon to display on the button.
  final IconData icon;

  /// Optional label to display next to the icon.
  final String? label;

  /// The list of menu items.
  final List<GlassMenuItem> items;

  /// Width of the trigger button.
  final double buttonWidth;

  /// Height of the trigger button.
  final double buttonHeight;

  /// Width of the expanded menu.
  final double menuWidth;

  /// Quality of the glass effect.
  final GlassQuality quality;

  /// Callback when a menu item is selected.
  ///
  /// This is called in addition to the individual [GlassMenuItem.onTap] callback.
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassMenu(
      menuWidth: menuWidth,
      quality: quality,
      triggerBuilder: (context, toggleMenu) {
        if (label != null && label!.isNotEmpty) {
          return GlassButton.custom(
            onTap: toggleMenu,
            width: buttonWidth,
            height: buttonHeight,
            quality: quality,
            useOwnLayer: quality == GlassQuality.premium,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return GlassButton(
          onTap: toggleMenu,
          icon: icon,
          label: label ?? '',
          width: buttonWidth,
          height: buttonHeight,
          quality: quality,
          useOwnLayer: quality == GlassQuality.premium,
        );
      },
      items: items.map((item) {
        // Wrap item tap to support onSelected callback if provided
        if (onSelected != null) {
          return GlassMenuItem(
            title: item.title,
            icon: item.icon,
            isDestructive: item.isDestructive,
            onTap: () {
              item.onTap.call();
              onSelected!(item.title);
            },
            trailing: item.trailing,
          );
        }
        return item;
      }).toList(),
    );
  }
}
