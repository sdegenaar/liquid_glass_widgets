import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The switch draws a 58 x 26 pt track, but a finger, VoiceOver, Voice
/// Control and Switch Control need a 44 x 44 pt target (Apple's minimum).
/// The semantics node grows around the track without changing the layout,
/// and the touch area as far as the parent's bounds allow.
void main() {
  Widget host(Widget child) => CupertinoApp(
        home: CupertinoPageScaffold(child: Center(child: child)),
      );

  group('GlassSwitch tap target', () {
    testWidgets('keeps its 58 x 26 layout size', (tester) async {
      await tester
          .pumpWidget(host(GlassSwitch(value: false, onChanged: (_) {})));

      expect(tester.getSize(find.byType(GlassSwitch)), const Size(58, 26));
    });

    testWidgets('meets the 44 pt minimum tap target', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(GlassSwitch(
        value: false,
        onChanged: (_) {},
        semanticLabel: 'Wi-Fi',
      )));

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('a tap just above or below the track toggles it',
        (tester) async {
      var value = false;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => GlassSwitch(
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      )));
      final center = tester.getCenter(find.byType(GlassSwitch));

      // The track spans 13 pt above and below its centre; the target, 22.
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

    testWidgets('a drag that starts beside the track moves the thumb',
        (tester) async {
      var value = false;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => GlassSwitch(
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      )));
      final rect = tester.getRect(find.byType(GlassSwitch));

      final gesture =
          await tester.startGesture(rect.centerLeft + const Offset(14, -18));
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(5, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets(
        'as a GlassListTile trailing, the node is 44 pt and taps toggle '
        'within the row that holds it', (tester) async {
      final handle = tester.ensureSemantics();
      var value = false;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => GlassListTile(
          title: const Text('Wi-Fi'),
          trailing: GlassSwitch(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      )));
      final center = tester.getCenter(find.byType(GlassSwitch));
      final row = tester.getRect(find
          .ancestor(of: find.byType(GlassSwitch), matching: find.byType(Row))
          .first);

      expect(
        tester.getSemantics(find.byType(GlassSwitch)).rect.size,
        const Size(58, 44),
      );

      // The row the tile puts its trailing widget in is as tall as the
      // track, and a hit test stops at it.
      await tester.tapAt(Offset(center.dx, row.top + 1));
      await tester.pumpAndSettle();
      expect(value, isTrue);

      await tester.tapAt(Offset(center.dx, row.bottom - 1));
      await tester.pumpAndSettle();
      expect(value, isFalse);

      await tester.tapAt(Offset(center.dx, row.top - 5));
      await tester.pumpAndSettle();
      expect(value, isFalse, reason: 'inside the 44 pt node, outside the row');
      handle.dispose();
    });

    testWidgets('a larger switch keeps its own size as its target',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(GlassSwitch(
        value: false,
        onChanged: (_) {},
        semanticLabel: 'Wi-Fi',
        width: 80,
        height: 50,
      )));

      expect(tester.getSize(find.byType(GlassSwitch)), const Size(80, 50));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Wi-Fi')).rect.size,
        const Size(80, 50),
      );
      handle.dispose();
    });
  });
}
