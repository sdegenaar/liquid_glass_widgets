import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('GlassPullDownButton toggles menu and handles selection',
      (WidgetTester tester) async {
    String selectedAction = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                label: 'Options',
                buttonWidth: 200, // Sufficient for "Options" text
                onSelected: (value) => selectedAction = value,
                items: [
                  GlassMenuItem(
                    title: 'Edit',
                    icon: Icon(CupertinoIcons.pen),
                    onTap: () {},
                  ),
                  GlassMenuItem(
                    title: 'Delete',
                    icon: Icon(CupertinoIcons.trash),
                    isDestructive: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state check
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    // Tap button to open menu
    await tester.tap(find.text('Options'));
    await tester.pump();
    await tester
        .pumpAndSettle(); // Wait for animation to complete (content appears at 65%+)

    // Menu should be open
    expect(find.text('Edit'), findsOneWidget);

    // Tap menu item
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify selection and closure
    expect(selectedAction, equals('Edit'));
    expect(find.text('Edit'), findsNothing);
  });

  // ── Icon-only button path (lines 99-106: label == null → GlassButton) ──────
  testWidgets('GlassPullDownButton icon-only (no label) uses GlassButton path',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                // label is null — exercises the else branch (line 99-106)
                items: [
                  GlassMenuItem(
                    title: 'Copy',
                    icon: Icon(CupertinoIcons.doc_on_doc),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlassPullDownButton), findsOneWidget);
  });

  // ── line 63: label != null but empty triggers else branch too ───────────────
  testWidgets('GlassPullDownButton empty-string label takes icon-only path',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                label: '', // empty → !label!.isNotEmpty → else branch
                items: [
                  GlassMenuItem(
                    title: 'Share',
                    icon: Icon(CupertinoIcons.share),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlassPullDownButton), findsOneWidget);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // semanticLabel
  // ────────────────────────────────────────────────────────────────────────────

  group('GlassPullDownButton semanticLabel', () {
    testWidgets('icon-only button uses semanticLabel as accessible name',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveLiquidGlassLayer(
              child: Center(
                child: GlassPullDownButton(
                  icon: const Icon(CupertinoIcons.ellipsis_circle),
                  semanticLabel: 'More options',
                  items: const [
                    GlassMenuItem(title: 'Action A', onTap: _noop),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // The GlassButton inside should carry the semanticLabel as its label
      final buttons = tester.widgetList<GlassButton>(
        find.descendant(
          of: find.byType(GlassPullDownButton),
          matching: find.byType(GlassButton),
        ),
      );
      expect(
        buttons.any((b) => b.label == 'More options'),
        isTrue,
        reason: 'semanticLabel must be passed through to GlassButton.label',
      );
    });

    test('semanticLabel is null by default', () {
      final btn = GlassPullDownButton(
        items: const [GlassMenuItem(title: 'Action', onTap: _noop)],
      );
      expect(btn.semanticLabel, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Issue #214: Minimal quality & platformViewBackdrop regression
  // ────────────────────────────────────────────────────────────────────────────

  testWidgets(
      'GlassPullDownButton opens and functions properly in minimal quality mode (#214)',
      (WidgetTester tester) async {
    String selectedAction = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveLiquidGlassLayer(
            quality: GlassQuality.minimal,
            child: Center(
              child: GlassPullDownButton(
                label: 'Options',
                buttonWidth: 200,
                quality: GlassQuality.minimal,
                onSelected: (value) => selectedAction = value,
                items: [
                  GlassMenuItem(
                    title: 'Option A',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Option A'), findsNothing);

    // Tap button to open menu in minimal quality mode
    await tester.tap(find.text('Options'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Menu should be open and rendered without throwing InheritedGeometryRenderLink assertion
    expect(find.text('Option A'), findsOneWidget);

    await tester.tap(find.text('Option A'));
    await tester.pumpAndSettle();

    expect(selectedAction, equals('Option A'));
  });

  testWidgets(
      'GlassMenu opens in minimal quality mode with platformViewBackdrop (#214)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              quality: GlassQuality.minimal,
              platformViewBackdrop: true,
              trigger: const Text('Open Menu'),
              items: [
                GlassMenuItem(
                  title: 'Item 1',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Menu'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('GlassPullDownButton preserves submenu when onSelected is set',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                icon: const Icon(CupertinoIcons.ellipsis_circle),
                onSelected: (title) {},
                items: const [
                  GlassMenuItem(
                    title: 'Share',
                    onTap: _noop,
                    submenu: [
                      GlassMenuItem(title: 'Sub 1', onTap: _noop),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final menu = tester.widget<GlassMenu>(find.byType(GlassMenu));
    final item = menu.items.first as GlassMenuItem;
    expect(item.submenu, isNotNull);
    expect(item.submenu!.length, 1);
  });

  testWidgets(
      'GlassPullDownButton preserves semanticsSelected when onSelected is set',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                icon: const Icon(CupertinoIcons.ellipsis_circle),
                onSelected: (title) {},
                items: const [
                  GlassMenuItem(
                    title: 'Name',
                    onTap: _noop,
                    semanticsSelected: true,
                  ),
                  GlassMenuItem(
                    title: 'Date',
                    onTap: _noop,
                    semanticsSelected: false,
                  ),
                  GlassMenuItem(title: 'Size', onTap: _noop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final menu = tester.widget<GlassMenu>(find.byType(GlassMenu));
    final items = menu.items.cast<GlassMenuItem>();
    expect(items.map((item) => item.semanticsSelected), [true, false, null]);
  });

  testWidgets('GlassPullDownButton forwards menuSemanticLabel to GlassMenu',
      (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                menuSemanticLabel: 'Sort options',
                items: [
                  GlassMenuItem(title: 'Name', onTap: _noop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final menu = tester.widget<GlassMenu>(find.byType(GlassMenu));
    expect(menu.menuSemanticLabel, 'Sort options');
  });

  testWidgets('GlassPullDownButton long menu stops at screen edge and scrolls',
      (tester) async {
    var chosen = false;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Align(
            alignment: Alignment.topRight,
            child: GlassPullDownButton(
              icon: const Icon(CupertinoIcons.ellipsis_circle),
              items: [
                for (var i = 1; i <= 30; i++)
                  GlassMenuItem(
                    title: 'Row $i',
                    onTap: () => chosen = i == 30,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GlassPullDownButton));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Row 1'), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final screen =
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(screen.contains(tester.getCenter(find.text('Row 30'))), isTrue);

    await tester.tap(find.text('Row 30'));
    await tester.pumpAndSettle();
    expect(chosen, isTrue);
  });

  testWidgets(
      'GlassPullDownButton long submenu stops at screen edge and scrolls',
      (tester) async {
    var chosen = false;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Align(
            alignment: Alignment.topRight,
            child: GlassPullDownButton(
              icon: const Icon(CupertinoIcons.ellipsis_circle),
              items: [
                GlassMenuItem(title: 'Copy', onTap: () {}),
                GlassMenuItem(
                  title: 'Move to…',
                  onTap: () {},
                  submenu: [
                    for (var i = 1; i <= 30; i++)
                      GlassMenuItem(
                        title: 'Folder $i',
                        onTap: () => chosen = i == 30,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GlassPullDownButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Move to…'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Folder 1'), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final screen =
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(screen.contains(tester.getCenter(find.text('Folder 30'))), isTrue);

    await tester.tap(find.text('Folder 30'));
    await tester.pumpAndSettle();
    expect(chosen, isTrue);
  });

  testWidgets(
      'GlassPullDownButton with label and buttonWidth < buttonHeight uses buttonWidth for capsule radius',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: GlassPullDownButton(
              label: 'A',
              buttonWidth: 80,
              buttonHeight: 100,
              items: [
                GlassMenuItem(title: 'Item', onTap: _noop),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
  });

  group(
      'GlassPullDownButton intrinsic sizing, submenu recursion & passthroughs',
      () {
    test('buttonWidth is null and menuPadding defaults to horizontal 12', () {
      const btn = GlassPullDownButton(
        items: [GlassMenuItem(title: 'Action', onTap: _noop)],
      );
      expect(btn.buttonWidth, isNull);
      expect(btn.menuPadding, const EdgeInsets.symmetric(horizontal: 12));
      expect(btn.menuBorderRadius, 32.0);
      expect(btn.morphSpeed, MorphSpeed.normal);
    });

    testWidgets(
        'icon-only defaults to 44pt while labeled button sizes intrinsically inside a Row',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  GlassPullDownButton(
                    key: ValueKey('icon_only_pd'),
                    items: [GlassMenuItem(title: 'One', onTap: _noop)],
                  ),
                  SizedBox(width: 12),
                  GlassPullDownButton(
                    key: ValueKey('labeled_pd'),
                    label: 'Select Workspace Options',
                    items: [GlassMenuItem(title: 'One', onTap: _noop)],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconSize =
          tester.getSize(find.byKey(const ValueKey('icon_only_pd')));
      final labeledSize =
          tester.getSize(find.byKey(const ValueKey('labeled_pd')));

      expect(iconSize.width, 44.0);
      expect(iconSize.height, 44.0);
      expect(labeledSize.width, greaterThan(160.0));
      expect(labeledSize.height, 44.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('icon-only button with non-square explicit width uses capsule',
        (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassPullDownButton(
                buttonWidth: 64,
                buttonHeight: 44,
                items: [GlassMenuItem(title: 'One', onTap: _noop)],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final btn = tester.widget<GlassButton>(find.byType(GlassButton));
      expect(btn.width, 64.0);
      expect(btn.shape, isA<LiquidRoundedSuperellipse>());
    });

    testWidgets(
        'onSelected recurses into nested submenu and doubly-nested submenu items',
        (tester) async {
      final selectedTitles = <String>[];
      var leafTapped = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassPullDownButton(
                label: 'Actions',
                onSelected: selectedTitles.add,
                items: [
                  GlassMenuItem(
                    title: 'Share…',
                    onTap: _noop,
                    submenu: [
                      GlassMenuItem(
                        title: 'More Channels…',
                        onTap: _noop,
                        submenu: [
                          GlassMenuItem(
                            title: 'Encrypted SMS',
                            onTap: () => leafTapped = true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share…'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('More Channels…'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Encrypted SMS'));
      await tester.pumpAndSettle();

      expect(leafTapped, isTrue);
      expect(selectedTitles, ['Encrypted SMS']);
    });

    testWidgets(
        'forwards menuPadding, menuBorderRadius, menuAlignment, morphSpeed, controller, and onClose to GlassMenu',
        (tester) async {
      final menuController = GlassMenuController();
      var closeCount = 0;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: GlassPullDownButton(
                label: 'Menu',
                menuPadding: const EdgeInsets.all(20),
                menuBorderRadius: 28.0,
                menuAlignment: GlassMenuAlignment.topCenter,
                morphSpeed: MorphSpeed.fast,
                controller: menuController,
                onClose: () => closeCount++,
                items: const [
                  GlassMenuItem(title: 'First', onTap: _noop),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final glassMenu = tester.widget<GlassMenu>(find.byType(GlassMenu));
      expect(glassMenu.menuPadding, const EdgeInsets.all(20));
      expect(glassMenu.menuBorderRadius, 28.0);
      expect(glassMenu.menuAlignment, GlassMenuAlignment.topCenter);
      expect(glassMenu.morphSpeed, MorphSpeed.fast);
      expect(glassMenu.controller, same(menuController));

      menuController.open();
      await tester.pumpAndSettle();
      expect(find.text('First'), findsOneWidget);

      menuController.close();
      await tester.pumpAndSettle();
      expect(closeCount, 1);
      expect(find.text('First'), findsNothing);
    });
  });
}

void _noop() {}
