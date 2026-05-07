// Shared internal widgets for GlassTabBar.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../src/renderer/liquid_glass_renderer.dart';
import '../../../types/glass_quality.dart';
import '../../../utils/draggable_indicator_physics.dart';
import '../../../utils/glass_spring.dart';
import '../../shared/animated_glass_indicator.dart';
import '../glass_bottom_bar.dart' show MaskingQuality;
import '../glass_tab_bar.dart' show GlassTab, DividerSettings;

// =============================================================================
// TabBarContent — draggable indicator + tab layout
// =============================================================================

/// Internal stateful widget managing the draggable pill indicator and tab
/// items for [GlassTabBar].
///
/// Extracted from [GlassTabBar] to keep the public widget focused on
/// configuration and glass-layer wrapping, while this widget owns all gesture,
/// spring, and rendering logic.
class TabBarContent extends StatefulWidget {
  const TabBarContent({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isScrollable,
    required this.scrollController,
    required this.indicatorColor,
    required this.selectedLabelStyle,
    required this.unselectedLabelStyle,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.iconSize,
    required this.labelPadding,
    required this.quality,
    this.indicatorBorderRadius,
    this.indicatorSettings,
    this.backgroundKey,
    this.maskingQuality = MaskingQuality.high,
    this.dividerSettings,
    this.indicatorShadow,
    this.tabBarBorderRadius,
    super.key,
  });

  final List<GlassTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;
  final ScrollController scrollController;
  final Color? indicatorColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final double iconSize;
  final EdgeInsetsGeometry labelPadding;
  final GlassQuality quality;
  final BorderRadius? indicatorBorderRadius;
  final LiquidGlassSettings? indicatorSettings;
  final GlobalKey? backgroundKey;
  final MaskingQuality maskingQuality;
  final DividerSettings? dividerSettings;
  final List<BoxShadow>? indicatorShadow;

  /// Border radius of the outer tab bar container — used to clip Layer 1
  /// (tab labels + background pill) to the same rounded shape.
  final BorderRadius? tabBarBorderRadius;

  @override
  State<TabBarContent> createState() => TabBarContentState();
}

/// State for [TabBarContent]. Public for testing via `@visibleForTesting`.
@visibleForTesting
class TabBarContentState extends State<TabBarContent>
    with TickerProviderStateMixin {
  // Cache default colors to avoid allocations
  static const _defaultIndicatorColor =
      Color(0x33FFFFFF); // white.withValues(alpha: 0.2)
  static const _defaultUnselectedTextColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)
  static const _defaultUnselectedIconColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)

  bool _isDown = false;
  bool _isDragging = false;
  late double _xAlign = _computeXAlignmentForTab(widget.selectedIndex);

  /// Specifically tracks if we are dragging the indicator in scrollable mode.
  bool _isDraggingIndicator = false;

  // Scrollable-overlay indicator position, animated in content space.
  // Decoupled from the _xAlign spring so scroll never causes drift.
  late SingleSpringController _indOffsetSpring;
  late SingleSpringController _indWidthSpring;

  late List<GlobalKey> _tabKeys;
  List<double> _tabWidths = [];
  List<double> _tabOffsets = [];

  // Gesture Recognizers for precision control in scrollable mode.
  late HorizontalDragGestureRecognizer _drag;
  late TapGestureRecognizer _tap;

  @override
  void initState() {
    super.initState();
    _indOffsetSpring = SingleSpringController(
      vsync: this,
      spring: GlassSpring.snappy(duration: const Duration(milliseconds: 300)),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _indWidthSpring = SingleSpringController(
      vsync: this,
      spring: GlassSpring.snappy(duration: const Duration(milliseconds: 300)),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    // Setup Gesture Arena Team to allow indicator drag to "steal" focus from ScrollView.
    final team = GestureArenaTeam();
    _drag = HorizontalDragGestureRecognizer()
      ..team = team
      ..onDown = _handleDragDown
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;

    team.captain = _drag;

    _tap = TapGestureRecognizer()..onTapUp = _handleTapUp;

    _initKeys();
    if (widget.isScrollable) {
      widget.scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    // Rebuild to update the screen-relative indicator position during scroll.
    if (mounted) setState(() {});
  }

  void _initKeys() {
    _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTabs());
  }

  void _measureTabs() {
    if (!mounted) return;
    double offset = 0;
    List<double> widths = [];
    List<double> offsets = [];
    bool allMeasured = true;
    final dividerWidth = widget.dividerSettings?.thickness ?? 0.0;
    for (int i = 0; i < _tabKeys.length; i++) {
      final box = _tabKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        allMeasured = false;
        break;
      }
      final width = box.size.width;
      offsets.add(offset);
      widths.add(width);
      offset += width;
      if (widget.dividerSettings != null && i != _tabKeys.length - 1) {
        offset += dividerWidth;
      }
    }
    if (allMeasured) {
      final selIdx = widget.selectedIndex.clamp(0, widths.length - 1);
      setState(() {
        _tabWidths = widths;
        _tabOffsets = offsets;
        // Snap indicator to selected tab after first measure (no animation).
        _indOffsetSpring.setValue(offsets[selIdx]);
        _indWidthSpring.setValue(widths[selIdx]);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureTabs());
    }
  }

  @override
  void dispose() {
    _indOffsetSpring.dispose();
    _indWidthSpring.dispose();
    _drag.dispose();
    _tap.dispose();
    if (widget.isScrollable) {
      widget.scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(TabBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle scrollController swap (e.g., parent provides a new controller).
    if (widget.isScrollable &&
        oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }

    // Handle isScrollable toggling (unlikely in practice, but safe).
    if (!oldWidget.isScrollable && widget.isScrollable) {
      widget.scrollController.addListener(_onScroll);
      // Re-measure in scrollable mode — tab widths may differ.
      setState(() {
        _tabWidths = [];
        _tabOffsets = [];
      });
      _indOffsetSpring.setValue(0);
      _indWidthSpring.setValue(0);
      _initKeys();
    } else if (oldWidget.isScrollable && !widget.isScrollable) {
      oldWidget.scrollController.removeListener(_onScroll);
      // Re-measure in non-scrollable mode (expanded layout).
      setState(() {
        _tabWidths = [];
        _tabOffsets = [];
      });
      _indOffsetSpring.setValue(0);
      _indWidthSpring.setValue(0);
      _initKeys();
    }

    if (oldWidget.selectedIndex != widget.selectedIndex && !_isDragging) {
      setState(() {
        _xAlign = _computeXAlignmentForTab(widget.selectedIndex);
      });
      // Animate overlay indicator to new tab (scrollable mode).
      if (widget.isScrollable &&
          widget.selectedIndex < _tabOffsets.length &&
          widget.selectedIndex < _tabWidths.length) {
        _indOffsetSpring.animateTo(_tabOffsets[widget.selectedIndex]);
        _indWidthSpring.animateTo(_tabWidths[widget.selectedIndex]);
      }
      // Programmatic selection change — ensure the new tab scrolls into view.
      if (widget.isScrollable) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToEnsureVisible(widget.selectedIndex),
        );
      }
    }
    if (oldWidget.tabs.length != widget.tabs.length) {
      setState(() {
        _xAlign = _computeXAlignmentForTab(widget.selectedIndex);
        _tabWidths = [];
        _tabOffsets = [];
      });
      _indOffsetSpring.setValue(0);
      _indWidthSpring.setValue(0);
      _initKeys();
    }
  }

  double _computeXAlignmentForTab(int tabIndex) {
    return DraggableIndicatorPhysics.computeAlignment(
      tabIndex,
      widget.tabs.length,
    );
  }

  // ===========================================================================
  // GESTURE HANDLERS
  // ===========================================================================

  void _handleTapUp(TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = details.localPosition.dx;

    int targetIndex = -1;
    if (widget.isScrollable) {
      final scrollOffset = widget.scrollController.hasClients
          ? widget.scrollController.offset
          : 0.0;
      final absoluteX = localX + scrollOffset;
      for (int i = 0; i < _tabOffsets.length; i++) {
        if (absoluteX >= _tabOffsets[i] &&
            absoluteX <= _tabOffsets[i] + _tabWidths[i]) {
          targetIndex = i;
          break;
        }
      }
    } else {
      targetIndex = (localX / box.size.width * widget.tabs.length).floor();
    }

    if (targetIndex != -1 && targetIndex < widget.tabs.length) {
      _onTabTap(targetIndex);
    }
  }

  void _handleDragDown(DragDownDetails details) {
    if (!widget.isScrollable) {
      setState(() => _isDown = true);
      return;
    }

    final scrollOffset = widget.scrollController.hasClients
        ? widget.scrollController.offset
        : 0.0;
    final absoluteX = details.localPosition.dx + scrollOffset;

    final selIdx = widget.selectedIndex;
    if (selIdx < _tabOffsets.length) {
      final left = _tabOffsets[selIdx];
      final right = left + _tabWidths[selIdx];

      // If the press is within the active indicator's bounds, we start an indicator drag.
      if (absoluteX >= left && absoluteX <= right) {
        setState(() {
          _isDraggingIndicator = true;
          _isDown = true;
        });
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || box.size.width <= 0) return;

    if (!widget.isScrollable) {
      setState(() {
        _isDragging = true;

        // Use absolute pointer position instead of delta accumulation.
        //
        // Delta-based dragging (`_xAlign += details.delta.dx`) introduces
        // visible lag/drift on desktop/web because pointer events may arrive
        // at a different rate than rendering frames.
        double raw = DraggableIndicatorPhysics.getAlignmentFromGlobalPosition(
          details.globalPosition,
          context,
          widget.tabs.length,
        );
        if (raw < -1.0) {
          raw = -1.0 + (raw + 1.0) * 0.5;
        } else if (raw > 1.0) {
          raw = 1.0 + (raw - 1.0) * 0.5;
        }
        final overstep = 0.85 * (2.0 / widget.tabs.length);
        _xAlign = raw.clamp(-1.0 - overstep, 1.0 + overstep);
      });
      return;
    }

    if (!_isDraggingIndicator || _tabOffsets.isEmpty) return;

    setState(() {
      _isDragging = true;
      double delta = details.delta.dx;
      final cur = _indOffsetSpring.value;
      final double screenWidth = box.size.width;
      final double scrollOffset = widget.scrollController.offset;
      final double viewMin = scrollOffset;
      final double viewMax = scrollOffset + screenWidth;
      if ((cur < viewMin && delta < 0) || (cur > viewMax && delta > 0)) {
        delta *= 0.5;
      }
      final newOffset = (cur + delta)
          .clamp(viewMin - screenWidth * 0.35, viewMax + screenWidth * 0.35);
      _indOffsetSpring.setValue(newOffset);

      // Update width based on current position between tabs.
      if (_tabWidths.length == widget.tabs.length) {
        int index = 0;
        for (int i = 0; i < _tabOffsets.length - 1; i++) {
          if (newOffset >= _tabOffsets[i]) index = i;
        }
        final nextIndex = (index + 1).clamp(0, widget.tabs.length - 1);
        final diff = _tabOffsets[nextIndex] - _tabOffsets[index];
        final t = (diff != 0 ? (newOffset - _tabOffsets[index]) / diff : 0.0)
            .clamp(0.0, 1.0);
        final interpolatedWidth =
            _tabWidths[index] + (_tabWidths[nextIndex] - _tabWidths[index]) * t;
        _indWidthSpring.setValue(interpolatedWidth);
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) {
      _handleDragCancel();
      return;
    }

    int targetTabIndex;

    if (widget.isScrollable) {
      targetTabIndex = widget.selectedIndex;
      double minDistance = double.infinity;
      for (int i = 0; i < _tabOffsets.length; i++) {
        final distance = (_indOffsetSpring.value - _tabOffsets[i]).abs();
        if (distance < minDistance) {
          minDistance = distance;
          targetTabIndex = i;
        }
      }
    } else {
      final currentRelativeX = (_xAlign + 1) / 2;
      final box = context.findRenderObject() as RenderBox?;
      final width = box?.size.width ?? 1.0;
      final velocityX = details.velocity.pixelsPerSecond.dx / width;
      targetTabIndex = _computeTargetTab(
        currentRelativeX: currentRelativeX,
        velocityX: velocityX,
        tabWidth: 1.0 / widget.tabs.length,
      );
    }

    setState(() {
      _isDragging = false;
      _isDraggingIndicator = false;
      _isDown = false;
      if (!widget.isScrollable) {
        _xAlign = _computeXAlignmentForTab(targetTabIndex);
      }
    });

    if (targetTabIndex != widget.selectedIndex) {
      widget.onTabSelected(targetTabIndex);
    } else if (widget.isScrollable) {
      _indOffsetSpring.animateTo(_tabOffsets[targetTabIndex]);
      _indWidthSpring.animateTo(_tabWidths[targetTabIndex]);
    }
  }

  void _handleDragCancel() {
    setState(() {
      _isDragging = false;
      _isDraggingIndicator = false;
      _isDown = false;
      if (!widget.isScrollable) {
        _xAlign = _computeXAlignmentForTab(widget.selectedIndex);
      }
    });
  }

  int _computeTargetTab({
    required double currentRelativeX,
    required double velocityX,
    required double tabWidth,
  }) {
    return DraggableIndicatorPhysics.computeTargetIndex(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      itemWidth: tabWidth,
      itemCount: widget.tabs.length,
    );
  }

  void _onTabTap(int index) {
    if (index != widget.selectedIndex) {
      widget.onTabSelected(index);
    }
    // Scroll the tapped tab fully into view in case it was partially visible.
    if (widget.isScrollable) {
      _scrollToEnsureVisible(index);
    }
  }

  /// Smoothly scrolls the [SingleChildScrollView] so that [tabIndex] is
  /// fully visible, with a small breathing-room edge padding.
  ///
  /// Called on tap and on programmatic selection changes. Only fires when
  /// measurements are ready and the controller has an attached position.
  void _scrollToEnsureVisible(int tabIndex) {
    if (!widget.scrollController.hasClients) return;
    if (tabIndex >= _tabOffsets.length || tabIndex >= _tabWidths.length) return;

    final position = widget.scrollController.position;
    final viewportWidth = position.viewportDimension;
    final currentOffset = position.pixels;
    const edgePadding = 12.0; // breathing room from the left/right edge

    final tabLeft = _tabOffsets[tabIndex];
    final tabRight = tabLeft + _tabWidths[tabIndex];

    double targetOffset = currentOffset;

    if (tabLeft - currentOffset < edgePadding) {
      // Tab is partially or fully off-screen to the left.
      targetOffset = tabLeft - edgePadding;
    } else if (tabRight - currentOffset > viewportWidth - edgePadding) {
      // Tab is partially or fully off-screen to the right.
      targetOffset = tabRight - viewportWidth + edgePadding;
    }

    targetOffset = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((targetOffset - currentOffset).abs() > 0.5) {
      widget.scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor = widget.indicatorColor ?? _defaultIndicatorColor;
    final targetAlignment = _computeXAlignmentForTab(widget.selectedIndex);

    final selectedLabelStyle = widget.selectedLabelStyle ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    final unselectedLabelStyle = widget.unselectedLabelStyle ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _defaultUnselectedTextColor,
        );

    final selectedIconColor = widget.selectedIconColor ?? Colors.white;
    final unselectedIconColor =
        widget.unselectedIconColor ?? _defaultUnselectedIconColor;

    final effectiveShadow = _isDragging ? null : widget.indicatorShadow;

    Widget buildContent() {
      return VelocitySpringBuilder(
        value: _xAlign,
        springWhenActive: GlassSpring.interactive(),
        springWhenReleased: GlassSpring.snappy(
          duration: const Duration(milliseconds: 350),
        ),
        active: _isDragging && !widget.isScrollable,
        builder: (context, value, velocity, child) {
          final alignment = Alignment(value, 0);
          return SpringBuilder(
            spring: GlassSpring.snappy(
              duration: const Duration(milliseconds: 300),
            ),
            value: _isDown || (alignment.x - targetAlignment).abs() > 0.05
                ? 1.0
                : 0.0,
            builder: (context, thickness, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (!widget.isScrollable)
                    AnimatedGlassIndicator(
                      velocity: velocity,
                      itemCount: widget.tabs.length,
                      alignment: alignment,
                      thickness: thickness,
                      quality: widget.quality,
                      indicatorColor: indicatorColor,
                      isBackgroundIndicator: false,
                      borderRadius:
                          widget.indicatorBorderRadius?.topLeft.x ?? 16,
                      glassSettings: widget.indicatorSettings,
                      backgroundKey: widget.backgroundKey,
                      expansion: widget.maskingQuality == MaskingQuality.off
                          ? 0.0
                          : 8.0,
                      shadows: effectiveShadow,
                    ),
                  child!,
                ],
              );
            },
            child: _buildTabLabels(
              selectedLabelStyle,
              unselectedLabelStyle,
              selectedIconColor,
              unselectedIconColor,
            ),
          );
        },
      );
    }

    Widget result;
    if (widget.isScrollable) {
      // Three-layer architecture:
      //  1. ClipRect layer: tab labels + solid background pill — both clip
      //     cleanly at the viewport boundary as the user scrolls.
      //  2. Glass bloom layer (above ClipRect): only the glass effect renders
      //     here, so the jelly bloom can expand freely past the bar edges.
      final bool measuredReady = _tabWidths.length == widget.tabs.length;
      final double scrollOffset = widget.scrollController.hasClients
          ? widget.scrollController.offset
          : 0.0;
      final double screenLeft = _indOffsetSpring.value - scrollOffset;

      // Bloom while the position spring is still in transit — deactivates
      // naturally as the spring settles (mirrors GlassSegmentedControl).
      final double targetOffset =
          measuredReady && widget.selectedIndex < _tabOffsets.length
              ? _tabOffsets[widget.selectedIndex]
              : 0.0;
      final bool isMoving = (_indOffsetSpring.value - targetOffset).abs() > 2.0;

      final physics = _isDraggingIndicator
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics();

      result = Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Layer 1: clipped content ────────────────────────────────────
          // ClipRRect clips to the tab bar's rounded corners so the solid
          // background pill and tab labels don't overflow the corner radius.
          ClipRRect(
            borderRadius: widget.tabBarBorderRadius ?? BorderRadius.zero,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background solid pill — clips with the bar.
                if (measuredReady && _indWidthSpring.value > 0)
                  SpringBuilder(
                    spring: GlassSpring.snappy(
                      duration: const Duration(milliseconds: 300),
                    ),
                    value: _isDown || isMoving ? 1.0 : 0.0,
                    builder: (context, thickness, _) {
                      return AnimatedGlassIndicator(
                        velocity: 0.0,
                        itemCount: widget.tabs.length,
                        alignment: Alignment.center,
                        thickness: thickness,
                        quality: widget.quality,
                        indicatorColor: indicatorColor,
                        isBackgroundIndicator: false,
                        borderRadius:
                            widget.indicatorBorderRadius?.topLeft.x ?? 16,
                        glassSettings: widget.indicatorSettings,
                        backgroundKey: widget.backgroundKey,
                        exactWidth: _indWidthSpring.value,
                        exactOffset: screenLeft,
                        expansion: widget.maskingQuality == MaskingQuality.off
                            ? 0.0
                            : 8.0,
                        paintBackground: true,
                        paintGlass: false, // glass rendered in layer 2
                        shadows: effectiveShadow,
                      );
                    },
                  ),

                // Tab labels (scrollable).
                NotificationListener<ScrollStartNotification>(
                  onNotification: (_) {
                    if (_isDown) setState(() => _isDown = false);
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: physics,
                    child: _buildTabLabels(
                      selectedLabelStyle,
                      unselectedLabelStyle,
                      selectedIconColor,
                      unselectedIconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Layer 2: glass bloom (above all clips) ──────────────────────
          if (measuredReady && _indWidthSpring.value > 0)
            SpringBuilder(
              spring: GlassSpring.snappy(
                duration: const Duration(milliseconds: 300),
              ),
              value: _isDown || isMoving ? 1.0 : 0.0,
              builder: (context, thickness, _) {
                return AnimatedGlassIndicator(
                  velocity: 0.0,
                  itemCount: widget.tabs.length,
                  alignment: Alignment.center,
                  thickness: thickness,
                  quality: widget.quality,
                  indicatorColor: indicatorColor,
                  isBackgroundIndicator: false,
                  borderRadius: widget.indicatorBorderRadius?.topLeft.x ?? 16,
                  glassSettings: widget.indicatorSettings,
                  backgroundKey: widget.backgroundKey,
                  exactWidth: _indWidthSpring.value,
                  exactOffset: screenLeft,
                  expansion:
                      widget.maskingQuality == MaskingQuality.off ? 0.0 : 8.0,
                  paintBackground: false, // background rendered in layer 1
                  paintGlass: true,
                );
              },
            ),
        ],
      );
    } else {
      result = buildContent();
    }

    return RawGestureDetector(
      gestures: {
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          () => _drag,
          (instance) {},
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => _tap,
          (instance) {},
        ),
      },
      child: result,
    );
  }

  Widget _buildTabLabels(
    TextStyle selectedStyle,
    TextStyle unselectedStyle,
    Color selectedIconColor,
    Color unselectedIconColor,
  ) {
    final List<Widget> tabWidgets = List.generate(
      widget.tabs.length,
      (index) {
        final tab = widget.tabs[index];
        final isSelected = index == widget.selectedIndex;
        return KeyedSubtree(
          key: _tabKeys[index],
          child: RepaintBoundary(
            child: TabBarItem(
              tab: tab,
              isSelected: isSelected,
              onTap: () {},
              onTapDown: () {},
              labelStyle: isSelected ? selectedStyle : unselectedStyle,
              iconColor: isSelected ? selectedIconColor : unselectedIconColor,
              iconSize: widget.iconSize,
              padding: widget.labelPadding,
            ),
          ),
        );
      },
    );

    if (widget.dividerSettings != null) {
      final d = widget.dividerSettings!;
      for (int i = widget.tabs.length - 1; i > 0; i--) {
        final isVisible = !d.isHideAutomatically ||
            (i - 1 != widget.selectedIndex && i != widget.selectedIndex);

        tabWidgets.insert(
          i,
          AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: d.duration ?? const Duration(milliseconds: 200),
            curve: d.curve ?? Curves.easeInOut,
            child: Container(
              width: d.thickness,
              margin: EdgeInsets.only(top: d.indent, bottom: d.endIndent),
              decoration: d.decoration ??
                  BoxDecoration(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        );
      }
    }

    if (widget.isScrollable) {
      return Row(children: tabWidgets);
    }

    return Row(
      children: tabWidgets
          .map((tab) => tab is KeyedSubtree ? Expanded(child: tab) : tab)
          .toList(),
    );
  }
}

// =============================================================================
// TabBarItem — single tab label/icon widget
// =============================================================================

/// Renders a single tab label and/or icon for [GlassTabBar].
///
/// Handles tap gestures, semantics, and animated text style transitions.
class TabBarItem extends StatelessWidget {
  const TabBarItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.onTapDown,
    required this.labelStyle,
    required this.iconColor,
    required this.iconSize,
    required this.padding,
    super.key,
  });

  final GlassTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final TextStyle labelStyle;
  final Color iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget? iconWidget;
    if (tab.icon != null) {
      iconWidget = IconTheme(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: tab.icon!,
      );
    }

    Widget? labelWidget;
    if (tab.label != null) {
      labelWidget = Text(
        tab.label!,
        style: labelStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    Widget content;
    if (iconWidget != null && labelWidget != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          labelWidget,
        ],
      );
    } else if (iconWidget != null) {
      content = iconWidget;
    } else if (labelWidget != null) {
      content = labelWidget;
    } else {
      content = const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: tab.semanticLabel ?? tab.label,
        child: Container(
          padding: padding,
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: labelStyle,
            child: content,
          ),
        ),
      ),
    );
  }
}
