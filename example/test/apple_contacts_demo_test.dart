import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets_example/apple_contacts/apple_contacts_demo.dart';

void main() {
  testWidgets('AppleContactsDemoApp mounts and displays Contacts list view',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleContactsDemoApp());
    await tester.pumpAndSettle();

    // Verify Contacts title and initial contacts
    expect(find.text('Contacts'), findsAtLeast(1));
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('My Card'), findsOneWidget);
    expect(find.text('Craig Federighi'), findsOneWidget);
    expect(find.text('Tim Cook'), findsOneWidget);
    // Lazy list: later rows are only built once scrolled into view.
    await tester.scrollUntilVisible(
      find.text('Kate Lovett'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kate Lovett'), findsOneWidget);
  });

  testWidgets(
      'Navigating to ContactDetailView displays hero avatar and detail sections',
      (tester) async {
    // Tall surface: the disclosure groups sit below the date pickers in a
    // lazily-built ListView, so make the surface tall enough to build them all.
    tester.view.physicalSize = const Size(1170, 12000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleContactsDemoApp());
    await tester.pumpAndSettle();

    // Tap Craig Federighi to navigate to detail
    await tester.tap(find.text('Craig Federighi'));
    await tester.pumpAndSettle();

    // Verify detail screen content
    expect(find.text('SVP Software Engineering · Apple Inc.'), findsOneWidget);
    expect(find.text('+1 (408) 996-1010'), findsOneWidget);
    expect(find.text('craig@apple.com'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);

    // Verify GlassDisclosureGroup headers
    expect(find.text('Emergency & Medical Details'), findsOneWidget);
    expect(find.text('Social Profiles & Handles'), findsOneWidget);
    expect(find.text('Privacy & AirDrop Sharing'), findsOneWidget);
  });

  testWidgets(
      'Tapping Edit in detail view presents ContactEditSheet via GlassFullScreenCover',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleContactsDemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Craig Federighi'));
    await tester.pumpAndSettle();

    // Tap Edit button in top bar
    await tester.tap(find.widgetWithText(CupertinoButton, 'Edit').first);
    await tester.pumpAndSettle();

    // Verify FullScreenCover modal
    expect(find.text('Edit Contact'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('BIRTHDAY & DATES'), findsOneWidget);
    expect(find.text('MILESTONES (MULTIDATE PICKER)'), findsOneWidget);

    // Tap Cancel to dismiss
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Contact'), findsNothing);
  });

  testWidgets(
      'Tapping Edit button in Contacts list view toggles edit mode and shows delete badges',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleContactsDemoApp());
    await tester.pumpAndSettle();

    // Verify GlassEditButton is present
    expect(find.byType(GlassEditButton), findsWidgets);

    // Tap GlassEditButton in pinned chrome
    await tester.tap(find.byType(GlassEditButton).last, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Now Done is shown
    expect(find.text('Done'), findsAtLeast(1));

    // Tap Done to exit edit mode
    await tester.tap(find.byType(GlassEditButton).last, warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Add contact (+) button opens New Contact sheet via GlassFullScreenCover',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleContactsDemoApp());
    await tester.pumpAndSettle();

    // Tap + button
    await tester.tap(find.byIcon(CupertinoIcons.add).first,
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('New Contact'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('New Contact'), findsNothing);
  });
}
