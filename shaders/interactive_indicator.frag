#include <flutter/runtime_effect.glsl>

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

uniform sampler2D uTexture;         // Captured background image

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
  //   First number (0.6): base strength multiplier
  //     Increase for more distortion, decrease for subtler effect
  //   Second part (0.6 + intensity * 0.5): dynamic range
  //     0.6 = minimum strength at rest (60% of base)
  //     0.5 = additional strength when pressed (up to 110% of base)
  float bendStrength = 0.6 * (0.6 + uInteractionIntensity * 0.5);
  
  // TWEAK: The final multiplier (uSize.y * 0.35) scales by widget height
  //   0.35 means max offset is 35% of widget height
  //   Increase for more dramatic effect, decrease for subtler
  vec2 edgeOffsetLogical = surfaceNormal * edgeInfluence * bendStrength * uSize.y * 0.35;
  vec2 edgeOffsetUV = edgeOffsetLogical / uBackgroundSize;
  
  // Apply refraction offset along the surface normal.
  // On OpenGL ES the background texture is stored with a bottom-left Y origin,
  // so edgeOffsetLogical.y (computed in Flutter's Y-down space) must be
  // negated to sample in the correct outward direction in the Y-up UV space.
  #ifdef IMPELLER_TARGET_OPENGLES
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
    if (uChromaticAberration < 0.001) {
      // No chromatic aberration — single texture fetch (2/3 fewer samples vs
      // the 3-channel path). This is the common default configuration.
      bg = texture(uTexture, localRefracted / uBackgroundSize).rgb;
    } else {
      // REAL REFRACTION with chromatic aberration: separate RGB channels
      vec3 colR = texture(uTexture, (localRefracted + chromaticShift) / uBackgroundSize).rgb;
      vec3 colG = texture(uTexture, localRefracted / uBackgroundSize).rgb;
      vec3 colB = texture(uTexture, (localRefracted - chromaticShift) / uBackgroundSize).rgb;
      bg = vec3(colR.r, colG.g, colB.b);
    }
  } else {
    // SYNTHETIC LIQUID: Bright clear base with subtle tint
    // We use a high base color (0.9) to ensure it looks like pure glass
    bg = vec3(0.9);
  }
  
  // uLightDirection is passed from Dart as [cos(angle), -sin(angle)]
  float edgeLightCatch = dot(surfaceNormal, uLightDirection);
  
  // Key light: bright highlight on edges facing the light
  // TWEAK: pow exponent (8.0) controls sharpness - higher = tighter highlight
  // NOTE: Using * 0.5 (same scale as kickHighlight) to avoid an over-bright "dot"
  // at the pill corner where the light direction perfectly aligns with the corner normal.
  float keyHighlight = pow(max(edgeLightCatch, 0.0), 8.0) * uLightIntensity * 0.5;
  
  // Kick light: subtle highlight on opposite edge (back-reflection)
  // TWEAK: pow exponent (12.0) is higher for tighter back-reflection
  float kickHighlight = pow(max(-edgeLightCatch, 0.0), 12.0) * uLightIntensity * 0.5;
  
  // TWEAK: ambientRim - minimum rim brightness regardless of light direction
  float rimBrightness = uAmbientRim + keyHighlight + kickHighlight;
  
  // ==========================================================================
  // FRESNEL GLOW
  // ==========================================================================
  // Subtle glow at grazing angles (edges appear slightly brighter)
  
  // TWEAK: multiplier (0.25) controls fresnel intensity
  float fresnel = pow(radialDist, 2.0) * 0.25;
  
  // ==========================================================================
  // HAIRLINE RIM
  // ==========================================================================
  // Thin bright line at the very edge of the pill
  
  // Configurable hairline rim
  float borderMask = 1.0 - smoothstep(0.0, smoothing * uRimSmoothing, distFromEdge - uRimThickness);
  // Scale rim brightness with ambientRim parameter
  vec3 rimColor = vec3(1.0) * rimBrightness * (uAmbientRim * 10.0);
  
  // ==========================================================================
  // COMPOSITE FINAL COLOR
  // ==========================================================================
  
  // Start with background, slightly brightened (glass adds luminosity)
  // TWEAK: multiplier (0.6) - increase for brighter glass
  vec3 finalColor = bg * 0.6;
  
  // Add rim highlight (only if rimColor is non-zero)
  finalColor += rimColor * borderMask;
  
  // Add fresnel glow
  // TWEAK: multiplier (0.5) controls fresnel brightness
  finalColor += vec3(1.0) * fresnel * 0.5;
  
  // Add constant brightness boost (makes glass feel more "lit")
  // TWEAK: (0.08) - increase for overall brighter appearance
  //finalColor += vec3(0.08);
  
  // Apply glass tint color
  finalColor = mix(finalColor, finalColor + uGlassColor.rgb * 0.2, uGlassColor.a);
  
  // Clamp to prevent over-bright pixels
  finalColor = min(finalColor, vec3(1.2));
  
  // ==========================================================================
  // ALPHA / TRANSPARENCY
  // ==========================================================================
  
  // TWEAK: baseAlpha - center transparency (lower = more see-through)
  // Standard mode: Fade to fully transparent at rest (Intensity 0)
  float standardBaseAlpha = uBaseAlphaMultiplier * uInteractionIntensity;
  float baseAlpha = (uHasBackground > 0.5) ? 0.7 : standardBaseAlpha;
  
  // TWEAK: edgeAlpha - edge opacity (higher = more solid edges)
  // Standard mode: Keep a faint structural rim even at rest (Intensity 0)
  float standardEdgeAlpha = uEdgeAlphaMultiplier * mix(0.3, 1.0, uInteractionIntensity);
  float edgeAlpha = (uHasBackground > 0.5) ? 0.95 : standardEdgeAlpha;
  
  // Blend from center to edge
  float glassAlpha = mix(baseAlpha, edgeAlpha, edgeInfluence);
  // The hardcoded `borderMask * 0.9` floor used to enforce a structural
  // rim even when the caller dropped baseAlpha/edgeAlpha to zero —
  // "prevents invisible shapes." That's fine for surfaces where you
  // want a permanent rim, but for an interactive indicator over a
  // PlatformView it manifests as a visible "rim flash" at the end of
  // the morph animation that can't be tuned away.
  //
  // Scaling the floor by `uEdgeAlphaMultiplier` makes it caller-
  // controlled: pass edgeAlphaMultiplier=0 to fully kill the floor
  // (and with it the morph-time rim), or leave it at the default 0.4
  // to preserve the original iOS-26 baseline.
  glassAlpha = max(glassAlpha, borderMask * 0.9 * uEdgeAlphaMultiplier);
  
  float alpha = glassAlpha * mask;
  
  // Premultiplied alpha output
  fragColor = vec4(finalColor * alpha, alpha);
}
