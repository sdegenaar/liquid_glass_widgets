import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE & GLASS SETTINGS (matches apple_messages_demo.dart & iOS 26 Mail)
// ─────────────────────────────────────────────────────────────────────────────

/// Primary background color (deep black in dark mode).
const kMailBg = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFF2F2F7),
  darkColor: Color(0xFF000000),
);

/// Card background for inset grouped lists (solid/opaque; never glass in scrollable lists).
const kMailCardBg = CupertinoDynamicColor.withBrightness(
  color: CupertinoColors.white,
  darkColor: Color(0xFF1C1C1E),
);

/// Inset divider line color.
const kMailDivider = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFE5E5EA),
  darkColor: Color(0xFF2C2C2E),
);

/// Secondary label color for count badges and metadata.
const kMailSecondaryLabel = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF8E8E93),
  darkColor: Color(0xFF8E8E93),
);

/// Avatar circle placeholder background.
const kMailAvatarBg = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFE5E5EA),
  darkColor: Color(0xFF3A3A50),
);

/// Standard iOS accent blue.
const kMailBlue = Color(0xFF007AFF);

/// Global notifier controlling whether the Apple Mail demo is rendering with
/// the native iOS 27 material terms or legacy/classic 1.7.2 glass settings.
final ValueNotifier<bool> kMailUseIos27 = ValueNotifier<bool>(true);

/// Scope that manages whether the Apple Mail demo is rendering with the native
/// iOS 27 material terms or legacy/classic 1.7.2 glass settings.
class MailGlassScope extends InheritedNotifier<ValueNotifier<bool>> {
  MailGlassScope({
    super.key,
    ValueNotifier<bool>? notifier,
    required super.child,
  }) : super(notifier: notifier ?? kMailUseIos27);

  /// Returns whether iOS 27 native material is active. Defaults to true.
  static bool isIos27(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MailGlassScope>();
    return (scope?.notifier ?? kMailUseIos27).value;
  }

  /// Returns the underlying [ValueNotifier].
  static ValueNotifier<bool> of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<MailGlassScope>()
            ?.notifier ??
        kMailUseIos27;
  }
}

LiquidGlassSettings _resolveMailGlass(BuildContext context) {
  final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
  if (MailGlassScope.isIos27(context)) {
    return isDark
        ? LiquidGlassSettings.ios27Dark
        : LiquidGlassSettings.ios27Light;
  }
  return isDark
      ? LiquidGlassSettings.ios26Dark
      : LiquidGlassSettings.ios26Light;
}

/// Glass shared by action triggers (matching Messages edit pill aesthetic).
LiquidGlassSettings kMailTriggerGlass(BuildContext context) =>
    _resolveMailGlass(context);

/// Glass for floating utility bars and compose morph triggers.
LiquidGlassSettings kMailSearchGlass(BuildContext context) =>
    _resolveMailGlass(context);

/// Glass settings for dropdown popover menus.
LiquidGlassSettings kMailMenuGlass(BuildContext context) =>
    _resolveMailGlass(context);
