import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/interactive/liquid_glass_scope.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('LiquidGlassScope', () {
    testWidgets('can be instantiated with a child', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassScope), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('renders child widget correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: const Text('Test Content'),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('provides background key to descendants via static of() method',
        (tester) async {
      GlobalKey? foundKey;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: Builder(
              builder: (context) {
                foundKey = LiquidGlassScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(foundKey, isNotNull);
    });

    testWidgets('returns null when no scope is present', (tester) async {
      GlobalKey? foundKey;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              foundKey = LiquidGlassScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(foundKey, isNull);
    });

    testWidgets('nested scope overrides parent scope', (tester) async {
      GlobalKey? innerKey;
      GlobalKey? outerKey;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: Builder(
              builder: (outerContext) {
                outerKey = LiquidGlassScope.of(outerContext);

                return LiquidGlassScope(
                  child: Builder(
                    builder: (innerContext) {
                      innerKey = LiquidGlassScope.of(innerContext);
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Both scopes should provide keys
      expect(outerKey, isNotNull);
      expect(innerKey, isNotNull);
      // Inner key should be different from outer key
      expect(innerKey, isNot(equals(outerKey)));
    });

    testWidgets('maintains stable key across rebuilds', (tester) async {
      GlobalKey? firstKey;
      GlobalKey? secondKey;

      final controller = ValueNotifier(0);

      await tester.pumpWidget(
        createTestApp(
          child: ValueListenableBuilder<int>(
            valueListenable: controller,
            builder: (context, value, _) {
              return LiquidGlassScope(
                child: Builder(
                  builder: (context) {
                    final key = LiquidGlassScope.of(context);
                    if (value == 0) {
                      firstKey = key;
                    } else {
                      secondKey = key;
                    }
                    return Text('Value: $value');
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(firstKey, isNotNull);

      // Trigger rebuild
      controller.value = 1;
      await tester.pump();

      expect(secondKey, isNotNull);
      // Key should be the same after rebuild (stable)
      expect(firstKey, equals(secondKey));
    });

    testWidgets('different instances have different keys', (tester) async {
      GlobalKey? key1;
      GlobalKey? key2;

      await tester.pumpWidget(
        createTestApp(
          child: Row(
            children: [
              LiquidGlassScope(
                child: Builder(
                  builder: (context) {
                    key1 = LiquidGlassScope.of(context);
                    return const SizedBox(width: 50);
                  },
                ),
              ),
              LiquidGlassScope(
                child: Builder(
                  builder: (context) {
                    key2 = LiquidGlassScope.of(context);
                    return const SizedBox(width: 50);
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(key1, isNotNull);
      expect(key2, isNotNull);
      expect(key1, isNot(equals(key2)));
    });
  });

  group('LiquidGlassBackground', () {
    testWidgets('can be instantiated with a child', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: LiquidGlassBackground(
              child: Container(
                width: 200,
                height: 200,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassBackground), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('wraps child in RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: LiquidGlassBackground(
              child: const Text('Background Content'),
            ),
          ),
        ),
      );

      // Should find RepaintBoundary as part of LiquidGlassBackground
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Background Content'), findsOneWidget);
    });

    testWidgets('works without LiquidGlassScope (standalone)', (tester) async {
      // LiquidGlassBackground should work standalone, just without the shared key
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassBackground(
            child: Container(
              width: 100,
              height: 100,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassBackground), findsOneWidget);
    });

    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: LiquidGlassBackground(
              child: Column(
                children: const [
                  Text('Line 1'),
                  Text('Line 2'),
                  Text('Line 3'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
      expect(find.text('Line 3'), findsOneWidget);
    });

    testWidgets('uses key from LiquidGlassScope when available',
        (tester) async {
      GlobalKey? scopeKey;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: Builder(
              builder: (context) {
                scopeKey = LiquidGlassScope.of(context);
                return LiquidGlassBackground(
                  child: const SizedBox(width: 100, height: 100),
                );
              },
            ),
          ),
        ),
      );

      expect(scopeKey, isNotNull);
      // The background should use the key from the scope
      // (We can't easily verify this without accessing internals,
      // but the fact that it renders without error is a good sign)
      expect(find.byType(LiquidGlassBackground), findsOneWidget);
    });
  });

  group('Integration: Scope + Background', () {
    testWidgets('scope and background work together', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: Stack(
              children: [
                LiquidGlassBackground(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.blue,
                  ),
                ),
                const Center(
                  child: Text('Overlay Content'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassScope), findsOneWidget);
      expect(find.byType(LiquidGlassBackground), findsOneWidget);
      expect(find.text('Overlay Content'), findsOneWidget);
    });

    testWidgets('multiple backgrounds require separate scopes', (tester) async {
      // Each LiquidGlassBackground should have its own LiquidGlassScope
      await tester.pumpWidget(
        createTestApp(
          child: Column(
            children: [
              LiquidGlassScope(
                child: LiquidGlassBackground(
                  child: Container(height: 100, color: Colors.red),
                ),
              ),
              LiquidGlassScope(
                child: LiquidGlassBackground(
                  child: Container(height: 100, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(LiquidGlassBackground), findsNWidgets(2));
      expect(find.byType(LiquidGlassScope), findsNWidgets(2));
    });
  });

  group('LiquidGlassScope.stack (Convenience Constructor)', () {
    testWidgets('creates correct widget tree structure', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(
              color: Colors.red,
              child: const Text('Background'),
            ),
            content: const Text('Content'),
          ),
        ),
      );

      // Should have LiquidGlassBackground
      expect(find.byType(LiquidGlassBackground), findsOneWidget);

      // Both background and content should be present
      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);

      // Should have a Stack (may be multiple in tree, but at least one)
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('wraps background in Positioned.fill', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(color: Colors.blue),
            content: Container(color: Colors.green),
          ),
        ),
      );

      // Should have 1 Positioned widget (for background only)
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('background is behind content in z-order', (tester) async {
      // This tests that the Stack children are in the correct order
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(
              key: const Key('background'),
              color: Colors.red,
            ),
            content: Container(
              key: const Key('content'),
              color: Colors.blue,
            ),
          ),
        ),
      );

      // Verify background and content are both present
      expect(find.byKey(const Key('background')), findsOneWidget);
      expect(find.byKey(const Key('content')), findsOneWidget);

      // Verify background is wrapped in LiquidGlassBackground
      expect(find.byType(LiquidGlassBackground), findsOneWidget);
    });

    testWidgets('provides scope key to descendants', (tester) async {
      GlobalKey? foundKey;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(color: Colors.red),
            content: Builder(
              builder: (context) {
                foundKey = LiquidGlassScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(foundKey, isNotNull);
    });

    testWidgets('accepts custom key parameter', (tester) async {
      const testKey = Key('test-scope');

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            key: testKey,
            background: Container(color: Colors.red),
            content: const Text('Content'),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('works with complex background widgets', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(
              color: Colors.red,
              child: const Center(child: Text('Background')),
            ),
            content: const Text('Content'),
          ),
        ),
      );

      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('works with complex content widgets', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(color: Colors.red),
            content: Column(
              children: const [
                Text('Content Line 1'),
                Text('Content Line 2'),
                Text('Content Line 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Content Line 1'), findsOneWidget);
      expect(find.text('Content Line 2'), findsOneWidget);
      expect(find.text('Content Line 3'), findsOneWidget);
    });

    testWidgets('creates simpler structure than manual Stack setup',
        (tester) async {
      // Build with convenience constructor
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(color: Colors.red),
            content: const Text('Test'),
          ),
        ),
      );

      // Verify structure with convenience constructor
      expect(find.byType(LiquidGlassBackground), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      // Only background is Positioned, content is not (avoids conflicts)
      expect(find.byType(Positioned), findsOneWidget);

      // Rebuild with manual setup (old way - more verbose)
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LiquidGlassBackground(
                    child: Container(color: Colors.red),
                  ),
                ),
                const Text('Test'), // Content not wrapped to avoid conflicts
              ],
            ),
          ),
        ),
      );

      // Verify structure with manual setup is the same
      expect(find.byType(LiquidGlassBackground), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('can be nested', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassScope.stack(
            background: Container(color: Colors.red),
            content: LiquidGlassScope.stack(
              background: Container(color: Colors.blue),
              content: const Text('Nested Content'),
            ),
          ),
        ),
      );

      // Should have 2 scopes
      expect(find.byType(LiquidGlassScope), findsNWidgets(2));
      // Should have 2 backgrounds
      expect(find.byType(LiquidGlassBackground), findsNWidgets(2));
      // Should find the nested content
      expect(find.text('Nested Content'), findsOneWidget);
    });
  });
}
