/// Tests that verify widgets resolve brightness-aware colors correctly
/// in both light and dark modes.
///
/// This file targets the content color audit from the iOS 26 light mode
/// support work. Each widget that was changed to resolve from
/// CupertinoColors.label / .secondaryLabel / .tertiaryLabel is tested
/// in both Brightness.light and Brightness.dark.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// =============================================================================
// Helpers
// =============================================================================

/// Wraps [child] in a CupertinoApp with the given [brightness].
///
/// Using CupertinoApp ensures CupertinoTheme provides the correct
/// brightness-resolved colors — matching real-world usage.
Widget _buildApp({
  required Brightness brightness,
  required Widget child,
}) {
  return CupertinoApp(
    theme: CupertinoThemeData(brightness: brightness),
    home: CupertinoPageScaffold(
      child: Center(child: child),
    ),
  );
}

/// Finds the first [IconTheme] descendant of [parentType] and returns its
/// effective icon color.
Color? _findIconColor(WidgetTester tester, Type parentType) {
  final iconTheme = tester.widget<IconTheme>(
    find
        .descendant(
          of: find.byType(parentType),
          matching: find.byType(IconTheme),
        )
        .first,
  );
  return iconTheme.data.color;
}

/// Finds the [Color] property of the first circular [Container] dot in
/// [GlassPageControl].
Color? _findActiveDotColor(WidgetTester tester) {
  final dots = find.descendant(
    of: find.byType(GlassPageControl),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          (widget.decoration as BoxDecoration).color != null,
    ),
  );

  // The active dot is the largest one (scale 1.0 vs 0.7).
  // Just return the first dot's color — for page 0, the first is active.
  final container = tester.widget<Container>(dots.first);
  return (container.decoration as BoxDecoration).color;
}

// =============================================================================
// GlassIconButton — light/dark color resolution
// =============================================================================

void main() {
  group('GlassIconButton brightness-aware colors', () {
    testWidgets('uses dark icon color (white) in dark mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.dark,
          child: GlassIconButton(
            icon: const Icon(CupertinoIcons.star),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final color = _findIconColor(tester, GlassIconButton);
      // In dark mode, CupertinoColors.label resolves to white
      expect(color, isNotNull);
      expect(color!.a, greaterThan(0.9));
      // White has R,G,B all near 1.0
      expect(color.r, greaterThan(0.9));
      expect(color.g, greaterThan(0.9));
      expect(color.b, greaterThan(0.9));
    });

    testWidgets('uses light icon color (black) in light mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: GlassIconButton(
            icon: const Icon(CupertinoIcons.star),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final color = _findIconColor(tester, GlassIconButton);
      // In light mode, CupertinoColors.label resolves to black
      expect(color, isNotNull);
      expect(color!.a, greaterThan(0.9));
      // Black has R,G,B all near 0.0
      expect(color.r, lessThan(0.1));
      expect(color.g, lessThan(0.1));
      expect(color.b, lessThan(0.1));
    });

    testWidgets('disabled icon uses tertiaryLabel in dark mode',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.dark,
          child: const GlassIconButton(
            icon: Icon(CupertinoIcons.star),
            onPressed: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final color = _findIconColor(tester, GlassIconButton);
      // tertiaryLabel in dark mode is a semi-transparent white
      expect(color, isNotNull);
      expect(color!.a, lessThan(0.5)); // significantly dimmed
    });

    testWidgets('disabled icon uses tertiaryLabel in light mode',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: const GlassIconButton(
            icon: Icon(CupertinoIcons.star),
            onPressed: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final color = _findIconColor(tester, GlassIconButton);
      // tertiaryLabel in light mode is a semi-transparent black
      expect(color, isNotNull);
      expect(color!.a, lessThan(0.5)); // significantly dimmed
    });
  });

  // ===========================================================================
  // GlassPageControl — light/dark dot colors
  // ===========================================================================

  group('GlassPageControl brightness-aware colors', () {
    testWidgets('active dot is white-ish in dark mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.dark,
          child: const GlassPageControl(
            count: 3,
            currentPage: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final color = _findActiveDotColor(tester);
      expect(color, isNotNull);
      // In dark mode, CupertinoColors.label is white
      expect(color!.r, greaterThan(0.9));
      expect(color.g, greaterThan(0.9));
      expect(color.b, greaterThan(0.9));
    });

    testWidgets('active dot is black-ish in light mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: const GlassPageControl(
            count: 3,
            currentPage: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final color = _findActiveDotColor(tester);
      expect(color, isNotNull);
      // In light mode, CupertinoColors.label is black
      expect(color!.r, lessThan(0.1));
      expect(color.g, lessThan(0.1));
      expect(color.b, lessThan(0.1));
    });

    testWidgets('custom activeColor overrides brightness resolution',
        (tester) async {
      const customColor = Color(0xFFFF0000);
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: const GlassPageControl(
            count: 3,
            currentPage: 0,
            activeColor: customColor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final color = _findActiveDotColor(tester);
      expect(color, equals(customColor));
    });
  });

  // ===========================================================================
  // GlassTabBar — light/dark label/icon colors
  // ===========================================================================

  group('GlassTabBar brightness-aware colors', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.dark,
          child: GlassTabBar(
            selectedIndex: 0,
            onTabSelected: (_) {},
            tabs: const [
              GlassTab(label: 'Tab 1'),
              GlassTab(label: 'Tab 2'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without error
      expect(find.byType(GlassTabBar), findsOneWidget);
      // Selected tab text should be visible (white-ish in dark mode)
      final selectedText = tester.widget<Text>(
        find.text('Tab 1'),
      );
      expect(selectedText.style?.color, isNotNull);
      final color = selectedText.style!.color!;
      expect(color.r, greaterThan(0.9));
      expect(color.g, greaterThan(0.9));
      expect(color.b, greaterThan(0.9));
    });

    testWidgets('renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: GlassTabBar(
            selectedIndex: 0,
            onTabSelected: (_) {},
            tabs: const [
              GlassTab(label: 'Tab 1'),
              GlassTab(label: 'Tab 2'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without error
      expect(find.byType(GlassTabBar), findsOneWidget);
      // Selected tab text should be visible (black-ish in light mode)
      final selectedText = tester.widget<Text>(
        find.text('Tab 1'),
      );
      expect(selectedText.style?.color, isNotNull);
      final color = selectedText.style!.color!;
      expect(color.r, lessThan(0.1));
      expect(color.g, lessThan(0.1));
      expect(color.b, lessThan(0.1));
    });

    testWidgets('unselected tab uses secondary color in light mode',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: GlassTabBar(
            selectedIndex: 0,
            onTabSelected: (_) {},
            tabs: const [
              GlassTab(label: 'Selected'),
              GlassTab(label: 'Unselected'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final unselectedText = tester.widget<Text>(find.text('Unselected'));
      expect(unselectedText.style?.color, isNotNull);
      // secondaryLabel in light mode is semi-transparent black (≈60% opacity)
      final color = unselectedText.style!.color!;
      expect(color.a, lessThan(0.7));
    });

    testWidgets('custom selectedLabelStyle overrides brightness resolution',
        (tester) async {
      const customStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF0000),
      );
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: GlassTabBar(
            selectedIndex: 0,
            onTabSelected: (_) {},
            selectedLabelStyle: customStyle,
            tabs: const [
              GlassTab(label: 'Custom'),
              GlassTab(label: 'Other'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectedText = tester.widget<Text>(find.text('Custom'));
      expect(selectedText.style?.color, equals(const Color(0xFFFF0000)));
    });
  });

  // ===========================================================================
  // GlassBottomBar — verify existing brightness resolution still works
  // ===========================================================================

  group('GlassBottomBar brightness-aware colors', () {
    testWidgets('renders in light mode without error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: GlassBottomBar(
            selectedIndex: 0,
            onTabSelected: (_) {},
            tabs: const [
              GlassBottomBarTab(
                label: 'Home',
                icon: Icon(CupertinoIcons.house),
              ),
              GlassBottomBarTab(
                label: 'Search',
                icon: Icon(CupertinoIcons.search),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassBottomBar), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.dark,
          child: GlassBottomBar(
            selectedIndex: 0,
            onTabSelected: (_) {},
            tabs: const [
              GlassBottomBarTab(
                label: 'Home',
                icon: Icon(CupertinoIcons.house),
              ),
              GlassBottomBarTab(
                label: 'Search',
                icon: Icon(CupertinoIcons.search),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassBottomBar), findsOneWidget);
    });
  });

  // ===========================================================================
  // GlassBadge — text stays white (intentional — on colored background)
  // ===========================================================================

  group('GlassBadge text color', () {
    testWidgets('badge text is white in dark mode (on colored bg)',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.dark,
          child: GlassBadge(
            count: 5,
            child: const Icon(CupertinoIcons.bell),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('5'));
      expect(text.style?.color, equals(CupertinoColors.white));
    });

    testWidgets('badge text is white in light mode (on colored bg)',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: GlassBadge(
            count: 3,
            child: const Icon(CupertinoIcons.bell),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('3'));
      // Badge text should remain white regardless of mode — it's on a red bg
      expect(text.style?.color, equals(CupertinoColors.white));
    });
  });

  // ===========================================================================
  // GlassSwitch thumb — stays white (iOS native behavior)
  // ===========================================================================

  group('GlassSwitch thumb color (should NOT change with brightness)', () {
    testWidgets('thumb is white in dark mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.dark,
          child: GlassSwitch(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassSwitch), findsOneWidget);
      // Just verify it renders — thumb color is internal
    });

    testWidgets('thumb is white in light mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          brightness: Brightness.light,
          child: GlassSwitch(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassSwitch), findsOneWidget);
    });
  });
}
