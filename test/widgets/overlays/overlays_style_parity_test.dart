import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/overlays/glass_sheet_defaults.dart';
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
          });
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
      });
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
          });
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
      });

      testWidgets('GlassPullDownButton forwards custom settings to GlassMenu',
          (tester) async {
        const customSettings = LiquidGlassSettings(blur: 33.0, frost: 14.0);
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: GlassPullDownButton(
                  label: 'Options',
                  buttonWidth: 200,
                  settings: customSettings,
                  items: [
                    GlassMenuItem(title: 'One', onTap: () {}),
                  ],
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
        });
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
      });

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
                              capturedStyle =
                                  GlassThemeHelpers.resolveStyle(sheetContext);
                              capturedBrightness =
                                  GlassTheme.brightnessOf(sheetContext);
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
          });

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
                              capturedStyle =
                                  GlassThemeHelpers.resolveStyle(sheetContext);
                              capturedBrightness =
                                  GlassTheme.brightnessOf(sheetContext);
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
          });
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
          return (box.decoration as BoxDecoration)
              .color
              ?.withValues(alpha: 1.0);
        }

        await tester.pumpWidget(buildSheet(GlassStyle.ios27));
        await tester.pumpAndSettle();
        expect(currentFillRgb(), const Color(0xFFF2F2F7));

        await tester.pumpWidget(buildSheet(GlassStyle.ios26));
        await tester.pumpAndSettle();
        expect(currentFillRgb(), const Color(0xFFF2F2F7));

        await tester.pumpWidget(buildSheet(GlassStyle.classic));
        await tester.pumpAndSettle();
        expect(currentFillRgb(), CupertinoColors.white.withValues(alpha: 1.0));
      });

      test(
          'SheetMorphGeometry.restingFillOpacity treats frost > 0 with blur == 0 as glass',
          () {
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
          reason:
              'ios26/ios27 settings have blur == 0 and frost > 0 — must remain glassy at half detent',
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
                      items: [
                        GlassMenuItem(title: 'Item A', onTap: () {}),
                      ],
                    ),
                    const Expanded(
                      child: GlassSheet(
                        child: Text('SheetInLayer'),
                      ),
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
      });
    });
  });
}
