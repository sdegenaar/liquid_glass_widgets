// test/widgets/shared/glass_page_push_back_scope_test.dart
//
// Integration tests for _GlassPageState's push-back scope subscription.
//
// Verifies that:
//  1. LiquidGlassPushBackScope is inactive at rest.
//  2. LiquidGlassPushBackScope becomes active when a sheet is pushed over the
//     page (secondaryAnimation > 0).
//  3. LiquidGlassPushBackScope returns to inactive when the sheet is dismissed.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/liquid_glass_push_back_scope.dart';

// Disable the initialize guard for tests — GlassPage checks it in debug mode
// but we deliberately skip LiquidGlassWidgets.initialize() here.
import 'package:liquid_glass_widgets/widgets/shared/glass_page.dart'
    show glassPageInitializeGuardEnabled;

void main() {
  setUp(() {
    glassPageInitializeGuardEnabled = false;
  });

  tearDown(() {
    glassPageInitializeGuardEnabled = true;
  });

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  /// Finds LiquidGlassPushBackScope.active from inside the GlassPage subtree.
  bool glassPagePushBackActive(WidgetTester tester) {
    final scope = tester.widget<LiquidGlassPushBackScope>(
      find.byType(LiquidGlassPushBackScope).first,
    );
    return scope.active;
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('GlassPage — LiquidGlassPushBackScope emission', () {
    testWidgets('scope is inactive when page is at rest', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassPage(
            child: const CupertinoPageScaffold(
              child: Text('Page'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(LiquidGlassPushBackScope),
        findsOneWidget,
        reason: 'GlassPage must always emit a LiquidGlassPushBackScope',
      );
      expect(
        glassPagePushBackActive(tester),
        isFalse,
        reason: 'At rest (no sheet presented), scope must be inactive',
      );
    });

    testWidgets('stays inactive for an ordinary page transition',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        CupertinoApp(
          navigatorKey: navigatorKey,
          home: GlassPage(
            child: const CupertinoPageScaffold(
              child: Text('Main page'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      navigatorKey.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) => const CupertinoPageScaffold(
            child: Text('Page'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        glassPagePushBackActive(tester),
        isFalse,
        reason: 'A sliding page does not scale its covered page back',
      );
    });

    testWidgets('ignores scale transitions above the Navigator',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        CupertinoApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => ScaleTransition(
            scale: const AlwaysStoppedAnimation<double>(1),
            child: child!,
          ),
          home: GlassPage(
            child: const CupertinoPageScaffold(
              child: Text('Main page'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      navigatorKey.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) => const CupertinoPageScaffold(
            child: Text('Page'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        glassPagePushBackActive(tester),
        isFalse,
        reason: 'Only a scale applied inside the route subtree is push-back',
      );
    });

    testWidgets('scope becomes active when a Cupertino sheet is pushed',
        (tester) async {
      // Build a navigator with our GlassPage as the initial route.
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        CupertinoApp(
          navigatorKey: navigatorKey,
          home: GlassPage(
            child: const CupertinoPageScaffold(
              child: Text('Main page'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially inactive.
      expect(glassPagePushBackActive(tester), isFalse);

      // A Cupertino sheet scales the covered page back while it presents.
      navigatorKey.currentState!.push(
        CupertinoSheetRoute<void>(
          scrollableBuilder: (context, scrollController) =>
              const CupertinoPageScaffold(child: Text('Sheet')),
        ),
      );

      // Pump partway through the transition (don't settle yet).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final activeDuringTransition = glassPagePushBackActive(tester);

      // Let the transition complete.
      await tester.pumpAndSettle();

      expect(activeDuringTransition, isTrue);

      // Now pop the route.
      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // After full dismissal, secondary animation on the page is 0 again.
      expect(
        glassPagePushBackActive(tester),
        isFalse,
        reason: 'After sheet is dismissed, push-back scope must be inactive',
      );
    });

    testWidgets(
        'GlassTabBar keeps its configured padding through an ordinary pop',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      const barKey = ValueKey('glass-tab-bar-under-test');

      await tester.pumpWidget(
        CupertinoApp(
          navigatorKey: navigatorKey,
          home: GlassScaffold(
            bottomBar: GlassTabBar.bottom(
              key: barKey,
              tabs: const [
                GlassTab(label: 'Home', icon: Icon(CupertinoIcons.house)),
                GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              horizontalPadding: 24,
              verticalPadding: 12,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Offset labelInset() {
        final bar = find.byKey(barKey, skipOffstage: false);
        final label = find
            .descendant(
              of: bar,
              matching: find.text('Home', skipOffstage: false),
            )
            .first;
        return tester.getCenter(label) - tester.getRect(bar).topLeft;
      }

      final restingInset = labelInset();

      navigatorKey.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) => const CupertinoPageScaffold(
            child: Text('Detail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        glassPagePushBackActive(tester),
        isFalse,
        reason: 'An ordinary slide-out must not freeze premium glass geometry',
      );
      final exitingInset = labelInset();
      expect(exitingInset.dx, closeTo(restingInset.dx, 0.1));
      expect(exitingInset.dy, closeTo(restingInset.dy, 0.1));
    });

    testWidgets(
        'scope remains inactive when GlassPage is not inside a navigator route',
        (tester) async {
      // GlassPage used without a route context — ModalRoute.of returns null.
      // The scope must default to inactive and not throw.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GlassPage(
            child: const Text('bare'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byType(LiquidGlassPushBackScope),
        findsOneWidget,
      );
      expect(
        glassPagePushBackActive(tester),
        isFalse,
        reason: 'Without a route, push-back scope must always be inactive',
      );
    });

    testWidgets('GlassPage disposes animation listeners without error',
        (tester) async {
      // Regression: ensure _subscribeSecondaryAnimation(null) in dispose()
      // does not throw even if the animation was never listened to.
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassPage(
            child: const CupertinoPageScaffold(child: Text('Page')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Replace root widget — causes GlassPage to be disposed.
      await tester.pumpWidget(const CupertinoApp(home: Text('Replaced')));
      await tester.pumpAndSettle();

      // If we reach here without exceptions, dispose cleaned up correctly.
      expect(find.text('Replaced'), findsOneWidget);
    });
  });
}
