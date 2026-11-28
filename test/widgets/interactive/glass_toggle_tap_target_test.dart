import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The toggle draws a 34 pt capsule, but a finger, VoiceOver, Voice Control
/// and Switch Control need a 44 x 44 pt target (Apple's minimum). The
/// semantics node grows around the capsule without changing the layout, and
/// the touch area as far as the parent's bounds allow.
void main() {
  const apple =
      TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.macOS});

  Widget host(Widget child) => CupertinoApp(
        home: CupertinoPageScaffold(child: Center(child: child)),
      );

  group('GlassToggle.button tap target', () {
    testWidgets('keeps its 34 pt layout height', (tester) async {
      await tester.pumpWidget(host(
          GlassToggle.button(value: false, onChanged: (_) {}, label: 'M')));

      expect(tester.getSize(find.byType(GlassToggle)).height, 34);
    });

    testWidgets('meets the 44 pt minimum tap target', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassToggle.button(value: false, onChanged: (_) {}, label: 'M'),
          const SizedBox(width: 8),
          GlassToggle.button(value: true, onChanged: (_) {}, label: 'Unread'),
          const SizedBox(width: 8),
          GlassToggle.button(
            value: false,
            onChanged: (_) {},
            icon: const Icon(CupertinoIcons.bell),
            semanticLabel: 'Alerts',
          ),
        ],
      )));

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    }, variant: apple);

    testWidgets('a tap just above or below the capsule toggles it',
        (tester) async {
      var value = false;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => GlassToggle.button(
          value: value,
          onChanged: (v) => setState(() => value = v),
          label: 'Unread',
        ),
      )));
      final center = tester.getCenter(find.byType(GlassToggle));

      // The capsule spans 17 pt above and below its centre; the target, 22.
      await tester.tapAt(center + const Offset(0, -20));
      await tester.pumpAndSettle();
      expect(value, isTrue);

      await tester.tapAt(center + const Offset(0, 20));
      await tester.pumpAndSettle();
      expect(value, isFalse);

      await tester.tapAt(center + const Offset(0, -24));
      await tester.pumpAndSettle();
      expect(value, isFalse, reason: 'outside the 44 pt target');
    });

    testWidgets('a narrow toggle takes taps beside it up to 44 pt wide',
        (tester) async {
      var value = false;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => GlassToggle.button(
          value: value,
          onChanged: (v) => setState(() => value = v),
          label: 'M',
        ),
      )));
      final rect = tester.getRect(find.byType(GlassToggle));
      expect(rect.width, lessThan(44));

      await tester.tapAt(rect.centerLeft - const Offset(1, 0));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('the touch area stops at a parent no taller than the capsule',
        (tester) async {
      var value = false;
      await tester.pumpWidget(host(SizedBox(
        height: 34,
        child: StatefulBuilder(
          builder: (context, setState) => GlassToggle.button(
            value: value,
            onChanged: (v) => setState(() => value = v),
            label: 'Unread',
          ),
        ),
      )));
      final center = tester.getCenter(find.byType(GlassToggle));

      await tester.tapAt(center + const Offset(0, -20));
      await tester.pumpAndSettle();
      expect(value, isFalse, reason: 'the hit test stops at the parent');

      await tester.tapAt(center + const Offset(0, -16));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('a toggle of 44 pt or more keeps its own size as its target',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(GlassToggle.button(
        value: false,
        onChanged: (_) {},
        label: 'Tall',
        width: 120,
        height: 50,
      )));

      final node = tester.getSemantics(find.bySemanticsLabel('Tall'));
      expect(node.rect.size, const Size(120, 50));
      handle.dispose();
    });
  });
}
