import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('IndicatorLensOptics', () {
    test('defaults to the measured UIKit lens', () {
      const native = IndicatorLensOptics.native;
      expect(native.enabled, isTrue);
      expect(native.contentDisplacement, -17.5);
      expect(native.contentBevel, 11.2);
      expect(native.backdropDisplacement, 9.0);
      expect(native.backdropBevel, 36.0);
      expect(native.ovalization, 0.5);
      expect(native.aberration, 2.7);
      expect(native.aberrationBand, 14.0);
      expect(const IndicatorLensOptics(), native);
    });

    test('disabled only switches the lens off', () {
      const disabled = IndicatorLensOptics.disabled;
      expect(disabled.enabled, isFalse);
      expect(disabled.copyWith(enabled: true), IndicatorLensOptics.native);
    });

    test('copyWith replaces only the given values', () {
      final tuned = IndicatorLensOptics.native.copyWith(
        contentDisplacement: -12,
        aberration: 0,
      );
      expect(tuned.contentDisplacement, -12);
      expect(tuned.aberration, 0);
      expect(tuned.contentBevel, IndicatorLensOptics.native.contentBevel);
      expect(tuned.backdropDisplacement,
          IndicatorLensOptics.native.backdropDisplacement);
      expect(tuned, isNot(IndicatorLensOptics.native));
    });

    test('equal optics share a hash code', () {
      const a = IndicatorLensOptics(backdropDisplacement: 6);
      const b = IndicatorLensOptics(backdropDisplacement: 6);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('backdrop: 6.0/36.0'));
    });

    test('rejects a zero bevel or band and an out-of-range ovalization', () {
      expect(() => IndicatorLensOptics(contentBevel: 0), throwsAssertionError);
      expect(() => IndicatorLensOptics(backdropBevel: 0), throwsAssertionError);
      expect(
          () => IndicatorLensOptics(aberrationBand: 0), throwsAssertionError);
      expect(() => IndicatorLensOptics(ovalization: 1.5), throwsAssertionError);
      expect(() => IndicatorLensOptics(aberration: -1), throwsAssertionError);
    });
  });
}
