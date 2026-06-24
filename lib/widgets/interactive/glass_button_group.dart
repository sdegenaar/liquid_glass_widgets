import 'package:flutter/cupertino.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../theme/glass_theme.dart';
import '../../types/glass_button_style.dart';
import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import 'glass_button.dart';
import '../../theme/glass_theme_helpers.dart';

// =============================================================================
// GlassGroupItem — lightweight data model
// =============================================================================

/// A lightweight data class representing a single item in a [GlassButtonGroup].
///
/// Unlike [GlassButton], a [GlassGroupItem] carries no widget state — no
/// animation controllers, no stretch physics, no glow overlays. The parent
/// [GlassButtonGroup] provides the glass surface and renders each item as a
/// simple icon with a press-dim highlight.
///
/// ```dart
/// GlassButtonGroup.icons(
///   items: [
///     GlassGroupItem(icon: Icon(CupertinoIcons.bold), onTap: () {}),
///     GlassGroupItem(icon: Icon(CupertinoIcons.italic), onTap: () {}),
///     GlassGroupItem(icon: Icon(CupertinoIcons.underline), onTap: () {}),
///   ],
/// )
/// ```
class GlassGroupItem {
  /// Creates a group item with an icon and tap callback.
  const GlassGroupItem({
    required this.icon,
    required this.onTap,
    this.label,
    this.enabled = true,
  });

  /// The icon widget to display.
  ///
  /// Typically a [CupertinoIcon] or [Icon]. The parent [GlassButtonGroup]
  /// wraps this in an [IconTheme] that sets size and color based on the
  /// current brightness.
  final Widget icon;

  /// Called when the item is tapped.
  final VoidCallback onTap;

  /// Optional semantic label for accessibility.
  ///
  /// If provided, wraps the item in [Semantics] with `button: true`.
  final String? label;

  /// Whether the item is interactive.
  ///
  /// When false, the item renders at 50% opacity and ignores taps.
  final bool enabled;
}

// =============================================================================
// GlassButtonGroup
// =============================================================================

/// A container that groups multiple buttons in a single glass pill.
///
/// ## Two usage modes
///
/// ### 1. Lightweight items (recommended)
///
/// Use [GlassButtonGroup.icons] with [GlassGroupItem] data objects. Each item
/// is rendered as a minimal icon with tap handling — no animation controllers
/// or glass shaders per item. The group provides the glass surface.
///
/// ```dart
/// GlassButtonGroup.icons(
///   items: [
///     GlassGroupItem(icon: Icon(CupertinoIcons.text_alignleft), onTap: () {}),
///     GlassGroupItem(icon: Icon(CupertinoIcons.trash), onTap: () {}),
///     GlassGroupItem(icon: Icon(CupertinoIcons.add), onTap: () {}),
///   ],
/// )
/// ```
///
/// ### 2. Full widget children
///
/// Use the default constructor with [GlassButton] children for full control
/// over each button's style, stretch, and glow.
///
/// ```dart
/// GlassButtonGroup(
///   children: [
///     GlassButton(icon: Icon(CupertinoIcons.bold), style: GlassButtonStyle.transparent, onTap: () {}),
///     GlassButton(icon: Icon(CupertinoIcons.italic), style: GlassButtonStyle.transparent, onTap: () {}),
///   ],
/// )
/// ```
class GlassButtonGroup extends StatelessWidget {
  /// Creates a group of glass buttons from widget children.
  ///
  /// Children should be [GlassButton]s with [GlassButtonStyle.transparent].
  /// For a lighter-weight alternative, use [GlassButtonGroup.icons].
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
    this.iconSize = 22.0,
    this.itemPadding = const EdgeInsets.all(12),
    this.platformViewBackdrop = false,
  }) : items = null;

  /// Creates a group of glass buttons from lightweight [GlassGroupItem]s.
  ///
  /// Each item is rendered as a simple icon with press-dim feedback — no
  /// animation controllers, stretch physics, or glow overlays. The group
  /// provides the glass surface.
  ///
  /// Defaults to `showDividers: false` and `borderRadius: 22.0` for the
  /// unified pill look shown in iOS 26 toolbar groups.
  const GlassButtonGroup.icons({
    required List<GlassGroupItem> this.items,
    super.key,
    this.direction = Axis.horizontal,
    this.settings,
    this.quality,
    this.borderRadius = 22.0,
    this.borderColor,
    this.useOwnLayer = false,
    this.showDividers = false,
    this.iconSize = 22.0,
    this.itemPadding = const EdgeInsets.all(12),
    this.platformViewBackdrop = false,
  }) : children = const [];

  /// The buttons to display in the group (widget children mode).
  ///
  /// Ideally, these should be [GlassButton]s with [GlassButtonStyle.transparent].
  /// Empty when using [GlassButtonGroup.icons].
  final List<Widget> children;

  /// Lightweight item data for icon-based groups.
  ///
  /// When non-null, [children] is ignored and items are rendered internally
  /// as lightweight icons with press-dim feedback.
  final List<GlassGroupItem>? items;

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
  /// Defaults to `true` for the [GlassButtonGroup] constructor,
  /// `false` for [GlassButtonGroup.icons].
  final bool showDividers;

  /// The icon size used for items in [GlassButtonGroup.icons] mode.
  ///
  /// Defaults to 22.0.
  final double iconSize;

  /// Padding around each item in [GlassButtonGroup.icons] mode.
  ///
  /// Defaults to `EdgeInsets.all(12)`.
  final EdgeInsetsGeometry itemPadding;

  /// Forces the BackdropFilter fallback render path so premium glass
  /// renders cleanly over an iOS PlatformView.
  ///
  /// The premium shader pipeline cannot sample PlatformView pixels (e.g.
  /// a Mapbox `MapWidget`), so over one it would render the group as a
  /// solid slab. When true, the group falls back to Flutter's
  /// BackdropFilter — which *can* sample PlatformViews on Impeller — so
  /// `quality: GlassQuality.premium` can be used over a PlatformView
  /// without the slab artifact. Forwarded to the underlying
  /// [GlassButton.custom] (items mode) / [GlassContainer] (children mode).
  /// Defaults to false.
  final bool platformViewBackdrop;

  @override
  Widget build(BuildContext context) {
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
    );

    // Resolve icon color from brightness.
    final iconColor = CupertinoColors.label.resolveFrom(context);

    // ---------------------------------------------------------------------------
    // Items mode: use a GlassButton.custom as the parent shell.
    //
    // This gives the whole pill stretch, glow, saturation, and shadow for free
    // via existing GlassButton infrastructure — one AnimationController for the
    // entire group instead of one per icon. Individual items handle their own
    // tap targets with lightweight GestureDetectors.
    // ---------------------------------------------------------------------------
    if (items != null) {
      final shape = LiquidRoundedSuperellipse(borderRadius: borderRadius);
      return GlassButton.custom(
        onTap: () {}, // Items handle their own taps
        shape: shape,
        settings: settings,
        useOwnLayer: useOwnLayer,
        quality: effectiveQuality,
        platformViewBackdrop: platformViewBackdrop,
        width: null, // Size to content
        height: null, // Size to content
        // Reduce stretch for grouped buttons — full stretch looks too dramatic
        // on a wide pill. This matches iOS 26 toolbar feel.
        stretch: 0.15,
        child: IntrinsicHeight(
          child: Flex(
            direction: direction,
            mainAxisSize: MainAxisSize.min,
            children: _buildItemWidgets(iconColor),
          ),
        ),
      );
    }

    // ---------------------------------------------------------------------------
    // Children mode: use GlassContainer for full widget flexibility.
    // ---------------------------------------------------------------------------
    final effectiveBorderColor = borderColor ??
        (GlassTheme.brightnessOf(context) == Brightness.light
            ? CupertinoColors.black.withValues(alpha: 0.12)
            : CupertinoColors.white.withValues(alpha: 0.12));

    return GlassContainer(
      useOwnLayer: useOwnLayer,
      quality: effectiveQuality,
      settings: settings,
      platformViewBackdrop: platformViewBackdrop,
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

  // ---------------------------------------------------------------------------
  // Items mode — lightweight icons with press-dim highlight
  // ---------------------------------------------------------------------------

  List<Widget> _buildItemWidgets(Color iconColor) {
    final itemList = items!;
    final List<Widget> widgets = [];

    for (int i = 0; i < itemList.length; i++) {
      if (showDividers && i > 0) {
        widgets.add(
          direction == Axis.horizontal
              ? Container(width: 1, color: iconColor.withValues(alpha: 0.12))
              : Container(height: 1, color: iconColor.withValues(alpha: 0.12)),
        );
      }

      widgets.add(
        _GlassGroupItemWidget(
          item: itemList[i],
          iconColor: iconColor,
          iconSize: iconSize,
          padding: itemPadding,
        ),
      );
    }
    return widgets;
  }

  // ---------------------------------------------------------------------------
  // Children mode — full widget children with optional dividers
  // ---------------------------------------------------------------------------

  List<Widget> _buildChildrenWithDividers(Color resolvedBorderColor) {
    if (!showDividers) {
      return children;
    }

    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        result.add(
          direction == Axis.horizontal
              ? Container(width: 1, color: resolvedBorderColor)
              : Container(height: 1, color: resolvedBorderColor),
        );
      }
      result.add(children[i]);
    }
    return result;
  }
}

// =============================================================================
// _GlassGroupItemWidget — lightweight per-item tap target
// =============================================================================

/// Renders a single [GlassGroupItem] as a minimal tap target.
///
/// The parent [GlassButton.custom] provides all visual press feedback
/// (stretch, glow, saturation). This widget only handles individual tap
/// routing and accessibility semantics.
class _GlassGroupItemWidget extends StatelessWidget {
  const _GlassGroupItemWidget({
    required this.item,
    required this.iconColor,
    required this.iconSize,
    required this.padding,
  });

  final GlassGroupItem item;
  final Color iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.enabled ? item.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: item.label,
        enabled: item.enabled,
        child: Opacity(
          opacity: item.enabled ? 1.0 : 0.5,
          child: Padding(
            padding: padding,
            child: IconTheme(
              data: IconThemeData(
                color: iconColor,
                size: iconSize,
              ),
              child: item.icon,
            ),
          ),
        ),
      ),
    );
  }
}
