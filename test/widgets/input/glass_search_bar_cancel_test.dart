// `cancelButtonAlwaysVisible` keeps the cancel button whatever the focus, and
// both flags apply after mount too.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Widget _bar({
  required bool shows,
  required bool always,
  FocusNode? focus,
  TextEditingController? controller,
  VoidCallback? onCancel,
  bool enabled = true,
}) =>
    CupertinoApp(
      home: Center(
        child: GlassSearchBar(
          showsCancelButton: shows,
          cancelButtonAlwaysVisible: always,
          focusNode: focus,
          controller: controller,
          onCancel: onCancel,
          enabled: enabled,
        ),
      ),
    );

Finder get _cancel => find.byIcon(CupertinoIcons.xmark);

void main() {
  testWidgets('always visible: shown without focus', (tester) async {
    await tester.pumpWidget(_bar(shows: true, always: true));
    expect(_cancel, findsOneWidget);
  });

  testWidgets('default: shown only while focused', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(_bar(shows: true, always: false, focus: focus));
    expect(_cancel, findsNothing);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(_cancel, findsOneWidget);
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(_cancel, findsNothing);
  });

  testWidgets('changing the flags after mount applies', (tester) async {
    await tester.pumpWidget(_bar(shows: true, always: false));
    expect(_cancel, findsNothing);
    await tester.pumpWidget(_bar(shows: true, always: true));
    await tester.pumpAndSettle();
    expect(_cancel, findsOneWidget);
    await tester.pumpWidget(_bar(shows: false, always: true));
    await tester.pumpAndSettle();
    expect(_cancel, findsNothing);
  });

  testWidgets('always visible: stays visible across focus/unfocus and cancels',
      (tester) async {
    final focus = FocusNode();
    final controller = TextEditingController(text: 'glass');
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    var cancelCount = 0;

    await tester.pumpWidget(
      _bar(
        shows: true,
        always: true,
        focus: focus,
        controller: controller,
        onCancel: () => cancelCount++,
      ),
    );

    focus.requestFocus();
    await tester.pumpAndSettle();
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(_cancel, findsOneWidget);

    // Tapping cancel while unfocused still clears text and fires onCancel.
    await tester.tap(_cancel);
    await tester.pumpAndSettle();
    expect(cancelCount, 1);
    expect(controller.text, isEmpty);
  });

  testWidgets('changing flags while focused updates cancel visibility',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(_bar(shows: false, always: false, focus: focus));
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(_cancel, findsNothing);

    await tester.pumpWidget(_bar(shows: true, always: true, focus: focus));
    await tester.pumpAndSettle();
    expect(_cancel, findsOneWidget);

    await tester.pumpWidget(_bar(shows: true, always: false, focus: focus));
    await tester.pumpAndSettle();
    expect(_cancel, findsOneWidget);

    focus.unfocus();
    await tester.pumpAndSettle();
    expect(_cancel, findsNothing);
  });

  testWidgets('enabled: false disables the always-visible cancel button',
      (tester) async {
    final controller = TextEditingController(text: 'locked');
    addTearDown(controller.dispose);
    var cancelCount = 0;

    await tester.pumpWidget(
      _bar(
        shows: true,
        always: true,
        controller: controller,
        enabled: false,
        onCancel: () => cancelCount++,
      ),
    );

    final cancelButton = tester.widget<GlassButton>(find.byType(GlassButton));
    expect(cancelButton.enabled, isFalse);

    await tester.tap(_cancel, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(cancelCount, 0);
    expect(controller.text, 'locked');
  });
}
