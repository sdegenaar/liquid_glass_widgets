part of '../glass_menu.dart';

class _GlassMenuState extends State<GlassMenu> with TickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final AnimationController _animationController;
  late final ScrollController _scrollController;
  Size? _triggerSize;
  double? _triggerBorderRadius;
  Offset _triggerGlobalPosition = Offset.zero; // captured in _openMenu
  int? _hoveredIndex;
  bool _isDragging = false;
  bool _hasStretched =
      false; // Prevents closing if we moved into stretch territory
  double _initialScrollOffset = 0.0;
  Offset _initialLocalPosition = Offset.zero;
  double _horizontalOffset = 0.0;
  double _verticalOffset = 0.0;

  // --- Granular Update System (Performance + No flicker) ---
  // We cache the outer list but use notifiers to update selection state
  // without rebuilding the entire menu tree.
  late final ValueNotifier<int?> _hoveredIndexNotifier;
  late final ValueNotifier<bool> _isDraggingNotifier;
  List<Widget>? _cachedWrappedItems;

  @override
  void didUpdateWidget(GlassMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.items, oldWidget.items)) {
      _cachedWrappedItems = null;
      // BUG 12 FIX: Clear hover state if items shrink while menu is open
      // to prevent RangeError when the selection pill tries to measure
      // a now-deleted index.
      if (widget.items.length < oldWidget.items.length) {
        _hoveredIndex = null;
        _hoveredIndexNotifier.value = null;
      }
    }
  }

  // ─── iOS 26 Spring Physics ────────────────────────────────────────────────
  //
  // OPEN — fast and clean (ζ≈0.69): no bounce, ~0.28s settle.
  //   Teardrop forms quickly, content reveals smoothly.
  //   ω₀ = √360 ≈ 19.0 rad/s
  //   ζ  = 26 / (2×19.0) ≈ 0.68 — slightly underdamped, clean settle
  // SLOW-MOTION DIAGNOSTIC — restore to stiffness: 360/350, damping: 26/35 after validation
  static const _openSpring = SpringDescription(
    mass: 1.0,
    stiffness: 30.0,
    damping: 8.0,
  );

  // CLOSE — critically damped for a smooth, bounceless merge back into
  // the trigger button. No liquid splash/overshoot on return.
  //   ω₀ = √350 ≈ 18.7 rad/s
  //   ζ  = 35 / (2×18.7) ≈ 0.93 — near-critically damped, no bounce
  // SLOW-MOTION DIAGNOSTIC: stiffness 25, critical damping = 10
  static const _closeSpring = SpringDescription(
    mass: 1.0,
    stiffness: 25.0,
    damping: 10.0,
  );

  Alignment _morphAlignment = Alignment.topLeft;

  Alignment? _getAlignment(GlassMenuAlignment align) {
    switch (align) {
      case GlassMenuAlignment.none:
        return null;

      // When the user selects "Left", we return "Right" alignment.
      // This anchors the menu's RIGHT edge to the button's RIGHT edge,
      // causing the menu body to expand to the LEFT (away from the button).
      case GlassMenuAlignment.topLeft:
        return Alignment.topRight;
      case GlassMenuAlignment.topCenter:
        return Alignment.topCenter;
      case GlassMenuAlignment.topRight:
        return Alignment.topLeft;
      case GlassMenuAlignment.centerLeft:
        return Alignment.centerRight;
      case GlassMenuAlignment.center:
        return Alignment.center;
      case GlassMenuAlignment.centerRight:
        return Alignment.centerLeft;
      case GlassMenuAlignment.bottomLeft:
        return Alignment.bottomRight;
      case GlassMenuAlignment.bottomCenter:
        return Alignment.bottomCenter;
      case GlassMenuAlignment.bottomRight:
        return Alignment.bottomLeft;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this);
    _animationController.addListener(() {
      if (mounted) setState(() {});

      // Hide overlay only when the spring has FULLY SETTLED near 0.
      // Velocity guard prevents premature hiding on first zero-crossing
      // during the underdamped close bounce — without this, the overlay
      // disappears at ~165ms and the rubber-band bounces are never seen.
      if (_overlayController.isShowing &&
          _animationController.value <= 0.001 &&
          _animationController.velocity.abs() < 0.5 &&
          _animationController.status != AnimationStatus.forward) {
        _overlayController.hide();
      }
    });
    _scrollController = ScrollController();
    _hoveredIndexNotifier = ValueNotifier(null);
    _isDraggingNotifier = ValueNotifier(false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _hoveredIndexNotifier.dispose();
    _isDraggingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawValue = _animationController.value;

    // The blob IS the button from frame 0 — same position, same shape,
    // fully opaque. We hide the underlying trigger whenever the overlay is
    // open so it doesn't double-render underneath the morphing blob.
    // Instantly hide the real trigger to prevent double-glass rendering artifacts
    // where the glass overlay stacks on top of the glass button.
    final triggerOpacity = _overlayController.isShowing ? 0.0 : 1.0;

    // Block trigger taps while menu is significantly open.
    final isMenuBlocking = _overlayController.isShowing && rawValue > 0.8;

    return Stack(
      children: [
        // Trigger — hidden while blob is the visual stand-in.
        Opacity(
          opacity: triggerOpacity,
          child: IgnorePointer(
            ignoring: isMenuBlocking,
            child: widget.triggerBuilder != null
                ? widget.triggerBuilder!(context, _toggleMenu)
                : GestureDetector(
                    onTap: _toggleMenu,
                    child: widget.trigger,
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
  }

  /// Runs a spring simulation toward [target].
  ///
  /// [velocityHint] is the gesture velocity (in logical pixels/s) that is
  /// injected as the spring's initial velocity, normalised to the 0–1 animation
  /// space.  A positive value means the gesture was moving in the "open"
  /// direction; negative means closing.  Defaults to 0 (tap with no drag).
  void _runSpring(double target, {double velocityHint = 0.0}) {
    // Select spring profile based on direction.
    final spring = target > 0.5 ? _openSpring : _closeSpring;
    final simulation = SpringSimulation(
      spring,
      _animationController.value,
      target,
      velocityHint, // Inject gesture velocity for organic feel
    );
    _animationController.animateWith(simulation);
  }

  void _toggleMenu() {
    if (_overlayController.isShowing && _animationController.value > 0.1) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    // Capture geometry and screen position for morphing
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // Safety: Cannot open menu if render box is not ready
      return;
    }

    _triggerSize = renderBox.size;
    _triggerBorderRadius = _triggerSize!.height / 2;
    _triggerGlobalPosition = renderBox.localToGlobal(Offset.zero); // store for overlay
    final position = _triggerGlobalPosition;
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? double.infinity;
    final screenHeight = mediaQuery?.size.height ?? double.infinity;

    // Calculate menu height for vertical boundary check
    final menuHeight = _calculateMenuHeight();

    // 1. Determine base alignment (Auto vs Manual)
    if (widget.menuAlignment == null ||
        widget.menuAlignment == GlassMenuAlignment.none) {
      // Horizontal alignment: left vs right half
      final isRightHalf = screenWidth.isFinite && position.dx > screenWidth / 2;

      // Vertical alignment: check if menu would overflow bottom
      final spaceBelow = screenHeight.isFinite
          ? screenHeight - (position.dy + _triggerSize!.height)
          : double.infinity;
      final spaceAbove = screenHeight.isFinite ? position.dy : double.infinity;

      // Prefer downward opening unless insufficient space
      final shouldFlipVertical =
          spaceBelow < menuHeight && spaceAbove > menuHeight;

      if (shouldFlipVertical) {
        _morphAlignment =
            isRightHalf ? Alignment.bottomRight : Alignment.bottomLeft;
      } else {
        _morphAlignment = isRightHalf ? Alignment.topRight : Alignment.topLeft;
      }
    } else {
      // MANUAL: Use provided alignment with inverted mapping
      _morphAlignment =
          _getAlignment(widget.menuAlignment!) ?? Alignment.center;
    }

    // 2. Clamping: calculate offsets to keep menu within screen bounds
    double hOffset = 0.0;
    double vOffset = 0.0;

    if (widget.autoAdjustToScreen) {
      final padding = widget.menuPadding;

      // Calculate global menu position
      final double targetX =
          position.dx + (1 + _morphAlignment.x) * _triggerSize!.width / 2;
      final double targetY =
          position.dy + (1 + _morphAlignment.y) * _triggerSize!.height / 2;
      final double menuLeft =
          targetX - (1 + _morphAlignment.x) * widget.menuWidth / 2;
      final double menuTop = targetY - (1 + _morphAlignment.y) * menuHeight / 2;

      // Horizontal adjustment
      if (menuLeft < padding.left) {
        hOffset = padding.left - menuLeft;
      } else if (screenWidth.isFinite &&
          menuLeft + widget.menuWidth > screenWidth - padding.right) {
        hOffset = (screenWidth - padding.right) - (menuLeft + widget.menuWidth);
      }

      // Vertical adjustment
      if (menuTop < padding.top) {
        vOffset = padding.top - menuTop;
      } else if (screenHeight.isFinite &&
          menuTop + menuHeight > screenHeight - padding.bottom) {
        vOffset = (screenHeight - padding.bottom) - (menuTop + menuHeight);
      }
    }

    setState(() {
      _horizontalOffset = hOffset;
      _verticalOffset = vOffset;
    });

    _overlayController.show();
    // No velocity hint: overdamped spring starts from rest for a clean,
    // smooth teardrop expansion with no artificial kick.
    _runSpring(1.0, velocityHint: 0.0);
  }

  void _closeMenu() {
    setState(() {
      _hoveredIndex = null;
      _isDragging = false;
    });
    // Strong initial kick: immediately drives the blob into fast collapse,
    // maximising the visible rubber-band bounce amplitude at the end.
    _runSpring(0.0, velocityHint: -2.5);
  }

  Widget _buildMorphingOverlay(BuildContext context) {
    if (_triggerSize == null) return const SizedBox.shrink();

    final value = _animationController.value.clamp(0.0, 1.0);

    final isUp = _morphAlignment.y > 0; // bottomLeft/Right → opens upward
    final isRight = _morphAlignment.x > 0; // right-side trigger

    final tw = _triggerSize!.width;
    final th = _triggerSize!.height;
    final menuWidth = widget.menuWidth.toDouble();
    final menuHeight = _calculateMenuHeight();

    // The destination of the menu center relative to the trigger center.
    // By setting dyMag to exactly (menuHeight - th) / 2.0, the final menu 
    // will perfectly align its top edge with the trigger's top edge, effectively
    // "covering" the faded out menu button.
    final dxMag = (menuWidth - tw) / 2.0;
    final dyMag = (menuHeight - th) / 2.0;
    final finalDx = isRight ? -dxMag : dxMag;
    final finalDy = isUp ? -dyMag : dyMag;

    // ─── Liquid Physics Interpolation ─────────────────────────────────────────
    //
    // The true iOS droplet effect uses independent curves for its trajectory (path)
    // and its scale (size).
    //
    // OPEN: Center drops fast (easeOut), size expands slow (easeInOut).
    // Result: A small, roundish blob drops down and left, and THEN expands UP 
    // and right to cover the button space.
    //
    // CLOSE: Center lingers at bottom (easeOut), size collapses fast (easeIn).
    // Result: Menu shrinks top and bottom into a blob, then shoots UP to the button.
    final isClosing = _animationController.velocity <= 0;
    double pathT;
    double sizeT;

    if (!isClosing) {
      pathT = Curves.easeOutQuart.transform(value);
      sizeT = Curves.easeInOutQuart.transform(value);
    } else {
      pathT = Curves.easeOutQuart.transform(value);
      sizeT = Curves.easeInQuart.transform(value);
    }

    final currentDx = finalDx * pathT;
    final currentDy = finalDy * pathT;

    final targetHeight = widget.menuHeight ?? menuHeight;
    final currentHeight = lerpDouble(th, targetHeight, sizeT)!;
    final currentWidth = lerpDouble(tw, widget.menuWidth, sizeT)!;

    // ─── Anchor Blob A Scaling ──────────────────────────────────────────────
    // Blob A acts as the "ghost" at the origin to anchor the liquid bridge.
    // To completely eliminate the "bigger circle" metaball inflation when 
    // the shapes perfectly overlap (frame 0), we animate the blend parameter 
    // itself based on how separated the blobs are.
    // This allows the shader to naturally handle the teardrop string snapping
    // without manual scale hacking.
    final double blobAEase = 1.0;

    // The separation between the position curve (pathT) and size curve (sizeT)
    // represents how far Blob B has pulled away from its anchor corner.
    // When separation is 0 (frame 0, and frame end), they perfectly overlap.
    // By scaling blend with separation, we ensure 0 swell when overlapping, 
    // and full 28.0 liquid teardrop blend when pulled apart!
    final separation = (pathT - sizeT).abs();
    final double currentBlend = (separation * 150.0).clamp(0.0, 28.0);

    final inheritedSettings = InheritedLiquidGlass.of(context);
    final effectiveSettings = widget.glassSettings ??
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
        if (value > 0.3)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeMenu,
              child: Container(color: Colors.black.withValues(alpha: 0.0)),
            ),
          ),

        // ── Two-Blob Metaball Morphing ───────────────────────────────────────
        //
        // We use LiquidGlassLayer at the root to create the transparent blend group.
        // Inside it, we use two CompositedTransformFollowers, BOTH anchored to the
        // trigger's center. This avoids manual coordinate math and prevents pixel drift.
        Positioned.fill(
          child: LiquidGlassLayer(
            settings: effectiveSettings,
            child: InheritedLiquidGlass(
              settings: effectiveSettings,
              quality: effectiveQuality,
              isBlurProvidedByAncestor: false,
              child: LiquidGlassBlendGroup(
                blend: currentBlend,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Blob A: Trigger Ghost ───────────────────────────────
                    // Stays perfectly centered on the trigger.
                    // Shrinks to 0 scale over the first 50% of the animation to
                    // smoothly break the liquid bridge.
                    Positioned(
                      left: _triggerGlobalPosition.dx,
                      top: _triggerGlobalPosition.dy,
                      child: Transform.scale(
                        scale: blobAEase,
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

                    // ── Blob B: Menu Body ───────────────────────────────────
                    // Its center travels diagonally relative to the trigger.
                    // By scaling the x/y offsets with the width/height curves,
                    // its edges stay perfectly pinned while it grows!
                    Positioned(
                      left: _triggerGlobalPosition.dx + tw / 2.0 + currentDx - currentWidth / 2.0 + (_horizontalOffset * value),
                      top: _triggerGlobalPosition.dy + th / 2.0 + currentDy - currentHeight / 2.0 + (_verticalOffset * value),
                      child: IgnorePointer(
                        ignoring: value < 0.8,
                        child: _buildMorphingContainer(value, sizeT, currentWidth, currentHeight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Calculates the total height of the menu content.
  ///
  /// Sums up all menu item heights plus padding to determine the target height
  /// for the morphing animation.
  double _calculateMenuHeight() {
    // Sum all menu item heights (each defaults to 44.0)
    final itemHeights = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + _getItemHeight(item),
    );

    // Add vertical padding (12px top + 12px bottom = 24px total)
    // plus vertical gaps between items (2px each)
    final gaps = (widget.items.length - 1) * 2.0;
    return itemHeights + 24.0 + gaps;
  }

  Widget _buildMorphingContainer(double value, double sizeT, double currentWidth, double currentHeight) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    // Raw (unclamped) value — drives overshoot/undershoot scale and opacity.
    // Can exceed 1.0 (open overshoot) or go below 0.0 (close undershoot bounce).
    final rawValue = _animationController.value;

    // ─── True Metaball Morphing ──────────────────────────────────────────────
    //
    // By using the pure spring value for both width and height, the menu container
    // expands uniformly while moving diagonally. This is the SECRET to the native
    // iOS liquid teardrop. The metaball shader naturally creates the bulbous bottom
    // and the pinched neck connecting back to the trigger.
    //
    // No more faking the shape with tall, thin rectangles! Let the shader do the work.

    // ─── Uniform Border Radius ──────────────────────────────────────────────
    //
    // By keeping the border radius uniform, the container starts as a perfect circle 
    // or pill (triggerR = shortestSide/2) and naturally morphs into a rounded rectangle.
    // This provides the cleanest geometric base for the metaball shader to operate on.
    final triggerR = _triggerBorderRadius ?? _triggerSize!.shortestSide / 2.0;
    final currentRadius = lerpDouble(triggerR, widget.menuBorderRadius, sizeT)!;
    
    // Build the shape
    final teardropShape = LiquidRoundedSuperellipse(
      borderRadius: currentRadius,
    );


    // ─── Container Scale Pulse ───────────────────────────────────────────────
    //
    // Close undershoot (rawValue < 0.0): blob squeezes visibly BELOW button
    //   size. Factor 0.55 means at rawValue=-0.34: scale = 1 - 0.34*0.55 = 0.81.
    final containerScale = rawValue > 1.0
        ? 1.0 + (rawValue - 1.0) * 0.10   // open overshoot (overdamped, won't fire)
        : rawValue < 0.0
            ? 1.0 + rawValue * 0.55        // close undershoot → strong squeeze
            : 1.0;

    // ─── Item Stagger ─────────────────────────────────────────────────────────
    // Pre-compute per-item stagger offsets (used in _buildMorphingContainer
    // via the items list length).  Each item is offset by 20ms relative to
    // the previous one so they cascade in smoothly from top-to-bottom.

    // Inherit settings from context (like GlassCard/GlassContainer)
    // If user provides custom settings, use those. Otherwise, check for inherited
    // settings from parent layer. If none, use subtle overlay defaults.
    // This matches the pattern used by all other glass widgets.
    final inheritedSettings = InheritedLiquidGlass.of(context);
    final effectiveSettings = widget.glassSettings ??
        inheritedSettings ??
        const LiquidGlassSettings(
          blur: 10,
          thickness: 10,
          glassColor: Color.fromRGBO(255, 255, 255, 0.12),
          lightAngle: GlassDefaults.lightAngle, // Apple iOS 26 standard
          lightIntensity: 0.7,
          ambientStrength: 0.4,
          saturation: 1.2,
          refractiveIndex: 0.7, // Thin rim - iOS 26 delicate aesthetic
          chromaticAberration: 0.0,
        );

    final glassContent = LiquidStretch(
      stretch: widget.stretch,
      interactionScale: widget.interactionScale,
      resistance: widget.stretchResistance,
      axis: widget.stretchAxis,
      suppressInteractionOnChildren: false,
      // Constrain stretch to 'Down' and 'Away from screen edge' by default,
      // but allow explicit user overrides.
      allowPositiveX: widget.allowPositiveX ?? (_morphAlignment.x < 0),
      allowNegativeX: widget.allowNegativeX ?? (_morphAlignment.x > 0),
      allowPositiveY: widget.allowPositiveY ?? (_morphAlignment.y < 0),
      allowNegativeY: widget.allowNegativeY ?? (_morphAlignment.y > 0),
      child: GlassContainer(
        useOwnLayer: false, // blends with the trigger ghost
        settings: effectiveSettings,
        quality: effectiveQuality,
        allowElevation:
            false, // Menu is overlay - don't darken when outside parent
        width: currentWidth,
        height: currentHeight, // Constrained during morph, natural when open
        shape: teardropShape,
        clipBehavior:
            Clip.antiAlias, // Clip items at the edges for edge-to-edge feel
        glowIntensity: widget.glowIntensity,
        child: GlassGlow(
          enabled: widget.enableInteractionGlow,
          glowOnTapOnly: widget.glowOnTapOnly,
          glowColor: widget.glowColor ?? Colors.white.withValues(alpha: 0.15),
          glowRadius: widget.glowRadius,
          glowBlurRadius: 40,
          clipper: ShapeBorderClipper(
            shape: teardropShape,
          ),
          child: Transform.scale(
            scale: containerScale,
            alignment: Alignment.center,
            child: Stack(
              alignment: _morphAlignment, // Align internal stack content
              clipBehavior:
                  Clip.none, // Prevent double-clip artifacts during stretch
              children: [
                // Menu content — only appears when container is nearly at
                // full size (0.94+), so the teardrop morph is fully visible
                // first. Items stagger in rapidly in the last 6% of animation.
                if (value > 0.94)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Sliding selection pill (background)
                      ValueListenableBuilder<int?>(
                        valueListenable: _hoveredIndexNotifier,
                        builder: (context, hoveredIndex, _) {
                          if (hoveredIndex == null) {
                            return const SizedBox.shrink();
                          }
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutCubic,
                            left: 12,
                            right: 12,
                            top: _getItemOffset(hoveredIndex) -
                                (_scrollController.hasClients
                                    ? _scrollController.offset
                                    : 0.0),
                            height: _getItemHeight(widget.items[hoveredIndex]),
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.selectionColor,
                                borderRadius: BorderRadius.circular(
                                    widget.itemBorderRadius),
                                border: Border.all(
                                  color: const Color(0x0DFFFFFF), // 5% white border
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Listener(
                        onPointerDown: (event) {
                          _isDragging = true;
                          _isDraggingNotifier.value = true;
                          _hasStretched = false;
                          _initialLocalPosition = event.localPosition;
                          _initialScrollOffset = _scrollController.hasClients
                              ? _scrollController.offset
                              : 0.0;
                          _updateHoveredIndex(event.localPosition);
                        },
                        onPointerMove: (event) {
                          if (_isDragging) {
                            _updateHoveredIndex(event.localPosition);
                          }
                        },
                        onPointerUp: (event) {
                          if (_isDragging) {
                            if (_hoveredIndex != null) {
                              final currentOffset = _scrollController.hasClients
                                  ? _scrollController.offset
                                  : 0.0;
                              final scrollDisplacement =
                                  (currentOffset - _initialScrollOffset).abs();
                              final dragDisplacement =
                                  (event.localPosition - _initialLocalPosition)
                                      .distance;

                              if (scrollDisplacement < 10 &&
                                  dragDisplacement < 10) {
                                final item = widget.items[_hoveredIndex!];
                                if (item is GlassMenuItem) {
                                  if (item.enabled) {
                                    item.onTap();
                                    _closeMenu();
                                  }
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
                          _isDragging = false;
                          _isDraggingNotifier.value = false;
                          _hoveredIndex = null;
                          _hoveredIndexNotifier.value = null;
                        },
                        child: SizedBox(
                          width: currentWidth,
                          height: widget.menuHeight, // Apply fixed height
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const ClampingScrollPhysics(), // iOS-style
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 12), // Top padding
                                  ..._buildWrappedItems()
                                      .asMap()
                                      .entries
                                      .expand((entry) {
                                    // Center-out stagger: items in the
                                    // MIDDLE of the menu appear first, then
                                    // top and bottom items fade in together.
                                    // Creates the "reveal upward AND downward"
                                    // splash effect from the drop center.
                                    final itemCount = widget.items.length;
                                    final midPoint = (itemCount - 1) / 2.0;
                                    final distFromCenter = midPoint == 0
                                        ? 0.0
                                        : ((entry.key.toDouble() - midPoint) / midPoint).abs();
                                    // Center items at 0.94, edge items at 0.985
                                    final staggerStart = 0.94 + distFromCenter * 0.045;
                                    final staggerEnd = (staggerStart + 0.06)
                                        .clamp(0.0, 1.0);
                                    final itemOpacity = ((value - staggerStart) /
                                            (staggerEnd - staggerStart))
                                        .clamp(0.0, 1.0);
                                    return [
                                      Opacity(
                                        opacity: itemOpacity,
                                        child: entry.value,
                                      ),
                                      if (entry.key < widget.items.length - 1)
                                        const SizedBox(height: 2),
                                    ];
                                  }),
                                  const SizedBox(height: 12), // Bottom padding
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ), // outer Stack
          ), // Transform.scale
        ), // GlassGlow
      ), // GlassContainer
    ); // LiquidStretch (glassContent)

    // The blob is always fully opaque — shape morph is the only animation.
    return glassContent;
  }

  List<Widget> _buildWrappedItems() {
    return _cachedWrappedItems ??= widget.items.asMap().entries.map((entry) {
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
              subtitle: item.subtitle,
              icon: item.icon,
              isDestructive: item.isDestructive,
              enabled: item.enabled,
              trailing: item.trailing,
              height: item.height,
              titleStyle: item.titleStyle,
              subtitleStyle: item.subtitleStyle,
              iconColor: item.iconColor,
              iconSize: item.iconSize,
              isSelected: isSelected,
              isPressed: isPressed,
              onTap:
                  () {}, // Provide empty callback to enable GestureDetector feedback
            );
          },
        );
      }
      return item;
    }).toList();
  }

  double _getItemHeight(Widget item) {
    if (item is GlassMenuItem) return item.height;
    if (item is GlassMenuDivider) return item.height;
    if (item is GlassMenuLabel) return item.height;
    return 44.0;
  }

  double _getItemOffset(int index) {
    double offset = 12.0; // Top padding
    for (int i = 0; i < index; i++) {
      offset += _getItemHeight(widget.items[i]) + 2.0; // height + 2px gap
    }
    return offset;
  }

  void _updateHoveredIndex(Offset localPosition) {
    // Detect if we've moved into "stretch territory" (outside visible menu bounds)
    // We use the visible container height if fixed, otherwise the natural height.
    final visibleHeight = widget.menuHeight ?? _calculateMenuHeight();
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
    final y =
        dy + (_scrollController.hasClients ? _scrollController.offset : 0.0);

    double currentOffset = 12.0;
    int? detectedIndex;

    // Only allow selecting items if we are within a small "active" buffer (20px)
    // This prevents triggering items while intentionally stretching the menu.
    final isWithinActiveZone = x > -20 &&
        x < widget.menuWidth + 20 &&
        dy > -20 &&
        dy < visibleHeight + 20;

    if (isWithinActiveZone) {
      // In scrollable menus, we disable pill tracking during significant movement
      // to prevent visual noise and overlapping highlights during scrolling.
      final isScrollable = widget.menuHeight != null;
      final hasMoved =
          _isDragging && (localPosition - _initialLocalPosition).distance > 10;

      if (!isScrollable || !hasMoved) {
        for (int i = 0; i < widget.items.length; i++) {
          final item = widget.items[i];
          final itemHeight = _getItemHeight(item);

          if (y >= currentOffset && y <= currentOffset + itemHeight) {
            // Only select interactive items
            if (item is GlassMenuItem && item.enabled) {
              detectedIndex = i;
            }
            break;
          }
          currentOffset += itemHeight + 2.0; // height + 2px gap
        }
      }
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
