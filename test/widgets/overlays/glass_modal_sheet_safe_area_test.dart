import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassModalSheet safe area', () {
    testWidgets('removes the screen top inset but keeps the bottom inset',
        (tester) async {
      late EdgeInsets contentPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.fromLTRB(11, 47, 13, 34),
          Stack(
            children: [
              GlassModalSheet(
                showDragIndicator: true,
                dragIndicatorTopPadding: 5,
                dragIndicatorHeight: 5,
                child: Builder(
                  builder: (context) {
                    contentPadding = MediaQuery.paddingOf(context);
                    return ListView(
                      children: const [SizedBox(height: 20)],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(contentPadding.left, 11);
      expect(contentPadding.right, 13);
      expect(contentPadding.top, 0,
          reason: 'the sheet removes the screen top inset and owns no fixed '
              'top safe area');
      expect(contentPadding.bottom, 34,
          reason: 'the large detent sinks behind the home indicator, so its '
              'content must retain the bottom safe area');
    });

    testWidgets('removes the top inset without a drag indicator',
        (tester) async {
      late EdgeInsets contentPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 47, bottom: 34),
          Stack(
            children: [
              GlassModalSheet(
                showDragIndicator: false,
                child: Builder(
                  builder: (context) {
                    contentPadding = MediaQuery.paddingOf(context);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(contentPadding.top, 0);
      expect(contentPadding.bottom, 34);
    });
  });
}

Widget _testAppWithPadding(EdgeInsets padding, Widget child) {
  return createTestApp(
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: padding),
        child: child,
      ),
    ),
  );
}
