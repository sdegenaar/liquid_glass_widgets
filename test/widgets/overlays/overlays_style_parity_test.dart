import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/overlays/glass_sheet_defaults.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/tab_bar_searchable_internal.dart'
    show DismissPill;
import 'package:liquid_glass_widgets/theme/glass_theme_helpers.dart';
import 'package:liquid_glass_widgets/widgets/overlays/glass_modal_sheet.dart'
    show SheetMorphGeometry;

void main() {
  group('Overlays 3-Tier GlassStyle & Brightness Parity', () {
    // ─────────────────────────────────────────────────────────────────────────
    // 1. GlassThemeHelpers.resolveSettings with widget fallbacks
    // ─────────────────────────────────────────────────────────────────────────
    group('GlassThemeHelpers.resolveSettings', () {
      for (final style in GlassStyle.values) {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          testWidgets(
            'resolves $style ($brightness) cleanly over kDefaultSheetSettings',
            (tester) async {
              late LiquidGlassSettings resolved;
              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: Builder(
                      builder: (context) {
                        resolved = GlassThemeHelpers.resolveSettings(
                          context,
                          fallback: kDefaultSheetSettings,
                        );
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              );

              switch (style) {
                case GlassStyle.ios27:
                  expect(resolved.lensModel, GlassLensModel.paraxial);
                  expect(resolved.frost, 14.0);
                  expect(resolved.ambientStrength, 0.0);
                  expect(resolved.rimShade, 1.0);
                  if (brightness == Brightness.light) {
                    expect(resolved.rimLight, closeTo(1.0, 1e-6));
                    expect(resolved.bodyShade, 0.0);
                  } else {
                    expect(resolved.rimLight, closeTo(1.15, 1e-6));
                    expect(resolved.bodyShade, closeTo(0.28, 1e-6));
                  }
                  break;
                case GlassStyle.ios26:
                  expect(resolved.lensModel, GlassLensModel.paraxial);
                  expect(resolved.frost, 14.0);
                  expect(resolved.rimShade, 0.0);
                  if (brightness == Brightness.light) {
                    expect(resolved.ambientStrength, 0.0);
                    expect(resolved.rimLight, closeTo(1.0, 1e-6));
                  } else {
                    expect(resolved.ambientStrength, closeTo(0.05, 1e-6));
                    expect(resolved.rimLight, closeTo(0.22, 1e-6));
                  }
                  break;
                case GlassStyle.classic:
                  expect(resolved.lensModel, GlassLensModel.spherical);
                  expect(resolved.refractiveIndex, 0.15);
                  expect(resolved.ambientStrength, 0.4);
                  break;
              }
            },
          );
        }
      }

      testWidgets(
        'classic style applies user GlassThemeVariant delta over widget fallback',
        (tester) async {
          late LiquidGlassSettings resolved;
          await tester.pumpWidget(
            MaterialApp(
              home: GlassTheme(
                data: const GlassThemeData(
                  style: GlassStyle.classic,
                  brightness: Brightness.light,
                  light: GlassThemeVariant(
                    settings: GlassThemeSettings(blur: 30.0),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    resolved = GlassThemeHelpers.resolveSettings(
                      context,
                      fallback: kDefaultSheetSettings,
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );

          // User delta (blur: 30.0) is applied, while kDefaultSheetSettings'
          // custom refractiveIndex (0.15) is preserved.
          expect(resolved.blur, 30.0);
          expect(resolved.refractiveIndex, 0.15);
        },
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. GlassMenu, GlassMenuItem, GlassMenuDivider, GlassPullDownButton
    // ─────────────────────────────────────────────────────────────────────────
    group('GlassMenu & GlassMenuItem style and brightness parity', () {
      for (final style in GlassStyle.values) {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          testWidgets(
            'GlassMenu resolves $style ($brightness) settings on open',
            (tester) async {
              final controller = GlassMenuController();
              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: CupertinoPageScaffold(
                      child: Center(
                        child: GlassMenu(
                          controller: controller,
                          trigger: const SizedBox(
                            width: 80,
                            height: 40,
                            child: Text('Menu'),
                          ),
                          items: [
                            GlassMenuItem(
                              title: 'Selected Row',
                              isSelected: true,
                              onTap: () {},
                            ),
                            const GlassMenuDivider(),
                            const GlassMenuLabel(title: 'Section'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );

              controller.open();
              await tester.pumpAndSettle();

              final layers = tester
                  .widgetList<AdaptiveLiquidGlassLayer>(
                    find.byType(AdaptiveLiquidGlassLayer),
                  )
                  .toList();
              expect(layers, isNotEmpty);
              final menuSettings = layers.last.settings!;

              switch (style) {
                case GlassStyle.ios27:
                  expect(menuSettings.lensModel, GlassLensModel.paraxial);
                  expect(menuSettings.frost, 14.0);
                  expect(menuSettings.frostOpacity, 1.0);
                  expect(menuSettings.rimShade, 1.0);
                  break;
                case GlassStyle.ios26:
                  expect(menuSettings.lensModel, GlassLensModel.paraxial);
                  expect(menuSettings.frost, 14.0);
                  expect(menuSettings.frostOpacity, 1.0);
                  expect(menuSettings.rimShade, 0.0);
                  break;
                case GlassStyle.classic:
                  expect(menuSettings.lensModel, GlassLensModel.spherical);
                  expect(menuSettings.refractiveIndex, 0.7);
                  break;
              }
            },
          );
        }
      }

      testWidgets(
        'GlassMenuItem, GlassMenuDivider, and GlassMenuLabel resolve CupertinoDynamicColor in dark mode',
        (tester) async {
          await tester.pumpWidget(
            CupertinoApp(
              theme: const CupertinoThemeData(brightness: Brightness.dark),
              home: GlassTheme(
                data: const GlassThemeData(
                  style: GlassStyle.ios27,
                  brightness: Brightness.dark,
                ),
                child: CupertinoPageScaffold(
                  child: Column(
                    children: [
                      GlassMenuItem(
                        title: 'Dark Action',
                        icon: const Icon(CupertinoIcons.star),
                        onTap: () {},
                      ),
                      const GlassMenuDivider(),
                      const GlassMenuLabel(title: 'Dark Header'),
                    ],
                  ),
                ),
              ),
            ),
          );

          final itemText = tester.widget<Text>(find.text('Dark Action'));
          // In dark mode, CupertinoColors.label resolves to white (r/g/b == 1.0).
          expect(itemText.style!.color!.r, closeTo(1.0, 0.01));
          expect(itemText.style!.color!.g, closeTo(1.0, 0.01));
          expect(itemText.style!.color!.b, closeTo(1.0, 0.01));

          final labelText = tester.widget<Text>(find.text('DARK HEADER'));
          expect(labelText.style!.color!.r, closeTo(235 / 255, 0.01));
          expect(labelText.style!.color!.a, closeTo(153 / 255, 0.01));

          final dividerBox = tester.widget<Container>(
            find.descendant(
              of: find.byType(GlassMenuDivider),
              matching: find.byType(Container),
            ),
          );
          expect(dividerBox.color!.r, closeTo(1.0, 0.01));
          expect(dividerBox.color!.a, closeTo(0.18, 0.01));
        },
      );

      testWidgets('GlassPullDownButton forwards custom settings to GlassMenu', (
        tester,
      ) async {
        const customSettings = LiquidGlassSettings(blur: 33.0, frost: 14.0);
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: GlassPullDownButton(
                  label: 'Options',
                  buttonWidth: 200,
                  settings: customSettings,
                  items: [GlassMenuItem(title: 'One', onTap: () {})],
                ),
              ),
            ),
          ),
        );

        final menu = tester.widget<GlassMenu>(find.byType(GlassMenu));
        expect(menu.settings, customSettings);
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. GlassContextMenu style and brightness parity
    // ─────────────────────────────────────────────────────────────────────────
    group('GlassContextMenu style and brightness parity', () {
      for (final style in GlassStyle.values) {
        testWidgets(
          'GlassContextMenu platter resolves $style settings when opened',
          (tester) async {
            await tester.pumpWidget(
              CupertinoApp(
                home: GlassTheme(
                  data: GlassThemeData(
                    style: style,
                    brightness: Brightness.light,
                  ),
                  child: CupertinoPageScaffold(
                    child: Center(
                      child: GlassContextMenu(
                        actions: [
                          GlassContextMenuAction(
                            onPressed: () {},
                            child: const Text('Copy'),
                          ),
                        ],
                        child: const SizedBox(
                          width: 100,
                          height: 44,
                          child: Center(child: Text('Hold Me')),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            final gesture = await tester.startGesture(
              tester.getCenter(find.text('Hold Me')),
            );
            await tester.pump(const Duration(milliseconds: 600));
            await gesture.up();
            await tester.pumpAndSettle();

            expect(find.text('Copy'), findsOneWidget);

            final platterGlass = tester.widget<AdaptiveGlass>(
              find.ancestor(
                of: find.text('Copy'),
                matching: find.byType(AdaptiveGlass),
              ),
            );

            switch (style) {
              case GlassStyle.ios27:
                expect(
                  platterGlass.settings.lensModel,
                  GlassLensModel.paraxial,
                );
                expect(platterGlass.settings.frost, 14.0);
                expect(platterGlass.settings.frostOpacity, 1.0);
                expect(platterGlass.settings.rimShade, 1.0);
                break;
              case GlassStyle.ios26:
                expect(
                  platterGlass.settings.lensModel,
                  GlassLensModel.paraxial,
                );
                expect(platterGlass.settings.frost, 14.0);
                expect(platterGlass.settings.frostOpacity, 1.0);
                expect(platterGlass.settings.rimShade, 0.0);
                break;
              case GlassStyle.classic:
                expect(
                  platterGlass.settings.lensModel,
                  GlassLensModel.spherical,
                );
                expect(platterGlass.settings.blur, 22.0);
                expect(platterGlass.settings.thickness, 16.0);
                break;
            }
          },
        );
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. GlassModalSheet & GlassSheet parity
    // ─────────────────────────────────────────────────────────────────────────
    group('GlassModalSheet & GlassSheet style and brightness parity', () {
      testWidgets(
        'GlassModalSheet defaults to 8pt margins and 36x5pt grabber at 5pt top inset',
        (tester) async {
          final sheet = GlassModalSheet(child: const SizedBox.shrink());
          expect(sheet.horizontalMargin, 8.0);
          expect(sheet.bottomMargin, 8.0);
          expect(sheet.dragIndicatorWidth, 36.0);
          expect(sheet.dragIndicatorHeight, 5.0);
          expect(sheet.dragIndicatorTopPadding, 5.0);
        },
      );

      for (final style in GlassStyle.values) {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          testWidgets(
            'GlassModalSheet.show() inherits GlassTheme ($style) and CupertinoTheme ($brightness)',
            (tester) async {
              GlassStyle? capturedStyle;
              Brightness? capturedBrightness;

              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: CupertinoPageScaffold(
                      child: Builder(
                        builder: (context) => CupertinoButton(
                          onPressed: () {
                            GlassModalSheet.show<void>(
                              context: context,
                              builder: (sheetContext) {
                                capturedStyle = GlassThemeHelpers.resolveStyle(
                                  sheetContext,
                                );
                                capturedBrightness = GlassTheme.brightnessOf(
                                  sheetContext,
                                );
                                return const Text('Sheet Body');
                              },
                            );
                          },
                          child: const Text('Present Modal Sheet'),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.tap(find.text('Present Modal Sheet'));
              await tester.pumpAndSettle();

              expect(capturedStyle, style);
              expect(capturedBrightness, brightness);
            },
          );

          testWidgets(
            'GlassSheet.show() inherits GlassTheme ($style) and CupertinoTheme ($brightness)',
            (tester) async {
              GlassStyle? capturedStyle;
              Brightness? capturedBrightness;

              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: CupertinoPageScaffold(
                      child: Builder(
                        builder: (context) => CupertinoButton(
                          onPressed: () {
                            GlassSheet.show<void>(
                              context: context,
                              builder: (sheetContext) {
                                capturedStyle = GlassThemeHelpers.resolveStyle(
                                  sheetContext,
                                );
                                capturedBrightness = GlassTheme.brightnessOf(
                                  sheetContext,
                                );
                                return const Text('Simple Sheet Body');
                              },
                            );
                          },
                          child: const Text('Present Simple Sheet'),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.tap(find.text('Present Simple Sheet'));
              await tester.pumpAndSettle();

              expect(capturedStyle, style);
              expect(capturedBrightness, brightness);

              // Verify GlassSheet grabber height (5pt in ios26/ios27, 4pt in classic)
              final indicatorFinder = find.byElementPredicate(
                (e) => e.widget.runtimeType.toString() == '_GlassDragIndicator',
              );
              final expectedHeight = style == GlassStyle.classic ? 4.0 : 5.0;
              final grabberContainer = find.descendant(
                of: indicatorFinder,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Container &&
                      w.constraints?.maxHeight == expectedHeight,
                ),
              );
              expect(grabberContainer, findsOneWidget);
            },
          );
        }
      }

      testWidgets(
        'GlassModalSheet expanded fill uses #F2F2F7 in light ios26/ios27 and white in classic',
        (tester) async {
          Widget buildSheet(GlassStyle style) {
            return CupertinoApp(
              theme: const CupertinoThemeData(brightness: Brightness.light),
              home: GlassTheme(
                data: GlassThemeData(
                  style: style,
                  brightness: Brightness.light,
                ),
                child: Stack(
                  children: [
                    GlassModalSheet(
                      initialState: GlassSheetState.full,
                      child: const SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            );
          }

          Color? currentFillRgb() {
            final box = tester.widget<DecoratedBox>(
              find.byKey(const Key('glass_modal_sheet_fill')),
            );
            return (box.decoration as BoxDecoration).color?.withValues(
              alpha: 1.0,
            );
          }

          await tester.pumpWidget(buildSheet(GlassStyle.ios27));
          await tester.pumpAndSettle();
          expect(currentFillRgb(), const Color(0xFFF2F2F7));

          await tester.pumpWidget(buildSheet(GlassStyle.ios26));
          await tester.pumpAndSettle();
          expect(currentFillRgb(), const Color(0xFFF2F2F7));

          await tester.pumpWidget(buildSheet(GlassStyle.classic));
          await tester.pumpAndSettle();
          expect(
            currentFillRgb(),
            CupertinoColors.white.withValues(alpha: 1.0),
          );
        },
      );

      test('SheetMorphGeometry.restingFillOpacity treats frost > 0 with blur == 0 as glass', () {
        const ios27Light = LiquidGlassSettings(
          blur: 0.0,
          frost: 14.0,
          lensModel: GlassLensModel.paraxial,
        );
        expect(
          SheetMorphGeometry.restingFillOpacity(
            state: GlassSheetState.half,
            baseSettings: ios27Light,
            enablePeek: false,
          ),
          0.0,
          reason: 'ios26/ios27 settings have blur == 0 and frost > 0 — must remain glassy at half detent',
        );
      });

      testWidgets(
        'GlassMenu and GlassSheet inside AdaptiveLiquidGlassLayer(settings: null) preserve classic fallbacks',
        (tester) async {
          await tester.pumpWidget(
            CupertinoApp(
              theme: const CupertinoThemeData(brightness: Brightness.light),
              home: GlassTheme(
                data: const GlassThemeData(
                  style: GlassStyle.classic,
                  brightness: Brightness.light,
                ),
                child: AdaptiveLiquidGlassLayer(
                  child: Column(
                    children: [
                      GlassPullDownButton(
                        label: 'MenuInLayer',
                        buttonWidth: 220,
                        items: [GlassMenuItem(title: 'Item A', onTap: () {})],
                      ),
                      const Expanded(
                        child: GlassSheet(child: Text('SheetInLayer')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          final sheetGlasses = tester
              .widgetList<AdaptiveGlass>(
                find.descendant(
                  of: find.byType(GlassSheet),
                  matching: find.byType(AdaptiveGlass),
                ),
              )
              .toList();
          expect(sheetGlasses.last.settings.refractiveIndex, 0.15);

          await tester.tap(find.text('MenuInLayer'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final allLayers = tester
              .widgetList<AdaptiveLiquidGlassLayer>(
                find.byType(AdaptiveLiquidGlassLayer),
              )
              .toList();
          expect(allLayers.last.settings?.refractiveIndex, 0.7);
        },
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. GlassDialog, GlassActionSheet, GlassPopover, GlassToast, FullScreenCover
    // ─────────────────────────────────────────────────────────────────────────
    group('GlassDialog, GlassActionSheet, GlassPopover, GlassToast & Cover', () {
      for (final style in GlassStyle.values) {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          testWidgets(
            'GlassDialog.show() inherits GlassTheme ($style) and CupertinoTheme ($brightness)',
            (tester) async {
              GlassStyle? capturedStyle;
              Brightness? capturedBrightness;

              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: CupertinoPageScaffold(
                      child: Builder(
                        builder: (context) => CupertinoButton(
                          onPressed: () {
                            GlassDialog.show<void>(
                              context: context,
                              title: 'Alert',
                              content: Builder(
                                builder: (dialogContext) {
                                  capturedStyle =
                                      GlassThemeHelpers.resolveStyle(
                                        dialogContext,
                                      );
                                  capturedBrightness = GlassTheme.brightnessOf(
                                    dialogContext,
                                  );
                                  return const Text('Body');
                                },
                              ),
                              actions: [
                                GlassDialogAction(
                                  label: 'OK',
                                  isPrimary: true,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            );
                          },
                          child: const Text('Show Dialog'),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.tap(find.text('Show Dialog'));
              await tester.pumpAndSettle();

              expect(capturedStyle, style);
              expect(capturedBrightness, brightness);

              // Outer platter card resolves with isOverlayPlatter: true
              final dialogGlasses = tester
                  .widgetList<AdaptiveGlass>(
                    find.descendant(
                      of: find.byType(GlassDialog),
                      matching: find.byType(AdaptiveGlass),
                    ),
                  )
                  .toList();
              expect(dialogGlasses, isNotEmpty);
              final platterSettings = dialogGlasses.first.settings;
              switch (style) {
                case GlassStyle.ios27:
                  expect(platterSettings.lensModel, GlassLensModel.paraxial);
                  expect(platterSettings.frost, 14.0);
                  expect(platterSettings.frostOpacity, 1.0);
                  expect(platterSettings.rimShade, 1.0);
                  break;
                case GlassStyle.ios26:
                  expect(platterSettings.lensModel, GlassLensModel.paraxial);
                  expect(platterSettings.frost, 14.0);
                  expect(platterSettings.frostOpacity, 1.0);
                  expect(platterSettings.rimShade, 0.0);
                  break;
                case GlassStyle.classic:
                  expect(platterSettings.lensModel, GlassLensModel.spherical);
                  expect(
                    platterSettings.thickness,
                    brightness == Brightness.dark ? 10.0 : 12.0,
                  );
                  break;
              }
            },
          );

          testWidgets(
            'showGlassActionSheet() inherits GlassTheme ($style) and CupertinoTheme ($brightness)',
            (tester) async {
              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: CupertinoPageScaffold(
                      child: Builder(
                        builder: (context) => CupertinoButton(
                          onPressed: () {
                            showGlassActionSheet<void>(
                              context: context,
                              title: 'Actions',
                              actions: [
                                GlassActionSheetAction(
                                  label: 'Share',
                                  onPressed: () {},
                                ),
                              ],
                            );
                          },
                          child: const Text('Show Action Sheet'),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.tap(find.text('Show Action Sheet'));
              await tester.pumpAndSettle();

              final actionGlasses = tester
                  .widgetList<AdaptiveGlass>(
                    find.ancestor(
                      of: find.text('Share'),
                      matching: find.byType(AdaptiveGlass),
                    ),
                  )
                  .toList();
              expect(actionGlasses, isNotEmpty);
              final sheetSettings = actionGlasses.first.settings;

              switch (style) {
                case GlassStyle.ios27:
                  expect(sheetSettings.lensModel, GlassLensModel.paraxial);
                  expect(sheetSettings.frost, 14.0);
                  expect(sheetSettings.frostOpacity, 1.0);
                  expect(sheetSettings.rimShade, 1.0);
                  break;
                case GlassStyle.ios26:
                  expect(sheetSettings.lensModel, GlassLensModel.paraxial);
                  expect(sheetSettings.frost, 14.0);
                  expect(sheetSettings.frostOpacity, 1.0);
                  expect(sheetSettings.rimShade, 0.0);
                  break;
                case GlassStyle.classic:
                  expect(sheetSettings.lensModel, GlassLensModel.spherical);
                  expect(sheetSettings.thickness, 30.0);
                  expect(sheetSettings.blur, 5.0);
                  expect(sheetSettings.refractiveIndex, 1.15);
                  break;
              }
            },
          );

          testWidgets(
            'GlassPopover resolves $style ($brightness) settings on open',
            (tester) async {
              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: AdaptiveLiquidGlassLayer(
                      child: CupertinoPageScaffold(
                        child: Center(
                          child: GlassPopover(
                            triggerBuilder: (context, open) => CupertinoButton(
                              onPressed: open,
                              child: const Text('Open Popover'),
                            ),
                            contentBuilder: (context, close) =>
                                const SizedBox(height: 80, child: Text('Pop')),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.tap(find.text('Open Popover'));
              await tester.pumpAndSettle();

              final popGlasses = tester
                  .widgetList<AdaptiveGlass>(
                    find.ancestor(
                      of: find.text('Pop'),
                      matching: find.byType(AdaptiveGlass),
                    ),
                  )
                  .toList();
              expect(popGlasses, isNotEmpty);
              final popSettings = popGlasses.first.settings;

              switch (style) {
                case GlassStyle.ios27:
                  expect(popSettings.lensModel, GlassLensModel.paraxial);
                  expect(popSettings.frost, 14.0);
                  expect(popSettings.frostOpacity, 1.0);
                  expect(popSettings.rimShade, 1.0);
                  break;
                case GlassStyle.ios26:
                  expect(popSettings.lensModel, GlassLensModel.paraxial);
                  expect(popSettings.frost, 14.0);
                  expect(popSettings.frostOpacity, 1.0);
                  expect(popSettings.rimShade, 0.0);
                  break;
                case GlassStyle.classic:
                  expect(popSettings.lensModel, GlassLensModel.spherical);
                  expect(popSettings.blur, 10.0);
                  expect(popSettings.refractiveIndex, 0.7);
                  break;
              }
            },
          );

          testWidgets(
            'GlassToast.show() inherits GlassTheme ($style) and CupertinoTheme ($brightness)',
            (tester) async {
              late VoidCallback dismiss;
              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: CupertinoPageScaffold(
                      child: Builder(
                        builder: (context) => CupertinoButton(
                          onPressed: () {
                            dismiss = GlassToast.show(
                              context,
                              message: 'Toast Message',
                              duration: Duration.zero,
                            );
                          },
                          child: const Text('Show Toast'),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.tap(find.text('Show Toast'));
              await tester.pumpAndSettle();

              final toastGlasses = tester
                  .widgetList<AdaptiveGlass>(
                    find.descendant(
                      of: find.byType(GlassToast),
                      matching: find.byType(AdaptiveGlass),
                    ),
                  )
                  .toList();
              expect(toastGlasses, isNotEmpty);
              final toastSettings = toastGlasses.first.settings;

              switch (style) {
                case GlassStyle.ios27:
                  expect(toastSettings.lensModel, GlassLensModel.paraxial);
                  expect(toastSettings.frost, 14.0);
                  expect(toastSettings.frostOpacity, 1.0);
                  expect(toastSettings.rimShade, 1.0);
                  break;
                case GlassStyle.ios26:
                  expect(toastSettings.lensModel, GlassLensModel.paraxial);
                  expect(toastSettings.frost, 14.0);
                  expect(toastSettings.frostOpacity, 1.0);
                  expect(toastSettings.rimShade, 0.0);
                  break;
                case GlassStyle.classic:
                  expect(toastSettings.lensModel, GlassLensModel.spherical);
                  expect(toastSettings.thickness, 25.0);
                  expect(toastSettings.blur, 6.0);
                  expect(toastSettings.refractiveIndex, 1.15);
                  break;
              }

              dismiss();
              await tester.pumpAndSettle();
            },
          );

          testWidgets(
            'showGlassFullScreenCover() inherits GlassTheme ($style) and CupertinoTheme ($brightness)',
            (tester) async {
              GlassStyle? capturedStyle;
              Brightness? capturedBrightness;

              await tester.pumpWidget(
                CupertinoApp(
                  theme: CupertinoThemeData(brightness: brightness),
                  home: GlassTheme(
                    data: GlassThemeData(style: style, brightness: brightness),
                    child: CupertinoPageScaffold(
                      child: Builder(
                        builder: (context) => CupertinoButton(
                          onPressed: () {
                            showGlassFullScreenCover<void>(
                              context: context,
                              builder: (coverContext) => GlassFullScreenCover(
                                title: const Text('Cover'),
                                child: Builder(
                                  builder: (innerContext) {
                                    capturedStyle =
                                        GlassThemeHelpers.resolveStyle(
                                          innerContext,
                                        );
                                    capturedBrightness =
                                        GlassTheme.brightnessOf(innerContext);
                                    return const Text('Cover Body');
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Text('Open Cover'),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.tap(find.text('Open Cover'));
              await tester.pumpAndSettle();

              expect(capturedStyle, style);
              expect(capturedBrightness, brightness);
            },
          );
        }
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Remaining Surfaces, Interactive, Input, Feedback & Container Controls
    // ─────────────────────────────────────────────────────────────────────────
    group('Surfaces, Interactive, Input, Feedback & Container Parity', () {
      for (final style in GlassStyle.values) {
        testWidgets(
          'GlassToolbar, GlassBadge, GlassPicker, GlassStepper, and GlassProgressIndicator resolve $style',
          (tester) async {
            await tester.pumpWidget(
              CupertinoApp(
                theme: const CupertinoThemeData(brightness: Brightness.light),
                home: GlassTheme(
                  data: GlassThemeData(
                    style: style,
                    brightness: Brightness.light,
                  ),
                  child: CupertinoPageScaffold(
                    child: Column(
                      children: [
                        const GlassToolbar(children: [Text('Tool')]),
                        const GlassBadge(
                          count: 5,
                          child: SizedBox(width: 24, height: 24),
                        ),
                        GlassPicker(
                          value: 'One',
                          useOwnLayer: true,
                          onTap: () {},
                        ),
                        GlassStepper(value: 1, onChanged: (_) {}),
                        const GlassProgressIndicator.circular(
                          useOwnLayer: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            final toolbarLayer = tester.widget<AdaptiveLiquidGlassLayer>(
              find.descendant(
                of: find.byType(GlassToolbar),
                matching: find.byType(AdaptiveLiquidGlassLayer),
              ),
            );
            final badgeLayer = tester.widget<AdaptiveLiquidGlassLayer>(
              find.descendant(
                of: find.byType(GlassBadge),
                matching: find.byType(AdaptiveLiquidGlassLayer),
              ),
            );
            final pickerGlass = tester.widget<AdaptiveGlass>(
              find.descendant(
                of: find.byType(GlassPicker),
                matching: find.byType(AdaptiveGlass),
              ),
            );
            final stepperGlass = tester.widget<AdaptiveGlass>(
              find.descendant(
                of: find.byType(GlassStepper),
                matching: find.byType(AdaptiveGlass),
              ),
            );
            final progressLayer = tester.widget<AdaptiveLiquidGlassLayer>(
              find.descendant(
                of: find.byType(GlassProgressIndicator),
                matching: find.byType(AdaptiveLiquidGlassLayer),
              ),
            );

            switch (style) {
              case GlassStyle.ios27:
                expect(
                  toolbarLayer.settings!.lensModel,
                  GlassLensModel.paraxial,
                );
                expect(toolbarLayer.settings!.rimShade, 1.0);
                expect(badgeLayer.settings!.lensModel, GlassLensModel.paraxial);
                expect(pickerGlass.settings.lensModel, GlassLensModel.paraxial);
                expect(
                  stepperGlass.settings.lensModel,
                  GlassLensModel.paraxial,
                );
                expect(
                  progressLayer.settings!.lensModel,
                  GlassLensModel.paraxial,
                );
                break;
              case GlassStyle.ios26:
                expect(
                  toolbarLayer.settings!.lensModel,
                  GlassLensModel.paraxial,
                );
                expect(toolbarLayer.settings!.rimShade, 0.0);
                expect(badgeLayer.settings!.lensModel, GlassLensModel.paraxial);
                expect(pickerGlass.settings.lensModel, GlassLensModel.paraxial);
                expect(
                  stepperGlass.settings.lensModel,
                  GlassLensModel.paraxial,
                );
                expect(
                  progressLayer.settings!.lensModel,
                  GlassLensModel.paraxial,
                );
                break;
              case GlassStyle.classic:
                expect(
                  toolbarLayer.settings!.lensModel,
                  GlassLensModel.spherical,
                );
                expect(toolbarLayer.settings!.blur, 20.0);
                expect(badgeLayer.settings!.thickness, 20.0);
                expect(pickerGlass.settings.thickness, 12.0);
                expect(pickerGlass.settings.glassColor.a, greaterThan(0.0));
                expect(stepperGlass.settings.thickness, 12.0);
                expect(progressLayer.settings!.thickness, 12.0);
                break;
            }
          },
        );
      }

      testWidgets(
        'GlassChip and GlassPasswordField inherit quality from GlassTheme when widget quality is omitted',
        (tester) async {
          await tester.pumpWidget(
            CupertinoApp(
              home: GlassTheme(
                data: const GlassThemeData(
                  style: GlassStyle.ios27,
                  light: GlassThemeVariant(quality: GlassQuality.minimal),
                ),
                child: AdaptiveLiquidGlassLayer(
                  quality: GlassQuality.minimal,
                  child: CupertinoPageScaffold(
                    child: Column(
                      children: [
                        GlassChip(label: 'Tag', onTap: () {}),
                        const GlassPasswordField(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          final chipButton = tester.widget<GlassButton>(
            find.descendant(
              of: find.byType(GlassChip),
              matching: find.byType(GlassButton),
            ),
          );
          expect(chipButton.quality, isNull);

          final textField = tester.widget<GlassTextField>(
            find.descendant(
              of: find.byType(GlassPasswordField),
              matching: find.byType(GlassTextField),
            ),
          );
          expect(textField.quality, isNull);
        },
      );

      testWidgets(
        'GlassPicker.showSheet() and showGlassDatePicker() inherit GlassTheme and CupertinoTheme',
        (tester) async {
          GlassStyle? sheetStyle;
          Brightness? sheetBrightness;
          GlassStyle? dateStyle;
          Brightness? dateBrightness;

          await tester.pumpWidget(
            CupertinoApp(
              theme: const CupertinoThemeData(brightness: Brightness.dark),
              home: GlassTheme(
                data: const GlassThemeData(
                  style: GlassStyle.ios26,
                  brightness: Brightness.dark,
                ),
                child: CupertinoPageScaffold(
                  child: Builder(
                    builder: (context) => Column(
                      children: [
                        CupertinoButton(
                          onPressed: () => GlassPicker.showSheet<String>(
                            context: context,
                            items: const ['One'],
                            itemBuilder: (item) => Builder(
                              builder: (itemContext) {
                                sheetStyle = GlassThemeHelpers.resolveStyle(
                                  itemContext,
                                );
                                sheetBrightness = GlassTheme.brightnessOf(
                                  itemContext,
                                );
                                return Text(item);
                              },
                            ),
                          ),
                          child: const Text('Open Picker'),
                        ),
                        CupertinoButton(
                          onPressed: () =>
                              showGlassDatePicker(context: context),
                          child: const Text('Open Date'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Open Picker'));
          await tester.pumpAndSettle();
          expect(sheetStyle, GlassStyle.ios26);
          expect(sheetBrightness, Brightness.dark);

          // Dismiss the picker sheet via its barrier.
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Open Date'));
          await tester.pumpAndSettle();
          final pickerContext = tester.element(find.byType(GlassDatePicker));
          dateStyle = GlassThemeHelpers.resolveStyle(pickerContext);
          dateBrightness = GlassTheme.brightnessOf(pickerContext);
          expect(dateStyle, GlassStyle.ios26);
          expect(dateBrightness, Brightness.dark);
        },
      );

      for (final style in GlassStyle.values) {
        testWidgets(
          'GlassTabBar.searchable DismissPill resolves $style optics under an indicatorColor',
          (tester) async {
            const tint = Color(0xFFFF9500);
            await tester.pumpWidget(
              CupertinoApp(
                home: GlassTheme(
                  data: GlassThemeData(
                    style: style,
                    brightness: Brightness.light,
                  ),
                  child: CupertinoPageScaffold(
                    child: Center(
                      child: DismissPill(
                        onTap: () {},
                        pillSize: 50,
                        barBorderRadius: 25,
                        quality: GlassQuality.standard,
                        indicatorColor: tint,
                      ),
                    ),
                  ),
                ),
              ),
            );

            final button = tester.widget<GlassButton>(find.byType(GlassButton));
            final settings = button.settings!;
            expect(settings.glassColor, tint);
            expect(settings.thickness, greaterThan(0.0));
            expect(
              settings.lensModel,
              style == GlassStyle.classic
                  ? GlassLensModel.spherical
                  : GlassLensModel.paraxial,
            );
          },
        );
      }

      testWidgets(
        'GlassListTile.standalone owns a layer only when settings are given',
        (tester) async {
          await tester.pumpWidget(
            const CupertinoApp(
              home: CupertinoPageScaffold(
                child: Column(
                  children: [
                    GlassListTile.standalone(title: Text('Default Tile')),
                    GlassListTile.standalone(
                      title: Text('Custom Tile'),
                      settings: LiquidGlassSettings(blur: 3),
                    ),
                  ],
                ),
              ),
            ),
          );

          final containers = tester
              .widgetList<GlassContainer>(find.byType(GlassContainer))
              .toList();
          expect(containers, hasLength(2));
          expect(containers[0].useOwnLayer, isFalse);
          expect(containers[1].useOwnLayer, isTrue);
        },
      );

      testWidgets(
        'GlassDialog.show() inherits ambient quality and honours barrierColor',
        (tester) async {
          await tester.pumpWidget(
            CupertinoApp(
              home: GlassTheme(
                data: const GlassThemeData(
                  light: GlassThemeVariant(quality: GlassQuality.minimal),
                ),
                child: CupertinoPageScaffold(
                  child: Builder(
                    builder: (context) => CupertinoButton(
                      onPressed: () => GlassDialog.show<void>(
                        context: context,
                        title: 'Alert',
                        barrierColor: const Color(0x80FF0000),
                        actions: [
                          GlassDialogAction(label: 'OK', onPressed: () {}),
                        ],
                      ),
                      child: const Text('Show'),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Show'));
          await tester.pumpAndSettle();

          final dialog = tester.widget<GlassDialog>(find.byType(GlassDialog));
          expect(dialog.quality, isNull);

          final barrier = tester.widget<AnimatedModalBarrier>(
            find.byType(AnimatedModalBarrier).last,
          );
          expect(barrier.color.value, const Color(0x80FF0000));
        },
      );
    });
  });
}
