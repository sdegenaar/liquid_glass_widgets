import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassAppBar', () {
    testWidgets('can be instantiated with default parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(),
            ),
          ),
        ),
      );

      expect(find.byType(GlassAppBar), findsOneWidget);
    });

    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                title: Text('App Title'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('App Title'), findsOneWidget);

      // Verify it wraps the title in a DefaultTextStyle for Cupertino styling
      final defaultTextStyle = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('App Title'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );

      final BuildContext context = tester.element(find.byType(GlassAppBar));
      expect(
        defaultTextStyle.style,
        equals(CupertinoTheme.of(context).textTheme.navTitleTextStyle),
      );

      // Verify it adds header semantics
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.text('App Title'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.header, isTrue);
    });

    testWidgets('displays leading widget', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Scaffold(
              appBar: GlassAppBar(
                leading: GlassButton(
                  icon: Icon(Icons.menu),
                  onTap: () {},
                ),
                title: const Text('Title'),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('displays actions', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Scaffold(
              appBar: GlassAppBar(
                title: const Text('Title'),
                actions: [
                  GlassButton(icon: Icon(Icons.search), onTap: () {}),
                  GlassButton(icon: Icon(Icons.more_horiz), onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('centers title by default', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                title: Text('Centered'),
              ),
            ),
          ),
        ),
      );

      // With the CustomMultiChildLayout delegate the title is centred
      // geometrically — there is no Center widget in the tree to find.
      // Assert the invariant directly: title midpoint ≈ bar midpoint.
      final titleFinder = find.text('Centered');
      expect(titleFinder, findsOneWidget);

      final appBarBox =
          tester.renderObject<RenderBox>(find.byType(GlassAppBar));
      final barCenter =
          appBarBox.localToGlobal(Offset.zero).dx + appBarBox.size.width / 2;

      final titleBox = tester.renderObject<RenderBox>(titleFinder);
      final titleCenter =
          titleBox.localToGlobal(Offset.zero).dx + titleBox.size.width / 2;

      expect(
        titleCenter,
        closeTo(barCenter, 2.0),
        reason: 'Default centerTitle:true should centre title on the bar',
      );
    });

    testWidgets('left-aligns title when centerTitle is false', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                title: Text('Left'),
                centerTitle: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassAppBar), findsOneWidget);
    });

    testWidgets('applies background color', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(
                backgroundColor: Color(0xFF2C2C2E),
                title: Text('Solid'),
              ),
            ),
          ),
        ),
      );

      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, equals(const Color(0xFF2C2C2E)));
    });

    testWidgets('implements ObstructingPreferredSizeWidget', (tester) async {
      const appBar = GlassAppBar();
      expect(appBar, isA<PreferredSizeWidget>());
      expect(appBar, isA<ObstructingPreferredSizeWidget>());
    });

    testWidgets(
        'shouldFullyObstruct returns false for transparent background (default)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const Scaffold(appBar: GlassAppBar())),
      );

      final appBar = tester.widget<GlassAppBar>(find.byType(GlassAppBar));
      final context = tester.element(find.byType(GlassAppBar));
      expect(appBar.shouldFullyObstruct(context), isFalse);
    });

    testWidgets('shouldFullyObstruct returns true for fully opaque background',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            appBar: GlassAppBar(backgroundColor: Colors.black),
          ),
        ),
      );

      final appBar = tester.widget<GlassAppBar>(find.byType(GlassAppBar));
      final context = tester.element(find.byType(GlassAppBar));
      expect(appBar.shouldFullyObstruct(context), isTrue);
    });

    test('defaults are correct', () {
      const appBar = GlassAppBar();

      expect(appBar.centerTitle, isTrue);
      expect(appBar.backgroundColor, equals(Colors.transparent));
      expect(appBar.toolbarHeight, equals(44.0));
      expect(
        appBar.padding,
        equals(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
      );
      expect(appBar.preferredSize, equals(const Size.fromHeight(64.0)));
      expect(appBar.bottom, isNull);
    });

    group('bottom parameter', () {
      testWidgets('preferredSize includes bottom widget height',
          (tester) async {
        const bottomHeight = 48.0;
        final appBar = GlassAppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(bottomHeight),
            child: const SizedBox.shrink(),
          ),
        );
        expect(
          appBar.preferredSize,
          equals(const Size.fromHeight(64.0 + bottomHeight)),
        );
      });

      testWidgets('bottom widget is rendered in the tree', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              appBar: GlassAppBar(
                title: const Text('Title'),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(48.0),
                  child: Text('bottom-content'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('bottom-content'), findsOneWidget);
      });

      testWidgets('scaffold reserves correct height with bottom',
          (tester) async {
        const bottomHeight = 48.0;
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              appBar: GlassAppBar(
                title: const Text('Title'),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(bottomHeight),
                  child: SizedBox.shrink(),
                ),
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );

        final appBarWidget = tester.widget<GlassAppBar>(
          find.byType(GlassAppBar),
        );
        expect(
          appBarWidget.preferredSize.height,
          equals(64.0 + bottomHeight),
        );
      });

      testWidgets('no bottom renders single toolbar row (no Column)',
          (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              appBar: GlassAppBar(title: Text('No Bottom')),
            ),
          ),
        );

        // Without bottom there should be no Column inside GlassAppBar
        expect(
          find.descendant(
            of: find.byType(GlassAppBar),
            matching: find.byType(Column),
          ),
          findsNothing,
        );
      });

      testWidgets('with bottom renders a Column wrapping toolbar + bottom',
          (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              appBar: GlassAppBar(
                title: const Text('Title'),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(40.0),
                  child: Text('tab-bar-placeholder'),
                ),
              ),
            ),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(GlassAppBar),
            matching: find.byType(Column),
          ),
          findsOneWidget,
        );
      });

      test('custom toolbarHeight is reflected in preferredSize without bottom',
          () {
        const appBar = GlassAppBar(toolbarHeight: 56.0);
        expect(appBar.preferredSize, equals(const Size.fromHeight(76.0)));
      });

      test('vertical padding is included in preferredSize', () {
        const appBar = GlassAppBar(
          padding: EdgeInsets.fromLTRB(8, 10, 8, 12),
        );
        expect(appBar.preferredSize, equals(const Size.fromHeight(66.0)));
      });

      test('pinned vertical padding is included in preferredSize', () {
        const appBar = GlassAppBar.pinned(
          padding: EdgeInsets.fromLTRB(8, 14, 8, 6),
        );
        expect(appBar.preferredSize, equals(const Size.fromHeight(64.0)));
      });

      testWidgets('lays out with the platform top safe area', (tester) async {
        Widget app(EdgeInsets padding) => MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(400, 800),
                  padding: padding,
                ),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 400,
                    child: GlassAppBar(title: Text('Title')),
                  ),
                ),
              ),
            );

        await tester.pumpWidget(app(const EdgeInsets.only(top: 8)));
        expect(
          tester.getSize(find.byType(GlassAppBar)).height,
          8 + 20 + 44,
        );

        await tester.pumpWidget(app(const EdgeInsets.only(top: 32)));
        expect(
          tester.getSize(find.byType(GlassAppBar)).height,
          32 + 20 + 44,
        );
      });

      testWidgets('works as a Material Scaffold appBar with a top inset',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(400, 800),
                padding: EdgeInsets.only(top: 24),
              ),
              child: Scaffold(
                appBar: const GlassAppBar(title: Text('Title')),
                body: Builder(
                  builder: (context) => Text(
                    'body-top:${MediaQuery.paddingOf(context).top}',
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(GlassAppBar)).height,
          24 + 64,
        );
      });

      testWidgets('content padding adds MediaQuery top, left and right insets',
          (tester) async {
        const configuredPadding = EdgeInsets.fromLTRB(5, 3, 7, 9);
        const mediaQueryPadding = EdgeInsets.fromLTRB(13, 11, 17, 19);
        const expectedContentPadding = EdgeInsets.fromLTRB(18, 14, 24, 9);

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(400, 800),
                padding: mediaQueryPadding,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 400,
                  child: GlassAppBar(
                    centerTitle: false,
                    padding: configuredPadding,
                    leading: SizedBox(
                      key: ValueKey('leading'),
                      width: 44,
                      height: 44,
                    ),
                    actions: [
                      SizedBox(
                        key: ValueKey('actions'),
                        width: 30,
                        height: 44,
                      ),
                    ],
                    title: Text('Title'),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Padding && widget.padding == expectedContentPadding,
          ),
          findsOneWidget,
          reason: 'the configured padding must be combined with the three '
              'safe-area sides, not replaced by them',
        );

        final appBarRect = tester.getRect(find.byType(GlassAppBar));
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('leading'))) -
              appBarRect.topLeft,
          const Offset(18, 14),
        );
        expect(
          tester.getTopRight(find.byKey(const ValueKey('actions'))).dx -
              appBarRect.left,
          appBarRect.width - 24,
        );
        expect(
          tester.getTopLeft(find.text('Title')).dx - appBarRect.left,
          18 + 44 + 8,
        );
        expect(
          appBarRect.height,
          14 + 44 + 9,
          reason: 'the bottom safe inset must not contribute to app-bar '
              'content padding',
        );
      });

      testWidgets('zero padding still applies the three safe-area insets',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(400, 800),
                padding: EdgeInsets.fromLTRB(13, 11, 17, 19),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 400,
                  child: GlassAppBar(
                    padding: EdgeInsets.zero,
                    title: Text('Title'),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Padding &&
                widget.padding == const EdgeInsets.fromLTRB(13, 11, 17, 0),
          ),
          findsOneWidget,
        );
      });

      test(
          'custom toolbarHeight + bottom height sum correctly in preferredSize',
          () {
        final appBar = GlassAppBar(
          toolbarHeight: 56.0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: SizedBox.shrink(),
          ),
        );
        expect(appBar.preferredSize, equals(const Size.fromHeight(124.0)));
      });
    });

    testWidgets('renders as StatelessWidget (no glass rendering)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            appBar: GlassAppBar(
              title: Text('No Glass'),
            ),
          ),
        ),
      );

      // The bar itself should never contain a BackdropFilter — glass belongs
      // on the individual buttons (GlassButton), not the bar surface.
      expect(find.byType(GlassAppBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(Opacity),
        ),
        findsNothing,
        reason: 'No Opacity wrappers without a largeTitleController',
      );
      expect(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
        reason: 'GlassAppBar is a layout container — glass belongs on buttons',
      );
    });

    testWidgets('wraps itself in GlassIsolationScope with isolated: true',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(title: Text('Test')),
            ),
          ),
        ),
      );

      // Find the GlassIsolationScope that is a descendant of GlassAppBar.
      final scope = tester.widget<GlassIsolationScope>(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(GlassIsolationScope),
        ),
      );
      expect(scope.isolated, isTrue,
          reason: 'GlassAppBar should self-isolate for Z-order correctness');
    });

    testWidgets('provides defaultQuality: premium via isolation scope',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const Scaffold(
              appBar: GlassAppBar(title: Text('Test')),
            ),
          ),
        ),
      );

      final scope = tester.widget<GlassIsolationScope>(
        find.descendant(
          of: find.byType(GlassAppBar),
          matching: find.byType(GlassIsolationScope),
        ),
      );
      expect(scope.defaultQuality, equals(GlassQuality.premium),
          reason: 'App bar buttons should default to premium quality');
    });
  });

  group('title centering', () {
    testWidgets(
        'title is centred on full bar width when leading button is present '
        '(regression #198)', (tester) async {
      // Use a fixed-width surface so we can measure absolute positions.
      const barWidth = 390.0;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: barWidth,
            child: Scaffold(
              appBar: GlassAppBar(
                title: const Text('Title'),
                leading: const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        ),
      );

      // Find the Text widget that renders the title.
      final titleFinder = find.text('Title');
      expect(titleFinder, findsOneWidget);

      final titleBox = tester.renderObject<RenderBox>(titleFinder);
      final titlePos = titleBox.localToGlobal(Offset.zero);
      final titleCenter = titlePos.dx + titleBox.size.width / 2;

      // Find the bar's RenderBox to get its actual rendered width.
      final appBarBox =
          tester.renderObject<RenderBox>(find.byType(GlassAppBar));
      final barCenter =
          appBarBox.localToGlobal(Offset.zero).dx + appBarBox.size.width / 2;

      // Title center must be within 2 px of the bar center.
      // Without the Stack fix this would be shifted ~22 px to the right.
      expect(
        titleCenter,
        closeTo(barCenter, 2.0),
        reason: 'Title should be centred on the full bar width, not just the '
            'space remaining after the leading widget (bug #198)',
      );
    });

    testWidgets(
        'title is centred on full bar width with both leading and actions '
        '(symmetric — existing behaviour preserved)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            appBar: GlassAppBar(
              title: Text('Title'),
              leading: SizedBox(width: 44, height: 44),
              actions: [SizedBox(width: 44, height: 44)],
            ),
          ),
        ),
      );

      final titleFinder = find.text('Title');
      expect(titleFinder, findsOneWidget);

      final titleBox = tester.renderObject<RenderBox>(titleFinder);
      final titlePos = titleBox.localToGlobal(Offset.zero);
      final titleCenter = titlePos.dx + titleBox.size.width / 2;

      final appBarBox =
          tester.renderObject<RenderBox>(find.byType(GlassAppBar));
      final barCenter =
          appBarBox.localToGlobal(Offset.zero).dx + appBarBox.size.width / 2;

      expect(
        titleCenter,
        closeTo(barCenter, 2.0),
        reason: 'Symmetric leading + actions should also be centred',
      );
    });

    testWidgets('centerTitle: false aligns title to leading edge',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            appBar: GlassAppBar(
              // ignore: avoid_redundant_argument_values
              centerTitle: false,
              title: Text('Left Title'),
              leading: SizedBox(width: 44, height: 44),
            ),
          ),
        ),
      );

      final titleFinder = find.text('Left Title');
      expect(titleFinder, findsOneWidget);

      final appBarBox =
          tester.renderObject<RenderBox>(find.byType(GlassAppBar));
      final barCenter =
          appBarBox.localToGlobal(Offset.zero).dx + appBarBox.size.width / 2;

      final titleBox = tester.renderObject<RenderBox>(titleFinder);
      final titleCenter =
          titleBox.localToGlobal(Offset.zero).dx + titleBox.size.width / 2;

      // Title should be left-aligned, so its centre is well to the left
      // of the bar's centre.
      expect(
        titleCenter,
        lessThan(barCenter),
        reason: 'centerTitle: false should left-align the title',
      );
    });
  });

  group('left-aligned title spacing (regression #282)', () {
    testWidgets(
      'left-aligned title respects padding without a leading widget (pinned)',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const CupertinoApp(
            home: GlassScaffold(
              appBar: GlassAppBar.pinned(
                backButton: false,
                centerTitle: false,
                padding: EdgeInsets.symmetric(horizontal: 16),
                title: Text('Activity Summary'),
              ),
              body: SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleLeft = tester.getTopLeft(find.text('Activity Summary')).dx;

        expect(
          titleLeft,
          16.0,
          reason:
              'Title should align to 16px content padding without extra gap',
        );
      },
    );

    testWidgets(
      'left-aligned title respects padding without a leading widget (unpinned)',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              appBar: GlassAppBar(
                centerTitle: false,
                padding: EdgeInsets.symmetric(horizontal: 16),
                title: Text('Activity Summary'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleLeft = tester.getTopLeft(find.text('Activity Summary')).dx;

        expect(
          titleLeft,
          16.0,
          reason:
              'Title should align directly to padding when no leading widget is provided',
        );
      },
    );

    testWidgets(
      'left-aligned title applies 8px gap when leading widget is present',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const double leadingWidth = 44.0;
        const double horizontalPadding = 16.0;

        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              appBar: GlassAppBar(
                centerTitle: false,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                leading: SizedBox(width: leadingWidth, height: 44),
                title: Text('Activity Summary'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleLeft = tester.getTopLeft(find.text('Activity Summary')).dx;

        // padding (16) + leadingWidth (44) + _titleGap (8) = 68.0
        expect(
          titleLeft,
          horizontalPadding + leadingWidth + 8.0,
          reason:
              'Title should include an 8px gap when a leading widget is present',
        );
      },
    );

    testWidgets(
      'left-aligned title constrains width to preserve 8px gap before actions',
      (tester) async {
        const double barWidth = 375.0;
        const double horizontalPadding = 16.0;
        const double actionsWidth = 50.0;

        await tester.pumpWidget(
          createTestApp(
            child: SizedBox(
              width: barWidth,
              child: const Scaffold(
                appBar: GlassAppBar(
                  centerTitle: false,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  actions: [SizedBox(width: actionsWidth, height: 44)],
                  title: Text(
                    'Very Long Title That Should Be Constrained By Layout',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleRight = tester
            .getTopRight(
              find.text('Very Long Title That Should Be Constrained By Layout'),
            )
            .dx;

        // Total width = 375.
        // Actions start at 375 - 16 - 50 = 309.
        // Title must end at or before 309 - 8 = 301.
        expect(titleRight, lessThanOrEqualTo(301.0));
      },
    );

    testWidgets(
      'relayouts when centerTitle changes',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              appBar: GlassAppBar(
                centerTitle: false,
                title: Text('Title'),
              ),
            ),
          ),
        );

        final initialLeft = tester.getTopLeft(find.text('Title')).dx;

        // Rebuild with centerTitle: true
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              appBar: GlassAppBar(
                centerTitle: true,
                title: Text('Title'),
              ),
            ),
          ),
        );

        final centeredLeft = tester.getTopLeft(find.text('Title')).dx;
        expect(centeredLeft, greaterThan(initialLeft));
      },
    );
  });
}
