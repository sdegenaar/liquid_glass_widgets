import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// What a screen reader gets from a [GlassSwitch].
///
/// - macOS gives `button` its role before switch, and writes an on/off value
///   only for the switch, radio button and check box roles, so a switch that
///   is also a button reads as "button" with no state there.
/// - VoiceOver and TalkBack already say "switch"; a default name in English
///   repeats it and is never localized.
void main() {
  Widget host(Widget child) => CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(child: SizedBox(width: 340, child: child)),
        ),
      );

  /// The nodes a screen reader can activate; a node merged into its parent
  /// is not one of them.
  Iterable<SemanticsNode> actionable() => find.semantics
      .byPredicate((node) =>
          !node.isMergedIntoParent &&
          node.getSemanticsData().hasAction(SemanticsAction.tap))
      .evaluate();

  group('GlassSwitch semantics', () {
    testWidgets('is a switch with its state, not a button', (tester) async {
      final handle = tester.ensureSemantics();
      for (final value in [true, false]) {
        await tester.pumpWidget(host(GlassSwitch(
          value: value,
          onChanged: (_) {},
          semanticLabel: 'Wi-Fi',
        )));

        final data = tester
            .getSemantics(find.bySemanticsLabel('Wi-Fi'))
            .getSemanticsData();
        expect(data.flagsCollection.isButton, isFalse,
            reason: 'macOS would read a button with no on/off state');
        expect(data.flagsCollection.isToggled,
            value ? Tristate.isTrue : Tristate.isFalse);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
      handle.dispose();
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('has no English default name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester
          .pumpWidget(host(GlassSwitch(value: true, onChanged: (_) {})));

      final nodes = actionable().toList();
      expect(nodes, hasLength(1));
      expect(nodes.single.getSemanticsData().label, isEmpty);
      expect(nodes.single.getSemanticsData().flagsCollection.isToggled,
          Tristate.isTrue);
      handle.dispose();
    });

    testWidgets(
        'merged into a list row, the row title names it: one element with '
        'the switch state', (tester) async {
      final handle = tester.ensureSemantics();
      var value = true;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => MergeSemantics(
          child: GlassListTile(
            title: const Text('Reminders'),
            trailing: GlassSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      )));

      final nodes = actionable().toList();
      expect(nodes, hasLength(1), reason: 'one element for the row');
      final data = nodes.single.getSemanticsData();
      expect(data.label, 'Reminders');
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isToggled, Tristate.isTrue);

      tester.semantics.performAction(
          find.semantics.byLabel('Reminders'), SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(value, isFalse);
      expect(actionable().single.getSemanticsData().flagsCollection.isToggled,
          Tristate.isFalse);
      handle.dispose();
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));
  });
}
