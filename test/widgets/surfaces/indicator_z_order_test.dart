// Regression tests for indicator Z-order and persistent selected-icon vibrancy.
//
// Architecture (current):
//
//   MaskingQuality.off (both bars):
//     Stack:
//       [0] bg glass RepaintBoundary
//       [1] Positioned(icons — all unselected style, for refraction)
//       [2] AnimatedGlassIndicator (only when thickness > 0.05)
//       [3] Positioned(selectedTabBuilder — always at TARGET position)
//     The selected-icon overlay at [3] renders the selected icon at full
//     saturation regardless of spring/thickness, fixing the "dull at rest" issue.
//
//   MaskingQuality.high (both bars):
//     Stack:
//       [0] bg glass RepaintBoundary
//       [1] Positioned(RepaintBoundary { inverse-clip unselected + forward-clip selected })
//       [2] AnimatedGlassIndicator
//     Both icon types are merged into ONE RepaintBoundary so the glass refracts
//     them correctly without white bleed-through.
//
// Tests verify:
//   1. The unselected icon base layer is BELOW AnimatedGlassIndicator in .high mode
//      (ensures glass can refract the icons beneath it).
//   2. The persistent selected-icon overlay is ABOVE AnimatedGlassIndicator in .off mode
//      (ensures selected icon is vibrant at rest).
//   3. AnimatedGlassIndicator is ABOVE the unselected icon layer in .high mode.
//
// Related: https://github.com/sdegenaar/liquid_glass_widgets/pull/29

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/shared/animated_glass_indicator.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/bottom_bar_internal.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/searchable_bottom_bar_internal.dart';

import '../../shared/test_helpers.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _tabs = [
  GlassBottomBarTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
  GlassBottomBarTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
  GlassBottomBarTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

(Element, Element)? _stackParentAndChild(Element element) {
  Element current = element;
  while (true) {
    Element? parent;
    current.visitAncestorElements((a) {
      parent = a;
      return false;
    });
    if (parent == null) return null;
    if (parent!.widget is Stack) return (parent!, current);
    current = parent!;
  }
}

int _childIndexInStack(Element stack, Element child) {
  int idx = -1;
  int i = 0;
  stack.visitChildren((c) {
    if (c == child) idx = i;
    i++;
  });
  return idx;
}

List<Element> _stackChildren(Element stack) {
  final children = <Element>[];
  stack.visitChildren(children.add);
  return children;
}

bool _containsType(Element root, Type type) {
  if (root.widget.runtimeType == type) return true;
  bool found = false;
  void visit(Element el) {
    if (found) return;
    if (el.widget.runtimeType == type) { found = true; return; }
    el.visitChildren(visit);
  }
  root.visitChildren(visit);
  return found;
}

// ---------------------------------------------------------------------------
// Assertions
// ---------------------------------------------------------------------------

/// For .off mode: verifies that:
///   - AnimatedGlassIndicator is ABOVE the unselected icon base layer (for refraction).
///   - At least one icon-bearing sibling is ABOVE the indicator (the selected overlay).
void _assertOffModeZOrder(WidgetTester tester, {required String context}) {
  final indicatorFinder = find.byType(AnimatedGlassIndicator);
  expect(indicatorFinder, findsAtLeastNWidgets(1),
      reason: '$context: AnimatedGlassIndicator not found.');

  final indicatorEl = indicatorFinder.evaluate().first;
  final pair = _stackParentAndChild(indicatorEl);
  expect(pair, isNotNull,
      reason: '$context: AnimatedGlassIndicator has no Stack ancestor.');

  final (stackEl, indicatorChild) = pair!;
  final indicatorIdx = _childIndexInStack(stackEl, indicatorChild);
  final siblings = _stackChildren(stackEl);

  // Collect icon-bearing siblings below and above the indicator.
  int iconsBelowCount = 0;
  int iconsAboveCount = 0;
  for (int i = 0; i < siblings.length; i++) {
    if (i == indicatorIdx) continue;
    if (_containsType(siblings[i], Container)) {
      if (i < indicatorIdx) iconsBelowCount++;
      if (i > indicatorIdx) iconsAboveCount++;
    }
  }

  expect(iconsBelowCount, greaterThan(0),
      reason: '$context (.off): Unselected icon base layer must be BELOW '
          'AnimatedGlassIndicator so the glass can refract the icons.');

  expect(iconsAboveCount, greaterThan(0),
      reason: '$context (.off): Persistent selected-icon overlay must be ABOVE '
          'AnimatedGlassIndicator so the selected icon is vibrant at rest. '
          'See: https://github.com/sdegenaar/liquid_glass_widgets/pull/29');
}

/// For .high mode: verifies that AnimatedGlassIndicator is the TOPMOST icon-
/// bearing sibling (the merged RepaintBoundary is below it).
void _assertHighModeZOrder(WidgetTester tester, {required String context}) {
  final indicatorFinder = find.byType(AnimatedGlassIndicator);
  expect(indicatorFinder, findsAtLeastNWidgets(1),
      reason: '$context: AnimatedGlassIndicator not found.');

  final indicatorEl = indicatorFinder.evaluate().last;
  final pair = _stackParentAndChild(indicatorEl);
  expect(pair, isNotNull);

  final (stackEl, indicatorChild) = pair!;
  final indicatorIdx = _childIndexInStack(stackEl, indicatorChild);
  final siblings = _stackChildren(stackEl);

  // All icon-bearing siblings must be below the indicator.
  for (int i = indicatorIdx + 1; i < siblings.length; i++) {
    expect(
      _containsType(siblings[i], Container),
      isFalse,
      reason: '$context (.high): Found an icon-bearing sibling (child #$i) '
          'ABOVE AnimatedGlassIndicator (child #$indicatorIdx). In .high mode '
          'ALL icon content must be in the merged RepaintBoundary below the '
          'glass to avoid white bleed-through.',
    );
  }

  // At least one icon-bearing sibling must be below the indicator.
  bool foundBelow = false;
  for (int i = 0; i < indicatorIdx; i++) {
    if (_containsType(siblings[i], Container)) { foundBelow = true; break; }
  }
  expect(foundBelow, isTrue,
      reason: '$context (.high): No icon-bearing sibling found below '
          'AnimatedGlassIndicator. The merged icon RepaintBoundary must be '
          'below the glass so it can be refracted.');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Indicator Z-order: refraction + vibrant selected icon', () {

    // ── GlassBottomBar / .off ─────────────────────────────────────────────

    testWidgets('GlassBottomBar .off — indicator above base icons, selected overlay above indicator',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: GlassBottomBar(
          tabs: _tabs, selectedIndex: 1, onTabSelected: (_) {},
          maskingQuality: MaskingQuality.off,
        ),
      ));
      await tester.pumpAndSettle();

      // Drive spring so AnimatedGlassIndicator enters tree.
      final state = tester.state<TabIndicatorState>(find.byType(TabIndicator));
      state.setState(() => state.tabIsDown = true);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));

      _assertOffModeZOrder(tester, context: 'GlassBottomBar');

      await tester.pumpAndSettle();
    });

    // ── GlassBottomBar / .high ────────────────────────────────────────────

    testWidgets('GlassBottomBar .high — merged icon layer below indicator',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: GlassBottomBar(
          tabs: _tabs, selectedIndex: 1, onTabSelected: (_) {},
          maskingQuality: MaskingQuality.high,
        ),
      ));
      await tester.pumpAndSettle();
      _assertHighModeZOrder(tester, context: 'GlassBottomBar');
    });

    // ── GlassSearchableBottomBar / .off ───────────────────────────────────

    testWidgets('GlassSearchableBottomBar .off — indicator above base icons, selected overlay above indicator',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: GlassSearchableBottomBar(
          tabs: _tabs, selectedIndex: 1, onTabSelected: (_) {},
          maskingQuality: MaskingQuality.off,
          searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
        ),
      ));
      await tester.pumpAndSettle();

      final state = tester.state<SearchableTabIndicatorState>(
          find.byType(SearchableTabIndicator));
      state.setState(() => state.tabIsDown = true);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));

      _assertOffModeZOrder(tester, context: 'GlassSearchableBottomBar');

      await tester.pumpAndSettle();
    });

    // ── GlassSearchableBottomBar / .high ──────────────────────────────────

    testWidgets('GlassSearchableBottomBar .high — merged icon layer below indicator',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: GlassSearchableBottomBar(
          tabs: _tabs, selectedIndex: 1, onTabSelected: (_) {},
          maskingQuality: MaskingQuality.high,
          searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
        ),
      ));
      await tester.pumpAndSettle();
      _assertHighModeZOrder(tester, context: 'GlassSearchableBottomBar');
    });
  });
}
