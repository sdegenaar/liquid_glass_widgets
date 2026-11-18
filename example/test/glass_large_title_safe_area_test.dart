import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets_example/apple_messages/apple_messages_demo.dart';
import 'package:liquid_glass_widgets_example/apple_mail/apple_mail_demo.dart';
import 'package:liquid_glass_widgets_example/widgets/glass_safe_area_slivers.dart';

void main() {
  testWidgets('Messages GlassLargeTitle clears the full GlassAppBar',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const CupertinoApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 59)),
          child: MessagesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final largeTitleContext = tester.element(find.byType(GlassLargeTitle));
    final bodyPadding = MediaQuery.paddingOf(largeTitleContext);
    final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
    final largeTitleText = find.descendant(
      of: find.byType(GlassLargeTitle),
      matching: find.text('Messages'),
    );
    final largeTitleTop = tester.getTopLeft(largeTitleText).dy;

    expect(bodyPadding.top, closeTo(appBarBottom, 0.5));
    expect(largeTitleTop, greaterThanOrEqualTo(appBarBottom));
  });

  testWidgets('Mailboxes GlassLargeTitle clears the full GlassAppBar',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();

    final largeTitleContext = tester.element(find.byType(GlassLargeTitle));
    final bodyPadding = MediaQuery.paddingOf(largeTitleContext);
    final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
    final largeTitleText = find.descendant(
      of: find.byType(GlassLargeTitle),
      matching: find.text('Mailboxes'),
    );
    final largeTitleTop = tester.getTopLeft(largeTitleText).dy;

    expect(bodyPadding.top, closeTo(appBarBottom, 0.5));
    expect(largeTitleTop, greaterThanOrEqualTo(appBarBottom));
  });

  testWidgets('Inbox GlassLargeTitle clears the full GlassAppBar',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Inboxes'));
    await tester.pumpAndSettle();

    final largeTitleContext = tester.element(find.byType(GlassLargeTitle));
    final bodyPadding = MediaQuery.paddingOf(largeTitleContext);
    final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
    final largeTitleText = find.descendant(
      of: find.byType(GlassLargeTitle),
      matching: find.text('Inbox'),
    );
    final largeTitleTop = tester.getTopLeft(largeTitleText).dy;

    expect(bodyPadding.top, closeTo(appBarBottom, 0.5));
    expect(largeTitleTop, greaterThanOrEqualTo(appBarBottom));
  });

  testWidgets('safe-area sliver reads GlassScaffold bar padding',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 59)),
          child: Builder(
            builder: (pageContext) => GlassScaffold(
              appBar: const GlassAppBar(
                title: Text('Title'),
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              body: CustomScrollView(
                slivers: [
                  glassTopSafeAreaSliver(),
                  const SliverToBoxAdapter(
                    child: SizedBox(key: ValueKey('first-item'), height: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('first-item'))).dy,
      closeTo(appBarBottom, 0.5),
    );
  });
}
