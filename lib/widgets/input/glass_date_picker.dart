import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../theme/glass_theme.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../containers/glass_container.dart';
import '../shared/glass_solid_surface.dart';

/// The display and interaction style of the [GlassDatePicker], matching SwiftUI's
/// `DatePickerStyle`.
enum GlassDatePickerStyle {
  /// Displays an authentic inline month calendar grid with specular selection ring,
  /// previous/next month navigation, and optional time selector.
  graphical,

  /// Displays compact liquid glass pill button(s) showing formatted date/time.
  /// Tapping opens an anchored modal or popover for interactive selection.
  compact,

  /// Displays 3D cylindrical Cupertino picker wheels enclosed in a liquid glass surface.
  wheel,
}

/// The mode of date/time information being selected in [GlassDatePicker].
enum GlassDatePickerMode {
  /// Select date only (year, month, day).
  date,

  /// Select time only (hour, minute, AM/PM).
  time,

  /// Select both date and time.
  dateAndTime,
}

/// An authentic iOS 26/27 Liquid Glass Date and Time Picker providing 100% parity
/// with SwiftUI's `DatePicker` and `MultiDatePicker`.
///
/// ## Key Features
/// - **Three Native Display Styles**: [GlassDatePickerStyle.compact], [GlassDatePickerStyle.graphical],
///   and [GlassDatePickerStyle.wheel].
/// - **Authentic Liquid Glass Styling**: Elevated specular selection rings, frosted glass month headers,
///   and subtle rim highlights.
/// - **Multi-Date Support**: [GlassMultiDatePicker] allows selecting multiple distinct dates.
/// - **Haptic Feedback**: Fires `HapticFeedback.selectionClick()` on every day/month transition.
/// - **Bounds & Constraints**: Respects [minimumDate], [maximumDate], and [minuteInterval].
/// - **Imperative Presentation**: [showGlassDatePicker] presents the picker modally.
class GlassDatePicker extends StatefulWidget {
  /// Creates a [GlassDatePicker] in [GlassDatePickerStyle.graphical] mode by default.
  const GlassDatePicker({
    super.key,
    required this.initialDateTime,
    this.onDateTimeChanged,
    this.mode = GlassDatePickerMode.date,
    this.style = GlassDatePickerStyle.graphical,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
    this.use24hFormat = false,
    this.tintColor,
    this.firstDayOfWeek = 7, // 7 = Sunday, 1 = Monday
    this.monthNames,
    this.weekdayNames,
    this.dateFormatter,
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : assert(monthNames == null || monthNames.length == 12),
       assert(weekdayNames == null || weekdayNames.length == 7);

  /// Creates a compact pill-styled [GlassDatePicker].
  const GlassDatePicker.compact({
    super.key,
    required this.initialDateTime,
    this.onDateTimeChanged,
    this.mode = GlassDatePickerMode.date,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
    this.use24hFormat = false,
    this.tintColor,
    this.firstDayOfWeek = 7,
    this.monthNames,
    this.weekdayNames,
    this.dateFormatter,
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : style = GlassDatePickerStyle.compact,
       assert(monthNames == null || monthNames.length == 12),
       assert(weekdayNames == null || weekdayNames.length == 7);

  /// Creates an inline graphical calendar-styled [GlassDatePicker].
  const GlassDatePicker.graphical({
    super.key,
    required this.initialDateTime,
    this.onDateTimeChanged,
    this.mode = GlassDatePickerMode.date,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
    this.use24hFormat = false,
    this.tintColor,
    this.firstDayOfWeek = 7,
    this.monthNames,
    this.weekdayNames,
    this.dateFormatter,
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : style = GlassDatePickerStyle.graphical,
       assert(monthNames == null || monthNames.length == 12),
       assert(weekdayNames == null || weekdayNames.length == 7);

  /// Creates a wheel-styled [GlassDatePicker] using Cupertino wheels in liquid glass.
  const GlassDatePicker.wheel({
    super.key,
    required this.initialDateTime,
    this.onDateTimeChanged,
    this.mode = GlassDatePickerMode.date,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
    this.use24hFormat = false,
    this.tintColor,
    this.firstDayOfWeek = 7,
    this.monthNames,
    this.weekdayNames,
    this.dateFormatter,
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : style = GlassDatePickerStyle.wheel,
       assert(monthNames == null || monthNames.length == 12),
       assert(weekdayNames == null || weekdayNames.length == 7);

  /// The initially selected date and time.
  final DateTime initialDateTime;

  /// Callback executed when the selected date or time changes.
  final ValueChanged<DateTime>? onDateTimeChanged;

  /// The components being selected (date, time, or dateAndTime).
  final GlassDatePickerMode mode;

  /// Presentation and interaction style.
  final GlassDatePickerStyle style;

  /// Earliest selectable date/time.
  final DateTime? minimumDate;

  /// Latest selectable date/time.
  final DateTime? maximumDate;

  /// Interval between minute increments in time selection.
  final int minuteInterval;

  /// Whether to display time in 24-hour format instead of 12-hour AM/PM.
  final bool use24hFormat;

  /// Accent tint color for the selected day highlight (defaults to [CupertinoColors.activeBlue]).
  final Color? tintColor;

  /// First day of the week (7 = Sunday, 1 = Monday).
  final int firstDayOfWeek;

  /// Optional localized full month names (12 entries, January through December).
  final List<String>? monthNames;

  /// Optional localized short weekday headers (7 entries ordered starting from
  /// [firstDayOfWeek]).
  final List<String>? weekdayNames;

  /// Optional formatter for the compact date pill label (defaults to
  /// `'Oct 12, 2026'`).
  final String Function(DateTime)? dateFormatter;

  /// Liquid glass settings. Ignored when [surfaceStyle] is
  /// [GlassSurfaceStyle.solid].
  final LiquidGlassSettings? settings;

  /// Shape of the picker's card (wheel, graphical and multi-date).
  ///
  /// If null, defaults to a 12pt [LiquidRoundedSuperellipse] for
  /// [GlassSurfaceStyle.glass] and 26pt for [GlassSurfaceStyle.solid], the
  /// corner radius of native iOS 26 inset grouped containers.
  final LiquidShape? shape;

  /// Rendering quality tier. Ignored when [surfaceStyle] is
  /// [GlassSurfaceStyle.solid].
  final GlassQuality? quality;

  /// How the picker's card is painted.
  ///
  /// [GlassSurfaceStyle.glass] (default in 1.x) renders a glass card.
  /// [GlassSurfaceStyle.solid] renders a flat opaque card matching native iOS
  /// grouped containers. Applies to the wheel and graphical styles and to the
  /// graphical popover opened by the compact style; the compact pills
  /// themselves are unchanged.
  final GlassSurfaceStyle surfaceStyle;

  @override
  State<GlassDatePicker> createState() => _GlassDatePickerState();
}

class _GlassDatePickerState extends State<GlassDatePicker> {
  late DateTime _selectedDateTime;
  late DateTime _displayedMonth;
  late PageController _monthPageController;
  bool _showMonthYear = false;
  bool? _activeCompactIsTime;
  final GlobalKey _compactRowKey = GlobalKey();

  static int _monthToPage(DateTime m) => (m.year - 1900) * 12 + (m.month - 1);
  static DateTime _pageToMonth(int page) => DateTime(1900, page + 1, 1);

  static const CupertinoDynamicColor _kNativeCalendarBlue =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFF0088FF),
        darkColor: Color(0xFF0091FF),
      );

  Color _effectiveTint(BuildContext context) => widget.tintColor != null
      ? CupertinoDynamicColor.resolve(widget.tintColor!, context)
      : _kNativeCalendarBlue.resolveFrom(context);

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _sundayFirstWeekdays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const List<String> _mondayFirstWeekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _displayedMonth = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      1,
    );
    _monthPageController = PageController(
      initialPage: _monthToPage(_displayedMonth),
    );
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GlassDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDateTime != widget.initialDateTime) {
      _selectedDateTime = widget.initialDateTime;
      final newMonth = DateTime(
        widget.initialDateTime.year,
        widget.initialDateTime.month,
        1,
      );
      if (newMonth != _displayedMonth) {
        _displayedMonth = newMonth;
        _syncMonthPageController();
      }
    }
  }

  void _syncMonthPageController() {
    final target = _monthToPage(_displayedMonth);
    if (_monthPageController.hasClients) {
      _monthPageController.jumpToPage(target);
    } else {
      _monthPageController.dispose();
      _monthPageController = PageController(initialPage: target);
    }
  }

  void _onDateSelected(DateTime date) {
    if (_isDateDisabled(date)) return;

    final updated = DateTime(
      date.year,
      date.month,
      date.day,
      _selectedDateTime.hour,
      _selectedDateTime.minute,
    );

    HapticFeedback.selectionClick();
    setState(() {
      _selectedDateTime = updated;
    });
    widget.onDateTimeChanged?.call(updated);
  }

  void _onTimeChanged(int hour, int minute) {
    final updated = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      hour,
      minute,
    );

    HapticFeedback.selectionClick();
    setState(() {
      _selectedDateTime = updated;
    });
    widget.onDateTimeChanged?.call(updated);
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minimumDate != null) {
      final min = DateTime(
        widget.minimumDate!.year,
        widget.minimumDate!.month,
        widget.minimumDate!.day,
      );
      if (date.isBefore(min)) return true;
    }
    if (widget.maximumDate != null) {
      final max = DateTime(
        widget.maximumDate!.year,
        widget.maximumDate!.month,
        widget.maximumDate!.day,
      );
      if (date.isAfter(max)) return true;
    }
    return false;
  }

  void _changeMonth(int delta, {PageController? controller}) {
    final nextMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + delta,
      1,
    );
    setState(() {
      _displayedMonth = nextMonth;
    });
    final ctrl = controller ?? _monthPageController;
    if (ctrl.hasClients) {
      ctrl.animateToPage(
        _monthToPage(nextMonth),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<String> get _effectiveMonthNames => widget.monthNames ?? _monthNames;

  List<String> get _effectiveWeekdays =>
      widget.weekdayNames ??
      (widget.firstDayOfWeek == 7
          ? _sundayFirstWeekdays
          : _mondayFirstWeekdays);

  String _formatDate(DateTime dt) {
    if (widget.dateFormatter != null) {
      return widget.dateFormatter!(dt);
    }
    final month = _shortMonthNames[dt.month - 1];
    return '$month ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    if (widget.use24hFormat) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else {
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour12:$m $period';
    }
  }

  // ===========================================================================
  // Build Methods
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case GlassDatePickerStyle.compact:
        return _buildCompact(context);
      case GlassDatePickerStyle.wheel:
        return _buildWheel(context);
      case GlassDatePickerStyle.graphical:
        return _buildGraphical(context);
    }
  }

  // ===========================================================================
  // Compact Style
  // ===========================================================================

  Widget _buildCompact(BuildContext context) {
    // Native iOS 26/27 compact pills: 36pt capsule, tertiary system fill,
    // label-coloured text (active time pill turns tint blue while open).
    final pillBg = CupertinoColors.tertiarySystemFill.resolveFrom(context);
    final baseTextColor =
        widget.tintColor ?? CupertinoColors.label.resolveFrom(context);
    final activeTint = _effectiveTint(context);

    Widget pill(String text, {required bool isTime}) {
      final isActive = _activeCompactIsTime == isTime;
      final pillTextColor = (isActive && isTime) ? activeTint : baseTextColor;
      return GestureDetector(
        onTap: () => _openCompactModal(context, initialTabIsTime: isTime),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: pillBg,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.4,
              color: pillTextColor,
            ),
          ),
        ),
      );
    }

    final showDatePill = widget.mode != GlassDatePickerMode.time;
    final showTimePill = widget.mode != GlassDatePickerMode.date;

    return Row(
      key: _compactRowKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDatePill) pill(_formatDate(_selectedDateTime), isTime: false),
        if (showDatePill && showTimePill) const SizedBox(width: 4),
        if (showTimePill) pill(_formatTime(_selectedDateTime), isTime: true),
      ],
    );
  }

  void _openCompactModal(
    BuildContext context, {
    required bool initialTabIsTime,
  }) {
    final isTimePopover =
        initialTabIsTime || widget.mode == GlassDatePickerMode.time;
    final box = _compactRowKey.currentContext?.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.sizeOf(context);
    final pillRect = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : Rect.fromCenter(
            center: Offset(screenSize.width / 2, screenSize.height / 2),
            width: 215,
            height: 36,
          );

    final popoverWidth = isTimePopover ? 232.0 : 320.0;
    final popoverHeight = isTimePopover ? 204.0 : 332.0;

    // Position 9pt above the compact pill (or 9pt below if not enough room above),
    // right-aligned with the compact pill row matching _UIDatePickerOverlayPlatterView.
    final rawLeft =
        pillRect.right + (isTimePopover ? 0.67 : 3.67) - popoverWidth;
    final left = rawLeft.clamp(16.0, screenSize.width - popoverWidth - 16.0);
    final topAbove = pillRect.top - 9.0 - popoverHeight;
    final top = topAbove >= 60.0
        ? topAbove
        : (pillRect.bottom + 9.0).clamp(
            60.0,
            screenSize.height - popoverHeight - 24.0,
          );

    setState(() => _activeCompactIsTime = isTimePopover);
    PageController popoverPageController = PageController(
      initialPage: _monthToPage(_displayedMonth),
    );
    final capturedGlassTheme = GlassTheme.maybeOf(context)?.data;
    final capturedCupertinoTheme = CupertinoTheme.of(context);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x00000000),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurveTween(curve: Curves.easeOutCubic).animate(anim);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            alignment: topAbove >= 60.0
                ? Alignment.bottomRight
                : Alignment.topRight,
            child: child,
          ),
        );
      },
      pageBuilder: (modalContext, _, _) {
        final platterColor = isDark
            ? const Color(0xE0252528)
            : const Color(0xECF9F9FB);
        final platterCapColor = isDark
            ? const Color(0xFF252528)
            : const Color(0xFFF7F7FA);
        final borderColor = isDark
            ? const Color(0x2EFFFFFF)
            : const Color(0x18000000);

        Widget popover = _OnDispose(
          onDispose: () => popoverPageController.dispose(),
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: popoverWidth,
                height: popoverHeight,
                child: Container(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(34),
                      side: BorderSide(color: borderColor, width: 0.67),
                    ),
                    shadows: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(
                          alpha: isDark ? 0.45 : 0.14,
                        ),
                        blurRadius: 36,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: CupertinoColors.black.withValues(
                          alpha: isDark ? 0.25 : 0.05,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: ColoredBox(
                        color: platterColor,
                        child: isTimePopover
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 16,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.time,
                                      initialDateTime: _selectedDateTime,
                                      minimumDate: widget.minimumDate,
                                      maximumDate: widget.maximumDate,
                                      minuteInterval: widget.minuteInterval,
                                      use24hFormat: widget.use24hFormat,
                                      onDateTimeChanged: (val) {
                                        final updated = DateTime(
                                          _selectedDateTime.year,
                                          _selectedDateTime.month,
                                          _selectedDateTime.day,
                                          val.hour,
                                          val.minute,
                                        );
                                        setState(
                                          () => _selectedDateTime = updated,
                                        );
                                        widget.onDateTimeChanged?.call(updated);
                                      },
                                    ),
                                    IgnorePointer(
                                      child: SizedBox(
                                        height: 36,
                                        width: double.infinity,
                                        child: CustomPaint(
                                          painter: _WheelCapsuleCapPainter(
                                            cardColor: platterCapColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : StatefulBuilder(
                                builder: (popoverCtx, setPopoverState) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      13,
                                      8,
                                      14,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _CalendarHeader(
                                          label:
                                              '${_effectiveMonthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                                          tint: _effectiveTint(popoverCtx),
                                          arrowColor: CupertinoColors.label
                                              .resolveFrom(popoverCtx),
                                          pickerOpen: _showMonthYear,
                                          onToggle: () {
                                            setState(() {
                                              _showMonthYear = !_showMonthYear;
                                              if (!_showMonthYear) {
                                                popoverPageController.dispose();
                                                popoverPageController =
                                                    PageController(
                                                      initialPage: _monthToPage(
                                                        _displayedMonth,
                                                      ),
                                                    );
                                                _syncMonthPageController();
                                              }
                                            });
                                            setPopoverState(() {});
                                          },
                                          onPrevious: () {
                                            _changeMonth(
                                              -1,
                                              controller: popoverPageController,
                                            );
                                            setPopoverState(() {});
                                          },
                                          onNext: () {
                                            _changeMonth(
                                              1,
                                              controller: popoverPageController,
                                            );
                                            setPopoverState(() {});
                                          },
                                        ),
                                        if (_showMonthYear)
                                          Expanded(
                                            child: _MonthYearWheel(
                                              displayedMonth: _displayedMonth,
                                              monthNames: _effectiveMonthNames,
                                              compact: true,
                                              onChanged: (m) {
                                                setState(
                                                  () => _displayedMonth = m,
                                                );
                                                setPopoverState(() {});
                                              },
                                            ),
                                          )
                                        else ...[
                                          const SizedBox(height: 8),
                                          _buildWeekdayRow(
                                            popoverCtx,
                                            cellSize: 42.67,
                                          ),
                                          const SizedBox(height: 2),
                                          _buildPagedCalendarGrid(
                                            popoverCtx,
                                            controller: popoverPageController,
                                            compact: true,
                                            onDayTapped: (d) {
                                              _onDateSelected(d);
                                              setPopoverState(() {});
                                            },
                                            onMonthSwiped: () {
                                              setPopoverState(() {});
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        popover = CupertinoTheme(data: capturedCupertinoTheme, child: popover);
        if (capturedGlassTheme != null) {
          popover = GlassTheme(data: capturedGlassTheme, child: popover);
        }
        return popover;
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _activeCompactIsTime = null;
          _showMonthYear = false;
        });
      }
    });
  }

  // ===========================================================================
  // Wheel Style
  // ===========================================================================

  Widget _buildWheel(BuildContext context) {
    CupertinoDatePickerMode cupertinoMode;
    switch (widget.mode) {
      case GlassDatePickerMode.date:
        cupertinoMode = CupertinoDatePickerMode.date;
        break;
      case GlassDatePickerMode.time:
        cupertinoMode = CupertinoDatePickerMode.time;
        break;
      case GlassDatePickerMode.dateAndTime:
        cupertinoMode = CupertinoDatePickerMode.dateAndTime;
        break;
    }

    final cardBg = resolveGlassSolidSurfaceColor(context);

    return GlassContainer.card(
      useOwnLayer: true,
      settings: widget.settings,
      shape: widget.shape,
      quality: widget.quality,
      surfaceStyle: widget.surfaceStyle,
      padding: const EdgeInsets.fromLTRB(16, 15, 34, 15),
      child: SizedBox(
        height: 216,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CupertinoDatePicker(
              key: ValueKey<CupertinoDatePickerMode>(cupertinoMode),
              mode: cupertinoMode,
              initialDateTime: _selectedDateTime,
              minimumDate: widget.minimumDate,
              maximumDate: widget.maximumDate,
              minuteInterval: widget.minuteInterval,
              use24hFormat: widget.use24hFormat,
              onDateTimeChanged: (DateTime newDate) {
                setState(() => _selectedDateTime = newDate);
                widget.onDateTimeChanged?.call(newDate);
              },
            ),
            if (widget.surfaceStyle == GlassSurfaceStyle.solid)
              IgnorePointer(
                child: SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _WheelCapsuleCapPainter(cardColor: cardBg),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Graphical Calendar Style
  // ===========================================================================

  Widget _buildGraphical(BuildContext context) {
    return GlassContainer.card(
      useOwnLayer: true,
      settings: widget.settings,
      shape: widget.shape,
      quality: widget.quality,
      surfaceStyle: widget.surfaceStyle,
      padding: const EdgeInsets.fromLTRB(16, 27.5, 16, 33),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.mode != GlassDatePickerMode.time) ...[
            _buildMonthHeader(context),
            if (_showMonthYear)
              _MonthYearWheel(
                displayedMonth: _displayedMonth,
                monthNames: _effectiveMonthNames,
                onChanged: (m) => setState(() => _displayedMonth = m),
              )
            else ...[
              const SizedBox(height: 12.5),
              _buildWeekdayRow(context),
              const SizedBox(height: 3.33),
              _buildPagedCalendarGrid(
                context,
                controller: _monthPageController,
              ),
            ],
          ],
          if (widget.mode == GlassDatePickerMode.dateAndTime) ...[
            const SizedBox(height: 14),
            Container(
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            const SizedBox(height: 14),
          ],
          if (widget.mode != GlassDatePickerMode.date)
            _buildTimeSection(context),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    return _CalendarHeader(
      label:
          '${_effectiveMonthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
      tint: _effectiveTint(context),
      pickerOpen: _showMonthYear,
      onToggle: () => setState(() {
        _showMonthYear = !_showMonthYear;
        if (!_showMonthYear) {
          _syncMonthPageController();
        }
      }),
      onPrevious: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
    );
  }

  Widget _buildWeekdayRow(BuildContext context, {double cellSize = 44}) {
    final weekdays = _effectiveWeekdays;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: cellSize,
          height: 16,
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPagedCalendarGrid(
    BuildContext context, {
    required PageController controller,
    bool compact = false,
    ValueChanged<DateTime>? onDayTapped,
    VoidCallback? onMonthSwiped,
  }) {
    final gridHeight = compact ? 225.35 : 237.32;
    return SizedBox(
      height: gridHeight,
      child: PageView.builder(
        controller: controller,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        onPageChanged: (page) {
          final newMonth = _pageToMonth(page);
          if (newMonth.year != _displayedMonth.year ||
              newMonth.month != _displayedMonth.month) {
            setState(() {
              _displayedMonth = newMonth;
            });
            onMonthSwiped?.call();
          }
        },
        itemBuilder: (pageCtx, page) {
          final monthDate = _pageToMonth(page);
          final daysInMonth = DateTime(
            monthDate.year,
            monthDate.month + 1,
            0,
          ).day;
          final firstWeekday = DateTime(
            monthDate.year,
            monthDate.month,
            1,
          ).weekday;
          final leading = widget.firstDayOfWeek == 7
              ? (firstWeekday % 7)
              : ((firstWeekday - 1) % 7);
          final sixRows = ((leading + daysInMonth) / 7).ceil() > 5;
          return _buildCalendarGrid(
            pageCtx,
            monthDate: monthDate,
            cellSize: compact
                ? (sixRows ? 36.0 : 42.67)
                : (sixRows ? 37.5 : 44.0),
            rowGap: compact ? (sixRows ? 1.8 : 3.0) : (sixRows ? 2.46 : 4.33),
            onDayTapped: onDayTapped,
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context, {
    DateTime? monthDate,
    double cellSize = 44,
    double rowGap = 4.33,
    ValueChanged<DateTime>? onDayTapped,
  }) {
    final targetMonth = monthDate ?? _displayedMonth;
    final year = targetMonth.year;
    final month = targetMonth.month;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final firstWeekday = firstDay.weekday;
    final leadingPaddingDays = widget.firstDayOfWeek == 7
        ? (firstWeekday % 7)
        : ((firstWeekday - 1) % 7);

    final totalCells = ((leadingPaddingDays + daysInMonth) / 7).ceil() * 7;

    final List<Widget> dayWidgets = [];
    final today = DateTime.now();
    final effectiveTint = _effectiveTint(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final invertedLabelColor = CupertinoColors.systemBackground.resolveFrom(
      context,
    );

    for (int i = 0; i < totalCells; i++) {
      if (i < leadingPaddingDays || i >= leadingPaddingDays + daysInMonth) {
        // Native iOS 26/27 UICalendarView leaves out-of-month cells blank.
        dayWidgets.add(SizedBox(width: cellSize, height: cellSize));
      } else {
        // Day in current month
        final dayNum = i - leadingPaddingDays + 1;
        final cellDate = DateTime(year, month, dayNum);

        final isSelected =
            cellDate.year == _selectedDateTime.year &&
            cellDate.month == _selectedDateTime.month &&
            cellDate.day == _selectedDateTime.day;

        final isToday =
            cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;

        final isDisabled = _isDateDisabled(cellDate);

        // Native iOS 26/27 DatePicker(.graphical) selection rules:
        // - Selected Today: solid tint circle (#0088FF / #0091FF) + white text
        // - Selected other day: solid label circle (black in light, white in dark)
        //   unless an explicit tintColor was supplied
        // - Unselected Today: translucent tint circle (alpha 0.12) + tint text
        Color? circleColor;
        Color textColor;
        if (isSelected) {
          if (isToday || widget.tintColor != null) {
            circleColor = effectiveTint;
            textColor = CupertinoColors.white;
          } else {
            circleColor = labelColor;
            textColor = invertedLabelColor;
          }
        } else if (isDisabled) {
          textColor = CupertinoColors.tertiaryLabel.resolveFrom(context);
        } else if (isToday) {
          circleColor = effectiveTint.withValues(alpha: 0.12);
          textColor = effectiveTint;
        } else {
          textColor = labelColor;
        }

        dayWidgets.add(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isDisabled
                ? null
                : () {
                    if (onDayTapped != null) {
                      onDayTapped(cellDate);
                    } else {
                      _onDateSelected(cellDate);
                    }
                  },
            child: SizedBox(
              width: cellSize,
              height: cellSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (circleColor != null)
                    Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                      ),
                    ),
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: -0.45,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final List<Widget> rowWidgets = [];
    for (int r = 0; r < dayWidgets.length; r += 7) {
      rowWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayWidgets.sublist(r, math.min(r + 7, dayWidgets.length)),
        ),
      );
      if (r + 7 < dayWidgets.length) {
        rowWidgets.add(SizedBox(height: rowGap));
      }
    }

    return Column(children: rowWidgets);
  }

  Widget _buildTimeSection(BuildContext context) {
    final hour = _selectedDateTime.hour;
    final minute = _selectedDateTime.minute;
    final effectiveTint = widget.tintColor ?? CupertinoColors.activeBlue;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hour control
            _buildTimeDigitPill(
              context,
              widget.use24hFormat
                  ? hour.toString().padLeft(2, '0')
                  : (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(
                      2,
                      '0',
                    ),
              onIncrement: () => _onTimeChanged((hour + 1) % 24, minute),
              onDecrement: () => _onTimeChanged((hour - 1 + 24) % 24, minute),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // Minute control
            _buildTimeDigitPill(
              context,
              minute.toString().padLeft(2, '0'),
              onIncrement: () =>
                  _onTimeChanged(hour, (minute + widget.minuteInterval) % 60),
              onDecrement: () => _onTimeChanged(
                hour,
                (minute - widget.minuteInterval + 60) % 60,
              ),
            ),
            if (!widget.use24hFormat) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final newHour = hour >= 12 ? hour - 12 : hour + 12;
                  _onTimeChanged(newHour, minute);
                },
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: effectiveTint.withValues(alpha: 0.15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hour >= 12 ? 'PM' : 'AM',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: effectiveTint,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTimeDigitPill(
    BuildContext context,
    String digits, {
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final pillBg = isDark
        ? CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.8)
        : CupertinoColors.systemGrey5.color.withValues(alpha: 0.8);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: pillBg,
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.12)
              : CupertinoColors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDecrement,
            child: const Icon(CupertinoIcons.minus, size: 12),
          ),
          const SizedBox(width: 6),
          Text(
            digits,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onIncrement,
            child: const Icon(CupertinoIcons.plus, size: 12),
          ),
        ],
      ),
    );
  }
}

/// A multi-date picker component providing 100% parity with SwiftUI's `MultiDatePicker`.
class GlassMultiDatePicker extends StatefulWidget {
  /// Creates a [GlassMultiDatePicker].
  const GlassMultiDatePicker({
    super.key,
    required this.selectedDates,
    this.onDatesChanged,
    this.displayedMonth,
    this.minimumDate,
    this.maximumDate,
    this.tintColor,
    this.firstDayOfWeek = 7,
    this.monthNames,
    this.weekdayNames,
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : assert(monthNames == null || monthNames.length == 12),
       assert(weekdayNames == null || weekdayNames.length == 7);

  /// The set of currently selected dates.
  final Set<DateTime> selectedDates;

  /// Callback executed when the selected dates change.
  final ValueChanged<Set<DateTime>>? onDatesChanged;

  /// Optional month initially displayed. If null, displays current month.
  final DateTime? displayedMonth;

  /// Earliest selectable date.
  final DateTime? minimumDate;

  /// Latest selectable date.
  final DateTime? maximumDate;

  /// Selection accent color.
  final Color? tintColor;

  /// First day of the week (7 = Sunday, 1 = Monday).
  final int firstDayOfWeek;

  /// Optional localized full month names (12 entries, January through December).
  final List<String>? monthNames;

  /// Optional localized short weekday headers (7 entries ordered starting from
  /// [firstDayOfWeek]).
  final List<String>? weekdayNames;

  /// Liquid glass settings. Ignored when [surfaceStyle] is
  /// [GlassSurfaceStyle.solid].
  final LiquidGlassSettings? settings;

  /// Shape of the picker's card.
  ///
  /// If null, defaults to a 12pt [LiquidRoundedSuperellipse] for
  /// [GlassSurfaceStyle.glass] and 26pt for [GlassSurfaceStyle.solid], the
  /// corner radius of native iOS 26 inset grouped containers.
  final LiquidShape? shape;

  /// Rendering quality tier. Ignored when [surfaceStyle] is
  /// [GlassSurfaceStyle.solid].
  final GlassQuality? quality;

  /// How the picker's card is painted.
  ///
  /// [GlassSurfaceStyle.glass] (default in 1.x) renders a glass card.
  /// [GlassSurfaceStyle.solid] renders a flat opaque card matching native iOS
  /// grouped containers.
  final GlassSurfaceStyle surfaceStyle;

  @override
  State<GlassMultiDatePicker> createState() => _GlassMultiDatePickerState();
}

class _GlassMultiDatePickerState extends State<GlassMultiDatePicker> {
  late DateTime _displayedMonth;
  late PageController _monthPageController;
  bool _showMonthYear = false;
  late Set<DateTime> _selectedDates;

  static int _monthToPage(DateTime m) => (m.year - 1900) * 12 + (m.month - 1);
  static DateTime _pageToMonth(int page) => DateTime(1900, page + 1, 1);

  static const CupertinoDynamicColor _kNativeCalendarBlue =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFF0088FF),
        darkColor: Color(0xFF0091FF),
      );

  Color _effectiveTint(BuildContext context) => widget.tintColor != null
      ? CupertinoDynamicColor.resolve(widget.tintColor!, context)
      : _kNativeCalendarBlue.resolveFrom(context);

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _sundayFirstWeekdays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const List<String> _mondayFirstWeekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDates = Set<DateTime>.from(
      widget.selectedDates.map(_normalizeDate),
    );
    final initialMonth = widget.displayedMonth != null
        ? DateTime(widget.displayedMonth!.year, widget.displayedMonth!.month, 1)
        : DateTime(DateTime.now().year, DateTime.now().month, 1);
    _displayedMonth = initialMonth;
    _monthPageController = PageController(
      initialPage: _monthToPage(_displayedMonth),
    );
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  void _syncMonthPageController() {
    final target = _monthToPage(_displayedMonth);
    if (_monthPageController.hasClients) {
      _monthPageController.jumpToPage(target);
    } else {
      _monthPageController.dispose();
      _monthPageController = PageController(initialPage: target);
    }
  }

  @override
  void didUpdateWidget(covariant GlassMultiDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDates != widget.selectedDates) {
      _selectedDates = Set<DateTime>.from(
        widget.selectedDates.map(_normalizeDate),
      );
    }
    if (oldWidget.displayedMonth != widget.displayedMonth &&
        widget.displayedMonth != null) {
      final newMonth = DateTime(
        widget.displayedMonth!.year,
        widget.displayedMonth!.month,
        1,
      );
      if (newMonth != _displayedMonth) {
        _displayedMonth = newMonth;
        _syncMonthPageController();
      }
    }
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isDateSelected(DateTime dt) {
    final norm = _normalizeDate(dt);
    return _selectedDates.contains(norm);
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minimumDate != null) {
      final min = _normalizeDate(widget.minimumDate!);
      if (date.isBefore(min)) return true;
    }
    if (widget.maximumDate != null) {
      final max = _normalizeDate(widget.maximumDate!);
      if (date.isAfter(max)) return true;
    }
    return false;
  }

  void _toggleDate(DateTime dt) {
    if (_isDateDisabled(dt)) return;
    final norm = _normalizeDate(dt);
    final newSet = Set<DateTime>.from(_selectedDates);

    if (newSet.contains(norm)) {
      newSet.remove(norm);
    } else {
      newSet.add(norm);
    }

    HapticFeedback.selectionClick();
    setState(() {
      _selectedDates = newSet;
    });
    widget.onDatesChanged?.call(newSet);
  }

  void _changeMonth(int delta, {PageController? controller}) {
    final nextMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + delta,
      1,
    );
    setState(() {
      _displayedMonth = nextMonth;
    });
    final ctrl = controller ?? _monthPageController;
    if (ctrl.hasClients) {
      ctrl.animateToPage(
        _monthToPage(nextMonth),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildMonthGrid(
    BuildContext context,
    DateTime monthDate, {
    required double cellSize,
    required double rowGap,
  }) {
    final effectiveTint = _effectiveTint(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final invertedLabelColor = CupertinoColors.systemBackground.resolveFrom(
      context,
    );
    final selectionCircleColor = widget.tintColor != null
        ? effectiveTint
        : labelColor;
    final selectionTextColor = widget.tintColor != null
        ? CupertinoColors.white
        : invertedLabelColor;
    final year = monthDate.year;
    final month = monthDate.month;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final firstWeekday = firstDay.weekday;
    final leadingPaddingDays = widget.firstDayOfWeek == 7
        ? (firstWeekday % 7)
        : ((firstWeekday - 1) % 7);

    final totalCells = ((leadingPaddingDays + daysInMonth) / 7).ceil() * 7;
    final List<Widget> dayWidgets = [];
    final today = DateTime.now();

    for (int i = 0; i < totalCells; i++) {
      if (i < leadingPaddingDays || i >= leadingPaddingDays + daysInMonth) {
        // Native iOS 26/27 MultiDatePicker leaves out-of-month cells blank.
        dayWidgets.add(SizedBox(width: cellSize, height: cellSize));
      } else {
        final dayNum = i - leadingPaddingDays + 1;
        final cellDate = DateTime(year, month, dayNum);
        final selected = _isDateSelected(cellDate);
        final disabled = _isDateDisabled(cellDate);

        final isToday =
            cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;

        Color textColor;
        if (selected) {
          textColor = selectionTextColor;
        } else if (disabled) {
          textColor = CupertinoColors.tertiaryLabel.resolveFrom(context);
        } else if (isToday) {
          textColor = effectiveTint;
        } else {
          textColor = labelColor;
        }

        dayWidgets.add(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: disabled ? null : () => _toggleDate(cellDate),
            child: SizedBox(
              width: cellSize,
              height: cellSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (selected)
                    Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectionCircleColor,
                      ),
                    ),
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: -0.45,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final List<Widget> rowWidgets = [];
    for (int r = 0; r < dayWidgets.length; r += 7) {
      rowWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayWidgets.sublist(r, math.min(r + 7, dayWidgets.length)),
        ),
      );
      if (r + 7 < dayWidgets.length) {
        rowWidgets.add(SizedBox(height: rowGap));
      }
    }

    return Column(children: rowWidgets);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMonthNames = widget.monthNames ?? _monthNames;
    final effectiveTint = _effectiveTint(context);
    final monthName = effectiveMonthNames[_displayedMonth.month - 1];
    final year = _displayedMonth.year;
    final weekdays =
        widget.weekdayNames ??
        (widget.firstDayOfWeek == 7
            ? _sundayFirstWeekdays
            : _mondayFirstWeekdays);

    return GlassContainer.card(
      useOwnLayer: true,
      settings: widget.settings,
      shape: widget.shape,
      quality: widget.quality,
      surfaceStyle: widget.surfaceStyle,
      padding: const EdgeInsets.fromLTRB(16, 27.5, 16, 33),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarHeader(
            label: '$monthName $year',
            tint: effectiveTint,
            pickerOpen: _showMonthYear,
            onToggle: () => setState(() {
              _showMonthYear = !_showMonthYear;
              if (!_showMonthYear) {
                _syncMonthPageController();
              }
            }),
            onPrevious: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          if (_showMonthYear)
            _MonthYearWheel(
              displayedMonth: _displayedMonth,
              monthNames: effectiveMonthNames,
              onChanged: (m) => setState(() => _displayedMonth = m),
            )
          else ...[
            const SizedBox(height: 12.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays.map((day) {
                return SizedBox(
                  width: 44,
                  height: 16,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 3.33),
            SizedBox(
              height: 237.32,
              child: PageView.builder(
                controller: _monthPageController,
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                onPageChanged: (page) {
                  final newMonth = _pageToMonth(page);
                  if (newMonth.year != _displayedMonth.year ||
                      newMonth.month != _displayedMonth.month) {
                    setState(() {
                      _displayedMonth = newMonth;
                    });
                  }
                },
                itemBuilder: (pageCtx, page) {
                  final monthDate = _pageToMonth(page);
                  final daysInMonth = DateTime(
                    monthDate.year,
                    monthDate.month + 1,
                    0,
                  ).day;
                  final firstWeekday = DateTime(
                    monthDate.year,
                    monthDate.month,
                    1,
                  ).weekday;
                  final leading = widget.firstDayOfWeek == 7
                      ? (firstWeekday % 7)
                      : ((firstWeekday - 1) % 7);
                  final sixRows = ((leading + daysInMonth) / 7).ceil() > 5;
                  return _buildMonthGrid(
                    pageCtx,
                    monthDate,
                    cellSize: sixRows ? 37.5 : 44.0,
                    rowGap: sixRows ? 2.46 : 4.33,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Imperatively displays a modal liquid glass date/time picker sheet.
///
/// [surfaceStyle] is forwarded to the [GlassDatePicker] inside the sheet.
Future<DateTime?> showGlassDatePicker({
  required BuildContext context,
  DateTime? initialDateTime,
  GlassDatePickerMode mode = GlassDatePickerMode.date,
  GlassDatePickerStyle style = GlassDatePickerStyle.graphical,
  DateTime? minimumDate,
  DateTime? maximumDate,
  int minuteInterval = 1,
  bool use24hFormat = false,
  Color? tintColor,
  String title = 'Select Date',
  LiquidGlassSettings? settings,
  GlassQuality? quality,
  GlassSurfaceStyle surfaceStyle = GlassSurfaceStyle.glass,
}) async {
  DateTime selected = initialDateTime ?? DateTime.now();
  final capturedGlassTheme = GlassTheme.maybeOf(context)?.data;
  final capturedCupertinoTheme = CupertinoTheme.of(context);

  final result = await showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (modalContext) {
      Widget sheet = Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: CupertinoColors.systemBackground.resolveFrom(modalContext),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.35),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(modalContext).pop(null),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(modalContext),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.of(modalContext).pop(selected),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassDatePicker(
              initialDateTime: selected,
              mode: mode,
              style: style,
              minimumDate: minimumDate,
              maximumDate: maximumDate,
              minuteInterval: minuteInterval,
              use24hFormat: use24hFormat,
              tintColor: tintColor,
              settings: settings,
              quality: quality,
              surfaceStyle: surfaceStyle,
              onDateTimeChanged: (val) {
                selected = val;
              },
            ),
          ],
        ),
      );
      sheet = DefaultTextStyle(
        style: capturedCupertinoTheme.textTheme.textStyle,
        child: CupertinoTheme(data: capturedCupertinoTheme, child: sheet),
      );
      if (capturedGlassTheme != null) {
        sheet = GlassTheme(data: capturedGlassTheme, child: sheet);
      }
      return sheet;
    },
  );

  return result;
}

/// Calendar header shared by the graphical and multi-date pickers:
/// a tappable "Month Year ›" label (opens the month/year wheel) and bold
/// previous/next chevrons, as in SwiftUI's graphical `DatePicker`.
class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.label,
    required this.tint,
    this.arrowColor,
    required this.pickerOpen,
    required this.onToggle,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final Color tint;
  final Color? arrowColor;
  final bool pickerOpen;
  final VoidCallback onToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final titleColor = pickerOpen
        ? tint
        : CupertinoColors.label.resolveFrom(context);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: titleColor,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: pickerOpen ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: 8,
                    height: 12,
                    child: CustomPaint(
                      painter: _PickerChevronPainter(
                        color: tint,
                        halfWidth: 2.2,
                        halfHeight: 4.2,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!pickerOpen) ...[
            _navButton(onPrevious, left: true),
            const SizedBox(width: 15.5),
            _navButton(onNext, left: false),
          ],
        ],
      ),
    );
  }

  Widget _navButton(VoidCallback onTap, {required bool left}) {
    return Semantics(
      button: true,
      label: left ? 'Previous month' : 'Next month',
      child: GestureDetector(
        key: ValueKey<String>(
          left ? 'glass_calendar_previous' : 'glass_calendar_next',
        ),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 44,
          child: CustomPaint(
            painter: _PickerChevronPainter(
              color: arrowColor ?? tint,
              halfWidth: 4.5,
              halfHeight: 8.5,
              strokeWidth: 2.8,
              pointsLeft: left,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bold, round-capped chevron matching SF Symbols `chevron.left/right`.
class _PickerChevronPainter extends CustomPainter {
  const _PickerChevronPainter({
    required this.color,
    required this.halfWidth,
    required this.halfHeight,
    required this.strokeWidth,
    this.pointsLeft = false,
  });

  final Color color;
  final double halfWidth;
  final double halfHeight;
  final double strokeWidth;
  final bool pointsLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dir = pointsLeft ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(cx - dir * halfWidth, cy - halfHeight)
      ..lineTo(cx + dir * halfWidth, cy)
      ..lineTo(cx - dir * halfWidth, cy + halfHeight);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PickerChevronPainter old) =>
      old.color != color ||
      old.halfWidth != halfWidth ||
      old.halfHeight != halfHeight ||
      old.strokeWidth != strokeWidth ||
      old.pointsLeft != pointsLeft;
}

/// Month / year wheels shown in place of the day grid when the calendar
/// header is tapped (native graphical `DatePicker` behaviour).
class _MonthYearWheel extends StatefulWidget {
  const _MonthYearWheel({
    required this.displayedMonth,
    required this.monthNames,
    required this.onChanged,
    this.compact = false,
  });

  final DateTime displayedMonth;
  final List<String> monthNames;
  final ValueChanged<DateTime> onChanged;
  final bool compact;

  @override
  State<_MonthYearWheel> createState() => _MonthYearWheelState();
}

class _MonthYearWheelState extends State<_MonthYearWheel> {
  static const int _firstYear = 1900;
  static const int _yearCount = 300;

  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    _month = widget.displayedMonth.month;
    _year = widget.displayedMonth.year;
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _year - _firstYear,
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _emit() {
    HapticFeedback.selectionClick();
    widget.onChanged(DateTime(_year, _month, 1));
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 21,
      letterSpacing: -0.45,
      color: CupertinoColors.label.resolveFrom(context),
    );
    final overlayColor = CupertinoColors.tertiarySystemFill.resolveFrom(
      context,
    );
    return Padding(
      padding: EdgeInsets.only(
        top: widget.compact ? 8 : 19.67,
        bottom: widget.compact ? 8 : 33.48,
      ),
      child: SizedBox(
        height: 216,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Container(
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 57,
                  child: CupertinoPicker(
                    scrollController: _monthController,
                    itemExtent: 34,
                    selectionOverlay: const SizedBox.shrink(),
                    onSelectedItemChanged: (i) {
                      _month = i + 1;
                      _emit();
                    },
                    children: [
                      for (final m in widget.monthNames)
                        Center(child: Text(m, style: style)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 43,
                  child: CupertinoPicker(
                    scrollController: _yearController,
                    itemExtent: 34,
                    selectionOverlay: const SizedBox.shrink(),
                    onSelectedItemChanged: (i) {
                      _year = _firstYear + i;
                      _emit();
                    },
                    children: [
                      for (var y = _firstYear; y < _firstYear + _yearCount; y++)
                        Center(child: Text('$y', style: style)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounds the 8pt corners of [CupertinoDatePicker]'s selection highlight into
/// a native iOS 26/27 34pt-tall stadium capsule on solid cards.
class _WheelCapsuleCapPainter extends CustomPainter {
  const _WheelCapsuleCapPainter({required this.cardColor});

  final Color cardColor;

  @override
  void paint(Canvas canvas, Size size) {
    final barRect = Rect.fromLTWH(
      9,
      (size.height - 34) / 2,
      size.width - 18,
      34,
    );
    final outer = Path()..addRect(Offset.zero & size);
    final capsule = Path()
      ..addRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(17)));
    final mask = Path.combine(PathOperation.difference, outer, capsule);
    canvas.drawPath(mask, Paint()..color = cardColor);
  }

  @override
  bool shouldRepaint(_WheelCapsuleCapPainter old) => old.cardColor != cardColor;
}

class _OnDispose extends StatefulWidget {
  const _OnDispose({required this.onDispose, required this.child});

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_OnDispose> createState() => _OnDisposeState();
}

class _OnDisposeState extends State<_OnDispose> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
