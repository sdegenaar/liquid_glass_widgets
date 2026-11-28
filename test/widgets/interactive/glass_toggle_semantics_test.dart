import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// What a screen reader gets from a [GlassToggle.button].
///
/// - macOS gives `button` its role before switch, radio button and check
///   box, and writes an on/off value only for those three, so a toggle that
///   is also a button reads as "button" with no state there.
/// - iOS reads a toggled or checked node outside a mutually exclusive group
///   as a switch, and a radio button's state from its selected trait.
void main() {
  const apple =
      TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.macOS});

  Widget host(Widget child) => CupertinoApp(
        home: CupertinoPageScaffold(child: Center(child: child)),
      );

  SemanticsData dataOf(WidgetTester tester, String label) =>
      tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();

  group('GlassToggle.button semantics', () {
    testWidgets('reads as a switch with its state, not a button',
        (tester) async {
      final handle = tester.ensureSemantics();
      for (final value in [true, false]) {
        await tester.pumpWidget(host(GlassToggle.button(
          value: value,
          onChanged: (_) {},
          label: 'Bold',
        )));

        final data = dataOf(tester, 'Bold');
        expect(data.flagsCollection.isButton, isFalse,
            reason: 'macOS would read a button with no on/off state');
        expect(data.flagsCollection.isToggled,
            value ? Tristate.isTrue : Tristate.isFalse);
        expect(data.flagsCollection.isChecked, CheckedState.none);
        expect(data.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
      handle.dispose();
    }, variant: apple);

    testWidgets('an icon-only toggle reads its semanticLabel as a switch',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(GlassToggle.button(
        value: true,
        onChanged: (_) {},
        icon: const Icon(CupertinoIcons.speaker_slash),
        semanticLabel: 'Mute',
      )));

      final data = dataOf(tester, 'Mute');
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      handle.dispose();
    }, variant: apple);

    testWidgets('a disabled toggle keeps its state and takes no tap',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const GlassToggle.button(
        value: true,
        onChanged: null,
        label: 'Locked',
      )));

      final data = dataOf(tester, 'Locked');
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    }, variant: apple);

    testWidgets('a screen reader tap reports the opposite value',
        (tester) async {
      final handle = tester.ensureSemantics();
      final values = <bool>[];
      await tester.pumpWidget(host(GlassToggle.button(
        value: false,
        onChanged: values.add,
        label: 'Bold',
      )));

      tester.semantics.tap(find.semantics.byLabel('Bold'));
      await tester.pump();
      expect(values, [true]);
      handle.dispose();
    }, variant: apple);
  });
}
