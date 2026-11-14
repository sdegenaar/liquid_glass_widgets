// Keeps a modal OverlayPortal overlay in the semantics tree while its barrier
// blocks the page behind it. Shared by GlassMenu and GlassPopover; internal,
// not exported from liquid_glass_widgets.dart.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// When [enabled] is true, emits an [OverlayPortal] overlay child's semantics
/// as sibling nodes in the [Overlay] rather than as traversal children of the
/// [OverlayPortal.child].
///
/// [OverlayPortal] grafts its overlay child's semantics onto a
/// `traversalParentIdentifier` node wrapping [OverlayPortal.child], which sits
/// in the page. The overlay's nodes drop out of the semantics tree whenever
/// that node does: when the open overlay's barrier applies [BlockSemantics] to
/// hide the page behind it, the page's [OverlayEntry], including that node, is
/// blocked; and with no [OverlayPortal.child] the node is 0x0. Marking the
/// overlay's child configurations as a sibling merge group attaches them
/// directly to the [Overlay] without `traversalChildIdentifier`, while
/// [BlockSemantics] still propagates up through the deferred layout box to
/// block the page behind it.
///
/// Wrap the overlay child in a non-boundary `Semantics(textDirection: ...)`
/// and put this host around that. The wrapper is load-bearing: it gives the
/// delegate a mergeable config to put in the sibling merge group, since the
/// barrier and the overlay's panel are semantic boundaries whose own
/// `configToMergeUp` is null.
///
/// Gated by [enabled] on the render object rather than by conditionally
/// wrapping the widget, so toggling it does not rebuild the overlay subtree.
/// Pass `false` when the overlay has no blocking barrier and its trigger is
/// the [OverlayPortal.child]: the overlay then stays in its normal traversal
/// position next to the trigger.
class OverlaySemanticsHost extends SingleChildRenderObjectWidget {
  /// Creates a host for an [OverlayPortal] overlay child's semantics.
  const OverlaySemanticsHost({
    super.key,
    this.enabled = true,
    required super.child,
  });

  /// Whether the overlay's semantics attach to the [Overlay] as siblings.
  ///
  /// Leave it `true` for an overlay whose barrier always blocks the page
  /// while it is up.
  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderOverlaySemanticsHost(enabled: enabled);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderOverlaySemanticsHost renderObject,
  ) {
    renderObject.enabled = enabled;
  }
}

/// The render object for [OverlaySemanticsHost].
class RenderOverlaySemanticsHost extends RenderProxyBox {
  /// Creates the render object for [OverlaySemanticsHost].
  RenderOverlaySemanticsHost({required this._enabled});

  /// Whether the child's semantics configurations form a sibling merge group.
  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsSemanticsUpdate();
  }

  static ChildSemanticsConfigurationsResult _delegate(
    List<SemanticsConfiguration> childConfigs,
  ) {
    final builder = ChildSemanticsConfigurationsResultBuilder();
    if (childConfigs.isNotEmpty) {
      builder.markAsSiblingMergeGroup(childConfigs);
    }
    return builder.build();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_enabled) {
      config.childConfigurationsDelegate = _delegate;
    }
  }
}
