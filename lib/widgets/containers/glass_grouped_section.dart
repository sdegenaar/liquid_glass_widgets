import 'package:flutter/cupertino.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import 'glass_container.dart';
import 'glass_disclosure_group.dart';
import 'glass_divider.dart';
import 'glass_list_tile.dart';
import '../shared/glass_solid_surface.dart';

/// A convenience wrapper that groups [GlassListTile]s inside a card
/// ([GlassContainer.card]).
///
/// [GlassGroupedSection] automatically injects [GlassDivider]s between tiles,
/// with smart leading-indent detection — 56px when the preceding tile has a
/// [GlassListTile.leading] widget, 16px otherwise.
///
/// ## iOS 26 pattern
///
/// In iOS 26, Settings-style screens group related rows inside
/// `UITableView` grouped sections. [GlassGroupedSection] provides the
/// glass equivalent of that pattern.
///
/// ## Usage
///
/// ```dart
/// GlassGroupedSection(
///   header: const Text('NETWORK'),
///   children: [
///     GlassListTile(
///       leading: Icon(CupertinoIcons.wifi, color: CupertinoColors.white),
///       title: Text('Wi-Fi'),
///       trailing: GlassListTile.chevron,
///     ),
///     GlassListTile(
///       leading: Icon(CupertinoIcons.bluetooth, color: CupertinoColors.white),
///       title: Text('Bluetooth'),
///       trailing: GlassListTile.chevron,
///     ),
///     GlassListTile(
///       leading: Icon(CupertinoIcons.antenna_radiowaves_left_right,
///           color: CupertinoColors.white),
///       title: Text('VPN'),
///       trailing: GlassListTile.chevron,
///     ),
///   ],
/// )
/// ```
///
/// ## Children
///
/// [GlassGroupedSection] is designed to contain [GlassListTile] rows and
/// standard Flutter content. Do not place interactive glass controls
/// (`GlassSegmentedControl`, `GlassSlider`, `GlassSwitch`, `GlassButton`)
/// as direct children — this is a glass-in-glass anti-pattern that degrades
/// refraction and can clip indicator animations. See [GlassContainer] for
/// the full explanation.
///
/// ## Surface style
///
/// [surfaceStyle] defaults to [GlassSurfaceStyle.glass] in 1.x. iOS renders
/// inset-grouped cards as flat, opaque surfaces, so use
/// [GlassSurfaceStyle.solid] for sections in a scrolling page to match:
///
/// ```dart
/// GlassGroupedSection(
///   surfaceStyle: GlassSurfaceStyle.solid,
///   children: [...],
/// )
/// ```

class GlassGroupedSection extends StatelessWidget {
  /// Creates a grouped section of glass list tiles.
  const GlassGroupedSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin,
    this.shape,
    this.settings,
    this.useOwnLayer = false,
    this.quality,
    this.dividerIndent,
    this.surfaceStyle = GlassSurfaceStyle.glass,
    this.clipBehavior,
  });

  /// The list tiles to display inside the section.
  ///
  /// Typically [GlassListTile] widgets. [GlassGroupedSection] automatically
  /// injects [GlassDivider]s between adjacent tiles — no manual divider or
  /// position tracking needed.
  final List<Widget> children;

  /// Optional header displayed above the glass card.
  ///
  /// Typically a [Text] widget with section title styling (uppercase, small
  /// font, muted colour) matching iOS grouped table section headers.
  final Widget? header;

  /// Optional footer displayed below the glass card.
  ///
  /// Typically a [Text] widget with explanatory text matching iOS grouped
  /// table section footers.
  final Widget? footer;

  /// Empty space to surround the section card.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16, vertical: 6)` matching
  /// iOS grouped table section insets.
  final EdgeInsetsGeometry? margin;

  /// Shape of the card.
  ///
  /// If null, uses [GlassContainer.card]'s default shape: a 12px superellipse
  /// for [GlassSurfaceStyle.glass], 26px for [GlassSurfaceStyle.solid].
  final LiquidShape? shape;

  /// Glass effect settings.
  ///
  /// If null, inherits from the parent layer or theme. Ignored when
  /// [surfaceStyle] is [GlassSurfaceStyle.solid].
  final LiquidGlassSettings? settings;

  /// Whether to create its own glass layer.
  ///
  /// Defaults to false (grouped mode). Ignored when [surfaceStyle] is
  /// [GlassSurfaceStyle.solid].
  final bool useOwnLayer;

  /// Rendering quality. Ignored when [surfaceStyle] is
  /// [GlassSurfaceStyle.solid].
  final GlassQuality? quality;

  /// How the section card is painted.
  ///
  /// [GlassSurfaceStyle.glass] (default in 1.x) renders a glass card.
  /// [GlassSurfaceStyle.solid] renders a flat opaque card matching native iOS
  /// inset-grouped lists, and clips the rows to the card's corners.
  final GlassSurfaceStyle surfaceStyle;

  /// How the section card clips its children.
  ///
  /// Defaults to [Clip.antiAlias] when [surfaceStyle] is
  /// [GlassSurfaceStyle.solid] (to clip row press highlights and swipe actions
  /// to the card's rounded corners), and [Clip.none] when [surfaceStyle] is
  /// [GlassSurfaceStyle.glass].
  final Clip? clipBehavior;

  /// Start inset of the automatically inserted dividers that follow a tile
  /// with a leading widget.
  ///
  /// Defaults to 56 (a 32pt leading slot + 12pt gap + 12pt inset). Set this to
  /// the text-start offset when using a larger leading widget, e.g. 72 for a
  /// 44pt avatar row. Dividers following tiles without a leading widget always
  /// use 16.
  final double? dividerIndent;

  Widget _buildHeader(BuildContext context) {
    if (header == null) return const SizedBox.shrink();
    return Padding(
      padding:
          const EdgeInsetsDirectional.only(start: 16.0, end: 16.0, bottom: 6.0),
      child: DefaultTextStyle(
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        child: header!,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (footer == null) return const SizedBox.shrink();
    return Padding(
      padding:
          const EdgeInsetsDirectional.only(start: 16.0, end: 16.0, top: 6.0),
      child: DefaultTextStyle(
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        child: footer!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMargin =
        margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6);

    // Interleave GlassDividers between adjacent children. The divider indent
    // is derived from the preceding tile's leading widget — 56px with a leading
    // icon (32px icon + 12px gap + 12px content start inset) or 16px otherwise.
    // If the user manually placed a GlassDivider in children, we don't insert
    // automatic dividers around it to prevent double-dividers.
    final processedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      processedChildren.add(children[i]);

      final isLastChild = i == children.length - 1;
      if (!isLastChild) {
        final currentChild = children[i];
        final nextChild = children[i + 1];

        // Skip auto-divider if the current child is a divider, or if the next
        // child is a divider. This prevents doubling them up.
        if (currentChild is GlassDivider || nextChild is GlassDivider) continue;

        // Compute indent based on whether the current tile has a leading widget.
        final double indent =
            ((currentChild is GlassListTile && currentChild.leading != null) ||
                    (currentChild is GlassDisclosureGroup &&
                        currentChild.leading != null))
                ? (dividerIndent ?? 56.0)
                : 16.0;
        processedChildren.add(GlassDivider(indent: indent));
      }
    }

    final effectiveClipBehavior = clipBehavior ??
        (surfaceStyle == GlassSurfaceStyle.solid ? Clip.antiAlias : Clip.none);

    final card = GlassContainer.card(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      shape: shape,
      settings: settings,
      useOwnLayer: useOwnLayer,
      quality: quality,
      surfaceStyle: surfaceStyle,
      clipBehavior: effectiveClipBehavior,
      child: InheritedGlassSurfaceStyle(
        surfaceStyle: surfaceStyle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: processedChildren,
        ),
      ),
    );

    Widget section = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        card,
        _buildFooter(context),
      ],
    );

    if (effectiveMargin != EdgeInsets.zero) {
      section = Padding(
        padding: effectiveMargin,
        child: section,
      );
    }

    return section;
  }
}
