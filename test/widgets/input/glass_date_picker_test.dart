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

    testWidgets('tapping compact date pill opens popup sheet', (tester) async {
      final initialDate = DateTime(2026, 10, 8, 14, 0);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassDatePicker.compact(
                initialDateTime: initialDate,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Oct 8, 2026'));
      await tester.pumpAndSettle();

      // Popup header should be visible
      expect(find.text('Select Date'), findsOneWidget);
      // Tap a day in the popup sheet
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      // Tap Cancel to close
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Select Date'), findsNothing);
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
          .where((d) => d.borderRadius == BorderRadius.circular(17.5));
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
  });
}
