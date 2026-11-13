import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// A modal overlay opened from a page puts a dismiss barrier over the page:
// pointers on the page close the overlay, and the barrier's BlockSemantics
// drops the page from the semantics tree. Neither reaches a
// GlassNavigationShell's pinned chrome. The shell paints the chrome after the
// app's Navigator, in an Overlay of its own, so it sits above the barrier: a
// tap on the capsule fired its action with the page menu still open, and
// BlockSemantics, which only drops what was painted before it, left the
// capsule in a screen reader's swipe order (#472).
//
// The pieces here put the chrome behind the barrier without moving the
// overlay out of its route (which would undo #274's confinement):
//
//  * the shell provides a [ShellChromeBarrierScope] around the app subtree
//    only, not around its own chrome, so an overlay opened from the chrome
//    (a GlassBarItem.menu) finds no scope and leaves the chrome alone;
//  * a page-level overlay wraps its barrier in a [ShellChromeBarrier], which
//    holds the scope's [ShellChromeBarriers] for exactly as long as the
//    barrier is mounted;
//  * the shell wraps its chrome in a [ShellChromeBarrierGate], which, while
//    any hold is outstanding, drops the chrome's semantics and ignores
//    pointers, so they fall through to whatever is below: normally the page
//    menu's barrier, which closes the menu as it would anywhere else.

/// The page-level modal barriers currently up under a navigation shell.
///
/// Holds are keyed by owner, so holding or releasing twice is harmless, and
/// listeners are only told when the answer to [active] changes.
class ShellChromeBarriers extends ChangeNotifier {
  final Set<Object> _holders = <Object>{};

  /// Whether any barrier is up, and the shell's chrome should behave as if it
  /// were behind it.
  bool get active => _holders.isNotEmpty;

  /// Registers [holder]'s barrier as up.
  void hold(Object holder) {
    if (_holders.add(holder) && _holders.length == 1) notifyListeners();
  }

  /// Registers [holder]'s barrier as down.
  void release(Object holder) {
    if (_holders.remove(holder) && _holders.isEmpty) notifyListeners();
  }
}

/// Exposes a shell's [ShellChromeBarriers] to the app beneath it.
///
/// Placed around the app subtree only, so that it marks a modal overlay as
/// page-level by where the overlay was opened from.
class ShellChromeBarrierScope extends InheritedWidget {
  /// Exposes [barriers] to [child].
  const ShellChromeBarrierScope({
    super.key,
    required this.barriers,
    required super.child,
  });

  /// The registry the shell's [ShellChromeBarrierGate] follows.
  final ShellChromeBarriers barriers;

  /// The nearest enclosing registry, or null outside a shell's app subtree.
  static ShellChromeBarriers? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ShellChromeBarrierScope>()
      ?.barriers;

  @override
  bool updateShouldNotify(ShellChromeBarrierScope oldWidget) =>
      !identical(barriers, oldWidget.barriers);
}

/// Puts the enclosing shell's chrome behind a page-level modal barrier for as
/// long as it is mounted.
///
/// A page-level modal overlay wraps its dismiss barrier in this. While it is
/// up, the chrome the shell paints above the page drops out of the semantics
/// tree and ignores pointers, which fall through to the barrier below. Tying
/// the hold to the barrier's own lifetime releases it however the barrier
/// goes: closing, a controller-driven close, or the page being removed or
/// popped while the overlay is open.
///
/// Outside a shell's app subtree it does nothing.
class ShellChromeBarrier extends StatefulWidget {
  /// Holds the shell's chrome behind the barrier while [child] is up.
  const ShellChromeBarrier({super.key, required this.child});

  /// The barrier.
  final Widget child;

  @override
  State<ShellChromeBarrier> createState() => _ShellChromeBarrierState();
}

class _ShellChromeBarrierState extends State<ShellChromeBarrier> {
  ShellChromeBarriers? _barriers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final barriers = ShellChromeBarrierScope.maybeOf(context);
    if (identical(barriers, _barriers)) return;
    _barriers?.release(this);
    _barriers = barriers?..hold(this);
  }

  // Released on deactivate rather than dispose: a barrier leaving the tree is
  // deactivated while the frame builds, so the chrome comes back in that
  // frame, to screen readers and pointers alike. Dispose only runs once the
  // frame's semantics flush is over, alongside the rest of the overlay's
  // teardown, and a semantics update made from there was observed to be lost.
  // A barrier moved with a GlobalKey is reactivated, and holds again.
  @override
  void activate() {
    super.activate();
    _barriers?.hold(this);
  }

  @override
  void deactivate() {
    _barriers?.release(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Puts [child] behind the page-level barriers in [barriers] while any is up.
///
/// While [ShellChromeBarriers.active], [child] is excluded from the semantics
/// tree and ignores pointers. They fall through to whatever is below the
/// chrome, normally the page menu's dismiss barrier, so a tap on the chrome
/// closes the menu and nothing in the chrome sees a tap, long press or drag.
///
/// Two consequences of passing pointers through rather than taking them:
///
///  * where the open menu's panel lies under the chrome, a tap there reaches
///    the panel's row instead of dismissing the menu;
///  * in a nested [Navigator] or [Overlay] layout where the barrier does not
///    reach the bar, the tap falls to the bar's in-route placeholder and does
///    nothing.
///
/// The render object follows [barriers] directly rather than rebuilding,
/// because a hold is taken while the barrier builds, and the shell's chrome is
/// not a descendant it could be marked dirty from. Hit testing reads the
/// registry live, and a semantics update lands in the same frame as the hold.
///
/// Overlay content portaled into an [Overlay] above this gate (a
/// GlassBarItem.menu's panel) is not [child]'s descendant in the render tree,
/// so it keeps its semantics and its pointers while the chrome is held.
class ShellChromeBarrierGate extends SingleChildRenderObjectWidget {
  /// Holds [child] behind the barriers in [barriers] while any is up.
  const ShellChromeBarrierGate({
    super.key,
    required this.barriers,
    super.child,
  });

  /// The registry to follow.
  final ShellChromeBarriers barriers;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderShellChromeBarrierGate(barriers: barriers);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderShellChromeBarrierGate renderObject,
  ) {
    renderObject.barriers = barriers;
  }
}

/// The render object of a [ShellChromeBarrierGate].
class RenderShellChromeBarrierGate extends RenderExcludeSemantics {
  /// Holds its child behind the barriers in [barriers] while any is up.
  RenderShellChromeBarrierGate({required ShellChromeBarriers barriers})
      : _barriers = barriers,
        super(excluding: barriers.active);

  /// The registry this follows.
  ShellChromeBarriers get barriers => _barriers;
  ShellChromeBarriers _barriers;
  set barriers(ShellChromeBarriers value) {
    if (identical(value, _barriers)) return;
    if (attached) {
      _barriers.removeListener(_sync);
      value.addListener(_sync);
    }
    _barriers = value;
    _sync();
  }

  void _sync() => excluding = _barriers.active;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      !_barriers.active && super.hitTest(result, position: position);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _barriers.addListener(_sync);
    _sync();
  }

  @override
  void detach() {
    _barriers.removeListener(_sync);
    super.detach();
  }
}
