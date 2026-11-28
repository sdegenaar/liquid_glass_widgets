import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The switch draws a 58 x 26 pt track, but a finger, VoiceOver, Voice
/// Control and Switch Control need a 44 x 44 pt target (Apple's minimum).
/// The target grows around the track without changing the layout.
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
