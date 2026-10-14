import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../shared/glass_solid_surface.dart';
import 'glass_container.dart';
import 'glass_divider.dart';

/// A reorderable list of items rendered with iOS liquid glass aesthetics,
/// providing direct parity with SwiftUI's `ForEach.onMove()` within a `List`.
///
/// When an item is dragged to reorder, [GlassReorderableList] applies an authentic
/// iOS lift effect with a subtle `1.025x` scale, elevated liquid glass shadow, and
/// smooth spring-animated row displacement.
///
/// ## Usage
///
/// ```dart
/// GlassReorderableList(
///   itemCount: items.length,
///   onReorderItem: (oldIndex, newIndex) {
///     setState(() {
///       final item = items.removeAt(oldIndex);
///       items.insert(newIndex, item);
///     });
///   },
///   itemBuilder: (context, index) {
///     final item = items[index];
///     return GlassListTile(
///       key: ValueKey(item.id),
///       reorderIndex: index,
///       canReorder: true,
///       title: Text(item.name),
///       onDelete: () => removeItem(index),
///     );
///   },
/// )
/// ```
class GlassReorderableList extends StatelessWidget {
  /// Creates a standard [GlassReorderableList].
  const GlassReorderableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onReorderItem,
    this.onReorder,
    this.proxyDecorator,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.header,
    this.footer,
    this.enableHaptics = true,
  })  : assert(
          onReorderItem != null || onReorder != null,
          'Either onReorderItem or onReorder must be provided.',
        ),
        _isGrouped = false,
        _settings = null,
        _shape = null,
        _quality = null,
        _useOwnLayer = null,
        _surfaceStyle = GlassSurfaceStyle.glass;

  /// Creates a [GlassReorderableList] styled as an iOS grouped table card
  /// with superellipse corners, automatic dividers, and optional header/footer.
  ///
  /// [surfaceStyle] defaults to [GlassSurfaceStyle.glass] in 1.x. Use
  /// [GlassSurfaceStyle.solid] for a flat opaque card matching native iOS
  /// inset-grouped lists. With the default proxy decorator, a solid list also
  /// gives the lifted row the card fill so it stays opaque while dragging.
  const GlassReorderableList.grouped({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onReorderItem,
    this.onReorder,
    this.proxyDecorator,
    this.padding,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.header,
    this.footer,
    this.enableHaptics = true,
    LiquidGlassSettings? settings,
    LiquidShape? shape,
    GlassQuality? quality,
    bool? useOwnLayer,
    GlassSurfaceStyle surfaceStyle = GlassSurfaceStyle.glass,
  })  : assert(
          onReorderItem != null || onReorder != null,
          'Either onReorderItem or onReorder must be provided.',
        ),
        _isGrouped = true,
        _settings = settings,
        _shape = shape,
        _quality = quality,
        _useOwnLayer = useOwnLayer,
        _surfaceStyle = surfaceStyle;

  /// Total number of items in the list.
  final int itemCount;

  /// Called to build each item widget for the given index.
  ///
  /// Every item returned MUST have a unique [Key] (e.g. [ValueKey]).
  final IndexedWidgetBuilder itemBuilder;

  /// Modern callback called when an item has finished dragging and settled at `newIndex`.
  ///
  /// Unlike legacy [onReorder], Flutter automatically adjusts `newIndex` for the removed item.
  final ReorderCallback? onReorderItem;

  /// Callback called when an item has finished dragging and settled at `newIndex`.
  ///
  /// If provided without [onReorderItem], `newIndex` is passed matching Flutter's legacy convention.
  final ReorderCallback? onReorder;

  /// Custom proxy decorator for the item being dragged.
  ///
  /// If null, uses the authentic iOS liquid glass elevation proxy.
  final ReorderItemProxyDecorator? proxyDecorator;

  /// Padding around the list content.
  final EdgeInsetsGeometry? padding;

  /// Whether the list should shrink-wrap its contents.
  final bool shrinkWrap;

  /// Scroll physics for the list.
  final ScrollPhysics? physics;

  /// Optional header widget displayed above the list.
  final Widget? header;

  /// Optional footer widget displayed below the list.
  final Widget? footer;

  /// Whether to trigger a selection haptic tick when an item is lifted.
  final bool enableHaptics;

  final bool _isGrouped;
  final LiquidGlassSettings? _settings;
  final LiquidShape? _shape;
  final GlassQuality? _quality;
  final bool? _useOwnLayer;
  final GlassSurfaceStyle _surfaceStyle;

  Widget _defaultProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    if (enableHaptics && animation.status == AnimationStatus.forward) {
      HapticFeedback.selectionClick();
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double animValue = Curves.easeOutCubic.transform(animation.value);
        final double scale = 1.0 + (0.025 * animValue);
        final double shadowElevation = 18.0 * animValue;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              // A solid card is opaque, so the lifted row must be too.
              color: _isGrouped && _surfaceStyle == GlassSurfaceStyle.solid
                  ? resolveGlassSolidSurfaceColor(context)
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      CupertinoColors.black.withValues(alpha: 0.32 * animValue),
                  blurRadius: shadowElevation,
                  offset: Offset(0, 8.0 * animValue),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProxyDecorator = proxyDecorator ?? _defaultProxyDecorator;

    Widget listView = CustomScrollView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      slivers: [
        if (padding != null)
          SliverPadding(
            padding: padding!,
            sliver: _buildSliverList(effectiveProxyDecorator),
          )
        else
          _buildSliverList(effectiveProxyDecorator),
      ],
    );

    if (_isGrouped) {
      final card = GlassContainer.card(
        useOwnLayer: _useOwnLayer ?? false,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        shape: _shape,
        settings: _settings,
        quality: _quality,
        surfaceStyle: _surfaceStyle,
        clipBehavior: _surfaceStyle == GlassSurfaceStyle.solid
            ? Clip.antiAlias
            : Clip.none,
        child: listView,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16.0,
                end: 16.0,
                bottom: 6.0,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                child: header!,
              ),
            ),
          card,
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16.0,
                end: 16.0,
                top: 6.0,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                child: footer!,
              ),
            ),
        ],
      );
    }

    if (header != null || footer != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          Flexible(child: listView),
          if (footer != null) footer!,
        ],
      );
    }

    return listView;
  }

  Widget _buildSliverList(ReorderItemProxyDecorator proxyDecorator) {
    return SliverReorderableList(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final child = itemBuilder(context, index);
        if (!_isGrouped || index == itemCount - 1) {
          return child;
        }

        // Interleave a GlassDivider below item if grouped
        return Column(
          key: child.key,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            const GlassDivider(indent: 56.0),
          ],
        );
      },
      // ignore: deprecated_member_use
      onReorder: (int oldIndex, int newIndex) {
        if (onReorderItem != null) {
          final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
          onReorderItem!(oldIndex, adjusted);
        } else {
          onReorder!(oldIndex, newIndex);
        }
      },
      proxyDecorator: proxyDecorator,
    );
  }
}
