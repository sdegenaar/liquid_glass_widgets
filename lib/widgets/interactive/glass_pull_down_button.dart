import 'package:flutter/cupertino.dart';

import '../../src/engine/liquid_glass_settings.dart';
import '../../src/engine/liquid_shape.dart';
import '../../theme/glass_theme.dart';
import '../../theme/glass_theme_helpers.dart';
import '../../types/glass_quality.dart';
import '../../utils/glass_morph_controller.dart';
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
    Widget? icon,
    this.label,
    this.semanticLabel,
    this.menuSemanticLabel,
    super.key,
    this.buttonWidth,
    this.buttonHeight = 44,
    this.buttonShape,
    this.menuWidth = 200,
    this.menuBorderRadius = 32.0,
    this.menuPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.menuAlignment,
    this.morphSpeed = MorphSpeed.normal,
    this.controller,
    this.onClose,
    this.settings,
    this.quality,
    this.onSelected,
    this.enableContinuousSwipe = true,
    this.continuousSwipeSlop = 10.0,
  }) : icon = icon ?? const Icon(CupertinoIcons.ellipsis_circle);

  /// The shape of the trigger button.
  ///
  /// If null, defaults to [LiquidOval] for square/circular triggers or
  /// [LiquidRoundedSuperellipse] stadium capsule for pill/wide triggers.
  final LiquidShape? buttonShape;

  /// The icon widget to display on the button.
  final Widget icon;

  /// Optional label to display next to the icon.
  final String? label;

  /// VoiceOver / TalkBack label for icon-only variants.
  ///
  /// Ignored when [label] is non-null (the visible text already serves as the
  /// accessibility label). When the button shows only an icon and [label] is
  /// null, the default announcement is an empty string — use [semanticLabel]
  /// to give it a meaningful name:
  ///
  /// ```dart
  /// GlassPullDownButton(
  ///   icon: Icon(CupertinoIcons.ellipsis_circle),
  ///   semanticLabel: 'More options',
  ///   items: [...],
  /// )
  /// ```
  final String? semanticLabel;

  /// What screen readers call the open menu panel.
  ///
  /// Forwarded to [GlassMenu.menuSemanticLabel]. Defaults to `"Menu"`.
  final String? menuSemanticLabel;

  /// The list of items to display in the menu.
  ///
  /// Accepts [GlassMenuItem] and [GlassMenuDivider] widgets, matching the
  /// [GlassMenu.items] contract directly. [GlassMenuDivider] items are passed
  /// through as-is; [GlassMenuItem] instances (including nested
  /// [GlassMenuItem.submenu] items) are wrapped by [onSelected].
  final List<Widget> items;

  /// Explicit width of the trigger button.
  ///
  /// When `null` (default):
  /// - Icon-only buttons (`label == null || label!.isEmpty`) default to `44.0`.
  /// - Labeled buttons size intrinsically to fit their icon + label with
  ///   horizontal capsule padding (constrained to at least [buttonHeight]).
  final double? buttonWidth;

  /// Height of the trigger button.
  final double buttonHeight;

  /// Width of the expanded menu.
  final double menuWidth;

  /// Border radius of the expanded menu platter.
  ///
  /// Forwarded to [GlassMenu.menuBorderRadius]. Defaults to `32.0`.
  final double menuBorderRadius;

  /// Minimum safe margin between the expanded menu and screen edges when
  /// [GlassMenu.autoAdjustToScreen] clamps placement.
  ///
  /// Forwarded to [GlassMenu.menuPadding]. Defaults to
  /// `EdgeInsets.symmetric(horizontal: 12)` so edge-clamped menus never touch
  /// `0px` screen edges.
  final EdgeInsets menuPadding;

  /// Controls where the menu expands relative to the trigger button.
  ///
  /// Defaults to [GlassMenuAlignment.none], which auto-detects the best
  /// alignment based on the trigger's position on screen.
  final GlassMenuAlignment? menuAlignment;

  /// Speed profile for the open/close liquid morph animation.
  ///
  /// Forwarded to [GlassMenu.morphSpeed]. Defaults to [MorphSpeed.normal].
  final MorphSpeed morphSpeed;

  /// Optional imperative controller forwarded to [GlassMenu.controller].
  final GlassMenuController? controller;

  /// Optional callback invoked when the menu begins closing, forwarded to
  /// [GlassMenu.onClose].
  final VoidCallback? onClose;

  /// Glass material settings for the trigger button and menu platter.
  final LiquidGlassSettings? settings;

  /// Quality of the glass effect.
  final GlassQuality? quality;

  /// Callback when a menu item (or nested submenu item) is selected.
  ///
  /// This is called in addition to the individual [GlassMenuItem.onTap] callback.
  final ValueChanged<String>? onSelected;

  /// Whether to enable iOS-style continuous swipe-to-select.
  ///
  /// When true, pressing down on the button opens the menu immediately and
  /// allows the user to slide to an item and release to activate it in a
  /// single continuous gesture without lifting their finger.
  ///
  /// Defaults to `true`.
  final bool enableContinuousSwipe;

  /// The movement slop in logical pixels required to arm continuous swipe.
  ///
  /// If the pointer is released within this distance of the initial touch-down,
  /// the gesture is treated as a tap and the menu remains open without
  /// selecting an item.
  ///
  /// Defaults to 10.0.
  final double continuousSwipeSlop;

  static List<Widget> _wrapMenuItems(
    List<Widget> sourceItems,
    ValueChanged<String> onSelectedCallback,
  ) {
    return sourceItems.map((item) {
      if (item is GlassMenuItem) {
        final wrappedSubmenu = item.submenu != null
            ? _wrapMenuItems(item.submenu!, onSelectedCallback)
            : null;
        return GlassMenuItem(
          key: item.key,
          title: item.title,
          semanticLabel: item.semanticLabel,
          icon: item.icon,
          isDestructive: item.isDestructive,
          subtitle: item.subtitle,
          enabled: item.enabled,
          height: item.height,
          isPressed: item.isPressed,
          isSelected: item.isSelected,
          semanticsSelected: item.semanticsSelected,
          titleStyle: item.titleStyle,
          subtitleStyle: item.subtitleStyle,
          iconColor: item.iconColor,
          iconSize: item.iconSize,
          maxLines: item.maxLines,
          enablePressScale: item.enablePressScale,
          semanticsChecked: item.semanticsChecked,
          closeDelay: item.closeDelay,
          submenu: wrappedSubmenu,
          trailing: item.trailing,
          onTap: () {
            item.onTap.call();
            onSelectedCallback(item.title);
          },
        );
      }
      return item;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
    );

    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final effectiveTextColor = CupertinoDynamicColor.resolve(
      CupertinoTheme.of(context).textTheme.textStyle.color ??
          (isDark ? CupertinoColors.white : CupertinoColors.black),
      context,
    );

    return GlassMenu(
      menuWidth: menuWidth,
      menuBorderRadius: menuBorderRadius,
      menuPadding: menuPadding,
      menuAlignment: menuAlignment,
      morphSpeed: morphSpeed,
      controller: controller,
      onClose: onClose,
      menuSemanticLabel: menuSemanticLabel,
      autoAdjustToScreen: true,
      settings: settings,
      quality: effectiveQuality,
      enableContinuousSwipe: enableContinuousSwipe,
      continuousSwipeSlop: continuousSwipeSlop,
      triggerBuilder: (context, toggleMenu) {
        if (label != null && label!.isNotEmpty) {
          final LiquidShape defaultShape;
          if (buttonWidth != null) {
            defaultShape = buttonWidth! == buttonHeight
                ? const LiquidOval()
                : LiquidRoundedSuperellipse(
                    borderRadius: (buttonWidth! < buttonHeight
                            ? buttonWidth!
                            : buttonHeight) /
                        2,
                  );
          } else {
            defaultShape = LiquidRoundedSuperellipse(
              borderRadius: buttonHeight / 2,
            );
          }

          final Widget rowContent = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(size: 20, color: effectiveTextColor),
                child: icon,
              ),
              const SizedBox(width: 8),
              Text(
                label!,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: effectiveTextColor,
                ),
              ),
            ],
          );

          return GlassButton.custom(
            onTap: toggleMenu,
            width: buttonWidth,
            height: buttonHeight,
            shape: buttonShape ?? defaultShape,
            settings: settings,
            quality: effectiveQuality,
            useOwnLayer: effectiveQuality == GlassQuality.premium,
            child: buttonWidth == null
                ? ConstrainedBox(
                    constraints: BoxConstraints(minWidth: buttonHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: rowContent,
                    ),
                  )
                : rowContent,
          );
        }

        final double effectiveIconWidth = buttonWidth ?? 44.0;
        final LiquidShape defaultIconShape = effectiveIconWidth == buttonHeight
            ? const LiquidOval()
            : LiquidRoundedSuperellipse(
                borderRadius: (effectiveIconWidth < buttonHeight
                        ? effectiveIconWidth
                        : buttonHeight) /
                    2,
              );

        return GlassButton(
          onTap: toggleMenu,
          icon: icon,
          label: semanticLabel ?? label ?? '',
          width: effectiveIconWidth,
          height: buttonHeight,
          shape: buttonShape ?? defaultIconShape,
          settings: settings,
          quality: effectiveQuality,
          useOwnLayer: effectiveQuality == GlassQuality.premium,
        );
      },
      items: onSelected != null ? _wrapMenuItems(items, onSelected!) : items,
    );
  }
}
