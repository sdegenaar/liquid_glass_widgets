part of '../glass_popover.dart';

class _GlassPopoverState extends State<GlassPopover>
    with TickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final GlassMorphController _morphController;

  Size? _triggerSize;
  double? _triggerBorderRadius;
  Offset _triggerGlobalPosition = Offset.zero;
  double _horizontalOffset = 0.0;
  double _verticalOffset = 0.0;

  Alignment _morphAlignment = Alignment.topLeft;

  /// Measured intrinsic height of the popover content.
  /// Only used when [widget.popoverHeight] is null.
  double? _measuredContentHeight;

  /// Key for the content measurement widget.
  final GlobalKey _contentKey = GlobalKey();

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
    _morphController = GlassMorphController(vsync: this);
    _morphController.addListener(() {
      if (mounted) setState(() {});

      // Hide overlay only when the spring has FULLY SETTLED near 0.
      // Velocity guard prevents premature hiding on first zero-crossing
      // during the underdamped close bounce.
      if (_overlayController.isShowing &&
          _morphController.value <= 0.001 &&
          _morphController.velocity.abs() < 0.5 &&
          _morphController.status != AnimationStatus.forward) {
        _overlayController.hide();
        // Reset screen-edge clamping offsets so stale values from a previous
        // open position don't bleed into the next open cycle.
        _horizontalOffset = 0.0;
        _verticalOffset = 0.0;
        _measuredContentHeight = null;
      }
    });
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync the reduced-motion accessibility flag to the morph controller.
    _morphController.setDisableAnimations(
      MediaQuery.of(context).disableAnimations,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphController.animation,
      builder: (context, child) {
        final rawValue = _morphController.value;

        // Block trigger taps while popover is significantly open.
        final isPopoverBlocking =
            _overlayController.isShowing && rawValue > 0.8;

        // Early handoff during close:
        // When closing and the liquid morph is almost finished, we latch the
        // handoff. We instantly hide the empty glass overlay and reveal the
        // REAL trigger.
        final isHandoff =
            _morphController.isClosing && _morphController.hasHandedOff;
        final triggerOpacity =
            (_overlayController.isShowing && !isHandoff) ? 0.0 : 1.0;

        // Calculate the momentum push vector based on the exact same logic
        // as Blob B so the real trigger precisely inherits the menu's
        // momentum trajectory.
        final tw = _triggerSize?.width ?? 44.0;
        final th = _triggerSize?.height ?? 44.0;
        final popoverWidth = widget.popoverWidth;
        final popoverHeight = _effectivePopoverHeight();
        final dxMag = (popoverWidth - tw) / 2.0;
        final dyMag = (popoverHeight - th) / 2.0;
        final finalDx = -_morphAlignment.x * dxMag;
        final finalDy = -_morphAlignment.y * dyMag;

        // Apply the push momentum to the real trigger during the underdamped
        // bounce. Include the offsets so the trajectory is mathematically
        // perfect.
        final double pushDx =
            isHandoff ? (finalDx + _horizontalOffset) * rawValue : 0.0;
        final double pushDy =
            isHandoff ? (finalDy + _verticalOffset) * rawValue : 0.0;

        return Stack(
          children: [
            // Trigger — physically bounces when slammed by the closing popover
            Transform.translate(
              offset: Offset(pushDx, pushDy),
              child: Opacity(
                opacity: triggerOpacity,
                child: IgnorePointer(
                  ignoring: isPopoverBlocking,
                  child: widget.triggerBuilder != null
                      ? widget.triggerBuilder!(context, _togglePopover)
                      : GestureDetector(
                          onTap: _togglePopover,
                          child: widget.trigger,
                        ),
                ),
              ),
            ),

            // Overlay portal for morphing animation
            OverlayPortal(
              controller: _overlayController,
              overlayChildBuilder: _buildMorphingOverlay,
            ),
          ],
        );
      },
    );
  }

  void _togglePopover() {
    if (_overlayController.isShowing && _morphController.value > 0.1) {
      _closePopover();
    } else {
      _openPopover();
    }
  }

  void _closePopover() {
    if (!mounted) return;
    // GlassMorphController.close() injects the -2.5 velocity hint internally,
    // maximising the rubber-band bounce amplitude at close.
    _morphController.close();
    widget.onClose?.call();
  }

  void _openPopover() {
    // Capture geometry and screen position for morphing
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    _triggerSize = renderBox.size;
    _triggerBorderRadius = _triggerSize!.height / 2;
    _triggerGlobalPosition = renderBox.localToGlobal(Offset.zero);
    final position = _triggerGlobalPosition;
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? double.infinity;
    final screenHeight = mediaQuery?.size.height ?? double.infinity;

    final popoverHeight = _effectivePopoverHeight();

    // 1. Determine base alignment (Auto vs Manual)
    if (widget.alignment == null ||
        widget.alignment == GlassMenuAlignment.none) {
      final isRightHalf = screenWidth.isFinite && position.dx > screenWidth / 2;

      final spaceBelow = screenHeight.isFinite
          ? screenHeight - (position.dy + _triggerSize!.height)
          : double.infinity;
      final spaceAbove = screenHeight.isFinite ? position.dy : double.infinity;

      final shouldFlipVertical =
          spaceBelow < popoverHeight && spaceAbove > popoverHeight;

      if (shouldFlipVertical) {
        _morphAlignment =
            isRightHalf ? Alignment.bottomRight : Alignment.bottomLeft;
      } else {
        _morphAlignment = isRightHalf ? Alignment.topRight : Alignment.topLeft;
      }
    } else {
      _morphAlignment = _getAlignment(widget.alignment!) ?? Alignment.center;
    }

    // 2. Clamping: calculate offsets to keep popover within screen bounds
    double hOffset = 0.0;
    double vOffset = 0.0;

    if (widget.autoAdjustToScreen) {
      final flutterView = View.of(context);
      final mqPadding = EdgeInsets.fromViewPadding(
          flutterView.padding, flutterView.devicePixelRatio);

      final double safeTop = widget.screenPadding.top + mqPadding.top;
      final double safeBottom = widget.screenPadding.bottom + mqPadding.bottom;
      final double safeLeft = widget.screenPadding.left + mqPadding.left;
      final double safeRight = widget.screenPadding.right + mqPadding.right;

      // Calculate global popover position
      final double targetX =
          position.dx + (1 + _morphAlignment.x) * _triggerSize!.width / 2;
      final double targetY =
          position.dy + (1 + _morphAlignment.y) * _triggerSize!.height / 2;
      final double popoverLeft =
          targetX - (1 + _morphAlignment.x) * widget.popoverWidth / 2;
      final double popoverTop =
          targetY - (1 + _morphAlignment.y) * popoverHeight / 2;

      // Horizontal adjustment
      if (popoverLeft < safeLeft) {
        hOffset = safeLeft - popoverLeft;
      } else if (screenWidth.isFinite &&
          popoverLeft + widget.popoverWidth > screenWidth - safeRight) {
        hOffset =
            (screenWidth - safeRight) - (popoverLeft + widget.popoverWidth);
      }

      // Vertical adjustment
      if (popoverTop < safeTop) {
        vOffset = safeTop - popoverTop;
      } else if (screenHeight.isFinite &&
          popoverTop + popoverHeight > screenHeight - safeBottom) {
        vOffset = (screenHeight - safeBottom) - (popoverTop + popoverHeight);
      }
    }

    setState(() {
      _horizontalOffset = hOffset;
      _verticalOffset = vOffset;
    });

    _overlayController.show();
    _morphController.open();
    widget.onOpen?.call();
  }

  double _effectivePopoverHeight() {
    // If explicit height is set, use that.
    if (widget.popoverHeight != null) {
      return widget.popoverHeight!;
    }

    // Use measured content height if available, otherwise estimate.
    // The estimate is used on the first frame before measurement.
    return _measuredContentHeight ?? 200.0;
  }

  Widget _buildMorphingOverlay(BuildContext context) {
    if (_triggerSize == null) return const SizedBox.shrink();

    final rawValue = _morphController.value;
    final clampedValue = rawValue.clamp(0.0, 1.0);

    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final popoverWidth = widget.popoverWidth;
    final popoverHeight = _effectivePopoverHeight();

    final dxMag = (popoverWidth - tw) / 2.0;
    final dyMag = (popoverHeight - th) / 2.0;
    final finalDx = -_morphAlignment.x * dxMag;
    final finalDy = -_morphAlignment.y * dyMag;

    // Delegate physics to GlassMorphController
    final state = _morphController.computeState(
      finalDx: finalDx,
      finalDy: finalDy,
      horizontalOffset: _horizontalOffset,
      verticalOffset: _verticalOffset,
    );

    final targetHeight = popoverHeight;
    final currentHeight = lerpDouble(th, targetHeight, state.sizeT)!;
    final currentWidth = lerpDouble(tw, popoverWidth, state.sizeT)!;

    final inheritedSettings = InheritedLiquidGlass.of(context);
    final effectiveSettings = widget.settings ??
        inheritedSettings ??
        const LiquidGlassSettings(
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

    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    return Stack(
      children: [
        // Invisible full-screen tap-to-close barrier
        if (clampedValue > 0.3 && widget.barrierDismissible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closePopover,
              child: Container(color: Colors.black.withValues(alpha: 0.0)),
            ),
          ),

        // Non-dismissible barrier (still blocks taps to underlying content)
        if (clampedValue > 0.3 && !widget.barrierDismissible)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Container(color: Colors.black.withValues(alpha: 0.0)),
            ),
          ),

        // ── Two-Blob Metaball Morphing ──────────────────────────────────
        Positioned.fill(
          child: Opacity(
            opacity:
                (_morphController.isClosing && _morphController.hasHandedOff)
                    ? 0.0
                    : 1.0,
            child: LiquidGlassLayer(
              settings: effectiveSettings,
              child: InheritedLiquidGlass(
                settings: effectiveSettings,
                quality: effectiveQuality,
                isBlurProvidedByAncestor: false,
                child: LiquidGlassBlendGroup(
                  blend: state.blend,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── Blob A: Trigger Ghost ─────────────────────────
                      // Stays perfectly centered on the trigger, shrinks to
                      // 0 scale over the first 40% of the animation to
                      // smoothly break the liquid bridge.
                      Positioned(
                        left: _triggerGlobalPosition.dx + state.pushDx,
                        top: _triggerGlobalPosition.dy + state.pushDy,
                        child: Transform.scale(
                          scale: state.anchorScale,
                          child: GlassContainer(
                            useOwnLayer: false,
                            settings: effectiveSettings,
                            quality: effectiveQuality,
                            width: tw,
                            height: th,
                            shape: LiquidRoundedSuperellipse(
                              borderRadius: _triggerBorderRadius ??
                                  _triggerSize!.shortestSide / 2.0,
                            ),
                          ),
                        ),
                      ),

                      // ── Blob B: Popover Body ─────────────────────────
                      Positioned(
                        left: _triggerGlobalPosition.dx +
                            tw / 2.0 +
                            state.currentDx -
                            currentWidth / 2.0 +
                            (_horizontalOffset * clampedValue),
                        top: _triggerGlobalPosition.dy +
                            th / 2.0 +
                            state.currentDy -
                            currentHeight / 2.0 +
                            (_verticalOffset * clampedValue),
                        child: IgnorePointer(
                          ignoring: clampedValue < 0.8,
                          child: _buildPopoverContainer(
                            state,
                            clampedValue,
                            currentWidth,
                            currentHeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopoverContainer(
    LiquidMorphState state,
    double clampedValue,
    double currentWidth,
    double currentHeight,
  ) {
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    // Morph border radius from pill to target
    final maxRadius = math.min(currentWidth, currentHeight) / 2.0;
    final double radiusT =
        Curves.easeInExpo.transform(state.sizeT.clamp(0.0, 1.0));
    final currentRadius =
        lerpDouble(maxRadius, widget.popoverBorderRadius, radiusT)!;

    final teardropShape = LiquidRoundedSuperellipse(
      borderRadius: currentRadius,
    );

    final containerScale = state.containerScale;

    final inheritedSettings = InheritedLiquidGlass.of(context);
    final effectiveSettings = widget.settings ??
        inheritedSettings ??
        const LiquidGlassSettings(
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

    return LiquidStretch(
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
        allowElevation: false,
        width: currentWidth,
        height: currentHeight,
        shape: teardropShape,
        clipBehavior: Clip.antiAlias,
        glowIntensity: widget.glowIntensity,
        child: Builder(builder: (context) {
          final isDark =
              CupertinoTheme.brightnessOf(context) == Brightness.dark;
          return GlassGlow(
            enabled: widget.enableInteractionGlow,
            glowOnTapOnly: widget.glowOnTapOnly,
            glowColor: widget.glowColor ??
                (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.10)),
            glowRadius: widget.glowRadius,
            glowBlurRadius: 40,
            clipper: ShapeBorderClipper(
              shape: teardropShape,
            ),
            child: Transform.scale(
              scale: containerScale,
              alignment: Alignment.center,
              child: Stack(
                alignment: _morphAlignment,
                clipBehavior: Clip.none,
                children: [
                  // Content scales up with the container morph — enters the
                  // tree at 30% and scales from 0.5× to 1.0×. On close the
                  // reverse plays: content shrinks back down with the
                  // collapsing container, matching GlassMenu behaviour.
                  if (clampedValue > 0.3)
                    _buildContentWithMeasurement(clampedValue),
                ],
              ),
            ),
          ); // GlassGlow
        }), // Builder
      ),
    );
  }

  Widget _buildContentWithMeasurement(double clampedValue) {
    // Fade content in smoothly: fully opaque by 70% morph progress.
    final contentOpacity = ((clampedValue - 0.3) / 0.4).clamp(0.0, 1.0);

    // Scale content from 0.5× to 1.0× with easeOut so it grows alongside
    // the expanding glass container (matches GlassMenu behaviour).
    final contentScale = lerpDouble(
      0.5,
      1.0,
      Curves.easeOut.transform(
        ((clampedValue - 0.3) / 0.7).clamp(0.0, 1.0),
      ),
    )!;

    final content = widget.contentBuilder(context, _closePopover);

    Widget measuredContent;
    if (widget.popoverHeight == null) {
      measuredContent = SizedBox(
        key: _contentKey,
        width: widget.popoverWidth,
        child: content,
      );

      // Measure after this frame's layout completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final renderBox =
            _contentKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize && mounted) {
          final height = renderBox.size.height;
          if (_measuredContentHeight != height) {
            setState(() {
              _measuredContentHeight = height;
            });
          }
        }
      });
    } else {
      measuredContent = SizedBox(
        width: widget.popoverWidth,
        height: widget.popoverHeight,
        child: content,
      );
    }

    // Provide full target dimensions during layout so the content Column
    // doesn't overflow inside the still-morphing container. The visual scale
    // transform handles the size illusion; the GlassContainer's Clip.antiAlias
    // clips anything outside the morph boundary.
    final targetHeight =
        widget.popoverHeight ?? _measuredContentHeight ?? 200.0;

    return OverflowBox(
      alignment: Alignment.center,
      minWidth: widget.popoverWidth,
      maxWidth: widget.popoverWidth,
      minHeight: 0,
      maxHeight: targetHeight,
      child: Opacity(
        opacity: contentOpacity,
        child: Transform.scale(
          scale: contentScale,
          child: measuredContent,
        ),
      ),
    );
  }
}
