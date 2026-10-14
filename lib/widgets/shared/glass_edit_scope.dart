import 'package:flutter/cupertino.dart';

/// The editing state of a list or form, providing parity with SwiftUI's `EditMode`.
enum GlassEditMode {
  /// The view is in its normal, non-editable state.
  inactive,

  /// The view is in edit mode with deletion badges and reorder drag handles active.
  active,

  /// The view is temporarily transitioning between modes.
  transient;

  /// Whether edit mode is currently active.
  bool get isEditing => this == GlassEditMode.active;
}

/// A controller managing [GlassEditMode] transitions across a widget tree.
class GlassEditController extends ChangeNotifier {
  /// Creates a controller with the given initial edit mode.
  GlassEditController({GlassEditMode initialMode = GlassEditMode.inactive})
      : _mode = initialMode;

  GlassEditMode _mode;

  /// The current edit mode.
  GlassEditMode get mode => _mode;

  /// Whether edit mode is currently active.
  bool get isEditing => _mode.isEditing;

  /// Updates the current edit mode and notifies listeners if changed.
  set mode(GlassEditMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }

  /// Toggles between [GlassEditMode.inactive] and [GlassEditMode.active].
  void toggle() {
    mode = isEditing ? GlassEditMode.inactive : GlassEditMode.active;
  }

  /// Activates edit mode.
  void startEditing() {
    mode = GlassEditMode.active;
  }

  /// Exits edit mode.
  void stopEditing() {
    mode = GlassEditMode.inactive;
  }
}

/// An ambient scope providing [GlassEditMode] to descendant widgets,
/// directly matching SwiftUI's `@Environment(\.editMode)` environment key.
///
/// Descendants like [GlassListTile], [GlassEditButton], and [GlassReorderableList]
/// automatically adapt their layout and controls based on this scope.
///
/// ## Usage
///
/// ```dart
/// GlassEditScope(
///   child: Column(
///     children: [
///       const GlassAppBar.pinned(
///         actions: [
///           GlassEditButton(),
///         ],
///       ),
///       GlassListTile(
///         title: const Text('John Appleseed'),
///         onDelete: () => removeItem(),
///         canReorder: true,
///       ),
///     ],
///   ),
/// )
/// ```
class GlassEditScope extends StatefulWidget {
  /// Creates a [GlassEditScope] with its own internal controller or a provided [controller].
  const GlassEditScope({
    super.key,
    required this.child,
    this.controller,
    this.initialMode = GlassEditMode.inactive,
    this.onModeChanged,
  });

  /// The child subtree with ambient access to edit mode.
  final Widget child;

  /// Optional external controller for managing the edit mode.
  final GlassEditController? controller;

  /// The initial edit mode when [controller] is not provided.
  final GlassEditMode initialMode;

  /// Callback fired whenever the edit mode changes.
  final ValueChanged<GlassEditMode>? onModeChanged;

  /// Returns the nearest [GlassEditController] in the widget tree, or throws if none is found.
  static GlassEditController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'No GlassEditScope found in the given BuildContext. '
      'Wrap your widget tree with a GlassEditScope.',
    );
    return controller!;
  }

  /// Returns the nearest [GlassEditController] in the widget tree, or null if none is found.
  static GlassEditController? maybeOf(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedGlassEditScope>();
    return inherited?.controller;
  }

  /// Convenience helper to check if edit mode is currently active.
  static bool isEditing(BuildContext context) {
    return maybeOf(context)?.isEditing ?? false;
  }

  @override
  State<GlassEditScope> createState() => _GlassEditScopeState();
}

class _GlassEditScopeState extends State<GlassEditScope> {
  late GlassEditController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        GlassEditController(initialMode: widget.initialMode);
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant GlassEditScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      _controller = widget.controller ??
          GlassEditController(initialMode: widget.initialMode);
      _controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    widget.onModeChanged?.call(_controller.mode);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return _InheritedGlassEditScope(
          controller: _controller,
          mode: _controller.mode,
          child: widget.child,
        );
      },
    );
  }
}

class _InheritedGlassEditScope extends InheritedWidget {
  const _InheritedGlassEditScope({
    required this.controller,
    required this.mode,
    required super.child,
  });

  final GlassEditController controller;
  final GlassEditMode mode;

  @override
  bool updateShouldNotify(covariant _InheritedGlassEditScope oldWidget) {
    return mode != oldWidget.mode || controller != oldWidget.controller;
  }
}
