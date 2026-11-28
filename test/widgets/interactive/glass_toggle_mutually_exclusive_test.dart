import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A choice chip: one of 3 s, 5 s and 10 s is chosen. Each toggle reads as a
/// radio button of a mutually exclusive group, checked when chosen, in place
/// of a switch: iOS reads a toggled node outside such a group as a switch,
/// and macOS reads no state from a button. Apple platforms also read the
/// chosen one as selected, as iOS reads a radio button's selected trait.
void main() {
  const all = TargetPlatformVariant({
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.android,
  });

  bool apple() =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Widget choices({int chosen = 5, ValueChanged<(int, bool)>? onAsk}) =>
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: Wrap(spacing: 8, children: [
              for (final s in [3, 5, 10])
                GlassToggle.button(
                  value: s == chosen,
                  onChanged: (on) => onAsk?.call((s, on)),
                  label: '$s s',
                  semanticsInMutuallyExclusiveGroup: true,
                ),
            ]),
          ),
        ),
      );

  SemanticsData dataOf(WidgetTester tester, String label) =>
      tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();

  group('GlassToggle.button(semanticsInMutuallyExclusiveGroup: true)', () {
    testWidgets('reads as a radio button, checked when on', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(choices());

      for (final (label, on) in [('3 s', false), ('5 s', true)]) {
        final flags = dataOf(tester, label).flagsCollection;
        expect(flags.isButton, isFalse,
            reason: 'macOS gives button its role before radio button');
        expect(flags.isToggled, Tristate.none,
            reason: 'iOS would read a switch');
        expect(flags.isInMutuallyExclusiveGroup, isTrue);
        expect(
            flags.isChecked, on ? CheckedState.isTrue : CheckedState.isFalse);
        expect(flags.isEnabled, Tristate.isTrue);
        // iOS reads a radio button's selected trait, not its checked state.
        expect(
          flags.isSelected,
          apple() ? (on ? Tristate.isTrue : Tristate.isFalse) : Tristate.none,
        );
      }
      handle.dispose();
    }, variant: all);

    testWidgets('a tap and a screen reader tap report the opposite value',
        (tester) async {
      final handle = tester.ensureSemantics();
      final asks = <(int, bool)>[];
      await tester.pumpWidget(choices(onAsk: asks.add));

      await tester.tap(find.text('10 s'));
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel('3 s'));
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel('5 s'));
      await tester.pump();
      expect(asks, [(10, true), (3, true), (5, false)]);
      handle.dispose();
    }, variant: all);

    testWidgets('a disabled option keeps its checked state and takes no tap',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: GlassToggle.button(
              value: true,
              onChanged: null,
              label: '30 d',
              semanticsInMutuallyExclusiveGroup: true,
            ),
          ),
        ),
      ));

      final data = dataOf(tester, '30 d');
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    }, variant: all);
  });
}
