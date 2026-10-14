import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../theme/glass_theme.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import 'glass_container.dart';
import 'glass_swipe_actions.dart';
import '../overlays/glass_context_menu.dart';
import '../shared/glass_edit_scope.dart';
import '../shared/glass_focus_region.dart';
import '../shared/glass_interaction_state_mixin.dart';
import '../shared/glass_solid_surface.dart';

/// A glass-aesthetic list tile following iOS 26 grouped row design.
///
/// [GlassListTile] is the glass design system's equivalent of Flutter's
/// [ListTile] — a clean, stateless item with no knowledge of its position.
///
/// Divider rendering is the responsibility of the parent container:
/// [GlassGroupedSection] automatically injects [GlassDivider]s between tiles.
/// For standalone column layouts, compose [GlassDivider] explicitly, as you
/// would with Flutter's built-in [ListTile] + [Divider] pattern.
///
/// ## Usage inside [GlassGroupedSection] (recommended):
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
///   ],
/// )
/// ```
///
/// ## Standalone tile (own glass layer):
///
/// ```dart
/// GlassListTile.standalone(
///   leading: Icon(CupertinoIcons.star_fill, color: Colors.yellow),
///   title: Text('Featured'),
///   onTap: () { },
/// )
/// ```
class GlassListTile extends StatefulWidget {
  /// Creates a glass list tile for use inside a [GlassContainer.card],
  /// [GlassGroupedSection], or other glass container.
  /// Does not create its own glass layer.
  const GlassListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.leadingIconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.leadingSwipeActions,
    this.trailingSwipeActions,
    this.allowsFullSwipe = true,
    this.fullSwipeThreshold = 0.65,
    this.swipeActionWidth = 74.0,
    this.swipeController,
    this.onSwipeStateChanged,
    this.swipeActionStyle,
    this.onDismissed,
    this.contextMenuActions,
    this.contextMenuPreviewBuilder,
    this.onContextMenuDismissed,
    this.contextMenuLongPressDuration,
    this.isEditing,
    this.canDelete = false,
    this.onDelete,
    this.canInsert = false,
    this.onInsert,
    this.canReorder = false,
    this.reorderIndex,
    this.canSelect = false,
    this.isSelected = false,
    this.onSelectedChanged,
  })  : _useOwnLayer = false,
        _settings = null,
        _quality = null;

  /// Creates a standalone glass list tile that manages its own glass layer.
  ///
  /// Use when the tile is not inside a [GlassContainer.card] or [GlassContainer].
  const GlassListTile.standalone({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.leadingIconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.leadingSwipeActions,
    this.trailingSwipeActions,
    this.allowsFullSwipe = true,
    this.fullSwipeThreshold = 0.65,
    this.swipeActionWidth = 74.0,
    this.swipeController,
    this.onSwipeStateChanged,
    this.swipeActionStyle,
    this.onDismissed,
    this.contextMenuActions,
    this.contextMenuPreviewBuilder,
    this.onContextMenuDismissed,
    this.contextMenuLongPressDuration,
    this.isEditing,
    this.canDelete = false,
    this.onDelete,
    this.canInsert = false,
    this.onInsert,
    this.canReorder = false,
    this.reorderIndex,
    this.canSelect = false,
    this.isSelected = false,
    this.onSelectedChanged,
    LiquidGlassSettings? settings,
    GlassQuality? quality,
  })  : _useOwnLayer = true,
        _settings = settings,
        _quality = quality;

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// Widget displayed at the start (left) of the tile.
  ///
  /// Typically an [Icon] or [CircleAvatar]. Constrained to 24×24 by default.
  final Widget? leading;

  /// Primary content. Typically a [Text] widget.
  final Widget title;

  /// Optional secondary content displayed under [title].
  final Widget? subtitle;

  /// Widget displayed at the end (right) of the tile.
  ///
  /// Use [GlassListTile.chevron] for iOS-style navigation disclosure arrows.
  final Widget? trailing;

  // ===========================================================================
  // Interaction Properties
  // ===========================================================================

  /// Called when the user taps the tile.
  final VoidCallback? onTap;

  /// Called when the user long-presses the tile.
  final VoidCallback? onLongPress;

  // ===========================================================================
  // Swipe Actions Properties
  // ===========================================================================

  /// Actions revealed when swiping from the leading edge (left in LTR).
  final List<GlassSwipeAction>? leadingSwipeActions;

  /// Actions revealed when swiping from the trailing edge (right in LTR).
  final List<GlassSwipeAction>? trailingSwipeActions;

  /// Whether pulling past [fullSwipeThreshold] automatically executes the
  /// outermost action on release.
  ///
  /// Defaults to `true`.
  final bool allowsFullSwipe;

  /// Proportion of tile width required to prime full-swipe execution.
  ///
  /// Defaults to `0.65` (65%).
  final double fullSwipeThreshold;

  /// Base width allocated for each swipe action button.
  ///
  /// Defaults to `74.0`.
  final double swipeActionWidth;

  /// Optional external controller for inspecting or triggering swipe actions.
  final GlassSwipeController? swipeController;

  /// Callback fired when the swipe state changes.
  final ValueChanged<GlassSwipeState>? onSwipeStateChanged;

  /// Visual styling applied to the swipe action platter.
  ///
  /// If null, defaults to [GlassSwipeActionStyle.solidVibrancy] when placed
  /// inside a solid surface container (e.g. [GlassGroupedSection] with
  /// [GlassSurfaceStyle.solid]), or [GlassSwipeActionStyle.tintedGlass] otherwise.
  final GlassSwipeActionStyle? swipeActionStyle;

  /// Optional callback executed when the row is dismissed via full swipe.
  final VoidCallback? onDismissed;

  /// Optional context menu actions attached to this tile's content.
  ///
  /// When provided, the tile content (excluding swipe platters) is wrapped in
  /// a [GlassContextMenu], mirroring SwiftUI's `.contextMenu { ... }.swipeActions { ... }`
  /// composition. This ensures the swipe action platter is never compressed or
  /// distorted when long-pressing the row.
  final List<Widget>? contextMenuActions;

  /// Optional custom preview widget builder displayed above the context menu.
  final Widget Function(BuildContext context)? contextMenuPreviewBuilder;

  /// Optional callback invoked when the context menu is dismissed.
  final VoidCallback? onContextMenuDismissed;

  /// Duration the user must press before the context menu activates.
  final Duration? contextMenuLongPressDuration;

  // ===========================================================================
  // Edit Mode Properties
  // ===========================================================================

  /// Whether edit mode is explicitly enabled for this tile.
  ///
  /// If null, the tile queries the ambient [GlassEditScope.isEditing(context)].
  final bool? isEditing;

  /// Whether this tile can be deleted in edit mode.
  ///
  /// If true or if [onDelete] is non-null, a circular red minus button is
  /// displayed at the leading edge.
  final bool canDelete;

  /// Callback executed when the deletion badge or delete button is confirmed.
  final VoidCallback? onDelete;

  /// Whether this tile acts as an insertion row in edit mode (e.g. "Add Phone").
  final bool canInsert;

  /// Callback executed when the green plus insertion button is tapped.
  final VoidCallback? onInsert;

  /// Whether this tile can be reordered in edit mode.
  ///
  /// If true, a 3-bar reorder handle is displayed at the trailing edge.
  final bool canReorder;

  /// Index of this item when nested in a [ReorderableList] or [GlassReorderableList].
  final int? reorderIndex;

  /// Whether this tile can be selected via a circular checkbox in edit mode.
  final bool canSelect;

  /// Whether this tile is currently selected in selection mode.
  final bool isSelected;

  /// Callback fired when the selection state changes.
  final ValueChanged<bool>? onSelectedChanged;

  // ===========================================================================
  // Styling Properties
  // ===========================================================================

  /// Padding inside the tile around the content row.
  ///
  /// Defaults to 16px horizontal, 12px vertical — matching iOS table row insets.
  final EdgeInsetsGeometry contentPadding;

  /// Tint applied to [leading] icon colour.
  ///
  /// If null, the icon uses its own colour or the theme's icon colour.
  final Color? leadingIconColor;

  /// Text style for [title].
  ///
  /// Defaults to white bold text matching glass surfaces.
  final TextStyle? titleStyle;

  /// Text style for [subtitle].
  ///
  /// Defaults to white with reduced opacity.
  final TextStyle? subtitleStyle;

  // ===========================================================================
  // Glass Layer Properties (standalone only)
  // ===========================================================================

  final bool _useOwnLayer;
  final LiquidGlassSettings? _settings;
  final GlassQuality? _quality;

  // ===========================================================================
  // Convenience Constants
  // ===========================================================================

  /// A standard iOS-style disclosure chevron for use as [trailing].
  static Widget get chevron => const Icon(
        CupertinoIcons.chevron_forward,
        color: CupertinoColors.systemGrey,
        size: 20,
      );

  /// A standard iOS-style detail disclosure (circle with 'i') for [trailing].
  static Widget get infoButton => const Icon(
        CupertinoIcons.info,
        color: CupertinoColors.systemGrey,
        size: 20,
      );

  @override
  State<GlassListTile> createState() => _GlassListTileState();
}

class _GlassListTileState extends State<GlassListTile>
    with GlassInteractionStateMixin {
  // Interaction state (isPressed, isFocused, pressedAndFocused)
  // is provided by GlassInteractionStateMixin.

  bool _isDeleteConfirming = false;

  @override
  Widget build(BuildContext context) {
    final effectiveIsEditing =
        widget.isEditing ?? GlassEditScope.isEditing(context);

    if (!effectiveIsEditing && _isDeleteConfirming) {
      _isDeleteConfirming = false;
    }

    Widget content = _buildContent(context, effectiveIsEditing);

    // Context menu wraps the tile's content (not the swipe action platter),
    // matching SwiftUI's `.contextMenu { ... }.swipeActions { ... }`.
    // This ensures long-pressing the row compresses only the cell content,
    // keeping the swipe action platter flush with the card boundary.
    if (widget.contextMenuActions != null &&
        widget.contextMenuActions!.isNotEmpty) {
      content = GlassContextMenu(
        actions: widget.contextMenuActions!,
        previewBuilder: widget.contextMenuPreviewBuilder,
        onDismissed: widget.onContextMenuDismissed,
        longPressDuration: widget.contextMenuLongPressDuration ??
            const Duration(milliseconds: 300),
        child: content,
      );
    }

    if (widget._useOwnLayer) {
      content = GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 12),
        settings: widget._settings,
        quality: widget._quality,
        padding: EdgeInsets.zero,
        child: content,
      );
    }

    final hasSwipeActions = !effectiveIsEditing &&
        ((widget.leadingSwipeActions != null &&
                widget.leadingSwipeActions!.isNotEmpty) ||
            (widget.trailingSwipeActions != null &&
                widget.trailingSwipeActions!.isNotEmpty));

    if (hasSwipeActions) {
      final effectiveStyle = widget.swipeActionStyle ??
          (InheritedGlassSurfaceStyle.maybeOf(context) ==
                  GlassSurfaceStyle.solid
              ? GlassSwipeActionStyle.solidVibrancy
              : GlassSwipeActionStyle.tintedGlass);

      content = GlassSwipeActions(
        leadingActions: widget.leadingSwipeActions ?? const [],
        trailingActions: widget.trailingSwipeActions ?? const [],
        allowsFullSwipe: widget.allowsFullSwipe,
        fullSwipeThreshold: widget.fullSwipeThreshold,
        actionWidth: widget.swipeActionWidth,
        controller: widget.swipeController,
        onSwipeStateChanged: widget.onSwipeStateChanged,
        style: effectiveStyle,
        onDismissed: widget.onDismissed,
        borderRadius: widget._useOwnLayer
            ? const BorderRadius.all(Radius.circular(12))
            : null,
        child: content,
      );
    }

    return content;
  }

  Widget _buildContent(BuildContext context, bool isEditing) {
    final dynamicLabelColor =
        CupertinoTheme.of(context).textTheme.textStyle.color ??
            CupertinoColors.label;

    final effectiveTitleStyle = widget.titleStyle ??
        TextStyle(
          color: dynamicLabelColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );
    final effectiveSubtitleStyle = widget.subtitleStyle ??
        TextStyle(
          color: dynamicLabelColor.withValues(alpha: 0.65),
          fontSize: 13,
        );

    Widget? leadingAccessory;
    final effectiveCanDelete = widget.canDelete || widget.onDelete != null;
    final effectiveCanInsert = widget.canInsert || widget.onInsert != null;

    Widget? editBadge;
    Widget? selectionAccessory;
    if (isEditing) {
      if (effectiveCanDelete) {
        editBadge = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _isDeleteConfirming = !_isDeleteConfirming;
            });
          },
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.centerLeft,
            child: AnimatedRotation(
              turns: _isDeleteConfirming ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: const Icon(
                CupertinoIcons.minus_circle_fill,
                color: CupertinoColors.systemRed,
                size: 25,
              ),
            ),
          ),
        );
      } else if (effectiveCanInsert) {
        editBadge = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onInsert?.call();
          },
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.centerLeft,
            child: const Icon(
              CupertinoIcons.plus_circle_fill,
              color: CupertinoColors.systemGreen,
              size: 25,
            ),
          ),
        );
      }
      // Native SwiftUI shows the selection circle *alongside* the delete /
      // insert badge when a List has both `onDelete` and a selection binding.
      if (widget.canSelect) {
        selectionAccessory = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onSelectedChanged?.call(!widget.isSelected);
          },
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.centerLeft,
            child: Icon(
              widget.isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: widget.isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey3,
              size: 25,
            ),
          ),
        );
      }
      if (editBadge != null && selectionAccessory != null) {
        leadingAccessory = Row(
          mainAxisSize: MainAxisSize.min,
          children: [editBadge, selectionAccessory],
        );
      } else {
        leadingAccessory = editBadge ?? selectionAccessory;
      }
    }

    Widget? trailingAccessory;
    if (isEditing) {
      if (_isDeleteConfirming) {
        trailingAccessory = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            CupertinoButton(
              color: CupertinoColors.systemRed,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              borderRadius: BorderRadius.circular(6),
              onPressed: () {
                setState(() => _isDeleteConfirming = false);
                widget.onDelete?.call();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      } else if (widget.canReorder) {
        Widget handle = Container(
          width: 32,
          height: 32,
          alignment: Alignment.centerRight,
          child: const Icon(
            CupertinoIcons.bars,
            color: CupertinoColors.systemGrey3,
            size: 20,
          ),
        );
        if (widget.reorderIndex != null) {
          handle = ReorderableDragStartListener(
            index: widget.reorderIndex!,
            child: handle,
          );
        }
        trailingAccessory = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            handle,
          ],
        );
      }
    } else if (widget.trailing != null) {
      trailingAccessory = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(
              color: dynamicLabelColor.withValues(alpha: 0.54),
              size: 20,
            ),
            child: widget.trailing!,
          ),
        ],
      );
    }

    Widget row = Row(
      children: [
        if (leadingAccessory != null) leadingAccessory,
        if (widget.leading != null) ...[
          IconTheme(
            data: IconThemeData(
              color: widget.leadingIconColor ?? dynamicLabelColor,
              size: 22,
            ),
            // A minimum (not fixed) width so a larger leading widget, such as
            // a 44pt avatar, keeps its natural size.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 32),
              child: widget.leading,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle(style: effectiveTitleStyle, child: widget.title),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: effectiveSubtitleStyle,
                  child: widget.subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (trailingAccessory != null) trailingAccessory,
      ],
    );

    Widget tile = Padding(padding: widget.contentPadding, child: row);

    if (_isDeleteConfirming) {
      tile = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _isDeleteConfirming = false),
        child: tile,
      );
    }

    if (widget.onTap != null || widget.onLongPress != null) {
      tile = GlassFocusRegion(
        enabled: true,
        // No shape → background highlight pattern for list rows, not outset ring.
        isFocusedNotifier: isFocused,
        semanticLabel: null, // title widget provides its own text semantics
        isButton: true,
        onKeyboardActivate: widget.onTap,
        semanticOnTap: widget.onTap,
        semanticOnLongPress: widget.onLongPress,
        // Role, tap and long press all live on the region's node. A button
        // Semantics or detector semantics in here would conflict with it and
        // split the tile into two nodes, one of them unlabelled (#381).
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: (_) => isPressed.value = true,
          onTapUp: (_) => isPressed.value = false,
          onTapCancel: () => isPressed.value = false,
          behavior: HitTestBehavior.opaque,
          child: ListenableBuilder(
            listenable: pressedAndFocused,
            builder: (context, child) {
              final bool showHighlight = isPressed.value || isFocused.value;
              return AnimatedContainer(
                duration: isPressed.value
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                color: showHighlight
                    ? (GlassTheme.brightnessOf(context) == Brightness.light
                        ? CupertinoColors.black.withValues(alpha: 0.08)
                        : CupertinoColors.white.withValues(alpha: 0.08))
                    : const Color(0x00000000),
                child: child,
              );
            },
            child: tile,
          ),
        ),
      );
    }

    return tile;
  }
}
