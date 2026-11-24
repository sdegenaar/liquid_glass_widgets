import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as barrel;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/bar_item_style_resolver.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/glass_nav_pinned_host.dart';

/// iPhone Duo's outer display in portrait (iOS 27.1 simulator metrics).
const _duoOuterPortrait = Size(466, 678);
const _duoOuterPortraitPadding = EdgeInsets.fromLTRB(0, 0, 84, 34);

void main() {
  setUp(() {
    GlassNavigationShellState.debugPinningSupported = true;
  });

  tearDown(() {
    GlassNavigationShellState.debugPinningSupported = null;
  });

  Widget cupertinoShellApp(
    Widget home, {
    bool shell = true,
    Brightness brightness = Brightness.light,
    Color? primaryColor,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return CupertinoApp(
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primaryColor,
      ),
      builder: (context, child) {
        final content = shell ? GlassNavigationShell(child: child!) : child!;
        return Directionality(
          textDirection: textDirection,
          child: content,
        );
      },
      home: home,
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump();
  }

  Finder inHost(Finder matching) => find.descendant(
        of: find.byType(GlassNavPinnedHost),
        matching: matching,
      );

  Finder inBar(Finder matching) => find.descendant(
        of: find.byType(GlassAppBar),
        matching: matching,
      );

  void setDuoScreen(WidgetTester tester) {
    const dpr = 3.0;
    tester.view
      ..devicePixelRatio = dpr
      ..physicalSize = _duoOuterPortrait * dpr
      ..viewPadding = FakeViewPadding(
        left: _duoOuterPortraitPadding.left * dpr,
        top: _duoOuterPortraitPadding.top * dpr,
        right: _duoOuterPortraitPadding.right * dpr,
        bottom: _duoOuterPortraitPadding.bottom * dpr,
      )
      ..padding = FakeViewPadding(
        left: _duoOuterPortraitPadding.left * dpr,
        top: _duoOuterPortraitPadding.top * dpr,
        right: _duoOuterPortraitPadding.right * dpr,
        bottom: _duoOuterPortraitPadding.bottom * dpr,
      );
    addTearDown(tester.view.reset);
  }

  // ===========================================================================
  // 1. API construction, defaults & assertions
  // ===========================================================================
  group('GlassBarItem.text and GlassBarItemStyle construction', () {
    test('GlassBarItem.text defaults to plain, shared, horizontal-automatic',
        () {
      var tapped = false;
      final item = GlassBarItem.text(
        title: 'Edit',
        id: 'edit',
        onTap: () => tapped = true,
      ) as GlassBarTextItem;

      expect(item.title, 'Edit');
      expect(item.id, 'edit');
      expect(item.label, isNull);
      expect(item.enabled, isTrue);
      expect(item.style, GlassBarItemStyle.plain);
      expect(item.background, GlassBarItemBackground.shared);
      expect(item.tintColor, isNull);
      expect(item.textStyle, isNull);
      expect(item.axisBehavior, GlassBarItemAxisBehavior.automatic);
      expect(item.hasTap, isTrue);
      expect(item.goesVertical, isFalse);

      item.onTap();
      expect(tapped, isTrue);

      final text = item.content as Text;
      expect(text.data, 'Edit');
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    test('GlassBarItem.text axisBehavior controls goesVertical', () {
      final auto =
          GlassBarItem.text(title: 'Edit', onTap: () {}) as GlassBarActionItem;
      final horiz = GlassBarItem.text(
        title: 'Edit',
        axisBehavior: GlassBarItemAxisBehavior.horizontalOnly,
        onTap: () {},
      ) as GlassBarActionItem;
      final vert = GlassBarItem.text(
        title: 'Edit',
        axisBehavior: GlassBarItemAxisBehavior.verticalPreferred,
        onTap: () {},
      ) as GlassBarActionItem;

      expect(auto.goesVertical, isFalse);
      expect(horiz.goesVertical, isFalse);
      expect(vert.goesVertical, isTrue);
    });

    test('prominent defaults background to separate across all action kinds',
        () {
      final items = <GlassBarActionItem>[
        GlassBarItem.icon(
          icon: const Icon(CupertinoIcons.checkmark),
          style: GlassBarItemStyle.prominent,
          onTap: () {},
        ) as GlassBarActionItem,
        GlassBarItem.text(
          title: 'Done',
          style: GlassBarItemStyle.prominent,
          onTap: () {},
        ) as GlassBarActionItem,
        const GlassBarItem.custom(
          child: Text('Save'),
          style: GlassBarItemStyle.prominent,
        ) as GlassBarActionItem,
        GlassBarItem.menu(
          icon: const Icon(CupertinoIcons.ellipsis),
          menuItems: const [],
          style: GlassBarItemStyle.prominent,
        ) as GlassBarActionItem,
        GlassBarItem.sheet(
          icon: const Icon(CupertinoIcons.add),
          onPresent: (_) {},
          style: GlassBarItemStyle.prominent,
        ) as GlassBarActionItem,
      ];

      for (final item in items) {
        expect(item.style, GlassBarItemStyle.prominent);
        expect(item.background, GlassBarItemBackground.separate);
      }

      // Prominent icon/menu/sheet still go vertical in Duo's strip.
      expect(items[0].goesVertical, isTrue);
      expect(items[1].goesVertical, isFalse);
      expect(items[3].goesVertical, isTrue);
      expect(items[4].goesVertical, isTrue);
    });

    test('prominent with explicit shared background asserts immediately', () {
      expect(
        () => GlassBarItem.text(
          title: 'Done',
          style: GlassBarItemStyle.prominent,
          background: GlassBarItemBackground.shared,
          onTap: () {},
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GlassBarItem.icon(
          icon: const Icon(CupertinoIcons.checkmark),
          style: GlassBarItemStyle.prominent,
          background: GlassBarItemBackground.shared,
          onTap: () {},
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GlassBarItem.custom(
          child: const Text('Save'),
          style: GlassBarItemStyle.prominent,
          background: GlassBarItemBackground.shared,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GlassBarItem.menu(
          icon: const Icon(CupertinoIcons.ellipsis),
          menuItems: const [],
          style: GlassBarItemStyle.prominent,
          background: GlassBarItemBackground.shared,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GlassBarItem.sheet(
          icon: const Icon(CupertinoIcons.add),
          onPresent: (_) {},
          style: GlassBarItemStyle.prominent,
          background: GlassBarItemBackground.shared,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('prominent allows none and own backgrounds', () {
      final noneItem = GlassBarItem.text(
        title: 'Done',
        style: GlassBarItemStyle.prominent,
        background: GlassBarItemBackground.none,
        onTap: () {},
      ) as GlassBarTextItem;
      final ownItem = const GlassBarItem.custom(
        child: SizedBox(),
        style: GlassBarItemStyle.prominent,
        background: GlassBarItemBackground.own,
      ) as GlassBarCustomItem;

      expect(noneItem.background, GlassBarItemBackground.none);
      expect(ownItem.background, GlassBarItemBackground.own);
    });

    test('barrel exports GlassBarItemStyle, GlassBarTextItem and new metrics',
        () {
      expect(barrel.GlassBarItemStyle.values, [
        barrel.GlassBarItemStyle.plain,
        barrel.GlassBarItemStyle.prominent,
      ]);
      expect(
        barrel.GlassNavPinnedMetrics.textHorizontalPadding,
        kBarItemTextHorizontalPadding,
      );
      expect(
        barrel.GlassNavPinnedMetrics.prominentTintAlpha,
        kBarItemProminentTintAlpha,
      );
    });
  });

  // ===========================================================================
  // 2. Grouping, stretch & slot matching
  // ===========================================================================
  group('grouping, stretch and slot matching', () {
    test('prominent item automatically splits from shared neighbours', () {
      final share = GlassBarItem.icon(
        icon: const Icon(CupertinoIcons.share),
        onTap: () {},
      );
      final bookmark = GlassBarItem.icon(
        icon: const Icon(CupertinoIcons.bookmark),
        onTap: () {},
      );
      final done = GlassBarItem.text(
        title: 'Done',
        style: GlassBarItemStyle.prominent,
        onTap: () {},
      );

      final groups = groupGlassNavBarItems([share, bookmark, done]);
      expect(groups, hasLength(2));
      expect(groups[0].background, GlassBarItemBackground.shared);
      expect(groups[0].items, hasLength(2));
      expect(groups[0].crossExtent, GlassNavPinnedMetrics.slot);

      expect(groups[1].background, GlassBarItemBackground.separate);
      expect(groups[1].items.single, same(done));
      expect(groups[1].crossExtent, GlassNavPinnedMetrics.backDiameter);
      expect(groups[1].stretch, GlassNavPinnedMetrics.capsuleStretch);
    });

    test('text pill uses capsuleStretch while circular icon uses buttonStretch',
        () {
      final textGroup = groupGlassNavBarItems([
        GlassBarItem.text(
          title: 'Cancel',
          background: GlassBarItemBackground.separate,
          onTap: () {},
        ),
      ]).single;
      final iconGroup = groupGlassNavBarItems([
        GlassBarItem.icon(
          icon: const Icon(CupertinoIcons.checkmark),
          style: GlassBarItemStyle.prominent,
          onTap: () {},
        ),
      ]).single;

      expect(textGroup.stretch, GlassNavPinnedMetrics.capsuleStretch);
      expect(iconGroup.stretch, GlassNavPinnedMetrics.buttonStretch);
    });

    test('GlassNavActionSlot compares text items and style/tint/enabled', () {
      final editA =
          GlassBarItem.text(title: 'Edit', onTap: () {}) as GlassBarActionItem;
      final editB =
          GlassBarItem.text(title: 'Edit', onTap: () {}) as GlassBarActionItem;
      final done = GlassBarItem.text(
        title: 'Done',
        style: GlassBarItemStyle.prominent,
        onTap: () {},
      ) as GlassBarActionItem;
      final editDisabled = GlassBarItem.text(
        title: 'Edit',
        enabled: false,
        onTap: () {},
      ) as GlassBarActionItem;
      final iconPlain = GlassBarItem.icon(
        icon: const Icon(CupertinoIcons.checkmark),
        background: GlassBarItemBackground.separate,
        onTap: () {},
      ) as GlassBarActionItem;
      final iconProminent = GlassBarItem.icon(
        icon: const Icon(CupertinoIcons.checkmark),
        style: GlassBarItemStyle.prominent,
        onTap: () {},
      ) as GlassBarActionItem;

      expect(
        GlassNavActionSlot(fromItem: editA, toItem: editB).crossFades,
        isFalse,
      );
      expect(
        GlassNavActionSlot(fromItem: editA, toItem: done).crossFades,
        isTrue,
      );
      expect(
        GlassNavActionSlot(fromItem: editA, toItem: editDisabled).crossFades,
        isTrue,
      );
      expect(
        GlassNavActionSlot(fromItem: iconPlain, toItem: iconProminent)
            .crossFades,
        isTrue,
      );
    });
  });

  // ===========================================================================
  // 3. Rendering, typography, sizing & hand-over parity (hoisted + in-route)
  // ===========================================================================
  group('GlassBarItem.text rendering and sizing', () {
    for (final useShell in [true, false]) {
      testWidgets(
          'plain text renders 17pt w400 label and fires onTap (shell: $useShell)',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Mailboxes'),
              actions: [
                GlassBarItem.text(
                  title: 'Edit',
                  onTap: () => taps++,
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final textFinder =
            useShell ? inHost(find.text('Edit')) : inBar(find.text('Edit'));
        expect(textFinder, findsOneWidget);

        final style = DefaultTextStyle.of(tester.element(textFinder)).style;
        expect(style.fontSize, 17.0);
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, -0.41);
        expect(
          style.color,
          CupertinoColors.label.resolveFrom(tester.element(textFinder)),
        );

        await tester.tap(textFinder);
        expect(taps, 1);
      });
    }

    testWidgets(
        'hoisted and in-route text capsules measure to the exact same size',
        (tester) async {
      Widget screen() => GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Compose'),
              leading: [
                GlassBarItem.text(
                  title: 'Cancel',
                  background: GlassBarItemBackground.separate,
                  onTap: () {},
                ),
              ],
              actions: [
                GlassBarItem.text(
                  title: 'Save',
                  style: GlassBarItemStyle.prominent,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          );

      await tester.pumpWidget(cupertinoShellApp(screen(), shell: true));
      await settle(tester);
      final hoistedButtons =
          tester.widgetList<GlassButton>(inHost(find.byType(GlassButton)));
      expect(hoistedButtons, hasLength(2));
      final hoistedCancelSize =
          tester.getSize(inHost(find.byType(GlassButton)).first);
      final hoistedSaveSize =
          tester.getSize(inHost(find.byType(GlassButton)).last);
      final hoistedTitleCenter = tester.getCenter(find.text('Compose'));

      await tester.pumpWidget(cupertinoShellApp(screen(), shell: false));
      await settle(tester);
      final inRouteCancelSize =
          tester.getSize(inBar(find.byType(GlassButtonGroup)).first);
      final inRouteSaveSize =
          tester.getSize(inBar(find.byType(GlassButtonGroup)).last);
      final inRouteTitleCenter = tester.getCenter(find.text('Compose'));

      expect(inRouteCancelSize, hoistedCancelSize);
      expect(inRouteSaveSize, hoistedSaveSize);
      expect(inRouteTitleCenter.dx, closeTo(hoistedTitleCenter.dx, 0.01));
    });

    testWidgets('short single-character label enforces minimum capsule width',
        (tester) async {
      await tester.pumpWidget(cupertinoShellApp(
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('Title'),
            actions: [
              GlassBarItem.text(
                title: 'X',
                style: GlassBarItemStyle.prominent,
                onTap: () {},
              ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ));
      await settle(tester);

      final pillSize = tester.getSize(inHost(find.byType(GlassButton)));
      expect(pillSize.height, GlassNavPinnedMetrics.backDiameter);
      expect(
        pillSize.width,
        greaterThanOrEqualTo(GlassNavPinnedMetrics.backDiameter),
      );
    });

    testWidgets('custom textStyle overrides default text color/weight',
        (tester) async {
      await tester.pumpWidget(cupertinoShellApp(
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('Edit'),
            actions: [
              GlassBarItem.text(
                title: 'Delete',
                textStyle: const TextStyle(color: CupertinoColors.systemRed),
                onTap: () {},
              ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ));
      await settle(tester);

      final textWidget = tester.widget<Text>(inHost(find.text('Delete')));
      expect(textWidget.style?.color, CupertinoColors.systemRed);
    });
  });

  // ===========================================================================
  // 4. Prominent styling, dynamic colour resolution & contrast (hoisted + in-route)
  // ===========================================================================
  group('GlassBarItemStyle.prominent visual styling', () {
    for (final useShell in [true, false]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        testWidgets(
            'untinted prominent text resolves primaryColor at 0.85 alpha with w600 white text (shell: $useShell, $brightness)',
            (tester) async {
          await tester.pumpWidget(cupertinoShellApp(
            shell: useShell,
            brightness: brightness,
            GlassScaffold(
              appBar: GlassAppBar.pinned(
                title: const Text('New Event'),
                actions: [
                  GlassBarItem.text(
                    title: 'Done',
                    style: GlassBarItemStyle.prominent,
                    onTap: () {},
                  ),
                ],
              ),
              body: const SizedBox.expand(),
            ),
          ));
          await settle(tester);

          final textFinder =
              useShell ? inHost(find.text('Done')) : inBar(find.text('Done'));
          final textElem = tester.element(textFinder);
          final expectedAccent = CupertinoDynamicColor.resolve(
            CupertinoTheme.of(textElem).primaryColor,
            textElem,
          ).withValues(alpha: GlassNavPinnedMetrics.prominentTintAlpha);

          if (useShell) {
            final shellBtn =
                tester.widget<GlassButton>(inHost(find.byType(GlassButton)));
            expect(shellBtn.settings?.bodyMode, GlassBodyMode.clear);
            expect(shellBtn.settings?.glassColor, expectedAccent);
          } else {
            final group = tester
                .widget<GlassButtonGroup>(inBar(find.byType(GlassButtonGroup)));
            expect(group.useOwnLayer, isTrue);
            expect(group.settings?.bodyMode, GlassBodyMode.clear);
            expect(group.settings?.glassColor, expectedAccent);
          }

          final style = DefaultTextStyle.of(textElem).style;
          expect(style.fontWeight, FontWeight.w600);
          expect(style.color, const Color(0xFFFFFFFF));
        });
      }

      testWidgets(
          'prominent foreground luminance flips cleanly for green/orange (white) vs yellow (black) (shell: $useShell)',
          (tester) async {
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Colors'),
              actions: [
                GlassBarItem.icon(
                  icon: const Icon(CupertinoIcons.checkmark),
                  style: GlassBarItemStyle.prominent,
                  tintColor: CupertinoColors.systemGreen,
                  onTap: () {},
                ),
                GlassBarItem.icon(
                  icon: const Icon(CupertinoIcons.flame),
                  style: GlassBarItemStyle.prominent,
                  tintColor: CupertinoColors.systemOrange,
                  onTap: () {},
                ),
                GlassBarItem.text(
                  title: 'Gold',
                  style: GlassBarItemStyle.prominent,
                  tintColor: CupertinoColors.systemYellow,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        Finder locate(Finder inner) => useShell ? inHost(inner) : inBar(inner);

        expect(
          IconTheme.of(
                  tester.element(locate(find.byIcon(CupertinoIcons.checkmark))))
              .color,
          const Color(0xFFFFFFFF),
        );
        expect(
          IconTheme.of(
                  tester.element(locate(find.byIcon(CupertinoIcons.flame))))
              .color,
          const Color(0xFFFFFFFF),
        );
        expect(
          DefaultTextStyle.of(tester.element(locate(find.text('Gold'))))
              .style
              .color,
          const Color(0xFF000000),
        );
      });

      testWidgets(
          'disabled prominent item reverts shell to neutral glass and dims foreground (shell: $useShell)',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Compose'),
              actions: [
                GlassBarItem.text(
                  title: 'Send',
                  style: GlassBarItemStyle.prominent,
                  enabled: false,
                  onTap: () => taps++,
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final shellBtn = tester.widget<GlassButton>(
          useShell
              ? inHost(find.byType(GlassButton))
              : inBar(find.byType(GlassButton)),
        );
        expect(shellBtn.settings, isNull);
        expect(shellBtn.enabled, isTrue);
        expect(shellBtn.interactionScale, 1.0);
        expect(shellBtn.stretch, 0.0);
        expect(shellBtn.glowRadius, 0.0);
        if (!useShell) {
          final group = tester
              .widget<GlassButtonGroup>(inBar(find.byType(GlassButtonGroup)));
          expect(group.settings, isNull);
        }

        final textFinder =
            useShell ? inHost(find.text('Send')) : inBar(find.text('Send'));
        final textElem = tester.element(textFinder);
        expect(
          DefaultTextStyle.of(textElem).style.color,
          CupertinoColors.label.resolveFrom(textElem),
        );
        expect(DefaultTextStyle.of(textElem).style.fontWeight, FontWeight.w600);

        await tester.tap(textFinder);
        expect(taps, 0);
      });

      testWidgets(
          'in-route plain tinted icon also flips foreground to contrast white (shell: $useShell)',
          (tester) async {
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Tinted'),
              actions: [
                GlassBarItem.icon(
                  icon: const Icon(CupertinoIcons.heart_fill),
                  background: GlassBarItemBackground.separate,
                  tintColor: CupertinoColors.systemBlue,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final iconFinder = useShell
            ? inHost(find.byIcon(CupertinoIcons.heart_fill))
            : inBar(find.byIcon(CupertinoIcons.heart_fill));
        expect(
          IconTheme.of(tester.element(iconFinder)).color,
          const Color(0xFFFFFFFF),
        );
      });
    }

    testWidgets('prominent with explicit translucent tintColor preserves alpha',
        (tester) async {
      const translucentTint = Color(0x8034C759);
      await tester.pumpWidget(cupertinoShellApp(
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('Translucent'),
            actions: [
              GlassBarItem.text(
                title: 'Save',
                style: GlassBarItemStyle.prominent,
                tintColor: translucentTint,
                onTap: () {},
              ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ));
      await settle(tester);

      final shellBtn =
          tester.widget<GlassButton>(inHost(find.byType(GlassButton)));
      expect(shellBtn.settings?.glassColor, translucentTint);
      expect(shellBtn.settings?.bodyMode, GlassBodyMode.clear);
    });

    testWidgets('prominent with background: none renders bare accent text',
        (tester) async {
      for (final useShell in [true, false]) {
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          primaryColor: const Color(0xFFAF52DE),
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Bare'),
              actions: [
                GlassBarItem.text(
                  title: 'Apply',
                  style: GlassBarItemStyle.prominent,
                  background: GlassBarItemBackground.none,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        if (useShell) {
          expect(inHost(find.byType(GlassButton)), findsNothing);
        } else {
          expect(inBar(find.byType(GlassButtonGroup)), findsNothing);
        }
        final textFinder =
            useShell ? inHost(find.text('Apply')) : inBar(find.text('Apply'));
        final style = DefaultTextStyle.of(tester.element(textFinder)).style;
        expect(style.fontWeight, FontWeight.w600);
        expect(style.color, const Color(0xFFAF52DE));
      }
    });

    testWidgets('prominent in MaterialApp adopts Material primary color',
        (tester) async {
      const seedColor = Color(0xFF6750A4);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(primary: seedColor),
        ),
        builder: (context, child) => GlassNavigationShell(child: child!),
        home: Scaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('Material'),
            actions: [
              GlassBarItem.text(
                title: 'Save',
                style: GlassBarItemStyle.prominent,
                onTap: () {},
              ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ));
      await settle(tester);

      final shellBtn =
          tester.widget<GlassButton>(inHost(find.byType(GlassButton)));
      expect(
        shellBtn.settings?.glassColor,
        seedColor.withValues(alpha: GlassNavPinnedMetrics.prominentTintAlpha),
      );
    });
  });

  // ===========================================================================
  // 5. Semantics
  // ===========================================================================
  group('GlassBarItem.text semantics', () {
    for (final useShell in [true, false]) {
      testWidgets(
          'uses title as button semantics when label is null and replaces when label is set (shell: $useShell)',
          (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Contacts'),
              leading: [
                GlassBarItem.text(
                  title: 'Edit',
                  label: 'Edit contacts',
                  onTap: () {},
                ),
              ],
              actions: [
                GlassBarItem.text(
                  title: 'Done',
                  style: GlassBarItemStyle.prominent,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        Finder locate(Finder f) => useShell ? inHost(f) : inBar(f);

        final doneNode =
            tester.getSemantics(locate(find.bySemanticsLabel('Done')));
        expect(
          doneNode,
          isSemantics(label: 'Done', isButton: true, hasTapAction: true),
        );

        final editNode =
            tester.getSemantics(locate(find.bySemanticsLabel('Edit contacts')));
        expect(
          editNode,
          isSemantics(
            label: 'Edit contacts',
            isButton: true,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      });

      testWidgets(
          'disabled text item reports disabled semantics (shell: $useShell)',
          (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Compose'),
              actions: [
                GlassBarItem.text(
                  title: 'Send',
                  style: GlassBarItemStyle.prominent,
                  enabled: false,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final finder = useShell
            ? inHost(find.bySemanticsLabel('Send'))
            : inBar(find.bySemanticsLabel('Send'));
        final node = tester.getSemantics(finder);
        expect(
          node,
          isSemantics(
            label: 'Send',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasTapAction: false,
          ),
        );
        handle.dispose();
      });
    }
  });

  // ===========================================================================
  // 6. Route transitions & morphing
  // ===========================================================================
  group('route transitions and morphing', () {
    testWidgets(
        'identical GlassBarItem.text across routes stays frozen with no gel swell',
        (tester) async {
      await tester.pumpWidget(cupertinoShellApp(
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('Step 1'),
            actions: [
              GlassBarItem.text(
                title: 'Done',
                style: GlassBarItemStyle.prominent,
                onTap: () {},
              ),
            ],
          ),
          body: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => GlassScaffold(
                      appBar: GlassAppBar.pinned(
                        title: const Text('Step 2'),
                        actions: [
                          GlassBarItem.text(
                            title: 'Done',
                            style: GlassBarItemStyle.prominent,
                            onTap: () {},
                          ),
                        ],
                      ),
                      body: const SizedBox.expand(),
                    ),
                  ),
                ),
                child: const Text('next'),
              ),
            ),
          ),
        ),
      ));
      await settle(tester);

      Finder trailingCluster() => find
          .byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_PinnedCluster',
          )
          .last;

      final restSize = tester.getSize(trailingCluster());
      await tester.tap(find.text('next'));
      await tester.pump();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        expect(tester.getSize(trailingCluster()), restSize);
      }
      await settle(tester);
    });

    testWidgets(
        'plain Edit morphs smoothly into prominent Done with shell colour interpolation',
        (tester) async {
      await tester.pumpWidget(cupertinoShellApp(
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('View'),
            actions: [
              GlassBarItem.text(
                id: 'primary',
                title: 'Edit',
                background: GlassBarItemBackground.separate,
                onTap: () {},
              ),
            ],
          ),
          body: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => GlassScaffold(
                      appBar: GlassAppBar.pinned(
                        title: const Text('Editor'),
                        backButton: false,
                        actions: [
                          GlassBarItem.text(
                            id: 'primary',
                            title: 'Done',
                            style: GlassBarItemStyle.prominent,
                            onTap: () {},
                          ),
                        ],
                      ),
                      body: const SizedBox.expand(),
                    ),
                  ),
                ),
                child: const Text('edit'),
              ),
            ),
          ),
        ),
      ));
      await settle(tester);

      // Resting plain Edit has null settings override.
      expect(
        tester.widget<GlassButton>(inHost(find.byType(GlassButton))).settings,
        isNull,
      );

      await tester.tap(find.text('edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Mid-transition shell smoothly interpolates tint via GlassBodyMode.clear.
      final midButton =
          tester.widget<GlassButton>(inHost(find.byType(GlassButton)));
      expect(midButton.settings, isNotNull);
      expect(midButton.settings!.bodyMode, GlassBodyMode.clear);

      await settle(tester);

      // Settled prominent Done has full prominent accent fill.
      final settledButton =
          tester.widget<GlassButton>(inHost(find.byType(GlassButton)));
      final elem = tester.element(inHost(find.text('Done')));
      final expectedFill = CupertinoDynamicColor.resolve(
        CupertinoTheme.of(elem).primaryColor,
        elem,
      ).withValues(alpha: GlassNavPinnedMetrics.prominentTintAlpha);
      expect(settledButton.settings?.glassColor, expectedFill);

      // Pop back: returns to neutral null settings.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.widget<GlassButton>(inHost(find.byType(GlassButton))).settings,
        isNotNull,
      );
      await settle(tester);
      expect(
        tester.widget<GlassButton>(inHost(find.byType(GlassButton))).settings,
        isNull,
      );
    });

    testWidgets(
        'entering prominent item beside a surviving plain item materializes with its own layer rather than budding',
        (tester) async {
      await tester.pumpWidget(cupertinoShellApp(
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('List'),
            actions: [
              GlassBarItem.icon(
                id: 'share',
                icon: const Icon(CupertinoIcons.share),
                onTap: () {},
              ),
            ],
          ),
          body: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => GlassScaffold(
                      appBar: GlassAppBar.pinned(
                        title: const Text('Confirm'),
                        backButton: false,
                        actions: [
                          GlassBarItem.icon(
                            id: 'share',
                            icon: const Icon(CupertinoIcons.share),
                            onTap: () {},
                          ),
                          GlassBarItem.text(
                            id: 'save',
                            title: 'Save',
                            style: GlassBarItemStyle.prominent,
                            onTap: () {},
                          ),
                        ],
                      ),
                      body: const SizedBox.expand(),
                    ),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ));
      await settle(tester);

      await tester.tap(find.text('go'));
      await tester.pump();
      // Mid-transition after materializeStart (0.45): Save is materializing in,
      // both shells keep useOwnLayer: true (no neutral blend bridge).
      await tester.pump(const Duration(milliseconds: 280));

      final shells = tester
          .widgetList<GlassButton>(inHost(find.byType(GlassButton)))
          .toList();
      expect(shells, hasLength(2));
      for (final shell in shells) {
        expect(shell.useOwnLayer, isTrue);
      }

      await settle(tester);
      expect(inHost(find.text('Save')), findsOneWidget);
    });
  });

  // ===========================================================================
  // 7. iPhone Duo vertical strip & RTL
  // ===========================================================================
  group('iPhone Duo vertical strip', () {
    testWidgets(
      'keeps GlassBarItem.text horizontal while prominent icon goes vertical in the 48pt strip',
      (tester) async {
        setDuoScreen(tester);
        await tester.pumpWidget(cupertinoShellApp(
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('New Note'),
              actions: [
                GlassBarItem.text(
                  title: 'Cancel',
                  onTap: () {},
                ),
                GlassBarItem.icon(
                  icon: const Icon(CupertinoIcons.checkmark),
                  style: GlassBarItemStyle.prominent,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        // Text item stays in the horizontal title row (top ~48, left of strip at 382).
        final cancelCenter = tester.getCenter(inHost(find.text('Cancel')));
        expect(cancelCenter.dy, closeTo(48, 1.0));
        expect(cancelCenter.dx, lessThan(382));

        // Prominent icon moves into the 48pt vertical strip (center x = 418, y >= 170).
        final checkCenter =
            tester.getCenter(inHost(find.byIcon(CupertinoIcons.checkmark)));
        expect(checkCenter.dx, closeTo(418, 0.5));
        expect(checkCenter.dy, closeTo(170 + 24, 0.5));

        final checkShell = tester.widget<GlassButton>(find.ancestor(
          of: inHost(find.byIcon(CupertinoIcons.checkmark)),
          matching: find.byType(GlassButton),
        ));
        expect(checkShell.settings?.bodyMode, GlassBodyMode.clear);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'verticalPreferred pulls GlassBarItem.text into the 48pt strip and overflows with title',
      (tester) async {
        setDuoScreen(tester);
        await tester.pumpWidget(cupertinoShellApp(
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Detail'),
              actions: [
                GlassBarItem.text(
                  title: 'Done',
                  style: GlassBarItemStyle.prominent,
                  axisBehavior: GlassBarItemAxisBehavior.verticalPreferred,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final doneShellFinder = find.ancestor(
          of: inHost(find.text('Done')),
          matching: find.byType(GlassButton),
        );
        final doneRect = tester.getRect(doneShellFinder);
        expect(doneRect.width,
            closeTo(GlassVerticalBarMetrics.controlExtent, 0.5));
        expect(doneRect.center.dx, closeTo(418, 0.5));
        expect(doneRect.top, greaterThanOrEqualTo(170));

        // Verify fitGlassNavStripGroups uses title / label fallback on overflow.
        final groups = groupGlassNavBarItems(
          [
            GlassBarItem.icon(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
            ),
            GlassBarItem.text(
              title: 'Save',
              axisBehavior: GlassBarItemAxisBehavior.verticalPreferred,
              onTap: () {},
            ),
            GlassBarItem.text(
              title: 'Edit',
              label: 'Edit item',
              axisBehavior: GlassBarItemAxisBehavior.verticalPreferred,
              onTap: () {},
            ),
          ],
          axis: Axis.vertical,
        );
        final fitted = fitGlassNavStripGroups(groups, 110.0);
        final overflowGroup = fitted.last;
        final overflowMenu = overflowGroup.items.single as GlassBarMenuItem;
        final menuTitles = overflowMenu.menuItems
            .whereType<GlassMenuItem>()
            .map((m) => m.title)
            .toList();
        expect(menuTitles, containsAllInOrder(['Save', 'Edit item']));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  group('RTL layout and hand-over', () {
    testWidgets(
        'prominent text action aligns to trailing edge (physical left) and preserves RTL across hand-over',
        (tester) async {
      TextDirection? capturedDirection;
      await tester.pumpWidget(cupertinoShellApp(
        textDirection: TextDirection.rtl,
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('العنوان'),
            actions: [
              GlassBarItem.icon(
                icon: const Icon(CupertinoIcons.share),
                onTap: () {},
              ),
              GlassBarItem.text(
                title: 'تم',
                style: GlassBarItemStyle.prominent,
                onTap: () {},
              ),
            ],
          ),
          body: Builder(
            builder: (context) => Center(
              child: CupertinoButton(
                onPressed: () {
                  showCupertinoModalPopup<void>(
                    context: context,
                    builder: (_) => const SizedBox(height: 200),
                  );
                },
                child: const Text('present'),
              ),
            ),
          ),
        ),
      ));
      await settle(tester);

      final doneHoistedFinder = inHost(find.text('تم'));
      final shareHoistedFinder = inHost(find.byIcon(CupertinoIcons.share));
      capturedDirection = Directionality.of(tester.element(doneHoistedFinder));
      expect(capturedDirection, TextDirection.rtl);

      final doneHoistedDx = tester.getCenter(doneHoistedFinder).dx;
      final shareHoistedDx = tester.getCenter(shareHoistedFinder).dx;
      // In RTL, trailing actions.last ('تم') sits at physical left (< share).
      expect(doneHoistedDx, lessThan(shareHoistedDx));

      // Present modal popup -> hands chrome back to in-route GlassAppBar.
      await tester.tap(find.text('present'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final doneInRouteFinder = inBar(find.text('تم'));
      final shareInRouteFinder = inBar(find.byIcon(CupertinoIcons.share));
      expect(
        Directionality.of(tester.element(doneInRouteFinder)),
        TextDirection.rtl,
      );
      expect(
        tester.getCenter(doneInRouteFinder).dx,
        lessThan(tester.getCenter(shareInRouteFinder).dx),
      );
    });

    testWidgets(
      'on iPhone Duo under RTL, GlassBarItem.text sits at physical left of the horizontal row',
      (tester) async {
        setDuoScreen(tester);
        await tester.pumpWidget(cupertinoShellApp(
          textDirection: TextDirection.rtl,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('العنوان'),
              actions: [
                GlassBarItem.text(
                  title: 'تم',
                  style: GlassBarItemStyle.prominent,
                  onTap: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final doneRect = tester.getRect(inHost(find.text('تم')));
        final titleRect = tester.getRect(find.text('العنوان'));
        expect(doneRect.center.dy, closeTo(48, 1.0));
        // Physical strip is on the right; title starts near the strip and the
        // horizontal text item sits at the trailing end (physical left).
        expect(doneRect.center.dx, lessThan(titleRect.center.dx));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  // ===========================================================================
  // 8. Prominent custom, menu, sheet & GlassPinnedBarChrome integration
  // ===========================================================================
  group('prominent across custom, menu, sheet and GlassPinnedBarChrome', () {
    for (final useShell in [true, false]) {
      testWidgets(
          'prominent custom item applies contrast foreground to both icon and text (shell: $useShell)',
          (tester) async {
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('AI'),
              actions: [
                GlassBarItem.custom(
                  style: GlassBarItemStyle.prominent,
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.sparkles),
                        SizedBox(width: 4),
                        Text('Ask'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final iconFinder = useShell
            ? inHost(find.byIcon(CupertinoIcons.sparkles))
            : inBar(find.byIcon(CupertinoIcons.sparkles));
        final textFinder =
            useShell ? inHost(find.text('Ask')) : inBar(find.text('Ask'));
        expect(
          IconTheme.of(tester.element(iconFinder)).color,
          const Color(0xFFFFFFFF),
        );
        expect(
          DefaultTextStyle.of(tester.element(textFinder)).style.color,
          const Color(0xFFFFFFFF),
        );
      });

      testWidgets(
          'prominent menu and sheet items render tinted shell and stay interactive (shell: $useShell)',
          (tester) async {
        GlassMorphAnchor? receivedAnchor;
        var sheetCalled = false;
        await tester.pumpWidget(cupertinoShellApp(
          shell: useShell,
          GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Tools'),
              leading: [
                GlassBarItem.menu(
                  icon: const Icon(CupertinoIcons.ellipsis),
                  style: GlassBarItemStyle.prominent,
                  label: 'Options',
                  menuItems: [
                    GlassMenuItem(title: 'Export', onTap: () {}),
                  ],
                ),
              ],
              actions: [
                GlassBarItem.sheet(
                  icon: const Icon(CupertinoIcons.add),
                  style: GlassBarItemStyle.prominent,
                  label: 'Compose',
                  onPresent: (anchor) {
                    sheetCalled = true;
                    receivedAnchor = anchor;
                  },
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ));
        await settle(tester);

        final addFinder = useShell
            ? inHost(find.byIcon(CupertinoIcons.add))
            : inBar(find.byIcon(CupertinoIcons.add));
        expect(
          IconTheme.of(tester.element(addFinder)).color,
          const Color(0xFFFFFFFF),
        );
        await tester.tap(addFinder);
        await tester.pump();
        expect(sheetCalled, isTrue);
        expect(receivedAnchor, isNotNull);
      });
    }

    testWidgets(
        'GlassPinnedBarChrome pins GlassBarItem.text and prominent items on Material AppBar',
        (tester) async {
      var saved = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => GlassNavigationShell(child: child!),
        home: GlassPinnedBarChrome(
          leading: [
            GlassBarItem.text(
              title: 'Cancel',
              onTap: () {},
            ),
          ],
          actions: [
            GlassBarItem.text(
              title: 'Save',
              style: GlassBarItemStyle.prominent,
              onTap: () => saved++,
            ),
          ],
          builder: (context, chrome) => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leadingWidth: 140,
              leading: chrome.leading,
              actions: chrome.actions,
              title: const Text('Custom Bar'),
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ));
      await settle(tester);

      expect(inHost(find.text('Cancel')), findsOneWidget);
      expect(inHost(find.text('Save')), findsOneWidget);
      await tester.tap(inHost(find.text('Save')));
      expect(saved, 1);
    });

    testWidgets('prominent-to-prominent morph smoothly lerps tint colour',
        (tester) async {
      const blue = Color(0xFF007AFF);
      const green = Color(0xFF34C759);
      await tester.pumpWidget(cupertinoShellApp(
        GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('A'),
            actions: [
              GlassBarItem.text(
                id: 'cta',
                title: 'Next',
                style: GlassBarItemStyle.prominent,
                tintColor: blue,
                onTap: () {},
              ),
            ],
          ),
          body: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => GlassScaffold(
                      appBar: GlassAppBar.pinned(
                        title: const Text('B'),
                        backButton: false,
                        actions: [
                          GlassBarItem.text(
                            id: 'cta',
                            title: 'Done',
                            style: GlassBarItemStyle.prominent,
                            tintColor: green,
                            onTap: () {},
                          ),
                        ],
                      ),
                      body: const SizedBox.expand(),
                    ),
                  ),
                ),
                child: const Text('push'),
              ),
            ),
          ),
        ),
      ));
      await settle(tester);

      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));

      final midColor = tester
          .widget<GlassButton>(inHost(find.byType(GlassButton)))
          .settings
          ?.glassColor;
      expect(midColor, isNotNull);
      expect(
        midColor,
        isNot(blue.withValues(alpha: GlassNavPinnedMetrics.prominentTintAlpha)),
      );
      expect(
        midColor,
        isNot(
            green.withValues(alpha: GlassNavPinnedMetrics.prominentTintAlpha)),
      );

      await settle(tester);
      final finalColor = tester
          .widget<GlassButton>(inHost(find.byType(GlassButton)))
          .settings
          ?.glassColor;
      expect(
        finalColor,
        green.withValues(alpha: GlassNavPinnedMetrics.prominentTintAlpha),
      );
    });
  });
}
