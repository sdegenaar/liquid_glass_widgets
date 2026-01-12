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
uniform vec2 uSize;                 // 0, 1 (Logical Size)
uniform vec2 uOrigin;               // 2, 3 (Physical Screen Origin)
uniform vec4 uGlassColor;           // 4, 5, 6, 7
uniform float uThickness;           // 8
uniform vec2 uLightDirection;      // 9, 10 [cos(angle), -sin(angle)]
uniform float uLightIntensity;      // 11
uniform float uAmbientStrength;     // 12
uniform float uSaturation;          // 13 (Color saturation: <1.0=desaturated, 1.0=normal, >1.0=vivid)
                                     //    Now matches Impeller's behavior!
uniform float uRefractiveIndex;     // 14 (Rim prominence: 0.7=subtle, 1.0=normal, 2.0=pronounced)
uniform float uChromaticAberration; // 15 (Impeller-only, ignored in lightweight shader)
uniform float uCornerRadius;        // 16 (logical pixels)
uniform vec2 uScale;                // 17, 18 (Physical scale including DPR)
uniform float uGlowIntensity;       // 19 (Interactive glow: 0.0=off, 1.0=full, button press feedback)
uniform float uDensityFactor;       // 20 (Elevation physics: 0.0=normal, 1.0=elevated, nested blur simulation) 
uniform float uIndicatorWeight;     // 21 (0.0=normal, 1.0=thick/bright indicator style)

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
const float kRimAlphaBase         = 0.8;   // Base rim opacity (calibrated to Impeller parity)
const float kRimAlphaSpecular     = 0.5;   // Additional opacity from specular highlights
const float kBodyAmbientBoost     = 0.1;   // Ambient light contribution to body layer
const float kCompositeRimAlpha    = 0.8;   // Rim-to-body blend strength at edges

// Light Intensity Response (how uLightIntensity modulates appearance)
const float kMinRimVisibility     = 0.5;   // Minimum rim brightness (prevents invisible shapes)
const float kRimIntensityScale    = 0.6;   // Rim sensitivity to light intensity changes
const float kBodyIntensityScale   = 0.15;  // Body sensitivity to light intensity changes

// Thickness Response (how uThickness affects glass appearance)
const float kThicknessReference   = 10.0;  // Neutral thickness value (no visual modulation)
const float kThicknessRimBoost    = 0.15;  // Rim opacity boost per unit thickness deviation  

out vec4 fragColor;

void main() {
  // ---- STAGE 0: COORDINATE SYNC ----
  vec2 pixelCoord = FlutterFragCoord().xy;
  vec2 localLogical = (pixelCoord - uOrigin) / uScale;

  // ---- STAGE 1: SDF SHAPE ----
  vec2 halfSize = uSize * 0.5;
  vec2 q = abs(localLogical - halfSize) - halfSize + uCornerRadius;
  float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - uCornerRadius;
  float smoothing = 1.0 / uScale.x;
  float mask = 1.0 - smoothstep(-smoothing, smoothing, dist);

  if (mask <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // ---- STAGE 2: SURFACE NORMALS ----
  vec2 innerHalfSize = uSize * 0.5 - uCornerRadius;
  vec2 p = localLogical - halfSize;
  vec2 closest = clamp(p, -innerHalfSize, innerHalfSize);
  vec2 grad = p - closest;
  vec2 surfaceNormal = (length(grad) > kNormalThreshold) ? normalize(grad) : vec2(0.0);

  // ---- STAGE 3: HAIRLINE MASK ----
  float effectiveBorder = kBorderThickness + uIndicatorWeight * 0.5;
  float effectiveSmoothing = smoothing * (1.0 + uIndicatorWeight * 0.5);
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
  float thicknessNorm = uThickness / kThicknessReference;
  float specularSharpness = (1.0 + (thicknessNorm - 1.0) * 0.15) * (1.0 + densityFactor * 0.2);

  // ---- STAGE 4: DETERMINISTIC LIGHTING ----
  // uLightDirection is passed from Dart as [cos(angle), -sin(angle)]
  float lightCatch = max(dot(surfaceNormal, uLightDirection), 0.0);
  float keySpecular = pow(lightCatch, kSpecularPowerPrimary * specularSharpness) * uLightIntensity;
  float kickCatch = max(dot(surfaceNormal, -uLightDirection), 0.0);
  float kickSpecular = pow(kickCatch, kSpecularPowerKick * specularSharpness) * uLightIntensity * kKickIntensity;

  // ---- STAGE 5: BODY LAYER (WITH SYNTHETIC DENSITY) ----
  float bodyIntensityBoost = kBodyAmbientBoost * (1.0 + uLightIntensity * kBodyIntensityScale);

  // Density Effect #2: Darker body (-30% ambient at full density)
  // Simulates how nested BackdropFilters darken background twice
  float effectiveAmbient = uAmbientStrength * (1.0 - densityFactor * 0.3);
  vec3 bodyColor = uGlassColor.rgb * (effectiveAmbient + bodyIntensityBoost);

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

  // STAGE 7.6: COLOR SATURATION (Like Impeller!)
  // Apply HSL-style saturation adjustment to final color.
  // This is the ORIGINAL purpose of the saturation parameter.
  // Constants match Impeller's implementation in render.glsl
  const vec3 LUMA_WEIGHTS = vec3(0.299, 0.587, 0.114);
  float luminance = dot(finalColor, LUMA_WEIGHTS);
  finalColor = mix(vec3(luminance), finalColor, uSaturation);
  finalColor = clamp(finalColor, 0.0, 1.0);

  fragColor = vec4(finalColor * finalAlpha, finalAlpha);
}