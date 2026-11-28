import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The header of a [GlassDisclosureGroup] must tell a screen reader whether
/// the group is open, and open from the keyboard.
///
/// iOS VoiceOver reads no `expanded` flag (macOS and Android do), so on iOS
/// the state is the header's value, in the app's language.
void main() {
  final opened = <bool>[];
  final rowTaps = <String>[];

  Widget disclosure() => CupertinoApp(
        home: CupertinoPageScaffold(
          child: ListView(
            children: [
              GlassDisclosureGroup(
                title: const Text('Advanced settings'),
                onExpansionChanged: opened.add,
                children: [
                  GlassListTile(
                    title: const Text('Reset statistics'),
                    onTap: () => rowTaps.add('Reset statistics'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  SemanticsData header(WidgetTester tester) => tester
      .getSemantics(find.bySemanticsLabel('Advanced settings'))
      .getSemanticsData();

  setUp(() {
    opened.clear();
    rowTaps.clear();
  });

  group('GlassDisclosureGroup header', () {
    testWidgets('on iOS reads its state as its value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(disclosure());

      var data = header(tester);
      expect(data.label, 'Advanced settings');
      expect(data.value, 'Collapsed');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.performAction(
          find.semantics.byLabel('Advanced settings'), SemanticsAction.tap);
      await tester.pumpAndSettle();
      data = header(tester);
      expect(data.value, 'Expanded');
      expect(opened, [true]);
      handle.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('elsewhere reads the expanded state and no value',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(disclosure());

      var data = header(tester);
      expect(data.value, isEmpty);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);

      tester.semantics.performAction(
          find.semantics.byLabel('Advanced settings'), SemanticsAction.tap);
      await tester.pumpAndSettle();
      data = header(tester);
      expect(data.value, isEmpty);
      expect(data.flagsCollection.isExpanded, Tristate.isTrue);
      handle.dispose();
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.macOS, TargetPlatform.android}));

    testWidgets('takes keyboard focus and opens with Space and Enter',
        (tester) async {
      await tester.pumpWidget(disclosure());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus?.context;
      expect(focused, isNotNull);
      expect(
        find.descendant(
          of: find.byType(GlassDisclosureGroup),
          matching: find.byWidget(focused!.widget),
        ),
        findsOneWidget,
        reason: 'Tab reaches the header first',
      );
      expect(
        find.ancestor(
          of: find.byWidget(focused.widget),
          matching: find.byType(GlassListTile),
        ),
        findsNothing,
        reason: 'the header, not a row inside the group',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(opened, [true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(opened, [true, false]);
      expect(rowTaps, isEmpty, reason: 'no hidden row was activated');
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('once open, Tab reaches the rows again', (tester) async {
      await tester.pumpWidget(disclosure());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(opened, [true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus?.context;
      expect(focused, isNotNull);
      expect(
        find.ancestor(
          of: find.byWidget(focused!.widget),
          matching: find.byType(GlassListTile),
        ),
        findsOneWidget,
        reason: 'the row "Reset statistics" has focus',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(rowTaps, ['Reset statistics']);
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('a custom headerBuilder on iOS reads its state as its value',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: ListView(
            children: [
              GlassDisclosureGroup(
                title: const Text('Advanced settings'),
                headerBuilder: (context, isExpanded, toggle) => GestureDetector(
                  onTap: toggle,
                  child: const Text('Advanced settings'),
                ),
                children: [
                  GlassListTile(
                    title: const Text('Reset statistics'),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ));

      var data = header(tester);
      expect(data.value, 'Collapsed');
      expect(data.flagsCollection.isButton, isTrue);

      await tester.tap(find.text('Advanced settings'));
      await tester.pumpAndSettle();
      data = header(tester);
      expect(data.value, 'Expanded');
      handle.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets(
        'with no CupertinoLocalizations in scope, iOS builds the header with '
        'no value', (tester) async {
      final handle = tester.ensureSemantics();
      // WidgetsApp provides only the widgets localizations.
      await tester.pumpWidget(WidgetsApp(
        color: const Color(0xFF007AFF),
        builder: (context, _) => ListView(
          children: const [
            GlassDisclosureGroup(
              title: Text('Advanced settings'),
              children: [Text('Reset statistics')],
            ),
          ],
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(
        Localizations.of<CupertinoLocalizations>(
            tester.element(find.byType(GlassDisclosureGroup)),
            CupertinoLocalizations),
        isNull,
      );
      final data = header(tester);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.value, isEmpty);
      handle.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
