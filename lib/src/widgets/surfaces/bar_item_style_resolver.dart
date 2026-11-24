import 'package:flutter/cupertino.dart';

import '../../../theme/glass_theme_helpers.dart';
import '../../../widgets/surfaces/glass_app_bar.dart'
    show DefaultButtonSettings;
import '../../../widgets/surfaces/glass_bar_item.dart';
import '../../renderer/liquid_glass_renderer.dart';

/// Horizontal padding on each side of a [GlassBarTextItem] inside its glass
/// capsule in a horizontal bar.
const double kBarItemTextHorizontalPadding = 14.0;

/// Compact horizontal padding used when a [GlassBarTextItem] is explicitly
/// placed inside iPhone Duo's 48pt vertical strip (`verticalPreferred`).
const double kBarItemVerticalTextHorizontalPadding = 4.0;

/// Vertical padding used when a [GlassBarTextItem] is explicitly placed inside
/// iPhone Duo's 48pt vertical strip (`verticalPreferred`).
const double kBarItemVerticalTextVerticalPadding = 6.0;

/// Default glass fill alpha for [GlassBarItemStyle.prominent] bar capsules when
/// the resolved fill colour is fully opaque (`alpha == 1.0`).
///
/// Matches `GlassButton(style: GlassButtonStyle.prominent, tintColor: ...)` so
/// prominent bar items retain translucent depth and Fresnel rim physics over
/// scrolling backdrops.
const double kBarItemProminentTintAlpha = 0.85;

/// Luminance threshold above which tinted/prominent bar-item foregrounds flip
/// from white to black.
///
/// Matches `GlassButton` and `GlassIconButton` (`0.55`), keeping white glyphs
/// and text on `systemGreen` (~0.46) and `systemOrange` (~0.40) while flipping
/// bright tints like `systemYellow` (~0.67) to high-contrast black.
const double kBarItemContrastLuminanceThreshold = 0.55;

/// Whether [item] requests a custom tinted or prominent shell material rather
/// than the bar's shared neutral glass.
bool barItemHasCustomShellMaterial(GlassBarActionItem item) =>
    item.tintColor != null || item.style == GlassBarItemStyle.prominent;

/// Resolves the `glassColor` to flood a single-item capsule with via
/// [GlassBodyMode.clear], or `null` when the shell should render as neutral
/// bar glass.
///
/// - For [GlassBarItemBackground.none] and [GlassBarItemBackground.own], no
///   host glass shell is drawn, so this returns `null`.
/// - For [GlassBarItemStyle.prominent]:
///   - When disabled (`!item.enabled`), returns `null` so the capsule reverts
///     to neutral translucent glass with a dimmed foreground, matching native
///     iOS 26/27 `UIBarButtonItem.Style.prominent` / `.glassProminent`.
///   - When enabled, resolves `item.tintColor ?? CupertinoTheme.of(context).primaryColor`
///     through [CupertinoDynamicColor.resolve] and applies
///     [kBarItemProminentTintAlpha] unless the colour already specifies a lower
///     alpha.
/// - For [GlassBarItemStyle.plain] with a non-null `tintColor`: resolves
///   [CupertinoDynamicColor.resolve] while preserving its alpha verbatim for
///   full 1.x backwards compatibility.
Color? resolveBarItemShellFill(
  BuildContext context,
  GlassBarActionItem item,
) {
  if (item.background == GlassBarItemBackground.none ||
      item.background == GlassBarItemBackground.own) {
    return null;
  }
  if (item.style == GlassBarItemStyle.prominent) {
    if (!item.enabled) return null;
    final raw = item.tintColor ?? CupertinoTheme.of(context).primaryColor;
    final resolved = CupertinoDynamicColor.resolve(raw, context);
    final alpha = resolved.a < 1.0 ? resolved.a : kBarItemProminentTintAlpha;
    return resolved.withValues(alpha: alpha);
  }
  final tint = item.tintColor;
  if (tint == null) return null;
  return CupertinoDynamicColor.resolve(tint, context);
}

/// Resolves the [LiquidGlassSettings] override for a resting single-item or
/// multi-item glass shell, returning `null` when neutral bar glass applies.
LiquidGlassSettings? resolveRestingBarGroupSettings(
  BuildContext context, {
  required bool glass,
  required List<GlassBarActionItem> items,
}) {
  if (!glass || items.length != 1) return null;
  final fill = resolveBarItemShellFill(context, items.single);
  if (fill == null) return null;
  return GlassThemeHelpers.resolveSettings(
    context,
    explicit: DefaultButtonSettings.of(context),
  ).copyWith(
    glassColor: fill,
    bodyMode: GlassBodyMode.clear,
  );
}

/// Resolves the [LiquidGlassSettings] override for a morphing shell between
/// [fromItems] and [toItems] at clamped morph progress [t].
///
/// Returns `null` when both endpoints use neutral bar glass (or at a settled
/// neutral endpoint), and smoothly interpolates `glassColor` through
/// [GlassBodyMode.clear] whenever either endpoint is tinted or prominent.
LiquidGlassSettings? resolveMorphingBarGroupSettings(
  BuildContext context, {
  required bool fromGlass,
  required List<GlassBarActionItem> fromItems,
  required bool toGlass,
  required List<GlassBarActionItem> toItems,
  required double t,
  required bool settled,
}) {
  if (settled) {
    return resolveRestingBarGroupSettings(
      context,
      glass: toGlass,
      items: toItems,
    );
  }
  final fromFill = fromGlass && fromItems.length == 1
      ? resolveBarItemShellFill(context, fromItems.single)
      : null;
  final toFill = toGlass && toItems.length == 1
      ? resolveBarItemShellFill(context, toItems.single)
      : null;
  if (fromFill == null && toFill == null) return null;

  final base = GlassThemeHelpers.resolveSettings(
    context,
    explicit: DefaultButtonSettings.of(context),
  );

  if (fromFill != null && toFill != null) {
    return base.copyWith(
      glassColor: Color.lerp(fromFill, toFill, t)!,
      bodyMode: GlassBodyMode.clear,
    );
  }
  if (fromFill == null) {
    // Neutral -> tinted / prominent.
    if (t <= 0.001) return null;
    if (t >= 0.999) {
      return base.copyWith(glassColor: toFill!, bodyMode: GlassBodyMode.clear);
    }
    return base.copyWith(
      glassColor: Color.lerp(base.glassColor, toFill!, t)!,
      bodyMode: GlassBodyMode.clear,
    );
  }
  // Tinted / prominent -> neutral.
  if (t <= 0.001) {
    return base.copyWith(glassColor: fromFill, bodyMode: GlassBodyMode.clear);
  }
  if (t >= 0.999) return null;
  return base.copyWith(
    glassColor: Color.lerp(fromFill, base.glassColor, t)!,
    bodyMode: GlassBodyMode.clear,
  );
}

/// Resolves the foreground icon/text colour for [item].
///
/// - Over an active tinted or prominent glass shell: high-contrast black or
///   white computed from the shell fill's luminance.
/// - For an enabled [GlassBarItemStyle.prominent] item with
///   [GlassBarItemBackground.none]: uses the resolved accent colour so bare
///   prominent labels remain readable on light and dark pages.
/// - Otherwise (plain untinted items, disabled prominent items reverted to
///   neutral glass, or `own` glass items): [CupertinoColors.label].
Color resolveBarItemForegroundColor(
  BuildContext context,
  GlassBarActionItem item,
) {
  final shellFill = resolveBarItemShellFill(context, item);
  if (shellFill != null) {
    return shellFill.computeLuminance() > kBarItemContrastLuminanceThreshold
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }
  if (item.style == GlassBarItemStyle.prominent &&
      item.background == GlassBarItemBackground.none &&
      item.enabled) {
    final raw = item.tintColor ?? CupertinoTheme.of(context).primaryColor;
    return CupertinoDynamicColor.resolve(raw, context);
  }
  return CupertinoColors.label.resolveFrom(context);
}

/// Resolves the Cupertino navigation-bar button typography for [item].
TextStyle resolveBarItemTextStyle(
  BuildContext context,
  GlassBarActionItem item,
  Color foregroundColor,
) {
  final base = CupertinoTheme.of(context).textTheme.navActionTextStyle;
  return base.copyWith(
    fontSize: 17.0,
    letterSpacing: -0.41,
    fontWeight: item.style == GlassBarItemStyle.prominent
        ? FontWeight.w600
        : FontWeight.w400,
    color: foregroundColor,
  );
}

/// Builds [item]'s sized and styled visual slot so hoisted chrome, in-route
/// chrome, and measuring placeholders agree to the sub-pixel.
///
/// When [imposeCrossExtent] is `true` (used by in-route `Flex` groups and
/// measuring placeholders), the cross-axis size ([crossExtent]) is imposed
/// explicitly; when `false` (used inside `_RenderPinnedCluster`, which already
/// imposes tight cross-axis constraints), only main-axis sizing and padding
/// are applied.
Widget buildBarItemSlotContent(
  BuildContext context, {
  required GlassBarActionItem item,
  required double crossExtent,
  required double slotExtent,
  required double iconSize,
  required Axis axis,
  required bool imposeCrossExtent,
  TextDirection? restoreDirection,
}) {
  final foreground = resolveBarItemForegroundColor(context, item);
  final hasShellFill = resolveBarItemShellFill(context, item) != null;

  Widget wrapDirection(Widget child) => restoreDirection == null
      ? child
      : Directionality(textDirection: restoreDirection, child: child);

  Widget wrapIconSlot(Widget icon) {
    final Widget sized;
    if (axis == Axis.vertical) {
      sized = SizedBox(
        width: imposeCrossExtent ? crossExtent : null,
        height: slotExtent,
        child: Center(child: wrapDirection(icon)),
      );
    } else {
      sized = SizedBox(
        width: slotExtent,
        height: imposeCrossExtent ? crossExtent : null,
        child: Center(child: wrapDirection(icon)),
      );
    }
    return IconTheme.merge(
      data: IconThemeData(size: iconSize, color: foreground),
      child: sized,
    );
  }

  return switch (item) {
    GlassBarIconItem(:final icon) => wrapIconSlot(icon),
    GlassBarMenuItem(:final icon) => wrapIconSlot(icon),
    GlassBarSheetItem(:final icon) => wrapIconSlot(icon),
    GlassBarTextItem() => _buildTextSlot(
        context,
        item: item,
        foreground: foreground,
        crossExtent: crossExtent,
        slotExtent: slotExtent,
        axis: axis,
        imposeCrossExtent: imposeCrossExtent,
        wrapDirection: wrapDirection,
      ),
    GlassBarCustomItem(:final child) => _buildCustomSlot(
        item: item,
        child: child,
        foreground: foreground,
        applyContrastTextColor:
            hasShellFill || item.style == GlassBarItemStyle.prominent,
        crossExtent: crossExtent,
        iconSize: iconSize,
        axis: axis,
        imposeCrossExtent: imposeCrossExtent,
        wrapDirection: wrapDirection,
      ),
  };
}

Widget _buildTextSlot(
  BuildContext context, {
  required GlassBarTextItem item,
  required Color foreground,
  required double crossExtent,
  required double slotExtent,
  required Axis axis,
  required bool imposeCrossExtent,
  required Widget Function(Widget) wrapDirection,
}) {
  final styledText = DefaultTextStyle(
    style: resolveBarItemTextStyle(context, item, foreground),
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    child: wrapDirection(item.content),
  );

  if (axis == Axis.vertical) {
    final constrained = ConstrainedBox(
      constraints: BoxConstraints(minHeight: slotExtent),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: kBarItemVerticalTextHorizontalPadding,
          vertical: kBarItemVerticalTextVerticalPadding,
        ),
        child: Center(heightFactor: 1.0, child: styledText),
      ),
    );
    return imposeCrossExtent
        ? SizedBox(width: crossExtent, child: constrained)
        : constrained;
  }

  final constrained = ConstrainedBox(
    constraints: BoxConstraints(minWidth: crossExtent),
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: kBarItemTextHorizontalPadding,
      ),
      child: Center(widthFactor: 1.0, child: styledText),
    ),
  );
  return imposeCrossExtent
      ? SizedBox(height: crossExtent, child: constrained)
      : constrained;
}

Widget _buildCustomSlot({
  required GlassBarCustomItem item,
  required Widget child,
  required Color foreground,
  required bool applyContrastTextColor,
  required double crossExtent,
  required double iconSize,
  required Axis axis,
  required bool imposeCrossExtent,
  required Widget Function(Widget) wrapDirection,
}) {
  Widget content = wrapDirection(child);
  if (applyContrastTextColor) {
    content = DefaultTextStyle.merge(
      style: TextStyle(color: foreground),
      child: content,
    );
  }
  content = IconTheme.merge(
    data: IconThemeData(size: iconSize, color: foreground),
    child: content,
  );
  if (!imposeCrossExtent) return content;

  // Bare custom items keep their own child alignment within crossExtent (matching
  // prior GlassPinnedBarChrome behaviour); glass-backed custom items centre
  // inside the capsule slot.
  final bool centerChild = item.background != GlassBarItemBackground.none &&
      item.background != GlassBarItemBackground.own;
  final inner = centerChild ? Center(child: content) : content;
  return axis == Axis.vertical
      ? SizedBox(width: crossExtent, child: inner)
      : SizedBox(height: crossExtent, child: inner);
}
