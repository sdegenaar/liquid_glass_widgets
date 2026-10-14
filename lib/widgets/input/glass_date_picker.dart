import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../containers/glass_container.dart';

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
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  });

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
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : style = GlassDatePickerStyle.compact;

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
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : style = GlassDatePickerStyle.graphical;

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
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  }) : style = GlassDatePickerStyle.wheel;

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
  bool _showMonthYear = false;

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
    'December'
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
    'Dec'
  ];

  static const List<String> _sundayFirstWeekdays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT'
  ];

  static const List<String> _mondayFirstWeekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _displayedMonth =
        DateTime(widget.initialDateTime.year, widget.initialDateTime.month, 1);
  }

  @override
  void didUpdateWidget(covariant GlassDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDateTime != widget.initialDateTime) {
      _selectedDateTime = widget.initialDateTime;
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

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
    });
  }

  String _formatDate(DateTime dt) {
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
    // Native iOS 26 compact pills: capsule, tertiary system fill, label-coloured
    // text (an explicit [tintColor] overrides the text colour).
    final pillBg = CupertinoColors.tertiarySystemFill.resolveFrom(context);
    final textColor =
        widget.tintColor ?? CupertinoColors.label.resolveFrom(context);

    Widget pill(String text, {required bool isTime}) {
      return GestureDetector(
        onTap: () => _openCompactModal(context, initialTabIsTime: isTime),
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17.5),
            color: pillBg,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.4,
              color: textColor,
            ),
          ),
        ),
      );
    }

    final showDatePill = widget.mode != GlassDatePickerMode.time;
    final showTimePill = widget.mode != GlassDatePickerMode.date;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDatePill) pill(_formatDate(_selectedDateTime), isTime: false),
        if (showDatePill && showTimePill) const SizedBox(width: 4),
        if (showTimePill) pill(_formatTime(_selectedDateTime), isTime: true),
      ],
    );
  }

  void _openCompactModal(BuildContext context,
      {required bool initialTabIsTime}) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: CupertinoColors.systemBackground.resolveFrom(modalContext),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
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
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                  Text(
                    widget.mode == GlassDatePickerMode.time
                        ? 'Select Time'
                        : 'Select Date',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GlassDatePicker.graphical(
                initialDateTime: _selectedDateTime,
                mode: widget.mode,
                minimumDate: widget.minimumDate,
                maximumDate: widget.maximumDate,
                minuteInterval: widget.minuteInterval,
                use24hFormat: widget.use24hFormat,
                tintColor: widget.tintColor,
                firstDayOfWeek: widget.firstDayOfWeek,
                settings: widget.settings,
                quality: widget.quality,
                surfaceStyle: widget.surfaceStyle,
                onDateTimeChanged: (val) {
                  setState(() => _selectedDateTime = val);
                  widget.onDateTimeChanged?.call(val);
                },
              ),
            ],
          ),
        );
      },
    );
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

    return GlassContainer.card(
      useOwnLayer: true,
      settings: widget.settings,
      shape: widget.shape,
      quality: widget.quality,
      surfaceStyle: widget.surfaceStyle,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: SizedBox(
        height: 216,
        child: CupertinoDatePicker(
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
      padding: const EdgeInsets.fromLTRB(16, 27, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.mode != GlassDatePickerMode.time) ...[
            _buildMonthHeader(context),
            if (_showMonthYear)
              _MonthYearWheel(
                displayedMonth: _displayedMonth,
                monthNames: _monthNames,
                onChanged: (m) => setState(() => _displayedMonth = m),
              )
            else ...[
              const SizedBox(height: 13),
              _buildWeekdayRow(context),
              const SizedBox(height: 8),
              _buildCalendarGrid(context),
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
          '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
      tint: widget.tintColor ?? CupertinoColors.activeBlue,
      pickerOpen: _showMonthYear,
      onToggle: () => setState(() => _showMonthYear = !_showMonthYear),
      onPrevious: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
    );
  }

  Widget _buildWeekdayRow(BuildContext context) {
    final weekdays = widget.firstDayOfWeek == 7
        ? _sundayFirstWeekdays
        : _mondayFirstWeekdays;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: 38,
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

  Widget _buildCalendarGrid(BuildContext context) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysInPrevMonth = DateTime(year, month, 0).day;

    final firstWeekday = firstDay.weekday;
    final leadingPaddingDays = widget.firstDayOfWeek == 7
        ? (firstWeekday % 7)
        : ((firstWeekday - 1) % 7);

    final totalCells = ((leadingPaddingDays + daysInMonth) / 7).ceil() * 7;

    final List<Widget> dayWidgets = [];
    final today = DateTime.now();
    final effectiveTint = widget.tintColor ?? CupertinoColors.activeBlue;

    for (int i = 0; i < totalCells; i++) {
      if (i < leadingPaddingDays) {
        // Day from previous month
        final dayNum = daysInPrevMonth - leadingPaddingDays + i + 1;
        dayWidgets.add(
          SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
        );
      } else if (i < leadingPaddingDays + daysInMonth) {
        // Day in current month
        final dayNum = i - leadingPaddingDays + 1;
        final cellDate = DateTime(year, month, dayNum);

        final isSelected = cellDate.year == _selectedDateTime.year &&
            cellDate.month == _selectedDateTime.month &&
            cellDate.day == _selectedDateTime.day;

        final isToday = cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;

        final isDisabled = _isDateDisabled(cellDate);

        Color textColor;
        if (isSelected) {
          textColor = CupertinoColors.white;
        } else if (isDisabled) {
          textColor = CupertinoColors.tertiaryLabel.resolveFrom(context);
        } else if (isToday) {
          textColor = effectiveTint;
        } else {
          textColor = CupertinoColors.label.resolveFrom(context);
        }

        dayWidgets.add(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isDisabled ? null : () => _onDateSelected(cellDate),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveTint,
                        boxShadow: [
                          BoxShadow(
                            color: effectiveTint.withValues(alpha: 0.38),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected || isToday
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
      } else {
        // Day in next month
        final dayNum = i - (leadingPaddingDays + daysInMonth) + 1;
        dayWidgets.add(
          SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
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
        rowWidgets.add(const SizedBox(height: 4));
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
                  : (hour % 12 == 0 ? 12 : hour % 12)
                      .toString()
                      .padLeft(2, '0'),
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
              onIncrement: () => _onTimeChanged(
                hour,
                (minute + widget.minuteInterval) % 60,
              ),
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
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
    this.settings,
    this.shape,
    this.quality,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  });

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
  bool _showMonthYear = false;
  late Set<DateTime> _selectedDates;

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
    'December'
  ];

  static const List<String> _sundayFirstWeekdays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT'
  ];

  static const List<String> _mondayFirstWeekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDates =
        Set<DateTime>.from(widget.selectedDates.map(_normalizeDate));
    _displayedMonth = widget.displayedMonth != null
        ? DateTime(widget.displayedMonth!.year, widget.displayedMonth!.month, 1)
        : DateTime.now();
  }

  @override
  void didUpdateWidget(covariant GlassMultiDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDates != widget.selectedDates) {
      _selectedDates =
          Set<DateTime>.from(widget.selectedDates.map(_normalizeDate));
    }
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isDateSelected(DateTime dt) {
    final norm = _normalizeDate(dt);
    return _selectedDates.contains(norm);
  }

  void _toggleDate(DateTime dt) {
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

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTint = widget.tintColor ?? CupertinoColors.activeBlue;
    final monthName = _monthNames[_displayedMonth.month - 1];
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysInPrevMonth = DateTime(year, month, 0).day;

    final firstWeekday = firstDay.weekday;
    final leadingPaddingDays = widget.firstDayOfWeek == 7
        ? (firstWeekday % 7)
        : ((firstWeekday - 1) % 7);

    final totalCells = ((leadingPaddingDays + daysInMonth) / 7).ceil() * 7;
    final weekdays = widget.firstDayOfWeek == 7
        ? _sundayFirstWeekdays
        : _mondayFirstWeekdays;

    final List<Widget> dayWidgets = [];
    final today = DateTime.now();

    for (int i = 0; i < totalCells; i++) {
      if (i < leadingPaddingDays) {
        final dayNum = daysInPrevMonth - leadingPaddingDays + i + 1;
        dayWidgets.add(
          SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
        );
      } else if (i < leadingPaddingDays + daysInMonth) {
        final dayNum = i - leadingPaddingDays + 1;
        final cellDate = DateTime(year, month, dayNum);
        final selected = _isDateSelected(cellDate);

        final isToday = cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;

        dayWidgets.add(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleDate(cellDate),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (selected)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveTint,
                        boxShadow: [
                          BoxShadow(
                            color: effectiveTint.withValues(alpha: 0.38),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected
                          ? CupertinoColors.white
                          : (isToday
                              ? effectiveTint
                              : CupertinoColors.label.resolveFrom(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        final dayNum = i - (leadingPaddingDays + daysInMonth) + 1;
        dayWidgets.add(
          SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
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
        rowWidgets.add(const SizedBox(height: 4));
      }
    }

    return GlassContainer.card(
      useOwnLayer: true,
      settings: widget.settings,
      shape: widget.shape,
      quality: widget.quality,
      surfaceStyle: widget.surfaceStyle,
      padding: const EdgeInsets.fromLTRB(16, 27, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarHeader(
            label: '$monthName $year',
            tint: effectiveTint,
            pickerOpen: _showMonthYear,
            onToggle: () => setState(() => _showMonthYear = !_showMonthYear),
            onPrevious: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          if (_showMonthYear)
            _MonthYearWheel(
              displayedMonth: _displayedMonth,
              monthNames: _monthNames,
              onChanged: (m) => setState(() => _displayedMonth = m),
            )
          else ...[
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays.map((day) {
                return SizedBox(
                  width: 38,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Column(children: rowWidgets),
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

  final result = await showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (modalContext) {
      return Container(
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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
    required this.pickerOpen,
    required this.onToggle,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final Color tint;
  final bool pickerOpen;
  final VoidCallback onToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
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
                    color: CupertinoColors.label.resolveFrom(context),
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
            const SizedBox(width: 8),
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
            left ? 'glass_calendar_previous' : 'glass_calendar_next'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 44,
          child: CustomPaint(
            painter: _PickerChevronPainter(
              color: tint,
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
  });

  final DateTime displayedMonth;
  final List<String> monthNames;
  final ValueChanged<DateTime> onChanged;

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
    _yearController =
        FixedExtentScrollController(initialItem: _year - _firstYear);
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
      color: CupertinoColors.label.resolveFrom(context),
    );
    return SizedBox(
      height: 216,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: CupertinoPicker(
              scrollController: _monthController,
              itemExtent: 36,
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
            flex: 2,
            child: CupertinoPicker(
              scrollController: _yearController,
              itemExtent: 36,
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
    );
  }
}
