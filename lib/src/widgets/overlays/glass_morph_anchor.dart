import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import '../../../utils/liquid_morph_physics.dart';

/// The widget a presented glass overlay (such as `GlassModalSheet` or
/// `showGlassConfirmationDialog`) morphs out of, and the channel that empties
/// it while the morph is in flight.
///
/// Close to an opaque token: [GlassMorphTrigger] creates one, hands it to its
/// builder, and disposes it; callers pass it straight to `morphFrom:` and never
/// touch it otherwise. All it reports back is [isPresenting], for chrome that
/// has to know whether the trigger it drew is currently standing in for a
/// presented overlay. The constructor is private so one cannot be made by hand
/// — an anchor with no trigger behind it has nothing to empty.
///
/// ## Why a token rather than a bare [GlobalKey]
///
/// A key can only *locate* the trigger. Reading its rect is enough to aim the
/// morph, but not to make the trigger look like it empties — and a trigger that
/// stays painted while a glass droplet inflates on top of it reads as a
/// duplicated button, not a morph. Nothing in Flutter lets one widget hide
/// another it does not own, so the trigger has to cooperate:
/// [GlassMorphTrigger] owns the key *and* the opacity, and this token is how
/// the presented overlay reaches back to it.
///
/// `GlassMenu` does the same thing internally with its own trigger; this is
/// that arrangement made available to a trigger the overlay does not own.
class GlassMorphAnchor {
  GlassMorphAnchor._();

  /// Identifies the trigger's subtree so its global rect can be resolved at
  /// presentation time.
  final GlobalKey _key = GlobalKey();

  /// Broadcasts state changes to the owning [GlassMorphTrigger].
  ///
  /// Held rather than inherited so this type stays a plain token: extending
  /// [ChangeNotifier] would put `addListener` and `dispose` on the public
  /// surface, and a caller disposing their own anchor would strand the morph.
  final _AnchorNotifier _notifier = _AnchorNotifier();

  bool _emptied = false;
  _MorphHandback? _handback;
  bool _disposed = false;

  /// Whether the trigger is currently emptied for a presented overlay.
  ///
  /// True from the frame the morph starts until the droplet is caught on
  /// dismissal — or, if the route is torn down without the closing morph,
  /// until the trigger is restored. What pinned bar chrome reads to keep a
  /// hoisted capsule through an overlay presented out of it.
  bool get isPresenting => _emptied;

  /// Notifies when [isPresenting] changes.
  ///
  /// Deferred past a build in progress exactly as the owning trigger is
  /// notified, so a listener may rebuild from it.
  Listenable get presentationChanges => _notifier;

  /// The trigger's rect in global coordinates, or null when it is not currently
  /// laid out.
  Rect? get _rect {
    final renderObject = _key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// Hides the trigger so the morph's anchor blob can stand in for it.
  void _empty() {
    if (_disposed) return;
    _handback = null;
    if (_emptied) return;
    _emptied = true;
    _notify();
  }

  /// Hands the trigger back at the moment the droplet is caught, passing the
  /// parallel recoil and width-splash phase state so the trigger continues
  /// smoothly without a seam after the modal route unmounts.
  void _handBack({
    required Offset travel,
    required double elapsedSeconds,
    required double speedMultiplier,
    required double startWidthProgress,
    required bool disableAnimations,
  }) {
    if (_disposed || !_emptied) return;
    _emptied = false;
    _handback = _MorphHandback(
      travel: travel,
      elapsedSeconds: elapsedSeconds,
      speedMultiplier: speedMultiplier,
      startWidthProgress: startWidthProgress,
      disableAnimations: disableAnimations,
    );
    _notify();
  }

  /// Restores the trigger with no bounce.
  ///
  /// The safety net for a route torn down without the closing morph ever
  /// running — a Navigator reset, a hot restart. Leaving the trigger emptied
  /// would erase a live button.
  void _restore() {
    if (_disposed || !_emptied) return;
    _emptied = false;
    _handback = null;
    _notify();
  }

  void _dispose() {
    _disposed = true;
    _notifier.dispose();
  }

  /// Notifies the trigger without ever marking it dirty mid-build.
  ///
  /// Presenters drive this from their own lifecycle — `didChangeDependencies`
  /// on the way in, `dispose` on the way out — both of which run while the tree
  /// is being built or is locked, where `setState` on the listening trigger is
  /// illegal. Deferring to the end of the frame in those phases costs the
  /// trigger one frame, during which the droplet is still exactly on top of it,
  /// so nothing shows.
  void _notify() {
    final binding = WidgetsBinding.instance;
    final phase = binding.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      binding.addPostFrameCallback((_) {
        if (!_disposed) _notifier.notify();
      });
      return;
    }
    _notifier.notify();
  }
}

/// Internal: returns [anchor]'s current global rect, or null if not laid out.
Rect? morphAnchorRect(GlassMorphAnchor anchor) => anchor._rect;

/// Internal: empties [anchor]'s trigger while the morphing overlay is visible.
void morphAnchorEmpty(GlassMorphAnchor anchor) => anchor._empty();

/// Internal: hands [anchor]'s trigger back with closing recoil/splash state.
void morphAnchorHandBack(
  GlassMorphAnchor anchor, {
  required Offset travel,
  required double elapsedSeconds,
  required double speedMultiplier,
  required double startWidthProgress,
  required bool disableAnimations,
}) =>
    anchor._handBack(
      travel: travel,
      elapsedSeconds: elapsedSeconds,
      speedMultiplier: speedMultiplier,
      startWidthProgress: startWidthProgress,
      disableAnimations: disableAnimations,
    );

/// Internal: restores [anchor]'s trigger immediately without recoil.
void morphAnchorRestore(GlassMorphAnchor anchor) => anchor._restore();

/// Internal: resolves the trigger's global rect from whichever of [morphFrom]
/// or [morphFromRect] the caller supplied, or null when neither was given.
///
/// An anchor whose trigger isn't laid out is a caller mistake, so it asserts
/// in debug; in release it returns null so the caller can fall back gracefully.
Rect? resolveMorphTriggerRect(
  GlassMorphAnchor? morphFrom,
  Rect? morphFromRect, {
  required String callerName,
}) {
  if (morphFromRect != null) return morphFromRect;
  if (morphFrom == null) return null;

  final rect = morphFrom._rect;
  assert(
    rect != null,
    '$callerName(morphFrom:) needs a GlassMorphAnchor whose '
    'GlassMorphTrigger is mounted and laid out. It was not on screen when '
    'presented — pass morphFromRect if the trigger has no render box of its '
    'own.',
  );
  return rect;
}

/// Minimal [ChangeNotifier] subclass exposing [notifyListeners] as [notify], so
/// [GlassMorphAnchor] can hold one instead of being one.
class _AnchorNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// The closing morph's phase clock and trigger state at the instant the trigger
/// catches the returning droplet (~284 ms at `MorphSpeed.normal`).
class _MorphHandback {
  const _MorphHandback({
    required this.travel,
    required this.elapsedSeconds,
    required this.speedMultiplier,
    required this.startWidthProgress,
    required this.disableAnimations,
  });

  /// Trigger centre → overlay centre. Recoil is bounded along this vector.
  final Offset travel;

  /// Speed-scaled elapsed seconds in the close phase when the droplet landed.
  final double elapsedSeconds;

  /// Active `MorphSpeed` multiplier (`0.65` slow, `1.0` normal, `1.35` fast,
  /// `2.5` instant) so the post-route tail matches the morph speed.
  final double speedMultiplier;

  /// Trigger width progress at the start of the close phase (`0.0` when settled
  /// open, `> 0.0` on an interrupted open).
  final double startWidthProgress;

  /// Whether Reduce Motion is active (suppresses post-handoff recoil/splash).
  final bool disableAnimations;
}

/// Wraps the widget a presented glass overlay (such as `GlassModalSheet` or
/// `showGlassConfirmationDialog`) morphs out of, so the trigger can empty
/// itself while the morph runs and take the hit when the droplet comes home.
///
/// The builder receives a [GlassMorphAnchor] to pass as `morphFrom`:
///
/// ```dart
/// GlassMorphTrigger(
///   builder: (context, anchor) => GlassButton(
///     onTap: () => GlassModalSheet.show(
///       context: context,
///       morphFrom: anchor,
///       builder: (context) => const MySheetBody(),
///     ),
///     icon: const Icon(CupertinoIcons.add),
///   ),
/// )
/// ```
///
/// While the overlay is presented the child paints nothing — the morph's anchor
/// blob stands in for it, so the two never appear at once. When the droplet
/// lands, the child is restored and *this widget* runs the rest of the closing
/// bounce on its own ticker, so it keeps easing home after the presented route
/// is gone. The button is tappable throughout that tail, exactly as
/// `GlassMenu`'s trigger is: grabbing it cancels the bounce and opens again.
///
/// Without this wrapper, callers can still pass `morphFromRect` to morph from
/// an explicit rect without hiding the underlying widget.
class GlassMorphTrigger extends StatefulWidget {
  /// Creates a new [GlassMorphTrigger].
  const GlassMorphTrigger({super.key, required this.builder});

  /// Builds the trigger, given the [GlassMorphAnchor] to present with.
  final Widget Function(BuildContext context, GlassMorphAnchor anchor) builder;

  @override
  State<GlassMorphTrigger> createState() => _GlassMorphTriggerState();
}

class _GlassMorphTriggerState extends State<GlassMorphTrigger>
    with SingleTickerProviderStateMixin {
  /// Speed-scaled seconds by which both the parallel close recoil and the
  /// wide-trigger splash have settled.
  static const double _tailEndScaledSeconds = 0.56;

  final GlassMorphAnchor _anchor = GlassMorphAnchor._();

  /// Drives the post-handoff tail of the parallel close recoil and wide-trigger
  /// horizontal splash after the presented route is torn down.
  late final AnimationController _bounce = AnimationController(vsync: this);

  /// Built once, not per build: [AnimatedBuilder] compares listenables by
  /// identity, so merging inline would resubscribe on every rebuild.
  late final Listenable _repaint =
      Listenable.merge([_anchor._notifier, _bounce]);

  /// Vector the current recoil settles along; zero when nothing is bouncing.
  Offset _travel = Offset.zero;
  double _handbackElapsedSeconds = 0.0;
  double _startWidthProgress = 0.0;
  Size? _triggerSize;

  @override
  void initState() {
    super.initState();
    _anchor._notifier.addListener(_onAnchorChanged);
  }

  @override
  void dispose() {
    _anchor._notifier.removeListener(_onAnchorChanged);
    _anchor._dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _onAnchorChanged() {
    if (!mounted) return;
    final handback = _anchor._handback;
    if (_anchor._emptied ||
        handback == null ||
        handback.disableAnimations ||
        handback.travel == Offset.zero ||
        handback.elapsedSeconds >= _tailEndScaledSeconds) {
      // A fresh open cancels any bounce still running — including one the user
      // interrupted by tapping the button mid-swing — and so does a plain
      // restore or Reduce Motion presentation.
      _bounce.stop();
      if (_travel != Offset.zero) setState(() => _travel = Offset.zero);
      return;
    }

    final remainingScaled = _tailEndScaledSeconds - handback.elapsedSeconds;
    final remainingWallSeconds =
        remainingScaled / math.max(0.1, handback.speedMultiplier);

    setState(() {
      _travel = handback.travel;
      _handbackElapsedSeconds = handback.elapsedSeconds;
      _startWidthProgress = handback.startWidthProgress;
      _triggerSize = _anchor._rect?.size;
    });

    _bounce
      ..duration = Duration(
        microseconds:
            (remainingWallSeconds * Duration.microsecondsPerSecond).round(),
      )
      ..forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repaint,
      // The consumer's trigger is built here, not inside the builder below, so
      // the bounce repaints it without rebuilding their subtree every frame.
      child: KeyedSubtree(
        key: _anchor._key,
        child: widget.builder(context, _anchor),
      ),
      builder: (context, child) {
        // Opacity is toggled between 0 and 1 outright, never animated: a glass
        // surface's backdrop pass renders fully or not at all, so a partial
        // fade pops. The morph's anchor blob covers the visual transition.
        final emptied = _anchor._emptied;
        final bool tailActive = !emptied && _bounce.isAnimating;

        Offset offset = Offset.zero;
        double scaleX = 1.0;
        double scaleY = 1.0;

        if (tailActive && _travel != Offset.zero) {
          final scaledElapsed = _handbackElapsedSeconds +
              (_tailEndScaledSeconds - _handbackElapsedSeconds) * _bounce.value;
          offset = LiquidMorphPhysics.recoilOffsetForElapsed(
            travel: _travel,
            elapsedSeconds: scaledElapsed,
          );
          final impactScale = LiquidMorphPhysics.impactScaleForElapsed(
            travel: _travel,
            elapsedSeconds: scaledElapsed,
          );
          final size = _triggerSize;
          final bool isWide = size != null && size.width > size.height * 1.15;
          final double widthRatio;
          if (isWide) {
            final widthProgress =
                LiquidMorphPhysics.closeTriggerWidthForElapsed(
              scaledElapsed,
              startWidthProgress: _startWidthProgress,
            );
            final compact = size.shortestSide;
            widthRatio = ((compact + (size.width - compact) * widthProgress) /
                    size.width)
                .clamp(0.90, 1.04);
          } else {
            widthRatio = 1.0;
          }
          // Never affine-squash wide trigger text below 0.90 even when an
          // interrupted open reverses early with small startWidthProgress.
          scaleX = isWide
              ? (impactScale * widthRatio).clamp(0.90, 1.04)
              : impactScale * widthRatio;
          scaleY = impactScale;
        }

        Widget content = Opacity(
          opacity: emptied ? 0.0 : 1.0,
          child: IgnorePointer(ignoring: emptied, child: child),
        );

        if (scaleX != 1.0 || scaleY != 1.0) {
          content = Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            alignment: Alignment.center,
            child: content,
          );
        }

        return Transform.translate(
          offset: offset,
          child: content,
        );
      },
    );
  }
}
