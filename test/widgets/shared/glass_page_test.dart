import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassPage', () {
    testWidgets('renders child directly when no background provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassPage(
            child: const Scaffold(
              body: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(GlassBackgroundSource), findsNothing);

      // Without background, Scaffold is not wrapped in Theme override
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets(
        'passes child through without Theme wrapper when background provided in MaterialApp',
        (tester) async {
      // GlassPage no longer injects a Theme to force Scaffold transparency.
      // GlassScaffold handles its own background color on CupertinoPageScaffold.
      // Users who use GlassPage with a raw Scaffold must set backgroundColor
      // explicitly if they want transparency.
      await tester.pumpWidget(
        MaterialApp(
          home: GlassPage(
            background: const SizedBox(key: Key('bg')),
            child: Scaffold(
              body: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('bg')), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      // No Theme injection around child — GlassPage is now a pure host-agnostic wrapper.
      final glassPageFinder = find.byType(GlassPage);
      final themesInsidePage = find.descendant(
        of: glassPageFinder,
        matching: find.byType(Theme),
      );
      // Any Theme found inside GlassPage should not be from GlassPage itself
      // (i.e., no scoped GlassTheme themeOverride wrapper — we didn't set one).
      expect(
          tester.widgetList<Theme>(themesInsidePage).where(
              (t) => t.data.scaffoldBackgroundColor == const Color(0x00000000)),
          isEmpty);
    });

    testWidgets('works in pure CupertinoApp host with no Material ancestor',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassPage(
            background: const SizedBox(key: Key('bg')),
            child: const CupertinoPageScaffold(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('bg')), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('respects themeOverride parameter', (tester) async {
      final overrideTheme = GlassThemeData(
        light: const GlassThemeVariant(settings: GlassThemeSettings(blur: 100)),
        dark: const GlassThemeVariant(settings: GlassThemeSettings(blur: 100)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GlassPage(
            themeOverride: overrideTheme,
            child: const Scaffold(
              body: Text('Content'),
            ),
          ),
        ),
      );

      final themeData = GlassTheme.of(tester.element(find.byType(Scaffold)));
      expect(themeData.data.light.settings?.blur, 100);
    });

    testWidgets('handles GlassStatusBarStyle.dark and light appropriately',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassPage(
            statusBarStyle: GlassStatusBarStyle.dark,
            child: const Scaffold(body: Text('Content')),
          ),
        ),
      );

      final annotatedDark =
          tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first);
      expect(annotatedDark.value, SystemUiOverlayStyle.dark);

      await tester.pumpWidget(
        MaterialApp(
          home: GlassPage(
            statusBarStyle: GlassStatusBarStyle.light,
            child: const Scaffold(body: Text('Content')),
          ),
        ),
      );

      final annotatedLight =
          tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first);
      expect(annotatedLight.value, SystemUiOverlayStyle.light);
    });

    testWidgets('handles GlassStatusBarStyle.auto based on platform brightness',
        (tester) async {
      // Simulate dark mode OS
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

      await tester.pumpWidget(
        MaterialApp(
          home: GlassPage(
            statusBarStyle: GlassStatusBarStyle.auto,
            child: const Scaffold(body: Text('Content')),
          ),
        ),
      );

      final annotatedLight =
          tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first);
      // In dark mode, auto uses light icons
      expect(annotatedLight.value, SystemUiOverlayStyle.light);

      // Simulate light mode OS
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

      await tester.pumpWidget(
        MaterialApp(
          home: GlassPage(
            statusBarStyle: GlassStatusBarStyle.auto,
            child: const Scaffold(body: Text('Content')),
          ),
        ),
      );

      final annotatedDark =
          tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first);
      // In light mode, auto uses dark icons
      expect(annotatedDark.value, SystemUiOverlayStyle.dark);

      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    testWidgets('edgeToEdge property updates properly on rebuild',
        (tester) async {
      bool edgeToEdge = false;

      await tester.pumpWidget(
        StatefulBuilder(builder: (context, setState) {
          return MaterialApp(
            home: GestureDetector(
              onTap: () => setState(() => edgeToEdge = !edgeToEdge),
              child: GlassPage(
                edgeToEdge: edgeToEdge,
                child: const Scaffold(body: Text('Content')),
              ),
            ),
          );
        }),
      );

      expect(find.byType(GlassPage), findsOneWidget);

      // Tap to toggle edgeToEdge
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Tap to toggle back
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Tests pass without exceptions during didUpdateWidget lifecycle
      expect(find.byType(GlassPage), findsOneWidget);
    });

    testWidgets(
        'applies ClipRSuperellipse during push, pop, and swipe-back, and unclips at rest',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => GlassPage(
              background: const ColoredBox(color: Color(0xFF112233)),
              child: CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => const GlassPage(
                            transitionCornerRadius: 42.0,
                            child: CupertinoPageScaffold(
                              child: Center(child: Text('Detail Page')),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Push Detail'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      List<ClipRSuperellipse> activeClips() => tester
          .widgetList<ClipRSuperellipse>(
            find.byType(ClipRSuperellipse, skipOffstage: false),
          )
          .where((c) => c.clipBehavior != Clip.none)
          .toList();

      // At rest on root page: no active ClipRSuperellipse
      expect(activeClips(), isEmpty);

      // Start push transition
      await tester.tap(find.text('Push Detail'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Mid-push: only the incoming primary sliding route (42.0) clips;
      // the underlying root route stays unclipped so no corner gap appears.
      final midPushClips = activeClips();
      expect(midPushClips.length, 1);
      expect(midPushClips.single.borderRadius, BorderRadius.circular(42.0));

      // Settle push: no active clips at rest
      await tester.pumpAndSettle();
      expect(find.text('Detail Page'), findsOneWidget);
      expect(activeClips(), isEmpty);

      // Interactive swipe-back from left edge (cancelled)
      var gesture = await tester.startGesture(const Offset(2, 300));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(activeClips().length, 1);
      expect(activeClips().single.borderRadius, BorderRadius.circular(42.0));

      // Release early to cancel swipe-back
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      expect(activeClips(), isNotEmpty);

      await tester.pumpAndSettle();
      expect(find.text('Detail Page'), findsOneWidget);
      expect(activeClips(), isEmpty);

      // Interactive swipe-back from left edge (completed)
      gesture = await tester.startGesture(const Offset(2, 300));
      await gesture.moveBy(const Offset(500, 0));
      await tester.pump();
      expect(activeClips().length, 1);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Push Detail'), findsOneWidget);
      expect(activeClips(), isEmpty);
    });

    testWidgets('transitionCornerRadius: 0 disables clipping during transition',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => GlassScaffold(
              transitionCornerRadius: 0.0,
              body: Center(
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const GlassScaffold(
                          transitionCornerRadius: 0.0,
                          body: Center(child: Text('Unclipped Detail')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Push Unclipped'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Unclipped'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final activeClips = tester
          .widgetList<ClipRSuperellipse>(
            find.byType(ClipRSuperellipse, skipOffstage: false),
          )
          .where((c) => c.clipBehavior != Clip.none);
      expect(activeClips, isEmpty);

      await tester.pumpAndSettle();
      expect(find.text('Unclipped Detail'), findsOneWidget);
    });

    testWidgets(
        'GlassPageTransitionsBuilder clips MaterialPageRoute transitions in MaterialApp',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android:
                    GlassPageTransitionsBuilder(transitionCornerRadius: 36.0),
                TargetPlatform.iOS:
                    GlassPageTransitionsBuilder(transitionCornerRadius: 36.0),
                TargetPlatform.macOS:
                    GlassPageTransitionsBuilder(transitionCornerRadius: 36.0),
              },
            ),
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: Center(child: Text('Material Detail')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Go Material'),
                ),
              ),
            ),
          ),
        ),
      );

      List<ClipRSuperellipse> activeClips() => tester
          .widgetList<ClipRSuperellipse>(
            find.byType(ClipRSuperellipse, skipOffstage: false),
          )
          .where((c) => c.clipBehavior != Clip.none)
          .toList();

      expect(activeClips(), isEmpty);

      await tester.tap(find.text('Go Material'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final midClips = activeClips();
      expect(midClips.length, 1);
      expect(midClips.single.borderRadius, BorderRadius.circular(36.0));

      await tester.pumpAndSettle();
      expect(find.text('Material Detail'), findsOneWidget);
      expect(activeClips(), isEmpty);
    });

    testWidgets(
        'GlassPageTransitionClip updates subscriptions on didUpdateWidget',
        (tester) async {
      final controller1 = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );
      final controller2 = AnimationController(
        vsync: const TestVSync(),
        value: 0.5,
      );
      addTearDown(controller1.dispose);
      addTearDown(controller2.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GlassPageTransitionClip(
            primaryAnimation: controller1,
            cornerRadius: 30.0,
            child: const SizedBox.expand(),
          ),
        ),
      );

      var clip =
          tester.widget<ClipRSuperellipse>(find.byType(ClipRSuperellipse));
      expect(clip.clipBehavior, Clip.none);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GlassPageTransitionClip(
            primaryAnimation: controller2,
            cornerRadius: 30.0,
            child: const SizedBox.expand(),
          ),
        ),
      );

      clip = tester.widget<ClipRSuperellipse>(find.byType(ClipRSuperellipse));
      expect(clip.clipBehavior, Clip.antiAlias);
      expect(clip.borderRadius, BorderRadius.circular(30.0));
    });

    testWidgets('resolveDisplayCornerRadius adapts to device screen geometry',
        (tester) async {
      Future<double> resolveFor({
        required Size size,
        required EdgeInsets viewPadding,
      }) async {
        late double resolved;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size, viewPadding: viewPadding),
            child: Builder(
              builder: (context) {
                resolved =
                    GlassPageTransitionClip.resolveDisplayCornerRadius(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        return resolved;
      }

      // iPhone 18 Pro (402x874, top 62, bottom 34) -> 62.0
      expect(
        await resolveFor(
          size: const Size(402, 874),
          viewPadding: const EdgeInsets.only(top: 62, bottom: 34),
        ),
        62.0,
      );

      // Dynamic Island iPhone 15/16 (393x852, top 59, bottom 34) -> 55.0
      expect(
        await resolveFor(
          size: const Size(393, 852),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
        ),
        55.0,
      );

      // Notch iPhone 14 (390x780, top 47, bottom 34) -> 47.33
      expect(
        await resolveFor(
          size: const Size(390, 780),
          viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        47.33,
      );

      // Rounded iPad Pro 11" (834x1194, top 24, bottom 20) -> 18.0
      expect(
        await resolveFor(
          size: const Size(834, 1194),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
        ),
        18.0,
      );

      // Zero viewPadding fallback -> 55.0
      expect(
        await resolveFor(
          size: const Size(800, 600),
          viewPadding: EdgeInsets.zero,
        ),
        GlassDefaults.pageTransitionCornerRadius,
      );
    });
  });
}
