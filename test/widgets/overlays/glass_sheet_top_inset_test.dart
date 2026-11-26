// GlassSheet is deprecated (use GlassModalSheet) but stays covered here
// until its removal in 2.0.0.
// ignore_for_file: deprecated_member_use_from_same_package
// A content-sized GlassSheet.show stops below the top safe area and scrolls
// its content, with or without `useSafeArea`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _viewPaddingTop = 59.0;

Future<void> _open(
  WidgetTester tester,
  double contentHeight, {
  bool useSafeArea = true,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.view.padding = const FakeViewPadding(top: _viewPaddingTop, bottom: 34);
  tester.view.viewPadding =
      const FakeViewPadding(top: _viewPaddingTop, bottom: 34);
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ),
  );
  GlassSheet.show<void>(
    context: ctx,
    quality: GlassQuality.minimal,
    useSafeArea: useSafeArea,
    builder: (_) => SizedBox(key: const Key('content'), height: contentHeight),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a short sheet keeps its natural height', (tester) async {
    await _open(tester, 100, useSafeArea: false);
    final rect = tester.getRect(find.byType(GlassSheet));
    // content + drag header + the bottom spacer + margins.
    expect(rect.height, lessThan(300));
    expect(rect.bottom, 800);
    expect(tester.takeException(), isNull);
  });

  for (final useSafeArea in [true, false]) {
    testWidgets(
        'a long sheet stops below the top inset and scrolls '
        '(useSafeArea: $useSafeArea)', (tester) async {
      await _open(tester, 3000, useSafeArea: useSafeArea);
      final rect = tester.getRect(find.byType(GlassSheet));
      expect(rect.top, greaterThanOrEqualTo(_viewPaddingTop));
      expect(tester.takeException(), isNull);
      final before = tester.getTopLeft(find.byKey(const Key('content'))).dy;
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(const Key('content'))).dy,
          lessThan(before));
    });
  }
}
