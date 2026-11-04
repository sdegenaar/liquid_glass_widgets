import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
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

/// iOS 26/27 system red (`#FF383C`) used by edit-mode delete controls.
const Color _kEditRedLight = Color(0xFFFF383C);

/// Dark-appearance system red (`#FF4245`).
const Color _kEditRedDark = Color(0xFFFF4245);

/// Distance (pt) the row slides left to reveal the delete cell, matching
/// native iOS.
const double _kDeleteShift = 80.0;

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
    this.swipeActionWidth,
    this.swipeActionButtonDiameter,
    this.swipeActionButtonSpacing,
    this.swipeActionHorizontalPadding,
    this.swipeController,
    this.onSwipeStateChanged,
    this.swipeActionStyle,
    this.onDismissed,
    this.contextMenuActions,
    this.contextMenuPreviewBuilder,
    this.onContextMenuDismissed,
    this.contextMenuLongPressDuration,
    this.contextMenuQuality,
    this.contextMenuSettings,
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
    this.swipeActionWidth,
    this.swipeActionButtonDiameter,
    this.swipeActionButtonSpacing,
    this.swipeActionHorizontalPadding,
    this.swipeController,
    this.onSwipeStateChanged,
    this.swipeActionStyle,
    this.onDismissed,
    this.contextMenuActions,
    this.contextMenuPreviewBuilder,
    this.onContextMenuDismissed,
    this.contextMenuLongPressDuration,
    this.contextMenuQuality,
    this.contextMenuSettings,
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
  /// Defaults to null, which uses authentic iOS 26/27 circular action button geometry
  /// ([swipeActionButtonDiameter] + [swipeActionButtonSpacing] + insets).
  final double? swipeActionWidth;

  /// Optional diameter for circular swipe action buttons.
  ///
  /// Defaults to null, which resolves to `50.0` logical pixels in [GlassSwipeActions].
  final double? swipeActionButtonDiameter;

  /// Optional spacing between adjacent swipe action buttons.
  ///
  /// Defaults to null, which resolves to `12.0` logical pixels in [GlassSwipeActions].
  final double? swipeActionButtonSpacing;

  /// Optional horizontal padding around swipe action buttons.
  ///
  /// Defaults to null, which resolves to `12.0` logical pixels in [GlassSwipeActions].
  final double? swipeActionHorizontalPadding;

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

  /// Optional glass quality override for the context menu action platter.
  ///
  /// Defaults to [GlassQuality.premium] when supported by the device.
  final GlassQuality? contextMenuQuality;

  /// Optional liquid glass shader settings for the context menu action platter.
  final LiquidGlassSettings? contextMenuSettings;

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
    with GlassInteractionStateMixin, TickerProviderStateMixin {
  // Interaction state (isPressed, isFocused, pressedAndFocused)
  // is provided by GlassInteractionStateMixin.

  late final AnimationController _confirmController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _confirmAnimation = CurvedAnimation(
    parent: _confirmController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final AnimationController _removeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _removeAnimation = CurvedAnimation(
    parent: _removeController,
    curve: Curves.easeInOutCubic,
  );

  bool _isDeleteConfirming = false;

  /// Pointer that went down on the grabber, so the row-wide hold listener
  /// doesn't start a second drag for the same touch.
  int? _grabberPointer;

  @override
  void initState() {
    super.initState();
    _confirmController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant GlassListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final effectiveIsEditing =
        widget.isEditing ?? GlassEditScope.isEditing(context);
    if (!effectiveIsEditing && _isDeleteConfirming) {
      _isDeleteConfirming = false;
      _confirmController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _removeController.dispose();
    super.dispose();
  }

  void _handleDeletePressed() {
    HapticFeedback.mediumImpact();
    _removeController.forward().then((_) {
      if (mounted) {
        widget.onDelete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIsEditing =
        widget.isEditing ?? GlassEditScope.isEditing(context);

    if (!effectiveIsEditing && _isDeleteConfirming) {
      _isDeleteConfirming = false;
      _confirmController.value = 0.0;
    }

    Widget content = _buildContent(context, effectiveIsEditing);

    // Context menu wraps the tile's content (not the swipe action platter),
    // matching SwiftUI's `.contextMenu { ... }.swipeActions { ... }`.
    // This ensures long-pressing the row compresses only the cell content,
    // keeping the swipe action platter flush with the card boundary.
    if (widget.contextMenuActions != null &&
        widget.contextMenuActions!.isNotEmpty) {
      final bool inSolidSection = InheritedGlassSurfaceStyle.maybeOf(context) ==
          GlassSurfaceStyle.solid;
      final bool isDarkTile =
          GlassTheme.brightnessOf(context) == Brightness.dark;
      content = GlassContextMenu(
        actions: widget.contextMenuActions!,
        previewBuilder: widget.contextMenuPreviewBuilder,
        rowBorderRadius: 16.0,
        rowCorners: InheritedGlassSectionRow.maybeOf(context),
        // Native iOS leaves the pressed cell's slot empty, showing the page
        // background (`systemGroupedBackground`) through it.
        originSlotColor: inSolidSection
            ? (isDarkTile ? const Color(0xFF000000) : const Color(0xFFF2F2F7))
            : null,
        quality: widget.contextMenuQuality,
        settings: widget.contextMenuSettings,
        onDismissed: widget.onContextMenuDismissed,
        longPressDuration: widget.contextMenuLongPressDuration ??
            const Duration(milliseconds: 700),
        child: content,
      );
    }

    if (widget._useOwnLayer) {
      content = GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 12),
        settings: widget._settings,
        quality: widget._quality,
        useOwnLayer: widget._settings != null,
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
        buttonDiameter: widget.swipeActionButtonDiameter ?? 50.0,
        buttonSpacing: widget.swipeActionButtonSpacing ?? 12.0,
        horizontalPadding: widget.swipeActionHorizontalPadding ?? 12.0,
        controller: widget.swipeController,
        onSwipeStateChanged: widget.onSwipeStateChanged,
        style: effectiveStyle,
        onDismissed: widget.onDismissed ?? widget.onDelete,
        borderRadius: widget._useOwnLayer
            ? const BorderRadius.all(Radius.circular(12))
            : null,
        child: content,
      );
    }

    if (_removeController.isAnimating || _removeController.isCompleted) {
      content = AnimatedBuilder(
        animation: _removeAnimation,
        builder: (context, child) {
          final double progress = _removeAnimation.value;
          return ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: (1.0 - progress).clamp(0.0, 1.0),
              child: Opacity(
                opacity: (1.0 - progress).clamp(0.0, 1.0),
                child: child,
              ),
            ),
          );
        },
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

    final bool isDarkEdit = GlassTheme.brightnessOf(context) == Brightness.dark;
    final Color editRed = isDarkEdit ? _kEditRedDark : _kEditRedLight;

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
              if (_isDeleteConfirming) {
                _confirmController.forward();
              } else {
                _confirmController.reverse();
              }
            });
          },
          child: Container(
            width: 39,
            height: 36,
            alignment: Alignment.centerLeft,
            child: Icon(
              CupertinoIcons.minus_circle_fill,
              color: editRed,
              size: 25,
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
            width: 39,
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
            width: 39,
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
      if (widget.canReorder) {
        Widget handle = Container(
          width: 48,
          height: 44,
          alignment: Alignment.centerRight,
          color: const Color(0x00000000),
          // Native 3-bar grabber: 21pt wide, 1.33pt bars on a 4.67pt pitch,
          // right edge 17.3pt in from the card edge.
          child: CustomPaint(
            size: const Size(22.3, 10),
            painter: _ReorderGrabberPainter(
              color: isDarkEdit
                  ? const Color(0x998E8E93)
                  : const Color(0xA0A3A3A7),
            ),
          ),
        );
        if (widget.reorderIndex != null) {
          handle = Listener(
            onPointerDown: (event) => _grabberPointer = event.pointer,
            child: _InstantReorderDragStartListener(
              index: widget.reorderIndex!,
              child: handle,
            ),
          );
        }
        trailingAccessory = handle;
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
              constraints: const BoxConstraints(minWidth: 28),
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

    final bool showSelectedHighlight =
        isEditing && widget.canSelect && widget.isSelected;
    final Color selectedHighlight =
        isDarkEdit ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6);

    if (effectiveCanDelete && isEditing) {
      final Color platterColor = showSelectedHighlight
          ? selectedHighlight
          : (isDarkEdit ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA));
      final Color pageColor =
          isDarkEdit ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
      final Color labelColor =
          isDarkEdit ? const Color(0x99EBEBF5) : const Color(0x993C3C43);

      // Native iOS: a 60x48 red button with an outline trash glyph and the
      // "Delete" caption *underneath* it, sitting in the vacated strip.
      final deleteCell = Semantics(
        button: true,
        label: 'Delete',
        excludeSemantics: true,
        onTap: _handleDeletePressed,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleDeletePressed,
          child: Padding(
            padding: const EdgeInsets.only(top: 4.3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: editRed,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      tile = AnimatedBuilder(
        animation: _confirmAnimation,
        builder: (context, child) {
          final double t = _confirmAnimation.value;
          if (t <= 0.0 && !_isDeleteConfirming) {
            return child!;
          }

          return ClipRect(
            child: Stack(
              children: [
                // 1. Platter (the row's own grey background) plus the
                //    page-colour strip it leaves behind as it slides left.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DeletePlatterPainter(
                      platterColor: platterColor,
                      pageColor: pageColor,
                      progress: t,
                    ),
                  ),
                ),
                // 2. Main content translated left
                Transform.translate(
                  offset: Offset(-_kDeleteShift * t, 0.0),
                  child: child,
                ),
                // 3. Delete cell sliding in from the right with the content
                Positioned(
                  right: 0.0,
                  top: 0.0,
                  bottom: 0.0,
                  width: _kDeleteShift,
                  child: Transform.translate(
                    offset: Offset((1.0 - t) * _kDeleteShift, 0.0),
                    child: deleteCell,
                  ),
                ),
              ],
            ),
          );
        },
        child: tile,
      );
    }

    if (showSelectedHighlight) {
      tile = ColoredBox(color: selectedHighlight, child: tile);
    }

    // Native rows toggle selection when tapped in edit mode; while the
    // delete confirmation is showing, a tap on the row dismisses it instead.
    if (_isDeleteConfirming) {
      tile = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            _isDeleteConfirming = false;
            _confirmController.reverse();
          });
        },
        child: tile,
      );
    } else if (isEditing && widget.canSelect) {
      tile = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onSelectedChanged?.call(!widget.isSelected);
        },
        child: tile,
      );
    }

    // Press-and-hold anywhere on the row lifts it for reordering. The grabber
    // itself lifts instantly (handled by its own listener), so touches that
    // started there are skipped.
    if (isEditing &&
        widget.canReorder &&
        widget.reorderIndex != null &&
        !_isDeleteConfirming) {
      tile = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (_grabberPointer == event.pointer) return;
          SliverReorderableList.maybeOf(context)?.startItemDragReorder(
            index: widget.reorderIndex!,
            event: event,
            recognizer: DelayedMultiDragGestureRecognizer(debugOwner: this)
              ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context),
          );
        },
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

/// Paints the native 3-bar reorder grabber (21pt wide, 1.33pt bars, 4.67pt
/// pitch). The bars are left-aligned in the painted box so the box's extra
/// width becomes the native right inset.
class _ReorderGrabberPainter extends CustomPainter {
  const _ReorderGrabberPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double barWidth = 21.0;
    const double barThickness = 4.0 / 3.0;
    const double pitch = 14.0 / 3.0;
    final paint = Paint()..color = color;
    final double top = (size.height - (2 * pitch + barThickness)) / 2;
    for (var i = 0; i < 3; i++) {
      final double y = top + i * pitch;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, barWidth, barThickness),
          const Radius.circular(barThickness / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ReorderGrabberPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Paints the grey platter that follows a row sliding left to reveal the
/// delete cell, plus the page-coloured strip it leaves behind (native iOS
/// shows the page background there, not the card).
class _DeletePlatterPainter extends CustomPainter {
  const _DeletePlatterPainter({
    required this.platterColor,
    required this.pageColor,
    required this.progress,
  });

  final Color platterColor;
  final Color pageColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double right = size.width - _kDeleteShift * progress;

    // Vacated strip.
    canvas.drawRect(
      Rect.fromLTRB(right, 0, size.width, size.height),
      Paint()..color = pageColor,
    );

    final double radius = (size.height / 2) < 28.0 ? (size.height / 2) : 28.0;
    final rect = Rect.fromLTRB(0, 0, right, size.height);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );

    // Page colour in the corner voids so the platter ends look cut out.
    final voids = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(
      voids,
      Paint()..color = pageColor.withValues(alpha: progress),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = platterColor.withValues(alpha: progress),
    );
  }

  @override
  bool shouldRepaint(_DeletePlatterPainter oldDelegate) =>
      oldDelegate.platterColor != platterColor ||
      oldDelegate.pageColor != pageColor ||
      oldDelegate.progress != progress;
}

/// Reorder grabber listener that lifts the row the instant it is touched.
///
/// Flutter's [ReorderableDragStartListener] only starts the drag once the
/// pointer has moved past the touch slop, so the row stays put under a
/// stationary finger. Native iOS lifts the row as soon as the grabber is
/// pressed (before any movement), which this reproduces.
class _InstantReorderDragStartListener extends ReorderableDragStartListener {
  const _InstantReorderDragStartListener({
    required super.index,
    required super.child,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return _InstantMultiDragGestureRecognizer(debugOwner: this);
  }
}

/// Multi-drag recognizer that claims the gesture arena on pointer-down.
class _InstantMultiDragGestureRecognizer extends MultiDragGestureRecognizer {
  _InstantMultiDragGestureRecognizer({super.debugOwner});

  _InstantPointerState? _lastState;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _lastState?.acceptNow();
  }

  @override
  MultiDragPointerState createNewPointerState(PointerDownEvent event) {
    return _lastState = _InstantPointerState(
      event.position,
      event.kind,
      gestureSettings,
    );
  }

  @override
  String get debugDescription => 'instant multidrag';
}

class _InstantPointerState extends MultiDragPointerState {
  _InstantPointerState(
      super.initialPosition, super.kind, super.gestureSettings);

  void acceptNow() => resolve(GestureDisposition.accepted);

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    starter(initialPosition);
  }
}
