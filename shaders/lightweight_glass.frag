#include <flutter/runtime_effect.glsl>

precision highp float;

/*
  LightweightLiquidGlass (Skia/Web fallback)
  -----------------------------------------yes
*/

// -----------------------------------------------------------------------------
// UNIFORMS (Managed by LightweightLiquidGlass.dart)
// -----------------------------------------------------------------------------
uniform vec2 uSize;                 // 0, 1 (Logical Size)
uniform vec2 uOrigin;               // 2, 3 (Physical Screen Origin)
uniform vec4 uGlassColor;           // 4, 5, 6, 7
uniform float uThickness;           // 8
uniform float uLightAngle;          // 9 (radians)
uniform float uLightIntensity;      // 10
uniform float uAmbientStrength;     // 11
uniform float uSaturation;          // 12 (REPURPOSED: glow intensity 0.0-1.0)
                                     //    0.0 = no glow, 1.0 = full glow
                                     //    Used for button press states on Skia
uniform float uRefractiveIndex;     // 13 (REPURPOSED: rim opacity multiplier 0.7-2.0)
                                     //    Impeller: actual refraction physics
                                     //    Lightweight: rim alpha boost (1.0=neutral)
uniform float uChromaticAberration; // 14 (Impeller-only, ignored here)
uniform float uCornerRadius;        // 15 (logical pixels)
uniform vec2 uScale;                // 16, 17 (Physical Scale including DPR)

// -----------------------------------------------------------------------------
// iOS 26 LIQUID GLASS: AESTHETIC PARAMETERS
// -----------------------------------------------------------------------------

// SHAPE & STRUCTURE
const float kBorderThickness      = 0.5;   // Structural hairline width (logical pixels)
                                            // iOS 26 uses 0.5px hairline for crisp edges
const float kNormalThreshold      = 0.01;  // Minimum gradient length for normal extraction
                                            // Prevents divide-by-zero in flat regions

// SPECULAR HIGHLIGHTS (Dual-highlight model for glass depth)
const float kSpecularPowerPrimary = 14.0;  // Key light sharpness (higher = tighter highlight)
                                            // 14.0 = sharp but not pinpoint (iOS 26 aesthetic)
const float kSpecularPowerKick    = 20.0;  // Back-surface reflection sharpness
                                            // 20.0 = sharper than primary (internal reflection)
const float kKickIntensity        = 0.4;   // Back-surface brightness relative to primary
                                            // 0.4 = subtle depth cue without overpowering

// RIM & BODY COLOR BALANCE
const float kRimBaseOpacity       = 0.4;   // Base rim brightness (before light modulation)
                                            // 0.4 = visible structure without dominating
const float kRimSpecularMix       = 0.6;   // How much specular highlights boost rim
                                            // 0.6 = balanced between flat and glossy
const float kRimAlphaBase         = 0.8;   // Base rim alpha (calibrated to Impeller)
                                            // 0.8 = strong edge definition
const float kRimAlphaSpecular     = 0.5;   // Alpha boost from light catch
                                            // 0.5 = highlights enhance edge without blowout
const float kBodyAmbientBoost     = 0.1;   // Ambient light lift for body color
                                            // 0.1 = subtle depth without washing out
const float kCompositeRimAlpha    = 0.8;   // Rim-to-body blend weighting
                                            // 0.8 = rim dominates at edges

// LIGHT INTENSITY RESPONSE (How uLightIntensity modulates appearance)
const float kMinRimVisibility     = 0.5;   // Minimum rim brightness (ensures shape visible)
                                            // 0.5 = half intensity even at lightIntensity=0
const float kRimIntensityScale    = 0.6;   // Rim response to light intensity changes
                                            // 0.6 = moderate response (more on specular)
const float kBodyIntensityScale   = 0.15;  // Body response to light intensity changes
                                            // 0.15 = subtle (keeps body stable)

// THICKNESS RESPONSE (How uThickness affects appearance)
const float kThicknessReference   = 10.0;  // Neutral thickness value (no modulation)
                                            // Settings: thickness=10 → neutral look
const float kThicknessRimBoost    = 0.15;  // Rim alpha boost per unit thickness
                                            // 0.15 = gradual increase with thickness
const float kThicknessScaleMin    = 0.5;   // Minimum thickness modulation
const float kThicknessScaleMax    = 3.0;   // Maximum thickness modulation

// Chroma-only optics (only used when uChromaticAberration > 0)
const float kDispersionPixels     = 1.2;   // max split in LOGICAL px at chroma=1.0
const float kRefractionStrength   = 0.35;  // bends the internal kick normal slightly

out vec4 fragColor;

void main() {
  // ---- STAGE 0: ZERO-LATENCY COORDINATE SYNC ----
  vec2 pixelCoord = FlutterFragCoord().xy;
  vec2 localLogical = (pixelCoord - uOrigin) / uScale;

  // ---- STAGE 1: SIGNED DISTANCE FIELD (SDF) SHAPE ----
  vec2 halfSize = uSize * 0.5;
  vec2 q = abs(localLogical - halfSize) - halfSize + uCornerRadius;
  float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - uCornerRadius;

  // Anti-aliasing threshold (~1 physical pixel in logical space)
  float smoothing = 1.0 / uScale.x;
  float mask = 1.0 - smoothstep(-smoothing, smoothing, dist);

  if (mask <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // ---- STAGE 2: ANALYTICAL SURFACE NORMALS ----
  vec2 innerHalfSize = uSize * 0.5 - uCornerRadius;
  vec2 p = localLogical - halfSize;
  vec2 closest = clamp(p, -innerHalfSize, innerHalfSize);
  vec2 grad = p - closest;
  vec2 n = (length(grad) > kNormalThreshold) ? normalize(grad) : vec2(0.0);

  // ---- STAGE 3: STRUCTURAL RIM (HAIRLINE MASK) ----
  float borderMask = 1.0 - smoothstep(0.0, smoothing, abs(dist) - kBorderThickness);

  // ---- STAGE 3.5: THICKNESS PHYSICS ----
  // Normalize thickness relative to reference (10.0 = neutral)
  float thicknessNorm = uThickness / kThicknessReference;

  // Specular sharpness: thicker glass = sharper internal reflections
  // thickness=5:  sharpness=0.925 (softer highlights)
  // thickness=10: sharpness=1.0   (neutral)
  // thickness=20: sharpness=1.15  (sharper, more pronounced)
  float specularSharpness = 1.0 + (thicknessNorm - 1.0) * 0.15;

  // ---- STAGE 4: iOS 26 DUAL-HIGHLIGHT PHYSICS ----
  vec2 lightDir = vec2(cos(uLightAngle), -sin(uLightAngle));

  // Primary Specular (Key Light)
  float lightCatch = max(dot(n, lightDir), 0.0);
  float effectivePrimaryPower = kSpecularPowerPrimary * specularSharpness;
  float keySpecular = pow(lightCatch, effectivePrimaryPower) * uLightIntensity;

  // Secondary Specular (Refractive Kick - back surface reflection)
  float kickCatchBase = max(dot(n, -lightDir), 0.0);
  float effectiveKickPower = kSpecularPowerKick * specularSharpness;
  float kickSpecularBase = pow(kickCatchBase, effectiveKickPower) * uLightIntensity * kKickIntensity;

  // ---- STAGE 5: BODY LAYER (ENHANCED INTENSITY MODEL) ----
  float bodyIntensityBoost = kBodyAmbientBoost * (1.0 + uLightIntensity * kBodyIntensityScale);
  vec3 bodyColor = uGlassColor.rgb * (uAmbientStrength + bodyIntensityBoost);
  float bodyAlpha = uGlassColor.a * mask;

  // ---- STAGE 6: RIM LAYER (INTENSITY + THICKNESS RESPONSE) ----
  // Thickness offset from neutral (negative=thin, zero=neutral, positive=thick)
  float thicknessOffset = (uThickness - kThicknessReference) / kThicknessReference;

  // Combine dual-specular highlights
  float rimSpecular = keySpecular + kickSpecularBase;

  // Rim brightness: base + intensity response + thickness boost
  // thickness=5:  +additive (-0.05) = slightly dimmer
  // thickness=10: +additive (0.0)   = neutral
  // thickness=20: +additive (+0.10) = brighter
  float rimBaseWithIntensity = max(
    kMinRimVisibility,
    kRimBaseOpacity * uLightIntensity * kRimIntensityScale
  );
  float rimBrightness = rimBaseWithIntensity + thicknessOffset * 0.10;

  // Rim color: white modulated by brightness and specular
  vec3 rimColorBase = vec3(1.0) * (rimBrightness + rimSpecular * kRimSpecularMix);

  // Rim alpha: base (boosted by refractiveIndex) + specular + thickness response
  // uRefractiveIndex is REPURPOSED here as rim prominence control (0.7-2.0)
  float rimAlphaBase = kRimAlphaBase * uRefractiveIndex;           // Base with prominence
  rimAlphaBase += rimSpecular * kRimAlphaSpecular;                  // Highlight boost
  rimAlphaBase *= (1.0 + thicknessOffset * kThicknessRimBoost);    // Thickness boost
  rimAlphaBase *= borderMask;                                       // Confine to rim
  rimAlphaBase = clamp(rimAlphaBase, 0.0, 1.0);                    // Safety clamp

  // ---- STAGE 7: FINAL COMPOSITE (WITH OPTIONAL GLOW) ----
  // ARCHITECTURE: Always use clean path (no chromatic aberration).
  // Chromatic aberration is an Impeller-only feature requiring backdrop sampling.

  vec3 finalColor = mix(bodyColor, rimColorBase, rimAlphaBase);
  float finalAlpha = max(bodyAlpha, rimAlphaBase * kCompositeRimAlpha);

  // STAGE 7.5: INTERACTIVE GLOW (Skia fallback for GlassGlow)
  // On Impeller, GlassGlow uses advanced compositing.
  // On Skia, we simulate it with a uniform brightness overlay.
  // IMPORTANT: Only applies when saturation is in range 0.0-1.0 (interactive mode)
  // When saturation > 1.0, it's used for color saturation (original behavior)
  if (uSaturation > 0.01 && uSaturation <= 1.0) {
    // Uniform glow across entire surface (no radial falloff)
    // This matches iOS 26 press behavior - whole button brightens
    vec3 glowColor = vec3(1.0);

    // Strong additive blend for instant, visible response
    finalColor = finalColor + glowColor * uSaturation * 0.7;
    finalColor = clamp(finalColor, 0.0, 1.0);

    // Subtle alpha boost to enhance visibility
    finalAlpha = max(finalAlpha, uSaturation * 0.3);
  }

  // PREMULTIPLIED ALPHA (Required for Flutter/Skia blend modes)
  fragColor = vec4(finalColor * finalAlpha, finalAlpha);

  // DEBUG: Uncomment to test if shader is rendering at all (should show bright pink)
  // fragColor = vec4(1.0, 0.0, 1.0, 1.0);

  // ---- LEGACY: ANALYTICAL CHROMA APPROXIMATION (DISABLED) ----
  // Preserved for reference when implementing backdrop sampling.
  // TODO: Re-enable with proper sampler2D uBackdrop texture.
  #if 0
  float chroma = clamp(uChromaticAberration, 0.0, 1.0);

  // CHROMA PATH: analytical spectral split on the rim + slightly more volumetric kick
  // (still not true refraction: no background sampling in Skia fallback)
  vec2 refractedN = normalize(n + (lightDir * (uRefractiveIndex - 1.0) * kRefractionStrength));
  float kickCatchChroma = max(dot(refractedN, -lightDir), 0.0);
  float kickSpecularChroma = pow(kickCatchChroma, effectiveKickPower) * uLightIntensity * kKickIntensity;

  float rimSpecular = keySpecular + kickSpecularChroma;

  // Recompute rim color with chroma kick (keeps motion moments slightly richer)
  vec3 rimColor = vec3(1.0) * (rimBaseWithThickness + rimSpecular * kRimSpecularMix);

  // Dispersion in logical pixels, scaled by chroma and refractiveIndex delta
  float dispersion = (uRefractiveIndex - 1.0) * kDispersionPixels * chroma;

  float rimR = 1.0 - smoothstep(0.0, smoothing, abs(dist + dispersion) - kBorderThickness);
  float rimG = 1.0 - smoothstep(0.0, smoothing, abs(dist) - kBorderThickness);
  float rimB = 1.0 - smoothstep(0.0, smoothing, abs(dist - dispersion) - kBorderThickness);

  vec3 spectralMask = vec3(rimR, rimG, rimB);

  // Use the same rim alpha base, but distribute it spectrally.
  // This guarantees: when chroma->0, output -> clean path.
  vec3 rimAlphaRGB = spectralMask * rimAlphaBase;

  // Per-channel mix (prism feel). Keep it subtle: only modulate spec sharpness a bit.
  float specPowerR = effectivePrimaryPower * mix(1.0, 0.85, chroma);
  float specPowerB = effectivePrimaryPower * mix(1.0, 1.15, chroma);

  float rimRColor = rimBaseWithThickness + (pow(lightCatch, specPowerR) * uLightIntensity) * kRimSpecularMix;
  float rimGColor = rimBaseWithThickness + (rimSpecular * kRimSpecularMix);
  float rimBColor = rimBaseWithThickness + (pow(lightCatch, specPowerB) * uLightIntensity) * kRimSpecularMix;

  vec3 rimColorRGB = vec3(rimRColor, rimGColor, rimBColor);

  vec3 finalColor;
  finalColor.r = mix(bodyColor.r, rimColorRGB.r, rimAlphaRGB.r);
  finalColor.g = mix(bodyColor.g, rimColorRGB.g, rimAlphaRGB.g);
  finalColor.b = mix(bodyColor.b, rimColorRGB.b, rimAlphaRGB.b);

  float maxRimAlpha = max(rimAlphaRGB.r, max(rimAlphaRGB.g, rimAlphaRGB.b));
  float finalAlpha = max(bodyAlpha, maxRimAlpha * kCompositeRimAlpha);

  // PREMULTIPLIED ALPHA (Required for Flutter/Skia blend modes)
  fragColor = vec4(finalColor * finalAlpha, finalAlpha);
  #endif
  // ---- END LEGACY CHROMA CODE ----
}