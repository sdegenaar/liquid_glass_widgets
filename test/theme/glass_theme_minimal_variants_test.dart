import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/theme/glass_theme_helpers.dart';

void main() {
  group('GlassThemeVariant.minimalLight / minimalDark', () {
    test('are minimal-quality frosted variants like minimal', () {
      for (final v in [
        GlassThemeVariant.minimalLight,
        GlassThemeVariant.minimalDark,
      ]) {
        expect(v.quality, GlassQuality.minimal);
        expect(v.settings!.blur, GlassThemeVariant.minimal.settings!.blur);
        expect(
          v.settings!.thickness,
          GlassThemeVariant.minimal.settings!.thickness,
        );
      }
    });

    test('take the iOS 27 tint of their brightness, a neutral one', () {
      final light = GlassThemeVariant.minimalLight.settings!.glassColor!;
      final dark = GlassThemeVariant.minimalDark.settings!.glassColor!;
      expect(light, GlassThemeSettings.ios27Light.glassColor);
      expect(dark, GlassThemeSettings.ios27Dark.glassColor);
      for (final c in [light, dark]) {
        expect(c.r, c.g, reason: 'no colour cast');
        expect(c.g, c.b, reason: 'no colour cast');
      }
    });
  });

  group('GlassThemeData.minimal', () {
    test('defaults match ios27 style with minimalLight and minimalDark', () {
      const theme = GlassThemeData.minimal();

      expect(theme.light, GlassThemeVariant.minimalLight);
      expect(theme.dark, GlassThemeVariant.minimalDark);
      expect(theme.style, GlassStyle.ios27);
      expect(theme.interaction, const GlassInteractionSettings());
      expect(theme.brightness, isNull);
      expect(
        theme,
        const GlassThemeData(
          light: GlassThemeVariant.minimalLight,
          dark: GlassThemeVariant.minimalDark,
        ),
      );
      expect(
        theme.hashCode,
        const GlassThemeData(
          light: GlassThemeVariant.minimalLight,
          dark: GlassThemeVariant.minimalDark,
        ).hashCode,
      );
    });

    test('forwards custom style, interaction, and brightness', () {
      const interaction = GlassInteractionSettings(
        stretch: 0.3,
        interactionScale: 1.05,
      );
      const theme = GlassThemeData.minimal(
        style: GlassStyle.ios26,
        interaction: interaction,
        brightness: Brightness.dark,
      );

      expect(theme.light, GlassThemeVariant.minimalLight);
      expect(theme.dark, GlassThemeVariant.minimalDark);
      expect(theme.style, GlassStyle.ios26);
      expect(theme.interaction, interaction);
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets(
      'resolves minimalLight / minimalDark and GlassQuality.minimal by brightness',
      (tester) async {
        late GlassThemeVariant resolvedVariant;
        late GlassQuality? resolvedQuality;
        late GlassThemeSettings? resolvedSettings;
        late GlassStyle resolvedStyle;

        Widget buildApp({
          required Brightness appBrightness,
          GlassThemeData data = const GlassThemeData.minimal(),
        }) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: appBrightness),
            home: GlassTheme(
              data: data,
              child: Builder(
                builder: (context) {
                  final theme = GlassThemeData.of(context);
                  resolvedVariant = theme.variantFor(context);
                  resolvedQuality = theme.qualityFor(context);
                  resolvedSettings = theme.settingsFor(context);
                  resolvedStyle = GlassThemeHelpers.resolveStyle(context);
                  return GlassButton.custom(
                    onTap: () {},
                    child: const Text('Minimal'),
                  );
                },
              ),
            ),
          );
        }

        // Light mode
        await tester.pumpWidget(buildApp(appBrightness: Brightness.light));
        expect(resolvedVariant, GlassThemeVariant.minimalLight);
        expect(resolvedQuality, GlassQuality.minimal);
        expect(resolvedSettings, GlassThemeVariant.minimalLight.settings);
        expect(resolvedStyle, GlassStyle.ios27);

        // Dark mode
        await tester.pumpWidget(buildApp(appBrightness: Brightness.dark));
        expect(resolvedVariant, GlassThemeVariant.minimalDark);
        expect(resolvedQuality, GlassQuality.minimal);
        expect(resolvedSettings, GlassThemeVariant.minimalDark.settings);
        expect(resolvedStyle, GlassStyle.ios27);

        // Explicit brightness override + non-default style preserves minimal settings
        await tester.pumpWidget(
          buildApp(
            appBrightness: Brightness.light,
            data: const GlassThemeData.minimal(
              style: GlassStyle.classic,
              brightness: Brightness.dark,
            ),
          ),
        );
        expect(resolvedVariant, GlassThemeVariant.minimalDark);
        expect(resolvedQuality, GlassQuality.minimal);
        expect(resolvedSettings, GlassThemeVariant.minimalDark.settings);
        expect(resolvedStyle, GlassStyle.classic);
      },
    );
  });
}
