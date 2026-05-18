#include <flutter/runtime_effect.glsl>

precision highp float;

/*
  Primary rendering path for all platforms (Skia, Web, Impeller).
  Standard quality default + automatic premium quality fallback on non-Impeller.
  -----------------------------------------
*/

// -----------------------------------------------------------------------------
// UNIFORMS
// -----------------------------------------------------------------------------
uniform vec4 uData0; // 0..3  (size.x, size.y, origin.x, origin.y)
uniform vec4 uData1; // 4..7  (glassColor)
uniform vec4 uData2; // 8..11 (thickness, lightDir.x, lightDir.y, lightIntensity)
uniform vec4 uData3; // 12..15 (ambientStrength, saturation, refractiveIndex, chromaticAberration)
uniform vec4 uData4; // 16..19 (cornerRadius, scale.x, scale.y, glowIntensity)
uniform vec4 uData5; // 20..23 (densityFactor, indicatorWeight, specularSharpnessF, backdropLuma)
// cornerRadius < 0 → asymmetric mode; per-corner radii come from uData6.
uniform vec4 uData6; // 24..27 (topLeft, topRight, bottomRight, bottomLeft) — asymmetric only
uniform vec4 uData7; // 28..31 (bgOrigin.x, bgOrigin.y, bgSize.width, bgSize.height)

uniform sampler2D uBackground; // The captured background texture
// Slot 22 (uData5.z): specular sharpness level — passed as float 0.0/1.0/2.0, cast to int.
// Flutter's FragmentShader API only supports setFloat — no setInt exists.
// Passing as a float and rounding in GLSL gives an exact integer; the GPU
// compiler still sees literal-constant exponents per if/else branch.
// Slot 23 (uData5.w): backdropLuma — VQ4 content-adaptive strength proxy.
//   Dart passes MediaQuery.platformBrightness: dark=0.15, light=0.85.
//   When LiquidGlassScope is active the app is explicitly light/dark themed;
//   the brightness flag is the correct per-app signal.

// -----------------------------------------------------------------------------
// iOS 26 LIQUID GLASS: AESTHETIC PARAMETERS (ORIGINAL CALIBRATION)
// -----------------------------------------------------------------------------
// These constants were calibrated to match iOS 26's liquid glass aesthetic.
// Modifications will affect the entire visual appearance.

// Shape & Structure
const float kBorderThickness      = 0.5;   // Rim width in logical pixels (iOS 26 hairline)
const float kNormalThreshold      = 0.01;  // Minimum gradient for surface normal calculation

// Dual-Highlight Specular Model (simulates glass depth)
const float kSpecularPowerPrimary = 14.0;  // Key light sharpness (higher = tighter highlight)
const float kSpecularPowerKick    = 20.0;  // Back-surface reflection sharpness (internal bounce)
const float kKickIntensity        = 0.4;   // Back-surface brightness relative to primary

// Rim & Body Color Balance
const float kRimBaseOpacity       = 0.4;   // Base rim brightness before light modulation
const float kRimSpecularMix       = 0.6;   // How much specular highlights boost rim
const float kRimAlphaBase         = 0.65;  // Base rim opacity (calibrated to Impeller parity)
const float kRimAlphaSpecular     = 0.5;   // Additional opacity from specular highlights
const float kBodyAmbientBoost     = 0.12;  // Additive frost/whitening contribution to body layer
                                            //   Intentionally additive (not multiplicative) so dark
                                            //   backgrounds don't collapse the body to near-black.
const float kCompositeRimAlpha    = 0.8;   // Rim-to-body blend strength at edges

// Light Intensity Response (how uLightIntensity modulates appearance)
const float kMinRimVisibility     = 0.35;  // Minimum rim brightness — lowered from 0.5 so
                                            //   AdaptiveGlass lightIntensity normalisation can
                                            //   actually reach the rim on the Standard (2D) path.
const float kRimIntensityScale    = 0.6;   // Rim sensitivity to light intensity changes
const float kBodyIntensityScale   = 0.15;  // Body sensitivity to light intensity changes

// Thickness Response (how uThickness affects glass appearance)
const float kThicknessReference   = 10.0;  // Neutral thickness value (no visual modulation)
const float kThicknessRimBoost    = 0.15;  // Rim opacity boost per unit thickness deviation  


// -----------------------------------------------------------------------------
// iOS 26 GLASS TINT MODEL (inlined from render.glsl::applyGlassColor)
// -----------------------------------------------------------------------------
// Luminosity-preserving glass tint — matches the Impeller final-render path.
//
// Chromatic glass (blue, amber, green): preserves backdrop luminance while
// shifting hue toward the glass colour.  Prevents the "muddy" darkening that
// a straight alpha-composite produces on saturated colours.
//
// Achromatic glass (white, grey, black): uses a direct alpha-composite so
// white glass actually lifts toward white (a brightness/frost effect).
// Without this, white glass collapses to a luminance-matched grey.
//
// The chroma factor blends smoothly between the two paths — fully branchless.
// glassColor.a = 0 → returns liquidColor unchanged via mix() in both paths.
//
// NOTE: In this shader "liquidColor" = the synthesised glass body (finalColor),
// not a background-texture sample.  The luminance-shift still applies correctly.
const vec3 LUMA_WEIGHTS = vec3(0.299, 0.587, 0.114);

vec3 applyGlassColorLW(vec3 liquidColor, vec4 glassColor) {
    float backdropLuminance = dot(liquidColor, LUMA_WEIGHTS);
    float glassLuminance    = dot(glassColor.rgb, LUMA_WEIGHTS);

    // Luminosity-preserving tint: shift chroma toward glass, keep body brightness.
    vec3 tinted = clamp(glassColor.rgb + (backdropLuminance - glassLuminance), 0.0, 1.0);

    // Chroma of the glass colour: 0 = achromatic, 1 = fully saturated.
    // Sharp ramp so anything with meaningful colour uses the luminosity path.
    float chroma = max(max(glassColor.r, glassColor.g), glassColor.b)
                 - min(min(glassColor.r, glassColor.g), glassColor.b);
    float chromaWeight = clamp(chroma * 8.0, 0.0, 1.0);

    vec3 directMix     = mix(liquidColor, glassColor.rgb, glassColor.a); // achromatic: lift toward glass
    vec3 luminosityMix = mix(liquidColor, tinted,         glassColor.a); // chromatic:  hue-shift, brightness held

    return mix(directMix, luminosityMix, chromaWeight);
}

out vec4 fragColor;

void main() {
  vec2 uSize = uData0.xy;
  vec2 uOrigin = uData0.zw;
  vec4 uGlassColor = uData1;
  float uThickness = uData2.x;
  vec2 uLightDirection = uData2.yz;
  float uLightIntensity = uData2.w;
  float uAmbientStrength = uData3.x;
  float uSaturation = uData3.y;
  float uRefractiveIndex = uData3.z;
  float uChromaticAberration = uData3.w;
  float uCornerRadius = uData4.x;
  vec2 uScale = uData4.yz;
  float uGlowIntensity = uData4.w;
  float uDensityFactor   = uData5.x;
  float uIndicatorWeight = uData5.y;
  // VQ4 + specular: packed into uData5.z / uData5.w to use correct slot 22/23
  // (uSpecularSharpnessF was previously declared as a separate uniform at slot 24,
  // but Dart only writes 23 floats. Packing into uData5.z fixes the alignment.)
  float uSpecularSharpnessF = uData5.z; // 0=soft, 1=medium, 2=sharp
  float uBackdropLuma       = uData5.w; // VQ4: 0.15=dark platform, 0.85=light platform
  vec2 uBackgroundOrigin    = uData7.xy;
  vec2 uBackgroundSize      = uData7.zw;

  // ---- STAGE 0: COORDINATE SYNC ----
  vec2 pixelCoord = FlutterFragCoord().xy;
  vec2 localLogical = (pixelCoord - uOrigin) / uScale;

  // ---- STAGE 1: SDF SHAPE & COMBINED NORMALS ----
  // OPTIMIZATION: We merge SDF distance calculation with surface normal generation.
  // The vector maxQ generated for the SDF exactly defines the surface gradient!
  vec2 halfSize = uSize * 0.5;
  vec2 p = localLogical - halfSize;

  // Asymmetric mode: uCornerRadius < 0 means per-corner radii are in uData6.
  // Quadrant selection: p.x<0 && p.y<0 → topLeft, p.x≥0 && p.y<0 → topRight,
  //                     p.x≥0 && p.y≥0 → bottomRight, p.x<0 && p.y≥0 → bottomLeft.
  // (Y increases downward in logical coords; top = negative p.y half.)
  float r;
  if (uCornerRadius < 0.0) {
    // Select per-corner radius based on fragment quadrant
    if (p.x < 0.0 && p.y < 0.0) {
      r = uData6.x; // topLeft
    } else if (p.x >= 0.0 && p.y < 0.0) {
      r = uData6.y; // topRight
    } else if (p.x >= 0.0 && p.y >= 0.0) {
      r = uData6.z; // bottomRight
    } else {
      r = uData6.w; // bottomLeft
    }
  } else {
    r = uCornerRadius;
  }

  vec2 q = abs(p) - halfSize + r;
  
  vec2 maxQ = max(q, 0.0);
  float maxQLen = length(maxQ);
  float dist = maxQLen + min(max(q.x, q.y), 0.0) - r;
  float smoothing = 1.0 / uScale.x;
  float mask = 1.0 - smoothstep(-smoothing, smoothing, dist);

  if (mask <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // ---- STAGE 2: SURFACE NORMALS ----
  // Since gradient is analytically derived from maximum positive divergence,
  // we do not need to re-clamp and calculate vector magnitudes.
  bool isEdge = maxQLen > kNormalThreshold;
  vec2 surfaceNormal = isEdge ? (sign(p) * maxQ / maxQLen) : vec2(0.0);

  // normalZ: the Z component of the 3D surface normal (view-facing component).
  // normalZ → 0 at the rim (surface nearly perpendicular to view ray)
  // normalZ → 1 at flat interior (surface facing camera directly)
  // Used by VQ2 Fresnel at Stage 7.8. Must be computed from dot(n,n) — not
  // collapsed to a binary int — because the SDF normal varies smoothly across
  // the corner arc, producing a continuous grazing-angle ramp that drives the
  // iOS 26 rim brightening effect. A binary snap would turn this into a hard
  // step, eliminating the smooth Fresnel highlight on rounded corners.
  float normalZ = sqrt(max(0.0, 1.0 - dot(surfaceNormal, surfaceNormal)));

  // ---- STAGE 3: HAIRLINE MASK ----
  float effectiveBorder = kBorderThickness + uIndicatorWeight * 0.2;
  float effectiveSmoothing = smoothing * (1.0 + uIndicatorWeight * 0.2);
  float borderMask = 1.0 - smoothstep(0.0, effectiveSmoothing, abs(dist) - effectiveBorder);

  // ---- STAGE 3.5: SYNTHETIC DENSITY PHYSICS ----
  // Performance Optimization: When a parent container provides blur (Batch-Blur O(1) optimization),
  // child buttons lose the visual "double-darkening" effect of nested BackdropFilters.
  // This stage ANALYTICALLY SIMULATES that visual effect without the O(n) performance cost.
  //
  // Density Factor (uDensityFactor):
  //   - Provided explicitly by AdaptiveGlass for elevated buttons
  //   - 0.0 = normal button (standalone or no elevation)
  //   - 1.0 = fully elevated button (inside glass container with shared blur)
  //
  // Four Coordinated Effects (mimic physics of nested blur):
  //   1. Sharper specular (+20% sharpness) - Appears "harder" like denser material
  //   2. Darker body (-30% ambient) - Simulates double-blur darkening
  //   3. Higher opacity (+15% alpha) - More "solid" appearance
  //   4. Brighter rim (+5% brightness) - Enhanced frost/edge definition
  float densityFactor = uDensityFactor;

  // Density elevation physics: elevated surfaces have a slightly tighter highlight.
  // Applied as a multiplier on the specular, NOT on the exponent — the exponent is
  // now fixed per enum variant (zero-transcendental multiply chain below).
  // Range: 1.0 (normal) → 1.2 (fully elevated), continuous.
  float thicknessNorm = uThickness / kThicknessReference;
  float densitySpecularBoost = (1.0 + (thicknessNorm - 1.0) * 0.15) * (1.0 + densityFactor * 0.2);

  // Decode specular level. Flutter's FragmentShader API only supports setFloat,
  // so the Dart side passes 0.0/1.0/2.0 and we round() to get an exact int.
  // The GPU compiler sees literal-constant exponents per branch and fully unrolls.
  int specLevel = int(round(uSpecularSharpnessF));

  // ---- STAGE 4: DETERMINISTIC LIGHTING (zero-transcendental specular) ----
  // PP2 optimisation: The old code was:
  //   pow(lightCatch, kSpecularPowerPrimary * specularSharpness)
  // pow(x, uniform) compiles on Metal/Vulkan as exp(n·log(x)) — two transcendental
  // ops per fragment. On Apple Metal, ARM Mali, and Qualcomm Adreno this is 4–8×
  // slower than a multiply. kSpecularPowerPrimary * specularSharpness ranged 14–20.
  //
  // Fix: uSpecularSharpness is an integer uniform (0/1/2). Each branch uses a
  // GLSL literal-constant exponent the GPU compiler sees at compilation time and
  // fully unrolls into a pure multiply chain — zero transcendentals.
  //
  // Wave coherency bonus: all fragments in a glass surface share the same value.
  // The driver eliminates dead branches for the entire draw call. In practice:
  // one branch executes, the rest are compiled away — zero warp divergence.
  //
  // Exponents chosen as powers-of-2 for minimum multiply count:
  //   n=8  → 3 multiplies  (soft:   x² → x⁴ → x⁸)
  //   n=16 → 4 multiplies  (medium: x² → x⁴ → x⁸ → x¹⁶, iOS 26 default)
  //   n=32 → 5 multiplies  (sharp:  x² → x⁴ → x⁸ → x¹⁶ → x³²)
  
  // VQ1: Anisotropic specular
  // Mathematical shortcut: surfaceNormal is strictly length 1.0 (if isEdge)
  // or 0.0. We avoid length(), division, and normalize() entirely.
  // length(surfaceNormal + tangent*0.2) = sqrt(1.0 + 0.04) = 1.0198039
  // 1.0 / 1.0198039 = 0.9805806
  vec2 anisoN = isEdge 
      ? (surfaceNormal + vec2(-surfaceNormal.y, surfaceNormal.x) * 0.2) * 0.9805806
      : vec2(0.0);

  float lightCatch = max(dot(anisoN, uLightDirection), 0.0);
  float kickCatch  = max(dot(anisoN, -uLightDirection), 0.0);

  float keySpecular;
  float kickSpecular;
  if (specLevel == 0) {
    // soft: n=8 — 3 multiplies
    float lc2 = lightCatch * lightCatch;
    float lc4 = lc2 * lc2;
    keySpecular = lc4 * lc4;
    float kc2 = kickCatch * kickCatch;
    float kc4 = kc2 * kc2;
    kickSpecular = kc4 * kc4;
  } else if (specLevel == 1) {
    // medium: n=16 — 4 multiplies (iOS 26 default)
    float lc2 = lightCatch * lightCatch;
    float lc4 = lc2 * lc2;
    float lc8 = lc4 * lc4;
    keySpecular = lc8 * lc8;
    float kc2 = kickCatch * kickCatch;
    float kc4 = kc2 * kc2;
    float kc8 = kc4 * kc4;
    kickSpecular = kc8 * kc8;
  } else {
    // sharp: n=32 — 5 multiplies
    float lc2 = lightCatch * lightCatch;
    float lc4 = lc2 * lc2;
    float lc8 = lc4 * lc4;
    float lc16 = lc8 * lc8;
    keySpecular = lc16 * lc16;
    float kc2 = kickCatch * kickCatch;
    float kc4 = kc2 * kc2;
    float kc8 = kc4 * kc4;
    float kc16 = kc8 * kc8;
    kickSpecular = kc16 * kc16;
  }
  keySpecular  *= uLightIntensity * densitySpecularBoost;
  kickSpecular *= uLightIntensity * kKickIntensity * densitySpecularBoost;

  // ---- STAGE 5: BODY LAYER (WITH SYNTHETIC DENSITY) ----
  float bodyIntensityBoost = kBodyAmbientBoost * (1.0 + uLightIntensity * kBodyIntensityScale);

  // Density Effect #2: Darker body (-30% ambient at full density)
  // Simulates how nested BackdropFilters darken background twice
  float effectiveAmbient = uAmbientStrength * (1.0 - densityFactor * 0.3);

  // Sample background texture if available (size > 1.0 means it's not the 1x1 dummy)
  vec3 bgRgb = vec3(uBackdropLuma);
  if (uBackgroundSize.x > 1.0) {
    vec2 posInBg = uBackgroundOrigin + localLogical;
    vec2 uv = posInBg / uBackgroundSize;
    // We do NOT do refraction bending here — lightweight path is flat glass.
    bgRgb = texture(uBackground, uv).rgb;
  }

  // Additive frost model: background shows through via ambient term;
  // bodyIntensityBoost is a fixed additive white lift (the glass 'frost')
  // that prevents the body from collapsing to near-black on dark backgrounds.
  // This ensures BG Sample ON and OFF produce consistent visual weight.
  vec3 bodyColor = bgRgb * effectiveAmbient + vec3(bodyIntensityBoost);

  // Density Effect #3: Higher opacity (+15% alpha at full density)
  // Elevated buttons appear more "solid" and less translucent
  float bodyAlpha = (uGlassColor.a + densityFactor * 0.15) * mask;

  // ---- STAGE 6: RIM LAYER ----
  float thicknessOffset = (uThickness - kThicknessReference) / kThicknessReference;
  float totalSpecular = keySpecular + kickSpecular;
  float rimBaseWithIntensity = max(kMinRimVisibility, kRimBaseOpacity * uLightIntensity * kRimIntensityScale);

  // Density Effect #4: Brighter rim (+5% brightness at full density)
  // Enhanced "frost" at edges makes elevated buttons stand out against containers
  float rimBrightness = rimBaseWithIntensity + thicknessOffset * 0.10 + (densityFactor * 0.05);
  vec3 rimColorBase = vec3(1.0) * (rimBrightness + totalSpecular * kRimSpecularMix);

  // Rim opacity: base (modulated by refractiveIndex) + specular highlights + thickness + density
  float rimAlphaBase = kRimAlphaBase * uRefractiveIndex;
  rimAlphaBase += totalSpecular * kRimAlphaSpecular;
  rimAlphaBase *= (1.0 + thicknessOffset * kThicknessRimBoost) * (1.0 + densityFactor * 0.1);
  rimAlphaBase *= borderMask;
  rimAlphaBase = clamp(rimAlphaBase, 0.0, 1.0);

  // ---- STAGE 7: FINAL COMPOSITE ----
  vec3 finalColor = mix(bodyColor, rimColorBase, rimAlphaBase);
  
  // Indicator-specific luminous boost when uIndicatorWeight is 1.0
  finalColor += vec3(0.05) * uIndicatorWeight;
  float finalAlpha = max(bodyAlpha, rimAlphaBase * kCompositeRimAlpha);

  // STAGE 7.5: INTERACTIVE GLOW (Branchless for GPU efficiency)
  // Uses explicit uGlowIntensity parameter (0.0-1.0) instead of saturation.
  // This matches Impeller's architecture where glow is separate from color saturation.
  float glowMask = step(0.01, uGlowIntensity);
  vec3 glowContribution = vec3(1.0) * uGlowIntensity * 0.3 * glowMask;
  finalColor = clamp(finalColor + glowContribution, 0.0, 1.0);
  finalAlpha = max(finalAlpha, uGlowIntensity * 0.3 * glowMask);

  // STAGE 7.6: iOS 26 GLASS TINT (luminosity-preserving — matches Impeller path)
  // Applied BEFORE saturation so the tint is saturation-neutral, matching the
  // order in liquid_glass_final_render.frag: applyGlassColor → applySaturation.
  //
  // Previously this was an additive tint:
  //   mix(finalColor, finalColor + uGlassColor.rgb * 0.2, uGlassColor.a)
  // That was wrong: additive blending blows out bright surfaces and doesn't
  // preserve luminance, so white glass on a white surface → overexposed white.
  finalColor = applyGlassColorLW(finalColor, uGlassColor);

  // STAGE 7.7: VQ4 CONTENT-ADAPTIVE STRENGTH + COLOR SATURATION
  //
  // Mirror of the VQ4 block in liquid_glass_final_render.frag.
  //
  // In the lightweight path there is no backdrop texture, so we use the
  // platform brightness as the backdrop luma proxy:
  //   uBackdropLuma = 0.15 → dark app theme → richer glass (strength 1.2)
  //   uBackdropLuma = 0.85 → light app theme → subtler glass (strength 0.8)
  //
  // This matches how iOS 26 adaptive glass actually behaves at the system
  // level: dark mode glass is heavier; light mode glass is lighter.
  //
  // Cost: 1 mix() for adaptiveStrength + 1 modified saturation mix() = 2 MADs.
  float adaptiveStrength = mix(1.2, 0.8, uBackdropLuma);

  // Adaptive saturation: same formula as Impeller path.
  float adaptiveSaturation = uSaturation * adaptiveStrength;
  float luminance = dot(finalColor, LUMA_WEIGHTS);
  finalColor = mix(vec3(luminance), finalColor, adaptiveSaturation);
  finalColor = clamp(finalColor, 0.0, 1.0);

  // STAGE 7.8: VQ2 FRESNEL EDGE BRIGHTENING — ported from liquid_glass_final_render.frag.
  // iOS 26 glass is subtly brighter at grazing angles even without a directional
  // highlight. normalZ → 0 at the rim, → 1 at the flat interior.
  // Gated by borderMask (equivalent to Impeller's edgeFactor) so the effect is
  // confined to the rim zone and does not accumulate on interior pixels.
  // VQ4: scale fresnel by adaptiveStrength — rim is crisper on dark content,
  // softer on light content, matching iOS 26 rim behaviour.
  // Fully branchless — zero GPU divergence.
  float fresnel = (1.0 - normalZ) * borderMask * 0.10 * adaptiveStrength;
  finalColor = clamp(finalColor + vec3(fresnel), 0.0, 1.0);

  fragColor = vec4(finalColor * finalAlpha, finalAlpha);
}