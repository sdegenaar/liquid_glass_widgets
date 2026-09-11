import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/glass_nav_pinned_host.dart';

void main() {
  setUp(() {
    // Headless test runs report no shader support; force the gate open so the
    // pinned path is exercised. Individual tests override to test the gate.
    GlassNavigationShellState.debugPinningSupported = true;
  });

  tearDown(() {
    GlassNavigationShellState.debugPinningSupported = null;
  });

  Widget shellApp(Widget home, {bool shell = true}) {
    return MaterialApp(
      builder: shell
          ? (context, child) => GlassNavigationShell(child: child!)
          : null,
      home: home,
    );
  }

  /// Settles the route transition and the post-frame registration handover.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump();
  }

  Finder inHost(Finder matching) =>
      find.descendant(of: find.byType(GlassNavPinnedHost), matching: matching);

  Finder inBar(Finder matching) =>
      find.descendant(of: find.byType(AppBar), matching: matching);

  group('horizontal inset', () {
    /// The chrome's own box, which is what the inset positions.
    Rect hostRect(WidgetTester tester) {
      final box =
          tester.renderObject<RenderBox>(find.byType(GlassNavPinnedHost));
      return box.localToGlobal(Offset.zero) & box.size;
    }

    testWidgets('defaults to the inset GlassAppBar draws its own chrome at',
        (tester) async {
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
      )));
      await settle(tester);

      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final rect = hostRect(tester);
      expect(rect.left, GlassNavPinnedMetrics.horizontalPadding);
      expect(rect.right, screen - GlassNavPinnedMetrics.horizontalPadding);
    });

    testWidgets('follows the bar that registered it', (tester) async {
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
        horizontalInset: 16,
      )));
      await settle(tester);

      // A bar aligned to its app's page gutter rather than the package's
      // default steps sideways at every hand-over unless the shell follows it.
      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final rect = hostRect(tester);
      expect(rect.left, 16);
      expect(rect.right, screen - 16);
    });

    testWidgets('a push lands on the incoming route\'s guide', (tester) async {
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
        horizontalInset: 16,
      )));
      await settle(tester);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => const _MaterialBarScreen(
          title: 'Detail',
          actionIcon: CupertinoIcons.share,
          horizontalInset: 4,
        ),
      ));
      await settle(tester);

      expect(hostRect(tester).left, 4);
    });
  });

  group('registration', () {
    testWidgets('a plain Material AppBar hands its items to the shell',
        (tester) async {
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
      )));
      await settle(tester);

      // The shell renders the capsule above the navigator...
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsOneWidget);
      // ...and the bar itself is left holding only its measuring placeholder.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(GlassButtonGroup),
        ),
        findsNothing,
      );
    });

    testWidgets('hoisted only flips on the frame after registration',
        (tester) async {
      final hoists = <bool>[];
      await tester.pumpWidget(shellApp(_RecordingScreen(hoists: hoists)));

      // The shell needs a frame to render its copy, so the first build must
      // still report the bar as owning its own chrome.
      expect(hoists, [false]);

      await tester.pump();
      expect(hoists.last, isTrue);
    });

    testWidgets('unregisters when the bar leaves the tree', (tester) async {
      await tester.pumpWidget(shellApp(const _TogglingScreen()));
      await settle(tester);
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsOneWidget);

      await tester.tap(find.text('drop'));
      await settle(tester);

      expect(find.byType(GlassPinnedBarChrome), findsNothing);
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsNothing);
    });

    testWidgets('a pushed route takes the chrome and hands it back on pop',
        (tester) async {
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
      )));
      await settle(tester);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => const _MaterialBarScreen(
          title: 'Thread',
          actionIcon: CupertinoIcons.search,
        ),
      ));
      await settle(tester);

      expect(inHost(find.byIcon(CupertinoIcons.search)), findsOneWidget);
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsNothing);
      // The back button is the shell's, not the AppBar's automatic one.
      expect(inHost(find.byIcon(CupertinoIcons.back)), findsOneWidget);

      navigator.pop();
      await settle(tester);

      expect(inHost(find.byIcon(CupertinoIcons.add)), findsOneWidget);
      expect(inHost(find.byIcon(CupertinoIcons.back)), findsNothing);
    });

    testWidgets('onBack overrides the default pop', (tester) async {
      var custom = 0;
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
      )));
      await settle(tester);

      tester.state<NavigatorState>(find.byType(Navigator)).push(
            MaterialPageRoute<void>(
              builder: (_) => _MaterialBarScreen(
                title: 'Thread',
                actionIcon: CupertinoIcons.search,
                onBack: () => custom++,
              ),
            ),
          );
      await settle(tester);

      await tester.tap(inHost(find.byIcon(CupertinoIcons.back)));
      await settle(tester);

      expect(custom, 1);
      expect(find.text('Thread'), findsOneWidget); // custom handler didn't pop
    });

    testWidgets('backButton: false suppresses the pinned back button',
        (tester) async {
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
      )));
      await settle(tester);

      tester.state<NavigatorState>(find.byType(Navigator)).push(
            MaterialPageRoute<void>(
              builder: (_) => const _MaterialBarScreen(
                title: 'Thread',
                actionIcon: CupertinoIcons.search,
                backButton: false,
              ),
            ),
          );
      await settle(tester);

      expect(inHost(find.byIcon(CupertinoIcons.search)), findsOneWidget);
      expect(inHost(find.byIcon(CupertinoIcons.back)), findsNothing);
    });
  });

  group('opting out', () {
    testWidgets('without a shell the bar keeps drawing its own chrome',
        (tester) async {
      await tester.pumpWidget(shellApp(
        shell: false,
        const _MaterialBarScreen(
          title: 'Inbox',
          actionIcon: CupertinoIcons.add,
        ),
      ));
      await settle(tester);

      expect(find.byType(GlassNavPinnedHost), findsNothing);
      // The widget builds the in-route capsule itself: a bar written against
      // it never has to declare a fallback of its own.
      expect(inBar(find.byType(GlassButtonGroup)), findsOneWidget);
      expect(inBar(find.byIcon(CupertinoIcons.add)), findsOneWidget);
    });

    testWidgets('the in-route back button is built for you and pops',
        (tester) async {
      await tester.pumpWidget(shellApp(
        shell: false,
        const _MaterialBarScreen(
          title: 'Inbox',
          actionIcon: CupertinoIcons.add,
        ),
      ));
      await settle(tester);

      tester.state<NavigatorState>(find.byType(Navigator)).push(
            MaterialPageRoute<void>(
              builder: (_) => const _MaterialBarScreen(
                title: 'Thread',
                actionIcon: CupertinoIcons.search,
              ),
            ),
          );
      await settle(tester);

      final back = inBar(find.byIcon(CupertinoIcons.back));
      expect(back, findsOneWidget);
      await tester.tap(back);
      await settle(tester);

      expect(find.text('Thread'), findsNothing);
      // Root route again: no back button, here or anywhere.
      expect(find.byIcon(CupertinoIcons.back), findsNothing);
    });

    testWidgets('an unsupported device falls back in-route', (tester) async {
      GlassNavigationShellState.debugPinningSupported = false;
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
      )));
      await settle(tester);

      expect(find.byType(GlassNavPinnedHost), findsNothing);
      // The widget builds the in-route capsule itself: a bar written against
      // it never has to declare a fallback of its own.
      expect(inBar(find.byType(GlassButtonGroup)), findsOneWidget);
      expect(inBar(find.byIcon(CupertinoIcons.add)), findsOneWidget);
    });

    testWidgets('enabled: false keeps a route out of the shell entirely',
        (tester) async {
      await tester.pumpWidget(shellApp(const _MaterialBarScreen(
        title: 'Inbox',
        actionIcon: CupertinoIcons.add,
        enabled: false,
      )));
      await settle(tester);

      expect(inHost(find.byIcon(CupertinoIcons.add)), findsNothing);
      expect(inBar(find.byIcon(CupertinoIcons.add)), findsOneWidget);
    });

    testWidgets('flipping enabled off releases a live registration',
        (tester) async {
      await tester.pumpWidget(shellApp(const _TogglingScreen()));
      await settle(tester);
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsOneWidget);

      await tester.tap(find.text('disable'));
      await settle(tester);

      expect(inHost(find.byIcon(CupertinoIcons.add)), findsNothing);
      expect(inBar(find.byIcon(CupertinoIcons.add)), findsOneWidget);
    });
  });

  testWidgets('spacers are rejected until multi-capsule rendering lands',
      (tester) async {
    await tester.pumpWidget(shellApp(GlassPinnedBarChrome(
      actions: const [GlassBarItem.spacer()],
      builder: (context, hoisted) => const SizedBox(),
    )));
    expect(tester.takeException(), isAssertionError);
  });
}

/// A screen whose bar is a plain Flutter [AppBar] that still pins.
///
/// Mirrors the shape an app with its own design system would use: the items
/// are declared once as data and the resolved slots go straight into the bar.
class _MaterialBarScreen extends StatelessWidget {
  const _MaterialBarScreen({
    required this.title,
    required this.actionIcon,
    this.onBack,
    this.backButton = true,
    this.enabled = true,
    this.horizontalInset,
  });

  final String title;
  final IconData actionIcon;
  final VoidCallback? onBack;
  final bool backButton;
  final bool enabled;
  final double? horizontalInset;

  @override
  Widget build(BuildContext context) {
    return GlassPinnedBarChrome(
      actions: [
        GlassBarItem.icon(icon: Icon(actionIcon), onTap: () {}),
      ],
      backButton: backButton,
      onBack: onBack,
      enabled: enabled,
      horizontalInset: horizontalInset,
      builder: (context, chrome) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          automaticallyImplyLeading: false,
          leading: chrome.leading,
          actions: chrome.actions,
        ),
        body: Center(child: Text('$title body')),
      ),
    );
  }
}

/// A screen that can drop its [GlassPinnedBarChrome] or disable it in place.
class _TogglingScreen extends StatefulWidget {
  const _TogglingScreen();

  @override
  State<_TogglingScreen> createState() => _TogglingScreenState();
}

class _TogglingScreenState extends State<_TogglingScreen> {
  bool _mounted = true;
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => setState(() => _mounted = false),
            child: const Text('drop'),
          ),
          TextButton(
            onPressed: () => setState(() => _enabled = false),
            child: const Text('disable'),
          ),
        ],
      ),
    );

    Widget bar(List<Widget> actions) => Scaffold(
          appBar: AppBar(title: const Text('Inbox'), actions: actions),
          body: body,
        );

    if (!_mounted) return bar(const []);
    return GlassPinnedBarChrome(
      actions: [
        GlassBarItem.icon(icon: const Icon(CupertinoIcons.add), onTap: () {}),
      ],
      enabled: _enabled,
      builder: (context, chrome) => bar(chrome.actions),
    );
  }
}

/// A screen that records every `hoisted` value its builder is handed.
class _RecordingScreen extends StatelessWidget {
  const _RecordingScreen({required this.hoists});

  final List<bool> hoists;

  @override
  Widget build(BuildContext context) {
    return GlassPinnedBarChrome(
      actions: [
        GlassBarItem.icon(icon: const Icon(CupertinoIcons.add), onTap: () {}),
      ],
      builder: (context, chrome) {
        hoists.add(chrome.hoisted);
        return const Scaffold(body: SizedBox());
      },
    );
  }
}
