import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets_example/apple_mail/apple_mail_demo.dart';

void main() {
  testWidgets('AppleMailDemoApp mounts and displays Mailboxes view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();

    // Mailboxes screen title and sections should be present
    expect(find.text('Mailboxes'), findsAtLeast(1));
    expect(find.text('All Inboxes'), findsOneWidget);
    expect(find.text('iCloud'), findsOneWidget);
    expect(find.text('Orion Labs'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('Flagged'), findsOneWidget);
  });

  testWidgets(
    'Navigating from Mailboxes to Inbox displays email list and bottom bar',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const AppleMailDemoApp());
      await tester.pumpAndSettle();

      // Tap All Inboxes
      await tester.tap(find.text('All Inboxes'));
      await tester.pumpAndSettle();

      // Verify Inbox header and mock emails
      expect(find.text('Inbox'), findsAtLeast(1));
      expect(find.text('Orion Labs · Updated Just Now'), findsOneWidget);
      expect(find.text('Apple'), findsAtLeast(1));
      expect(find.text('Marcus Vance'), findsOneWidget);
      expect(find.text('Project Nova Launch'), findsOneWidget);
      expect(find.text('Starlink'), findsOneWidget);

      // Verify bottom search bar
      expect(find.text('Search'), findsOneWidget);
    },
  );

  testWidgets('Select button toggles batch selection mode and Done button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();

    // Navigate to Inbox
    await tester.tap(find.text('All Inboxes'));
    await tester.pumpAndSettle();

    // Tap Select
    final selectButton = find.text('Select').last;
    expect(find.text('Select'), findsAtLeast(1));
    await tester.tap(selectButton);
    await tester.pumpAndSettle();

    // Batch actions bar should appear
    expect(find.text('Select Messages'), findsOneWidget);
    expect(find.text('Mark'), findsOneWidget);
    expect(find.text('Trash'), findsOneWidget);
    expect(find.text('Select All'), findsAtLeast(1));

    // Tap Select All
    await tester.tap(find.text('Select All').last);
    await tester.pumpAndSettle();
    expect(find.text('Deselect All'), findsAtLeast(1));
  });

  testWidgets('Tapping email pushes EmailDetailView with headers and body', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();

    // Navigate to Inbox
    await tester.tap(find.text('All Inboxes'));
    await tester.pumpAndSettle();

    // Tap Marcus Vance email
    await tester.tap(find.text('Project Nova Launch'));
    await tester.pumpAndSettle();

    // Verify detail view
    expect(find.textContaining('To:'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.trash), findsAtLeast(1));
    expect(find.byIcon(CupertinoIcons.folder), findsAtLeast(1));
    expect(find.byIcon(CupertinoIcons.reply), findsAtLeast(1));
  });

  testWidgets('Compose button opens ComposeEmailSheet with send button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();

    // Navigate to Inbox
    await tester.tap(find.text('All Inboxes'));
    await tester.pumpAndSettle();

    // Tap compose button
    final composeIcon = find.byIcon(CupertinoIcons.square_pencil);
    expect(composeIcon, findsOneWidget);
    await tester.tap(composeIcon);
    await tester.pumpAndSettle();

    // Verify compose sheet
    expect(find.text('New Message'), findsOneWidget);
    expect(find.text('To: '), findsOneWidget);
    expect(find.textContaining('Cc/Bcc, From: sebastian@'), findsOneWidget);
    expect(find.text('Sent from my iPhone'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);

    // Type recipient
    await tester.enterText(
      find
          .descendant(
            of: find.byType(ComposeEmailSheet),
            matching: find.byType(CupertinoTextField),
          )
          .first,
      'sarah@design.io',
    );
    await tester.pumpAndSettle();

    // Verify Send button arrow
    expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);
  });

  testWidgets(
    'GlassBarItem.sheet in EmailDetailView morphs into reply ComposeEmailSheet',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const AppleMailDemoApp());
      await tester.pumpAndSettle();

      // Navigate to Inbox
      await tester.tap(find.text('All Inboxes'));
      await tester.pumpAndSettle();

      // Navigate to email detail
      await tester.tap(find.text('Project Nova Launch'));
      await tester.pumpAndSettle();

      // Tap reply sheet item in pinned bar (follows PR #325 GlassBarItem.sheet)
      final replyIcon = find.byIcon(CupertinoIcons.reply).last;
      await tester.tap(replyIcon);
      await tester.pumpAndSettle();

      // Verify reply compose sheet opened
      expect(find.text('New Message'), findsOneWidget);
      expect(find.text('Re: Project Nova Launch'), findsOneWidget);
    },
  );

  testWidgets(
    'Inbox options menu opens and reveals all items without clipping',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const AppleMailDemoApp());
      await tester.pumpAndSettle();

      // Navigate to Inbox
      await tester.tap(find.text('All Inboxes'));
      await tester.pumpAndSettle();

      // Tap the ellipsis menu button
      final ellipsisFinder = find.byIcon(CupertinoIcons.ellipsis).last;
      await tester.tap(ellipsisFinder);
      await tester.pumpAndSettle();

      // Verify all menu items are rendered and visible
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('List View'), findsOneWidget);
      expect(find.text('About Categories'), findsOneWidget);
      expect(find.text('Show Priority'), findsOneWidget);
      expect(find.text('Show Contact Photos'), findsOneWidget);
      expect(find.text('iOS 27 Glass'), findsOneWidget);
      expect(find.byType(GlassSwitch), findsOneWidget);
    },
  );

  testWidgets(
    'iOS 27 Glass GlassSwitch in menu persists glass mode across navigation',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        kMailUseIos27.value = true;
      });

      await tester.pumpWidget(const AppleMailDemoApp());
      await tester.pumpAndSettle();

      // Starts in iOS 27 mode
      expect(kMailUseIos27.value, isTrue);

      // Navigate to Inbox
      await tester.tap(find.text('All Inboxes'));
      await tester.pumpAndSettle();

      // Verify Inbox starts in iOS 27 mode
      final inboxContext = tester.element(find.text('Inbox').first);
      expect(MailGlassScope.isIos27(inboxContext), isTrue);

      // Open the ··· options menu
      final ellipsisFinder = find.byIcon(CupertinoIcons.ellipsis).last;
      await tester.tap(ellipsisFinder);
      await tester.pumpAndSettle();

      // Menu shows the iOS 27 Glass row with switch ON
      expect(find.text('iOS 27 Glass'), findsOneWidget);
      final switchWidget = tester.widget<GlassSwitch>(find.byType(GlassSwitch));
      expect(switchWidget.value, isTrue);

      // Tap the menu item row to toggle to iOS 26
      await tester.tap(find.text('iOS 27 Glass'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(kMailUseIos27.value, isFalse);
      expect(MailGlassScope.isIos27(inboxContext), isFalse);

      // Reopen menu — switch should now reflect iOS 26 mode (OFF)
      await tester.tap(ellipsisFinder);
      await tester.pumpAndSettle();
      final switchOff = tester.widget<GlassSwitch>(find.byType(GlassSwitch));
      expect(switchOff.value, isFalse);

      // Dismiss the menu by tapping outside it, then pop back
      await tester.tapAt(const Offset(30, 200));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      // MailboxesView still reflects iOS 26 mode via shared notifier
      expect(kMailUseIos27.value, isFalse);
    },
  );

  testWidgets(
    'Compose sheet circular buttons: send enables on text entry and close dismisses',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const AppleMailDemoApp());
      await tester.pumpAndSettle();

      // Navigate to Inbox
      await tester.tap(find.text('All Inboxes'));
      await tester.pumpAndSettle();

      // Tap compose button
      await tester.tap(find.byIcon(CupertinoIcons.square_pencil));
      await tester.pumpAndSettle();

      // Verify circular buttons are rendered
      final xmarkFinder = find.byIcon(CupertinoIcons.xmark);
      final sendFinder = find.byIcon(CupertinoIcons.arrow_up);
      expect(xmarkFinder, findsOneWidget);
      expect(sendFinder, findsOneWidget);

      // Send button is initially inactive (settings.glassColor is not kMailBlue)
      final sendButtonBefore = tester.widget<GlassButton>(
        find.ancestor(of: sendFinder, matching: find.byType(GlassButton)),
      );
      expect(sendButtonBefore.settings?.glassColor, isNot(equals(kMailBlue)));

      // Enter recipient text into "To: " field
      await tester.enterText(
        find
            .descendant(
              of: find.byType(ComposeEmailSheet),
              matching: find.byType(CupertinoTextField),
            )
            .first,
        'dev@liquidglass.com',
      );
      await tester.pumpAndSettle();

      // Send button is now ready: GlassButton turned vibrant kMailBlue with GlassBodyMode.clear!
      final sendButtonAfter = tester.widget<GlassButton>(
        find.ancestor(of: sendFinder, matching: find.byType(GlassButton)),
      );
      expect(sendButtonAfter.settings?.glassColor, equals(kMailBlue));
      expect(sendButtonAfter.settings?.bodyMode, equals(GlassBodyMode.clear));

      // Clear recipient text
      await tester.enterText(
        find
            .descendant(
              of: find.byType(ComposeEmailSheet),
              matching: find.byType(CupertinoTextField),
            )
            .first,
        '',
      );
      await tester.pumpAndSettle();

      // Tapping close button (X) dismisses the compose sheet directly
      await tester.tap(xmarkFinder);
      await tester.pumpAndSettle();

      // Compose sheet is dismissed, back to Inbox view
      expect(find.text('New message'), findsNothing);
      expect(find.text('Inbox'), findsAtLeast(1));
    },
  );

  testWidgets('Tapping close button with draft triggers confirm', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('All Inboxes'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.square_pencil));
    await tester.pumpAndSettle();

    await tester.enterText(
      find
          .descendant(
            of: find.byType(ComposeEmailSheet),
            matching: find.byType(CupertinoTextField),
          )
          .first,
      'dev@liquidglass.com',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    // Verify ActionSheet appears with Delete Draft and Cancel
    expect(find.text('Delete Draft'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Delete Draft to dismiss cleanly
    await tester.tap(find.text('Delete Draft'));
    await tester.pumpAndSettle();

    // Compose sheet is dismissed back to Inbox
    expect(find.text('New Message'), findsNothing);
    expect(find.text('Inbox'), findsAtLeast(1));
  });

  testWidgets('Edit button in Mailboxes morphs into menu button in Inbox', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppleMailDemoApp());
    await tester.pumpAndSettle();

    // Verify Edit pill is visible in Mailboxes
    expect(find.text('Edit'), findsAtLeast(1));

    // Navigate to Inbox
    await tester.tap(find.text('All Inboxes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // Mid-morph: both the morphing capsule and entering items participate
    expect(find.byType(GlassButton), findsWidgets);

    await tester.pumpAndSettle();

    // In Inbox: Edit is gone, replaced by menu button and Select pill
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(CupertinoIcons.ellipsis), findsAtLeast(1));
    expect(find.text('Select'), findsAtLeast(1));
  });

  testWidgets(
    'Compose sheet keyboard toolbar floats above keyboard when viewInsets are active',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(const AppleMailDemoApp());
      await tester.pumpAndSettle();

      // Navigate to Inbox and open Compose
      await tester.tap(find.text('All Inboxes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.square_pencil));
      await tester.pumpAndSettle();

      final composeToolbarFinder = find.descendant(
        of: find.byType(ComposeEmailSheet),
        matching: find.byType(GlassButtonGroup),
      );

      // When keyboard is closed, formatting toolbar is hidden (opacity 0)
      final animatedOpacityFinder = find.ancestor(
        of: composeToolbarFinder,
        matching: find.byType(AnimatedOpacity),
      );
      expect(animatedOpacityFinder, findsOneWidget);
      final initialOpacity = tester
          .widget<AnimatedOpacity>(animatedOpacityFinder)
          .opacity;
      expect(initialOpacity, 0.0);

      // Simulate software keyboard opening (bottom: 900 physical = 300 logical px)
      tester.view.viewInsets = FakeViewPadding(bottom: 900);
      await tester.pumpAndSettle();

      // When keyboard is active, toolbar fades in (opacity 1.0)
      final activeOpacity = tester
          .widget<AnimatedOpacity>(animatedOpacityFinder)
          .opacity;
      expect(activeOpacity, 1.0);

      // Screen height is 2532 / 3.0 = 844 logical px.
      // Keyboard top is at 844 - 300 = 544.
      // The bottom of the toolbar must be at or above 544 (sitting just above the keyboard).
      final toolbarRect = tester.getRect(composeToolbarFinder);

      expect(toolbarRect.bottom, lessThanOrEqualTo(544.0));
      // It should be neatly positioned just above the keyboard (e.g. 12pt margin -> bottom ~532)
      expect(toolbarRect.bottom, greaterThan(520.0));
    },
  );
}
