// A `morphFrom` sheet that was dragged past the frame it rested in when the
// morph ended still takes touches there.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  const bodyKey = Key('body');

  setUp(() => GlassModalSheet.debugMorphSupportsBlending = true);
  tearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);

  /// A `morphFrom` sheet opened at half and dragged to full, so its upper part
  /// lies above the frame it rested in when the morph ended.
  Future<ValueNotifier<bool>> pumpExpanded(
    WidgetTester tester, {
    required VoidCallback onBodyTap,
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final closed = ValueNotifier(false);
    addTearDown(closed.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: GlassMorphTrigger(
              builder: (context, anchor) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => GlassModalSheet.show<void>(
                  context: context,
                  morphFrom: anchor,
                  halfSize: 0.7,
                  builder: (_) => GestureDetector(
                    onTap: onBodyTap,
                    child: const ColoredBox(
                      key: bodyKey,
                      color: Color(0xFF000000),
                      child: SizedBox(width: 300, height: 300),
                    ),
                  ),
                ).then((_) => closed.value = true),
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GlassMorphTrigger));
    await tester.pumpAndSettle();

    await tester.dragFrom(
      tester.getCenter(find.byKey(bodyKey)),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    return closed;
  }

  testWidgets('a tap above the half-height frame reaches the expanded sheet', (
    tester,
  ) async {
    var taps = 0;
    final closed = await pumpExpanded(tester, onBodyTap: () => taps++);

    // Above where the sheet's top edge sits at half: 30 % of 874.
    await tester.tapAt(
      tester.getTopLeft(find.byKey(bodyKey)) + const Offset(100, 60),
    );
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(closed.value, isFalse);
  });

  testWidgets('a drag above the half-height frame moves the expanded sheet', (
    tester,
  ) async {
    await pumpExpanded(tester, onBodyTap: () {});
    final full = tester.getTopLeft(find.byKey(bodyKey)).dy;

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byKey(bodyKey)) + const Offset(100, 60),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.getTopLeft(find.byKey(bodyKey)).dy, greaterThan(full + 50));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the grabber of the expanded sheet drags it', (tester) async {
    await pumpExpanded(tester, onBodyTap: () {});
    final full = tester.getTopLeft(find.byKey(bodyKey)).dy;

    // The grabber's row: the sheet's top 44 pt, which the body starts under.
    final gesture = await tester.startGesture(Offset(200, full + 10));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.getTopLeft(find.byKey(bodyKey)).dy, greaterThan(full + 50));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
