// Copyright 2026, Sebastian Degenaar for pixel-innovations.com (liquid_glass_widgets)
//
// SPDX-License-Identifier: MIT

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'liquid_glass_settings.dart';

/// Resolved CoreAnimation-calibrated face tone & edge-bleed parameters for a
/// single glass surface at a specific logical shortest side [shortestSide].
///
/// Consumed by both the Impeller premium render shader (`uFace`, `uFaceExtra`)
/// and the cross-platform lightweight shader (`uFace`).
final class ResolvedGlassFaceOptics {
  const ResolvedGlassFaceOptics({
    required this.faceBlack,
    required this.faceWhite,
    required this.faceMaxLuma,
    required this.faceFillAlpha,
    required this.faceChroma,
    required this.bleedStrength,
    required this.bleedSign,
    required this.lumaBracketTint,
    required this.effectiveFrostSigma,
    this.effectiveThickness = 0.0,
    this.shadowOpacityScale = 1.0,
  });

  /// Identity / disabled face optics (bit-exact no-op in shaders).
  static const ResolvedGlassFaceOptics disabled = ResolvedGlassFaceOptics(
    faceBlack: 0.0,
    faceWhite: 0.0,
    faceMaxLuma: 1.0,
    faceFillAlpha: 0.0,
    faceChroma: 1.0,
    bleedStrength: 0.0,
    bleedSign: 0.0,
    lumaBracketTint: 0.0,
    effectiveFrostSigma: 0.0,
    effectiveThickness: 0.0,
    shadowOpacityScale: 1.0,
  );

  /// Lower luminance anchor (`inputFaceColorMatrixBlack`).
  final double faceBlack;

  /// Upper luminance anchor (`inputFaceColorMatrixWhite`).
  ///
  /// Shaders enable the CoreAnimation face model strictly when
  /// `faceWhite > faceBlack`.
  final double faceWhite;

  /// SDR maximum luminance cap (`inputFaceColorMatrixMaxLumaSDR` / holding
  /// tone). `1.0` leaves luminance uncapped.
  final double faceMaxLuma;

  /// Signed fill mix opacity: positive mixes toward white (`+alpha`), negative
  /// mixes toward black (`-alpha`), `0.0` disables fill mixing.
  final double faceFillAlpha;

  /// Chroma preservation multiplier (`inputFaceColorMatrixSaturation`).
  final double faceChroma;

  /// Edge bleed strength `[0..1]` for large surfaces (`h > 64 pt`).
  final double bleedStrength;

  /// `+1.0` for light-mode frost bleed, `-1.0` for dark-mode smoked bleed.
  final double bleedSign;

  /// `1.0` enables luma-bracketed chromatic tinting; `0.0` keeps legacy
  /// luminance-shift tinting for custom/classic presets.
  final double lumaBracketTint;

  /// Effective frost blur sigma (quantized to 0.5 pt steps when size-adaptive
  /// so resizing animations do not thrash `ImageFilter.blur` caches).
  final double effectiveFrostSigma;

  /// Effective bevel thickness in logical pixels, synchronized between the
  /// cached geometry matte and the render pass. For tiny size-adaptive pills
  /// (`h < 44 pt`) this caps smoothly at `max(8.0, 0.75 * h)` so refraction
  /// does not over-bend the center; standard controls (`h >= 44 pt`) keep
  /// `settings.effectiveThickness` unchanged.
  final double effectiveThickness;

  /// Multiplier applied to drop-shadow alpha for large size-adaptive platters:
  /// `1.0` for small/medium controls (`h <= 64 pt`), easing smoothly down to
  /// `0.55` at `h >= 160 pt` (matching CoreAnimation's shadow attenuation on
  /// large alerts, menus, and cards).
  final double shadowOpacityScale;

  /// Whether the CoreAnimation face model is active.
  bool get isActive => faceWhite > faceBlack;

  /// Packs `uFace` (slots 54..57 in `liquid_glass_render.frag` and 39..42 in
  /// `lightweight_glass.frag`).
  List<double> get uFace => <double>[
        faceBlack,
        faceWhite,
        faceMaxLuma,
        faceFillAlpha,
      ];

  /// Packs `uFaceExtra` (slots 58..61 in `liquid_glass_render.frag`).
  List<double> get uFaceExtra => <double>[
        faceChroma,
        bleedStrength,
        bleedSign,
        lumaBracketTint,
      ];
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Quantizes a blur sigma to 0.5 logical-pixel steps to prevent per-frame
/// `ImageFilter.blur` allocation churn during height animations.
double quantizeSigmaHalfPt(double sigma) =>
    sigma <= 0 ? 0.0 : (sigma * 2.0).round() / 2.0;

/// Resolves the logical bevel thickness shared between the cached geometry
/// matte (`RenderLiquidGlassBlendGroup`) and the render pass
/// (`LiquidGlassRenderObject`).
///
/// When `settings.sizeAdaptive` is enabled and `shortestSide` is positive,
/// compact controls (`h < 44 pt`, e.g. 24–36 pt pills/badges) cap their bevel
/// smoothly at `max(8.0, shortestSide * 0.75)` so refraction never over-bends
/// the interior; all standard controls (`h >= 44 pt`) and non-adaptive
/// settings keep `settings.effectiveThickness` unchanged.
double resolveEffectiveGlassThickness(
  LiquidGlassSettings settings,
  double shortestSide,
) {
  final base = settings.effectiveThickness;
  if (!settings.sizeAdaptive ||
      base <= 0.0 ||
      !shortestSide.isFinite ||
      shortestSide <= 0.0) {
    return base;
  }
  final cap = math.max(8.0, shortestSide * 0.75);
  return math.min(base, cap);
}

/// Resolves CoreAnimation-calibrated face tone, SDR max-luma ceiling, edge
/// bleed, and size-adaptive frost sigma for [settings] at logical shortest
/// side [shortestSide].
///
/// Calibration sources:
/// - **iOS 27 (`ios27Light` / `ios27Dark`):** Measured directly from live
///   iOS 27.0 CoreAnimation `glassBackground` filter archives (`h = 30..160 pt`):
///   - Light: `black=0.40, white=1.03, chroma=1.20, fill=+0.20, maxLuma=0.94`,
///     bleed `0.5 * t` (`t = clamp((h - 64) / 96, 0, 1)`).
///   - Dark: `black=0.125, white=1.125, chroma=1.30, fill=0.0`,
///     `maxLuma = lerp(0.60, 0.35, clamp((h - 64) / 40, 0, 1))`,
///     bleed `0.8 * t`.
/// - **iOS 26 (`ios26Light` / `ios26Dark`):** Calibrated to iOS 26.5
///   CoreAnimation `glassBackground` small (`≤ 64 pt`) vs large (`160 pt`)
///   face laws with `0.97` SDR holding tone.
///
/// Returns disabled optics (preserving `effectiveFrostSigma =
/// settings.effectiveFrost`) whenever:
/// - `settings.sizeAdaptive` is `false` (all custom, classic, indicator, and
///   clear presets — bit-exact backwards compatibility), OR
/// - `settings.bodyMode == GlassBodyMode.clear` (explicit design-token hex
///   tints such as prominent buttons stay pixel-accurate), OR
/// - `settings.visibility <= 0.001`, OR
/// - the glass surface has been faded dormant (e.g. `GlassModalSheet` scaling
///   `glassColor.a`, `frost`, `blur`, and `thickness` to zero), OR
/// - the caller explicitly replaced the preset's achromatic `glassColor` with
///   a custom achromatic tint or higher opacity (honoring explicit overrides).
ResolvedGlassFaceOptics resolveGlassFaceOptics(
  LiquidGlassSettings settings,
  double shortestSide,
) {
  final baseFrost = settings.effectiveFrost;
  final effectiveThickness =
      resolveEffectiveGlassThickness(settings, shortestSide);
  ResolvedGlassFaceOptics inactive() => ResolvedGlassFaceOptics(
        faceBlack: 0.0,
        faceWhite: 0.0,
        faceMaxLuma: 1.0,
        faceFillAlpha: 0.0,
        faceChroma: 1.0,
        bleedStrength: 0.0,
        bleedSign: 0.0,
        lumaBracketTint: 0.0,
        effectiveFrostSigma: baseFrost,
        effectiveThickness: settings.effectiveThickness,
        shadowOpacityScale: 1.0,
      );

  if (!settings.sizeAdaptive ||
      settings.bodyMode == GlassBodyMode.clear ||
      settings.visibility <= 0.001) {
    return inactive();
  }

  // Dormant / faded-off surfaces (e.g. GlassModalSheet at full detent or
  // SheetMorphGeometry.dormantSurface) zero out frost, blur, thickness, and
  // glassColor.a without altering visibility.
  if (baseFrost <= 0.001 &&
      settings.effectiveBlur <= 0.001 &&
      settings.effectiveThickness <= 0.001 &&
      settings.glassColor.a <= 0.001) {
    return inactive();
  }

  final bool isDark = settings.frostClamp < 0.0;
  final int colorRgb = settings.glassColor.toARGB32() & 0x00FFFFFF;
  // Identify iOS 27 vs iOS 26 cleanly even when rimShade is scaled toward 0
  // during GlassModalSheet fade-out.
  final bool isIos27 = settings.rimShade > 0.0 ||
      (!isDark && colorRgb == 0xF8F8F8) ||
      (isDark && (settings.frostClamp - (-0.45)).abs() < 0.01);

  final presetColor = isIos27
      ? (isDark
          ? LiquidGlassSettings.ios27Dark.glassColor
          : LiquidGlassSettings.ios27Light.glassColor)
      : (isDark
          ? LiquidGlassSettings.ios26Dark.glassColor
          : LiquidGlassSettings.ios26Light.glassColor);
  final int presetRgb = presetColor.toARGB32() & 0x00FFFFFF;

  final gc = settings.glassColor;
  final double maxC = math.max(gc.r, math.max(gc.g, gc.b));
  final double minC = math.min(gc.r, math.min(gc.g, gc.b));
  final double chroma = maxC - minC;
  final bool isChromatic = chroma > 0.04;
  final bool matchesPresetRgb = colorRgb == presetRgb;

  // Respect explicit user overrides of achromatic glassColor (different neutral
  // color, or explicitly raised opacity above the preset baseline) instead of
  // silently discarding them in the shader's uFace branch.
  if (!isChromatic) {
    if (!matchesPresetRgb || gc.a > presetColor.a + 0.005) {
      return inactive();
    }
  }

  // When a widget (such as GlassModalSheet) fades an era preset out by scaling
  // glassColor.a downward toward 0, track that presence factor in lockstep so
  // uFace dissolves smoothly to identity with zero pop at full expansion.
  final double alphaPresence = !isChromatic && presetColor.a > 0.001
      ? (gc.a / presetColor.a).clamp(0.0, 1.0)
      : 1.0;
  final double presence = settings.visibility.clamp(0.0, 1.0) * alphaPresence;
  if (presence <= 0.001) {
    return inactive();
  }

  final h = shortestSide.isFinite && shortestSide > 0
      ? shortestSide.clamp(24.0, 160.0)
      : 44.0;
  // Large-surface ramp: 0 at h <= 64 pt (pills/buttons/bars), 1 at h >= 160 pt
  // (menus/cards/dialogs/sheets).
  final double largeT = ((h - 64.0) / 96.0).clamp(0.0, 1.0);
  // iOS 27 dark maxLuma transitions tightly between 64 pt and 104 pt.
  final double ios27DarkCapT = ((h - 64.0) / 40.0).clamp(0.0, 1.0);

  double faceBlack;
  double faceWhite;
  double faceMaxLuma;
  double faceFillAlpha;
  double faceChroma;
  double bleedStrength;
  double bleedSign;

  if (isIos27) {
    if (isDark) {
      faceBlack = 0.125;
      faceWhite = 1.125;
      faceMaxLuma = _lerp(0.60, 0.35, ios27DarkCapT);
      faceFillAlpha = 0.0;
      faceChroma = 1.30;
      bleedStrength = 0.80 * largeT;
      bleedSign = -1.0;
    } else {
      faceBlack = 0.40;
      faceWhite = 1.03;
      faceMaxLuma = 0.94;
      faceFillAlpha = 0.20;
      faceChroma = 1.20;
      bleedStrength = 0.50 * largeT;
      bleedSign = 1.0;
    }
  } else {
    if (isDark) {
      faceBlack = _lerp(0.06, 0.14, largeT);
      faceWhite = _lerp(0.72, 0.48, largeT);
      faceMaxLuma = 0.97;
      faceFillAlpha = -_lerp(0.06, 0.16, largeT);
      faceChroma = 1.15;
      bleedStrength = 0.55 * largeT;
      bleedSign = -1.0;
    } else {
      faceBlack = _lerp(0.36, 0.42, largeT);
      faceWhite = 1.00;
      faceMaxLuma = 0.97;
      faceFillAlpha = _lerp(0.22, 0.44, largeT);
      faceChroma = _lerp(1.15, 0.95, largeT);
      bleedStrength = 0.35 * largeT;
      bleedSign = 1.0;
    }
  }

  // Smoothly dissolve the face transform toward identity as presence -> 0
  // (covers both GlassMaterializeScope visibility fades and GlassModalSheet
  // alpha/frost expansion fades).
  if (presence < 1.0) {
    faceBlack = _lerp(0.0, faceBlack, presence);
    faceWhite = _lerp(1.0, faceWhite, presence);
    faceMaxLuma = _lerp(1.0, faceMaxLuma, presence);
    faceFillAlpha *= presence;
    faceChroma = _lerp(1.0, faceChroma, presence);
    bleedStrength *= presence;
  }

  // Frost blur scaling:
  // - Live iOS 27.0 CoreAnimation probing (h = 30..160 pt) shows Apple keeps
  //   inputBlurFillBlurRadius = 8.0 strictly constant across all surface sizes
  //   (adapting only maxLumaSDR and bleedOpacity). Keeping baseFrost constant
  //   on iOS 27 also guarantees Impeller's GlassBackdropGroup filter cache
  //   (all_filters_equal) never busts when 44 pt app-bar buttons share a group
  //   with a 64..72 pt bottom tab bar.
  // - On iOS 26, standalone large surfaces (h > 64 pt) deepen frost up to +35%,
  //   quantized to 0.5 pt steps to avoid per-frame ImageFilter cache churn.
  final double scaledFrost = baseFrost <= 0
      ? 0.0
      : isIos27
          ? baseFrost
          : quantizeSigmaHalfPt(baseFrost * (1.0 + 0.35 * largeT));

  final double shadowOpacityScale = _lerp(1.0, 0.55, largeT);

  return ResolvedGlassFaceOptics(
    faceBlack: faceBlack,
    faceWhite: faceWhite,
    faceMaxLuma: faceMaxLuma,
    faceFillAlpha: faceFillAlpha,
    faceChroma: faceChroma,
    bleedStrength: bleedStrength,
    bleedSign: bleedSign,
    lumaBracketTint: 1.0,
    effectiveFrostSigma: math.max(0.0, scaledFrost),
    effectiveThickness: effectiveThickness,
    shadowOpacityScale: shadowOpacityScale,
  );
}
