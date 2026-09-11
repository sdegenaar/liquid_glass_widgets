import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/glass_nav_pinned_host.dart';

void main() {
  setUp(() {
    GlassNavigationShellState.debugPinningSupported = true;
    GlassModalSheet.debugMorphSupportsBlending = true;
  });

  tearDown(() {
    GlassNavigationShellState.debugPinningSupported = null;
    GlassModalSheet.debugMorphSupportsBlending = null;
  });

  Widget shellApp(Widget home) => CupertinoApp(
        builder: (context, child) => GlassNavigationShell(child: child!),
        home: home,
      );

  /// Settles the route transition and the post-frame registration handover.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump();
  }

  Finder inHost(Finder matching) => find.descendant(
        of: find.byType(GlassNavPinnedHost),
        matching: matching,
      );

  /// What the route's own capsule is painted at. The screen declares one
  /// group, so the bar owns exactly one trigger, and the first [Opacity] below
  /// it is the one the trigger empties.
  double barCapsuleOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .descendant(
              of: find.byType(GlassMorphTrigger),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  group('a sheet item in the pinned chrome', () {
    testWidgets(
        'presents through the route\'s own capsule, not the hoisted one',
        (tester) async {
      await tester.pumpWidget(shellApp(const _Screen()));
      await settle(tester);
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsOneWidget);
      expect(barCapsuleOpacity(tester), 1.0);

      await tester.tap(inHost(find.byIcon(CupertinoIcons.add)));
      await tester.pump();
      await tester.pump();

      // The hoisted capsule is drawn above the Navigator, where the sheet
      // cannot cover it; the one the bar owns is inside the route.
      expect(barCapsuleOpacity(tester), 0.0);
    });

    testWidgets('leaves the sheet free to cover the rest of the chrome',
        (tester) async {
      await tester.pumpWidget(shellApp(const _Screen()));
      await settle(tester);
      final route = ModalRoute.of(tester.element(find.text('body')))!;
      final shell = tester.state<GlassNavigationShellState>(
        find.byType(GlassNavigationShell),
      );

      await tester.tap(inHost(find.byIcon(CupertinoIcons.add)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // A presentation hands the chrome back, so it sits under the sheet with
      // the rest of the page. Holding it hoisted for the morph would leave a
      // back button painted over the sheet and live above its barrier.
      expect(shell.isHoisting(route), isFalse);
      expect(find.byType(GlassNavPinnedHost), findsNothing);
    });

    testWidgets('empties the capsule rather than the glyph it was tapped on',
        (tester) async {
      await tester.pumpWidget(shellApp(const _Screen()));
      await settle(tester);

      await tester.tap(inHost(find.byIcon(CupertinoIcons.add)));
      await tester.pump();
      await tester.pump();

      // The neighbouring icon goes with it: on screen the cluster is one
      // control, and a droplet out of a hole in it reads as a second object.
      final emptied = find.ancestor(
        of: find.byIcon(CupertinoIcons.share),
        matching: find.byType(Opacity),
      );
      expect(
        emptied.evaluate().any((e) => (e.widget as Opacity).opacity == 0.0),
        isTrue,
      );
    });

    testWidgets('is inert while a transition is running', (tester) async {
      await tester.pumpWidget(shellApp(const _Screen()));
      await settle(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        CupertinoPageRoute<void>(builder: (_) => const _Screen(title: 'Next')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Mid-transition the item is not hit-testable at all, which is the
      // point — a miss here is the assertion, not a flake.
      await tester.tap(
        inHost(find.byIcon(CupertinoIcons.add)).first,
        warnIfMissed: false,
      );
      await tester.pump();

      expect(barCapsuleOpacity(tester), 1.0);
      await settle(tester);
    });

    testWidgets('still presents when the bar offers no capsule of its own',
        (tester) async {
      var presented = 0;
      GlassMorphAnchor? seen;
      await tester.pumpWidget(shellApp(_OwnBarScreen(
        onPresent: (anchor) {
          presented++;
          seen = anchor;
        },
      )));
      await settle(tester);

      await tester.tap(inHost(find.byIcon(CupertinoIcons.add)));
      await tester.pump();

      // A bar that renders the items itself has no anchor to offer. Losing the
      // morph is the cost; losing the tap would be a bug.
      expect(presented, 1);
      expect(seen, isNull);
    });

    testWidgets(
        'dismissing the sheet restores the capsule and re-hoists chrome',
        (tester) async {
      await tester.pumpWidget(shellApp(const _Screen()));
      await settle(tester);
      final route = ModalRoute.of(tester.element(find.text('body')))!;
      final shell = tester.state<GlassNavigationShellState>(
        find.byType(GlassNavigationShell),
      );

      await tester.tap(inHost(find.byIcon(CupertinoIcons.add)));
      await tester.pump();
      await tester.pump();

      expect(barCapsuleOpacity(tester), 0.0);
      expect(shell.isHoisting(route), isFalse);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await settle(tester);

      expect(barCapsuleOpacity(tester), 1.0);
      expect(shell.isHoisting(route), isTrue);
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsOneWidget);
    });

    testWidgets('presents through the leading capsule when declared in leading',
        (tester) async {
      await tester.pumpWidget(shellApp(const _LeadingScreen()));
      await settle(tester);
      expect(inHost(find.byIcon(CupertinoIcons.add)), findsOneWidget);
      expect(barCapsuleOpacity(tester), 1.0);

      await tester.tap(inHost(find.byIcon(CupertinoIcons.add)));
      await tester.pump();
      await tester.pump();

      expect(barCapsuleOpacity(tester), 0.0);
    });
  });

  group('a sheet item drawn in-route', () {
    testWidgets('presents through the same capsule it would hoisted',
        (tester) async {
      await tester.pumpWidget(const CupertinoApp(home: _Screen()));
      await settle(tester);
      expect(find.byType(GlassNavPinnedHost), findsNothing);
      expect(barCapsuleOpacity(tester), 1.0);

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pump();
      await tester.pump();

      expect(barCapsuleOpacity(tester), 0.0);
    });
  });
}

/// A screen whose one trailing group presents a sheet out of its capsule.
class _Screen extends StatelessWidget {
  const _Screen({this.title = 'Home'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: Text(title),
        backButton: false,
        actions: [
          GlassBarItem.sheet(
            icon: const Icon(CupertinoIcons.add),
            onPresent: (anchor) => GlassModalSheet.show<void>(
              context: context,
              morphFrom: anchor,
              builder: (_) => const SizedBox(height: 200),
            ),
          ),
          GlassBarItem.icon(
            icon: const Icon(CupertinoIcons.share),
            onTap: () {},
          ),
        ],
      ),
      body: const Center(child: Text('body')),
    );
  }
}

/// A screen that registers with the shell directly, drawing its own bar — the
/// shape `GlassPinnedBarChrome`'s own doc points such an app at.
class _OwnBarScreen extends StatefulWidget {
  const _OwnBarScreen({required this.onPresent});

  final void Function(GlassMorphAnchor? anchor) onPresent;

  @override
  State<_OwnBarScreen> createState() => _OwnBarScreenState();
}

class _OwnBarScreenState extends State<_OwnBarScreen> {
  GlassNavigationShellState? _shell;
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shell = GlassNavigationShell.maybeOf(context);
    _route = ModalRoute.of(context);
    _shell?.register(
      _route!,
      GlassNavBarRegistration(
        actions: [
          GlassBarItem.sheet(
            icon: const Icon(CupertinoIcons.add),
            onPresent: widget.onPresent,
          ),
        ],
        showsBackButton: false,
      ),
    );
  }

  @override
  void dispose() {
    if (_route != null) _shell?.unregister(_route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const CupertinoPageScaffold(child: Center(child: Text('body')));
}

/// A screen whose one leading group presents a sheet out of its capsule.
class _LeadingScreen extends StatelessWidget {
  const _LeadingScreen();

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Leading'),
        backButton: false,
        leading: [
          GlassBarItem.sheet(
            icon: const Icon(CupertinoIcons.add),
            onPresent: (anchor) => GlassModalSheet.show<void>(
              context: context,
              morphFrom: anchor,
              builder: (_) => const SizedBox(height: 200),
            ),
          ),
        ],
      ),
      body: const Center(child: Text('body')),
    );
  }
}
