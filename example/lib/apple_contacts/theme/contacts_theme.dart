import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Design tokens and palettes for Apple Contacts (iOS 26/27).
class ContactsTheme {
  const ContactsTheme._();

  static const bg = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF000000),
  );

  static const cardBg = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: Color(0xFF1C1C1E),
  );

  static const secondaryCardBg = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFE5E5EA),
    darkColor: Color(0xFF2C2C2E),
  );

  static const divider = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFE5E5EA),
    darkColor: Color(0xFF38383A),
  );

  static const label = CupertinoColors.label;
  static const secondaryLabel = CupertinoColors.secondaryLabel;
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF3B30);
  static const purple = Color(0xFFAF52DE);

  /// Authentic iOS 27 liquid glass navigation settings.
  static const navSettings = LiquidGlassSettings.ios27Dark;

  /// Authentic iOS 27 liquid glass settings for cards and platters.
  static const cardSettings = LiquidGlassSettings.ios27Dark;
}

/// Theme-aware authentic Apple Contacts background.
///
/// In iOS 26/27, Apple Contacts uses the solid ground-plane system grouped
/// background (pure OLED #000000 in dark mode, #F2F2F7 in light mode).
/// Liquid glass is reserved strictly for the floating chrome, app bars,
/// swipe trays, context menus, and controls that sit above this surface.
class AppleContactsBackground extends StatelessWidget {
  const AppleContactsBackground({
    super.key,
    this.isModal = false,
  });

  final bool isModal;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    if (isModal) {
      return Container(
        color:
            isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
      );
    }
    return Container(
      color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
    );
  }
}
