import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class _Park {
  const _Park(this.name, this.location);
  final String name;
  final String location;
}

void main() {
  group('GlassNavigationStack & GlassNavigationLink', () {
    testWidgets('renders root widget at rest', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassNavigationStack(
            root: const CupertinoPageScaffold(
              child: Center(child: Text('Home Root Screen')),
            ),
          ),
        ),
      );

      expect(find.text('Home Root Screen'), findsOneWidget);
    });

    testWidgets(
        'GlassNavigationLink with explicit destination pushes screen on tap',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassNavigationStack(
            root: CupertinoPageScaffold(
              child: Center(
                child: GlassNavigationLink(
                  title: const Text('Go to Detail'),
                  destination: (context) => const CupertinoPageScaffold(
                    child: Center(child: Text('Detail Screen Reached')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Go to Detail'), findsOneWidget);
      expect(find.text('Detail Screen Reached'), findsNothing);

      // Tap link
      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Screen Reached'), findsOneWidget);
    });

    testWidgets('typed navigation via GlassNavigationPath and destinations map',
        (tester) async {
      final path = GlassNavigationPath();

      await tester.pumpWidget(
        CupertinoApp(
          home: GlassNavigationStack(
            path: path,
            destinations: {
              _Park: (context, park) {
                final p = park as _Park;
                return CupertinoPageScaffold(
                  child:
                      Center(child: Text('Park: ${p.name} in ${p.location}')),
                );
              },
            },
            root: CupertinoPageScaffold(
              child: Center(
                child: GlassNavigationLink<_Park>(
                  title: const Text('Visit Yosemite'),
                  value: const _Park('Yosemite', 'California'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Visit Yosemite'), findsOneWidget);
      expect(find.text('Park: Yosemite in California'), findsNothing);

      // Tap link with typed value
      await tester.tap(find.text('Visit Yosemite'));
      await tester.pumpAndSettle();

      expect(find.text('Park: Yosemite in California'), findsOneWidget);
      expect(path.length, 1);

      // Pop path programmatically
      path.pop();
      await tester.pumpAndSettle();

      expect(find.text('Park: Yosemite in California'), findsNothing);
      expect(find.text('Visit Yosemite'), findsOneWidget);
    });

    testWidgets(
        'GlassNavigationLink renders GlassListTile with chevron by default',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassNavigationLink(
              leading: const Icon(CupertinoIcons.star),
              title: const Text('Starred Items'),
              subtitle: const Text('Favorites'),
              destination: (context) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(GlassListTile), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
      expect(find.text('Starred Items'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });

    testWidgets('GlassNavigationLink supports custom child widget',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassNavigationStack(
            root: CupertinoPageScaffold(
              child: GlassNavigationLink(
                destination: (context) => const CupertinoPageScaffold(
                  child: Center(child: Text('Custom Target Screen')),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Text('Custom Clickable Pill'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Clickable Pill'), findsOneWidget);
      expect(find.byType(GlassListTile), findsNothing);

      await tester.tap(find.text('Custom Clickable Pill'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Target Screen'), findsOneWidget);
    });

    test('GlassNavigationPath helpers: isEmpty, isNotEmpty, popToRoot, clear',
        () {
      final path = GlassNavigationPath();
      expect(path.isEmpty, isTrue);
      expect(path.isNotEmpty, isFalse);

      path.append('item 1');
      path.append('item 2');
      expect(path.isEmpty, isFalse);
      expect(path.isNotEmpty, isTrue);
      expect(path.length, 2);

      path.popToRoot();
      expect(path.isEmpty, isTrue);
      expect(path.length, 0);

      path.append('item A');
      expect(path.isNotEmpty, isTrue);
      path.clear();
      expect(path.isEmpty, isTrue);
    });

    testWidgets('GlassNavigationStack.of and programmatic push / pop',
        (tester) async {
      late GlassNavigationStackState stackState;

      await tester.pumpWidget(
        CupertinoApp(
          home: GlassNavigationStack(
            root: Builder(
              builder: (context) {
                stackState = GlassNavigationStack.of(context);
                return CupertinoPageScaffold(
                  child: Center(
                    child: CupertinoButton(
                      child: const Text('Push Screen'),
                      onPressed: () {
                        stackState.push(
                          const CupertinoPageScaffold(
                            child: Center(child: Text('Pushed Screen Content')),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(stackState.navigatorKey, isNotNull);
      expect(find.text('Push Screen'), findsOneWidget);

      await tester.tap(find.text('Push Screen'));
      await tester.pumpAndSettle();

      expect(find.text('Pushed Screen Content'), findsOneWidget);

      // Pop using stackState
      stackState.pop();
      await tester.pumpAndSettle();

      expect(find.text('Pushed Screen Content'), findsNothing);
      expect(find.text('Push Screen'), findsOneWidget);

      // Push when navigator is unmounted returns null
      await tester.pumpWidget(const SizedBox());
      final nullPush = await stackState.push(const SizedBox());
      expect(nullPush, isNull);
    });

    testWidgets('GlassNavigationStack.of throws assertion outside of stack',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              expect(
                () => GlassNavigationStack.of(context),
                throwsA(isA<AssertionError>()),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets(
        'GlassNavigationStack didUpdateWidget swaps navigatorKey and path',
        (tester) async {
      final key1 = GlobalKey<NavigatorState>();
      final key2 = GlobalKey<NavigatorState>();
      final path1 = GlassNavigationPath();
      final path2 = GlassNavigationPath();

      await tester.pumpWidget(
        CupertinoApp(
          home: GlassNavigationStack(
            navigatorKey: key1,
            path: path1,
            root: const Text('Root 1'),
          ),
        ),
      );

      expect(find.text('Root 1'), findsOneWidget);

      // Update widget with new key and path
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassNavigationStack(
            navigatorKey: key2,
            path: path2,
            root: const Text('Root 2'),
          ),
        ),
      );

      expect(find.text('Root 2'), findsOneWidget);
    });

    testWidgets(
        'GlassNavigationLink without stack pushes directly via Navigator.of',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GlassNavigationLink(
              title: const Text('Standard Nav Link'),
              destination: (context) => const CupertinoPageScaffold(
                child: Center(child: Text('Standard Destination')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Standard Nav Link'), findsOneWidget);
      await tester.tap(find.text('Standard Nav Link'));
      await tester.pumpAndSettle();

      expect(find.text('Standard Destination'), findsOneWidget);
    });

    testWidgets('navigationTitle extension wraps with header semantics',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: const Text('Page Body').navigationTitle('Settings Header'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.text('Page Body'));
      expect(semantics.label, contains('Settings Header'));
    });
  });
}
