import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassFullScreenCover & showGlassFullScreenCover', () {
    testWidgets('renders content and top bar at rest', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open Cover'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => const GlassFullScreenCover(
                      title: Text('Account Settings'),
                      child: Center(child: Text('Cover Body Content')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cover Body Content'), findsNothing);

      // Tap to open cover
      await tester.tap(find.text('Open Cover'));
      await tester.pumpAndSettle();

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Cover Body Content'), findsOneWidget);
      expect(find.byType(GlassFullScreenCoverBar), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    });

    testWidgets('tapping close button dismisses cover', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => GlassFullScreenCover(
                      title: const Text('Profile'),
                      onDismiss: () => dismissed = true,
                      child: const Text('Profile Details'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Details'), findsOneWidget);

      // Tap close button (xmark icon)
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();

      expect(find.text('Profile Details'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets('renders text close button label (Done) and dismisses on tap',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => const GlassFullScreenCover(
                      title: Text('Terms of Service'),
                      closeButtonLabel: 'Done',
                      child: Text('Terms Body'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Terms Body'), findsNothing);
    });

    testWidgets('leading close button position works properly', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => const GlassFullScreenCover(
                      title: Text('New Document'),
                      closeButtonPosition:
                          GlassFullScreenCoverClosePosition.leading,
                      child: Text('Editor'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();

      expect(find.text('Editor'), findsNothing);
    });

    testWidgets('swipe down past dismissThreshold dismisses cover',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => GlassFullScreenCover(
                      title: const Text('Swipe Test'),
                      dismissThreshold: 100.0,
                      onDismiss: () => dismissed = true,
                      child: const Center(child: Text('Content to Drag')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Content to Drag'), findsOneWidget);

      // Drag downward 150 pixels from near top
      final center = tester.getCenter(find.text('Swipe Test'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Content to Drag'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets('swipe down below dismissThreshold springs back',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => GlassFullScreenCover(
                      title: const Text('Spring Test'),
                      dismissThreshold: 150.0,
                      onDismiss: () => dismissed = true,
                      child: const Center(child: Text('Content')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Drag downward only 30 pixels (well below 150 threshold)
      final center = tester.getCenter(find.text('Spring Test'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Should still be open
      expect(find.text('Content'), findsOneWidget);
      expect(dismissed, isFalse);
    });

    testWidgets('enableSwipeToDismiss: false disables dragging down',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => const GlassFullScreenCover(
                      title: Text('No Swipe'),
                      enableSwipeToDismiss: false,
                      child: Center(child: Text('Fixed Content')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.text('No Swipe'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Should not have dismissed
      expect(find.text('Fixed Content'), findsOneWidget);
    });

    testWidgets('declarative .glassFullScreenCover extension works',
        (tester) async {
      bool isPresented = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    child: const Text('Toggle Cover'),
                    onPressed: () => setState(() => isPresented = !isPresented),
                  ),
                ).glassFullScreenCover(
                  isPresented: isPresented,
                  onDismiss: () => setState(() => isPresented = false),
                  content: (context) => const GlassFullScreenCover(
                    title: Text('Declarative Modal'),
                    child: Center(child: Text('Declarative Body')),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Declarative Body'), findsNothing);

      // Toggle to open
      await tester.tap(find.text('Toggle Cover'));
      await tester.pumpAndSettle();

      expect(find.text('Declarative Body'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();

      expect(find.text('Declarative Body'), findsNothing);
      expect(isPresented, isFalse);
    });

    testWidgets('custom leading and trailing accessories render in top bar',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open Custom'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => GlassFullScreenCover(
                      leading: const Text('CancelAction'),
                      trailing: const Text('SaveAction'),
                      title: const Text('TitleAction'),
                      showCloseButton: false,
                      child: const Text('Custom Content'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Custom'));
      await tester.pumpAndSettle();

      expect(find.text('CancelAction'), findsOneWidget);
      expect(find.text('SaveAction'), findsOneWidget);
      expect(find.text('TitleAction'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsNothing);
    });

    testWidgets(
        'high velocity downward fling dismisses cover even if offset < threshold',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => GlassFullScreenCover(
                      title: const Text('Fling Test'),
                      dismissThreshold: 300.0, // High threshold
                      velocityThreshold: 500.0,
                      onDismiss: () => dismissed = true,
                      child: const Center(child: Text('Fling Body')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Fling Body'), findsOneWidget);

      // Fling down quickly with velocity > 800
      await tester.fling(find.text('Fling Test'), const Offset(0, 80), 1000.0);
      await tester.pumpAndSettle();

      expect(find.text('Fling Body'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets(
        'declarative glassFullScreenCover presents and dismisses via state',
        (tester) async {
      Widget buildApp({required bool isPresented}) {
        return CupertinoApp(
          home: CupertinoPageScaffold(
            child: const Center(
              child: Text('Main Screen'),
            ).glassFullScreenCover(
              isPresented: isPresented,
              content: (context) => const Text('Declarative Cover Content'),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildApp(isPresented: false));
      expect(find.text('Declarative Cover Content'), findsNothing);

      // Present
      await tester.pumpWidget(buildApp(isPresented: true));
      await tester.pumpAndSettle();

      expect(find.text('Declarative Cover Content'), findsOneWidget);

      // Dismiss declaratively via didUpdateWidget
      await tester.pumpWidget(buildApp(isPresented: false));
      await tester.pumpAndSettle();

      expect(find.text('Declarative Cover Content'), findsNothing);
    });

    testWidgets(
        'declarative glassFullScreenCover with onDismiss in dark mode dismisses via swipe',
        (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: const Text('Main Screen').glassFullScreenCover(
              isPresented: true,
              onDismiss: () => dismissed = true,
              content: (context) => const Text('Swipable Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Swipable Content'), findsOneWidget);

      await tester.fling(
          find.text('Swipable Content'), const Offset(0, 300), 1000.0);
      await tester.pumpAndSettle();

      expect(find.text('Swipable Content'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets(
        'GlassFullScreenCoverBar renders drag handle in light and dark mode',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: const CupertinoPageScaffold(
            child: GlassFullScreenCoverBar(
              showDragHandle: true,
              title: Text('Title With Handle'),
            ),
          ),
        ),
      );

      expect(find.text('Title With Handle'), findsOneWidget);

      // Switch to light mode
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: const CupertinoPageScaffold(
            child: GlassFullScreenCoverBar(
              showDragHandle: true,
              title: Text('Title With Handle'),
            ),
          ),
        ),
      );

      expect(find.text('Title With Handle'), findsOneWidget);
    });

    testWidgets('upward drag applies rubber-band resistance damping',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => const GlassFullScreenCover(
                      title: Text('Damping Test'),
                      child: Text('Damping Body'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Drag upward (negative dy)
      await tester.drag(find.text('Damping Test'), const Offset(0, -60));
      await tester.pumpAndSettle();

      // Cover should still be visible and spring back
      expect(find.text('Damping Body'), findsOneWidget);
    });

    testWidgets(
        'declarative cover with isPresented: true initially presents on mount',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: const Text('Initial Screen').glassFullScreenCover(
              isPresented: true,
              content: (context) => const Text('Initial Cover Body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initial Cover Body'), findsOneWidget);
    });

    testWidgets(
        'drag past threshold and drag back up resets threshold crossing',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                child: const Text('Open Threshold Test'),
                onPressed: () {
                  showGlassFullScreenCover(
                    context: context,
                    builder: (context) => const GlassFullScreenCover(
                      title: Text('Threshold Title'),
                      dismissThreshold: 100.0,
                      child: Text('Threshold Body'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Threshold Test'));
      await tester.pumpAndSettle();

      // Start drag down past threshold (120px)
      final gesture = await tester
          .startGesture(tester.getCenter(find.text('Threshold Title')));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();

      // Move back up above threshold (-50px)
      await gesture.moveBy(const Offset(0, -50));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Threshold Body'), findsOneWidget);
    });
  });
}
