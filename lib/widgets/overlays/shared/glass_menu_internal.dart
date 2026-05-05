part of '../glass_menu.dart';

class _GlassMenuState extends State<GlassMenu> with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final AnimationController _animationController;
  late final ScrollController _scrollController;
  Size? _triggerSize;
  double? _triggerBorderRadius;
  int? _hoveredIndex;
  bool _isDragging = false;
  bool _hasStretched =
      false; // Prevents closing if we moved into stretch territory
  double _initialScrollOffset = 0.0;
  Offset _initialLocalPosition = Offset.zero;

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

  // iOS 26 Liquid Glass smooth spring physics
  // Gentle, fluid motion with subtle overshoot - NOT harsh bounces
  //
  // Response: ~0.35s (smooth, not too fast)
  // DampingFraction: 0.7 (slightly underdamped = gentle settle, no harsh bounce)
  // Result: Seamless liquid feel that complements the swoop curve
  //
  // Conversion to Flutter SpringSimulation:
  // - stiffness: 300 (smooth, not too snappy)
  // - damping: 2 * 0.7 * sqrt(300) ≈ 24.2
  final _springDescription = const SpringDescription(
    mass: 1.0,
    stiffness: 300.0, // Smooth motion (not too fast)
    damping: 24.0, // Gentle settle (no harsh bounce)
  );

  Alignment _morphAlignment = Alignment.topLeft;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this);
    _animationController.addListener(() {
      // Rebuild on each spring physics tick
      if (mounted) setState(() {});

      // Auto-hide when spring settles back to closed state
      if (_overlayController.isShowing &&
          _animationController.value <= 0.001 &&
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
    final isMenuOpen =
        _overlayController.isShowing && _animationController.value > 0.05;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Stack(
        children: [
          // Original trigger button (hidden when menu is morphing)
          Opacity(
            opacity: isMenuOpen ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: isMenuOpen,
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
      ),
    );
  }

  void _runSpring(double target) {
    final simulation = SpringSimulation(
      _springDescription,
      _animationController.value,
      target,
      0.0, // Initial velocity (could add velocity for swipe gestures)
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

    // Determine alignment based on screen position
    // This ensures menu doesn't overflow screen edges
    final position = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? double.infinity;
    final screenHeight = mediaQuery?.size.height ?? double.infinity;

    // Calculate menu height for vertical boundary check
    final menuHeight = _calculateMenuHeight();

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

    // Determine final alignment based on both axes
    if (shouldFlipVertical) {
      _morphAlignment =
          isRightHalf ? Alignment.bottomRight : Alignment.bottomLeft;
    } else {
      _morphAlignment = isRightHalf ? Alignment.topRight : Alignment.topLeft;
    }

    _overlayController.show();
    _runSpring(1.0);
  }

  void _closeMenu() {
    setState(() {
      _hoveredIndex = null;
      _isDragging = false;
    });
    _runSpring(0.0);
  }

  Widget _buildMorphingOverlay(BuildContext context) {
    if (_triggerSize == null) return const SizedBox.shrink();

    // Clamp animation value to prevent overshoot artifacts
    final value = _animationController.value.clamp(0.0, 1.0);

    return Stack(
      children: [
        // Backdrop barrier (only active when menu is significantly open)
        if (value > 0.3)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeMenu,
              child: Container(
                color: Colors.black
                    .withValues(alpha: 0.0), // Invisible but tappable
              ),
            ),
          ),

        // Morphing glass container
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          // anchor based on calculated alignment
          targetAnchor: _morphAlignment,
          followerAnchor: _morphAlignment,
          // iOS 26 "liquid swoop" offset:
          // - Parabolic curve creates smooth, gravity-like arc
          // - Subtle 5px vertical displacement at peak (t=0.5)
          // - Seamless in both directions (opening and closing)
          offset: Offset(0, _calculateSwoopOffset(value)),
          child: _buildMorphingContainer(value),
        ),
      ],
    );
  }

  /// Calculates the vertical "swoop" offset for liquid glass morphing.
  ///
  /// iOS 26 uses a gentle parabolic curve that creates a subtle "liquid droop"
  /// effect during morphing. This is NOT a bounce - it's a smooth arc that
  /// complements the spring physics for a seamless feel.
  ///
  /// The curve peaks at mid-animation (t=0.5) and smoothly returns to zero
  /// at both ends, creating a natural "swoop down and up" motion.
  double _calculateSwoopOffset(double t) {
    // Parabolic curve: peaks at t=0.5, zero at t=0 and t=1
    // This creates a smooth down-and-up arc without harsh direction changes
    // Formula: -4 * (t - 0.5)² + 1, scaled by amplitude
    final parabola = 1.0 - 4.0 * (t - 0.5) * (t - 0.5);

    // Gentle 5px peak displacement for subtle liquid feel
    // Opening: swoops down then up (parabola is always positive)
    // Closing: same smooth curve in reverse (no jarring direction change)
    return parabola * 5.0;
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

  Widget _buildMorphingContainer(double value) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    // Calculate menu height by measuring its natural size
    // This is necessary for proper height interpolation during morph
    final menuHeight = _calculateMenuHeight();

    // iOS 26: Width always interpolates smoothly throughout animation
    // Height goes natural at 85% to prevent any overflow from content
    final currentWidth =
        lerpDouble(_triggerSize!.width, widget.menuWidth, value)!;

    final targetHeight = widget.menuHeight ?? menuHeight;
    final currentHeight = value < 0.85
        ? lerpDouble(_triggerSize!.height, targetHeight, value)!
        : widget.menuHeight; // Natural height (null) or fixed height

    // Interpolate border radius: circular button -> rounded menu
    final currentBorderRadius = lerpDouble(
      _triggerBorderRadius ?? 16.0,
      widget.menuBorderRadius,
      value,
    )!;

    // iOS 26 Crossfade Timing + Material Fade
    // Problem: Empty morphing container still visible (glowing blob) during closing
    // Solution: Fade glass material opacity as container shrinks
    //
    // Menu content: Fades in 0.7→1.0 opening, exits cleanly when closing
    final menuOpacity = ((value - 0.7) / 0.3).clamp(0.0, 1.0);

    // Glass container opacity: Fully visible when menu open, fades during closing
    // - value > 0.3: Fully visible (1.0)
    // - value 0.3→0: Fades out to transparent
    // - Result: No "empty glowing blob" - seamless fade to real button
    final containerOpacity = (value / 0.3).clamp(0.0, 1.0);

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
        useOwnLayer: true,
        settings: effectiveSettings,
        quality: effectiveQuality,
        allowElevation:
            false, // Menu is overlay - don't darken when outside parent
        width: currentWidth,
        height: currentHeight, // Constrained during morph, natural when open
        shape: LiquidRoundedSuperellipse(borderRadius: currentBorderRadius),
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
            shape: LiquidRoundedSuperellipse(borderRadius: currentBorderRadius),
          ),
          child: Stack(
            alignment: _morphAlignment, // Align internal stack content
            clipBehavior:
                Clip.none, // Prevent double-clip artifacts during stretch
            children: [
              // Menu content - waits for container to be nearly full width
              if (value > 0.85)
                Opacity(
                  opacity: menuOpacity,
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
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(
                                      0x0DFFFFFF), // 5% white border
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
                              // Only trigger tap if we didn't scroll or drag much (prevents selection during stretching)
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
                                } else {
                                  // For non-GlassMenuItem (labels, dividers),
                                  // we might want to close if it's a generic item,
                                  // but usually only menu items close on tap.
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
                              physics:
                                  const ClampingScrollPhysics(), // iOS-style scrolling
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(
                                      height: 12), // Inner top padding
                                  ..._buildWrappedItems()
                                      .asMap()
                                      .entries
                                      .expand((entry) => [
                                            entry.value,
                                            if (entry.key <
                                                widget.items.length - 1)
                                              const SizedBox(height: 2),
                                          ]),
                                  const SizedBox(
                                      height: 12), // Inner bottom padding
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return containerOpacity >= 1.0
        ? glassContent
        : Opacity(opacity: containerOpacity, child: glassContent);
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
