import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  const tabs = <GlassTab>[
    GlassTab(icon: Icon(CupertinoIcons.home), label: 'Home'),
    GlassTab(icon: Icon(CupertinoIcons.search), label: 'Search'),
    GlassTab(icon: Icon(CupertinoIcons.person), label: 'Profile'),
  ];

  group('Wave 1.7 / W0.2 — Scroll frame budget & GlassScrollEdgeEffect', () {
    testWidgets(
      'scrolling 50-item ListView inside GlassScaffold triggers 0 GlassTabBar '
      'and 0 GlassAppBar rebuilds',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: GlassScaffold(
              appBar: GlassAppBar(
                title: const Text('Scroll Budget'),
                actions: [
                  GlassButton(
                    icon: const Icon(CupertinoIcons.add),
                    onTap: () {},
                  ),
                ],
              ),
              bottomBar: GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
              ),
              body: ListView.builder(
                controller: scrollController,
                itemCount: 50,
                itemBuilder: (context, index) => SizedBox(
                  height: 60,
                  child: Center(child: Text('Row $index')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rebuiltChrome = <Type>[];
        final prevHook = debugOnRebuildDirtyWidget;
        debugOnRebuildDirtyWidget = (Element e, bool builtOnce) {
          final w = e.widget;
          if (w is GlassTabBar || w is GlassAppBar) {
            rebuiltChrome.add(w.runtimeType);
          }
          prevHook?.call(e, builtOnce);
        };
        addTearDown(() => debugOnRebuildDirtyWidget = prevHook);

        for (var i = 1; i <= 15; i++) {
          scrollController.jumpTo(i * 30.0);
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(
          rebuiltChrome,
          isEmpty,
          reason:
              'GlassAppBar and GlassTabBar must not rebuild on scroll frames.',
        );
      },
    );

    testWidgets(
      'GlassScrollEdgeEffect(style: blur) shares one BackdropKey across top '
      'and bottom ProgressiveBlur strips',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GlassScrollEdgeEffect(
                style: GlassScrollEdgeStyle.blur,
                fadeTop: true,
                fadeBottom: true,
                child: SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pump();

        final blurs = tester
            .widgetList<ProgressiveBlur>(find.byType(ProgressiveBlur))
            .toList();
        expect(blurs, hasLength(2));
        expect(blurs[0].backdropKey, isNotNull);
        expect(
          identical(blurs[0].backdropKey, blurs[1].backdropKey),
          isTrue,
          reason: 'Top and bottom ProgressiveBlur strips must share a single '
              'BackdropKey so Impeller captures the backdrop once.',
        );
      },
    );

    testWidgets(
      'Wave 2.1 — GlassScaffold shares one BackdropKey across appBar and '
      'bottomBar while isolating body glass',
      (tester) async {
        BackdropKey? appBarKey;
        BackdropKey? bottomBarKey;
        BackdropKey? bodyKey;

        await tester.pumpWidget(
          MaterialApp(
            home: GlassScaffold(
              appBar: GlassAppBar(
                title: const Text('Shared Chrome'),
                actions: [
                  Builder(
                    builder: (context) {
                      appBarKey = GlassBackdropGroup.keyOf(context);
                      return const SizedBox(width: 44, height: 44);
                    },
                  ),
                ],
              ),
              bottomBar: Builder(
                builder: (context) {
                  bottomBarKey = GlassBackdropGroup.keyOf(context);
                  return GlassTabBar.bottom(
                    tabs: tabs,
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                  );
                },
              ),
              body: Builder(
                builder: (context) {
                  bodyKey = GlassBackdropGroup.keyOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(appBarKey, isNotNull);
        expect(bottomBarKey, isNotNull);
        expect(
          identical(appBarKey, bottomBarKey),
          isTrue,
          reason: 'GlassScaffold appBar and bottomBar must share a single '
              'BackdropKey.',
        );
        expect(
          bodyKey,
          isNull,
          reason:
              'GlassScaffold body must opt out of the chrome BackdropGroup so '
              'top/bottom bars sample body glass beneath them.',
        );
      },
    );
  });
}
