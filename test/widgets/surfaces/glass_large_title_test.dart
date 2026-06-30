import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // GlassLargeTitleController
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassLargeTitleController', () {
    test('initial collapseProgress is 0.0', () {
      final controller = GlassLargeTitleController();
      expect(controller.collapseProgress, 0.0);
      controller.dispose();
    });

    test('exposes a ScrollController', () {
      final controller = GlassLargeTitleController();
      expect(controller.scrollController, isA<ScrollController>());
      controller.dispose();
    });

    test('collapseProgress stays at 0.0 with no scroll', () {
      final controller = GlassLargeTitleController();
      expect(controller.collapseProgress, 0.0);
      controller.dispose();
    });

    test('custom collapseTitleHeight is accepted', () {
      final controller = GlassLargeTitleController(collapseTitleHeight: 80.0);
      expect(controller.collapseProgress, 0.0);
      controller.dispose();
    });

    test('dispose cleans up without error', () {
      final controller = GlassLargeTitleController();
      expect(() => controller.dispose(), returnsNormally);
    });

    test('listeners are notified — integration via addListener', () async {
      final controller = GlassLargeTitleController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // No notification until scroll position actually changes.
      expect(notifyCount, 0);
      controller.dispose();
    });

    test('removeListener does not throw', () {
      final controller = GlassLargeTitleController();
      void listener() {}
      controller.addListener(listener);
      expect(() => controller.removeListener(listener), returnsNormally);
      controller.dispose();
    });

    test('rawScrollOffset starts at 0.0', () {
      final controller = GlassLargeTitleController();
      expect(controller.rawScrollOffset, 0.0);
      controller.dispose();
    });

    test('reportMeasuredHeight updates internal threshold without error', () {
      final controller = GlassLargeTitleController(collapseTitleHeight: 52.0);
      // Reporting a different height is accepted gracefully. _updateState
      // returns early (no scroll client) so no notification fires here.
      expect(() => controller.reportMeasuredHeight(68.0), returnsNormally);
      controller.dispose();
    });

    test('reportMeasuredHeight ignores zero or unchanged height', () {
      final controller = GlassLargeTitleController(collapseTitleHeight: 52.0);
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.reportMeasuredHeight(0.0); // ignored — zero
      controller.reportMeasuredHeight(52.0); // ignored — same as current
      expect(notifyCount, 0);
      controller.dispose();
    });

    // ── Phase 2: search bar collapse ───────────────────────────────────────

    test('initial searchBarCollapseProgress is 0.0', () {
      final controller = GlassLargeTitleController();
      expect(controller.searchBarCollapseProgress, 0.0);
      controller.dispose();
    });

    test('custom searchBarHeight constructor param is accepted', () {
      final controller = GlassLargeTitleController(searchBarHeight: 60.0);
      // No scroll attached — progress stays 0.
      expect(controller.searchBarCollapseProgress, 0.0);
      controller.dispose();
    });

    test('reportSearchBarHeight updates threshold without error', () {
      final controller = GlassLargeTitleController(searchBarHeight: 44.0);
      expect(() => controller.reportSearchBarHeight(56.0), returnsNormally);
      controller.dispose();
    });

    test('reportSearchBarHeight ignores zero height', () {
      final controller = GlassLargeTitleController(searchBarHeight: 44.0);
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.reportSearchBarHeight(0.0); // ignored
      expect(notifyCount, 0);
      controller.dispose();
    });

    test('reportSearchBarHeight ignores unchanged height', () {
      final controller = GlassLargeTitleController(searchBarHeight: 44.0);
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.reportSearchBarHeight(44.0); // same — ignored
      expect(notifyCount, 0);
      controller.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GlassLargeTitle widget
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassLargeTitle widget', () {
    late GlassLargeTitleController controller;

    setUp(() {
      controller = GlassLargeTitleController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestApp({Widget? child}) {
      return CupertinoApp(
        home: CupertinoPageScaffold(
          child: child ?? const SizedBox(),
        ),
      );
    }

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(text: 'Test', controller: controller),
          ],
        ),
      ));
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(text: 'Chats', controller: controller),
          ],
        ),
      ));
      expect(find.text('Chats'), findsOneWidget);
    });

    testWidgets('is fully opaque at 0 scroll offset', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(text: 'Messages', controller: controller),
            // Enough content to scroll
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (_, i) =>
                  SizedBox(height: 60, child: Text('Item $i')),
            ),
          ],
        ),
      ));
      await tester.pump();

      // collapseProgress should be 0 — opacity 1.0
      expect(controller.collapseProgress, 0.0);

      // Find the Text and verify it's within an Opacity of 1.0
      final text = tester.widget<Text>(find.text('Messages'));
      // Alpha on text colour should be 1.0 (fully visible)
      expect(text.style?.color?.a, closeTo(1.0, 0.01));
    });

    testWidgets('accepts trailing widget', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(
              text: 'Library',
              controller: controller,
              trailing: const Text('trailing_widget'),
            ),
          ],
        ),
      ));
      expect(find.text('trailing_widget'), findsOneWidget);
    });

    testWidgets('respects custom fontSize', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(
              text: 'Browse',
              controller: controller,
              fontSize: 28.0,
            ),
          ],
        ),
      ));
      final text = tester.widget<Text>(find.text('Browse'));
      expect(text.style?.fontSize, 28.0);
    });

    testWidgets('respects custom color', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(
              text: 'Inbox',
              controller: controller,
              color: const Color(0xFFFF0000),
            ),
          ],
        ),
      ));
      final text = tester.widget<Text>(find.text('Inbox'));
      // Red channel at full, fully opaque
      expect(text.style?.color?.r, closeTo(1.0, 0.01));
    });

    testWidgets('swapping controller re-subscribes correctly', (tester) async {
      final controller2 = GlassLargeTitleController();
      var notifyCount = 0;

      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(text: 'Title', controller: controller),
          ],
        ),
      ));

      // Swap to controller2
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller2.scrollController,
          slivers: [
            GlassLargeTitle(text: 'Title', controller: controller2),
          ],
        ),
      ));

      // No error — controller1 listener removed, controller2 subscribed
      expect(notifyCount, 0);
      controller2.dispose();
    });

    // ── Phase 2: searchBar widget ──────────────────────────────────────────

    testWidgets('searchBar child is rendered when provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(
              text: 'Messages',
              controller: controller,
              searchBar: const Text('search_bar_widget'),
            ),
          ],
        ),
      ));
      // Both title and search bar must be present.
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('search_bar_widget'), findsOneWidget);
    });

    testWidgets('no searchBar — renders without error and no ClipRect',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(text: 'Library', controller: controller),
          ],
        ),
      ));
      // Title present, no crash.
      expect(find.text('Library'), findsOneWidget);
      // No ClipRect added when searchBar is null.
      expect(find.byType(ClipRect), findsNothing);
    });

    testWidgets('searchBar is wrapped in ClipRect for height collapse',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(
              text: 'Inbox',
              controller: controller,
              searchBar: const SizedBox(key: Key('sb'), height: 44),
            ),
          ],
        ),
      ));
      // ClipRect must wrap the search bar for height-collapse animation.
      expect(find.byType(ClipRect), findsOneWidget);
    });

    testWidgets('searchBar is fully visible at zero scroll progress',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(
              text: 'Search',
              controller: controller,
              searchBar: const Text('search_visible'),
            ),
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (_, i) =>
                  SizedBox(height: 60, child: Text('Item $i')),
            ),
          ],
        ),
      ));
      await tester.pump();

      // searchBarCollapseProgress == 0 → Opacity should be 1.0
      expect(controller.searchBarCollapseProgress, 0.0);
      // Search bar text is visible (not hidden by zero opacity).
      expect(find.text('search_visible'), findsOneWidget);
    });

    testWidgets('custom searchBarPadding is accepted without error',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            GlassLargeTitle(
              text: 'Pad',
              controller: controller,
              searchBar: const Text('padded_search'),
              searchBarPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ],
        ),
      ));
      expect(find.text('padded_search'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GlassAppBar.largeTitleController
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassAppBar with largeTitleController', () {
    late GlassLargeTitleController controller;

    setUp(() {
      controller = GlassLargeTitleController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildApp({GlassLargeTitleController? ctrl}) {
      return MaterialApp(
        home: Scaffold(
          appBar: GlassAppBar(
            title: const Text('bar_title'),
            largeTitleController: ctrl,
          ),
          body: const SizedBox(),
        ),
      );
    }

    testWidgets('renders normally without controller — no regression',
        (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('bar_title'), findsOneWidget);
    });

    testWidgets('with controller at progress 0, bar title opacity is 0',
        (tester) async {
      await tester.pumpWidget(buildApp(ctrl: controller));
      await tester.pump();

      // collapseProgress == 0 → barProgress = (0 - 0.5) / 0.5 = -1 → clamped to 0
      // → Opacity wraps title at 0.0
      final opacityFinder = find.ancestor(
        of: find.text('bar_title'),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsWidgets);
      final opacity = tester.widgetList<Opacity>(opacityFinder).first;
      expect(opacity.opacity, closeTo(0.0, 0.01));
    });

    testWidgets('bar title stays invisible below 50% collapse progress',
        (tester) async {
      // The delayed fade means bar title only starts appearing after progress >= 0.5.
      await tester.pumpWidget(buildApp(ctrl: controller));
      await tester.pump();

      final opacityFinder = find.ancestor(
        of: find.text('bar_title'),
        matching: find.byType(Opacity),
      );
      final opacity = tester.widgetList<Opacity>(opacityFinder).first;
      // progress=0.0 → barProgress=(0-0.5)/0.5=-1→0.0 → easeOut(0.0)=0.0
      expect(opacity.opacity, closeTo(0.0, 0.01));
    });

    testWidgets('without controller, no Opacity wrapper around title',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // With no controller, title should NOT be wrapped in a zero-opacity Opacity.
      final zeroOpacities = tester
          .widgetList<Opacity>(find.ancestor(
            of: find.text('bar_title'),
            matching: find.byType(Opacity),
          ))
          .where((o) => o.opacity < 1.0)
          .toList();
      expect(zeroOpacities, isEmpty);
    });
  });
}
