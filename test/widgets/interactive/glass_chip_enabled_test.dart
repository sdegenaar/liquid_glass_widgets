// GlassChip is deprecated (use GlassToggle.button) but stays covered here
// until its removal in 2.0.0.
// ignore_for_file: deprecated_member_use_from_same_package
// A chip without a handler is drawn disabled by default (retaining disabled
// button semantics); `enabled: true` draws it at full strength as static text.
// `enabled: false` disables chips even when handlers are provided, across both
// glass and solid surface styles.
import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> _pump(WidgetTester t, Widget child) => t.pumpWidget(
      CupertinoApp(home: Center(child: child)),
    );

void main() {
  testWidgets('enabled follows the handlers unless given', (t) async {
    await _pump(t, const GlassChip(label: 'Info'));
    expect(t.widget<GlassButton>(find.byType(GlassButton)).enabled, isFalse);
    expect(
      t.widget<GlassButton>(find.byType(GlassButton)).isStationary,
      isTrue,
    );

    await _pump(t, const GlassChip(label: 'Info', enabled: true));
    expect(t.widget<GlassButton>(find.byType(GlassButton)).enabled, isTrue);
    expect(
      t.widget<GlassButton>(find.byType(GlassButton)).isStationary,
      isTrue,
    );

    await _pump(t, GlassChip(label: 'Tap', onTap: () {}));
    expect(t.widget<GlassButton>(find.byType(GlassButton)).enabled, isTrue);
    expect(
      t.widget<GlassButton>(find.byType(GlassButton)).isStationary,
      isFalse,
    );
  });

  testWidgets(
      'informational chip is static text with no button or not-selected state',
      (t) async {
    final handle = t.ensureSemantics();
    try {
      await _pump(t, const GlassChip(label: 'Info', enabled: true));
      final data =
          t.getSemantics(find.bySemanticsLabel('Info')).getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isEnabled, Tristate.none);
      expect(data.flagsCollection.isSelected, Tristate.none);
      expect(data.hasAction(SemanticsAction.tap), isFalse);

      // Selected informational chip announces selected without button state.
      await _pump(
        t,
        const GlassChip(label: 'Active', enabled: true, selected: true),
      );
      final selectedData =
          t.getSemantics(find.bySemanticsLabel('Active')).getSemanticsData();
      expect(selectedData.flagsCollection.isButton, isFalse);
      expect(selectedData.flagsCollection.isSelected, Tristate.isTrue);

      // Interactive chip keeps button + tap action and omits not-selected.
      await _pump(t, GlassChip(label: 'Tap', onTap: () {}));
      final tapData =
          t.getSemantics(find.bySemanticsLabel('Tap')).getSemanticsData();
      expect(tapData.flagsCollection.isButton, isTrue);
      expect(tapData.flagsCollection.isSelected, Tristate.none);
      expect(tapData.hasAction(SemanticsAction.tap), isTrue);

      // Selected interactive chip announces selected.
      await _pump(t, GlassChip(label: 'Filter', selected: true, onTap: () {}));
      final filterData =
          t.getSemantics(find.bySemanticsLabel('Filter')).getSemanticsData();
      expect(filterData.flagsCollection.isButton, isTrue);
      expect(filterData.flagsCollection.isSelected, Tristate.isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('disabled chip keeps disabled button semantics and blocks input',
      (t) async {
    final handle = t.ensureSemantics();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var tapped = 0;
    var deleted = 0;

    try {
      // Default handler-less chip (enabled: null) is a disabled button.
      await _pump(t, const GlassChip(label: 'Unavailable'));
      final defaultDisabled = t
          .getSemantics(find.bySemanticsLabel('Unavailable'))
          .getSemanticsData();
      expect(defaultDisabled.flagsCollection.isButton, isTrue);
      expect(defaultDisabled.flagsCollection.isEnabled, Tristate.isFalse);
      expect(defaultDisabled.flagsCollection.isSelected, Tristate.none);

      // Explicit enabled: false blocks both onTap and onDeleted and focus.
      await _pump(
        t,
        GlassChip(
          label: 'Locked',
          enabled: false,
          focusNode: focusNode,
          onTap: () => tapped++,
          onDeleted: () => deleted++,
        ),
      );
      expect(t.widget<GlassButton>(find.byType(GlassButton)).enabled, isFalse);
      final lockedData =
          t.getSemantics(find.bySemanticsLabel('Locked')).getSemanticsData();
      expect(lockedData.flagsCollection.isButton, isTrue);
      expect(lockedData.flagsCollection.isEnabled, Tristate.isFalse);

      await t.tap(find.text('Locked'), warnIfMissed: false);
      await t.tap(
        find.byIcon(CupertinoIcons.xmark_circle_fill),
        warnIfMissed: false,
      );
      focusNode.requestFocus();
      await t.pump();
      expect(tapped, 0);
      expect(deleted, 0);
      expect(focusNode.hasFocus, isFalse);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('GlassSurfaceStyle.solid honors enabled: true, false, and null',
      (t) async {
    final handle = t.ensureSemantics();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var tapped = 0;
    var deleted = 0;

    try {
      // Informational solid chip: full strength, static text, not dimmed.
      await _pump(
        t,
        const GlassChip(
          label: 'Solid Info',
          surfaceStyle: GlassSurfaceStyle.solid,
          enabled: true,
        ),
      );
      expect(
        find.descendant(
          of: find.byType(GlassChip),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      final infoData = t
          .getSemantics(find.bySemanticsLabel('Solid Info'))
          .getSemanticsData();
      expect(infoData.flagsCollection.isButton, isFalse);
      expect(infoData.flagsCollection.isEnabled, Tristate.none);
      expect(infoData.flagsCollection.isSelected, Tristate.none);

      // Disabled solid chip (explicit enabled: false with handlers):
      // 50% opacity, blocks tap/delete/keyboard, disabled button semantics.
      await _pump(
        t,
        GlassChip(
          label: 'Solid Disabled',
          surfaceStyle: GlassSurfaceStyle.solid,
          enabled: false,
          focusNode: focusNode,
          onTap: () => tapped++,
          onDeleted: () => deleted++,
        ),
      );
      final opacity = t.widget<Opacity>(
        find.descendant(
          of: find.byType(GlassChip),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.5);
      final disabledData = t
          .getSemantics(find.bySemanticsLabel('Solid Disabled'))
          .getSemanticsData();
      expect(disabledData.flagsCollection.isButton, isTrue);
      expect(disabledData.flagsCollection.isEnabled, Tristate.isFalse);

      await t.tap(find.text('Solid Disabled'), warnIfMissed: false);
      await t.tap(
        find.byIcon(CupertinoIcons.xmark_circle_fill),
        warnIfMissed: false,
      );
      focusNode.requestFocus();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(tapped, 0);
      expect(deleted, 0);
      expect(focusNode.hasFocus, isFalse);

      // Inherited solid surface inside GlassContainer.card honors enabled too.
      await _pump(
        t,
        GlassContainer.card(
          surfaceStyle: GlassSurfaceStyle.solid,
          child: const GlassChip(label: 'Inherited Tag', enabled: true),
        ),
      );
      final inheritedData = t
          .getSemantics(find.bySemanticsLabel('Inherited Tag'))
          .getSemanticsData();
      expect(inheritedData.flagsCollection.isButton, isFalse);
      expect(inheritedData.flagsCollection.isEnabled, Tristate.none);
    } finally {
      handle.dispose();
    }
  });
}
