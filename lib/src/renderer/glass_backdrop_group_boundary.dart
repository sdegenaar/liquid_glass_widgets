import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../engine/render_liquid_glass_geometry.dart';

/// Marks where a [GlassBackdropGroup] starts in the render tree, and counts
/// the glass layers that share its backdrop read.
///
/// Impeller copies a shared backdrop once per frame, from the render pass of
/// the first filter that uses the key (`Canvas::SaveLayer`, `canvas.cc`). A
/// member drawn inside a save layer the others are not in (a fade, a shader
/// mask, the content of another glass surface) would read the wrong pass, so
/// a member checks the path up to here before it joins (see
/// [opensRenderPassBelow]). And the group only pays off with two members: on
/// its own a member folds its frost weight into the frost filter for nothing,
/// which costs more than the separate pass.
class GlassBackdropGroupBoundary extends SingleChildRenderObjectWidget {
  /// Marks the start of a group around [child], or, with [startsGroup]
  /// false, a group that joins the one further up.
  const GlassBackdropGroupBoundary({
    this.startsGroup = true,
    super.key,
    super.child,
  });

  /// Whether the group starts here. False when it joins an enclosing group,
  /// whose boundary then counts the members.
  final bool startsGroup;

  @override
  RenderGlassBackdropGroupBoundary createRenderObject(BuildContext context) =>
      RenderGlassBackdropGroupBoundary(startsGroup: startsGroup);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGlassBackdropGroupBoundary renderObject,
  ) {
    renderObject.startsGroup = startsGroup;
  }
}

/// The render object of a [GlassBackdropGroupBoundary].
class RenderGlassBackdropGroupBoundary extends RenderProxyBox {
  /// Creates the boundary of a group, see [startsGroup].
  RenderGlassBackdropGroupBoundary({bool startsGroup = true})
      : _startsGroup = startsGroup;

  final Set<RenderObject> _members = {};
  final Set<RenderObject> _membersWithPass1 = {};
  final Map<RenderObject, OffsetLayer> _hoistedLayers = {};
  final Map<RenderObject, Rect> _hoistedRects = {};
  RenderGlassBackdropHoistSlot? _hoistSlot;
  bool _repaintScheduled = false;

  /// Shared Pass-2 backdrop key for render-shader layers whose Pass 1 (blur
  /// and frost) has been hoisted ahead of all Pass-2 shaders in this group, or
  /// when no member in this group runs a Pass 1 filter.
  ///
  /// Together with the group's Pass-1 [BackdropKey], hoisting reduces an entire
  /// screen of `N` non-overlapping glass surfaces from `N + 1` full-screen
  /// framebuffer copies to **2** (1 shared Pass-1 frost read + 1 shared Pass-2
  /// shader read).
  final BackdropKey glassKey = BackdropKey();

  /// Whether the group starts here, or joins the one further up.
  bool get startsGroup => _startsGroup;
  bool _startsGroup;
  set startsGroup(bool value) {
    if (_startsGroup == value) return;
    _startsGroup = value;
    // The members move to the other boundary when they next paint.
    _repaintMembers();
  }

  /// How many glass layers share the group's backdrop read right now.
  int get memberCount => _members.length;

  /// How many glass layers currently hoist their Pass-1 blur/frost into this
  /// group's [GlassBackdropHoistSlot].
  @visibleForTesting
  int get hoistedCount => _hoistedLayers.length;

  /// Whether a [GlassBackdropHoistSlot] is attached inside this group and ready
  /// to host hoisted Pass-1 blur/frost layers.
  bool get hasHoistHost => _hoistSlot != null && _hoistSlot!.attached;

  /// The [RenderBox] of the attached hoist slot, or null when none is mounted.
  RenderBox? get hoistHostBox =>
      (_hoistSlot != null && _hoistSlot!.attached) ? _hoistSlot : null;

  /// Whether every member in this group has no Pass-1 blur/frost (so Pass 2
  /// shaders can share [glassKey] even without a hoist slot).
  bool get allMembersWithoutPass1 =>
      _members.length >= 2 && _membersWithPass1.isEmpty;

  /// Whether [member] currently shares the group's backdrop read.
  bool contains(RenderObject member) => _members.contains(member);

  /// Records whether [member] paints a Pass-1 blur/frost pass.
  void setMemberHasPass1(RenderObject member, bool hasPass1) {
    final changed = hasPass1
        ? _membersWithPass1.add(member)
        : _membersWithPass1.remove(member);
    if (changed) _repaintMembers();
  }

  /// Registers [slot] as this group's scoped Pass-1 hoist container.
  void attachHoistSlot(RenderGlassBackdropHoistSlot slot) {
    if (identical(_hoistSlot, slot)) return;
    _hoistSlot = slot;
    // Re-attach any already-hoisted layers into the new slot container.
    for (final layer in _hoistedLayers.values) {
      slot.attachHoistedLayer(layer);
    }
    _repaintMembers();
  }

  /// Unregisters [slot] when detached or disposed.
  void detachHoistSlot(RenderGlassBackdropHoistSlot slot) {
    if (!identical(_hoistSlot, slot)) return;
    for (final layer in _hoistedLayers.values) {
      layer.remove();
    }
    _hoistedLayers.clear();
    _hoistedRects.clear();
    _hoistSlot = null;
    if (_members.isNotEmpty) _repaintMembers();
  }

  /// Returns `true` if [rectInHost] intersects any other member's currently
  /// hoisted Pass-1 rect (inflated by 1 logical px for AA safety).
  bool overlapsOtherHoisted(RenderObject member, Rect rectInHost) {
    final expanded = rectInHost.inflate(1.0);
    for (final entry in _hoistedRects.entries) {
      if (identical(entry.key, member)) continue;
      if (entry.value.overlaps(expanded)) return true;
    }
    return false;
  }

  /// Registers or updates [member]'s hoisted Pass-1 [layer] at [rectInHost].
  void setHoisted(RenderObject member, OffsetLayer layer, Rect rectInHost) {
    final slot = _hoistSlot;
    if (slot == null || !slot.attached) return;
    final prev = _hoistedLayers[member];
    if (prev != null && !identical(prev, layer)) {
      prev.remove();
    }
    _hoistedLayers[member] = layer;
    _hoistedRects[member] = rectInHost;
    slot.attachHoistedLayer(layer);
  }

  /// Updates the cached rect for an already-hoisted [member] during composite.
  void updateHoistedRect(RenderObject member, Rect rectInHost) {
    if (!_hoistedLayers.containsKey(member)) return;
    _hoistedRects[member] = rectInHost;
    _hoistSlot?.markHoistDirty();
  }

  /// Removes [member]'s hoisted Pass-1 layer from the hoist container.
  void removeHoisted(RenderObject member) {
    final prev = _hoistedLayers.remove(member);
    _hoistedRects.remove(member);
    if (prev != null) {
      prev.remove();
      _hoistSlot?.markHoistDirty();
    }
  }

  /// Adds [member]. The others repaint, since whether they share depends on
  /// how many there are.
  void join(RenderObject member) {
    if (_members.add(member)) _repaintMembers();
  }

  /// Removes [member], and repaints the others.
  void leave(RenderObject member) {
    removeHoisted(member);
    _membersWithPass1.remove(member);
    if (_members.remove(member)) _repaintMembers();
  }

  // Joins and leaves happen while painting, where marking another render
  // object for paint is not allowed, so the repaint waits for the frame to end.
  void _repaintMembers() {
    if (_repaintScheduled) return;
    _repaintScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _repaintScheduled = false;
      for (final member in _members) {
        if (member.attached) member.markNeedsPaint();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void detach() {
    for (final layer in _hoistedLayers.values) {
      layer.remove();
    }
    _hoistedLayers.clear();
    _hoistedRects.clear();
    _membersWithPass1.clear();
    _hoistSlot = null;
    _members.clear();
    super.detach();
  }
}

/// Tree-scoped Pass-1 frost hoist slot placed immediately after backdrop
/// content and before floating glass chrome inside a [GlassBackdropGroup].
///
/// Eligible non-overlapping [RenderLiquidGlassLayer] members hoist their
/// Pass-1 blur/frost layers into this slot's [ContainerLayer] so all Pass-1
/// layers paint together (1 framebuffer copy via the group's frost key) before
/// any Pass-2 render shader runs (1 framebuffer copy via `glassKey`).
///
/// Strictly scoped to its enclosing [RenderGlassBackdropGroupBoundary] with
/// zero global registries.
class GlassBackdropHoistSlot extends LeafRenderObjectWidget {
  /// Creates a tree-scoped Pass-1 hoist slot.
  const GlassBackdropHoistSlot({super.key});

  @override
  RenderGlassBackdropHoistSlot createRenderObject(BuildContext context) =>
      RenderGlassBackdropHoistSlot();
}

/// Render object for [GlassBackdropHoistSlot].
class RenderGlassBackdropHoistSlot extends RenderBox {
  RenderGlassBackdropGroupBoundary? _boundary;
  final LayerHandle<OffsetLayer> _hoistContainerHandle =
      LayerHandle<OffsetLayer>();

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  OffsetLayer get _ensureContainer =>
      _hoistContainerHandle.layer ??= OffsetLayer();

  /// Attaches [layer] into this slot's [OffsetLayer] container so hoisted
  /// Pass-1 children paint in this slot's exact local coordinate space.
  ///
  /// [ContainerLayer.append] and [Layer.remove] automatically mark the
  /// container for scene recomposition.
  void attachHoistedLayer(OffsetLayer layer) {
    final container = _ensureContainer;
    if (!identical(layer.parent, container)) {
      if (layer.parent != null) layer.remove();
      container.append(layer);
    }
  }

  /// No-op hook retained for callers; [OffsetLayer] marks itself dirty
  /// automatically when children are appended, removed, or re-offset.
  void markHoistDirty() {}

  void _syncBoundary() {
    final next = enclosingBackdropGroup(this);
    if (identical(next, _boundary)) return;
    _boundary?.detachHoistSlot(this);
    _boundary = next;
    _boundary?.attachHoistSlot(this);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _syncBoundary();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _syncBoundary();
    final container = _ensureContainer;
    if (container.offset != offset) {
      container.offset = offset;
    }
    // Use addLayer (NOT pushLayer): PaintingContext.pushLayer calls
    // container.removeAllChildren(), which wipes hoisted Pass-1 frost layers
    // belonging to glass chrome sitting behind clean RepaintBoundaries
    // (such as GlassTabBar) whenever the scaffold or sibling content repaints.
    container.remove();
    context.addLayer(container);
  }

  @override
  void detach() {
    _boundary?.detachHoistSlot(this);
    _boundary = null;
    _hoistContainerHandle.layer?.removeAllChildren();
    super.detach();
  }

  @override
  void dispose() {
    _hoistContainerHandle.layer?.removeAllChildren();
    _hoistContainerHandle.layer = null;
    super.dispose();
  }
}

/// Pure [InheritedWidget] scope that keeps glass in [child] inside its
/// enclosing [GlassBackdropGroup] while optionally opting it out of Pass-1
/// frost hoisting.
///
/// Used by [GlassAppBar] with `optedOut: usesFullBlur` (always mounted so
/// live `GlassStyle` / posture toggles never remount child state): when iOS
/// 27's scroll-under blurred surface paints between [GlassBackdropHoistSlot]
/// and the app bar buttons, hoisting Pass 1 below the scroll-under surface
/// would let the scroll-under blur overwrite hoisted odd frost rows before
/// Pass 2 reads them.
class GlassBackdropHoistOptOut extends InheritedWidget {
  /// Creates a Pass-1 hoist opt-out scope around [child].
  const GlassBackdropHoistOptOut({
    required super.child,
    this.optedOut = true,
    super.key,
  });

  /// Whether Pass-1 hoisting is disabled for [child].
  final bool optedOut;

  /// Whether an ancestor opted this subtree out of Pass-1 frost hoisting.
  static bool isOptedOut(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GlassBackdropHoistOptOut>()
          ?.optedOut ??
      false;

  @override
  bool updateShouldNotify(GlassBackdropHoistOptOut oldWidget) =>
      optedOut != oldWidget.optedOut;
}

/// The group [member] belongs to, or null when there is none between it and
/// the root, or when a render pass of its own opens between the two (see
/// [opensRenderPassBelow]). Boundaries that join an enclosing group are
/// passed on the way up.
RenderGlassBackdropGroupBoundary? enclosingBackdropGroup(RenderObject member) {
  RenderObject? node = member.parent;
  while (node != null) {
    if (node is RenderGlassBackdropGroupBoundary && node.startsGroup) {
      return node;
    }
    if (opensRenderPassBelow(node)) return null;
    node = node.parent;
  }
  return null;
}

/// Whether [node] draws, or may start drawing, its subtree into a save layer
/// of its own, which on Impeller is a render pass of its own.
///
/// These are the framework's save layers that can stand between glass and
/// its group: an opacity, a shader mask, a backdrop filter, a clip with
/// [Clip.antiAliasWithSaveLayer], and the content of a glass surface, which
/// is drawn inside that surface's backdrop filters.
///
/// An opacity counts at any value, 1 included. A member only checks this
/// path when it paints, and glass paints below a repaint boundary: when a
/// fade starts after the first paint (1 → 0.99), the framework re-composites
/// the member's cached layer inside the new opacity layer without painting
/// it again, so a member that joined at 1 would keep the group's key in the
/// wrong pass.
bool opensRenderPassBelow(RenderObject node) {
  bool saves(Clip clip) => clip == Clip.antiAliasWithSaveLayer;
  return switch (node) {
    RenderOpacity() ||
    RenderAnimatedOpacityMixin() ||
    RenderSliverOpacity() ||
    RenderShaderMask() ||
    RenderBackdropFilter() =>
      true,
    RenderLiquidGlassGeometry() => true,
    RenderClipRect(:final clipBehavior) => saves(clipBehavior),
    RenderClipRRect(:final clipBehavior) => saves(clipBehavior),
    RenderClipRSuperellipse(:final clipBehavior) => saves(clipBehavior),
    RenderClipOval(:final clipBehavior) => saves(clipBehavior),
    RenderClipPath(:final clipBehavior) => saves(clipBehavior),
    RenderPhysicalModel(:final clipBehavior) => saves(clipBehavior),
    RenderPhysicalShape(:final clipBehavior) => saves(clipBehavior),
    _ => false,
  };
}
