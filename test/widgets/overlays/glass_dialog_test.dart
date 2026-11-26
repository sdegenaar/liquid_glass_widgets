// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/glass_materialize_scope.dart';
import 'package:liquid_glass_widgets/src/widgets/overlays/glass_alert_platter.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassDialog', () {
    final testActions = [
      GlassDialogAction(
        label: 'Cancel',
        onPressed: () {},
      ),
      GlassDialogAction(
        label: 'OK',
        onPressed: () {},
      ),
    ];

    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            actions: testActions,
          ),
        ),
      );

      expect(find.byType(GlassDialog), findsOneWidget);
    });

    testWidgets('displays title when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            title: 'Alert',
            actions: testActions,
          ),
        ),
      );

      expect(find.text('Alert'), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            title: 'Confirm',
            message: 'Are you sure?',
            actions: testActions,
          ),
        ),
      );

      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('displays custom content when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            content: const Text('Custom Content'),
            actions: testActions,
          ),
        ),
      );

      expect(find.text('Custom Content'), findsOneWidget);
    });

    testWidgets('displays all action buttons', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            actions: testActions,
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('action buttons call onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassDialog(
            actions: [
              GlassDialogAction(
                label: 'Press Me',
                onPressed: () => pressed = true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Press Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows dialog with static show method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  GlassDialog.show(
                    context: context,
                    title: 'Test Dialog',
                    actions: testActions,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
    });

    test('defaults are correct', () {
      final dialog = GlassDialog(
        actions: testActions,
      );

      expect(dialog.maxWidth, isNull,
          reason: 'null follows the active style: 320 native, 280 classic');
      expect(dialog.quality, isNull);
    });

    test('asserts 1-3 actions', () {
      expect(
        () => GlassDialog(actions: []),
        throwsAssertionError,
      );

      expect(
        () => GlassDialog(
          actions: List.generate(
            4,
            (i) => GlassDialogAction(
              label: 'Action $i',
              onPressed: () {},
            ),
          ),
        ),
        throwsAssertionError,
      );
    });
  });

  group('GlassDialogAction', () {
    test('can be instantiated', () {
      final action = GlassDialogAction(
        label: 'OK',
        onPressed: () {},
      );

      expect(action.label, equals('OK'));
      expect(action.isPrimary, isFalse);
      expect(action.isDestructive, isFalse);
      expect(action.tintColor, isNull);
      expect(action.foregroundColor, isNull);
    });

    test('can configure custom tintColor and foregroundColor', () {
      final action = GlassDialogAction(
        label: 'Subscribe',
        onPressed: () {},
        isPrimary: true,
        tintColor: CupertinoColors.systemPurple,
        foregroundColor: CupertinoColors.white,
      );

      expect(action.isPrimary, isTrue);
      expect(action.tintColor, equals(CupertinoColors.systemPurple));
      expect(action.foregroundColor, equals(CupertinoColors.white));
    });

    test('can be marked as primary', () {
      final action = GlassDialogAction(
        label: 'Save',
        onPressed: () {},
        isPrimary: true,
      );

      expect(action.isPrimary, isTrue);
    });

    test('can be marked as destructive', () {
      final action = GlassDialogAction(
        label: 'Delete',
        onPressed: () {},
        isDestructive: true,
      );

      expect(action.isDestructive, isTrue);
    });
  });

  group('GlassDialog action layout', () {
    List<GlassDialogAction> two(String a, String b) => [
          GlassDialogAction(label: a, onPressed: () {}),
          GlassDialogAction(label: b, onPressed: () {}, isPrimary: true),
        ];

    Future<void> pumpDialog(
      WidgetTester tester,
      List<GlassDialogAction> actions, {
      double textScale = 1.0,
    }) async {
      await tester.pumpWidget(
        createTestApp(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: GlassDialog(title: 'Title', actions: actions),
          ),
        ),
      );
    }

    final inRow = find.descendant(
      of: find.byType(GlassDialog),
      matching: find.byType(Row),
    );

    testWidgets('keeps two short labels side by side', (tester) async {
      // The test font draws every glyph a full em wide, so "short" here is
      // a few letters.
      await pumpDialog(tester, two('No', 'OK'));

      expect(inRow, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('No')).dy,
        tester.getTopLeft(find.text('OK')).dy,
      );
    });

    testWidgets('stacks two actions when a label is too long', (tester) async {
      await pumpDialog(
          tester, two('Cancel', 'Continue without saving changes'));

      expect(inRow, findsNothing);
      expect(
        tester.getTopLeft(find.text('Continue without saving changes')).dy,
        greaterThan(tester.getTopLeft(find.text('Cancel')).dy),
      );
    });

    testWidgets('stacks two short labels at a large text scale',
        (tester) async {
      await pumpDialog(tester, two('No', 'OK'), textScale: 4.0);

      expect(inRow, findsNothing);
    });

    testWidgets('keeps a single long action in the horizontal row',
        (tester) async {
      await pumpDialog(tester, [
        GlassDialogAction(
          label: 'Continue without saving',
          onPressed: () {},
          isPrimary: true,
        ),
      ]);

      expect(inRow, findsOneWidget);
    });
  });

  group(
      'GlassDialog & showGlassActionSheet materialize transition & standard optics',
      () {
    List<BackdropFilterLayer> collectBackdropLayers(Layer root) {
      final result = <BackdropFilterLayer>[];
      void visit(Layer layer) {
        if (layer is BackdropFilterLayer) result.add(layer);
        if (layer is ContainerLayer) {
          var child = layer.firstChild;
          while (child != null) {
            visit(child);
            child = child.nextSibling;
          }
        }
      }

      visit(root);
      return result;
    }

    bool hasOpacityAncestor(Layer layer) {
      var parent = layer.parent;
      while (parent != null) {
        if (parent is OpacityLayer) return true;
        parent = parent.parent;
      }
      return false;
    }

    for (final style in GlassStyle.values) {
      for (final quality in [GlassQuality.premium, GlassQuality.standard]) {
        testWidgets(
            'GlassDialog.show has zero OpacityLayer over BackdropFilterLayer on entrance and exit ($style, $quality)',
            (tester) async {
          await tester.runAsync(LightweightLiquidGlass.preWarm);

          await tester.pumpWidget(
            GlassTheme(
              data: GlassThemeData(style: style, brightness: Brightness.dark),
              child: MaterialApp(
                home: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      GlassDialog.show<void>(
                        context: context,
                        title: 'Delete Item?',
                        message: 'This action cannot be undone.',
                        quality: quality,
                        actions: [
                          GlassDialogAction(
                            label: 'Cancel',
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .pop(),
                          ),
                          GlassDialogAction(
                            label: 'Delete',
                            isDestructive: true,
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .pop(),
                          ),
                        ],
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Open Dialog'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));

          // Mid-entrance: no ancestor FadeTransition and no OpacityLayer above
          // any BackdropFilterLayer.
          expect(
            find.ancestor(
              of: find.byType(GlassDialog),
              matching: find.byType(FadeTransition),
            ),
            findsNothing,
          );
          final entranceScope = tester.widget<GlassMaterializeScope>(
            find.ancestor(
              of: find.byType(GlassDialog),
              matching: find.byType(GlassMaterializeScope),
            ),
          );
          expect(entranceScope.glassProgress, greaterThan(0.0));
          expect(entranceScope.glassProgress, lessThan(1.0));
          expect(
            entranceScope.glassProgress,
            greaterThan(entranceScope.contentOpacity),
            reason: 'Entrance resolves glass ahead of content',
          );

          final entranceBackdrops =
              collectBackdropLayers(tester.binding.renderView.debugLayer!);
          expect(entranceBackdrops, isNotEmpty);
          for (final backdrop in entranceBackdrops) {
            expect(hasOpacityAncestor(backdrop), isFalse);
          }

          await tester.pumpAndSettle();

          // Dismiss and verify reverse exit co-dissolves at scale 1.0 with no
          // OpacityLayer above BackdropFilterLayer.
          await tester.tap(find.text('Cancel'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));

          final exitScope = tester.widget<GlassMaterializeScope>(
            find.ancestor(
              of: find.byType(GlassDialog),
              matching: find.byType(GlassMaterializeScope),
            ),
          );
          expect(exitScope.glassProgress, greaterThan(0.0));
          expect(exitScope.glassProgress, lessThan(1.0));
          expect(
            exitScope.glassProgress,
            closeTo(exitScope.contentOpacity, 1e-6),
            reason: 'Exit co-dissolves glass and content together',
          );
          expect(exitScope.contentSigma, 0.0);

          final exitBackdrops =
              collectBackdropLayers(tester.binding.renderView.debugLayer!);
          expect(exitBackdrops, isNotEmpty);
          for (final backdrop in exitBackdrops) {
            expect(hasOpacityAncestor(backdrop), isFalse);
          }

          await tester.pumpAndSettle();
          expect(find.byType(GlassDialog), findsNothing);
        });
      }
    }

    testWidgets(
        'showGlassActionSheet on ios27 has zero OpacityLayer over BackdropFilterLayer mid-transition',
        (tester) async {
      await tester.runAsync(LightweightLiquidGlass.preWarm);

      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData.ios27(brightness: Brightness.dark),
          child: CupertinoApp(
            home: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  showGlassActionSheet<void>(
                    context: context,
                    title: 'Choose Action',
                    actions: [
                      GlassActionSheetAction(
                        label: 'Share',
                        onPressed: () {},
                      ),
                    ],
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(
        find.ancestor(
          of: find.byType(GlassAlertPlatter),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      final backdrops =
          collectBackdropLayers(tester.binding.renderView.debugLayer!);
      expect(backdrops, isNotEmpty);
      for (final backdrop in backdrops) {
        expect(hasOpacityAncestor(backdrop), isFalse);
      }

      await tester.pumpAndSettle();
    });

    testWidgets(
        'standard quality dark alert platters calibrate blur, ambient darkening, and tint while preserving premium defaults',
        (tester) async {
      for (final (style, expectedTint) in [
        (GlassStyle.ios27, const Color(0x22FFFFFF)),
        (GlassStyle.ios26, const Color(0x18FFFFFF)),
      ]) {
        await tester.pumpWidget(
          GlassTheme(
            data: GlassThemeData(style: style, brightness: Brightness.dark),
            child: CupertinoApp(
              home: GlassDialog(
                title: 'Dark Standard Alert',
                message: 'Legible over bright background content.',
                quality: GlassQuality.standard,
                actions: [
                  GlassDialogAction(label: 'OK', onPressed: () {}),
                ],
              ),
            ),
          ),
        );

        final adaptive = tester.widget<AdaptiveGlass>(
          find
              .descendant(
                of: find.byType(GlassAlertPlatter),
                matching: find.byType(AdaptiveGlass),
              )
              .first,
        );
        expect(adaptive.quality, GlassQuality.standard);
        expect(adaptive.settings.blur, 18.0);
        expect(adaptive.settings.ambientStrength, 0.75);
        expect(adaptive.settings.glassColor, expectedTint);
      }
    });

    testWidgets(
        'stateful content and autofocused CupertinoTextField inside GlassDialog.show mount once and retain focus across entrance and exit',
        (tester) async {
      await tester.runAsync(LightweightLiquidGlass.preWarm);
      var initCount = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData.ios27(brightness: Brightness.light),
          child: CupertinoApp(
            home: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  GlassDialog.show<void>(
                    context: context,
                    title: 'Rename Folder',
                    content: _DialogInputProbe(
                      focusNode: focusNode,
                      onInit: () => initCount++,
                    ),
                    actions: [
                      GlassDialogAction(
                        label: 'Done',
                        isPrimary: true,
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                      ),
                    ],
                  );
                },
                child: const Text('Rename'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rename'));
      // Frame 0 (progress == 0.0)
      await tester.pump();
      expect(initCount, 1);

      // Frame 1+ (crossing 0.0 → >0.0 → settled at 1.0)
      await tester.pump(const Duration(milliseconds: 16));
      expect(initCount, 1, reason: 'Must not remount content on frame 1');
      await tester.pumpAndSettle();
      expect(initCount, 1, reason: 'Must not remount content on settle');
      expect(focusNode.hasFocus, isTrue);

      await tester.enterText(find.byType(CupertinoTextField), 'Invoices');
      expect(find.text('Invoices'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pump(const Duration(milliseconds: 60));
      expect(initCount, 1, reason: 'Must not remount content during exit');
      await tester.pumpAndSettle();
    });

    testWidgets(
        'mid-entrance fast-dismiss rewinds continuously without snapping scale or content channels',
        (tester) async {
      late BuildContext hostContext;
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassTheme(
            data: GlassThemeData.ios27(brightness: Brightness.dark),
            child: Builder(
              builder: (context) {
                hostContext = context;
                return CupertinoButton(
                  onPressed: () {
                    GlassDialog.show<void>(
                      context: context,
                      quality: GlassQuality.standard,
                      title: 'Fast Dismiss',
                      message: 'Cancelled mid-entrance',
                      actions: [
                        GlassDialogAction(
                          label: 'OK',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      // Advance partway into the entrance (~64ms, 0 < progress < 0.9)
      await tester.pump(const Duration(milliseconds: 64));

      GlassMaterializeScope readScope() => tester.widget<GlassMaterializeScope>(
            find.byType(GlassMaterializeScope),
          );
      double readScale() {
        final transform = tester.widget<Transform>(
          find.ancestor(
            of: find.byType(GlassMaterializeScope),
            matching: find.byType(Transform),
          ),
        );
        return transform.transform.storage[0];
      }

      final beforeScope = readScope();
      final beforeScale = readScale();
      expect(beforeScope.glassProgress, greaterThan(0.1));
      expect(beforeScope.glassProgress, lessThan(0.95));
      expect(beforeScope.contentSigma, greaterThan(0.5));
      expect(beforeScale, greaterThan(1.002));

      // Pop mid-entrance before settling: reversal frame (dt = 0) must not snap
      Navigator.of(hostContext, rootNavigator: true).pop();
      await tester.pump();

      final reverseScope = readScope();
      final reverseScale = readScale();
      expect(
          reverseScope.glassProgress, closeTo(beforeScope.glassProgress, 1e-6));
      expect(
        reverseScope.contentOpacity,
        closeTo(beforeScope.contentOpacity, 1e-6),
      );
      expect(
          reverseScope.contentSigma, closeTo(beforeScope.contentSigma, 1e-6));
      expect(reverseScale, closeTo(beforeScale, 1e-6));

      // Advancing 16ms in reverse rewinds monotonically toward 0
      await tester.pump(const Duration(milliseconds: 16));
      final rewoundScope = readScope();
      expect(rewoundScope.glassProgress, lessThan(beforeScope.glassProgress));

      await tester.pumpAndSettle();
      expect(find.text('Fast Dismiss'), findsNothing);
    });
  });
}

class _DialogInputProbe extends StatefulWidget {
  const _DialogInputProbe({
    required this.focusNode,
    required this.onInit,
  });

  final FocusNode focusNode;
  final VoidCallback onInit;

  @override
  State<_DialogInputProbe> createState() => _DialogInputProbeState();
}

class _DialogInputProbeState extends State<_DialogInputProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      focusNode: widget.focusNode,
      autofocus: true,
    );
  }
}
