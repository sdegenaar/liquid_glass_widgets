import 'package:flutter/foundation.dart';

/// Optics of the lifted iOS 26/27 tab-bar selection lens.
///
/// Pass it as `indicatorLens` on [GlassTabBar.bottom] or [GlassTabBar.inline]
/// to change how the lens bends what is under it, or use
/// [IndicatorLensOptics.disabled] to keep the single-pass glass refraction.
///
/// The defaults were read from UIKit: a native `UITabBar` on the iOS 27.2
/// simulator, held lifted through XCUITest while its `_UILiquidLensView`
/// layer tree was archived and its two displacement maps were rendered over a
/// position-encoded ramp. The lens warps two things separately:
///
/// * **Content** — the tab items in their selected colour, each magnified on
///   its own centre ([GlassTabBar.magnification], 1.16 natively), are drawn
///   inside the lens and displaced inward near the rim ([contentDisplacement]
///   across [contentBevel]). The rim band shows a mirrored, compressed copy
///   of what lies further in: an icon or label crossing the edge folds back.
/// * **Backdrop** — the bar and the page behind the lens are displaced
///   outward ([backdropDisplacement] across [backdropBevel]), so what sits
///   just outside the lens is pulled into its edge.
///
/// Both follow the same profile: a sample `d` points in from the rim moves
/// by `displacement × (1 − √(1 − t²))` with `t = 1 − d / bevel`, along the
/// rim normal bent [ovalization] of the way toward an ellipse's. Samples the
/// backdrop warp pushes past the lens repeat the lens' edge, as UIKit's
/// margin-less backdrop capture does, so what sits just outside is smeared
/// across the rim.
///
/// On top, the glass splits red from blue across the outer [aberrationBand]
/// of the warped image ([aberration], fading to nothing at the band's inner
/// edge), which turns that smear and anything crossing the rim into rainbow
/// fringes.
///
/// The native lens needs Impeller (`ImageFilter.isShaderFilterSupported`)
/// and [GlassQuality.premium]; elsewhere the indicator keeps its single-pass
/// refraction.
///
/// Lengths are logical pixels.
@immutable
class IndicatorLensOptics {
  /// Creates lens optics. Every value defaults to the measured native lens.
  const IndicatorLensOptics({
    this.enabled = true,
    this.contentDisplacement = -17.5,
    this.contentBevel = 11.2,
    this.backdropDisplacement = 9.0,
    this.backdropBevel = 36.0,
    this.ovalization = 0.5,
    this.aberration = 2.7,
    this.aberrationBand = 14.0,
  })  : assert(contentBevel > 0, 'contentBevel must be positive'),
        assert(backdropBevel > 0, 'backdropBevel must be positive'),
        assert(ovalization >= 0.0 && ovalization <= 1.0,
            'ovalization must be in [0.0, 1.0]'),
        assert(aberration >= 0.0, 'aberration must be non-negative'),
        assert(aberrationBand > 0, 'aberrationBand must be positive');

  /// The measured native lens (the default).
  static const IndicatorLensOptics native = IndicatorLensOptics();

  /// No native lens: the indicator keeps its single-pass refraction.
  static const IndicatorLensOptics disabled =
      IndicatorLensOptics(enabled: false);

  /// Whether the native lens runs at all.
  final bool enabled;

  /// How far the selected content is displaced at the rim. Negative values
  /// sample further in, which folds the rim band back on itself.
  final double contentDisplacement;

  /// Width of the band, measured in from the rim, over which the content is
  /// displaced.
  final double contentBevel;

  /// How far the backdrop is displaced at the rim. Positive values sample
  /// outward, pulling the surroundings into the lens edge.
  final double backdropDisplacement;

  /// Width of the band, measured in from the rim, over which the backdrop is
  /// displaced.
  final double backdropBevel;

  /// How far the displacement direction bends from the rim normal toward the
  /// normal of the ellipse inscribed in the lens (`0` follows the rim).
  final double ovalization;

  /// How far red and blue are pulled apart at the rim, in opposite
  /// directions along the position's normalised `(y, x)`: along the rim at
  /// the ends and the middle of each side, across it on the diagonals.
  final double aberration;

  /// Width of the band, measured in from the rim, that shows [aberration].
  final double aberrationBand;

  /// Returns a copy with the given values replaced.
  IndicatorLensOptics copyWith({
    bool? enabled,
    double? contentDisplacement,
    double? contentBevel,
    double? backdropDisplacement,
    double? backdropBevel,
    double? ovalization,
    double? aberration,
    double? aberrationBand,
  }) =>
      IndicatorLensOptics(
        enabled: enabled ?? this.enabled,
        contentDisplacement: contentDisplacement ?? this.contentDisplacement,
        contentBevel: contentBevel ?? this.contentBevel,
        backdropDisplacement: backdropDisplacement ?? this.backdropDisplacement,
        backdropBevel: backdropBevel ?? this.backdropBevel,
        ovalization: ovalization ?? this.ovalization,
        aberration: aberration ?? this.aberration,
        aberrationBand: aberrationBand ?? this.aberrationBand,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorLensOptics &&
          other.enabled == enabled &&
          other.contentDisplacement == contentDisplacement &&
          other.contentBevel == contentBevel &&
          other.backdropDisplacement == backdropDisplacement &&
          other.backdropBevel == backdropBevel &&
          other.ovalization == ovalization &&
          other.aberration == aberration &&
          other.aberrationBand == aberrationBand;

  @override
  int get hashCode => Object.hash(
        enabled,
        contentDisplacement,
        contentBevel,
        backdropDisplacement,
        backdropBevel,
        ovalization,
        aberration,
        aberrationBand,
      );

  @override
  String toString() => 'IndicatorLensOptics(enabled: $enabled, '
      'content: $contentDisplacement/$contentBevel, '
      'backdrop: $backdropDisplacement/$backdropBevel, '
      'ovalization: $ovalization, '
      'aberration: $aberration/$aberrationBand)';
}
