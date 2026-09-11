import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter/widgets.dart';

import '../../constants/glass_defaults.dart';
import '../../src/engine/liquid_glass_settings.dart';
import '../effects/glass_materialize.dart';
import 'glass_bar_item.dart';
import 'shared/glass_nav_pinned_host.dart';

/// What a single route contributes to the pinned navigation chrome.
///
/// Created by [GlassAppBar.pinned] bars and handed to the enclosing
/// [GlassNavigationShell]. Consumers never construct this directly.
@immutable
class GlassNavBarRegistration {
  /// Creates a registration describing one route's pinned bar chrome.
  const GlassNavBarRegistration({
    required this.actions,
    this.leading = const <GlassBarItem>[],
    required this.showsBackButton,
    this.onBack,
    this.buttonSettings,
  });

  /// The trailing cluster items for this route.
  final List<GlassBarItem> actions;

  /// The leading cluster items for this route, excluding the back button.
  ///
  /// Whether the back button also appears is [showsBackButton]'s business: the
  /// bar has already applied the replace-or-supplement rule by the time it
  /// registers, so the host reads one flag rather than re-deriving it.
  final List<GlassBarItem> leading;

  /// Whether this route shows the pinned back button.
  final bool showsBackButton;

  /// Overrides the default back action (`Navigator.maybePop`).
  final VoidCallback? onBack;

  /// Glass settings applied to this route's pinned chrome.
  final LiquidGlassSettings? buttonSettings;

  /// The tappable items in [actions], with spacers removed.
  List<GlassBarActionItem> get actionItems =>
      actions.whereType<GlassBarActionItem>().toList(growable: false);

  /// The tappable items in [leading], with spacers removed.
  List<GlassBarActionItem> get leadingItems =>
      leading.whereType<GlassBarActionItem>().toList(growable: false);
}

/// Hosts navigation-bar glass chrome **above** the [Navigator], so it stays
/// pinned while route content slides during a push or pop.
///
/// This reproduces the iOS 26 navigation bar model, where bar items belong to
/// the navigation stack rather than to any one screen. Apple documents the
/// behaviour on `UIBarButtonItem.identifier`: *"When the set of bar button
/// items in a navigation bar or toolbar changes (for example, when pushing or
/// popping view controllers), UIKit automatically animates the transition
/// between the different sets of items."*
///
/// Install it once, wrapping whatever [Navigator] your app builds. This works
/// with the imperative [Navigator] and with any router built on the Pages API
/// (go_router, auto_route, beamer), because the shell only ever reads
/// [ModalRoute] animations — it never intercepts navigation:
///
/// ```dart
/// CupertinoApp(
///   builder: (context, child) => GlassNavigationShell(child: child!),
///   home: const HomeScreen(),
/// );
///
/// // Or with a router:
/// CupertinoApp.router(
///   routerConfig: router,
///   builder: (context, child) => GlassNavigationShell(child: child!),
/// );
/// ```
///
/// Screens opt in with the [GlassAppBar.pinned] constructor. Screens using
/// the plain [GlassAppBar] are unaffected, and when no shell is present (or
/// the device can't render the effect) pinned bars fall back to rendering the
/// same buttons inside the route.
class GlassNavigationShell extends StatefulWidget {
  /// Creates a navigation shell around [child].
  const GlassNavigationShell({
    super.key,
    required this.child,
    this.enabled = true,
    this.effectTransition = GlassEffectTransition.materialize,
  });

  /// The subtree containing the [Navigator], typically the `child` handed to
  /// `CupertinoApp.builder`.
  final Widget child;

  /// Whether pinning is enabled at all.
  ///
  /// When false the shell is inert and every screen renders its bar chrome
  /// in-route, exactly as if no shell were installed.
  final bool enabled;

  /// How chrome that appears or disappears across a transition animates —
  /// a back button on the first push off the root, an actions capsule on a
  /// route whose destination has none.
  ///
  /// Defaults to [GlassEffectTransition.materialize], mirroring iOS 26.
  /// [GlassEffectTransition.identity] restores the single switch at the
  /// transition midpoint, which is what reduce motion selects too.
  ///
  /// Set on the shell rather than per screen because the choreography spans
  /// two routes: with a knob on each bar, a push between routes that disagree
  /// would have no answer for which one wins.
  final GlassEffectTransition effectTransition;

  /// The nearest enclosing shell, or null if there is none.
  static GlassNavigationShellState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_GlassNavigationShellScope>()
        ?.state;
  }

  @override
  State<GlassNavigationShell> createState() => GlassNavigationShellState();
}

/// Registry and animation clock for a [GlassNavigationShell].
///
/// Routes register through [register] and are ranked by how covered they are,
/// so the shell always knows which route is on top and which sits beneath it
/// mid-transition.
class GlassNavigationShellState extends State<GlassNavigationShell>
    with SingleTickerProviderStateMixin {
  /// Registrations keyed by route, in registration order.
  final Map<ModalRoute<dynamic>, GlassNavBarRegistration> _registry =
      <ModalRoute<dynamic>, GlassNavBarRegistration>{};

  /// Routes whose animations this shell currently listens to.
  final Set<Animation<double>> _listened = <Animation<double>>{};

  /// Fires whenever the rendered chrome may have changed.
  final _TickNotifier _tick = _TickNotifier();

  /// Notifies when the answer [isHoisting] gives may have changed.
  ///
  /// Registrants follow this rather than reading the routes themselves, so
  /// that the bar and the shell always swap in the same frame.
  Listenable get chromeChanges => _tick;

  /// Whether a deferred notification is already queued for this frame.
  bool _notifyQueued = false;

  // ---------------------------------------------------------------------------
  // Interactive back-swipe hold
  // ---------------------------------------------------------------------------
  // The chrome's own transition waits for the gesture to commit rather than
  // scrubbing under the finger. Dragging halfway and letting go should not
  // have half-dissolved a button on the way — until the pop is committed
  // there is no answer yet to which chrome wins, and animating toward one
  // reads as the bar guessing. The page and its title still track the drag;
  // it is only the pinned chrome that waits.

  /// Whether a user gesture was in progress on the previous resolve.
  bool _gestureActive = false;

  /// Chrome progress frozen at the moment the gesture began.
  double? _gestureHeldProgress;

  /// The most recent progress observed with no gesture running.
  ///
  /// A drag is already under way by the time the shell first resolves during
  /// it, so this is what the chrome is held at rather than the value on that
  /// first frame.
  double? _ungesturedProgress;

  /// Plays the chrome's transition after a swipe commits.
  ///
  /// The chrome cannot ride the route's remaining travel here. Cupertino
  /// sizes the commit animation by how far the drag got —
  /// `lerpDouble(0, maxDroppedSwipeTime, controller.value)` — so releasing
  /// late leaves almost nothing to play over, and the whole dissolve was
  /// being squeezed into about five frames. Given its own duration it always
  /// reads, at the price of outliving the page transition on a late release.
  late final AnimationController _commitExit = AnimationController(
    vsync: this,
    duration: GlassDefaults.dematerializeDuration,
  );

  /// The chrome as it stood when the swipe committed, or null when no commit
  /// is playing.
  ///
  /// Frozen because the outgoing route unregisters the moment its pop
  /// finishes, which is *before* this animation ends. Resolving from the live
  /// registry would flip `from`/`to` mid-play and snap the chrome — the exact
  /// thing the fixed duration exists to avoid.
  GlassNavPinnedState? _commitExitSnapshot;

  /// Chrome progress the commit animation starts from.
  double _commitExitStart = 1.0;

  bool _pinningSupported = false;

  /// Whether pinning is currently active.
  ///
  /// False when the shell is disabled or the resolved glass quality can't
  /// render the effect, in which case registrants render in-route instead.
  bool get isActive => widget.enabled && _pinningSupported;

  @override
  void initState() {
    super.initState();
    _commitExit
      ..addListener(_tick.notify)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        _commitExitSnapshot = null;
        _clearGestureHold();
        // Back to rest so the next commit holds at its snapshot rather than
        // starting from a controller still parked at 1.0.
        _commitExit.reset();
        _scheduleNotify();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pinning is chrome GEOMETRY: it hoists the registered bar out of the
    // route into the shell so it survives the transition. It costs no shader
    // of its own, and the pinned bar still renders through the normal glass
    // path — GlassNavPinnedHost resolves its own quality — so at `minimal` it
    // is simply a BackdropFilter-only bar that stays put across routes, which
    // is the correct degraded behaviour rather than a reason to switch the
    // feature off.
    //
    // This used to mirror the modal sheet morph's gate
    // (`quality != GlassQuality.minimal`). That borrowed the blur's
    // capability floor for something that does not depend on it: the sheet
    // morph asks whether real glass can be drawn, and pinning never needed an
    // answer to that.
    //
    // It also meant an adaptive decision about blur cost silently changed an
    // unrelated layout behaviour. `minimal` is not only a developer opt-in —
    // GlassQualityAdapter steps down to it on its own when frame times
    // regress, which a debug build reaches routinely just by being a debug
    // build — so pinning switched itself off during ordinary local
    // development, and on any app deliberately shipping `minimal` for low-end
    // devices, which are exactly the devices where a per-route bar rebuild is
    // most visible.
    final supported = debugPinningSupported ?? true;
    if (supported != _pinningSupported) {
      _pinningSupported = supported;
    }
  }

  /// Overrides the capability gate in tests, where no GPU is available.
  @visibleForTesting
  static bool? debugPinningSupported;

  // ---------------------------------------------------------------------------
  // Registry
  // ---------------------------------------------------------------------------

  /// Registers or updates [route]'s pinned chrome.
  void register(
    ModalRoute<dynamic> route,
    GlassNavBarRegistration registration,
  ) {
    final existing = _registry[route];
    _registry[route] = registration;
    if (existing == null) {
      _listenTo(route.animation);
      _listenTo(route.secondaryAnimation);
    }
    _scheduleNotify();
  }

  /// Removes [route] from the registry.
  void unregister(ModalRoute<dynamic> route) {
    if (_registry.remove(route) == null) return;
    _unlisten(route.animation);
    _unlisten(route.secondaryAnimation);
    _scheduleNotify();
  }

  /// Listens to both the value and the status of [animation].
  ///
  /// The status matters on its own: a transition's last value tick lands on
  /// 1.0 (or 0.0) *before* the controller reports itself completed, so a
  /// value-only listener never hears the frame where a rebounding back-swipe
  /// stops being a transition. [GlassNavPinnedState.settled] reads that
  /// status, so it needs the notification.
  void _listenTo(Animation<double>? animation) {
    if (animation == null || !_listened.add(animation)) return;
    animation.addListener(_onAnimationTick);
    animation.addStatusListener(_onAnimationStatus);
  }

  void _unlisten(Animation<double>? animation) {
    if (animation == null || !_listened.remove(animation)) return;
    animation.removeListener(_onAnimationTick);
    animation.removeStatusListener(_onAnimationStatus);
  }

  // A route wiring its secondary animation (`ProxyAnimation.parent=` inside
  // `didChangeNext`) notifies value listeners synchronously, and for a
  // page-based Navigator that runs inside `didUpdateWidget` — the build
  // phase — so the tick has to defer exactly as a status change does.
  void _onAnimationTick() => _scheduleNotify();

  void _onAnimationStatus(AnimationStatus status) {
    // Not while a finger is down: several routes' animations are listened to
    // at once, and one of them settling elsewhere must not drop the hold on
    // the swipe currently in progress.
    if (!_gestureActive &&
        (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed)) {
      _clearGestureHold();
    }
    _scheduleNotify();
  }

  /// Notifies listeners, deferring past build/layout when necessary.
  ///
  /// Registration happens during a descendant's build, so notifying inline
  /// would mutate the tree mid-frame. This mirrors the deferral used by the
  /// modal sheet morph's anchor.
  void _scheduleNotify() {
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      // Several routes can register in one frame (first build after a hot
      // reload, a popUntil); queue a single deferred notification for all.
      if (_notifyQueued) return;
      _notifyQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyQueued = false;
        if (mounted) _tick.notify();
      });
    } else {
      _tick.notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Ordering
  // ---------------------------------------------------------------------------

  /// The registered routes ordered from topmost to bottom-most.
  ///
  /// Rank comes from `secondaryAnimation`, which measures how much a route is
  /// covered by whatever sits above it: the top route is uncovered (0), and a
  /// route being covered by a push animates toward 1. This derives stack order
  /// from the routes themselves, so no [NavigatorObserver] is needed and any
  /// Pages-API router works unchanged.
  List<MapEntry<ModalRoute<dynamic>, GlassNavBarRegistration>>
      get _orderedEntries {
    final entries = _registry.entries
        .where((e) => _participates(e.key))
        .toList(growable: false);
    final insertionIndex = <ModalRoute<dynamic>, int>{};
    var i = 0;
    for (final route in _registry.keys) {
      insertionIndex[route] = i++;
    }
    entries.sort((a, b) {
      final byCoverage = _coverageOf(a.key).compareTo(_coverageOf(b.key));
      if (byCoverage != 0) return byCoverage;
      // Equally covered: the more recently pushed route is on top.
      return insertionIndex[b.key]!.compareTo(insertionIndex[a.key]!);
    });
    return entries;
  }

  /// Whether [route] still contributes chrome this frame.
  ///
  /// `isActive` goes false the instant a route is popped, while its exit
  /// transition still has its full duration left to run. Filtering on that
  /// alone drops the outgoing route from the interpolation on the very first
  /// frame of a button-driven pop, snapping the chrome to the destination
  /// instead of morphing into it. A reversing route is still on screen and
  /// still owns chrome. The back-swipe never hit this, because a swipe only
  /// pops the route once the gesture commits.
  static bool _participates(ModalRoute<dynamic> route) =>
      route.isActive || route.animation?.status == AnimationStatus.reverse;

  static double _coverageOf(ModalRoute<dynamic> route) =>
      route.secondaryAnimation?.value ?? 0.0;

  /// Whether [route] should leave its chrome to the shell this frame.
  ///
  /// True for every registered route while the shell is drawing, not only the
  /// topmost one: mid-transition the chrome is a blend of two routes' items,
  /// so the outgoing route has to keep its placeholder or its own buttons
  /// would slide out from underneath the pinned copy.
  bool isHoisting(ModalRoute<dynamic> route) {
    if (!isActive || !_registry.containsKey(route)) return false;
    final ordered = _orderedEntries;
    if (ordered.isEmpty) return false;
    return !_isPresentedOver(ordered.first.key);
  }

  /// Whether a route this shell cannot rank has been *presented* over [route].
  ///
  /// UIKit's push/present split is the one that matters here, and the two need
  /// opposite treatment. A pushed route slides the covered bar away with its
  /// page, which the shell mirrors by retreating the chrome on the covered
  /// route's `secondaryAnimation`. A presented one — a dialog, an action
  /// sheet, a modal sheet, a fullscreen dialog — comes up over the whole
  /// navigation stack with the bar inside it, and drives no exit transition to
  /// retreat on: `CupertinoRouteTransitionMixin.canTransitionTo` refuses a
  /// next route that is neither a `CupertinoRouteTransitionMixin` nor carries
  /// a `delegatedTransition`, and refuses a fullscreen dialog outright.
  ///
  /// Retreating would be the wrong answer even if there were an animation to
  /// retreat on. The chrome is not covered by a presentation, it is *under*
  /// one — still on screen behind a sheet, dimming with the barrier like the
  /// rest of the page. The shell cannot draw it there, because it draws above
  /// the [Navigator] the presentation was pushed into, so it gives the chrome
  /// back and the route renders it exactly where it renders when no shell is
  /// installed at all.
  ///
  /// `isCurrent` cannot answer this on its own: a route being popped is not
  /// current either, and it owns the chrome for the whole of its exit. What
  /// separates the two is whether any transition is running.
  static bool _isPresentedOver(ModalRoute<dynamic> route) =>
      !route.isCurrent && _isAtRest(route);

  /// Whether no transition involving [route] is in flight.
  static bool _isAtRest(ModalRoute<dynamic> route) =>
      (route.animation?.status ?? AnimationStatus.completed) ==
          AnimationStatus.completed &&
      (route.secondaryAnimation?.status ?? AnimationStatus.dismissed) ==
          AnimationStatus.dismissed &&
      !(route.navigator?.userGestureInProgress ?? false);

  /// The chrome progress to render, holding still under an active gesture.
  ///
  /// While the finger is down this returns the value the chrome had when the
  /// drag began, so nothing dissolves or cross-fades under a swipe that may
  /// yet be cancelled.
  ///
  /// Neither release path needs re-timing here. A commit is handed to
  /// [_commitExit], which replays the transition on its own clock; a cancelled
  /// swipe rebounds the route back to where the chrome was already held, so
  /// the live progress is the right answer on its own.
  double _holdForGesture(double progress, bool gesturing) {
    if (gesturing) {
      // The last value seen *before* the gesture, not the one on the frame it
      // was first observed: a drag has already travelled some distance by the
      // time the first frame resolves, and holding at that would bake the
      // jump it made in the meantime into the held value.
      _gestureHeldProgress ??= _ungesturedProgress ?? progress;
      _gestureActive = true;
      return _gestureHeldProgress!;
    }

    // Released. A commit is taken over by [_commitExit] and never reaches
    // here; a cancelled swipe rebounds to where it was held, so the live
    // progress is already the right answer.
    _gestureActive = false;
    _gestureHeldProgress = null;
    _ungesturedProgress = progress;
    return progress;
  }

  /// Drops the gesture hold once a transition is over.
  ///
  /// Without this the next push would be re-timed against a release point
  /// from a swipe that finished long ago.
  void _clearGestureHold() {
    _gestureActive = false;
    _gestureHeldProgress = null;
  }

  /// The chrome to render right now, or null when nothing should be shown.
  GlassNavPinnedState? resolveState() {
    if (!isActive) return null;

    // A committed swipe plays from the frozen snapshot, not the registry: the
    // outgoing route unregisters when its pop finishes, which happens before
    // this animation does.
    final exiting = _commitExitSnapshot;
    if (exiting != null) {
      return GlassNavPinnedState(
        from: exiting.from,
        to: exiting.to,
        progress: _commitExitStart * (1.0 - _commitExit.value),
        coverage: exiting.coverage,
        settled: false,
        // A committed swipe is a pop by definition.
        popping: true,
        topRoute: exiting.topRoute,
        transition: exiting.transition,
      );
    }

    final ordered = _orderedEntries;
    if (ordered.isEmpty) return null;

    final top = ordered.first;

    // Nothing drawn above the `Navigator` can be underneath a route presented
    // into it, so the shell stands down and the registrants take their chrome
    // back for as long as one is up.
    if (_isPresentedOver(top.key)) return null;

    final below = ordered.length > 1 ? ordered[1] : null;

    // Progress of the top route's own entrance: 1 at rest, 0 when it has just
    // been pushed, and scrubbed by the interactive back-swipe during a pop.
    var progress = top.key.animation?.value ?? 1.0;

    // A route's `animation` is a ProxyAnimation that reports itself complete
    // at 1.0 until the navigator attaches the real controller in `didPush`,
    // which lands *after* the route's first build — and that build is when its
    // bar registers. Taken at face value it says a route that has not begun to
    // move is fully entered, so the incoming chrome paints solid for one frame
    // before dropping back to 0 and materializing: a visible flash.
    //
    // The route underneath is the witness. It is covered in lockstep with the
    // top route's entrance, so at rest the two agree (1.0 and fully covered),
    // and during a real transition they agree at every scrubbed value. Only
    // the frame before the controller is attached has the top route claiming
    // to be fully in while nothing below it has been covered at all.
    if (below != null &&
        progress == 1.0 &&
        _coverageOf(below.key) == 0.0 &&
        top.key.animation?.status == AnimationStatus.completed) {
      progress = 0.0;
    }

    // Retreat only when something *unregistered* sits above the top route —
    // a plain route or a modal sheet. `isCurrent` is what distinguishes that
    // from a pop still unwinding this route's secondaryAnimation: anything
    // registered above would have sorted above it instead, so a non-current
    // top route is covered by something this shell doesn't manage.
    final coverage = top.key.isCurrent ? 0.0 : _coverageOf(top.key);

    // True for the whole of a swipe *and* the commit or rebound that follows
    // it: Cupertino only calls `didStopUserGesture` from a status listener
    // once that animation has finished.
    final userGesture = top.key.navigator?.userGestureInProgress ?? false;

    // Whether the chrome may be tapped. Deliberately not derived from
    // `progress`: a pop starts at 1.0 and a back-swipe sits there until the
    // finger moves, so by value alone a transition that is very much running
    // looks finished. The controller's status and the navigator's gesture flag
    // are what actually tell the two apart, and `isCurrent` covers a route
    // that something unregistered has been pushed over.
    final settled = top.key.isCurrent &&
        (top.key.animation?.status ?? AnimationStatus.completed) ==
            AnimationStatus.completed &&
        !userGesture;

    // Whether the finger is still down with the pop not yet committed — which
    // is narrower than [userGesture], and is what the chrome hold needs.
    // Holding on the broader flag kept the chrome frozen for the whole commit
    // animation and then snapped it at the end, with no transition played.
    //
    // The route is the witness: committing pops it immediately, so `isActive`
    // goes false the moment the finger lifts on a commit, while a cancelled
    // swipe leaves it active through the rebound — exactly when the chrome
    // should still be holding.
    final gesturing = userGesture && top.key.isActive;

    // The frame the swipe commits: the finger has lifted and the route is
    // already popped. Freeze what the chrome looked like and hand it to
    // [_commitExit], which plays it out on its own clock.
    //
    // The held value has to be read before [_holdForGesture] runs, because
    // releasing clears it — and the held value is exactly where the chrome
    // must start from, not the live progress the drag happened to reach.
    final committing = _gestureActive && !gesturing && !top.key.isActive;
    final heldAtCommit = _gestureHeldProgress ?? progress;

    // A pop plays the same forward choreography toward the other target, not
    // the push in reverse — the host mirrors the clock and swaps the roles.
    // The gesture flag matters as much as the status: a back-swipe holds the
    // controller at whatever value the finger dictates without ever entering
    // AnimationStatus.reverse.
    final popping = !settled &&
        ((top.key.animation?.status ?? AnimationStatus.completed) ==
                AnimationStatus.reverse ||
            userGesture);

    final state = GlassNavPinnedState(
      from: below?.value ??
          const GlassNavBarRegistration(
            actions: <GlassBarItem>[],
            showsBackButton: false,
          ),
      to: top.value,
      progress: committing
          ? heldAtCommit.clamp(0.0, 1.0)
          : _holdForGesture(progress, gesturing).clamp(0.0, 1.0),
      coverage: coverage.clamp(0.0, 1.0),
      settled: settled,
      popping: popping,
      topRoute: top.key,
      transition: widget.effectTransition,
    );

    if (committing) {
      _gestureActive = false;
      _gestureHeldProgress = null;
      _commitExitStart = state.progress;
      _commitExitSnapshot = state;
      // Deferred: this runs inside [_tick]'s own ListenableBuilder, and
      // starting a controller notifies its listeners synchronously — which
      // would mark that builder dirty in the middle of its own build. The
      // controller rests at 0 until then, so the frame in between holds the
      // snapshot rather than showing a gap.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _commitExitSnapshot != null) {
          _commitExit.forward(from: 0.0);
        }
      });
    }
    return state;
  }

  @override
  void dispose() {
    for (final animation in _listened) {
      animation.removeListener(_onAnimationTick);
      animation.removeStatusListener(_onAnimationStatus);
    }
    _listened.clear();
    _commitExit.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassNavigationShellScope(
      state: this,
      child: Stack(
        children: [
          widget.child,
          // The chrome gets an Overlay of its own because it deliberately sits
          // above the app's Navigator, and therefore outside the Navigator's
          // Overlay — a GlassBarItem.menu portals to the root overlay, and up
          // here there would otherwise be none to find. This one is full-screen
          // and origin-aligned, so the menu's global-coordinate morph lands on
          // its trigger exactly as it does inside a route, and its dismiss
          // barrier covers the page below. It is a *sibling* of the Navigator,
          // not an ancestor, so nothing inside the app resolves its root
          // overlay to this one.
          if (widget.enabled)
            Overlay.wrap(
              child: ListenableBuilder(
                listenable: _tick,
                builder: (context, _) {
                  final state = resolveState();
                  if (state == null) return const SizedBox.shrink();
                  return GlassNavPinnedHost(state: state);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Exposes the shell state to descendant registrants.
class _GlassNavigationShellScope extends InheritedWidget {
  const _GlassNavigationShellScope({
    required this.state,
    required super.child,
  });

  final GlassNavigationShellState state;

  @override
  bool updateShouldNotify(_GlassNavigationShellScope oldWidget) =>
      state != oldWidget.state;
}

/// A [ChangeNotifier] whose notification is callable by its owner.
class _TickNotifier extends ChangeNotifier {
  /// Notifies listeners that the pinned chrome may have changed.
  void notify() => notifyListeners();
}
