// Copyright 2026, Sebastian Degenaar for pixel-innovations.com (liquid_glass_widgets)
//
// SPDX-License-Identifier: MIT
//
// Original work — iOS 26-style liquid glass refraction shader for interactive
// indicators (segmented controls, pills). Fully original implementation.

#include <flutter/runtime_effect.glsl>
#include "gles_compat.glsl"

precision highp float;

/*
  iOS 26 LIQUID GLASS INDICATOR SHADER
  =====================================
  
  This shader creates the liquid glass refraction effect for interactive
  indicators (like the pill in a segmented control). It samples a captured
  background texture and applies edge distortion to simulate light bending
  through glass.
  
  COORDINATE SYSTEM:
  - All calculations use LOGICAL pixels (not physical/device pixels)
  - uBackgroundOrigin and uBackgroundSize are in logical pixels
  - This avoids DPR scaling issues across different devices
  
  MAIN EFFECTS:
  1. Edge refraction - bends the background image at the pill edges
  2. Chromatic aberration - separates RGB channels at edges for prism effect
  3. Directional lighting - rim highlights based on light angle
  4. Fresnel glow - subtle glow at grazing angles
  5. Synthetic bevel gradient - top-bright / bottom-dim rim falloff that
     simulates the view-angle gradient of a real 3D Impeller bevel
*/

// -----------------------------------------------------------------------------
// UNIFORMS
// -----------------------------------------------------------------------------
// We pack uniforms into vec4s to avoid Metal's 14 constant buffer limit on the iOS Simulator.
uniform vec4 uData0; // 0..3 (size.x, size.y, origin.x, origin.y)
uniform vec4 uData1; // 4..7 (glassColor)
uniform vec4 uData2; // 8..11 (thickness, lightDir.x, lightDir.y, lightIntensity)
uniform vec4 uData3; // 12..15 (ambientStrength, saturation, refractiveIndex, chromaticAberration)
uniform vec4 uData4; // 16..19 (cornerRadius, scale.x, scale.y, glowIntensity)
uniform vec4 uData5; // 20..23 (densityFactor, interactionIntensity, bgOrigin.x, bgOrigin.y)
uniform vec4 uData6; // 24..27 (bgSize.width, bgSize.height, hasBackground, ambientRim)
uniform vec4 uData7; // 28..31 (baseAlphaMultiplier, edgeAlphaMultiplier, rimThickness, rimSmoothing)
// 32:  uDpr (float)  — device pixel ratio for textureBilinear()
// 33:  uEdgeAbsorption — Beer-Lambert meniscus rim darkening strength [0..1]

uniform sampler2D uTexture;         // Captured background image

// 32: Device pixel ratio — passed from Dart _RenderInteractiveIndicator.
// The background texture is now captured at full DPR resolution, so the
// physical texel size = logical uBackgroundSize * uDpr.
uniform float uDpr;

// 33: Meniscus rim darkening — Beer-Lambert absorption at the pill boundary.
// Applied before specular highlights (physical ordering: light is absorbed
// first, then reflected). Same formula as liquid_glass_render.frag.
// Range: 0.0 (flat, no absorption) → 1.0 (fully dark rim).
// iOS 26 reference calibrated at ~0.15.
uniform float uEdgeAbsorption;

// 34..37: uRimConfig — (rimShade, rimLight, rimShadeEnds, backdropLuma)
uniform vec4 uRimConfig;

// 38: Grazing-angle Fresnel rim strength [0..∞].
uniform float uFresnelStrength;

out vec4 fragColor;

float fastPowInd(float x, float n) {
    return x <= 1e-4 ? 0.0 : exp2(n * log2(x));
}

// ── Manual Bilinear Filtering ─────────────────────────────────────────────
// Impeller's explicit setImageSampler() binding may also default to
// Nearest-Neighbor. Even when it does not, the background texture was
// previously captured at pixelRatio: 1.0, meaning each "texel" covered
// a 3×3 block of physical pixels on a 3× Retina screen. Both issues
// produced blocky staircase aliasing on edge refraction and chromatic
// aberration.
//
// This function replaces all uTexture lookups with a 4-texel bilinear
// interpolation in GLSL, guaranteeing smooth sub-pixel sampling regardless
// of Impeller's sampler default.
//
// uv       — UV coordinate in [0,1] (relative to logical uBackgroundSize)
// logSize  — uBackgroundSize in logical pixels
// physSize — uBackgroundSize * uDpr = actual pixel dimensions of the texture
// invPhys  — 1.0 / physSize (precomputed for efficiency)
vec4 textureBilinear(vec2 uv, vec2 physSize, vec2 invPhys) {
    // Convert UV to physical texel coordinate, centre on the texel grid.
    vec2 px = uv * physSize - 0.5;
    vec2 f  = fract(px);
    vec2 p0 = floor(px);
    vec2 p1 = p0 + vec2(1.0, 0.0);
    vec2 p2 = p0 + vec2(0.0, 1.0);
    vec2 p3 = p0 + vec2(1.0, 1.0);

    // Explicitly clamp to texture bounds. In Impeller, custom FragmentShader 
    // samplers may not use ClampToEdge by default. When the indicator pill 
    // expands outside the RepaintBoundary bounds (e.g. via jelly overshoot 
    // or LiquidStretch scaling), out-of-bounds UVs cause extreme wrap-around 
    // chromatic aliasing (jagged rainbows) on the pill's top/left edges.
    vec2 maxPx = max(vec2(0.0), physSize - 1.0);
    p0 = clamp(p0, vec2(0.0), maxPx);
    p1 = clamp(p1, vec2(0.0), maxPx);
    p2 = clamp(p2, vec2(0.0), maxPx);
    p3 = clamp(p3, vec2(0.0), maxPx);

    vec4 c0 = texture(uTexture, (p0 + 0.5) * invPhys);
    vec4 c1 = texture(uTexture, (p1 + 0.5) * invPhys);
    vec4 c2 = texture(uTexture, (p2 + 0.5) * invPhys);
    vec4 c3 = texture(uTexture, (p3 + 0.5) * invPhys);

    vec4 cTop = mix(c0, c1, f.x);
    vec4 cBot = mix(c2, c3, f.x);
    return mix(cTop, cBot, f.y);
}

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
  float uDensityFactor = uData5.x;
  float uInteractionIntensity = uData5.y;
  vec2 uBackgroundOrigin = uData5.zw;
  vec2 uBackgroundSize = uData6.xy;
  float uHasBackground = uData6.z;
  float uAmbientRim = uData6.w;
  float uBaseAlphaMultiplier = uData7.x;
  float uEdgeAlphaMultiplier = uData7.y;
  float uRimThickness = uData7.z;
  float uRimSmoothing = uData7.w;
  float uRimShade = uRimConfig.x;
  float uRimLight = uRimConfig.y;
  float uRimShadeEnds = uRimConfig.z;
  float uBackdropLuma = uRimConfig.w;

  // ==========================================================================
  // COORDINATE SETUP
  // ==========================================================================
  // FlutterFragCoord gives pixel position within the current drawing layer.
  // Since we're inside a RepaintBoundary layer, this starts at (0,0).
  
  vec2 fragPx = FlutterFragCoord().xy;
  
  // Convert to local logical position (0 to uSize)
  // Note: uOrigin is (0,0) and uScale is (1,1) due to layer boundaries
  vec2 localLogical = (fragPx - uOrigin) / uScale;
  vec2 center = uSize * 0.5;
  vec2 normalizedP = (localLogical - center) / center;
  float radialDist = length(normalizedP);  // 0 at center, 1 at edge
  
  // ==========================================================================
  // SDF PILL SHAPE
  // ==========================================================================
  // Using a standard high-fidelity Rounded Rectangle SDF for lighting stability.
  
  vec2 halfSize = uSize * 0.5;
  vec2 q = abs(localLogical - halfSize) - halfSize + uCornerRadius;
  float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - uCornerRadius;

  // Anti-aliasing: smooth transition at edge
  float smoothing = 1.0 / uScale.x;
  float mask = 1.0 - smoothstep(-smoothing, smoothing, dist);
  
  // Early exit if outside the shape
  if (mask <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }
  
  // ==========================================================================
  // SURFACE NORMAL
  // ==========================================================================
  vec2 innerHalfSize = halfSize - uCornerRadius;
  vec2 p = localLogical - halfSize;
  vec2 closestOnSkeleton = clamp(p, -innerHalfSize, innerHalfSize);
  vec2 toEdge = p - closestOnSkeleton;
  float edgeLen = length(toEdge);
  // Reuse edgeLen for the division — normalize(toEdge) would recompute length()
  // internally. Dividing by the already-computed scalar saves one length() call
  // per fragment in the surface normal path.
  vec2 surfaceNormal = (edgeLen > 0.001) ? (toEdge / edgeLen) : vec2(0.0);
  
  // ==========================================================================
  // BACKGROUND REFRACTION (THE MAIN EFFECT)
  // ==========================================================================
  // Sample the background texture with UV coordinates.
  // All values are in LOGICAL pixels for consistency.
  
  vec2 posInBg = uBackgroundOrigin + localLogical;
  vec2 uvBase = posInBg / uBackgroundSize;
  
  // --------------------------------------------------------------------------
  // EDGE DISTORTION
  // --------------------------------------------------------------------------
  // Creates the "liquid lens" effect at the pill edges by bending the
  // sampled background position inward along the surface normal.
  
  float distFromEdge = abs(dist);
  
  // TWEAK: edgeZone - How far from the edge the distortion extends (logical px)
  //   Smaller = sharper transition, concentrated at very edge
  //   Larger = softer, more gradual effect spreading inward
  float edgeZone = 14.0;
  
  // Calculate influence: 1.0 at edge, 0.0 at edgeZone pixels inward
  float edgeInfluence = smoothstep(edgeZone, 0.0, distFromEdge);
  
  // TWEAK: Quadratic falloff makes the bend gentler (less abrupt)
  //   Use edgeInfluence directly for sharper edge effect
  //   Use edgeInfluence * edgeInfluence for gentler, more natural curve
  //   Use pow(edgeInfluence, 3.0) for even gentler effect
  edgeInfluence = edgeInfluence * edgeInfluence;
  
  // TWEAK: bendStrength - Overall refraction intensity
  //   Base (0.9): stronger edge lens distortion, closer to Impeller volumetric warp
  //   Range: 0.45 (rest) → 1.17 (fully pressed)
  float bendStrength = 0.9 * (0.5 + uInteractionIntensity * 0.7);
  
  // TWEAK: The final multiplier (uSize.y * 0.35) scales by widget height
  //   0.35 means max offset is 35% of widget height
  //   Increase for more dramatic effect, decrease for subtler
  vec2 edgeOffsetLogical = surfaceNormal * edgeInfluence * bendStrength * uSize.y * 0.35;
  vec2 edgeOffsetUV = edgeOffsetLogical / uBackgroundSize;
  
  // Apply refraction offset along the surface normal.
  // On pre-3.46 OpenGL ES the background texture is stored with a bottom-left Y
  // origin, so edgeOffsetLogical.y (computed in Flutter's Y-down space) must be
  // negated to sample in the correct outward direction in the Y-up UV space.
  // Flutter 3.46+ stores it top-down on every backend (see gles_compat.glsl),
  // where negating would invert the refraction instead of correcting it.
  #ifdef LGR_GLES_FLIP_SAMPLE_Y
    vec2 localRefracted = posInBg + vec2(edgeOffsetLogical.x, -edgeOffsetLogical.y);
  #else
    vec2 localRefracted = posInBg - edgeOffsetLogical;
  #endif
  
  // --------------------------------------------------------------------------
  // CHROMATIC ABERRATION
  // --------------------------------------------------------------------------
  // Separates RGB channels slightly at edges, creating a subtle prism effect.
  // Red shifts one way, blue shifts the opposite, green stays centered.
  
  // TWEAK: (0.12) - subtle chromatic shift for "Apple style" refraction
  vec2 distort = surfaceNormal * edgeInfluence * uChromaticAberration;
  vec2 chromaticShift = distort * 0.12; 
  
  vec3 bg;
  if (uHasBackground > 0.5) {
    // Physical texture size (actual pixel dimensions after DPR capture).
    // uBackgroundSize is in LOGICAL pixels; the texture has uDpr× more texels.
    vec2 physBgSize = uBackgroundSize * uDpr;
    vec2 invPhysBgSize = 1.0 / physBgSize;

    if (uChromaticAberration < 0.001) {
      // No chromatic aberration — single bilinear fetch.
      bg = textureBilinear(localRefracted / uBackgroundSize, physBgSize, invPhysBgSize).rgb;
    } else {
      // Chromatic aberration: separate RGB channels with bilinear filtering.
      vec3 colR = textureBilinear((localRefracted + chromaticShift) / uBackgroundSize, physBgSize, invPhysBgSize).rgb;
      vec3 colG = textureBilinear(localRefracted / uBackgroundSize, physBgSize, invPhysBgSize).rgb;
      vec3 colB = textureBilinear((localRefracted - chromaticShift) / uBackgroundSize, physBgSize, invPhysBgSize).rgb;
      bg = vec3(colR.r, colG.g, colB.b);
    }
  } else {
    // SYNTHETIC LIQUID: Use the passed indicator color
    // This allows the standard mode to respect the color passed to the widget
    bg = uGlassColor.rgb;
  }
  
  // uLightDirection is passed from Dart as [cos(angle), -sin(angle)]
  float edgeLightCatch = dot(surfaceNormal, uLightDirection);
  
  // Key light: bright highlight on edges facing the light
  // PP2: pow(x, 8.0) replaced with multiply chain — zero transcendentals.
  // x^8 = ((x^2)^2)^2 — 3 multiplies vs exp(8·log(x)).
  // Same optimisation already applied in lightweight_glass.frag.
  float lc  = max(edgeLightCatch,  0.0);
  float lc2 = lc  * lc;
  float lc4 = lc2 * lc2;
  float keyHighlight = lc4 * lc4 * uLightIntensity * 0.5;  // lc^8
  
  // Kick light: subtle highlight on opposite edge (back-reflection)
  // PP2: pow(x, 12.0) = x^8 * x^4 — 4 multiplies vs transcendental.
  float kc  = max(-edgeLightCatch, 0.0);
  float kc2 = kc  * kc;
  float kc4 = kc2 * kc2;
  float kc8 = kc4 * kc4;
  float kickHighlight = kc8 * kc4 * uLightIntensity * 0.5; // kc^12
  
  // TWEAK: ambientRim - minimum rim brightness regardless of light direction
  float rimBrightness = uAmbientRim + keyHighlight + kickHighlight;
  
  // ==========================================================================
  // FRESNEL GLOW
  // ==========================================================================
  // Subtle glow at grazing angles (edges appear slightly brighter)
  
  // PP2: pow(radialDist, 2.0) → radialDist * radialDist (1 multiply, no transcendental).
  float fresnel = (radialDist * radialDist) * 0.25;
  
  // ==========================================================================
  // HAIRLINE RIM
  // ==========================================================================
  // Thin bright line at the very edge of the pill
  
  // Configurable hairline rim
  float borderMask = 1.0 - smoothstep(0.0, smoothing * uRimSmoothing, distFromEdge - uRimThickness);

  // --------------------------------------------------------------------------
  // SYNTHETIC BEVEL GRADIENT
  // --------------------------------------------------------------------------
  // The Impeller 3D bevel naturally brightens at the top because the top-face
  // normals angle toward the viewer, catching more ambient light. On a flat 2D
  // ring every point gets the same brightness, which reads as "fake".
  //
  // We simulate this by blending rim brightness with a vertical gradient derived
  // from the Y component of the surface normal:
  //   surfaceNormal.y < 0  → top of pill  → brighter (add bevelBoost)
  //   surfaceNormal.y > 0  → bottom       → dimmer   (subtract bevelDip)
  //
  // This is pure ALU — no texture samples, no uniforms required.
  // kBevelStrength: calibrated so the gradient reads clearly on large pills
  // (tab bar ~50px) without being aggressive on small elements (switch thumb ~22px).
  const float kBevelStrength = 0.18;
  // normalY range: -1 (top edge) to +1 (bottom edge) in Flutter's Y-down space
  float bevelGradient = -surfaceNormal.y * kBevelStrength;
  // Blend the gradient in only where the border mask is visible to avoid
  // affecting the body of the pill.
  // Retain at least 65% of rimBrightness at the bottom edge so the bottom
  // capsule arc never disappears against dark backdrops.
  float modifiedRimBrightness = max(rimBrightness * 0.65, rimBrightness + bevelGradient * borderMask);

  // Scale rim brightness with ambientRim parameter
  vec3 rimColor = vec3(1.0) * modifiedRimBrightness * (uAmbientRim * 10.0);

  // Native iOS 26 / iOS 27 indicator rim light (soft cos³ lobe at ends of
  // light axis with inset core + tail) and iOS 27 rim shade (directional dark
  // hairline across light axis), calibrated to match liquid_glass_render.frag.
  // Scaled by activeLens (uInteractionIntensity) so resting switch/slider knobs
  // stay pure white at rest (matching Premium's activeIntensity gate).
  float activeLens = clamp(uInteractionIntensity, 0.0, 1.0);
  float isLightBackdrop = step(0.5, uBackdropLuma);
  float effectiveRimShade = mix(
      uRimShade,
      max(uRimShade, uRimLight * 1.20) * 1.12,
      isLightBackdrop);
  float effectiveShadeEnds = mix(
      uRimShadeEnds * 0.35,
      max(uRimShadeEnds, 0.68),
      isLightBackdrop);
  float nativeRimLight = 0.0;
  float nativeRimShade = 0.0;
  float hairline = 1.0 - smoothstep(0.25, 1.10, distFromEdge);
  if ((uRimLight > 0.001 || uRimShade > 0.001) && activeLens > 0.001 && distFromEdge < 12.0) {
    float along = dot(surfaceNormal, uLightDirection);
    float lit   = max(along, 0.0);
    float opp   = max(-along, 0.0);
    // Indicator lens weights from liquid_glass_render.frag (isClearIndicator=1):
    // litWeight = 0.84, oppWeight = 1.02, indicatorRimBoost = 1.32.
    // On diagonal light angles (e.g. iOS 26 at 135°), cos³(45°) drops to 0.35
    // on the flat top and bottom edges; vertArch ensures the top and bottom
    // horizontal capsule arcs maintain a continuous specular rim.
    float lobe  = 0.84 * lit * lit * lit + 1.02 * opp * opp * opp;
    float vertArch = surfaceNormal.y * surfaceNormal.y * abs(uLightDirection.x);
    float effectiveLobe = max(lobe, vertArch * mix(0.68, 0.54, isLightBackdrop));
    if (uRimLight > 0.001) {
      float inset = max(distFromEdge - 0.75, 0.0);
      float core  = exp(-inset / 1.5);
      float tail  = exp(-inset / 5.5);
      float ease  = mix(0.56, 0.68, isLightBackdrop);
      float hairlineGate = 1.0 - hairline * step(0.001, effectiveRimShade);
      nativeRimLight = clamp(
          uRimLight * 1.32 * effectiveLobe * ease * (0.165 * core + 0.042 * tail) * hairlineGate * activeLens,
          0.0,
          1.0);
    }
    if (effectiveRimShade > 0.001 && distFromEdge < 2.2) {
      float across = fastPowInd(max(0.0, 1.0 - along * along), 1.75);
      nativeRimShade = clamp(
          effectiveRimShade * 0.314 * mix(effectiveShadeEnds, 1.0, across) * hairline * activeLens,
          0.0,
          1.0);
    }
  }

  // [1] Hemisphere lens thickness profile
  float r_norm = clamp(distFromEdge / edgeZone, 0.0, 1.0);
  float lensThickness = sqrt(max(0.0, 1.0 - r_norm * r_norm)); // hemisphere arc

  // [2] Light-modulated strength: weaker on lit side (0.6×), stronger on shadow (1.4×)
  float litness = dot(surfaceNormal, uLightDirection); // [-1, +1]
  float dirScale = mix(1.4, 0.6, litness * 0.5 + 0.5); // shadow → lit
  float modulatedAbsorption = uEdgeAbsorption * dirScale;

  // ==========================================================================
  // COMPOSITE FINAL COLOR
  // ==========================================================================
  float standardBaseAlpha = uBaseAlphaMultiplier * mix(0.6, 1.0, uInteractionIntensity);
  float standardEdgeAlpha = uEdgeAlphaMultiplier * mix(0.6, 1.0, uInteractionIntensity);

  if (uHasBackground > 0.5) {
    // PATH A: Captured background texture refraction
    float bgBoost = uSaturation;
    vec3 finalColor = bg * bgBoost;
    finalColor += rimColor * borderMask * 1.5;
    finalColor += vec3(1.0) * fresnel * (uGlowIntensity + 0.15 * uFresnelStrength);
    finalColor += vec3(uAmbientStrength);
    finalColor = mix(finalColor, finalColor + uGlassColor.rgb * 0.2, uGlassColor.a);

    float absorption = 1.0 - lensThickness * modulatedAbsorption;
    finalColor *= max(0.0, absorption);
    if (nativeRimLight > 0.0) {
      finalColor = mix(finalColor, vec3(1.0), nativeRimLight);
    }
    if (nativeRimShade > 0.0) {
      finalColor *= (1.0 - nativeRimShade);
    }
    finalColor = min(finalColor, vec3(1.2));

    float glassAlpha = mix(0.70, 0.95, edgeInfluence);
    float ringOpacity = borderMask * 0.9 * clamp(uAmbientRim * 10.0, 0.0, 1.0);
    glassAlpha = max(glassAlpha, ringOpacity);
    float alpha = glassAlpha * mask;
    fragColor = vec4(finalColor * alpha, alpha);
  } else {
    // PATH B: Zero-capture synthetic indicator lens (composited via SrcOver).
    // Uses proper premultiplied alpha compositing so meniscus absorption and
    // iOS 27 rimShade genuinely darken the underlying platter at the curved
    // edge, while specular highlights and cos³ rimLight lobes shine with
    // independent specular alpha over a crystal-clear center.
    float hasNativeRimF = step(0.001, uRimLight + uRimShade);
    float bodyAlpha = mix(
        standardBaseAlpha,
        standardEdgeAlpha,
        edgeInfluence * (1.0 - hasNativeRimF));
    vec3 bodyColor  = (uGlassColor.a > 0.001) ? uGlassColor.rgb : vec3(1.0);
    float effectiveBodyA = max(bodyAlpha, uGlassColor.a * mix(0.6, 1.0, uInteractionIntensity));
    vec3 pmRgb = bodyColor * effectiveBodyA;
    float pmA  = effectiveBodyA;

    // 1. Curved meniscus bevel darkening (Beer-Lambert absorption + iOS 27 top keyShade)
    float bevelZone = min(edgeZone, max(4.5, min(uSize.x, uSize.y) * 0.24));
    float bevelNorm = clamp(distFromEdge / bevelZone, 0.0, 1.0);
    float bevelBand = (1.0 - bevelNorm) * (1.0 - bevelNorm);
    float normY = localLogical.y / max(uSize.y, 1.0);
    float topTrough = smoothstep(0.04, 0.16, normY)
                    * (1.0 - smoothstep(0.22, 0.52, normY))
                    * smoothstep(1.5, 3.5, distFromEdge);
    float keyShade = 0.025 * topTrough * isLightBackdrop * hasNativeRimF * (1.0 - hairline) * activeLens;
    float effectiveAbsorption = max(modulatedAbsorption, 0.055 * isLightBackdrop * hasNativeRimF * dirScale);
    float absorbDarken = clamp(
        bevelBand * effectiveAbsorption * mix(0.55, 0.78, isLightBackdrop) * activeLens + keyShade,
        0.0,
        0.42);
    pmRgb *= (1.0 - absorbDarken);
    pmA    = pmA + absorbDarken * (1.0 - pmA);

    // 2. Directional specular rim, top bevel gradient, and grazing Fresnel
    float classicRingSpec = clamp(
        modifiedRimBrightness * (0.85 + uAmbientRim * 3.5) * borderMask,
        0.0,
        0.85);
    float nativePerimeterSpec = borderMask * 0.08 * (1.0 - step(0.001, effectiveRimShade));
    float ringSpec = mix(
        classicRingSpec,
        max(nativePerimeterSpec, classicRingSpec * mix(0.15, 0.55, isLightBackdrop)) * activeLens,
        hasNativeRimF);
    float fresnelSpec = clamp(
        fresnel * (uGlowIntensity * 0.5 + 0.16 * uFresnelStrength) * edgeInfluence * activeLens,
        0.0,
        0.45);
    float totalSpec = clamp(ringSpec + fresnelSpec + uAmbientStrength * activeLens, 0.0, 0.90);
    pmRgb = pmRgb * (1.0 - totalSpec) + vec3(totalSpec);
    pmA   = pmA + totalSpec * (1.0 - pmA);

    // 3. Native iOS 26 / iOS 27 cos³ rimLight lobe (core + tail)
    if (nativeRimLight > 0.0) {
      pmRgb = pmRgb * (1.0 - nativeRimLight) + vec3(nativeRimLight);
      pmA   = pmA + nativeRimLight * (1.0 - pmA);
    }

    // 4. Native iOS 27 directional dark hairline contour (rimShade)
    if (nativeRimShade > 0.0) {
      pmRgb *= (1.0 - nativeRimShade);
      pmA    = pmA + nativeRimShade * (1.0 - pmA);
    }

    fragColor = vec4(clamp(pmRgb, 0.0, 1.0) * mask, clamp(pmA, 0.0, 1.0) * mask);
  }
}
