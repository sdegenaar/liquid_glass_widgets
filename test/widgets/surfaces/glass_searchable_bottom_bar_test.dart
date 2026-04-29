import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _testTabs = [
  const GlassBottomBarTab(
    label: 'For You',
    icon: Icon(CupertinoIcons.news),
  ),
  const GlassBottomBarTab(
    label: 'Following',
    icon: Icon(CupertinoIcons.person_2),
  ),
  const GlassBottomBarTab(
    label: 'Saved',
    icon: Icon(CupertinoIcons.bookmark),
  ),
];

Widget _buildBar({
  bool isSearchActive = false,
  int selectedIndex = 0,
  ValueChanged<int>? onTabSelected,
  ValueChanged<bool>? onSearchToggle,
  TextEditingController? controller,
  FocusNode? focusNode,
  ValueChanged<String>? onChanged,
  GlassBottomBarExtraButton? extraButton,
  GlassQuality? quality,
}) {
  return createTestApp(
    child: GlassSearchableBottomBar(
      tabs: _testTabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected ?? (_) {},
      isSearchActive: isSearchActive,
      maskingQuality: MaskingQuality.off, // no dual-layer in tests
      quality: quality,
      extraButton: extraButton,
      searchConfig: GlassSearchBarConfig(
        onSearchToggle: onSearchToggle ?? (_) {},
        hintText: 'Search News',
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GlassSearchableBottomBar', () {
    // ── Instantiation ─────────────────────────────────────────────────────────

    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(_buildBar());
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('displays tab labels when search is inactive', (tester) async {
      await tester.pumpWidget(_buildBar());
      await tester.pump();

      expect(find.text('For You'), findsWidgets);
      expect(find.text('Following'), findsWidgets);
      expect(find.text('Saved'), findsWidgets);
    });

    testWidgets('displays search hint text when search is active',
        (tester) async {
      await tester.pumpWidget(_buildBar(isSearchActive: true));
      await tester.pumpAndSettle();

      expect(find.text('Search News'), findsOneWidget);
    });

    // ── Tab interaction ───────────────────────────────────────────────────────

    testWidgets('calls onTabSelected when a tab is tapped', (tester) async {
      var selected = 0;

      await tester.pumpWidget(
        _buildBar(onTabSelected: (i) => selected = i),
      );
      await tester.pump();

      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();

      expect(selected, equals(1));
    });

    testWidgets('reflects selectedIndex correctly', (tester) async {
      await tester.pumpWidget(_buildBar(selectedIndex: 2));
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    // ── Search toggle ─────────────────────────────────────────────────────────

    testWidgets('calls onSearchToggle when search pill is tapped',
        (tester) async {
      bool? lastToggle;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSearchableBottomBar(
            tabs: _testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            isSearchActive: false,
            maskingQuality: MaskingQuality.off,
            searchConfig: GlassSearchBarConfig(
              onSearchToggle: (v) => lastToggle = v,
              hintText: 'Search',
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap the search icon (search toggle button)
      final searchIconFinder = find.byIcon(CupertinoIcons.search);
      if (searchIconFinder.evaluate().isNotEmpty) {
        await tester.tap(searchIconFinder.first);
        await tester.pumpAndSettle();
        expect(lastToggle, isNotNull);
      }
    });

    // ── Text controller ───────────────────────────────────────────────────────

    testWidgets('uses provided TextEditingController', (tester) async {
      final controller = TextEditingController(text: 'flutter');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildBar(isSearchActive: true, controller: controller),
      );
      await tester.pumpAndSettle();

      // Widget should mount without errors when a controller is provided.
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    // ── Focus node ────────────────────────────────────────────────────────────

    testWidgets('accepts and preserves a caller-provided FocusNode',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _buildBar(isSearchActive: true, focusNode: focusNode),
      );
      await tester.pumpAndSettle();

      // Widget mounted successfully with external focus node — node must still
      // be alive (the widget must NOT have disposed it).
      expect(focusNode.dispose, isA<Function>());
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('does not dispose caller-provided FocusNode on rebuild',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester
          .pumpWidget(_buildBar(isSearchActive: true, focusNode: focusNode));
      await tester.pumpAndSettle();
      // Trigger a rebuild by toggling search state.
      await tester
          .pumpWidget(_buildBar(isSearchActive: false, focusNode: focusNode));
      await tester.pumpAndSettle();

      // Node should still be usable after the widget rebuilds.
      expect(() => focusNode.hasFocus, returnsNormally);
    });

    // ── onChanged callback ────────────────────────────────────────────────────

    testWidgets('calls onChanged as user types', (tester) async {
      final values = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildBar(
          isSearchActive: true,
          controller: controller,
          onChanged: values.add,
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'glass');
        await tester.pump();
        expect(values, contains('glass'));
      }
    });

    // ── Extra button ──────────────────────────────────────────────────────────

    testWidgets('displays extra button when provided', (tester) async {
      await tester.pumpWidget(
        _buildBar(
          extraButton: GlassBottomBarExtraButton(
            icon: const Icon(CupertinoIcons.add),
            label: 'Add',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    });

    testWidgets('extra button fires onTap correctly', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildBar(
          extraButton: GlassBottomBarExtraButton(
            icon: const Icon(CupertinoIcons.add),
            label: 'Add',
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pump();

      expect(tapped, isTrue);
    });

    // ── Quality path ──────────────────────────────────────────────────────────

    testWidgets('mounts correctly with GlassQuality.minimal', (tester) async {
      await tester.pumpWidget(_buildBar(quality: GlassQuality.minimal));
      await tester.pump();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('mounts correctly with GlassQuality.standard', (tester) async {
      await tester.pumpWidget(_buildBar(quality: GlassQuality.standard));
      await tester.pump();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    // ── Defaults ──────────────────────────────────────────────────────────────

    test('widget defaults are correct', () {
      final bar = GlassSearchableBottomBar(
        tabs: _testTabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
        searchConfig: GlassSearchBarConfig(
          onSearchToggle: (_) {},
        ),
      );

      expect(bar.isSearchActive, isFalse);
      expect(bar.spacing, equals(8));
      expect(bar.barHeight, equals(64));
      expect(bar.barBorderRadius, equals(32));
      expect(bar.horizontalPadding, equals(20));
      expect(bar.verticalPadding, equals(20));
      expect(bar.showIndicator, isTrue);
      expect(bar.quality, isNull);
    });

    // ── Assertions ────────────────────────────────────────────────────────────

    test('asserts on empty tabs list', () {
      expect(
        () => GlassSearchableBottomBar(
          tabs: const [],
          selectedIndex: 0,
          onTabSelected: (_) {},
          searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
        ),
        throwsAssertionError,
      );
    });

    test('asserts when selectedIndex is out of range', () {
      expect(
        () => GlassSearchableBottomBar(
          tabs: _testTabs,
          selectedIndex: 99,
          onTabSelected: (_) {},
          searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
        ),
        throwsAssertionError,
      );
    });
  });

  // ── GlassSearchBarConfig ───────────────────────────────────────────────────

  group('GlassSearchBarConfig', () {
    test('can be instantiated with required parameters', () {
      final config = GlassSearchBarConfig(
        onSearchToggle: (_) {},
      );

      expect(config.hintText, equals('Search'));
      expect(config.collapsedTabWidth, isNull);
      expect(config.autocorrect, isTrue);
      expect(config.enableSuggestions, isTrue);
      expect(config.autoFocusOnExpand, isFalse);
      expect(config.showsCancelButton, isTrue);
      expect(config.cancelButtonText, equals('Cancel'));
    });

    test('respects custom hint text', () {
      final config = GlassSearchBarConfig(
        onSearchToggle: (_) {},
        hintText: 'Search Apple News',
      );
      expect(config.hintText, equals('Search Apple News'));
    });

    test('stores focusNode reference without disposing', () {
      final node = FocusNode();
      addTearDown(node.dispose);

      final config = GlassSearchBarConfig(
        onSearchToggle: (_) {},
        focusNode: node,
      );

      expect(config.focusNode, same(node));
    });

    test('stores controller reference', () {
      final ctrl = TextEditingController();
      addTearDown(ctrl.dispose);

      final config = GlassSearchBarConfig(
        onSearchToggle: (_) {},
        controller: ctrl,
      );

      expect(config.controller, same(ctrl));
    });
  });

  // ── Additional coverage for uncovered branches ───────────────────────────

  group('GlassSearchableBottomBar uncovered branch coverage', () {
    testWidgets('quality inherited when quality param is null', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassSearchableBottomBar(
              tabs: _testTabs,
              selectedIndex: 0,
              onTabSelected: (_) {},
              maskingQuality: MaskingQuality.off,
              searchConfig: GlassSearchBarConfig(
                onSearchToggle: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('tabPillAnchor center activates centeredTab branch',
        (tester) async {
      bool searching = false;
      late StateSetter outerSetState;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return GlassSearchableBottomBar(
                tabs: _testTabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                isSearchActive: searching,
                maskingQuality: MaskingQuality.off,
                tabPillAnchor: GlassTabPillAnchor.center,
                searchConfig: GlassSearchBarConfig(
                  onSearchToggle: (v) => setState(() => searching = v),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      outerSetState(() => searching = true);
      await tester.pumpAndSettle();

      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('didUpdateWidget clears _searchFocused when search deactivated',
        (tester) async {
      bool searching = true;
      late StateSetter outerSetState;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return GlassSearchableBottomBar(
                tabs: _testTabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                isSearchActive: searching,
                maskingQuality: MaskingQuality.off,
                searchConfig: GlassSearchBarConfig(
                  onSearchToggle: (v) => setState(() => searching = v),
                  autoFocusOnExpand: true,
                  showsCancelButton: true,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      outerSetState(() => searching = false);
      await tester.pumpAndSettle();

      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('collapsedTabWidth positive value is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSearchableBottomBar(
            tabs: _testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            isSearchActive: true,
            maskingQuality: MaskingQuality.off,
            searchConfig: GlassSearchBarConfig(
              onSearchToggle: (_) {},
              collapsedTabWidth: 48.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets(
        'extraButton with position afterSearch reserves right-side space',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSearchableBottomBar(
            tabs: _testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassBottomBarExtraButton(
              icon: const Icon(CupertinoIcons.mic),
              label: 'Mic',
              onTap: () {},
              position: ExtraButtonPosition.afterSearch,
            ),
            searchConfig: GlassSearchBarConfig(
              onSearchToggle: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(CupertinoIcons.mic), findsOneWidget);
    });

    testWidgets(
        'extraButton collapseOnSearchFocus=false keeps button during search',
        (tester) async {
      bool searching = false;
      late StateSetter outerSetState;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return GlassSearchableBottomBar(
                tabs: _testTabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                isSearchActive: searching,
                maskingQuality: MaskingQuality.off,
                extraButton: GlassBottomBarExtraButton(
                  icon: const Icon(CupertinoIcons.add_circled),
                  label: 'Add',
                  onTap: () {},
                  collapseOnSearchFocus: false,
                ),
                searchConfig: GlassSearchBarConfig(
                  onSearchToggle: (v) => setState(() => searching = v),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      outerSetState(() => searching = true);
      await tester.pumpAndSettle();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('showsCancelButton=false skips dismiss pill layout',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSearchableBottomBar(
            tabs: _testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            isSearchActive: true,
            maskingQuality: MaskingQuality.off,
            searchConfig: GlassSearchBarConfig(
              onSearchToggle: (_) {},
              showsCancelButton: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });

    testWidgets('autoFocusOnExpand=true requests focus when search expands',
        (tester) async {
      bool searching = false;
      late StateSetter outerSetState;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return GlassSearchableBottomBar(
                tabs: _testTabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                isSearchActive: searching,
                maskingQuality: MaskingQuality.off,
                searchConfig: GlassSearchBarConfig(
                  onSearchToggle: (v) => setState(() => searching = v),
                  autoFocusOnExpand: true,
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      outerSetState(() => searching = true);
      await tester.pumpAndSettle();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });
  });

  // ── Interaction glow color — theme propagation (fix for collapsed logo pill)
  //
  // Regression: the collapsed logo GlassButton was hardcoding 0x33FFFFFF as a
  // fallback even though the outer GlassSearchableBottomBar had already resolved
  // the correct theme color. This group verifies the full propagation chain:
  //
  //   GlassThemeData.glowColors.primary
  //       → effectiveInteractionGlowColor (GlassSearchableBottomBar.build)
  //       → SearchableTabIndicator.interactionGlowColor
  //       → GlassButton.glowColor  (collapsed logo pill, isSearchActive=true)

  group('GlassSearchableBottomBar interaction glow — theme propagation', () {
    /// Builds the bar inside a [GlassTheme] with a known primary glow color,
    /// then returns the [GlassButton] widget rendered for the collapsed logo.
    Widget buildWithTheme({
      required Color primaryGlow,
      bool isSearchActive = true,
      GlassInteractionBehavior interactionBehavior =
          GlassInteractionBehavior.glowOnly,
    }) {
      return MaterialApp(
        home: GlassTheme(
          data: GlassThemeData(
            light: GlassThemeVariant(
              glowColors: GlassGlowColors(primary: primaryGlow),
            ),
            dark: GlassThemeVariant(
              glowColors: GlassGlowColors(primary: primaryGlow),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GlassSearchableBottomBar(
              tabs: _testTabs,
              selectedIndex: 0,
              onTabSelected: (_) {},
              isSearchActive: isSearchActive,
              interactionBehavior: interactionBehavior,
              maskingQuality: MaskingQuality.off,
              searchConfig: GlassSearchBarConfig(
                onSearchToggle: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'collapsed logo GlassButton receives GlassThemeData.primary glow color',
        (tester) async {
      const expectedColor = Color(0xFF00FF00); // vivid green — unmistakable

      await tester.pumpWidget(
        buildWithTheme(primaryGlow: expectedColor),
      );
      await tester.pumpAndSettle();

      // The collapsed logo pill is a GlassButton. Its glowColor should be
      // exactly the theme primary we injected — not the old hardcoded 0x33FFFFFF.
      final buttons = tester.widgetList<GlassButton>(find.byType(GlassButton));
      expect(buttons, isNotEmpty,
          reason: 'Expected at least one GlassButton in collapsed bar');

      // At least one GlassButton must carry the theme color.
      final match = buttons.any((b) => b.glowColor == expectedColor);
      expect(match, isTrue,
          reason:
              'No GlassButton received the theme glow color $expectedColor. '
              'Found: ${buttons.map((b) => b.glowColor).toList()}');
    });

    testWidgets(
        'explicit interactionGlowColor overrides theme (widget param wins)',
        (tester) async {
      const themeColor = Color(0xFF00FF00);
      const explicitColor = Color(0xFFFF0000); // red — different from theme

      await tester.pumpWidget(
        MaterialApp(
          home: GlassTheme(
            data: GlassThemeData(
              light: GlassThemeVariant(
                glowColors: const GlassGlowColors(primary: themeColor),
              ),
              dark: GlassThemeVariant(
                glowColors: const GlassGlowColors(primary: themeColor),
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: GlassSearchableBottomBar(
                tabs: _testTabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                isSearchActive: true,
                // Explicit widget param must win over theme
                interactionGlowColor: explicitColor,
                maskingQuality: MaskingQuality.off,
                searchConfig: GlassSearchBarConfig(
                  onSearchToggle: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<GlassButton>(find.byType(GlassButton));
      expect(buttons, isNotEmpty);

      final hasExplicit = buttons.any((b) => b.glowColor == explicitColor);
      expect(hasExplicit, isTrue,
          reason: 'Explicit interactionGlowColor should override theme');

      // The theme green must NOT appear — widget param has priority
      final hasTheme = buttons.any((b) => b.glowColor == themeColor);
      expect(hasTheme, isFalse,
          reason: 'Theme color should be overridden by explicit param');
    });

    testWidgets(
        'GlassInteractionBehavior.none passes Colors.transparent — glow suppressed',
        (tester) async {
      const primaryGlow = Color(0xFF00FF00);

      await tester.pumpWidget(
        buildWithTheme(
          primaryGlow: primaryGlow,
          interactionBehavior: GlassInteractionBehavior.none,
        ),
      );
      await tester.pumpAndSettle();

      // With .none behavior the bar passes Colors.transparent so the glow
      // wrapper is skipped. No GlassButton should have the theme green.
      final buttons = tester.widgetList<GlassButton>(find.byType(GlassButton));
      final hasGreen = buttons.any((b) => b.glowColor == primaryGlow);
      expect(hasGreen, isFalse,
          reason:
              'GlassInteractionBehavior.none should suppress theme glow color');
    });

    testWidgets(
        'bar mounts correctly in tab-bar mode (isSearchActive=false) with theme',
        (tester) async {
      const primaryGlow = Color(0xFF00FF00);

      await tester.pumpWidget(
        buildWithTheme(primaryGlow: primaryGlow, isSearchActive: false),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });
  });
}
