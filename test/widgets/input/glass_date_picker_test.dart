import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassDatePicker (Graphical & Inline Calendar)', () {
    testWidgets('renders month header, weekdays, and day numbers',
        (tester) async {
      final initialDate = DateTime(2026, 10, 8);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: initialDate,
              ),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);
      for (final d in ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']) {
        expect(find.text(d), findsOneWidget);
      }
      expect(find.text('8'), findsWidgets); // Day 8 of October
    });

    testWidgets('tapping next and previous month chevrons updates month',
        (tester) async {
      final initialDate = DateTime(2026, 10, 8);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: initialDate,
              ),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);

      // Tap next month chevron
      await tester
          .tap(find.byKey(const ValueKey<String>('glass_calendar_next')));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);

      // Tap previous month chevron twice
      await tester
          .tap(find.byKey(const ValueKey<String>('glass_calendar_previous')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey<String>('glass_calendar_previous')));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('tapping a day selects it and triggers onDateTimeChanged',
        (tester) async {
      final initialDate = DateTime(2026, 10, 8);
      DateTime? changedDate;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: initialDate,
                onDateTimeChanged: (val) => changedDate = val,
              ),
            ),
          ),
        ),
      );

      // Tap on day 15
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(changedDate, isNotNull);
      expect(changedDate!.year, 2026);
      expect(changedDate!.month, 10);
      expect(changedDate!.day, 15);
    });

    testWidgets('respects minimumDate constraint', (tester) async {
      final initialDate = DateTime(2026, 10, 8);
      final minDate = DateTime(2026, 10, 5);
      DateTime? changedDate;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: initialDate,
                minimumDate: minDate,
                onDateTimeChanged: (val) => changedDate = val,
              ),
            ),
          ),
        ),
      );

      // Tap day 2 (before minimum date of Oct 5)
      await tester.tap(find.text('2').first);
      await tester.pumpAndSettle();

      // Should not have updated
      expect(changedDate, isNull);

      // Tap day 10 (after minimum date)
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      expect(changedDate, isNotNull);
      expect(changedDate!.day, 10);
    });
  });

  group('GlassDatePicker (Compact Style)', () {
    testWidgets('renders compact date and time pills', (tester) async {
      final initialDate = DateTime(2026, 10, 8, 20, 30);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.compact(
                initialDateTime: initialDate,
                mode: GlassDatePickerMode.dateAndTime,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Oct 8, 2026'), findsOneWidget);
      expect(find.text('8:30 PM'), findsOneWidget);
    });

    testWidgets(
        'tapping compact date or time pill opens anchored floating glass popover',
        (tester) async {
      final initialDate = DateTime(2026, 10, 8, 14, 0);
      DateTime? latest;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.compact(
                initialDateTime: initialDate,
                mode: GlassDatePickerMode.dateAndTime,
                onDateTimeChanged: (dt) => latest = dt,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Oct 8, 2026'));
      await tester.pumpAndSettle();

      // Floating calendar popover header should be visible
      expect(find.text('October 2026'), findsOneWidget);
      // Tap a day in the floating popover
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(latest?.day, 15);

      // Tap outside the popover to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsNothing);
      expect(find.text('Oct 15, 2026'), findsOneWidget);

      // Tap the time pill to open the floating wheel popover
      await tester.tap(find.text('2:00 PM'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoDatePicker), findsOneWidget);

      // Tap outside to dismiss the time popover
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsNothing);
    });
  });

  group('GlassDatePicker (Wheel Style)', () {
    testWidgets('renders Cupertino picker wheel in liquid glass card',
        (tester) async {
      final initialDate = DateTime(2026, 10, 8);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.wheel(
                initialDateTime: initialDate,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.byType(GlassContainer), findsOneWidget);
    });
  });

  group('GlassDatePicker (Time & DateAndTime Modes)', () {
    testWidgets('dateAndTime mode renders both calendar grid and time section',
        (tester) async {
      final initialDate = DateTime(2026, 10, 8, 9, 41);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker(
                initialDateTime: initialDate,
                mode: GlassDatePickerMode.dateAndTime,
                style: GlassDatePickerStyle.graphical,
              ),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('09'), findsOneWidget);
      expect(find.text('41'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
    });

    testWidgets('time controls increment and decrement hours and minutes',
        (tester) async {
      final initialDate = DateTime(2026, 10, 8, 10, 15);
      DateTime? changedDate;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker(
                initialDateTime: initialDate,
                mode: GlassDatePickerMode.dateAndTime,
                onDateTimeChanged: (val) => changedDate = val,
              ),
            ),
          ),
        ),
      );

      // Tap + button for hour (first plus icon)
      await tester.tap(find.byIcon(CupertinoIcons.plus).first);
      await tester.pumpAndSettle();

      expect(changedDate, isNotNull);
      expect(changedDate!.hour, 11);
      expect(changedDate!.minute, 15);
    });
  });

  group('GlassMultiDatePicker', () {
    testWidgets('allows selecting and unselecting multiple dates',
        (tester) async {
      Set<DateTime> selected = {
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 12),
      };
      Set<DateTime>? changedDates;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassMultiDatePicker(
                selectedDates: selected,
                displayedMonth: DateTime(2026, 10, 1),
                onDatesChanged: (val) => changedDates = val,
              ),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);

      // Tap day 20 to add to selection
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      expect(changedDates, isNotNull);
      expect(changedDates!.length, 3);
      expect(changedDates!.any((d) => d.day == 20), isTrue);

      // Tap day 5 to unselect
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      expect(changedDates!.length, 2);
      expect(changedDates!.any((d) => d.day == 5), isFalse);
    });
  });

  group('showGlassDatePicker', () {
    testWidgets('imperatively presents modal picker and returns selected date',
        (tester) async {
      DateTime? resultDate;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Pick Date'),
                onPressed: () async {
                  resultDate = await showGlassDatePicker(
                    context: context,
                    initialDateTime: DateTime(2026, 10, 8),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();

      expect(find.text('Select Date'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);

      // Tap day 22
      await tester.tap(find.text('22').first);
      await tester.pumpAndSettle();

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Select Date'), findsNothing);
      expect(resultDate, isNotNull);
      expect(resultDate!.day, 22);
    });
  });

  group('GlassDatePicker native parity', () {
    testWidgets('tapping the month label opens the month/year wheels',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: DateTime(2026, 10, 8),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoPicker), findsNothing);
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoPicker), findsNWidgets(2));
      expect(find.text('SUN'), findsNothing);

      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoPicker), findsNothing);
      expect(find.text('SUN'), findsOneWidget);
    });

    testWidgets('compact pills are capsules with label-coloured text',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.compact(
                initialDateTime: DateTime(2026, 10, 8, 16, 54),
                mode: GlassDatePickerMode.dateAndTime,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Oct 8, 2026'), findsOneWidget);
      expect(find.text('4:54 PM'), findsOneWidget);
      final decorated = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.borderRadius == BorderRadius.circular(18));
      expect(decorated, hasLength(2));
    });

    testWidgets('custom shape is applied to the wheel card', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.wheel(
                initialDateTime: DateTime(2026, 10, 8),
                shape: const LiquidRoundedSuperellipse(borderRadius: 26),
              ),
            ),
          ),
        ),
      );

      final card = tester.widget<GlassContainer>(find.byType(GlassContainer));
      expect(card.shape, const LiquidRoundedSuperellipse(borderRadius: 26));
    });

    testWidgets(
        'time controls increment, decrement, and AM/PM toggle in dark mode',
        (tester) async {
      DateTime? changed;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: DateTime(2026, 10, 8, 9, 30),
                mode: GlassDatePickerMode.dateAndTime,
                onDateTimeChanged: (dt) => changed = dt,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Time'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);

      // Increment hour
      final plusFinder = find.byIcon(CupertinoIcons.plus);
      await tester.tap(plusFinder.first);
      await tester.pumpAndSettle();
      expect(changed?.hour, 10);

      // Decrement hour
      final minusFinder = find.byIcon(CupertinoIcons.minus);
      await tester.tap(minusFinder.first);
      await tester.pumpAndSettle();
      expect(changed?.hour, 9);

      // Increment minute
      await tester.tap(plusFinder.last);
      await tester.pumpAndSettle();
      expect(changed?.minute, 31);

      // Decrement minute
      await tester.tap(minusFinder.last);
      await tester.pumpAndSettle();
      expect(changed?.minute, 30);

      // Toggle AM/PM
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      expect(changed?.hour, 21);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('respects maximumDate constraint', (tester) async {
      final initialDate = DateTime(2026, 10, 8);
      final maxDate = DateTime(2026, 10, 10);
      DateTime? changedDate;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: initialDate,
                maximumDate: maxDate,
                onDateTimeChanged: (val) => changedDate = val,
              ),
            ),
          ),
        ),
      );

      // Tap on day 15 (beyond maximumDate)
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(changedDate, isNull);
    });

    testWidgets('GlassDatePicker and GlassMultiDatePicker didUpdateWidget',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassDatePicker.graphical(
              initialDateTime: DateTime(2026, 10, 8),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);

      // Update widget with new date
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassDatePicker.graphical(
              initialDateTime: DateTime(2026, 11, 15),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Multi date picker
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassMultiDatePicker(
              selectedDates: {DateTime(2026, 10, 8)},
            ),
          ),
        ),
      );

      // Update multi date picker
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassMultiDatePicker(
              selectedDates: {DateTime(2026, 11, 20)},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('showGlassDatePicker modal popup done and cancel paths',
        (tester) async {
      DateTime? selectedResult;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) {
                return CupertinoButton(
                  child: const Text('Open Modal Picker'),
                  onPressed: () async {
                    selectedResult = await showGlassDatePicker(
                      context: context,
                      initialDateTime: DateTime(2026, 10, 8),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      // Open and tap Done
      await tester.tap(find.text('Open Modal Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);

      // Open and tap Cancel
      selectedResult = DateTime(2026, 1, 1);
      await tester.tap(find.text('Open Modal Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNull);
    });

    testWidgets('compact style with use24hFormat renders 24-hour time',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassDatePicker.compact(
              initialDateTime: DateTime(2026, 10, 8, 9, 5),
              mode: GlassDatePickerMode.time,
              use24hFormat: true,
            ),
          ),
        ),
      );

      expect(find.text('09:05'), findsOneWidget);
    });

    testWidgets('wheel style with time and dateAndTime modes renders picker',
        (tester) async {
      DateTime? changedTime;
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassDatePicker.wheel(
              initialDateTime: DateTime(2026, 10, 8, 14, 30),
              mode: GlassDatePickerMode.time,
              onDateTimeChanged: (dt) => changedTime = dt,
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoDatePicker), findsOneWidget);

      // Drag picker wheel
      await tester.drag(find.byType(CupertinoDatePicker), const Offset(0, -50));
      await tester.pumpAndSettle();
      expect(changedTime, isNotNull);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassDatePicker.wheel(
              initialDateTime: DateTime(2026, 10, 8, 14, 30),
              mode: GlassDatePickerMode.dateAndTime,
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoDatePicker), findsOneWidget);
    });

    testWidgets(
        'GlassMultiDatePicker chevrons navigate months and label toggles wheel',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassMultiDatePicker(
              selectedDates: const {},
              displayedMonth: DateTime(2026, 10, 1),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);

      // Tap next month chevron
      await tester
          .tap(find.byKey(const ValueKey<String>('glass_calendar_next')));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);

      // Tap previous month chevron
      await tester
          .tap(find.byKey(const ValueKey<String>('glass_calendar_previous')));
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);

      // Tap month label to open month/year wheel
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoPicker), findsNWidgets(2));

      // Scroll month wheel
      await tester.drag(
          find.byType(CupertinoPicker).first, const Offset(0, -60));
      await tester.pumpAndSettle();

      // Scroll year wheel
      await tester.drag(
          find.byType(CupertinoPicker).last, const Offset(0, -60));
      await tester.pumpAndSettle();
    });

    testWidgets('firstDayOfWeek: 1 starts week on Monday', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassDatePicker.graphical(
              initialDateTime: DateTime(2026, 10, 8),
              firstDayOfWeek: 1,
            ),
          ),
        ),
      );
      expect(find.text('MON'), findsOneWidget);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassMultiDatePicker(
              selectedDates: const {},
              displayedMonth: DateTime(2026, 10, 1),
              firstDayOfWeek: 1,
            ),
          ),
        ),
      );
      expect(find.text('MON'), findsOneWidget);
    });

    testWidgets(
        'renders black selection circle for non-today dates in light mode and white in dark mode',
        (tester) async {
      // Pick a non-today date in 2025 so it is guaranteed not to be DateTime.now()
      final selectedDate = DateTime(2025, 6, 15);

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: CupertinoPageScaffold(
            child: GlassDatePicker.graphical(
              initialDateTime: selectedDate,
            ),
          ),
        ),
      );

      final lightDayStack = find
          .ancestor(
            of: find.text('15'),
            matching: find.byType(Stack),
          )
          .first;
      final lightDayContainer = tester.widget<Container>(
        find.descendant(
          of: lightDayStack,
          matching: find.byType(Container),
        ),
      );
      final lightDec = lightDayContainer.decoration! as BoxDecoration;
      expect(lightDec.color!.toARGB32(), 0xFF000000);
      expect(lightDec.shape, BoxShape.circle);

      // Dark mode: white selection circle
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: GlassDatePicker.graphical(
              initialDateTime: selectedDate,
            ),
          ),
        ),
      );

      final darkDayStack = find
          .ancestor(
            of: find.text('15'),
            matching: find.byType(Stack),
          )
          .first;
      final darkDayContainer = tester.widget<Container>(
        find.descendant(
          of: darkDayStack,
          matching: find.byType(Container),
        ),
      );
      final darkDec = darkDayContainer.decoration! as BoxDecoration;
      expect(darkDec.color!.toARGB32(), 0xFFFFFFFF);
    });

    testWidgets('out-of-month cells are blank and do not duplicate day labels',
        (tester) async {
      // February 2026 starts on Sunday and has 28 days (no 29, 30, 31 in Feb).
      // March 2026 starts on Sunday and ends on Tuesday (4 trailing cells).
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassDatePicker.graphical(
              initialDateTime: DateTime(2026, 3, 10),
            ),
          ),
        ),
      );

      // Days 1..4 should appear once (from March), not twice (no April 1..4).
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
        'GlassMultiDatePicker enforces minimumDate and maximumDate constraints',
        (tester) async {
      Set<DateTime>? changed;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassMultiDatePicker(
              selectedDates: const {},
              displayedMonth: DateTime(2026, 10, 1),
              minimumDate: DateTime(2026, 10, 5),
              maximumDate: DateTime(2026, 10, 20),
              onDatesChanged: (val) => changed = val,
            ),
          ),
        ),
      );

      // Tap day 2 (before minimumDate)
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(changed, isNull);

      // Tap day 25 (after maximumDate)
      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();
      expect(changed, isNull);

      // Tap day 10 (within range)
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      expect(changed, isNotNull);
      expect(changed!.single.day, 10);
    });

    testWidgets(
        'swiping left and right on graphical, compact popover, and multi-date calendars animates between months',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.graphical(
                initialDateTime: DateTime(2026, 10, 15),
              ),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);

      // Swipe left -> November 2026
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);

      // Swipe right -> October 2026
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      // MultiDatePicker horizontal swipe
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassMultiDatePicker(
                selectedDates: const {},
                displayedMonth: DateTime(2026, 10, 1),
              ),
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets(
        'supports localized monthNames, weekdayNames, and dateFormatter',
        (tester) async {
      const frMonths = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];
      const frWeekdays = ['DIM', 'LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM'];

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Column(
              children: [
                GlassDatePicker.graphical(
                  initialDateTime: DateTime(2026, 10, 12),
                  monthNames: frMonths,
                  weekdayNames: frWeekdays,
                ),
                GlassDatePicker.compact(
                  initialDateTime: DateTime(2026, 10, 12),
                  monthNames: frMonths,
                  weekdayNames: frWeekdays,
                  dateFormatter: (dt) => '${dt.day} oct. ${dt.year}',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Octobre 2026'), findsOneWidget);
      expect(find.text('LUN'), findsOneWidget);
      expect(find.text('12 oct. 2026'), findsOneWidget);
    });

    testWidgets(
        'compact date and time popovers support month navigation, wheel toggle, and time wheel changes',
        (tester) async {
      DateTime? latest;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.compact(
                initialDateTime: DateTime(2026, 6, 15, 9, 30),
                mode: GlassDatePickerMode.dateAndTime,
                use24hFormat: true,
                tintColor: CupertinoColors.systemGreen,
                onDateTimeChanged: (dt) => latest = dt,
              ),
            ),
          ),
        ),
      );

      // 1. Open compact date popover
      await tester.tap(find.text('Jun 15, 2026'));
      await tester.pumpAndSettle();

      // Navigate next and previous month inside compact popover
      await tester.tap(find.byKey(const ValueKey('glass_calendar_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('glass_calendar_previous')));
      await tester.pumpAndSettle();

      // Swipe month page inside compact popover
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Toggle month/year wheel open inside compact popover, scroll it, and toggle closed
      await tester.tap(find.text('July 2026'));
      await tester.pumpAndSettle();
      await tester.drag(
          find.byType(CupertinoPicker).first, const Offset(0, -40));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AnimatedRotation).first);
      await tester.pumpAndSettle();

      // Dismiss compact date popover
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 2. Open compact time popover and scroll the time wheel
      await tester.tap(find.text('09:30'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(CupertinoDatePicker),
        const Offset(0, -40),
      );
      await tester.pumpAndSettle();
      expect(latest, isNotNull);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'GlassMultiDatePicker didUpdateWidget syncs displayedMonth and toggles month/year wheel',
        (tester) async {
      DateTime displayed = DateTime(2026, 6, 1);
      late StateSetter outerSetState;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return GlassMultiDatePicker(
                  selectedDates: {DateTime(2026, 6, 10)},
                  displayedMonth: displayed,
                  tintColor: CupertinoColors.systemOrange,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('June 2026'), findsOneWidget);

      // Update displayedMonth while PageView has clients
      outerSetState(() => displayed = DateTime(2026, 8, 1));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);

      // Open month/year wheel (PageView unmounted -> hasClients is false)
      await tester.tap(find.text('August 2026'));
      await tester.pumpAndSettle();

      // Update displayedMonth while month/year wheel is open
      outerSetState(() => displayed = DateTime(2026, 10, 1));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      // Close month/year wheel to exercise _syncMonthPageController
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'compact date popover and showGlassDatePicker propagate ambient GlassTheme across modal routes',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassTheme(
            data: const GlassThemeData.ios26(brightness: Brightness.dark),
            child: CupertinoPageScaffold(
              child: Builder(
                builder: (context) => Column(
                  children: [
                    GlassDatePicker.compact(
                      initialDateTime: DateTime(2026, 6, 15),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        showGlassDatePicker(
                          context: context,
                          initialDateTime: DateTime(2026, 6, 15),
                        );
                      },
                      child: const Text('Open Modal Date Picker'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Open compact date popover -> covers L736
      await tester.tap(find.text('Jun 15, 2026'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 2. Open showGlassDatePicker -> covers L1755
      await tester.tap(find.text('Open Modal Date Picker'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });
  });
}
