import 'package:flutter/cupertino.dart';

/// An abstract interface for controllable swipe action rows.
///
/// Implemented by the state of [GlassSwipeActions] to allow coordination
/// by [GlassSwipeActionScope].
abstract class GlassSwipeActionsControllerInterface {
  /// Closes the swipe actions row with animation.
  void close({bool animated = true});
}

/// A scope that coordinates mutual exclusivity and automatic dismissal for
/// descendant swipe action rows.
///
/// When multiple swipeable rows are placed inside a scrollable list, wrapping
/// the list in a [GlassSwipeActionScope] ensures:
/// 1. Only one row can be open at a time — opening a second row automatically
///    springs any previously open row closed.
/// 2. Scrolling the list immediately closes any currently revealed swipe actions.
///
/// ## Usage
///
/// ```dart
/// GlassSwipeActionScope(
///   child: ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, index) => GlassListTile(
///       title: Text(items[index].title),
///       trailingSwipeActions: [
///         GlassSwipeAction(
///           icon: const Icon(CupertinoIcons.trash),
///           label: const Text('Delete'),
///           isDestructive: true,
///           onTap: () => deleteItem(index),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
class GlassSwipeActionScope extends StatefulWidget {
  /// Creates a scope for coordinating swipe actions.
  const GlassSwipeActionScope({
    super.key,
    required this.child,
    this.closeOnScroll = true,
  });

  /// The child subtree containing swipe action widgets.
  final Widget child;

  /// Whether scrolling in descendant scrollables should automatically close
  /// any open swipe action row.
  ///
  /// Defaults to `true`, matching native iOS behavior.
  final bool closeOnScroll;

  /// Retrieves the nearest [GlassSwipeActionScopeState] from the widget tree,
  /// or null if none is found.
  static GlassSwipeActionScopeState? of(BuildContext context) {
    return context.findAncestorStateOfType<GlassSwipeActionScopeState>();
  }

  /// Closes any currently open swipe row in the nearest [GlassSwipeActionScope].
  static void closeAll(BuildContext context) {
    of(context)?.closeOpenRow();
  }

  @override
  State<GlassSwipeActionScope> createState() => GlassSwipeActionScopeState();
}

/// State for [GlassSwipeActionScope].
class GlassSwipeActionScopeState extends State<GlassSwipeActionScope> {
  GlassSwipeActionsControllerInterface? _openRow;

  /// Closes the currently open swipe action row, if any.
  void closeOpenRow() {
    final row = _openRow;
    _openRow = null;
    row?.close();
  }

  /// Registers a row that has just opened or started dragging, closing any
  /// previously open row.
  void registerOpenRow(GlassSwipeActionsControllerInterface row) {
    if (_openRow != null && _openRow != row) {
      final prev = _openRow;
      _openRow = null;
      prev?.close();
    }
    _openRow = row;
  }

  /// Unregisters a row when it has settled back to closed.
  void unregisterRow(GlassSwipeActionsControllerInterface row) {
    if (_openRow == row) {
      _openRow = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    if (widget.closeOnScroll) {
      result = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (_openRow != null) {
            if (notification is ScrollStartNotification ||
                (notification is ScrollUpdateNotification &&
                    notification.scrollDelta != null &&
                    notification.scrollDelta!.abs() > 1.0)) {
              closeOpenRow();
            }
          }
          return false;
        },
        child: result,
      );
    }

    return _InheritedGlassSwipeActionScope(
      state: this,
      child: result,
    );
  }
}

class _InheritedGlassSwipeActionScope extends InheritedWidget {
  const _InheritedGlassSwipeActionScope({
    required this.state,
    required super.child,
  });

  final GlassSwipeActionScopeState state;

  @override
  bool updateShouldNotify(_InheritedGlassSwipeActionScope oldWidget) => false;
}
