import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A row that is one choice among several (a checkmark list) must tell a
/// screen reader which row is chosen. macOS gives `button` its role before
/// radio button and reports no selected state, so the row reads as a plain
/// button there unless it is a radio button with a checked state.
void main() {
  Widget options({required bool? lightChecked, VoidCallback? onLightTap}) =>
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ListView(
            children: [
              GlassListTile(
                title: const Text('Light'),
                onTap: onLightTap ?? () {},
                semanticsChecked: lightChecked,
              ),
              GlassListTile(
                title: const Text('Dark'),
                onTap: () {},
                semanticsChecked: lightChecked == null ? null : !lightChecked,
              ),
            ],
          ),
        ),
      );

  SemanticsData row(WidgetTester tester, String title) =>
      tester.getSemantics(find.bySemanticsLabel(title)).getSemanticsData();

  group('GlassListTile.semanticsChecked', () {
    testWidgets('a checked row is a checked radio button, not a button',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(options(lightChecked: true));

      final light = row(tester, 'Light');
      expect(light.flagsCollection.isButton, isFalse);
      expect(light.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(light.flagsCollection.isChecked, CheckedState.isTrue);
      expect(light.hasAction(SemanticsAction.tap), isTrue);

      final dark = row(tester, 'Dark');
      expect(dark.flagsCollection.isButton, isFalse);
      expect(dark.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(dark.flagsCollection.isChecked, CheckedState.isFalse);
      expect(dark.hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets(
        'on Apple platforms the checked row is also selected, as Flutter '
        'radios are', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(options(lightChecked: true));

      // iOS reads no checked state from a radio button (it reads a button),
      // and announces the selected trait instead.
      expect(row(tester, 'Light').flagsCollection.isSelected, Tristate.isTrue);
      expect(row(tester, 'Dark').flagsCollection.isSelected, Tristate.isFalse);
      semantics.dispose();
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('elsewhere the checked state alone is reported',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(options(lightChecked: true));

      expect(row(tester, 'Light').flagsCollection.isSelected, Tristate.none);
      expect(row(tester, 'Dark').flagsCollection.isSelected, Tristate.none);
      semantics.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a tap still reaches onTap', (tester) async {
      var taps = 0;
      await tester
          .pumpWidget(options(lightChecked: false, onLightTap: () => taps++));

      await tester.tap(find.text('Light'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('null (the default) keeps the button', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(options(lightChecked: null));

      final light = row(tester, 'Light');
      expect(light.flagsCollection.isButton, isTrue);
      expect(light.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
      expect(light.flagsCollection.isChecked, CheckedState.none);
      expect(light.flagsCollection.isSelected, Tristate.none);
      semantics.dispose();
    });
  });
}
