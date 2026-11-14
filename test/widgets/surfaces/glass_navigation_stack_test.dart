import 'package:cupertino_ui/cupertino_ui.dart';
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
      },
    );

    testWidgets(
      'typed navigation via GlassNavigationPath and destinations map',
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
                    child: Center(
                      child: Text('Park: ${p.name} in ${p.location}'),
                    ),
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
      },
    );

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
      },
    );

    testWidgets('GlassNavigationLink supports custom child widget', (
      tester,
    ) async {
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

    test(
      'GlassNavigationPath helpers: isEmpty, isNotEmpty, popToRoot, clear',
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
      },
    );

    testWidgets('GlassNavigationStack.of and programmatic push / pop', (
      tester,
    ) async {
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

    testWidgets('GlassNavigationStack.of throws assertion outside of stack', (
      tester,
    ) async {
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
      },
    );

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
      },
    );

    testWidgets('navigationTitle extension wraps with header semantics', (
      tester,
    ) async {
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

    testWidgets(
      'supports recursive Push Deeper and syncs path when Navigator pops',
      (tester) async {
        final path = GlassNavigationPath();

        Widget buildDetail(BuildContext context, String value) {
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(middle: Text('Detail')),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value),
                  CupertinoButton(
                    onPressed: () {
                      GlassNavigationStack.of(context).effectivePath
                          .append('$value -> Deeper');
                    },
                    child: const Text('Push Deeper'),
                  ),
                ],
              ),
            ),
          );
        }

        await tester.pumpWidget(
          GlassTheme(
            data: const GlassThemeData.ios27(),
            child: CupertinoApp(
              home: GlassNavigationStack(
                path: path,
                destinations: {
                  String: (context, val) => buildDetail(context, val as String),
                },
                root: const CupertinoPageScaffold(
                  child: Center(
                    child: GlassNavigationLink<String>(
                      value: 'Level 1: Optics Architecture',
                      title: Text('Optics Architecture'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Push Level 1
        await tester.tap(find.text('Optics Architecture'));
        await tester.pumpAndSettle();
        expect(find.text('Level 1: Optics Architecture'), findsOneWidget);
        expect(path.length, 1);

        // Push Deeper -> Level 2
        await tester.tap(find.text('Push Deeper'));
        await tester.pumpAndSettle();
        expect(
          find.text('Level 1: Optics Architecture -> Deeper'),
          findsOneWidget,
        );
        expect(path.length, 2);

        // Push Deeper -> Level 3
        await tester.tap(find.text('Push Deeper'));
        await tester.pumpAndSettle();
        expect(
          find.text('Level 1: Optics Architecture -> Deeper -> Deeper'),
          findsOneWidget,
        );
        expect(path.length, 3);

        // Pop via Navigator (simulating back button / swipe-back) -> Level 2
        final stackState = tester.state<GlassNavigationStackState>(
          find.byType(GlassNavigationStack),
        );
        stackState.pop();
        await tester.pumpAndSettle();
        expect(path.length, 2);
        expect(
          find.text('Level 1: Optics Architecture -> Deeper'),
          findsOneWidget,
        );

        // Pop via path.pop() -> Level 1
        path.pop();
        await tester.pumpAndSettle();
        expect(path.length, 1);
        expect(find.text('Level 1: Optics Architecture'), findsOneWidget);

        // Pop to root
        path.popToRoot();
        await tester.pumpAndSettle();
        expect(path.isEmpty, isTrue);
        expect(find.text('Optics Architecture'), findsOneWidget);
      },
    );

    group('edge cases', () {
      Widget detail(BuildContext context, Object? value) =>
          CupertinoPageScaffold(child: Center(child: Text('Detail $value')));

      Widget app(
        GlassNavigationPath path, {
        TextDirection direction = TextDirection.ltr,
        Widget? root,
      }) {
        return CupertinoApp(
          builder: (context, child) =>
              Directionality(textDirection: direction, child: child!),
          home: GlassNavigationStack(
            path: path,
            destinations: {String: detail},
            root:
                root ??
                const CupertinoPageScaffold(child: Center(child: Text('Root'))),
          ),
        );
      }

      testWidgets('rapid appends push every route in order', (tester) async {
        final path = GlassNavigationPath();
        await tester.pumpWidget(app(path));

        path
          ..append('a')
          ..append('b')
          ..append('c');
        await tester.pumpAndSettle();

        expect(path.length, 3);
        expect(find.text('Detail c'), findsOneWidget);

        path.popToRoot();
        await tester.pumpAndSettle();
        expect(find.text('Root'), findsOneWidget);
        expect(path.isEmpty, isTrue);
      });

      testWidgets('append racing a pop in the same frame stays in sync', (
        tester,
      ) async {
        final path = GlassNavigationPath();
        await tester.pumpWidget(app(path));

        path.append('a');
        await tester.pumpAndSettle();

        path
          ..pop()
          ..append('b');
        await tester.pumpAndSettle();

        expect(path.length, 1);
        expect(find.text('Detail b'), findsOneWidget);
        expect(find.text('Detail a'), findsNothing);

        path.pop();
        await tester.pumpAndSettle();
        expect(find.text('Root'), findsOneWidget);
      });

      testWidgets('swapping the path reconciles the navigator', (tester) async {
        final first = GlassNavigationPath();
        final second = GlassNavigationPath()..append('x');
        await tester.pumpWidget(app(first));
        first.append('a');
        await tester.pumpAndSettle();
        expect(find.text('Detail a'), findsOneWidget);

        // A shorter (here: different) path pops back and re-pushes to match.
        await tester.pumpWidget(app(second));
        await tester.pumpAndSettle();

        expect(find.text('Detail x'), findsOneWidget);
        expect(second.length, 1);

        // The old path no longer drives the stack.
        first.append('ignored');
        await tester.pumpAndSettle();
        expect(find.text('Detail ignored'), findsNothing);
        expect(find.text('Detail x'), findsOneWidget);

        // Swapping to an empty path returns to the root.
        await tester.pumpWidget(app(GlassNavigationPath()));
        await tester.pumpAndSettle();
        expect(find.text('Root'), findsOneWidget);
      });

      testWidgets(
        'a cancelled swipe-back keeps the path; a completed one pops it',
        (tester) async {
          final path = GlassNavigationPath();
          await tester.pumpWidget(app(path));
          path.append('a');
          await tester.pumpAndSettle();
          expect(path.length, 1);

          // Short drag from the left edge, then release: route stays.
          var gesture = await tester.startGesture(const Offset(2, 300));
          await gesture.moveBy(const Offset(40, 0));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();
          expect(path.length, 1);
          expect(find.text('Detail a'), findsOneWidget);

          // Long drag: route pops and the path follows.
          gesture = await tester.startGesture(const Offset(2, 300));
          await gesture.moveBy(const Offset(400, 0));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();
          expect(path.length, 0);
          expect(find.text('Root'), findsOneWidget);
        },
      );

      testWidgets('GlassAppBar.pinned(padding:) moves the pinned back button', (
        tester,
      ) async {
        Future<double> backButtonX(
          WidgetTester tester, {
          EdgeInsetsGeometry? padding,
          TextDirection direction = TextDirection.ltr,
        }) async {
          final path = GlassNavigationPath();
          await tester.pumpWidget(
            CupertinoApp(
              builder: (context, child) =>
                  Directionality(textDirection: direction, child: child!),
              home: GlassNavigationStack(
                path: path,
                destinations: {
                  String: (context, v) => CupertinoPageScaffold(
                    child: Column(
                      children: [
                        GlassAppBar.pinned(
                          title: const Text('Detail'),
                          padding: padding,
                        ),
                      ],
                    ),
                  ),
                },
                root: const CupertinoPageScaffold(child: Text('Root')),
              ),
            ),
          );
          path.append('a');
          await tester.pumpAndSettle();
          return tester.getCenter(find.byIcon(CupertinoIcons.back)).dx;
        }

        final defaultX = await backButtonX(tester);
        final wideX = await backButtonX(
          tester,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        );
        // An explicit 8 is the same as the default, not "unset".
        final eightX = await backButtonX(
          tester,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );
        expect(wideX - defaultX, closeTo(8, 0.01));
        expect(eightX, closeTo(defaultX, 0.01));

        // The leading edge wins under RTL: the button mirrors to the right.
        final rtlX = await backButtonX(
          tester,
          padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
          direction: TextDirection.rtl,
        );
        expect(rtlX, greaterThan(400));
      });

      testWidgets('works under RTL and flips chevron to chevron_left', (
        tester,
      ) async {
        final path = GlassNavigationPath();
        await tester.pumpWidget(
          app(
            path,
            direction: TextDirection.rtl,
            root: const CupertinoPageScaffold(
              child: Center(
                child: GlassNavigationLink<String>(
                  title: Text('RTL Link'),
                  value: 'a',
                ),
              ),
            ),
          ),
        );
        expect(find.byIcon(CupertinoIcons.chevron_left), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.chevron_right), findsNothing);

        path.append('a');
        await tester.pumpAndSettle();
        expect(find.text('Detail a'), findsOneWidget);

        path.pop();
        await tester.pumpAndSettle();
        expect(find.text('RTL Link'), findsOneWidget);
        expect(path.isEmpty, isTrue);
      });

      testWidgets('resetting navigatorKey to null allocates a fresh key', (
        tester,
      ) async {
        final customKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          CupertinoApp(
            home: GlassNavigationStack(
              navigatorKey: customKey,
              root: const Text('Root'),
            ),
          ),
        );
        final state = tester.state<GlassNavigationStackState>(
          find.byType(GlassNavigationStack),
        );
        expect(state.navigatorKey, same(customKey));

        await tester.pumpWidget(
          const CupertinoApp(home: GlassNavigationStack(root: Text('Root'))),
        );
        expect(state.navigatorKey, isNot(same(customKey)));
      });

      testWidgets(
        '.navigationTitle drives GlassAppBar.pinned title from body or ancestor',
        (tester) async {
          // 1. SwiftUI pattern: .navigationTitle attached inside GlassScaffold.body
          await tester.pumpWidget(
            CupertinoApp(
              home: GlassScaffold(
                appBar: const GlassAppBar.pinned(),
                body: const Center(child: Text('Body Content'))
                    .navigationTitle('Body Driven Title'),
              ),
            ),
          );
          expect(find.text('Body Driven Title'), findsOneWidget);

          // Dynamic update of .navigationTitle inside body
          await tester.pumpWidget(
            CupertinoApp(
              home: GlassScaffold(
                appBar: const GlassAppBar.pinned(),
                body: const Center(child: Text('Body Content'))
                    .navigationTitle('Updated Body Title'),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('Updated Body Title'), findsOneWidget);

          // 2. Ancestor pattern: .navigationTitle wrapping GlassScaffold
          await tester.pumpWidget(
            CupertinoApp(
              home: const GlassScaffold(
                appBar: GlassAppBar.pinned(),
                body: Center(child: Text('Body Content')),
              ).navigationTitle('Ancestor Driven Title'),
            ),
          );
          expect(find.text('Ancestor Driven Title'), findsOneWidget);
        },
      );

      testWidgets(
        'resolveGlassSolidSurfaceColor shifts to #2C2C2E in elevated dark mode',
        (tester) async {
          late Color baseColor;
          late Color elevatedColor;

          await tester.pumpWidget(
            GlassTheme(
              data: const GlassThemeData(brightness: Brightness.dark),
              child: CupertinoApp(
                home: Builder(
                  builder: (context) {
                    baseColor = resolveGlassSolidSurfaceColor(context);
                    return CupertinoUserInterfaceLevel(
                      data: CupertinoUserInterfaceLevelData.elevated,
                      child: Builder(
                        builder: (innerContext) {
                          elevatedColor = resolveGlassSolidSurfaceColor(
                            innerContext,
                          );
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );

          expect(baseColor, kGlassSolidSurfaceDark);
          expect(elevatedColor, kGlassSolidSurfaceDarkElevated);
        },
      );
    });

    test('GlassThemeData.ios27 applies ios27Light and ios27Dark presets', () {
      final runtimeBrightness = [Brightness.dark].first;
      final runtimeTheme = GlassThemeData.ios27(brightness: runtimeBrightness);
      expect(runtimeTheme.brightness, Brightness.dark);

      const theme = GlassThemeData.ios27();
      final lightApplied = theme.light.settings!.applyTo(
        const LiquidGlassSettings(),
      );
      final darkApplied = theme.dark.settings!.applyTo(
        const LiquidGlassSettings(),
      );

      expect(lightApplied.blur, LiquidGlassSettings.ios27Light.blur);
      expect(lightApplied.thickness, LiquidGlassSettings.ios27Light.thickness);
      expect(
        lightApplied.chromaticAberration,
        LiquidGlassSettings.ios27Light.chromaticAberration,
      );
      expect(
        lightApplied.shadowElevation,
        LiquidGlassSettings.ios27Light.shadowElevation,
      );
      expect(darkApplied.blur, LiquidGlassSettings.ios27Dark.blur);
      expect(darkApplied.thickness, LiquidGlassSettings.ios27Dark.thickness);
      expect(
        darkApplied.shadowElevation,
        LiquidGlassSettings.ios27Dark.shadowElevation,
      );
    });

    testWidgets(
      'initial non-empty path, navigatorKey swap, and Object destination fallback work',
      (tester) async {
        final path = GlassNavigationPath(['initial']);
        final key1 = GlobalKey<NavigatorState>();
        final key2 = GlobalKey<NavigatorState>();

        Widget buildStack(GlobalKey<NavigatorState> navKey) {
          return CupertinoApp(
            home: GlassNavigationStack(
              navigatorKey: navKey,
              path: path,
              destinations: {
                Object: (context, value) => CupertinoPageScaffold(
                  child: Center(child: Text('Fallback $value')),
                ),
              },
              root: const CupertinoPageScaffold(
                child: Center(child: Text('Root Page')),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildStack(key1));
        await tester.pumpAndSettle();

        final state = tester.state<GlassNavigationStackState>(
          find.byType(GlassNavigationStack),
        );
        expect(state.path, same(path));
        expect(find.text('Fallback initial'), findsOneWidget);

        await tester.pumpWidget(buildStack(key2));
        await tester.pumpAndSettle();
        expect(find.text('Fallback initial'), findsOneWidget);
      },
    );

    testWidgets(
      'GlassNavigationStack and GlassScaffold coordinate transitionCornerRadius without double clipping',
      (tester) async {
        final path = GlassNavigationPath();

        await tester.pumpWidget(
          CupertinoApp(
            home: GlassNavigationStack(
              path: path,
              transitionCornerRadius: 48.0,
              destinations: {
                String: (context, value) => GlassScaffold(
                  transitionCornerRadius: value == 'custom' ? 24.0 : null,
                  appBar: const GlassAppBar.pinned(title: Text('Detail')),
                  body: Center(child: Text('Detail: $value')),
                ),
              },
              root: const GlassScaffold(
                appBar: GlassAppBar.pinned(title: Text('Root')),
                body: Center(child: Text('Root Body')),
              ),
            ),
          ),
        );

        List<ClipRSuperellipse> activePageClips() => tester
            .widgetList<ClipRSuperellipse>(
              find.descendant(
                of: find.byType(GlassPageTransitionClip, skipOffstage: false),
                matching: find.byType(ClipRSuperellipse, skipOffstage: false),
                skipOffstage: false,
              ),
            )
            .where((c) => c.clipBehavior != Clip.none)
            .toList();

        // At rest: zero active page transition clips
        expect(activePageClips(), isEmpty);

        // Push 'default': inherits 48.0 from stack, only ONE active clip (no double clipping)
        path.append('default');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        var midClips = activePageClips();
        expect(midClips.length, 1);
        expect(midClips.single.borderRadius, BorderRadius.circular(48.0));

        await tester.pumpAndSettle();
        expect(activePageClips(), isEmpty);

        // Push 'custom': overrides stack's 48.0 with 24.0, only ONE active clip
        path.append('custom');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        midClips = activePageClips();
        expect(midClips.length, 1);
        expect(midClips.single.borderRadius, BorderRadius.circular(24.0));

        await tester.pumpAndSettle();
        expect(activePageClips(), isEmpty);

        // Pop back: mid-pop clips the popping route, then unclips at rest
        path.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(activePageClips().length, 1);

        await tester.pumpAndSettle();
        expect(activePageClips(), isEmpty);
      },
    );

    testWidgets(
      'GlassNavigationLink forwards transitionCornerRadius outside GlassNavigationStack',
      (tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: GlassNavigationLink(
                  title: const Text('Push Custom Radius'),
                  transitionCornerRadius: 30.0,
                  destination: (_) => const CupertinoPageScaffold(
                    child: Center(child: Text('Destination')),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push Custom Radius'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final activeClips = tester
            .widgetList<ClipRSuperellipse>(
              find.byType(ClipRSuperellipse, skipOffstage: false),
            )
            .where((c) => c.clipBehavior != Clip.none)
            .toList();

        expect(activeClips, isNotEmpty);
        expect(activeClips.first.borderRadius, BorderRadius.circular(30.0));

        await tester.pumpAndSettle();
      },
    );
  });
}
