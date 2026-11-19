// `cancelButtonAlwaysVisible` keeps the cancel button whatever the focus, and
// both flags apply after mount too.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Widget _bar({required bool shows, required bool always, FocusNode? focus}) =>
    CupertinoApp(
      home: Center(
        child: GlassSearchBar(
          showsCancelButton: shows,
          cancelButtonAlwaysVisible: always,
          focusNode: focus,
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
}
