part of '../glass_popover.dart';

class _GlassPopoverState extends State<GlassPopover>
    with TickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final GlassMorphController _morphController;

  /// Ramps the backdrop blur from `0` → [GlassPopover.settings]'s blur over the
  /// opening morph, so the expensive full-strength [BackdropFilter] is not paid
  /// on the cheap early frames (see [GlassPopover.blurRampDuration]).
  ///
  /// Driven independently of [_morphController] so the blur follows a clean,
  /// monotonic ease to full strength instead of wobbling with the morph
  /// spring's underdamped overshoot. Held at `1.0` (full blur, no animation)
  /// when the ramp is disabled or reduced-motion is active.
  late final AnimationController _blurRamp;
  late final Listenable _overlayListenable;

  Size? _triggerSize;
  double? _triggerBorderRadius;
  Offset _triggerGlobalPosition = Offset.zero;
  Offset _triggerOverlayPosition = Offset.zero;
  double _horizontalOffset = 0.0;
  double _verticalOffset = 0.0;

  Alignment _morphAlignment = Alignment.topLeft;

  // Mid-flight interruption C0 continuity state (zero when starting from rest).
  Rect? _lastPlatterRect;
  double? _lastPlatterRadius;
  Offset _platterInterruptCenterDelta = Offset.zero;
  Offset _platterInterruptSizeDelta = Offset.zero;
  double _platterInterruptRadiusDelta = 0.0;

  void _resetInterruptState() {
    _lastPlatterRect = null;
    _lastPlatterRadius = null;
    _platterInterruptCenterDelta = Offset.zero;
    _platterInterruptSizeDelta = Offset.zero;
    _platterInterruptRadiusDelta = 0.0;
  }

  /// Measured intrinsic height of the popover content.
  /// Only used when [widget.popoverHeight] is null.
  double? _measuredContentHeight;

  /// True once the first measurement pass has fired for the current open cycle,
  /// so we never queue a second [postFrameCallback] while the first is still
  /// pending or after measurement has settled.
  bool _contentMeasured = false;

  /// Cached widget subtree from [widget.contentBuilder].
  ///
  /// Set exactly once in [_openPopover] and again in [didUpdateWidget] when the
  /// widget configuration changes while the popover is showing. It is NEVER
  /// mutated inside [build] — that would violate Flutter's purity contract.
  Widget? _cachedContent;

  /// Key used to measure the intrinsic height of the content subtree.
  final GlobalKey _contentKey = GlobalKey();

  /// Guards against stacking multiple post-frame re-measure callbacks when the
  /// live content reports several size changes within one frame.
  bool _remeasureScheduled = false;

  /// Re-measures the live content after it changed size while the popover is
  /// open (e.g. a row growing taller after a state toggle) and grows/shrinks
  /// the popover to match, instead of overflowing the frozen initial height.
  void _scheduleRemeasure() {
    if (_remeasureScheduled || !_contentMeasured) return;
    _remeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remeasureScheduled = false;
      if (!mounted || !_contentMeasured) return;
      final renderBox =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;
      final newHeight = renderBox.size.height;
      if (_measuredContentHeight != newHeight) {
        setState(() {
          _measuredContentHeight = newHeight;
          _updatePositionAndClamping();
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Alignment helper
  // ---------------------------------------------------------------------------

  Alignment? _getAlignment(GlassMenuAlignment align) {
    switch (align) {
      case GlassMenuAlignment.none:
        return null;
      case GlassMenuAlignment.topLeft:
        return Alignment.topLeft;
      case GlassMenuAlignment.topCenter:
        return Alignment.topCenter;
      case GlassMenuAlignment.topRight:
        return Alignment.topRight;
      case GlassMenuAlignment.centerLeft:
        return Alignment.centerLeft;
      case GlassMenuAlignment.center:
        return Alignment.center;
      case GlassMenuAlignment.centerRight:
        return Alignment.centerRight;
      case GlassMenuAlignment.bottomLeft:
        return Alignment.bottomLeft;
      case GlassMenuAlignment.bottomCenter:
        return Alignment.bottomCenter;
      case GlassMenuAlignment.bottomRight:
        return Alignment.bottomRight;
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _blurRamp = AnimationController(
      vsync: this,
      // A valid non-zero duration for the controller even when the ramp is
      // disabled (Duration.zero) — in that case it is never driven, just held
      // at full. The real duration is (re)applied in [_startMorphOpen].
      duration: widget.blurRampDuration > Duration.zero
          ? widget.blurRampDuration
          : const Duration(milliseconds: 260),
      // Start full so any paint before the first open (or a disabled ramp) is
      // never under-blurred; [_startMorphOpen] forces it back to 0 on open.
      value: 1.0,
    );
    _morphController = GlassMorphController(
      vsync: this,
      speed: widget.morphSpeed,
    )..verticalOnlyRecoil = true;
    _overlayListenable = Listenable.merge([
      _morphController.animation,
      _blurRamp,
    ]);
    _morphController.addListener(() {
      // Hide the overlay only once the closing morph — including the parallel
      // trigger recoil and wide-trigger splash (~550 ms) — has fully settled.
      if (_overlayController.isShowing &&
          _contentMeasured &&
          !_morphController.isShowing &&
          _morphController.status != AnimationStatus.forward) {
        if (SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _overlayController.isShowing &&
                !_morphController.isShowing) {
              _overlayController.hide();
              _blurRamp.value = 0.0;
              _resetInterruptState();
              setState(() {
                _horizontalOffset = 0.0;
                _verticalOffset = 0.0;
                _measuredContentHeight = null;
                _contentMeasured = false;
                _cachedContent = null;
              });
            }
          });
        } else {
          _overlayController.hide();
          // Reset per-open-cycle state so stale values from a previous position
          // never bleed into the next open cycle.
          // Reset the blur ramp to sharp so the next open blooms in from 0 again
          // (it was frozen mid-value by _closePopover, not wound back).
          _blurRamp.value = 0.0;
          _resetInterruptState();
          setState(() {
            _horizontalOffset = 0.0;
            _verticalOffset = 0.0;
            _measuredContentHeight = null;
            _contentMeasured = false;
            _cachedContent = null;
          });
        }
      }
    });
  }

  List<ModalRoute<dynamic>> _routes = const <ModalRoute<dynamic>>[];

  @override
  void dispose() {
    widget.controller?._detach(this);
    _removeRouteListeners();
    _routes = const [];
    _blurRamp.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync the reduced-motion accessibility flag to the morph controller.
    _morphController.setDisableAnimations(
      GlassAccessibilityData.of(context).reduceMotion,
    );
    _updateRouteListener();
  }

  List<ModalRoute<dynamic>> _findAncestorRoutes() {
    final routes = <ModalRoute<dynamic>>[];
    final visited = <ModalRoute<dynamic>>{};
    ModalRoute<dynamic>? route = ModalRoute.of(context);
    while (route != null && visited.add(route)) {
      routes.add(route);
      final nav = route.navigator;
      if (nav == null || !nav.mounted) break;
      route = ModalRoute.of(nav.context);
    }
    return routes;
  }

  void _updateRouteListener() {
    final currentRoutes = _findAncestorRoutes();
    if (!_routesEqual(_routes, currentRoutes)) {
      _removeRouteListeners();
      _routes = currentRoutes;
      _addRouteListeners();
    }
  }

  static bool _routesEqual(
    List<ModalRoute<dynamic>> a,
    List<ModalRoute<dynamic>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _addRouteListeners() {
    for (final route in _routes) {
      route.secondaryAnimation
          ?.addStatusListener(_handleSecondaryAnimationStatus);
      route.animation?.addStatusListener(_handlePrimaryAnimationStatus);
    }
  }

  void _removeRouteListeners() {
    for (final route in _routes) {
      route.secondaryAnimation
          ?.removeStatusListener(_handleSecondaryAnimationStatus);
      route.animation?.removeStatusListener(_handlePrimaryAnimationStatus);
    }
  }

  void _handleSecondaryAnimationStatus(AnimationStatus status) {
    if (!_overlayController.isShowing) return;
    if (status == AnimationStatus.forward) {
      _dismissImmediately();
    }
  }

  void _handlePrimaryAnimationStatus(AnimationStatus status) {
    if (!_overlayController.isShowing) return;
    if (status == AnimationStatus.reverse) {
      _dismissImmediately();
    }
  }

  void _dismissImmediately() {
    if (!_overlayController.isShowing && _morphController.value == 0.0) {
      return;
    }
    // Never call hide(), reset(), or setState() synchronously during
    // persistent callbacks (e.g. declarative Navigator.pages / go_router updates).
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dismissImmediately();
        }
      });
      return;
    }
    final wasClosing = _morphController.isClosing;
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    _morphController.reset();
    _blurRamp.stop();
    _blurRamp.value = 0.0;
    _resetInterruptState();
    _horizontalOffset = 0.0;
    _verticalOffset = 0.0;
    _measuredContentHeight = null;
    _contentMeasured = false;
    _cachedContent = null;
    if (!wasClosing) {
      widget.onClose?.call();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(GlassPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    // If the popover is showing and the widget configuration changed, refresh
    // the cached content tree so the user sees up-to-date data. This is the
    // correct lifecycle hook — never do this inside build().
    if (_overlayController.isShowing &&
        (oldWidget.contentBuilder != widget.contentBuilder ||
            oldWidget.popoverWidth != widget.popoverWidth ||
            oldWidget.popoverHeight != widget.popoverHeight)) {
      setState(() {
        _cachedContent = widget.contentBuilder(context, _closePopover);
      });
    }
    if (oldWidget.morphSpeed != widget.morphSpeed) {
      _morphController.speed = widget.morphSpeed;
    }
    // If the blur ramp params changed while a ramp is actively running, apply
    // the new duration immediately so the current cycle uses it. The new curve
    // is picked up automatically on the next _blurFactor read (it reads
    // widget.blurRampCurve directly). No restart needed — the controller
    // continues from its current value with the updated duration.
    if (oldWidget.blurRampDuration != widget.blurRampDuration ||
        oldWidget.blurRampCurve != widget.blurRampCurve) {
      if (_blurRamp.isAnimating) {
        _blurRamp.duration = widget.blurRampDuration > Duration.zero
            ? widget.blurRampDuration
            : const Duration(milliseconds: 260);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Mirror the GlassMenu structure exactly:
    //   AnimatedBuilder (top-level, no render object) →
    //     builder returns Stack([trigger, OverlayPortal])
    //
    // This matters for _openPopover(): context.findRenderObject() traverses
    // down from the GlassPopover element. Because AnimatedBuilder has NO render
    // object, it keeps descending into the builder's returned Stack. That Stack
    // is always sized to the trigger button, so localToGlobal(Offset.zero) gives
    // the correct global position of the trigger on screen.
    //
    // If we return an outer Stack from build() instead, findRenderObject() stops
    // at the outer Stack, whose origin can be corrupted by the OverlayPortal
    // sibling when the overlay is visible.
    //
    // The trigger is passed as AnimatedBuilder's `child` (not rebuilt inside
    // the builder closure) so it is stable across animation ticks.
    final Widget triggerContent = widget.triggerBuilder != null
        ? widget.triggerBuilder!(context, _togglePopover)
        // A plain trigger (an icon, a text) gets the button role here; its
        // text, if any, merges into this node as the name.
        : Semantics(
            container: true,
            button: true,
            label: widget.semanticLabel,
            child: GestureDetector(
              onTap: _togglePopover,
              child: widget.trigger,
            ),
          );

    return AnimatedBuilder(
      animation: _morphController.animation,
      builder: (context, child) {
        final rawValue = _morphController.value;
        final clampedValue = rawValue.clamp(0.0, 1.0);

        // Block trigger taps while the popover is meaningfully open (not closing).
        final isPopoverBlocking = _overlayController.isShowing &&
            !_morphController.isClosing &&
            rawValue > 0.8;

        final effectiveQuality = GlassThemeHelpers.resolveQuality(
          context,
          widgetQuality: widget.quality,
          fallback: GlassThemeHelpers.nativeStyleQuality(context),
        );
        final isPremiumQuality = effectiveQuality == GlassQuality.premium &&
            !widget.platformViewBackdrop;

        final tw = _triggerSize?.width ?? 44.0;
        final th = _triggerSize?.height ?? 44.0;
        final compactCore = math.min(tw, th);

        final LiquidMorphState? liveState =
            (_overlayController.isShowing && _contentMeasured)
                ? _computeCurrentMorphState(tw: tw, th: th)
                : null;

        // Strictly binary trigger opacity (0.0 or 1.0) — never fractional, so
        // no offscreen saveLayer is ever pushed above a live BackdropFilter.
        // On premium close, Blob A carries the full 0..~283ms SDF capsule merge
        // until !isPlatterActive; on non-premium close (where Blob A is
        // suppressed), the real trigger swaps back in once clampedValue <= 0.14
        // (when triggerWidthProgress >= 0.88 and platterOpacity dissolves).
        final bool hideTrigger = liveState != null &&
            liveState.isPlatterActive &&
            (_morphController.isClosing
                ? (isPremiumQuality || clampedValue > 0.14)
                : (isPremiumQuality || clampedValue > 0.12));
        final double triggerOpacity = hideTrigger ? 0.0 : 1.0;

        // Parallel close recoil (~183ms peak) and tactile impact compression,
        // plus centered horizontal width splash (~398ms peak) on wide triggers.
        final double pushDx = (liveState != null && _morphController.isClosing)
            ? liveState.triggerPushDx
            : 0.0;
        final double pushDy = (liveState != null && _morphController.isClosing)
            ? liveState.triggerPushDy
            : 0.0;
        final double impactScale =
            (liveState != null && _morphController.isClosing)
                ? liveState.triggerImpactScale
                : 1.0;
        final double widthRatio = (liveState != null &&
                _morphController.isClosing &&
                !hideTrigger &&
                tw > th * 1.15)
            ? ((compactCore +
                        (tw - compactCore) * liveState.triggerWidthProgress) /
                    tw)
                .clamp(0.90, 1.04)
            : 1.0;
        final double scaleX = tw > th * 1.15
            ? (impactScale * widthRatio).clamp(0.90, 1.04)
            : impactScale * widthRatio;
        final double scaleY = impactScale;

        final outer = GlassMaterializeScope.maybeOf(context);

        final bool hasTransform =
            pushDx != 0.0 || pushDy != 0.0 || scaleX != 1.0 || scaleY != 1.0;

        Widget triggerWidget = Opacity(
          opacity: triggerOpacity,
          child: GlassMaterializeScope(
            glassProgress: triggerOpacity * (outer?.glassProgress ?? 1.0),
            contentOpacity: outer?.contentOpacity ?? 1.0,
            contentSigma: outer?.contentSigma ?? 0.0,
            child: IgnorePointer(
              ignoring: isPopoverBlocking,
              child: child, // triggerContent
            ),
          ),
        );

        if (scaleX != 1.0 || scaleY != 1.0) {
          triggerWidget = Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            alignment: Alignment.center,
            child: triggerWidget,
          );
        }

        if (pushDx != 0.0 || pushDy != 0.0) {
          triggerWidget = Transform.translate(
            offset: Offset(pushDx, pushDy),
            child: triggerWidget,
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Trigger ────────────────────────────────────────────────────
            // Only apply Transform/Opacity/IgnorePointer layers when actually needed
            // to prevent unnecessary compositing layers that cause BackdropFilter
            // flickering (Premium quality) during scroll.
            hasTransform
                ? triggerWidget
                : triggerOpacity < 1.0
                    ? triggerWidget
                    : isPopoverBlocking
                        ? IgnorePointer(
                            ignoring: true,
                            child: child,
                          )
                        : child ??
                            const SizedBox
                                .shrink(), // Raw trigger when completely idle

            // ── Overlay portal ─────────────────────────────────────────────
            OverlayPortal(
              controller: _overlayController,
              overlayLocation: OverlayChildLocation.nearestOverlay,
              overlayChildBuilder: _buildMorphingOverlay,
            ),
          ],
        );
      },
      child: triggerContent,
    );
  }

  // ---------------------------------------------------------------------------
  // Popover open / close
  // ---------------------------------------------------------------------------

  void _togglePopover() {
    if (_overlayController.isShowing &&
        !_morphController.isClosing &&
        _morphController.value > 0.1) {
      _closePopover();
    } else {
      _openPopover();
    }
  }

  // ---------------------------------------------------------------------------
  // Blur ramp (see GlassPopover.blurRampDuration)
  // ---------------------------------------------------------------------------

  /// Whether the backdrop-blur ramp should run for this open cycle. Disabled
  /// when the caller opts out ([GlassPopover.blurRampDuration] == zero) or when
  /// reduced-motion is active — in both cases the blur is shown at full
  /// strength immediately.
  bool get _blurRampEnabled =>
      widget.blurRampDuration > Duration.zero &&
      !_morphController.disableAnimations;

  /// The current fraction (`0` → `1`) of [GlassPopover.settings]'s blur to
  /// apply this frame. `1.0` means full strength.
  double get _blurFactor {
    if (!_blurRampEnabled) return 1.0;
    return widget.blurRampCurve.transform(_blurRamp.value.clamp(0.0, 1.0));
  }

  /// Launches the morph and, in lock-step, the blur ramp. Called at every point
  /// the morph actually starts opening (immediately for fixed-height popovers,
  /// or after the intrinsic-height measurement pass).
  void _startMorphOpen() {
    final bool hasPrev = _overlayController.isShowing &&
        _morphController.isShowing &&
        _lastPlatterRect != null &&
        _morphController.value > 0.005 &&
        _morphController.value < 0.995;
    final Rect? prevRect = hasPrev ? _lastPlatterRect : null;
    final double? prevRadius = hasPrev ? _lastPlatterRadius : null;

    _morphController.open();
    if (prevRect != null) {
      final nextBase = _computeBasePopoverGeometry();
      if (nextBase != null) {
        _platterInterruptCenterDelta = prevRect.center - nextBase.rect.center;
        _platterInterruptSizeDelta = Offset(
          prevRect.width - nextBase.rect.width,
          prevRect.height - nextBase.rect.height,
        );
        _platterInterruptRadiusDelta =
            (prevRadius ?? nextBase.radius) - nextBase.radius;
      }
    } else {
      _platterInterruptCenterDelta = Offset.zero;
      _platterInterruptSizeDelta = Offset.zero;
      _platterInterruptRadiusDelta = 0.0;
    }

    if (_blurRampEnabled) {
      _blurRamp.duration = widget.blurRampDuration;
      if (hasPrev) {
        // Mid-close reversal: continue ramping from the frozen blur value
        // instead of snapping back to 0.0 while the platter is still large.
        _blurRamp.forward();
      } else {
        _blurRamp.forward(from: 0.0);
      }
    } else {
      // No ramp — show the blur at full strength from the first painted frame.
      _blurRamp.value = 1.0;
    }
  }

  void _closePopover() {
    if (!mounted ||
        !_overlayController.isShowing ||
        _morphController.isClosing) {
      return;
    }
    // If close() is called before the intrinsic-height Offstage measurement
    // pass finishes (e.g. open() followed immediately by close() in the same
    // frame), cancel the pending open cleanly instead of entering a close
    // morph that cannot settle to hide().
    if (!_contentMeasured) {
      _overlayController.hide();
      _blurRamp.stop();
      _blurRamp.value = 0.0;
      _resetInterruptState();
      _horizontalOffset = 0.0;
      _verticalOffset = 0.0;
      _measuredContentHeight = null;
      _cachedContent = null;
      widget.onClose?.call();
      setState(() {});
      return;
    }
    final bool hasPrev = _morphController.isShowing &&
        _lastPlatterRect != null &&
        _morphController.value > 0.005 &&
        _morphController.value < 0.995;
    final Rect? prevRect = hasPrev ? _lastPlatterRect : null;
    final double? prevRadius = hasPrev ? _lastPlatterRadius : null;

    // Freeze the blur where it is for the collapse. Ramping it back down here
    // would race the morph and read as the blur "popping off" while the blob is
    // still visibly shrinking; holding it keeps the close visually coherent.
    // It is reset to 0 when the overlay finally hides (see the initState
    // listener), so the next open still ramps from sharp.
    _blurRamp.stop();
    _morphController.close();
    if (prevRect != null) {
      final nextBase = _computeBasePopoverGeometry();
      if (nextBase != null) {
        _platterInterruptCenterDelta = prevRect.center - nextBase.rect.center;
        _platterInterruptSizeDelta = Offset(
          prevRect.width - nextBase.rect.width,
          prevRect.height - nextBase.rect.height,
        );
        _platterInterruptRadiusDelta =
            (prevRadius ?? nextBase.radius) - nextBase.radius;
      }
    } else {
      _platterInterruptCenterDelta = Offset.zero;
      _platterInterruptSizeDelta = Offset.zero;
      _platterInterruptRadiusDelta = 0.0;
    }
    widget.onClose?.call();
  }

  void _openPopover() {
    if (!mounted ||
        (_overlayController.isShowing && !_morphController.isClosing)) {
      return;
    }
    _updateRouteListener();
    // context.findRenderObject() works correctly here because build() returns
    // AnimatedBuilder at the top level. AnimatedBuilder has no render object of
    // its own, so the traversal descends into the builder's returned Stack,
    // which is always sized to the trigger button. localToGlobal therefore gives
    // the trigger's actual screen position.
    final renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.hasSize) return;

    _triggerSize = renderBox.size;
    _triggerBorderRadius = _triggerSize!.shortestSide / 2.0;
    _triggerGlobalPosition = renderBox.localToGlobal(Offset.zero);
    final overlay = Overlay.maybeOf(context);
    final overlayBox = overlay?.context.findRenderObject() as RenderBox?;
    _triggerOverlayPosition = overlayBox != null
        ? renderBox.localToGlobal(Offset.zero, ancestor: overlayBox)
        : _triggerGlobalPosition;

    // Build the content widget exactly once for this open cycle. All
    // subsequent frames read _cachedContent; didUpdateWidget refreshes it
    // if the parent rebuilds with changed props while the popover is open.
    _cachedContent = widget.contentBuilder(context, _closePopover);

    // If popoverHeight is explicitly provided (or we are reversing a live
    // mid-close morph whose intrinsic height was already measured), skip the
    // Offstage pass so mid-morph reopen stays C0-continuous.
    _contentMeasured = widget.popoverHeight != null ||
        (_overlayController.isShowing && _measuredContentHeight != null);

    setState(() {
      if (_contentMeasured) {
        _updatePositionAndClamping();
      }
      if (!_overlayController.isShowing) {
        _overlayController.show();
      }
    });

    if (_contentMeasured) {
      _startMorphOpen();
    }
    widget.onOpen?.call();
  }

  // ---------------------------------------------------------------------------
  // Layout helpers
  // ---------------------------------------------------------------------------

  /// Returns the maximum height the popover may occupy, bounded by the
  /// safe-area-inset screen height.
  ///
  /// Falls back to a finite sentinel (800 dp) instead of [double.infinity]
  /// so downstream lerp / arithmetic never yields NaN or Infinity when
  /// [MediaQuery] is unavailable (e.g. in some test environments).
  double _getMaxPopoverHeight([EdgeInsets? precomputedPadding]) {
    final screenSize = MediaQuery.maybeSizeOf(context);
    if (screenSize == null) return 800.0;

    final screenHeight = screenSize.height;
    final insets = precomputedPadding ?? _viewInsets();
    final double safeTop = widget.screenPadding.top + insets.top;
    final double safeBottom = widget.screenPadding.bottom + insets.bottom;
    return math.max(0.0, screenHeight - safeTop - safeBottom);
  }

  /// Computes [EdgeInsets] from the platform view padding once so callers
  /// that need both max-height and edge clamping share the same values.
  EdgeInsets _viewInsets() {
    final flutterView = View.of(context);
    return EdgeInsets.fromViewPadding(
        flutterView.padding, flutterView.devicePixelRatio);
  }

  double _effectivePopoverHeight([EdgeInsets? precomputedPadding]) {
    if (widget.popoverHeight != null) return widget.popoverHeight!;
    final maxH = _getMaxPopoverHeight(precomputedPadding);
    // By the time the morph animation uses this value, _measuredContentHeight
    // is guaranteed to be populated via the Offstage measurement pass.
    return math.min(_measuredContentHeight ?? 0.0, maxH);
  }

  /// Recomputes [_morphAlignment], [_horizontalOffset], and [_verticalOffset]
  /// from the current trigger geometry and screen metrics.
  ///
  /// Must only be called when [_triggerSize] is non-null.
  /// Safe to call inside a [setState] callback; it only mutates fields and
  /// never calls [setState] itself.
  LiquidMorphState _computeCurrentMorphState({
    required double tw,
    required double th,
    double? precomputedPopoverHeight,
  }) {
    final compactCore = math.min(tw, th);
    final popoverWidth = widget.popoverWidth;
    final popoverHeight = precomputedPopoverHeight ?? _effectivePopoverHeight();
    final travelDx =
        -_morphAlignment.x * (popoverWidth - tw) * 0.5 + _horizontalOffset;
    final travelDy =
        -_morphAlignment.y * (popoverHeight - th) * 0.5 + _verticalOffset;
    final scaleDelta = LiquidMorphPhysics.computeScaleDelta(
      sourceSize: Size(compactCore, compactCore),
      targetSize: Size(popoverWidth, math.max(1.0, popoverHeight)),
    );
    return _morphController.computeState(
      finalDx: travelDx,
      finalDy: travelDy,
      scaleDelta: scaleDelta,
      adaptiveDamping: true,
    );
  }

  void _updatePositionAndClamping() {
    if (_triggerSize == null) return;

    final position = _triggerGlobalPosition;
    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final triggerCenterX = position.dx + tw * 0.5;
    final screenSize = MediaQuery.maybeSizeOf(context);
    final screenWidth = screenSize?.width ?? double.infinity;
    final screenHeight = screenSize?.height ?? double.infinity;

    // Compute view insets once and share between max-height and clamping.
    final insets = _viewInsets();
    final popoverHeight = _effectivePopoverHeight(insets);

    // 1. Determine alignment (auto vs. manual)
    final stripAlignment = verticalBarPresentationAlignment(
      context,
      position & _triggerSize!,
    );
    if ((widget.alignment == null ||
            widget.alignment == GlassMenuAlignment.none) &&
        stripAlignment != null) {
      // From iPhone Duo's vertical bar strip: towards the content.
      _morphAlignment = stripAlignment;
    } else if (widget.alignment == null ||
        widget.alignment == GlassMenuAlignment.none) {
      final spaceBelow = screenHeight.isFinite
          ? screenHeight - (position.dy + th)
          : double.infinity;
      final spaceAbove = screenHeight.isFinite ? position.dy : double.infinity;

      final shouldFlipVertical =
          spaceBelow < popoverHeight && spaceAbove > popoverHeight;

      final isHorizontallyCentered = screenWidth.isFinite &&
          (triggerCenterX - screenWidth * 0.5).abs() <=
              math.max(24.0, screenWidth * 0.08);
      final isRightHalf =
          screenWidth.isFinite && triggerCenterX > screenWidth * 0.5;

      if (isHorizontallyCentered) {
        _morphAlignment =
            shouldFlipVertical ? Alignment.bottomCenter : Alignment.topCenter;
      } else {
        _morphAlignment = shouldFlipVertical
            ? (isRightHalf ? Alignment.bottomRight : Alignment.bottomLeft)
            : (isRightHalf ? Alignment.topRight : Alignment.topLeft);
      }
    } else {
      _morphAlignment = _getAlignment(widget.alignment!) ?? Alignment.center;
    }

    // 2. Edge clamping: compute offsets to keep the popover within the safe area
    double hOffset = 0.0;
    double vOffset = 0.0;

    if (widget.autoAdjustToScreen) {
      final double safeTop = widget.screenPadding.top + insets.top;
      final double safeBottom = widget.screenPadding.bottom + insets.bottom;
      // The strip's inset is no bar to a popover opened out of the strip,
      // which natively lies over the item it came from.
      final double safeLeft = widget.screenPadding.left +
          (stripAlignment == null ? insets.left : 0.0);
      final double safeRight = widget.screenPadding.right +
          (stripAlignment == null ? insets.right : 0.0);

      final double targetX = position.dx + (1 + _morphAlignment.x) * tw / 2;
      final double targetY = position.dy + (1 + _morphAlignment.y) * th / 2;
      final double popoverLeft =
          targetX - (1 + _morphAlignment.x) * widget.popoverWidth / 2;
      final double popoverTop =
          targetY - (1 + _morphAlignment.y) * popoverHeight / 2;

      // Horizontal
      if (popoverLeft < safeLeft) {
        hOffset = safeLeft - popoverLeft;
      } else if (screenWidth.isFinite &&
          popoverLeft + widget.popoverWidth > screenWidth - safeRight) {
        hOffset =
            (screenWidth - safeRight) - (popoverLeft + widget.popoverWidth);
      }

      // Vertical
      if (popoverTop < safeTop) {
        vOffset = safeTop - popoverTop;
      } else if (screenHeight.isFinite &&
          popoverTop + popoverHeight > screenHeight - safeBottom) {
        vOffset = (screenHeight - safeBottom) - (popoverTop + popoverHeight);
      }
    }

    _horizontalOffset = hOffset;
    _verticalOffset = vOffset;
  }

  ({
    Rect rect,
    double radius,
    double blobADriftX,
    double blobADriftY,
  })? _computeBasePopoverGeometry() {
    if (_triggerSize == null || !_contentMeasured) return null;
    final rawValue = _morphController.value;
    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final compactCore = math.min(tw, th);
    final popoverWidth = widget.popoverWidth;
    final popoverHeight = _effectivePopoverHeight();
    final anchorAlignX = (1.0 + _morphAlignment.x) * 0.5;
    final anchorAlignY = (1.0 + _morphAlignment.y) * 0.5;
    final triggerCenterX = _triggerOverlayPosition.dx + tw * 0.5;
    final triggerCenterY = _triggerOverlayPosition.dy + th * 0.5;
    final triggerCenter = Offset(triggerCenterX, triggerCenterY);
    final restingLeft = _triggerOverlayPosition.dx +
        anchorAlignX * (tw - popoverWidth) +
        _horizontalOffset;
    final restingTop = _triggerOverlayPosition.dy +
        anchorAlignY * (th - popoverHeight) +
        _verticalOffset;
    final restingRect =
        Rect.fromLTWH(restingLeft, restingTop, popoverWidth, popoverHeight);
    final travelDx = restingRect.center.dx - triggerCenterX;
    final travelDy = restingRect.center.dy - triggerCenterY;
    final scaleDelta = LiquidMorphPhysics.computeScaleDelta(
      sourceSize: Size(compactCore, compactCore),
      targetSize: Size(popoverWidth, math.max(1.0, popoverHeight)),
    );
    final state = _morphController.computeState(
      finalDx: travelDx,
      finalDy: travelDy,
      scaleDelta: scaleDelta,
      adaptiveDamping: true,
    );
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );
    final bool isPremium = !widget.platformViewBackdrop &&
        effectiveQuality == GlassQuality.premium &&
        ImageFilter.isShaderFilterSupported;

    if (_morphController.isClosing && isPremium) {
      final closedGeo = LiquidMorphPhysics.computeClosingTeardropGeometry(
        rawValue: rawValue,
        pathT: state.pathT,
        triggerCenter: triggerCenter,
        triggerSize: Size(tw, th),
        restingRect: restingRect,
        targetRadius: widget.popoverBorderRadius,
        effectivePush: Offset(state.triggerPushDx, state.triggerPushDy),
        elapsedSeconds: _morphController.phaseElapsedSeconds,
        closeStartProgress: _morphController.closeStartProgress,
        alignX: _morphAlignment.x,
        disableAnimations: _morphController.disableAnimations,
      );
      return (
        rect: closedGeo.rect,
        radius: closedGeo.borderRadius,
        blobADriftX: 0.0,
        blobADriftY: 0.0,
      );
    }

    final double triggerRadius = _triggerBorderRadius ?? (compactCore * 0.5);
    if (_morphController.isClosing) {
      final sizeProgress = ((state.pathT + state.sizeT) * 0.5).clamp(0.0, 1.0);
      final w =
          math.max(1.0, lerpDouble(compactCore, popoverWidth, sizeProgress)!);
      final h =
          math.max(1.0, lerpDouble(compactCore, popoverHeight, sizeProgress)!);
      final closePathT = state.pathT.clamp(0.0, 1.0);
      final recoilCatch = 1.0 - rawValue.clamp(0.0, 1.0);
      final cx = triggerCenterX +
          travelDx * closePathT +
          state.triggerPushDx * recoilCatch;
      final cy = triggerCenterY +
          travelDy * closePathT +
          state.triggerPushDy * recoilCatch;
      final r = LiquidMorphPhysics.computeCornerRadius(
        currentSize: Size(w, h),
        triggerRadius: triggerRadius,
        targetRadius: widget.popoverBorderRadius,
        progress: sizeProgress,
      );
      return (
        rect: Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        radius: r,
        blobADriftX: 0.0,
        blobADriftY: 0.0,
      );
    }

    final sizeProgress = state.sizeT.clamp(0.0, 1.25);
    final w =
        math.max(1.0, lerpDouble(compactCore, popoverWidth, sizeProgress)!);
    final h =
        math.max(1.0, lerpDouble(compactCore, popoverHeight, sizeProgress)!);
    final detachRelease = 1.0 - state.anchorScale * 0.55;
    final effectivePathT =
        state.sizeT + (state.pathT - state.sizeT) * detachRelease;
    double blobLeft = triggerCenterX + travelDx * effectivePathT - w * 0.5;
    double blobTop = triggerCenterY + travelDy * effectivePathT - h * 0.5;
    final blobADriftX = travelDx *
        (state.pathT - state.sizeT) *
        (1.0 - state.anchorScale) *
        0.35;
    final blobADriftY = travelDy *
        (state.pathT - state.sizeT) *
        (1.0 - state.anchorScale) *
        0.35;

    if (widget.autoAdjustToScreen && state.pathT > 1.0) {
      final screenSize = MediaQuery.maybeSizeOf(context);
      final screenWidth = screenSize?.width ?? double.infinity;
      final screenHeight = screenSize?.height ?? double.infinity;
      final insets = _viewInsets();
      final overlayOrigin = _triggerGlobalPosition - _triggerOverlayPosition;
      final minOverlayX =
          widget.screenPadding.left + insets.left - overlayOrigin.dx;
      final maxOverlayX = screenWidth.isFinite
          ? screenWidth -
              widget.screenPadding.right -
              insets.right -
              overlayOrigin.dx
          : double.infinity;
      final minOverlayY =
          widget.screenPadding.top + insets.top - overlayOrigin.dy;
      final maxOverlayY = screenHeight.isFinite
          ? screenHeight -
              widget.screenPadding.bottom -
              insets.bottom -
              overlayOrigin.dy
          : double.infinity;
      if (maxOverlayX.isFinite && maxOverlayX - minOverlayX >= w) {
        blobLeft = blobLeft.clamp(minOverlayX, maxOverlayX - w);
      }
      if (maxOverlayY.isFinite && maxOverlayY - minOverlayY >= h) {
        blobTop = blobTop.clamp(minOverlayY, maxOverlayY - h);
      }
    }
    final r = LiquidMorphPhysics.computeCornerRadius(
      currentSize: Size(w, h),
      triggerRadius: triggerRadius,
      targetRadius: widget.popoverBorderRadius,
      progress: sizeProgress.clamp(0.0, 1.0),
    );
    return (
      rect: Rect.fromLTWH(blobLeft, blobTop, w, h),
      radius: r,
      blobADriftX: blobADriftX,
      blobADriftY: blobADriftY,
    );
  }

  // ---------------------------------------------------------------------------
  // Overlay rendering
  // ---------------------------------------------------------------------------

  Widget _buildMorphingOverlay(BuildContext context) {
    if (_triggerSize == null) return const SizedBox.shrink();

    if (!_contentMeasured) {
      // Invisible measurement pass.
      // Renders the content offstage to allow Flutter's layout engine to
      // synchronously calculate its exact intrinsic height before we launch
      // the morph animation on the very next frame.
      return Offstage(
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: widget.popoverWidth,
          maxWidth: widget.popoverWidth,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Builder(builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted ||
                  !_overlayController.isShowing ||
                  _contentMeasured ||
                  _morphController.isClosing) {
                return;
              }
              final renderBox =
                  _contentKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null && renderBox.hasSize) {
                setState(() {
                  _measuredContentHeight = renderBox.size.height;
                  _contentMeasured = true;
                  _updatePositionAndClamping();
                });
                _startMorphOpen();
              }
            });
            return SizedBox(
              key: _contentKey,
              width: widget.popoverWidth,
              child: _cachedContent ?? const SizedBox.shrink(),
            );
          }),
        ),
      );
    }

    // ── Values computed ONCE per overlay build ──────────────────────────────
    // Hoisted outside AnimatedBuilder so they are never recomputed on every
    // animation tick (60 fps).

    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final compactCore = math.min(tw, th);
    final popoverWidth = widget.popoverWidth;
    final popoverHeight = _effectivePopoverHeight();

    final double anchorAlignX = (1.0 + _morphAlignment.x) * 0.5;
    final double anchorAlignY = (1.0 + _morphAlignment.y) * 0.5;

    final double triggerCenterX = _triggerOverlayPosition.dx + tw * 0.5;
    final double triggerCenterY = _triggerOverlayPosition.dy + th * 0.5;

    final double restingLeft = _triggerOverlayPosition.dx +
        anchorAlignX * (tw - popoverWidth) +
        _horizontalOffset;
    final double restingTop = _triggerOverlayPosition.dy +
        anchorAlignY * (th - popoverHeight) +
        _verticalOffset;

    final double travelDx = (restingLeft + popoverWidth * 0.5) - triggerCenterX;
    final double travelDy = (restingTop + popoverHeight * 0.5) - triggerCenterY;

    final double scaleDelta = LiquidMorphPhysics.computeScaleDelta(
      sourceSize: Size(compactCore, compactCore),
      targetSize: Size(popoverWidth, math.max(1.0, popoverHeight)),
    );

    final double contentAlignX = popoverWidth > 0.0
        ? (((triggerCenterX - restingLeft) / popoverWidth) * 2.0 - 1.0)
            .clamp(-1.0, 1.0)
        : _morphAlignment.x;
    final double contentAlignY = popoverHeight > 0.0
        ? (((triggerCenterY - restingTop) / popoverHeight) * 2.0 - 1.0)
            .clamp(-1.0, 1.0)
        : _morphAlignment.y;
    final Alignment contentAnchor = Alignment(contentAlignX, contentAlignY);

    // InheritedWidget lookups — traverses the element tree; must NOT be inside
    // the AnimatedBuilder's builder closure.
    final effectiveSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: widget.settings,
      fallback: _kDefaultPopoverSettings,
      isOverlayPlatter: true,
    );

    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );

    final bool isPremium = !widget.platformViewBackdrop &&
        effectiveQuality == GlassQuality.premium &&
        ImageFilter.isShaderFilterSupported;

    // LiquidGlassBlendGroup requires a LiquidGlassLayer ancestor, which
    // AdaptiveLiquidGlassLayer only mounts for GlassQuality.premium.
    final bool useBlendGroup = effectiveQuality == GlassQuality.premium &&
        !widget.platformViewBackdrop;

    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;

    // ── Per-frame AnimatedBuilder ────────────────────────────────────────────
    // Listens to BOTH the morph spring and the blur ramp so the backdrop blur
    // repaints as it eases in, independently of where the morph spring is.
    final overlay = AnimatedBuilder(
      animation: _overlayListenable,
      builder: (context, child) {
        final rawValue = _morphController.value;
        final clampedValue = rawValue.clamp(0.0, 1.0);

        final blurFactor = _blurFactor;
        final rampedSettings = blurFactor >= 1.0
            ? effectiveSettings
            : effectiveSettings.copyWith(
                blur: effectiveSettings.blur * blurFactor,
                frost: effectiveSettings.frost * blurFactor,
              );

        final state = _morphController.computeState(
          finalDx: travelDx,
          finalDy: travelDy,
          scaleDelta: scaleDelta,
          adaptiveDamping: true,
        );

        final bool showOverlayLayer =
            !_morphController.isClosing || state.isPlatterActive;

        if (!showOverlayLayer) {
          _lastPlatterRect = null;
          _lastPlatterRadius = null;
          return const SizedBox.shrink();
        }

        final baseGeo = _computeBasePopoverGeometry();
        if (baseGeo == null) return const SizedBox.shrink();

        final double interruptDecay =
            (_platterInterruptCenterDelta != Offset.zero ||
                    _platterInterruptSizeDelta != Offset.zero ||
                    _platterInterruptRadiusDelta != 0.0)
                ? math.exp(-22.0 * _morphController.phaseElapsedSeconds)
                : 0.0;

        final double currentWidth = math.max(
            1.0,
            baseGeo.rect.width +
                _platterInterruptSizeDelta.dx * interruptDecay);
        final double currentHeight = math.max(
            1.0,
            baseGeo.rect.height +
                _platterInterruptSizeDelta.dy * interruptDecay);
        final double shortestHalfNow =
            math.max(0.0, math.min(currentWidth, currentHeight) * 0.5);
        final double currentRadius =
            (baseGeo.radius + _platterInterruptRadiusDelta * interruptDecay)
                .clamp(0.0, shortestHalfNow);
        final Offset effectiveCenter =
            baseGeo.rect.center + _platterInterruptCenterDelta * interruptDecay;
        final double blobLeft = effectiveCenter.dx - currentWidth * 0.5;
        final double blobTop = effectiveCenter.dy - currentHeight * 0.5;
        final double blobADriftX = baseGeo.blobADriftX;
        final double blobADriftY = baseGeo.blobADriftY;

        _lastPlatterRect =
            Rect.fromLTWH(blobLeft, blobTop, currentWidth, currentHeight);
        _lastPlatterRadius = currentRadius;

        final bool isWideTrigger = tw > th * 1.15;
        final double blobAWidth = math.max(
          1.0,
          compactCore + (tw - compactCore) * state.triggerWidthProgress,
        );
        final double blobAHeight = isWideTrigger
            ? math.max(1.0, th)
            : math.max(
                1.0,
                compactCore + (th - compactCore) * state.triggerWidthProgress,
              );
        final double triggerCapRadius =
            _triggerBorderRadius ?? (compactCore * 0.5);
        final double blobARadius = math.min(
          triggerCapRadius,
          math.min(blobAWidth, blobAHeight) * 0.5,
        );

        final bool showBlobA;
        final double blobAScale;
        if (_morphController.isClosing) {
          if (!isPremium || !state.isPlatterActive) {
            showBlobA = false;
            blobAScale = 0.0;
          } else if (isWideTrigger) {
            showBlobA = true;
            blobAScale = state.triggerImpactScale;
          } else {
            final closeBlobAGrow =
                LiquidMorphPhysics.computeCloseBlobAEmergence(
              platterRect: _lastPlatterRect!,
              platterRadius: currentRadius,
              triggerCenter: Offset(
                triggerCenterX + state.triggerPushDx,
                triggerCenterY + state.triggerPushDy,
              ),
              rawValue: rawValue,
            );
            showBlobA = closeBlobAGrow > 0.001;
            blobAScale = closeBlobAGrow * state.triggerImpactScale;
          }
        } else {
          final double openAnchorScale = isWideTrigger
              ? (1.0 - ((clampedValue - 0.25) / 0.35).clamp(0.0, 1.0))
              : state.anchorScale;
          showBlobA = openAnchorScale > 0.20;
          blobAScale = openAnchorScale * state.triggerImpactScale;
        }

        final double layerBlend = (_morphController.isClosing && showBlobA)
            ? LiquidMorphPhysics.computeCloseBlend(rawValue: rawValue)
            : state.blend;

        final bool showBarrier =
            !_morphController.isClosing && clampedValue > 0.3;

        return Stack(
          children: [
            // ── Tap-to-close barrier ─────────────────────────────────────────
            if (showBarrier && widget.barrierDismissible)
              Positioned.fill(
                child: BlockSemantics(
                  child: Semantics(
                    container: true,
                    label: glassCupertinoLocalizationsOf(context)
                        .modalBarrierDismissLabel,
                    onDismiss: _closePopover,
                    onTap: _closePopover,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      excludeFromSemantics: true,
                      onTap: _closePopover,
                      child: const ColoredBox(color: Color(0x00000000)),
                    ),
                  ),
                ),
              ),

            // ── Non-dismissible barrier (absorbs taps without closing) ───────
            if (showBarrier && !widget.barrierDismissible)
              const Positioned.fill(
                child: BlockSemantics(
                  child: AbsorbPointer(),
                ),
              ),

            // ── Two-blob metaball morphing ───────────────────────────────────
            if (showOverlayLayer)
              Positioned.fill(
                child: AdaptiveLiquidGlassLayer(
                  settings: rampedSettings,
                  quality: effectiveQuality,
                  blendAmount: layerBlend,
                  platformViewBackdrop: widget.platformViewBackdrop,
                  child: Builder(
                    builder: (context) {
                      final blobStack = Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ── Blob A: Trigger ghost ──────────────────────────
                          if (showBlobA)
                            Positioned(
                              left: triggerCenterX -
                                  blobAWidth * 0.5 +
                                  blobADriftX +
                                  state.triggerPushDx,
                              top: triggerCenterY -
                                  blobAHeight * 0.5 +
                                  blobADriftY +
                                  state.triggerPushDy,
                              child: Transform.scale(
                                scale: blobAScale,
                                alignment: Alignment.center,
                                child: GlassContainer(
                                  useOwnLayer: false,
                                  settings: rampedSettings,
                                  quality: effectiveQuality,
                                  platformViewBackdrop:
                                      widget.platformViewBackdrop,
                                  width: blobAWidth,
                                  height: blobAHeight,
                                  shape: LiquidRoundedSuperellipse(
                                    borderRadius: blobARadius,
                                  ),
                                ),
                              ),
                            ),

                          // ── Blob B: Popover body ───────────────────────────
                          Positioned(
                            left: blobLeft,
                            top: blobTop,
                            child: Semantics(
                              container: true,
                              explicitChildNodes: true,
                              child: IgnorePointer(
                                ignoring: clampedValue < 0.8 ||
                                    _morphController.isClosing,
                                child: _buildPopoverContainer(
                                  state: state,
                                  currentRadius: currentRadius,
                                  currentWidth: currentWidth,
                                  currentHeight: currentHeight,
                                  effectiveSettings: rampedSettings,
                                  effectiveQuality: effectiveQuality,
                                  isDark: isDark,
                                  contentAnchor: contentAnchor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );

                      final bool needsInnerBlendGroup = useBlendGroup &&
                          LiquidGlassBlendGroup.maybeOf(context) == null;
                      return needsInnerBlendGroup
                          ? LiquidGlassBlendGroup(
                              blend: layerBlend,
                              child: blobStack,
                            )
                          : blobStack;
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );

    return OverlaySemanticsHost(
      child: Semantics(
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        child: overlay,
      ),
    );
  }

  Widget _buildPopoverContainer({
    required LiquidMorphState state,
    required double currentRadius,
    required double currentWidth,
    required double currentHeight,
    required LiquidGlassSettings effectiveSettings,
    required GlassQuality effectiveQuality,
    required bool isDark,
    required Alignment contentAnchor,
  }) {
    final teardropShape = LiquidRoundedSuperellipse(
      borderRadius: currentRadius,
    );

    final double platterGlassOpacity =
        _morphController.isClosing ? state.platterOpacity.clamp(0.0, 1.0) : 1.0;

    final double rawContentOpacity = _morphController.isClosing
        ? state.contentOpacity
        : ((state.sizeT - 0.22) / 0.63).clamp(0.0, 1.0);

    // Compensate LightweightLiquidGlass child visibility scaling on Skia/Web/
    // Standard quality so content fades linearly instead of t^2.
    final bool usesLightweightGlass =
        effectiveQuality != GlassQuality.minimal &&
            !widget.platformViewBackdrop &&
            !GlassAccessibilityData.of(context).reduceTransparency &&
            !(effectiveQuality == GlassQuality.premium &&
                ImageFilter.isShaderFilterSupported);
    final double effectiveContentOpacity = usesLightweightGlass
        ? (platterGlassOpacity > 1e-4
            ? (rawContentOpacity / platterGlassOpacity).clamp(0.0, 1.0)
            : 0.0)
        : rawContentOpacity;

    final outerScope = GlassMaterializeScope.maybeOf(context);

    return GlassMaterializeScope(
      glassProgress: platterGlassOpacity * (outerScope?.glassProgress ?? 1.0),
      contentOpacity: outerScope?.contentOpacity ?? 1.0,
      contentSigma: outerScope?.contentSigma ?? 0.0,
      child: LiquidStretch(
        stretch: widget.stretch,
        interactionScale: widget.interactionScale,
        resistance: widget.stretchResistance,
        axis: widget.stretchAxis,
        suppressInteractionOnChildren: false,
        anchorStretch: false,
        allowPositiveX: widget.allowPositiveX ?? (_morphAlignment.x < 0),
        allowNegativeX: widget.allowNegativeX ?? (_morphAlignment.x > 0),
        allowPositiveY: widget.allowPositiveY ?? (_morphAlignment.y < 0),
        allowNegativeY: widget.allowNegativeY ?? (_morphAlignment.y > 0),
        child: GlassContainer(
          useOwnLayer: false,
          settings: effectiveSettings,
          quality: effectiveQuality,
          platformViewBackdrop: widget.platformViewBackdrop,
          allowElevation: false,
          width: currentWidth,
          height: currentHeight,
          shape: teardropShape,
          clipBehavior: Clip.antiAlias,
          glowIntensity: widget.glowIntensity,
          child: GlassGlow(
            enabled: widget.enableInteractionGlow,
            glowOnTapOnly: widget.glowOnTapOnly,
            glowColor: widget.glowColor ??
                (isDark
                    ? CupertinoColors.white
                        .withValues(alpha: GlassDefaults.specularLightAlpha)
                    : CupertinoColors.black
                        .withValues(alpha: GlassDefaults.specularDarkAlpha)),
            glowRadius: widget.glowRadius,
            glowBlurRadius: 40,
            clipper: ShapeBorderClipper(shape: teardropShape),
            child: Transform.scale(
              scale: state.containerScale,
              alignment: Alignment.center,
              child: Stack(
                alignment: contentAnchor,
                clipBehavior: Clip.none,
                children: [
                  if (rawContentOpacity > 0.01)
                    _buildContentWithMeasurement(
                      contentOpacity: effectiveContentOpacity,
                      contentBlurSigma: state.contentBlurSigma,
                      currentWidth: currentWidth,
                      contentAnchor: contentAnchor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWithMeasurement({
    required double contentOpacity,
    required double contentBlurSigma,
    required double currentWidth,
    required Alignment contentAnchor,
  }) {
    final double contentScale = widget.popoverWidth > 0.0
        ? (currentWidth / widget.popoverWidth).clamp(0.20, 1.2)
        : 1.0;

    final content =
        _cachedContent ?? widget.contentBuilder(context, _closePopover);

    Widget measuredContent;
    if (widget.popoverHeight == null) {
      measuredContent = NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          _scheduleRemeasure();
          return true;
        },
        child: SizeChangedLayoutNotifier(
          child: SizedBox(
            key: _contentKey,
            width: widget.popoverWidth,
            child: content,
          ),
        ),
      );
    } else {
      measuredContent = SizedBox(
        width: widget.popoverWidth,
        height: widget.popoverHeight,
        child: content,
      );
    }

    if (contentBlurSigma >= 0.05) {
      measuredContent = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: contentBlurSigma,
          sigmaY: contentBlurSigma,
          tileMode: TileMode.decal,
        ),
        child: measuredContent,
      );
    }

    return OverflowBox(
      alignment: contentAnchor,
      minWidth: widget.popoverWidth,
      maxWidth: widget.popoverWidth,
      minHeight: 0,
      maxHeight: widget.popoverHeight ?? _getMaxPopoverHeight(),
      child: Opacity(
        opacity: contentOpacity,
        child: Transform.scale(
          scale: contentScale,
          alignment: contentAnchor,
          child: measuredContent,
        ),
      ),
    );
  }
}

const LiquidGlassSettings _kDefaultPopoverSettings = LiquidGlassSettings(
  blur: 10,
  thickness: 10,
  glassColor: Color.fromRGBO(255, 255, 255, 0.12),
  lightAngle: GlassDefaults.lightAngle,
  lightIntensity: 0.7,
  ambientStrength: 0.4,
  saturation: 1.2,
  refractiveIndex: 0.7,
  chromaticAberration: 0.0,
);
