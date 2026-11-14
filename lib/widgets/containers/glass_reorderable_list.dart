import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../shared/glass_edit_scope.dart';
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
class GlassReorderableList extends StatefulWidget {
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
  }) : assert(
         onReorderItem != null || onReorder != null,
         'Either onReorderItem or onReorder must be provided.',
       ),
       _isGrouped = false,
       dividerIndent = 56.0,
       dividerEndIndent = 0.0,
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
    this.dividerIndent = 56.0,
    this.dividerEndIndent = 0.0,
    this._settings,
    this._shape,
    this._quality,
    this._useOwnLayer,
    this._surfaceStyle = GlassSurfaceStyle.glass,
  }) : assert(
         onReorderItem != null || onReorder != null,
         'Either onReorderItem or onReorder must be provided.',
       ),
       _isGrouped = true;

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

  /// Start inset (logical pixels) of the dividers between rows in a
  /// [GlassReorderableList.grouped] card.
  ///
  /// Defaults to 56. Native iOS aligns the separator with the row title, so a
  /// row with a leading badge and icon typically needs a larger value
  /// (e.g. 124 for the edit-mode layout).
  final double dividerIndent;

  /// End inset (logical pixels) of the dividers between rows in a
  /// [GlassReorderableList.grouped] card.
  ///
  /// Defaults to 0. Native inset-grouped lists stop the separator 16pt short
  /// of the card's trailing edge.
  final double dividerEndIndent;

  final bool _isGrouped;
  final LiquidGlassSettings? _settings;
  final LiquidShape? _shape;
  final GlassQuality? _quality;
  final bool? _useOwnLayer;
  final GlassSurfaceStyle _surfaceStyle;

  @override
  State<GlassReorderableList> createState() => _GlassReorderableListState();
}

class _GlassReorderableListState extends State<GlassReorderableList> {
  int? _draggedIndex;

  Widget _defaultProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    if (widget.enableHaptics && animation.status == AnimationStatus.forward) {
      HapticFeedback.selectionClick();
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double animValue = Curves.easeOutCubic.transform(animation.value);
        final double scale = 1.0 + (0.035 * animValue);
        final double shadowElevation = 20.0 * animValue;

        // Native iOS scales the lifted row about the finger. In edit mode the
        // finger is on the grabber (centre ≈27.8pt in from the trailing edge),
        // so the row grows mostly leftwards instead of about its centre.
        final bool fromGrabber = GlassEditScope.maybeOf(this.context) != null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final Alignment scaleAlignment = fromGrabber && w.isFinite && w > 0
                ? Alignment(1.0 - (2 * 27.8 / w), 0)
                : Alignment.center;
            return Transform.scale(
              scale: scale,
              alignment: scaleAlignment,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Shadow layer: clipped to the *outside* of the row so a
                  // translucent fill isn't darkened by the shadow beneath it.
                  Positioned.fill(
                    child: ClipPath(
                      clipper: const _OutsideRectClipper(),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withValues(
                                alpha: 0.18 * animValue,
                              ),
                              blurRadius: shadowElevation,
                              offset: Offset(0, 8.0 * animValue),
                            ),
                            BoxShadow(
                              color: CupertinoColors.black.withValues(
                                alpha: 0.06 * animValue,
                              ),
                              blurRadius: 6.0 * animValue,
                              offset: Offset(0, 2.0 * animValue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      // Native iOS 27 lifts the row with a slightly translucent
                      // card fill: the rows passing underneath stay faintly
                      // visible.
                      color:
                          widget._isGrouped &&
                              widget._surfaceStyle == GlassSurfaceStyle.solid
                          ? resolveGlassSolidSurfaceColor(context)
                                .withValues(alpha: 1.0 - (0.24 * animValue))
                          : null,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: child,
                  ),
                ],
              ),
            );
          },
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProxyDecorator =
        widget.proxyDecorator ?? _defaultProxyDecorator;
    final effectiveSurfaceStyle =
        InheritedGlassSurfaceStyle.maybeOf(context) ?? widget._surfaceStyle;
    final editController = GlassEditScope.maybeOf(context);

    Widget listView = CustomScrollView(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      slivers: [
        if (widget.padding != null)
          SliverPadding(
            padding: widget.padding!,
            sliver: _buildSliverList(
              effectiveProxyDecorator,
              editController,
              effectiveSurfaceStyle,
            ),
          )
        else
          _buildSliverList(
            effectiveProxyDecorator,
            editController,
            effectiveSurfaceStyle,
          ),
      ],
    );

    if (widget._isGrouped) {
      final card = GlassContainer.card(
        useOwnLayer: widget._useOwnLayer ?? false,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        shape: widget._shape,
        settings: widget._settings,
        quality: widget._quality,
        surfaceStyle: widget._surfaceStyle,
        color:
            _draggedIndex != null &&
                effectiveSurfaceStyle == GlassSurfaceStyle.solid
            ? const Color(0x00000000)
            : null,
        clipBehavior: widget._surfaceStyle == GlassSurfaceStyle.solid
            ? Clip.antiAlias
            : Clip.none,
        child: listView,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null)
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
                child: widget.header!,
              ),
            ),
          card,
          if (widget.footer != null)
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
                child: widget.footer!,
              ),
            ),
        ],
      );
    }

    if (widget.header != null || widget.footer != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null) widget.header!,
          Flexible(child: listView),
          if (widget.footer != null) widget.footer!,
        ],
      );
    }

    return listView;
  }

  Widget _buildSliverList(
    ReorderItemProxyDecorator proxyDecorator,
    GlassEditController? editController,
    GlassSurfaceStyle surfaceStyle,
  ) {
    return SliverReorderableList(
      itemCount: widget.itemCount,
      onReorderStart: (int index) {
        setState(() {
          _draggedIndex = index;
        });
      },
      onReorderEnd: (int index) {
        setState(() {
          _draggedIndex = null;
        });
      },
      itemBuilder: (context, index) {
        final child = widget.itemBuilder(context, index);
        if (!widget._isGrouped) {
          return child;
        }

        // When an item is actively being dragged in a solid grouped list,
        // native iOS splits the card into separate rounded cards around the
        // dragged item/gap, showing the screen background between segments.
        if (_draggedIndex != null && surfaceStyle == GlassSurfaceStyle.solid) {
          if (index == _draggedIndex) {
            // For the item being dragged, in-list placeholder is empty and proxy uses this tile.
            return _ReorderableRowWithDivider(
              key: child.key,
              tile: child,
              divider: GlassDivider(
                indent: widget.dividerIndent,
                endIndent: widget.dividerEndIndent,
              ),
              showDivider: false,
            );
          }

          final bool isAbove = index < _draggedIndex!;
          final bool isLastInSegment = isAbove
              ? index == _draggedIndex! - 1
              : index == widget.itemCount - 1;

          // Native cuts the card flat at the gap: only the real outer card
          // corners (top of the first row, bottom of the last) stay rounded.
          final bool roundTop = isAbove && index == 0;
          final bool roundBottom = !isAbove && index == widget.itemCount - 1;
          final BorderRadius borderRadius = BorderRadius.vertical(
            top: Radius.circular(roundTop ? 26 : 0),
            bottom: Radius.circular(roundBottom ? 26 : 0),
          );

          final bool showDivider = isAbove || !isLastInSegment;

          return _ReorderableRowWithDivider(
            key: child.key,
            tile: child,
            divider: GlassDivider(
              indent: widget.dividerIndent,
              endIndent: widget.dividerEndIndent,
            ),
            decoration: BoxDecoration(
              color: resolveGlassSolidSurfaceColor(context),
              borderRadius: borderRadius,
            ),
            borderRadius: borderRadius,
            showDivider: showDivider,
          );
        }

        if (index == widget.itemCount - 1) {
          return _ReorderableRowWithDivider(
            key: child.key,
            tile: child,
            divider: GlassDivider(
              indent: widget.dividerIndent,
              endIndent: widget.dividerEndIndent,
            ),
            showDivider: false,
          );
        }

        // Interleave a GlassDivider below item if grouped (omitted in drag proxy)
        return _ReorderableRowWithDivider(
          key: child.key,
          tile: child,
          divider: GlassDivider(
            indent: widget.dividerIndent,
            endIndent: widget.dividerEndIndent,
          ),
        );
      },
      // ignore: deprecated_member_use
      onReorder: (int oldIndex, int newIndex) {
        if (widget.onReorderItem != null) {
          final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
          widget.onReorderItem!(oldIndex, adjusted);
        } else {
          widget.onReorder!(oldIndex, newIndex);
        }
      },
      proxyDecorator: (child, index, animation) {
        Widget wrapped = child;
        if (editController != null) {
          wrapped = GlassEditScope(controller: editController, child: wrapped);
        }
        wrapped = InheritedGlassSurfaceStyle(
          surfaceStyle: surfaceStyle,
          child: wrapped,
        );
        wrapped = _InheritedReorderProxy(child: wrapped);
        return proxyDecorator(wrapped, index, animation);
      },
    );
  }
}

class _InheritedReorderProxy extends InheritedWidget {
  const _InheritedReorderProxy({required super.child});

  static bool isProxy(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedReorderProxy>() !=
      null;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _ReorderableRowWithDivider extends StatelessWidget {
  const _ReorderableRowWithDivider({
    super.key,
    required this.tile,
    required this.divider,
    this.decoration,
    this.borderRadius,
    this.showDivider = true,
  });

  final Widget tile;
  final Widget divider;
  final Decoration? decoration;
  final BorderRadius? borderRadius;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final bool isProxy = _InheritedReorderProxy.isProxy(context);
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [tile, if (!isProxy && showDivider) divider],
    );
    if (!isProxy && decoration != null) {
      content = Container(
        decoration: decoration,
        clipBehavior:
            (borderRadius != null && borderRadius != BorderRadius.zero)
            ? Clip.antiAlias
            : Clip.none,
        child: content,
      );
    }
    return content;
  }
}

/// Clips to everything *outside* the widget's bounds (even-odd), used to keep
/// a drop shadow from showing through a translucent surface.
class _OutsideRectClipper extends CustomClipper<Path> {
  const _OutsideRectClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTRB(-400, -400, size.width + 400, size.height + 400))
      ..addRect(Offset.zero & size);
  }

  @override
  bool shouldReclip(_OutsideRectClipper oldClipper) => false;
}
