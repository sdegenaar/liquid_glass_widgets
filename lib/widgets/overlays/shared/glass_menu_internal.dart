part of '../glass_menu.dart';

class _GlassMenuState extends State<GlassMenu> with TickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final GlassMorphController _morphController;

  late final ScrollController _scrollController;
  Size? _triggerSize;
  double? _triggerBorderRadius;
  Offset _triggerGlobalPosition = Offset.zero; // captured in _openMenu
  Offset _triggerOverlayPosition =
      Offset.zero; // captured in _openMenu (overlay-relative)
  int? _hoveredIndex;
  bool _isDragging = false;
  bool _hasStretched =
      false; // Prevents closing if we moved into stretch territory
  double _initialScrollOffset = 0.0;
  double _horizontalOffset = 0.0;
  double _verticalOffset = 0.0;

  /// Live screen-space nudge added to the captured trigger position while the
  /// menu is OPEN, so an external owner can keep the floating menu glued to a
  /// moving anchor (e.g. a canvas tile trailing under a rubberband) WITHOUT
  /// re-opening. Reset to zero on each [_openMenu]. Applied to both morph blobs
  /// in [_buildMorphingOverlay]. It deliberately does NOT recompute the
  /// screen-edge clamping ([_horizontalOffset]/[_verticalOffset]) — trails are
  /// small and bounded, and recomputing per-frame is not worth the cost. Driven
  /// via [GlassMenuController.setFollowOffset] / [setFollowOffset].
  Offset _followOffset = Offset.zero;

  int? _swipePointerId;
  Offset _swipeStartPosition = Offset.zero;
  bool _swipeArmed = false;
  bool _openedOnPointerDown = false;
  final GlobalKey _menuContentKey = GlobalKey();

  // Mid-flight interruption C0 continuity state (zero when starting from rest).
  Offset _lastPushOffset = Offset.zero;
  Offset _phaseResidualPush = Offset.zero;
  Rect? _lastPlatterRect;
  double? _lastPlatterRadius;
  Offset _platterInterruptCenterDelta = Offset.zero;
  Offset _platterInterruptSizeDelta = Offset.zero;
  double _platterInterruptRadiusDelta = 0.0;
  double? _lastContentOpacity;
  double? _lastContentBlurSigma;
  double _closeStartContentOpacity = 1.0;
  double _closeStartContentBlur = 0.0;
  double? _reopenStartContentOpacity;
  double? _reopenStartContentBlur;

  void _resetInterruptState() {
    _lastPushOffset = Offset.zero;
    _phaseResidualPush = Offset.zero;
    _lastPlatterRect = null;
    _lastPlatterRadius = null;
    _platterInterruptCenterDelta = Offset.zero;
    _platterInterruptSizeDelta = Offset.zero;
    _platterInterruptRadiusDelta = 0.0;
    _lastContentOpacity = null;
    _lastContentBlurSigma = null;
    _closeStartContentOpacity = 1.0;
    _closeStartContentBlur = 0.0;
    _reopenStartContentOpacity = null;
    _reopenStartContentBlur = null;
  }

  // --- Granular Update System (Performance + No flicker) ---
  // We cache the outer list but use notifiers to update selection state
  // without rebuilding the entire menu tree.
  late final ValueNotifier<int?> _hoveredIndexNotifier;
  late final ValueNotifier<bool> _isDraggingNotifier;
  List<Widget>? _cachedWrappedItems;
  final GlobalKey _triggerChildKey = GlobalKey();

  // --- Layered submenus (GlassMenuItem.submenu) ---
  // Every pushed level opens a second glass card OVER the menu body (the way
  // native iOS context menus open submenus): the body below stays where it is,
  // recedes slightly, and its rows dim. Each entry keeps the parent row (for
  // the card's header) and the item list shown in the card. Cleared on every
  // open.
  final List<_SubmenuLevel> _submenuStack = [];

  /// True while a level morph runs BACKWARD (a header pop): the top card then
  /// travels back toward its source row while the body un-recedes.
  bool _levelMorphPopping = false;

  /// Drives the layered morph: the body's recede/dim, and each card's flight
  /// from (or back to) its source row. Value 1.0 means no level is open or the
  /// morph has settled (0 = start).
  late final AnimationController _contentMorph;
  double _contentMorphFromHOffset = 0.0;
  double _contentMorphFromVOffset = 0.0;
  double _contentMorphToHOffset = 0.0;
  double _contentMorphToVOffset = 0.0;

  /// True while a pointer-up on the menu body is being dispatched, so a row's
  /// tap recogniser can tell a touch (already handled by the body Listener)
  /// from a keyboard / assistive-technology activation.
  bool _bodyPointerUpHandled = false;
  bool _glideOverParent = false;

  /// The list of the TOP level: the root items, or the items of the newest
  /// submenu card (the only interactive list while a card is open).
  List<Widget> get _items =>
      _submenuStack.isEmpty ? widget.items : _submenuStack.last.list;

  @override
  void didUpdateWidget(GlassMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (!identical(widget.items, oldWidget.items)) {
      _cachedWrappedItems = null;
      _refreshOpenLevels();
      // BUG 12 FIX: Clear hover state if items shrink while menu is open
      // to prevent RangeError when the selection pill tries to measure
      // a now-deleted index (including inside an open submenu card).
      if (widget.items.length < oldWidget.items.length ||
          (_hoveredIndex != null && _hoveredIndex! >= _items.length)) {
        _hoveredIndex = null;
        _hoveredIndexNotifier.value = null;
      }
    }
    if (widget.morphSpeed != oldWidget.morphSpeed) {
      _morphController.setSpeed(widget.morphSpeed);
    }
  }

  Alignment _morphAlignment = Alignment.topLeft;

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

  @override
  void initState() {
    super.initState();
    _morphController =
        GlassMorphController(vsync: this, speed: widget.morphSpeed)
          // Native menu kick is near-constant (~17 px) and strictly vertical
          // (MagicMorphView #2 tx == 0.0 even on left/right-aligned menus).
          ..recoilHalfTravelPx = LiquidMorphPhysics.menuRecoilHalfTravelPx
          ..verticalOnlyRecoil = true;
    _morphController.addListener(() {
      // AnimatedBuilder in build() already listens to _morphController.animation,
      // so calling setState() here would double-rebuild the entire menu on every
      // morph tick. Only settle/hide the overlay when the morph finishes.
      if (_overlayController.isShowing &&
          !_morphController.isShowing &&
          _morphController.status != AnimationStatus.forward) {
        if (SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _overlayController.isShowing &&
                !_morphController.isShowing) {
              _overlayController.hide();
              _horizontalOffset = 0.0;
              _verticalOffset = 0.0;
              _resetInterruptState();
              _resetSubmenus();
              setState(() {});
            }
          });
        } else {
          _overlayController.hide();
          // Reset screen-edge clamping offsets so stale values from a previous
          // open position don't bleed into the next open cycle.
          _horizontalOffset = 0.0;
          _verticalOffset = 0.0;
          _resetInterruptState();
          _resetSubmenus();
          if (mounted) setState(() {});
        }
      }
    });
    _scrollController = ScrollController();
    _hoveredIndexNotifier = ValueNotifier(null);
    _isDraggingNotifier = ValueNotifier(false);
    _contentMorph = AnimationController(
      vsync: this,
      duration: _kSubmenuMorphDuration,
      value: 1.0,
    )..addListener(_onContentMorphTick);
    widget.controller?._attach(this);
  }

  List<ModalRoute<dynamic>> _routes = const <ModalRoute<dynamic>>[];

  @override
  void dispose() {
    _removeRouteListeners();
    _routes = const [];
    widget.controller?._detach(this);
    _morphController.dispose();
    _contentMorph.dispose();
    _scrollController.dispose();
    _hoveredIndexNotifier.dispose();
    _isDraggingNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync the reduced-motion accessibility flag to the morph controller.
    // This fires on first build and again whenever MediaQuery changes
    // (e.g. user toggles Reduce Motion in Settings while the app is running).
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
    _horizontalOffset = 0.0;
    _verticalOffset = 0.0;
    _hoveredIndex = null;
    _hoveredIndexNotifier.value = null;
    _isDragging = false;
    _isDraggingNotifier.value = false;
    _hasStretched = false;
    _followOffset = Offset.zero;
    _resetInterruptState();
    _swipePointerId = null;
    _swipeArmed = false;
    _openedOnPointerDown = false;
    _resetSubmenus();
    if (!wasClosing) {
      widget.onClose?.call();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget triggerChild = widget.triggerBuilder != null
        ? widget.triggerBuilder!(context, _toggleMenu)
        // A plain trigger (an icon, a text) gets the button role here;
        // its text, if any, merges into this node as the name.
        : Semantics(
            container: true,
            button: true,
            label: widget.semanticLabel,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: widget.trigger,
            ),
          );

    return AnimatedBuilder(
      animation: _morphController.animation,
      child: triggerChild,
      builder: (context, child) {
        final rawValue = _morphController.value;

        // Block trigger taps while menu is significantly open (unless closing,
        // so tapping a closing trigger immediately reopens with C0 continuity).
        final isMenuBlocking = _overlayController.isShowing &&
            !_morphController.isClosing &&
            rawValue > 0.8;

        final isHandoff =
            _morphController.isClosing && _morphController.hasHandedOff;

        final effectiveQuality = GlassThemeHelpers.resolveQuality(
          context,
          widgetQuality: widget.quality,
          fallback: GlassThemeHelpers.nativeStyleQuality(context),
        );
        final isPremiumQuality = effectiveQuality == GlassQuality.premium &&
            !widget.platformViewBackdrop;
        final isImpellerPremium =
            isPremiumQuality && ImageFilter.isShaderFilterSupported;

        final tw = _triggerSize?.width ?? 44.0;
        final th = _triggerSize?.height ?? 44.0;
        final minTriggerSide = math.min(tw, th);
        final coreSize = widget.morphFromZero
            ? Size.zero
            : Size(minTriggerSide, minTriggerSide);
        final menuWidth = widget.menuWidth.toDouble();
        final menuHeight = _calculateMenuHeight();
        final dxMag = (menuWidth - tw) / 2.0;
        final dyMag = (menuHeight - th) / 2.0;
        final finalDx = -_morphAlignment.x * dxMag;
        final finalDy = -_morphAlignment.y * dyMag;
        final scaleDelta = widget.morphFromZero
            ? 1.0
            : LiquidMorphPhysics.computeScaleDelta(
                sourceSize: coreSize,
                targetSize: Size(menuWidth, menuHeight),
              );

        final state = _morphController.computeState(
          finalDx: finalDx,
          finalDy: finalDy,
          horizontalOffset: _horizontalOffset,
          verticalOffset: _verticalOffset,
          scaleDelta: scaleDelta,
        );

        final bool isMorphActive =
            _overlayController.isShowing || _morphController.isShowing;

        // Tactile detach and re-merge trigger visibility.
        //
        // On open (premium): hides on frame 1 so the centered contracting
        // Blob A (MagicMorphView #2) is visible without double-painting.
        // On premium close: stays hidden (0.0) while Blob A SDF-merges and
        // expands to full capsule width (clampedValue > 0.14), cross-fading in
        // cleanly over clampedValue in [0.0, 0.14] (~225..283 ms) once
        // triggerWidthProgress >= 0.88 so text and capsule endcaps are never
        // affine-squished before riding the ~400 ms horizontal splash.
        final double triggerProgress;
        final clampedValue = rawValue.clamp(0.0, 1.0);
        if (!isMorphActive || isHandoff) {
          triggerProgress = 1.0;
        } else if (!_morphController.isClosing) {
          if (isPremiumQuality && !widget.morphFromZero) {
            triggerProgress = 0.0;
          } else {
            final detachT = (clampedValue / 0.20).clamp(0.0, 1.0);
            triggerProgress = 1.0 - detachT;
          }
        } else if (isImpellerPremium && !widget.morphFromZero) {
          // On Impeller premium close, Blob A inside AdaptiveLiquidGlassLayer
          // carries the full 0..~275 ms SDF capsule merge until
          // !state.isPlatterActive (uShapeData[] has no per-shape opacity).
          // Keeping the real trigger at 0.0 while isPlatterActive prevents
          // placing a useOwnLayer:true GlassButton beneath Blob A's
          // BackdropFilter (which blurs it into a foggy halo and double-stacks
          // two glass passes), then swaps cleanly to 1.0 on the exact frame
          // _buildMorphingOverlay unmounts at !state.isPlatterActive.
          triggerProgress = state.isPlatterActive ? 0.0 : 1.0;
        } else {
          triggerProgress = state.isPlatterActive
              ? ((0.38 - clampedValue) / 0.32).clamp(0.0, 1.0)
              : 1.0;
        }

        // Interactive glass triggers (triggerBuilder, e.g. GlassButton /
        // GlassPullDownButton) dissolve through GlassMaterializeScope with a
        // strictly binary Opacity (0.0 or 1.0) so an ancestor OpacityLayer
        // never breaks BackdropFilter or useOwnLayer shaders. Plain widget
        // triggers (Text / Icon) fade via Opacity directly without double-fading.
        final bool useMaterializeForTrigger = widget.triggerBuilder != null;
        final double triggerLayerOpacity = useMaterializeForTrigger
            ? (triggerProgress <= 0.001 ? 0.0 : 1.0)
            : triggerProgress;
        final double scopeFactor =
            useMaterializeForTrigger ? triggerProgress : 1.0;
        final double glassScopeFactor =
            useMaterializeForTrigger || triggerProgress <= 0.001
                ? triggerProgress
                : 1.0;

        // Parallel close recoil (~183 ms peak) and wide-trigger horizontal
        // splash (~398 ms +1.6% peak) driven continuously through ~550 ms,
        // with widthScale clamped to [0.90, 1.04] so real trigger text and
        // capsule endcaps are never affine-squashed.
        final double residualDecay = _phaseResidualPush != Offset.zero
            ? math.exp(-18.0 * _morphController.phaseElapsedSeconds)
            : 0.0;
        final double pushDx = isMorphActive
            ? state.triggerPushDx + _phaseResidualPush.dx * residualDecay
            : 0.0;
        final double pushDy = isMorphActive
            ? state.triggerPushDy + _phaseResidualPush.dy * residualDecay
            : 0.0;
        _lastPushOffset = Offset(pushDx, pushDy);

        final double impactScale =
            isMorphActive ? state.triggerImpactScale : 1.0;
        final double rawWidthScale = (isMorphActive &&
                triggerProgress > 0.001 &&
                !widget.morphFromZero &&
                tw > th &&
                tw > 0.0)
            ? (lerpDouble(minTriggerSide, tw, state.triggerWidthProgress)! / tw)
            : 1.0;
        final double widthScale = rawWidthScale.clamp(0.90, 1.04);
        final double triggerScaleX = tw > th
            ? (impactScale * widthScale).clamp(0.90, 1.04)
            : impactScale * widthScale;
        final double triggerScaleY = impactScale;

        // Omit Opacity when fully opaque (idle) so menu triggers inside
        // GlassAppBar/GlassToolbar stay inside an enclosing GlassBackdropGroup
        // (RenderOpacity at any alpha — even 1.0 — acts as a render-pass
        // isolation boundary in GlassBackdropGroupBoundary). Keeping
        // _triggerChildKey on the trigger preserves its Element/State and
        // geometry caches across open/close reparenting.
        final outer = GlassMaterializeScope.maybeOf(context);
        Widget triggerWidget = KeyedSubtree(
          key: _triggerChildKey,
          child: GlassMaterializeScope(
            glassProgress: glassScopeFactor * (outer?.glassProgress ?? 1.0),
            contentOpacity: scopeFactor * (outer?.contentOpacity ?? 1.0),
            contentSigma: outer?.contentSigma ?? 0.0,
            child: IgnorePointer(
              ignoring: isMenuBlocking,
              child: child,
            ),
          ),
        );
        if (triggerLayerOpacity < 0.999) {
          triggerWidget = Opacity(
            opacity: triggerLayerOpacity,
            child: triggerWidget,
          );
        }

        return OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: _buildMorphingOverlay,
          overlayLocation: OverlayChildLocation.nearestOverlay,
          // Trigger — rides parallel ~183 ms catch recoil and wide splash!
          child: Transform.translate(
            offset: Offset(pushDx, pushDy),
            child: Transform.scale(
              scaleX: triggerScaleX,
              scaleY: triggerScaleY,
              alignment: Alignment.center,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _handleTriggerPointerDown,
                onPointerMove: _handleTriggerPointerMove,
                onPointerUp: _handleTriggerPointerUp,
                onPointerCancel: _handleTriggerPointerCancel,
                child: triggerWidget,
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleMenu() {
    if (_openedOnPointerDown) {
      // Tap-up from the same press that opened the menu on pointer down.
      // Consume it so we don't immediately re-toggle the menu closed.
      _openedOnPointerDown = false;
      return;
    }
    if (_overlayController.isShowing &&
        !_morphController.isClosing &&
        _morphController.value > 0.1) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _handleTriggerPointerDown(PointerDownEvent event) {
    if (!widget.enableContinuousSwipe) return;

    if (_overlayController.isShowing &&
        !_morphController.isClosing &&
        _morphController.value > 0.1) {
      _closeMenu();
      return;
    }

    _swipePointerId = event.pointer;
    _swipeStartPosition = event.position;
    _swipeArmed = false;
    _openedOnPointerDown = true;

    _openMenu();
  }

  void _handleTriggerPointerMove(PointerMoveEvent event) {
    // Flutter retains the pointer hit-test path until the gesture ends.
    if (!mounted) return;
    if (!widget.enableContinuousSwipe) return;
    if (event.pointer != _swipePointerId) return;
    // Continuous swipe has no meaning on scrollable menus: arming would block
    // scroll and always dismiss on release without selecting anything.
    if (_isScrollable) return;

    final distance = (event.position - _swipeStartPosition).distance;
    if (!_swipeArmed) {
      if (distance >= widget.continuousSwipeSlop) {
        _swipeArmed = true;
        _isDragging = true;
        _isDraggingNotifier.value = true;
      }
    }

    if (_swipeArmed) {
      _updateHoverFromGlobalPosition(event.position);
    }
  }

  void _updateHoverFromGlobalPosition(Offset globalPosition) {
    Offset localPosition;
    final renderBox =
        _menuContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.attached && renderBox.hasSize) {
      localPosition = renderBox.globalToLocal(globalPosition);
    } else {
      localPosition = globalPosition - _restingMenuGlobalRect().topLeft;
    }

    final previousIndex = _hoveredIndex;
    _updateHoveredIndex(localPosition);

    // Haptic feedback on item boundary crossing (iOS HIG)
    if (_hoveredIndex != null && _hoveredIndex != previousIndex) {
      HapticFeedback.selectionClick();
    }

    // Feed touch position to GlassGlow if interaction glow is enabled
    if (widget.enableInteractionGlow) {
      final glowLayerState = _menuContentKey.currentContext
          ?.findAncestorStateOfType<GlassGlowLayerState>();
      if (glowLayerState != null) {
        final layerBox =
            glowLayerState.context.findRenderObject() as RenderBox?;
        if (layerBox != null && layerBox.attached && layerBox.hasSize) {
          final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
          final glowColor = widget.glowColor ??
              (isDark
                  ? CupertinoColors.white
                      .withValues(alpha: GlassDefaults.specularLightAlpha)
                  : CupertinoColors.black
                      .withValues(alpha: GlassDefaults.specularDarkAlpha));
          glowLayerState.updateTouch(
            layerBox.globalToLocal(globalPosition),
            radius: widget.glowRadius,
            color: glowColor,
            blurRadius: 40,
          );
        }
      }
    }
  }

  void _handleTriggerPointerUp(PointerUpEvent event) {
    if (!mounted) return;
    if (!widget.enableContinuousSwipe) return;
    if (event.pointer != _swipePointerId) return;

    if (widget.enableInteractionGlow) {
      final glowLayerState = _menuContentKey.currentContext
          ?.findAncestorStateOfType<GlassGlowLayerState>();
      glowLayerState?.removeTouch();
    }

    if (_swipeArmed) {
      final indexToTap = _hoveredIndex;
      if (indexToTap != null && indexToTap >= 0 && indexToTap < _items.length) {
        final item = _items[indexToTap];
        if (item is GlassMenuItem && item.enabled) {
          _activateItem(item);
        } else {
          _closeMenu();
        }
      } else {
        _closeMenu();
      }
    }

    _isDragging = false;
    _isDraggingNotifier.value = false;
    _hoveredIndex = null;
    _hoveredIndexNotifier.value = null;
    _hasStretched = false;
    _swipePointerId = null;
    _swipeArmed = false;
    // Keep _openedOnPointerDown true across synchronous GestureDetector tap
    // resolution on this same pointer-up (e.g. when 10px <= drag < 18px touch
    // slop and _closeMenu() just started closing), then clear on microtask.
    _openedOnPointerDown = true;
    scheduleMicrotask(() => _openedOnPointerDown = false);
  }

  void _handleTriggerPointerCancel(PointerCancelEvent event) {
    if (!mounted) return;
    if (!widget.enableContinuousSwipe) return;
    if (event.pointer != _swipePointerId) return;

    if (widget.enableInteractionGlow) {
      final glowLayerState = _menuContentKey.currentContext
          ?.findAncestorStateOfType<GlassGlowLayerState>();
      glowLayerState?.removeTouch();
    }

    if (_swipeArmed) {
      _closeMenu();
    }

    _isDragging = false;
    _isDraggingNotifier.value = false;
    _hoveredIndex = null;
    _hoveredIndexNotifier.value = null;
    _hasStretched = false;
    _swipePointerId = null;
    _swipeArmed = false;
    _openedOnPointerDown = false;
  }

  /// Nudges the OPEN menu by [offset] (screen px) on top of its captured trigger
  /// position, so an external owner can track a moving anchor live. A no-op
  /// delta is skipped to avoid needless rebuilds. Has no visible effect while
  /// closed; the next [_openMenu] resets it to zero.
  void setFollowOffset(Offset offset) {
    if (_followOffset == offset) return;
    setState(() => _followOffset = offset);
  }

  void _openMenu() {
    _updateRouteListener();
    // Capture geometry and screen position for morphing
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // Safety: Cannot open menu if render box is not ready.
      // Also clear the pointer ID so stray move/up events from the same
      // finger don't try to hit-test against a menu that never opened.
      _openedOnPointerDown = false;
      _swipePointerId = null;
      return;
    }

    _triggerSize = renderBox.size;
    _triggerBorderRadius = _triggerSize!.shortestSide / 2;
    _triggerGlobalPosition =
        renderBox.localToGlobal(Offset.zero); // store for screen bounds
    final overlay = Overlay.maybeOf(context);
    final overlayBox = overlay?.context.findRenderObject() as RenderBox?;
    _triggerOverlayPosition = overlayBox != null
        ? renderBox.localToGlobal(Offset.zero, ancestor: overlayBox)
        : _triggerGlobalPosition;
    // A fresh open must never inherit a previous open's live anchor nudge.
    _followOffset = Offset.zero;
    // ...nor a previous open's submenu level.
    _resetSubmenus();
    final position = _triggerGlobalPosition;
    final screenSize = MediaQuery.maybeSizeOf(context);
    final screenWidth = screenSize?.width ?? double.infinity;
    final screenHeight = screenSize?.height ?? double.infinity;

    // Calculate menu height for vertical boundary check
    final menuHeight = _calculateMenuHeight();

    // 1. Determine base alignment (Auto vs Manual)
    final stripAlignment = verticalBarPresentationAlignment(
      context,
      position & _triggerSize!,
    );
    if ((widget.menuAlignment == null ||
            widget.menuAlignment == GlassMenuAlignment.none) &&
        stripAlignment != null) {
      // From iPhone Duo's vertical bar strip: towards the content. Natively a
      // menu, unlike a popover, is not centred on its item: it covers it
      // edge to edge and grows away from the nearer of the top and bottom.
      final upperHalf = !screenHeight.isFinite ||
          position.dy + _triggerSize!.height / 2 <= screenHeight / 2;
      _morphAlignment = Alignment(stripAlignment.x, upperHalf ? -1.0 : 1.0);
    } else if (widget.menuAlignment == null ||
        widget.menuAlignment == GlassMenuAlignment.none) {
      final tw = _triggerSize!.width;
      final th = _triggerSize!.height;
      final triggerCenterX = position.dx + tw * 0.5;

      // Vertical alignment: check if menu would overflow bottom
      final spaceBelow = screenHeight.isFinite
          ? screenHeight - (position.dy + th)
          : double.infinity;
      final spaceAbove = screenHeight.isFinite ? position.dy : double.infinity;

      // Prefer downward opening unless insufficient space
      final shouldFlipVertical =
          spaceBelow < menuHeight && spaceAbove > menuHeight;
      final double alignY = shouldFlipVertical ? 1.0 : -1.0;

      // Wide pill/button triggers (tw > th * 1.25) and triggers centered in the
      // middle screen band center their menu over trigger.center by default
      // (clamped cleanly to screen bounds when autoAdjustToScreen is enabled,
      // or when centered placement fits within the viewport).
      final bool isWideTrigger = tw > th * 1.25;
      final bool isCenterBand = screenWidth.isFinite &&
          triggerCenterX >= screenWidth * 0.35 &&
          triggerCenterX <= screenWidth * 0.65;
      final bool centeredFitsScreen = !screenWidth.isFinite ||
          (triggerCenterX - widget.menuWidth * 0.5 >= 0.0 &&
              triggerCenterX + widget.menuWidth * 0.5 <= screenWidth);
      final double alignX;
      if ((isWideTrigger || isCenterBand) &&
          (widget.autoAdjustToScreen || centeredFitsScreen)) {
        alignX = 0.0;
      } else {
        final isRightHalf =
            screenWidth.isFinite && triggerCenterX > screenWidth / 2;
        alignX = isRightHalf ? 1.0 : -1.0;
      }
      _morphAlignment = Alignment(alignX, alignY);
    } else {
      // MANUAL: Use the provided alignment directly.
      // Note: autoAdjustToScreen clamping will still compensate for overflow.
      _morphAlignment =
          _getAlignment(widget.menuAlignment!) ?? Alignment.center;
    }

    // 2. Clamping: calculate offsets to keep menu within screen bounds
    final clamp = _computeClampOffsets(menuHeight);

    setState(() {
      _horizontalOffset = clamp.dx;
      _verticalOffset = clamp.dy;
    });

    final bool wasInFlight =
        _overlayController.isShowing && _morphController.isShowing;
    final bool hasPrevPlatter = wasInFlight &&
        _lastPlatterRect != null &&
        _morphController.value > 0.005 &&
        _morphController.value < 0.995;
    final Rect? prevPlatterRect = hasPrevPlatter ? _lastPlatterRect : null;
    final double? prevPlatterRadius =
        hasPrevPlatter ? _lastPlatterRadius : null;
    final double? prevContentOpacity =
        hasPrevPlatter ? _lastContentOpacity : null;
    final double? prevContentBlur =
        hasPrevPlatter ? _lastContentBlurSigma : null;
    _phaseResidualPush = wasInFlight ? _lastPushOffset : Offset.zero;

    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
    // GlassMorphController.open() uses 0.0 velocity — spring starts from rest
    // for a clean, smooth teardrop expansion with no artificial kick.
    _morphController.open();
    if (prevPlatterRect != null) {
      final nextBase = _computeBasePlatterGeometry();
      if (nextBase != null) {
        _platterInterruptCenterDelta =
            prevPlatterRect.center - nextBase.rect.center;
        _platterInterruptSizeDelta = Offset(
          prevPlatterRect.width - nextBase.rect.width,
          prevPlatterRect.height - nextBase.rect.height,
        );
        _platterInterruptRadiusDelta =
            (prevPlatterRadius ?? nextBase.radius) - nextBase.radius;
      }
      _reopenStartContentOpacity = prevContentOpacity;
      _reopenStartContentBlur = prevContentBlur;
    } else {
      _platterInterruptCenterDelta = Offset.zero;
      _platterInterruptSizeDelta = Offset.zero;
      _platterInterruptRadiusDelta = 0.0;
      _reopenStartContentOpacity = null;
      _reopenStartContentBlur = null;
    }
    _closeStartContentOpacity = 1.0;
    _closeStartContentBlur = 0.0;
    widget.onLevelChanged?.call(0, _targetBodyHeight());
  }

  /// Offsets that keep a menu of [menuHeight] inside the screen's safe area
  /// (only when [GlassMenu.autoAdjustToScreen] is set), for the trigger
  /// geometry and alignment captured by the last [_openMenu].
  Offset _computeClampOffsets(double menuHeight) {
    if (!widget.autoAdjustToScreen || _triggerSize == null) return Offset.zero;
    final position = _triggerGlobalPosition;
    final screenSize = MediaQuery.maybeSizeOf(context);
    final screenWidth = screenSize?.width ?? double.infinity;
    final screenHeight = screenSize?.height ?? double.infinity;
    final flutterView = View.of(context);
    final mqPadding = EdgeInsets.fromViewPadding(
      flutterView.padding,
      flutterView.devicePixelRatio,
    );

    // The strip's inset is no bar to a menu opened out of the strip, which
    // natively lies over the item it came from; its status cluster is.
    final stripAlignment = verticalBarPresentationAlignment(
      context,
      position & _triggerSize!,
    );
    final double safeTop = math.max(
      widget.menuPadding.top + mqPadding.top,
      verticalBarPresentationTop(context, position & _triggerSize!) ?? 0.0,
    );
    final double safeBottom = widget.menuPadding.bottom + mqPadding.bottom;
    final double safeLeft = widget.menuPadding.left +
        (stripAlignment == null ? mqPadding.left : 0.0);
    final double safeRight = widget.menuPadding.right +
        (stripAlignment == null ? mqPadding.right : 0.0);

    // Calculate global menu position
    final double targetX =
        position.dx + (1 + _morphAlignment.x) * _triggerSize!.width / 2;
    final double targetY =
        position.dy + (1 + _morphAlignment.y) * _triggerSize!.height / 2;
    final double menuLeft =
        targetX - (1 + _morphAlignment.x) * widget.menuWidth / 2;
    final double menuTop = targetY - (1 + _morphAlignment.y) * menuHeight / 2;

    double hOffset = 0.0;
    double vOffset = 0.0;

    // Horizontal adjustment
    if (menuLeft < safeLeft) {
      hOffset = safeLeft - menuLeft;
    } else if (screenWidth.isFinite &&
        menuLeft + widget.menuWidth > screenWidth - safeRight) {
      hOffset = (screenWidth - safeRight) - (menuLeft + widget.menuWidth);
    }

    // Vertical adjustment
    if (menuTop < safeTop) {
      vOffset = safeTop - menuTop;
    } else if (screenHeight.isFinite &&
        menuTop + menuHeight > screenHeight - safeBottom) {
      vOffset = (screenHeight - safeBottom) - (menuTop + menuHeight);
    }
    return Offset(hOffset, vOffset);
  }

  // ─── Layered submenus ──────────────────────────────────────────────────────

  /// Activates [item] the way a tap does: a card's header row pops the card,
  /// a submenu item opens a new card, and any other item runs and closes the
  /// whole menu.
  void _activateItem(GlassMenuItem item) {
    if (item is _GlassMenuHeaderItem) {
      _popSubmenu();
    } else if (item.submenu != null) {
      _pushSubmenu(item);
    } else {
      _fireItemTap(item);
    }
  }

  /// Opens a card over the menu (or the card below it) for [parent]'s
  /// submenu. The card's header sits on the row that was activated, the body
  /// below recedes and dims, and the whole stack is re-clamped for the card's
  /// extent (see [_stackExtent]).
  void _pushSubmenu(GlassMenuItem parent) {
    if (_contentMorph.isAnimating || _morphController.isClosing) return;
    final sourceList = _items;
    final sourceIndex = sourceList.indexOf(parent);
    if (sourceIndex < 0) return;
    final sourceOffset = _listRowTop(sourceIndex, sourceList) -
        (_scrollController.hasClients ? _scrollController.offset : 0.0);
    final list = _levelList(parent, _submenuStack.length + 1);
    setState(() {
      _submenuStack.add(_SubmenuLevel(
        list: list,
        sourceIndex: sourceIndex,
        sourceRowTop: sourceOffset,
        sourceScrollOffset:
            _scrollController.hasClients ? _scrollController.offset : 0.0,
        sourceRowHeight: _getScaledItemHeight(parent, context),
      ));
      _cachedWrappedItems = null;
      _hoveredIndex = null;
      _isDragging = false;
      _hasStretched = false;
      _levelMorphPopping = false;
    });
    _hoveredIndexNotifier.value = null;
    _isDraggingNotifier.value = false;
    if (_scrollController.hasClients) _scrollController.jumpTo(0.0);
    _reclampStack();
    _startLevelMorph();
    widget.onLevelChanged?.call(_submenuStack.length, _stackExtent());
  }

  /// The card for [parent]'s submenu at [depth]: its header (the source row
  /// repeated) and its rows.
  List<Widget> _levelList(GlassMenuItem parent, int depth) => <Widget>[
        _GlassMenuHeaderItem(
          key: ValueKey<String>('glass-menu-header-$depth'),
          title: parent.title,
          icon: parent.icon,
          titleStyle: (parent.titleStyle ??
                  TextStyle(
                    fontSize: 17,
                    color: parent.iconColor ??
                        CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .color
                            ?.withValues(alpha: 0.9),
                  ))
              .copyWith(fontWeight: FontWeight.w600),
          height: parent.height,
          iconColor: parent.isDestructive ? null : parent.iconColor,
          iconSize: parent.iconSize,
          enablePressScale: parent.enablePressScale,
        ),
        const GlassMenuDivider(),
        ...parent.submenu!,
      ];

  /// Rebuilds each open card from the parent row now at its source index, so a
  /// card follows its parent when the menu's items change while it is open (a
  /// title that counts down, a check that moves between rows). A level whose
  /// parent is no longer a submenu row stays as it was.
  void _refreshOpenLevels() {
    var list = widget.items;
    for (var depth = 0; depth < _submenuStack.length; depth++) {
      final level = _submenuStack[depth];
      final parent = list.elementAtOrNull(level.sourceIndex);
      if (parent is! GlassMenuItem || parent.submenu == null) return;
      list = _levelList(parent, depth + 1);
      _submenuStack[depth] = level.withList(list);
    }
  }

  /// Closes the top card: it flies back to its source row while the level
  /// below un-recedes.
  void _popSubmenu() {
    if (_submenuStack.isEmpty || _contentMorph.isAnimating) return;
    _clearGlide();
    setState(() {
      _cachedWrappedItems = null;
      _levelMorphPopping = true;
    });
    _reclampStack();
    _startLevelMorph();
    widget.onLevelChanged?.call(
      _submenuStack.length - 1,
      _stackExtentAfterPop(),
    );
  }

  /// Drives the stack through a level morph: the clamp offsets lerp from the
  /// level's old placement to its new one, and a finished pop removes its
  /// card's level.
  void _onContentMorphTick() {
    if (!mounted) return;
    final t = _kSubmenuMorphCurve.transform(_contentMorph.value);
    setState(() {
      _horizontalOffset = lerpDouble(
        _contentMorphFromHOffset,
        _contentMorphToHOffset,
        t,
      )!;
      _verticalOffset = lerpDouble(
        _contentMorphFromVOffset,
        _contentMorphToVOffset,
        t,
      )!;
    });
    _finishPopIfNeeded();
  }

  void _startLevelMorph() {
    final reduceMotion = GlassAccessibilityData.of(context).reduceMotion;
    _contentMorph.duration =
        reduceMotion ? Duration.zero : _kSubmenuMorphDuration;
    _contentMorph.forward(from: 0.0);
  }

  /// Removes the popped level once its card has flown back to its source row.
  /// Level state is kept until then so the morph can render the returning card.
  void _finishPopIfNeeded() {
    if (_levelMorphPopping && _contentMorph.value >= 1.0) {
      final removed = _submenuStack.last;
      setState(() {
        _submenuStack.removeLast();
        _cachedWrappedItems = null;
        _levelMorphPopping = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(removed.sourceScrollOffset
              .clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
      _hoveredIndex = null;
      _hoveredIndexNotifier.value = null;
    }
  }

  // ── Level geometry ───────────────────────────────────────────────────────
  //
  // All rects are in the OVERLAY's coordinate space (the space the morphing
  // blob stack is laid out in), derived from the body's resting rect: the
  // body plus every card shifts together with the live follow offset and the
  // screen clamp.

  /// Whether the menu grows DOWN (anchored at its top edge).
  bool get _growsDown => _morphAlignment.y <= 0.0;

  /// The scale the body recedes to while a submenu card is open, measured from
  /// native iOS captures (416 → 404 px wide).
  static const double _kRecedeScale = 0.971;

  /// The opacity the rows of a level covered by a card dim to (native iOS:
  /// text drops from 9/236 to 122/236 grey ≈ 0.5).
  static const double _kDimmedOpacity = 0.5;

  /// The morph progress of the current layered morph: 1.0 when settled.
  double get _levelT {
    if (!_contentMorph.isAnimating && _contentMorph.value == 1.0) return 1.0;
    return _kSubmenuMorphCurve.transform(_contentMorph.value);
  }

  /// How far the level below the top card is receded/dimmed right now (0–1).
  double get _recedeT {
    if (_submenuStack.isEmpty) return 0.0;
    final raw = _levelMorphPopping ? 1.0 - _levelT : _levelT;
    return raw.clamp(0.0, 1.0);
  }

  /// The body's resting rect in overlay space at the CURRENT frame: the
  /// settled blob-B rect (anchored edge fixed, centred on the trigger axis),
  /// shifted by the screen clamp and the live follow offset.
  Rect _restingBodyOverlayRect() {
    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final menuWidth = widget.menuWidth.toDouble();
    final menuHeight = _targetBodyHeight();
    final dxMag = (menuWidth - tw) / 2.0;
    final dyMag = (menuHeight - th) / 2.0;
    final centre = _triggerOverlayPosition +
        _followOffset +
        Offset(
          tw / 2.0 - _morphAlignment.x * dxMag + _horizontalOffset,
          th / 2.0 - _morphAlignment.y * dyMag + _verticalOffset,
        );
    return Rect.fromCenter(
      center: centre,
      width: menuWidth,
      height: menuHeight,
    );
  }

  /// The resting rect of the card for [levelIndex], at full morph progress, in
  /// overlay space. The header row sits on the source row's centre in the
  /// receded level below (clamped to the body's top padding); a card on an
  /// upward-growing menu is shifted up so it never grows toward the trigger
  /// past the receded body's bottom edge.
  Rect _cardRect(int levelIndex) {
    final level = _submenuStack[levelIndex];
    final parentRect =
        levelIndex == 0 ? _restingBodyOverlayRect() : _cardRect(levelIndex - 1);
    final recededParent = _scaleLevelRect(parentRect, _kRecedeScale);
    final rowCentreY = recededParent.top +
        (level.sourceRowTop + level.sourceRowHeight / 2) * _kRecedeScale;
    final headerHeight = _getScaledItemHeight(level.list.first, context);
    var height = _visibleListHeight(level.list);
    var top = rowCentreY - _kBodyVerticalPadding - headerHeight / 2;
    final root = _restingBodyOverlayRect();
    final budget = _maximumStackHeight;
    if (_growsDown) {
      // Keep a header and the first child reachable even if the source row
      // is at the very bottom of a tall/scrolled ancestor.
      final minimumViewport =
          math.min(height, _listHeight(level.list.take(3).toList()));
      top = math.max(parentRect.top, top);
      top = math.min(top, root.top + budget - minimumViewport);
      height = math.min(height, root.top + budget - top);
    } else {
      top = math.min(parentRect.bottom - height, top);
      top = math.max(top, root.bottom - budget);
      height = math.min(height, parentRect.bottom - top);
    }
    return Rect.fromLTWH(parentRect.left, top, parentRect.width, height);
  }

  /// The body's recede progress (0 = full size, 1 = receded) — the level
  /// directly below the top card recedes with the current morph; with no card
  /// open it is 0.
  double get _bodyRecede => _coverProgress(0);

  /// Earlier ancestors stay receded while a deeper card opens or closes.
  double _coverProgress(int depth) {
    if (depth >= _submenuStack.length) return 0.0;
    return depth == _submenuStack.length - 1 ? _recedeT : 1.0;
  }

  Rect _scaleLevelRect(Rect rect, double scale) => Rect.fromLTWH(
        rect.center.dx - rect.width * scale / 2,
        _growsDown ? rect.top : rect.bottom - rect.height * scale,
        rect.width * scale,
        rect.height * scale,
      );

  /// The card's rect at the CURRENT morph progress: flying from its source
  /// row toward [_cardRect] on push, and back on pop.
  Rect _cardFlightRect(int levelIndex) {
    final target = _cardRect(levelIndex);
    if (levelIndex < _submenuStack.length - 1) return target;
    final level = _submenuStack[levelIndex];
    final parentRect =
        levelIndex == 0 ? _restingBodyOverlayRect() : _cardRect(levelIndex - 1);
    final source = Rect.fromLTWH(
      parentRect.left,
      parentRect.top + level.sourceRowTop - _kBodyVerticalPadding,
      parentRect.width,
      level.sourceRowHeight + 2 * _kBodyVerticalPadding,
    );
    return Rect.lerp(source, target, _recedeT)!;
  }

  /// Builds the glass card for [levelIndex]: its header row (the parent row
  /// repeated, bold, with a downward chevron), a divider, and its rows —
  /// interactive when it is the top level, dimmed and inert otherwise.
  Widget _buildSubmenuCard(
    int levelIndex,
    LiquidGlassSettings settings,
    GlassQuality quality, {
    double rootCloseOpacity = 1.0,
    double? borderRadiusOverride,
  }) {
    final level = _submenuStack[levelIndex];
    final isTop = levelIndex == _submenuStack.length - 1;
    final dimmed = !isTop;
    final shape = LiquidRoundedSuperellipse(
      borderRadius: borderRadiusOverride ?? widget.menuBorderRadius,
    );
    final cardContent = _buildListContent(
      level.list,
      interactive: isTop,
      dimmed: dimmed,
      coveredDepth: dimmed ? levelIndex + 1 : null,
      coverProgress: _coverProgress(levelIndex + 1),
      viewportHeight: _cardRect(levelIndex).height,
      passiveScrollOffset:
          isTop ? 0.0 : _submenuStack[levelIndex + 1].sourceScrollOffset,
    );
    final fade = isTop ? _cardFade() : (glass: 1.0, text: 1.0);
    final effectiveGlassFade = (fade.glass * rootCloseOpacity).clamp(0.0, 1.0);
    final effectiveTextFade = (fade.text * rootCloseOpacity).clamp(0.0, 1.0);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final glowColor = widget.glowColor ??
        (isDark
            ? CupertinoColors.white
                .withValues(alpha: GlassDefaults.specularLightAlpha)
            : CupertinoColors.black
                .withValues(alpha: GlassDefaults.specularDarkAlpha));

    return GlassMaterializeScope(
      glassProgress: effectiveGlassFade,
      contentOpacity: effectiveTextFade,
      contentSigma: 0.0,
      child: Transform.scale(
        scale: lerpDouble(1.0, _kRecedeScale, _coverProgress(levelIndex + 1))!,
        alignment: Alignment(0, _growsDown ? -1 : 1),
        child: _panelSurface(
          shape: shape,
          width: widget.menuWidth.toDouble(),
          height: _cardFlightRect(levelIndex).height,
          // An opaque card fades in and out with the glass it replaces.
          surfaceOpacity: effectiveGlassFade,
          glass: (child) => GlassContainer(
            // A card samples the backdrop on its own (it sits OVER the menu body,
            // outside the body's blend group) — never a shared layer.
            useOwnLayer: true,
            settings: settings,
            quality: quality,
            platformViewBackdrop: widget.platformViewBackdrop,
            width: widget.menuWidth.toDouble(),
            height: _cardFlightRect(levelIndex).height,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            glowIntensity: widget.glowIntensity,
            // Same material as the root. Any apparent brightening comes from
            // compositing over the parent, not a separate white/black tint veil.
            child: child,
          ),
          child: GlassGlow(
            enabled: widget.enableInteractionGlow && isTop,
            glowOnTapOnly: widget.glowOnTapOnly,
            glowColor: glowColor,
            glowRadius: widget.glowRadius,
            glowBlurRadius: 40,
            clipper: ShapeBorderClipper(shape: shape),
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: _cardRect(levelIndex).height,
              maxHeight: _cardRect(levelIndex).height,
              child: cardContent,
            ),
          ),
        ),
      ),
    );
  }

  /// The surface of the menu body or a submenu card: [glass] around [child],
  /// or, when [GlassMenu.opaqueColor] is set, a flat fill of that color in
  /// the same [shape] instead. [GlassMenu.border] is drawn over either.
  ///
  /// [surfaceOpacity] fades the opaque fill and the border the way the glass
  /// material fades (a submenu card arriving or leaving); the glass handles
  /// its own fade.
  Widget _panelSurface({
    required LiquidShape shape,
    required double width,
    required double height,
    required Widget Function(Widget child) glass,
    required Widget child,
    double surfaceOpacity = 1.0,
  }) {
    final opaqueColor = widget.opaqueColor;
    final border = widget.border;
    final hasBorder = border != null && border.style != BorderStyle.none;
    if (opaqueColor == null && !hasBorder) return glass(child);
    final outline = shape.toOutlinedBorder();
    final Widget surface = opaqueColor == null
        ? glass(child)
        : SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: surfaceOpacity,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: opaqueColor,
                      shape: outline,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: shape.toBorderRadius() ?? BorderRadius.zero,
                  child: child,
                ),
              ],
            ),
          );
    if (!hasBorder) return surface;
    return Stack(
      children: [
        surface,
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: surfaceOpacity,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: outline.copyWith(side: border),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Eased progress of the current level morph between [from] and [to].
  double _morphStage(double from, double to) => Curves.easeOut
      .transform(((_contentMorph.value - from) / (to - from)).clamp(0.0, 1.0));

  /// Fade of the top card. On push its rows arrive with the material (and
  /// lead it, so the card never shows as an empty frosted panel); on pop the
  /// material dissolves together with the rows (just behind them), so no
  /// frame shows an empty frosted card blurring the returning parent rows.
  ({double glass, double text}) _cardFade() {
    if (_levelMorphPopping) {
      return (
        glass: 1.0 - _morphStage(0.0, 0.32),
        text: 1.0 - _morphStage(0.0, 0.3),
      );
    }
    return (glass: _morphStage(0.0, 0.45), text: _morphStage(0.0, 0.3));
  }

  /// Opacity of the rows at [depth] that the card above it covers once
  /// settled: they cross-fade out faster than the card's rows arrive, and
  /// return as those clear on pop, so the two sets of labels never compete
  /// and no frame shows an empty frosted card over hidden rows. Rows the card does not cover keep the usual dimming.
  double _coveredRowOpacity(int depth) {
    if (depth >= _submenuStack.length) return 1.0;
    if (depth < _submenuStack.length - 1) return 0.0;
    return _levelMorphPopping
        ? _morphStage(0.1, 0.35)
        : 1.0 - _morphStage(0.0, 0.15);
  }

  /// Whether row [index] of the level at [depth] lies under the settled card
  /// that level's submenu opens (its centre inside the card's rect).
  bool _isCoveredRow(int depth, int index, List<Widget> items) {
    final parentRect =
        depth == 0 ? _restingBodyOverlayRect() : _cardRect(depth - 1);
    final receded = _scaleLevelRect(parentRect, _kRecedeScale);
    final card = _cardRect(depth);
    final centre = _listRowTop(index, items) +
        _getScaledItemHeight(items[index], context) / 2 -
        _submenuStack[depth].sourceScrollOffset;
    final y = receded.top + centre * _kRecedeScale;
    return y > card.top && y < card.bottom;
  }

  /// Vertical offset of row [index] from its list's top (body padding included).
  double _listRowTop(int index, List<Widget> list) {
    var offset = _kBodyVerticalPadding;
    for (var i = 0; i < index && i < list.length; i++) {
      offset += _getScaledItemHeight(list[i], context) + _kRowGap;
    }
    return offset;
  }

  double _listHeight(List<Widget> list) {
    var height = 2.0 * _kBodyVerticalPadding;
    for (var i = 0; i < list.length; i++) {
      height += _getScaledItemHeight(list[i], context);
      if (i < list.length - 1) height += _kRowGap;
    }
    return height;
  }

  /// The resting height of the whole visible stack, measured from the body's
  /// anchored edge the way the menu grows: the body's own receded extent, plus
  /// how far the cards reach past it. This is what `onLevelChanged` reports so
  /// an external owner can make room for the card.
  double _stackExtent() => _extentAtDepth(_submenuStack.length);

  Rect _boundsAtDepth(int depth) {
    final root = _restingBodyOverlayRect();
    var bounds = depth == 0 ? root : _scaleLevelRect(root, _kRecedeScale);
    for (var i = 0; i < depth; i++) {
      final card = _cardRect(i);
      bounds = bounds.expandToInclude(
          i == depth - 1 ? card : _scaleLevelRect(card, _kRecedeScale));
    }
    return bounds;
  }

  double _extentAtDepth(int depth) {
    final root = _restingBodyOverlayRect();
    final bounds = _boundsAtDepth(depth);
    return _growsDown ? bounds.bottom - root.top : root.bottom - bounds.top;
  }

  /// The stack extent once the popping card is gone (what `onLevelChanged`
  /// reports on pop, before the level is removed).
  double _stackExtentAfterPop() => _extentAtDepth(_submenuStack.length - 1);

  /// Re-clamps the whole stack (body + cards) for its current extent, the way
  /// the body alone was clamped before submenus existed. Only active when the
  /// owner asked for screen clamping at all.
  void _reclampStack() {
    final depth = _submenuStack.length - (_levelMorphPopping ? 1 : 0);
    var to = Offset.zero;
    if (widget.autoAdjustToScreen) {
      // Clamp the union without changing the root's anchor equation.
      final origin = _triggerGlobalPosition - _triggerOverlayPosition;
      final bounds = _boundsAtDepth(depth)
          .shift(origin - Offset(_horizontalOffset, _verticalOffset));
      final mqSize = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context) + widget.menuPadding;
      double fit(double lo, double hi, double min, double max) =>
          lo < min ? min - lo : (hi > max ? max - hi : 0.0);
      to = Offset(
        fit(bounds.left, bounds.right, padding.left,
            mqSize.width - padding.right),
        fit(bounds.top, bounds.bottom, padding.top,
            mqSize.height - padding.bottom),
      );
    }
    _contentMorphFromHOffset = _horizontalOffset;
    _contentMorphFromVOffset = _verticalOffset;
    _contentMorphToHOffset = to.dx;
    _contentMorphToVOffset = to.dy;
  }

  void _resetSubmenus() {
    _submenuStack.clear();
    _levelMorphPopping = false;
    _cachedWrappedItems = null;
    _contentMorph.value = 1.0;
  }

  // ─── External glide (GlassMenuController.glideTo / endGlide) ────────────────

  bool _glideTo(Offset globalPosition) {
    if (!_overlayController.isShowing || _morphController.isClosing) {
      return false;
    }
    if (_contentMorph.isAnimating) {
      _clearGlide();
      return _restingMenuGlobalRect().contains(globalPosition);
    }
    _glideOverParent = false;
    if (_submenuStack.isNotEmpty) {
      final origin = _triggerGlobalPosition - _triggerOverlayPosition;
      final point = globalPosition - origin;
      if (!_cardRect(_submenuStack.length - 1).contains(point)) {
        _clearGlide();
        _glideOverParent = _restingBodyOverlayRect().contains(point) ||
            List.generate(_submenuStack.length - 1, _cardRect)
                .any((rect) => rect.contains(point));
        return _restingMenuGlobalRect().contains(globalPosition);
      }
    }
    if (!_isDragging) {
      _isDragging = true;
      _isDraggingNotifier.value = true;
    }
    _updateHoverFromGlobalPosition(globalPosition);
    return _restingMenuGlobalRect().contains(globalPosition);
  }

  bool _endGlide() {
    if (!_overlayController.isShowing) return false;
    final index = _hoveredIndex;
    final pop = _glideOverParent;
    _clearGlide();
    if (_morphController.isClosing || _contentMorph.isAnimating) return false;
    if (pop) {
      _popSubmenu();
      return true;
    }
    if (index != null && index >= 0 && index < _items.length) {
      final item = _items[index];
      if (item is GlassMenuItem && item.enabled) {
        _activateItem(item);
        return true;
      }
    }
    return false;
  }

  void _cancelGlide() {
    if (!_overlayController.isShowing) return;
    _clearGlide();
  }

  void _clearGlide() {
    _glideOverParent = false;
    if (widget.enableInteractionGlow) {
      final glowLayerState = _menuContentKey.currentContext
          ?.findAncestorStateOfType<GlassGlowLayerState>();
      glowLayerState?.removeTouch();
    }
    _isDragging = false;
    _isDraggingNotifier.value = false;
    _hoveredIndex = null;
    _hoveredIndexNotifier.value = null;
    if (_hasStretched) setState(() => _hasStretched = false);
  }

  /// The open stack's global rect at rest: the body plus every open card,
  /// including the screen clamping and the live follow offset. This is the
  /// region a glide counts as "over the menu".
  Rect _restingMenuGlobalRect() {
    // Overlay coords → global coords: the trigger's position is known in both
    // (captured by _openMenu), so their difference is the overlay's origin.
    final origin = _triggerGlobalPosition - _triggerOverlayPosition;
    Rect toGlobal(Rect r) => r.shift(origin);
    var rect = toGlobal(_restingBodyOverlayRect());
    for (var i = 0; i < _submenuStack.length; i++) {
      rect = rect.expandToInclude(toGlobal(_cardRect(i)));
    }
    return rect;
  }

  void _closeMenu() {
    if (!_overlayController.isShowing || _morphController.isClosing) return;
    final bool hasPrevPlatter = _morphController.isShowing &&
        _lastPlatterRect != null &&
        _morphController.value > 0.005 &&
        _morphController.value < 0.995;
    final Rect? prevPlatterRect = hasPrevPlatter ? _lastPlatterRect : null;
    final double? prevPlatterRadius =
        hasPrevPlatter ? _lastPlatterRadius : null;
    final double? prevContentOpacity =
        hasPrevPlatter ? _lastContentOpacity : null;
    final double? prevContentBlur =
        hasPrevPlatter ? _lastContentBlurSigma : null;
    setState(() {
      _hoveredIndex = null;
      _isDragging = false;
    });
    _hoveredIndexNotifier.value = null;
    _isDraggingNotifier.value = false;
    _swipePointerId = null;
    _swipeArmed = false;
    _openedOnPointerDown = false;
    _morphController.close();
    // Preserve C0 trigger push continuity if closing immediately after a
    // mid-close reopen where residual push was still decaying.
    final stateAfter = _morphController.computeState(
      finalDx: -_morphAlignment.x *
          ((widget.menuWidth.toDouble() - (_triggerSize?.width ?? 44.0)) / 2.0),
      finalDy: -_morphAlignment.y *
          ((_calculateMenuHeight() - (_triggerSize?.height ?? 44.0)) / 2.0),
      horizontalOffset: _horizontalOffset,
      verticalOffset: _verticalOffset,
    );
    _phaseResidualPush = _lastPushOffset -
        Offset(stateAfter.triggerPushDx, stateAfter.triggerPushDy);
    if (prevPlatterRect != null) {
      final nextBase = _computeBasePlatterGeometry();
      if (nextBase != null) {
        _platterInterruptCenterDelta =
            prevPlatterRect.center - nextBase.rect.center;
        _platterInterruptSizeDelta = Offset(
          prevPlatterRect.width - nextBase.rect.width,
          prevPlatterRect.height - nextBase.rect.height,
        );
        _platterInterruptRadiusDelta =
            (prevPlatterRadius ?? nextBase.radius) - nextBase.radius;
      }
      _closeStartContentOpacity = (prevContentOpacity ?? 1.0).clamp(0.0, 1.0);
      _closeStartContentBlur = (prevContentBlur ?? 0.0).clamp(0.0, 8.0);
    } else {
      _platterInterruptCenterDelta = Offset.zero;
      _platterInterruptSizeDelta = Offset.zero;
      _platterInterruptRadiusDelta = 0.0;
      _closeStartContentOpacity = 1.0;
      _closeStartContentBlur = 0.0;
    }
    _reopenStartContentOpacity = null;
    _reopenStartContentBlur = null;
    widget.onClose?.call();
  }

  /// Single source of truth for the analytical (un-decayed) Blob B geometry
  /// (`rect`, `radius`, and anchor drift) in the current controller phase.
  /// Shared by [_openMenu], [_closeMenu], and [_buildMorphingOverlay] so
  /// mid-flight open↔close reversals stay strictly C0 continuous.
  ({
    Rect rect,
    double radius,
    double anchorDriftX,
    double anchorDriftY,
    Offset effectivePush,
  })? _computeBasePlatterGeometry() {
    if (_triggerSize == null) return null;
    final rawValue = _morphController.value;
    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final minTriggerSide = math.min(tw, th);
    final coreW = widget.morphFromZero ? 0.0 : minTriggerSide;
    final coreH = widget.morphFromZero ? 0.0 : minTriggerSide;
    final menuWidth = widget.menuWidth.toDouble();
    final menuHeight = _calculateMenuHeight();
    final targetHeight = widget.menuHeight ?? menuHeight;
    final dxMag = (menuWidth - tw) / 2.0;
    final dyMag = (menuHeight - th) / 2.0;
    final finalDx = -_morphAlignment.x * dxMag;
    final finalDy = -_morphAlignment.y * dyMag;
    final scaleDelta = widget.morphFromZero
        ? 1.0
        : LiquidMorphPhysics.computeScaleDelta(
            sourceSize: Size(coreW, coreH),
            targetSize: Size(menuWidth, targetHeight),
          );
    final state = _morphController.computeState(
      finalDx: finalDx,
      finalDy: finalDy,
      horizontalOffset: _horizontalOffset,
      verticalOffset: _verticalOffset,
      scaleDelta: scaleDelta,
    );
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );
    final isPremiumQuality = effectiveQuality == GlassQuality.premium &&
        !widget.platformViewBackdrop;
    final triggerCenter =
        _triggerOverlayPosition + _followOffset + Offset(tw * 0.5, th * 0.5);
    final originRect =
        Rect.fromCenter(center: triggerCenter, width: coreW, height: coreH);
    final anchorAlignX = (1.0 + _morphAlignment.x) / 2.0;
    final anchorAlignY = (1.0 + _morphAlignment.y) / 2.0;
    final restingRect = Rect.fromLTWH(
      _triggerOverlayPosition.dx +
          _followOffset.dx +
          anchorAlignX * (tw - menuWidth) +
          _horizontalOffset,
      _triggerOverlayPosition.dy +
          _followOffset.dy +
          anchorAlignY * (th - targetHeight) +
          _verticalOffset,
      menuWidth,
      targetHeight,
    );

    final double residualPushDecay = _phaseResidualPush != Offset.zero
        ? math.exp(-18.0 * _morphController.phaseElapsedSeconds)
        : 0.0;
    final Offset effectivePush =
        Offset(state.triggerPushDx, state.triggerPushDy) +
            _phaseResidualPush * residualPushDecay;

    double anchorDriftX = 0.0;
    double anchorDriftY = 0.0;
    final Rect baseRect;
    final double baseRadius;

    if (_morphController.isClosing) {
      final closedGeo = LiquidMorphPhysics.computeClosingTeardropGeometry(
        rawValue: rawValue,
        pathT: state.pathT,
        triggerCenter: triggerCenter,
        triggerSize: Size(tw, th),
        restingRect: restingRect,
        targetRadius: widget.menuBorderRadius,
        effectivePush: effectivePush,
        elapsedSeconds: _morphController.phaseElapsedSeconds,
        closeStartProgress: _morphController.closeStartProgress,
        alignX: _morphAlignment.x,
        disableAnimations: _morphController.disableAnimations,
        morphFromZero: widget.morphFromZero,
      );
      baseRect = closedGeo.rect;
      baseRadius = closedGeo.borderRadius;
    } else {
      final sizeProgress =
          (!_morphController.disableAnimations && scaleDelta > 3.0)
              ? LiquidMorphPhysics.computeMenuOpenSizeProgress(rawValue)
              : state.sizeT.clamp(0.0, 1.0);
      final double baseWidth =
          lerpDouble(coreW, menuWidth, sizeProgress)!.clamp(0.0, menuWidth);
      final double baseHeight = lerpDouble(coreH, targetHeight, sizeProgress)!
          .clamp(0.0, targetHeight);
      final double triggerRadius =
          _triggerBorderRadius ?? (_triggerSize!.shortestSide / 2.0);
      baseRadius =
          (!_morphController.disableAnimations && !widget.morphFromZero)
              ? LiquidMorphPhysics.computeOpenCornerRadius(
                  currentSize: Size(baseWidth, baseHeight),
                  restingSize: Size(menuWidth, targetHeight),
                  targetRadius: widget.menuBorderRadius,
                  elapsedSeconds: _morphController.phaseElapsedSeconds,
                  openStartProgress: _morphController.openStartProgress,
                )
              : LiquidMorphPhysics.computeCornerRadius(
                  currentSize: Size(baseWidth, baseHeight),
                  triggerRadius: triggerRadius,
                  targetRadius: widget.menuBorderRadius,
                  progress: sizeProgress,
                );
      final interpolated = Rect.lerp(originRect, restingRect, sizeProgress)!;
      final totalDelta = restingRect.center - originRect.center;
      final maxDrift = isPremiumQuality ? 14.0 : 8.0;
      final detachRelease =
          isPremiumQuality ? (1.0 - state.anchorScale * 0.65) : 1.0;
      anchorDriftX =
          (totalDelta.dx * (state.pathT - sizeProgress) * detachRelease)
              .clamp(-maxDrift, maxDrift);
      anchorDriftY =
          (totalDelta.dy * (state.pathT - sizeProgress) * detachRelease)
              .clamp(-maxDrift, maxDrift);
      final bool timedDrift =
          !_morphController.disableAnimations && !widget.morphFromZero;
      final double platterDriftY = timedDrift
          ? totalDelta.dy.sign *
              LiquidMorphPhysics.computeOpenDrift(
                elapsedSeconds: _morphController.phaseElapsedSeconds,
                menuHeight: targetHeight,
                openStartProgress: _morphController.openStartProgress,
              )
          : anchorDriftY;
      final Offset baseCenter =
          interpolated.center + Offset(anchorDriftX, platterDriftY);
      double baseLeft = baseCenter.dx - baseWidth * 0.5;
      double baseTop = baseCenter.dy - baseHeight * 0.5;

      // Keep mid-flight open drift inside screen bounds when
      // autoAdjustToScreen is enabled.
      if (widget.autoAdjustToScreen) {
        final screenSize = MediaQuery.maybeSizeOf(context);
        final screenWidth = screenSize?.width ?? double.infinity;
        final screenHeight = screenSize?.height ?? double.infinity;
        final flutterView = View.of(context);
        final mqPadding = EdgeInsets.fromViewPadding(
          flutterView.padding,
          flutterView.devicePixelRatio,
        );
        if (screenWidth.isFinite) {
          final originShiftX =
              _triggerGlobalPosition.dx - _triggerOverlayPosition.dx;
          final safeLeft =
              widget.menuPadding.left + mqPadding.left - originShiftX;
          final safeRight = screenWidth -
              widget.menuPadding.right -
              mqPadding.right -
              baseWidth -
              originShiftX;
          final minAllowedX = math.min(originRect.left, safeLeft);
          final maxAllowedX = math.max(
            minAllowedX,
            math.max(originRect.right - baseWidth, safeRight),
          );
          baseLeft = baseLeft.clamp(minAllowedX, maxAllowedX);
        }
        if (screenHeight.isFinite) {
          final originShiftY =
              _triggerGlobalPosition.dy - _triggerOverlayPosition.dy;
          final safeTop = widget.menuPadding.top + mqPadding.top - originShiftY;
          final safeBottom = screenHeight -
              widget.menuPadding.bottom -
              mqPadding.bottom -
              baseHeight -
              originShiftY;
          final minAllowedY = math.min(originRect.top, safeTop);
          final maxAllowedY = math.max(
            minAllowedY,
            math.max(originRect.bottom - baseHeight, safeBottom),
          );
          baseTop = baseTop.clamp(minAllowedY, maxAllowedY);
        }
      }
      baseRect = Rect.fromLTWH(baseLeft, baseTop, baseWidth, baseHeight);
    }

    return (
      rect: baseRect,
      radius: baseRadius,
      anchorDriftX: anchorDriftX,
      anchorDriftY: anchorDriftY,
      effectivePush: effectivePush,
    );
  }

  /// Fires [item.onTap] then closes the menu, honouring [GlassMenuItem.closeDelay].
  ///
  /// When [closeDelay] is null the close is synchronous (default behaviour).
  /// When set, the item action fires immediately but the menu morph is deferred
  /// so that animated [trailing] widgets (e.g. a [GlassSwitch]) can complete
  /// their state transition while the menu is still visible.
  void _fireItemTap(GlassMenuItem item) {
    item.onTap();
    final delay = item.closeDelay;
    if (delay == null || delay == Duration.zero) {
      _closeMenu();
    } else {
      Future.delayed(delay, () {
        if (mounted) _closeMenu();
      });
    }
  }

  Widget _buildMorphingOverlay(BuildContext context) {
    if (_triggerSize == null) return const SizedBox.shrink();

    final rawValue = _morphController.value;
    final clampedValue = rawValue.clamp(0.0, 1.0);

    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final minTriggerSide = math.min(tw, th);
    final double coreW = widget.morphFromZero ? 0.0 : minTriggerSide;
    final double coreH = widget.morphFromZero ? 0.0 : minTriggerSide;

    final menuWidth = widget.menuWidth.toDouble();
    final menuHeight = _calculateMenuHeight();
    final targetHeight = widget.menuHeight ?? menuHeight;

    final dxMag = (menuWidth - tw) / 2.0;
    final dyMag = (menuHeight - th) / 2.0;
    final finalDx = -_morphAlignment.x * dxMag;
    final finalDy = -_morphAlignment.y * dyMag;
    final scaleDelta = widget.morphFromZero
        ? 1.0
        : LiquidMorphPhysics.computeScaleDelta(
            sourceSize: Size(coreW, coreH),
            targetSize: Size(menuWidth, targetHeight),
          );

    final state = _morphController.computeState(
      finalDx: finalDx,
      finalDy: finalDy,
      horizontalOffset: _horizontalOffset,
      verticalOffset: _verticalOffset,
      scaleDelta: scaleDelta,
    );

    // Once the closing platter has vanished into the trigger (~283 ms), the
    // real trigger widget in the page tree handles the remaining horizontal
    // splash (~400 ms) and recoil settle (~550 ms) with zero overlay overdraw.
    if (_morphController.isClosing && !state.isPlatterActive) {
      _lastPlatterRect = null;
      _lastPlatterRadius = null;
      _lastContentOpacity = null;
      _lastContentBlurSigma = null;
      return const SizedBox.shrink();
    }

    final baseGeo = _computeBasePlatterGeometry();
    if (baseGeo == null) return const SizedBox.shrink();

    final effectiveSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: widget.settings,
      fallback: _kDefaultMenuSettings,
      isOverlayPlatter: true,
    );

    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );

    // LiquidGlassBlendGroup requires a LiquidGlassLayer ancestor, which
    // AdaptiveLiquidGlassLayer only mounts for GlassQuality.premium.
    final bool useBlendGroup = effectiveQuality == GlassQuality.premium &&
        !widget.platformViewBackdrop;

    final bool isPremiumQuality = effectiveQuality == GlassQuality.premium &&
        !widget.platformViewBackdrop;
    final bool isPremium =
        isPremiumQuality && ImageFilter.isShaderFilterSupported;

    final Offset triggerCenter =
        _triggerOverlayPosition + _followOffset + Offset(tw * 0.5, th * 0.5);

    final double anchorAlignX = (1.0 + _morphAlignment.x) / 2.0;
    final double anchorAlignY = (1.0 + _morphAlignment.y) / 2.0;
    final Rect restingRect = Rect.fromLTWH(
      _triggerOverlayPosition.dx +
          _followOffset.dx +
          anchorAlignX * (tw - menuWidth) +
          _horizontalOffset,
      _triggerOverlayPosition.dy +
          _followOffset.dy +
          anchorAlignY * (th - targetHeight) +
          _verticalOffset,
      menuWidth,
      targetHeight,
    );

    final double interruptDecay =
        (_platterInterruptCenterDelta != Offset.zero ||
                _platterInterruptSizeDelta != Offset.zero ||
                _platterInterruptRadiusDelta != 0.0 ||
                _reopenStartContentOpacity != null ||
                _reopenStartContentBlur != null)
            ? math.exp(-22.0 * _morphController.phaseElapsedSeconds)
            : 0.0;

    final double currentWidth =
        (baseGeo.rect.width + _platterInterruptSizeDelta.dx * interruptDecay)
            .clamp(0.0, menuWidth);
    final double currentHeight =
        (baseGeo.rect.height + _platterInterruptSizeDelta.dy * interruptDecay)
            .clamp(0.0, targetHeight);
    final double shortestHalfNow =
        math.max(0.0, math.min(currentWidth, currentHeight) * 0.5);
    final double currentRadius =
        (baseGeo.radius + _platterInterruptRadiusDelta * interruptDecay)
            .clamp(0.0, shortestHalfNow);

    final double triggerRadius =
        _triggerBorderRadius ?? (_triggerSize!.shortestSide / 2.0);
    final Offset effectivePush = baseGeo.effectivePush;
    final double anchorDriftX = baseGeo.anchorDriftX;
    final double anchorDriftY = baseGeo.anchorDriftY;
    final Offset effectiveCenter =
        baseGeo.rect.center + _platterInterruptCenterDelta * interruptDecay;
    final double blobBLeft = effectiveCenter.dx - currentWidth * 0.5;
    final double blobBTop = effectiveCenter.dy - currentHeight * 0.5;

    _lastPlatterRect =
        Rect.fromLTWH(blobBLeft, blobBTop, currentWidth, currentHeight);
    _lastPlatterRadius = currentRadius;

    // Blob A (MagicMorphView #2): True-width capsule centered on
    // triggerCenter + effectivePush. Contracts tw -> min(tw, th) on open, and
    // on premium close stays active across 0..~283 ms expanding min(tw, th) -> tw
    // with true 22px semicircular endcaps so Blob B SDF-merges seamlessly into
    // the middle of the wide capsule before handing off to the real trigger!
    // Native keeps the widening capsule hidden inside the retracting droplet
    // for ~50 ms longer than the raw width spring suggests (it fades in as it
    // emerges), so the *drawn* capsule trails the spring on close and
    // converges back to it by the ~283 ms handoff (C⁰ with the real trigger).
    final double blobAWidthProgress = _morphController.isClosing
        ? _delayedCloseWidthProgress(state.triggerWidthProgress)
        : state.triggerWidthProgress;
    final double blobAWidth =
        lerpDouble(minTriggerSide, tw, blobAWidthProgress)!
            .clamp(1.0, double.infinity);
    final double blobAHeight = th.clamp(1.0, double.infinity);
    final double blobARadius = math.min(
      triggerRadius,
      math.min(blobAWidth, blobAHeight) * 0.5,
    );
    final double openAnchorScale = (tw > th * 1.15)
        ? (1.0 - ((clampedValue - 0.25) / 0.35).clamp(0.0, 1.0))
        : (1.0 - (clampedValue / 0.50)).clamp(0.0, 1.0);
    // Close: native hides the trigger's own glass while the droplet leaves
    // (frames 1–6 are a single blob; the trigger pill only appears near the end
    // with a neck into the droplet). Drawing Blob A from t = 0 left a second,
    // detached circle. Blob A is therefore held back until BOTH rawValue < 0.45
    // and the droplet is close enough for the metaball bridge to reach it (the
    // distance depends on alignment: a left/right-aligned droplet sits off to
    // the side), then grows in from nothing so it emerges from the tip.
    final double closeBlobAGrow = _morphController.isClosing
        ? LiquidMorphPhysics.computeCloseBlobAEmergence(
            platterRect:
                Rect.fromLTWH(blobBLeft, blobBTop, currentWidth, currentHeight),
            platterRadius: currentRadius,
            triggerCenter: triggerCenter + effectivePush,
            rawValue: rawValue,
          )
        : 1.0;
    final double blobAScale = _morphController.isClosing
        ? state.triggerImpactScale * closeBlobAGrow
        : openAnchorScale;
    final bool showBlobA = !widget.morphFromZero &&
        (_morphController.isClosing
            ? (isPremium && state.isPlatterActive && closeBlobAGrow > 0.001)
            : openAnchorScale > 0.15);

    // Close (premium, non-zero origin): drive the metaball bridge directly so the
    // platter and trigger read as one teardrop (see
    // LiquidMorphPhysics.computeCloseBlend); open keeps the controller blend.
    final double layerBlend =
        (_morphController.isClosing && !widget.morphFromZero && showBlobA)
            ? LiquidMorphPhysics.computeCloseBlend(rawValue: rawValue)
            : state.blend;

    final overlay = Stack(
      children: [
        // Invisible full-screen tap-to-close barrier (inactive once closing so
        // tapping the trigger or another control mid-close responds immediately)
        if (!_morphController.isClosing &&
            clampedValue > 0.3 &&
            widget.showDismissBarrier)
          Positioned.fill(
            child: BlockSemantics(
              child: Semantics(
                container: true,
                label: glassCupertinoLocalizationsOf(context).menuDismissLabel,
                onDismiss: _closeMenu,
                onTap: _closeMenu,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  excludeFromSemantics: true,
                  onTap: _closeMenu,
                  child: ShellChromeBarrier(
                    child: Container(color: const Color(0x00000000)),
                  ),
                ),
              ),
            ),
          ),

        // ── Two-Blob Metaball Morphing (no fractional Opacity over layer!) ──
        Positioned.fill(
          child: AdaptiveLiquidGlassLayer(
            settings: effectiveSettings,
            quality: effectiveQuality,
            blendAmount: layerBlend,
            platformViewBackdrop: widget.platformViewBackdrop,
            child: Builder(
              builder: (context) {
                final blobs = Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ─── Blob A: Centered Trigger Morph (MagicMorphView #2) ──
                    if (showBlobA)
                      Positioned(
                        left: triggerCenter.dx -
                            blobAWidth * 0.5 +
                            anchorDriftX * (1.0 - openAnchorScale) * 0.5 +
                            effectivePush.dx,
                        top: triggerCenter.dy -
                            blobAHeight * 0.5 +
                            anchorDriftY * (1.0 - openAnchorScale) * 0.5 +
                            effectivePush.dy,
                        child: Transform.scale(
                          scale: blobAScale,
                          alignment: Alignment.center,
                          child: GlassContainer(
                            useOwnLayer: false,
                            settings: effectiveSettings,
                            quality: effectiveQuality,
                            platformViewBackdrop: widget.platformViewBackdrop,
                            width: blobAWidth,
                            height: blobAHeight,
                            shape: LiquidRoundedSuperellipse(
                              borderRadius: blobARadius,
                            ),
                          ),
                        ),
                      ),

                    // ── Blob B: Menu Body ───────────────────────────────────
                    Positioned(
                      left: blobBLeft,
                      top: blobBTop,
                      child: IgnorePointer(
                        ignoring: clampedValue < 0.8,
                        child: _buildMorphingContainer(
                          state,
                          clampedValue,
                          currentWidth,
                          currentHeight,
                          currentRadius,
                          effectiveQuality,
                          effectiveSettings,
                        ),
                      ),
                    ),
                  ],
                );

                // Avoid nesting a duplicate LiquidGlassBlendGroup when
                // AdaptiveLiquidGlassLayer (premium Impeller) already provides
                // one, while still providing one for standard quality / tests.
                final bool needsInnerBlendGroup = useBlendGroup &&
                    LiquidGlassBlendGroup.maybeOf(context) == null;
                final Widget blobsGrouped = needsInnerBlendGroup
                    ? LiquidGlassBlendGroup(
                        blend: layerBlend,
                        child: blobs,
                      )
                    : blobs;

                // ── Submenu cards ─────────────────────────────────────────
                final cardsOpacity = _morphController.isClosing
                    ? (state.contentOpacity * _closeStartContentOpacity)
                    : 1.0;
                final double cardCloseScale =
                    (_morphController.isClosing && menuWidth > 0.0)
                        ? (currentWidth / menuWidth).clamp(0.20, 1.0)
                        : 1.0;
                final Offset blobBCenter = Offset(
                  blobBLeft + currentWidth * 0.5,
                  blobBTop + currentHeight * 0.5,
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    blobsGrouped,
                    if (_submenuStack.isNotEmpty && cardsOpacity > 0.001)
                      for (var i = 0; i < _submenuStack.length; i++)
                        Builder(
                          builder: (context) {
                            final cardRest = _cardFlightRect(i);
                            final Offset cardPos = _morphController.isClosing
                                ? (blobBCenter +
                                    (cardRest.center - restingRect.center) *
                                        cardCloseScale -
                                    Offset(
                                      cardRest.width * 0.5,
                                      cardRest.height * 0.5,
                                    ))
                                : cardRest.topLeft;
                            final double? cardCloseRadius =
                                _morphController.isClosing
                                    ? (currentRadius / cardCloseScale).clamp(
                                        widget.menuBorderRadius,
                                        math.min(
                                              cardRest.width,
                                              cardRest.height,
                                            ) *
                                            0.5,
                                      )
                                    : null;
                            return Positioned(
                              left: cardPos.dx,
                              top: cardPos.dy,
                              child: Transform.scale(
                                scale: cardCloseScale,
                                alignment: Alignment.center,
                                child: IgnorePointer(
                                  ignoring: clampedValue < 0.8 ||
                                      _contentMorph.isAnimating,
                                  child: _buildSubmenuCard(
                                    i,
                                    effectiveSettings,
                                    effectiveQuality,
                                    rootCloseOpacity: cardsOpacity,
                                    borderRadiusOverride: cardCloseRadius,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );

    // The non-boundary Semantics(textDirection:) wrapper is load-bearing: it
    // gives OverlaySemanticsHost's delegate a mergeable config to put in the
    // sibling merge group (the barrier and menu panel are semantic boundaries
    // whose own configToMergeUp is null). Without a dismiss barrier the host
    // is off, so the menu stays next to its trigger in traversal order.
    return OverlaySemanticsHost(
      enabled: widget.showDismissBarrier,
      child: Semantics(
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        child: overlay,
      ),
    );
  }

  /// The body height used for layout this frame. The body always shows the
  /// ROOT list: a submenu opens a card over it (see [_pushSubmenu]) rather
  /// than changing the body's height.
  double _calculateMenuHeight() => _targetBodyHeight();

  /// The resting height of the menu body: the ROOT list's natural height, or
  /// the fixed [GlassMenu.menuHeight] when set.
  double _targetBodyHeight() {
    if (widget.menuHeight != null) {
      return math.min(widget.menuHeight!, _maximumStackHeight);
    }

    // Account for system text scaling when calculating natural height.
    // Without this, increased text size causes items to render taller than
    // the height budget, triggering unwanted scrolling (GitHub issue).
    final screenSize = MediaQuery.maybeSizeOf(context);

    // Sum all menu item heights, scaled by text scaler
    final itemHeights = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + _getScaledItemHeight(item, context),
    );

    // Add vertical padding (12px top + 12px bottom = 24px total)
    // plus vertical gaps between items (2px each)
    final gaps = (widget.items.length - 1) * 2.0;
    final naturalHeight =
        math.min(itemHeights + 24.0 + gaps, _maximumStackHeight);

    if (widget.autoAdjustToScreen) {
      if (screenSize != null) {
        final flutterView = View.of(context);
        final mqPadding = EdgeInsets.fromViewPadding(
            flutterView.padding, flutterView.devicePixelRatio);

        // Clamp to screen height minus safe areas and a 20px safety buffer
        var maxHeight = screenSize.height -
            mqPadding.vertical -
            widget.menuPadding.vertical -
            20.0;
        // From the vertical bar strip, to the room below its status cluster.
        final stripTop = _triggerSize == null
            ? null
            : verticalBarPresentationTop(
                context,
                _triggerGlobalPosition & _triggerSize!,
              );
        if (stripTop != null) {
          maxHeight = math.min(
            maxHeight,
            screenSize.height -
                stripTop -
                mqPadding.bottom -
                widget.menuPadding.bottom,
          );
        }
        return math.min(naturalHeight, math.max(0.0, maxHeight));
      }
    }

    return naturalHeight;
  }

  Widget _buildMorphingContainer(
    LiquidMorphState state,
    double clampedValue,
    double currentWidth,
    double currentHeight,
    double currentRadius,
    GlassQuality effectiveQuality,
    LiquidGlassSettings effectiveSettings,
  ) {
    if (currentWidth < 1.0 || currentHeight < 1.0) {
      return const SizedBox.shrink();
    }

    // Continuous iOS 27 superellipse contour with monotonic corner radius.
    final teardropShape = LiquidRoundedSuperellipse(
      borderRadius: currentRadius,
    );

    final containerScale = state.containerScale;

    final double menuWidth = widget.menuWidth.toDouble();
    final double contentScale =
        menuWidth > 0.0 ? (currentWidth / menuWidth).clamp(0.20, 1.0) : 1.0;
    // Note: On Impeller (GlassQuality.premium, useOwnLayer: false), grouped SDF
    // shapes inside AdaptiveLiquidGlassLayer remain 100% opaque until
    // !state.isPlatterActive (uShapeData[] has no per-shape opacity).
    // state.platterOpacity drives the smooth final dissolve on
    // LightweightLiquidGlass (GlassQuality.standard / Skia) and opaqueColor.
    final double platterGlassOpacity = state.platterOpacity;

    // Open: native reveals the rows late and smeared (resolving over
    // ~130–230 ms), driven by phase time. Reduce Motion / settled states keep
    // the controller's own values. C0 continuity is preserved across both
    // early-open cancellations (_closeStartContent*) and mid-close reopens
    // (_reopenStartContent*).
    final bool timedOpenContent = !_morphController.isClosing &&
        !_morphController.disableAnimations &&
        !widget.morphFromZero;
    final double phaseT = _morphController.phaseElapsedSeconds;
    final double contentInterruptDecay =
        (_reopenStartContentOpacity != null || _reopenStartContentBlur != null)
            ? math.exp(-22.0 * phaseT)
            : 0.0;
    final double baseOpenOpacity = timedOpenContent
        ? math.min(
            state.contentOpacity,
            LiquidMorphPhysics.computeOpenContentOpacity(
              elapsedSeconds: phaseT,
              openStartProgress: _morphController.openStartProgress,
            ),
          )
        : state.contentOpacity;
    final double baseOpenBlur = timedOpenContent
        ? (state.isPlatterActive
            ? LiquidMorphPhysics.computeOpenContentBlur(
                elapsedSeconds: phaseT,
                openStartProgress: _morphController.openStartProgress,
              )
            : 0.0)
        : state.contentBlurSigma;
    final double contentOpacityNow = _morphController.isClosing
        ? (state.contentOpacity * _closeStartContentOpacity).clamp(0.0, 1.0)
        : (_reopenStartContentOpacity != null
            ? lerpDouble(
                baseOpenOpacity,
                _reopenStartContentOpacity!,
                contentInterruptDecay,
              )!
            : baseOpenOpacity);
    final double contentBlurNow = _morphController.isClosing
        ? math.max(state.contentBlurSigma, _closeStartContentBlur)
        : (_reopenStartContentBlur != null
            ? lerpDouble(
                baseOpenBlur,
                _reopenStartContentBlur!,
                contentInterruptDecay,
              )!
            : baseOpenBlur);
    _lastContentOpacity = contentOpacityNow;
    _lastContentBlurSigma = contentBlurNow;

    // On Skia / Web / GlassQuality.standard, AdaptiveGlass routes to
    // LightweightLiquidGlass, which already wraps its child in
    // GlassControlledOpacity(opacity: settings.visibility) (= platterGlassOpacity).
    // Divide out platterGlassOpacity so items fade linearly as t (not t^2).
    final bool usesLightweightGlass = widget.opaqueColor == null &&
        effectiveQuality != GlassQuality.minimal &&
        !widget.platformViewBackdrop &&
        !GlassAccessibilityData.of(context).reduceTransparency &&
        !(effectiveQuality == GlassQuality.premium &&
            ImageFilter.isShaderFilterSupported);
    final double bodyItemOpacity = usesLightweightGlass
        ? (platterGlassOpacity > 1e-4
            ? (contentOpacityNow / platterGlassOpacity).clamp(0.0, 1.0)
            : 0.0)
        : contentOpacityNow;

    final outerScope = GlassMaterializeScope.maybeOf(context);

    final glassContent = GlassMaterializeScope(
      glassProgress: platterGlassOpacity * (outerScope?.glassProgress ?? 1.0),
      contentOpacity: outerScope?.contentOpacity ?? 1.0,
      contentSigma: outerScope?.contentSigma ?? 0.0,
      child: LiquidStretch(
        stretch: widget.stretch,
        interactionScale: widget.interactionScale,
        resistance: widget.stretchResistance,
        axis: widget.stretchAxis,
        suppressInteractionOnChildren: false,
        anchorStretch: false, // Menus use jelly-follow, not anchored
        allowPositiveX: widget.allowPositiveX ?? (_morphAlignment.x < 0),
        allowNegativeX: widget.allowNegativeX ?? (_morphAlignment.x > 0),
        allowPositiveY: widget.allowPositiveY ?? (_morphAlignment.y < 0),
        allowNegativeY: widget.allowNegativeY ?? (_morphAlignment.y > 0),
        child: _panelSurface(
          shape: teardropShape,
          width: currentWidth,
          height: currentHeight,
          surfaceOpacity: platterGlassOpacity,
          glass: (child) => GlassContainer(
            useOwnLayer: false, // blends with the trigger ghost
            settings: effectiveSettings,
            quality: effectiveQuality,
            platformViewBackdrop: widget.platformViewBackdrop,
            allowElevation:
                false, // Menu is overlay - don't darken when outside parent
            width: currentWidth,
            height: currentHeight,
            shape: teardropShape,
            clipBehavior: Clip.antiAlias,
            glowIntensity: widget.glowIntensity,
            child: child,
          ),
          child: _buildBodyContent(
            effectiveSettings,
            effectiveQuality,
            contentScale,
            bodyItemOpacity,
            contentOpacityNow > 0.01,
            teardropShape,
            containerScale,
            contentBlurNow,
          ),
        ),
      ),
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: widget.menuSemanticLabel ?? 'Menu',
      child: Transform.scale(
        scale: lerpDouble(1.0, _kRecedeScale, _bodyRecede)!,
        alignment: Alignment(0, _growsDown ? -1 : 1),
        child: glassContent,
      ),
    );
  }

  /// The menu body's content: the interactive root list, or the same rows
  /// dimmed and inert while a submenu card covers them.
  Widget _buildBodyContent(
    LiquidGlassSettings settings,
    GlassQuality quality,
    double contentScale,
    double contentOpacity,
    bool showContent,
    LiquidShape teardropShape,
    double containerScale,
    double contentBlurSigma,
  ) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final interactive = _submenuStack.isEmpty;
    return GlassGlow(
      enabled: widget.enableInteractionGlow && interactive,
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
        scale: containerScale,
        alignment: Alignment.center,
        child: Stack(
          alignment: _morphAlignment,
          clipBehavior: Clip.none,
          children: [
            if (showContent)
              OverflowBox(
                alignment: _morphAlignment,
                minWidth: widget.menuWidth,
                maxWidth: widget.menuWidth,
                minHeight: 0.0,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: contentScale,
                  alignment: _morphAlignment,
                  child: _blurRows(
                    contentBlurSigma,
                    _buildListContent(
                      widget.items,
                      interactive: interactive,
                      dimmed: !interactive,
                      coveredDepth: interactive ? null : 0,
                      coverProgress: _bodyRecede,
                      viewportHeight: _targetBodyHeight(),
                      itemOpacity: contentOpacity,
                      passiveScrollOffset: interactive
                          ? 0.0
                          : _submenuStack.first.sourceScrollOffset,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Close-phase width progress for the drawn trigger capsule (Blob A): the
  /// width spring evaluated [_kCloseCapsuleDelay] late, blended back to the
  /// undelayed [rawProgress] by the handoff so there is no pop.
  double _delayedCloseWidthProgress(double rawProgress) {
    if (_morphController.disableAnimations) return rawProgress;
    final t = _morphController.phaseElapsedSeconds;
    final delayed = LiquidMorphPhysics.closeTriggerWidthForElapsed(
      math.max(0.0, t - _kCloseCapsuleDelay),
      startWidthProgress: _morphController.phaseStartTriggerWidth,
    );
    final blend =
        ((t - _kCloseCapsuleDelay) / _kCloseCapsuleCatchUp).clamp(0.0, 1.0);
    return lerpDouble(delayed, rawProgress, blend)!;
  }

  /// Softens the rows while the platter collapses on close (see
  /// [LiquidMorphState.contentBlurSigma]); a no-op at rest and during open.
  Widget _blurRows(double sigma, Widget child) {
    if (sigma < 0.05) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
  }

  Widget _buildListContent(
    List<Widget> items, {
    required bool interactive,
    required bool dimmed,
    double coverProgress = 0.0,
    required double viewportHeight,
    double itemOpacity = 1.0,
    double passiveScrollOffset = 0.0,
    int? coveredDepth,
  }) {
    final coveredOpacity =
        coveredDepth == null ? 1.0 : _coveredRowOpacity(coveredDepth);
    // Hoist wrapped items once per build instead of re-allocating inside the
    // per-row loop (O(N^2) -> O(N)).
    final resolvedItems = interactive ? _buildWrappedItems() : items;
    Widget rows;
    if (coveredDepth == null) {
      // Single Column with at most 1 Opacity saveLayer (0 when opaque) instead
      // of N individual per-row Opacity widgets.
      rows = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: _kBodyVerticalPadding),
          for (var i = 0; i < resolvedItems.length; i++) ...[
            resolvedItems[i],
            if (i < resolvedItems.length - 1) const SizedBox(height: _kRowGap),
          ],
          const SizedBox(height: _kBodyVerticalPadding),
        ],
      );
      if (itemOpacity < 0.999) {
        rows = Opacity(opacity: itemOpacity, child: rows);
      }
    } else {
      rows = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: _kBodyVerticalPadding),
          for (var i = 0; i < resolvedItems.length; i++) ...[
            if (_isCoveredRow(coveredDepth, i, items))
              Opacity(
                opacity: itemOpacity * coveredOpacity,
                child: resolvedItems[i],
              )
            else if (itemOpacity < 0.999)
              Opacity(
                opacity: itemOpacity,
                child: resolvedItems[i],
              )
            else
              resolvedItems[i],
            if (i < resolvedItems.length - 1) const SizedBox(height: _kRowGap),
          ],
          const SizedBox(height: _kBodyVerticalPadding),
        ],
      );
    }
    final listBody = SizedBox(
      width: widget.menuWidth,
      height: viewportHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: interactive
            ? SingleChildScrollView(
                controller: _scrollController,
                primary: false,
                physics: _isScrollable
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: rows,
              )
            : ClipRect(
                child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: Transform.translate(
                    offset: Offset(0, -passiveScrollOffset), child: rows),
              )),
      ),
    );

    if (dimmed) {
      // A covered level: dimmed, inert, and tapping its visible part closes
      // the card over it (native iOS behavior) without running anything.
      return Opacity(
        opacity: lerpDouble(1.0, _kDimmedOpacity, coverProgress)!,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _popSubmenu,
          child: ExcludeSemantics(
            child: ExcludeFocus(child: IgnorePointer(child: listBody)),
          ),
        ),
      );
    }

    return AbsorbPointer(
        absorbing: _contentMorph.isAnimating,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sliding selection pill (background)
            ValueListenableBuilder<int?>(
              valueListenable: _hoveredIndexNotifier,
              builder: (context, hoveredIndex, _) {
                if (hoveredIndex == null) {
                  return const SizedBox.shrink();
                }
                final isDark =
                    GlassTheme.brightnessOf(context) == Brightness.dark;
                final style =
                    GlassTheme.maybeOf(context)?.data.style ?? GlassStyle.ios27;
                final effectiveSelectionColor =
                    widget.selectionColor != const Color(0x3DFFFFFF)
                        ? widget.selectionColor
                        : (style == GlassStyle.classic || isDark)
                            ? widget.selectionColor
                            : const Color(0x14000000);
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  left: 12,
                  right: 12,
                  top: _listRowTop(hoveredIndex, items) -
                      (_scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0),
                  height: _getScaledItemHeight(items[hoveredIndex], context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveSelectionColor,
                      borderRadius:
                          BorderRadius.circular(widget.itemBorderRadius),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x0DFFFFFF)
                            : const Color(0x0D000000),
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            MouseRegion(
              // A mouse resting on a row moves the selection pill there, the
              // same highlight a press-and-slide shows. The rows' own hover
              // fill is a white wash meant for dark glass and disappears on
              // light glass, so without this a pointer gets no hover at all.
              onExit: (_) {
                if (!mounted || _isDragging) return;
                _hoveredIndex = null;
                _hoveredIndexNotifier.value = null;
              },
              child: Listener(
                onPointerHover: (event) {
                  if (!mounted || _isDragging) return;
                  final index =
                      _calculateIndexFromPosition(event.localPosition, context);
                  _hoveredIndex = index;
                  _hoveredIndexNotifier.value = index;
                },
                onPointerDown: (event) {
                  if (!mounted) return;
                  _isDragging = true;
                  _isDraggingNotifier.value = true;
                  _hasStretched = false;
                  _initialScrollOffset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  _updateHoveredIndex(event.localPosition);
                },
                onPointerMove: (event) {
                  if (!mounted) return;
                  if (_isDragging) {
                    _updateHoveredIndex(event.localPosition);
                  }
                },
                onPointerUp: (event) {
                  if (!mounted) return;
                  // The row's own tap recogniser fires later in this same dispatch;
                  // it must not activate the row a second time (see
                  // _buildWrappedItems).
                  _bodyPointerUpHandled = true;
                  scheduleMicrotask(() => _bodyPointerUpHandled = false);
                  if (_isDragging) {
                    final currentOffset = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                    final scrollDisplacement =
                        (currentOffset - _initialScrollOffset).abs();

                    // Slide-to-select logic (for non-scrollable menus, tap or
                    // slide-and-release).
                    if (scrollDisplacement < 10 && !_isScrollable) {
                      final indexToTap = _hoveredIndex ??
                          _calculateIndexFromPosition(
                              event.localPosition, context);
                      if (indexToTap != null) {
                        final item = _items[indexToTap];
                        if (item is GlassMenuItem && item.enabled) {
                          _activateItem(item);
                        }
                      }
                    }
                    _isDragging = false;
                    _isDraggingNotifier.value = false;
                    _hoveredIndex = null;
                    _hoveredIndexNotifier.value = null;
                    _hasStretched = false;
                  }
                },
                onPointerCancel: (_) {
                  if (!mounted) return;
                  _isDragging = false;
                  _isDraggingNotifier.value = false;
                  _hoveredIndex = null;
                  _hoveredIndexNotifier.value = null;
                },
                child: SizedBox(
                  key: interactive ? _menuContentKey : null,
                  width: widget.menuWidth,
                  height: viewportHeight,
                  child: listBody.child!,
                ),
              ),
            ),
          ],
        ));
  }

  List<Widget> _buildWrappedItems() {
    return _cachedWrappedItems ??= _items.asMap().entries.map((entry) {
      final item = entry.value;

      if (item is GlassMenuItem) {
        return _SelectionItemWrapper(
          index: entry.key,
          hoverNotifier: _hoveredIndexNotifier,
          dragNotifier: _isDraggingNotifier,
          builder: (context, isSelected, isPressed) {
            return GlassMenuItem(
              key: item.key ?? ValueKey(item.title),
              title: item.title,
              semanticLabel: item.semanticLabel,
              subtitle: item.subtitle,
              icon: item.icon,
              isDestructive: item.isDestructive,
              enabled: item.enabled,
              trailing: item.trailing,
              height: item.height,
              titleStyle: item.titleStyle,
              subtitleStyle: item.subtitleStyle,
              iconColor: item.iconColor,
              semanticsChecked: item.semanticsChecked,
              iconSize: item.iconSize,
              maxLines: item.maxLines,
              closeDelay: item.closeDelay,
              enablePressScale: item.enablePressScale,
              submenu: item.submenu,
              isSelected: isSelected,
              isPressed: isPressed,
              semanticsSelected: item.semanticsSelected,
              onTap: () {
                if (!item.enabled) return;
                // For scrollable menus, we delegate taps to the native GestureDetector
                // so it can properly participate in the gesture arena with the ScrollView.
                if (_isScrollable) {
                  _activateItem(item);
                  return;
                }
                // Non-scrollable menus activate touches from the body
                // Listener (slide-to-select), which runs first and marks the
                // pointer event as handled. An onTap with no pointer behind
                // it is a keyboard or assistive-technology activation
                // (VoiceOver / TalkBack), which must still work.
                if (_bodyPointerUpHandled) return;
                _activateItem(item);
              },
            );
          },
        );
      }
      return item;
    }).toList();
  }

  bool get _isScrollable {
    return (_submenuStack.isEmpty && widget.menuHeight != null) ||
        _activeHeight < _listHeight(_items) - 1.0;
  }

  double get _activeHeight => _submenuStack.isEmpty
      ? _targetBodyHeight()
      : _cardRect(_submenuStack.length - 1).height;

  double get _maximumStackHeight {
    final external = widget.maxStackHeight ?? double.infinity;
    if (!widget.autoAdjustToScreen) return external;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final padVertical = MediaQuery.paddingOf(context).vertical;
    return math.min(
        external,
        math.max(0.0,
            screenHeight - padVertical - widget.menuPadding.vertical - 20));
  }

  double _visibleListHeight(List<Widget> items) =>
      math.min(_listHeight(items), _maximumStackHeight);

  /// Accounts for system text scaling.
  ///
  /// When the user increases the system text size, GlassMenuItem renders
  /// with scaled text inside a ConstrainedBox (minHeight). The text content
  /// may push the actual height beyond the nominal [GlassMenuItem.height].
  /// This method estimates the rendered height to prevent the menu from
  /// becoming scrollable when it shouldn't be.
  double _getScaledItemHeight(Widget item, BuildContext context) {
    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;

    if (item is GlassMenuItem) {
      // The item has 8px vertical padding top + bottom = 16px fixed chrome.
      // The remaining space is text content that scales with system text size.
      const fixedPadding = 16.0;
      final baseFontSize = item.titleStyle?.fontSize ?? 17.0;
      final scaledFontSize = textScaler.scale(baseFontSize);
      final lineHeight = scaledFontSize * 1.2; // Approximate line height
      final textHeight = lineHeight * item.maxLines;

      // Subtitle adds another scaled line
      double subtitleHeight = 0;
      if (item.subtitle != null) {
        final subFontSize = item.subtitleStyle?.fontSize ?? 13.0;
        subtitleHeight = textScaler.scale(subFontSize) * 1.2;
      }

      final contentHeight = textHeight + subtitleHeight + fixedPadding;
      // Use the larger of nominal height or scaled content height
      return math.max(item.height, contentHeight);
    }
    // Dividers and labels don't contain user-facing scaled text
    if (item is GlassMenuDivider) return item.height;
    if (item is GlassMenuLabel) return item.height;
    if (item is PreferredSizeWidget) return item.preferredSize.height;
    return 44.0;
  }

  int? _calculateIndexFromPosition(Offset localPosition, BuildContext context) {
    final visibleHeight = _activeHeight;
    final x = localPosition.dx;
    final dy = localPosition.dy;
    final y =
        dy + (_scrollController.hasClients ? _scrollController.offset : 0.0);

    final isWithinActiveZone = x > -20 &&
        x < widget.menuWidth + 20 &&
        dy > -20 &&
        dy < visibleHeight + 20;

    if (!isWithinActiveZone) return null;

    double currentOffset = 12.0;
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final itemHeight = _getScaledItemHeight(item, context);

      // Rows own half of each 2 px gap on either side, so the hit zones are
      // contiguous: a release between two rows activates the nearer row
      // instead of silently doing nothing.
      if (y >= currentOffset - 1.0 && y < currentOffset + itemHeight + 1.0) {
        if (item is GlassMenuItem && item.enabled) {
          return i;
        }
        break;
      }
      currentOffset += itemHeight + 2.0; // height + 2px gap
    }
    return null;
  }

  void _updateHoveredIndex(Offset localPosition) {
    // Detect if we've moved into "stretch territory" (outside visible menu bounds)
    final visibleHeight = _activeHeight;
    final x = localPosition.dx;
    final dy = localPosition.dy;

    // We add a 100px buffer to allow for intense liquid stretching without accidental closure.
    // We also allow cancelling the stretch if the user moves their finger back.
    final outsideBounds = dy < -100 ||
        dy > visibleHeight + 100 ||
        x < -100 ||
        x > widget.menuWidth + 100;

    if (_hasStretched != outsideBounds) {
      setState(() => _hasStretched = outsideBounds);
    }

    int? detectedIndex;

    // Only calculate hover selection for non-scrollable menus (slide-to-select).
    if (!_isScrollable) {
      detectedIndex = _calculateIndexFromPosition(localPosition, context);
    }

    _hoveredIndex = detectedIndex;
    _hoveredIndexNotifier.value = detectedIndex;
  }
}

/// Internal helper to update selection state for cached items.
class _SelectionItemWrapper extends StatelessWidget {
  final int index;
  final ValueNotifier<int?> hoverNotifier;
  final ValueNotifier<bool> dragNotifier;
  final Widget Function(BuildContext context, bool isSelected, bool isPressed)
      builder;

  const _SelectionItemWrapper({
    required this.index,
    required this.hoverNotifier,
    required this.dragNotifier,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: hoverNotifier,
      builder: (context, hoveredIndex, _) {
        final isSelected = hoveredIndex == index;
        return ValueListenableBuilder<bool>(
          valueListenable: dragNotifier,
          builder: (context, isDragging, _) {
            return builder(context, isSelected, isDragging && isSelected);
          },
        );
      },
    );
  }
}

const Duration _kSubmenuMorphDuration = Duration(milliseconds: 320);
const Curve _kSubmenuMorphCurve = Curves.easeOutCubic;
const double _kBodyVerticalPadding = 12.0;
const double _kRowGap = 2.0;

/// How late (seconds) the drawn trigger capsule trails the close width spring.
const double _kCloseCapsuleDelay = 0.05;

/// Seconds over which the delayed capsule catches back up to the spring.
const double _kCloseCapsuleCatchUp = 0.23;

const LiquidGlassSettings _kDefaultMenuSettings = LiquidGlassSettings(
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

/// Geometry is captured before switching the active scroll viewport. Titles
/// are not identifiers: two rows may have the same label.
class _SubmenuLevel {
  const _SubmenuLevel({
    required this.list,
    required this.sourceIndex,
    required this.sourceRowTop,
    required this.sourceRowHeight,
    required this.sourceScrollOffset,
  });

  final List<Widget> list;

  /// The parent row's index in the list below this card.
  final int sourceIndex;
  final double sourceRowTop;
  final double sourceRowHeight;
  final double sourceScrollOffset;

  /// The same level over a rebuilt [list].
  _SubmenuLevel withList(List<Widget> list) => _SubmenuLevel(
        list: list,
        sourceIndex: sourceIndex,
        sourceRowTop: sourceRowTop,
        sourceRowHeight: sourceRowHeight,
        sourceScrollOffset: sourceScrollOffset,
      );
}

/// The source row repeated as a collapsible header, not a generic Back action.
class _GlassMenuHeaderItem extends GlassMenuItem {
  const _GlassMenuHeaderItem({
    super.key,
    required super.title,
    super.icon,
    super.height,
    super.titleStyle,
    super.iconColor,
    super.iconSize,
    super.enablePressScale,
  }) : super(
            trailing: const Icon(CupertinoIcons.chevron_down, size: 16),
            onTap: _noop);

  static void _noop() {}
}
