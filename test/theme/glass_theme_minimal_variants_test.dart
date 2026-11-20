import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
}
