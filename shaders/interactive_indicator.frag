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
uniform vec2 uSize;                 // Widget size in logical pixels
uniform vec2 uOrigin;               // Origin offset (usually 0,0 due to layers)
uniform vec4 uGlassColor;           // Tint color for the glass
uniform float uThickness;           // Glass thickness (affects visual weight)
uniform vec2 uLightDirection;      // Pre-calculated light vector [cos(angle), -sin(angle)]
uniform float uLightIntensity;      // Brightness of rim highlights (0-2)
uniform float uAmbientStrength;     // Base ambient brightness
uniform float uSaturation;          // Color saturation
uniform float uRefractiveIndex;     // Rim prominence
uniform float uChromaticAberration; // RGB separation strength (0-1)
uniform float uCornerRadius;        // Pill corner radius in logical pixels
uniform vec2 uScale;                // Device scale (usually 1,1 in layer)
uniform float uGlowIntensity;       // Interactive glow when pressed
uniform float uDensityFactor;       // Visual density for nested glass
uniform float uInteractionIntensity;// Press/drag intensity (0-1)
uniform vec2 uBackgroundOrigin;     // Widget position in background (logical px)
uniform vec2 uBackgroundSize;       // Background texture size (logical px)
uniform float uHasBackground;       // 1.0 = use texture, 0.0 = use synthetic frost

uniform sampler2D uTexture;         // Captured background image

out vec4 fragColor;

void main() {
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
  vec2 surfaceNormal = (edgeLen > 0.001) ? normalize(toEdge) : vec2(0.0);
  
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
  
  // Apply refraction offset (subtract because we bend inward)
  vec2 localRefracted = posInBg - edgeOffsetLogical;
  
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
    // REAL REFRACTION: Sample from captured background
    vec3 colR = texture(uTexture, (localRefracted + chromaticShift) / uBackgroundSize).rgb;
    vec3 colG = texture(uTexture, localRefracted / uBackgroundSize).rgb;
    vec3 colB = texture(uTexture, (localRefracted - chromaticShift) / uBackgroundSize).rgb;
    bg = vec3(colR.r, colG.g, colB.b);
  } else {
    // SYNTHETIC FROST: Premium semi-transparent white base
    // This makes it look "cool" even without a background capture
    bg = vec3(0.1);
  }
  
  // uLightDirection is passed from Dart as [cos(angle), -sin(angle)]
  float edgeLightCatch = dot(surfaceNormal, uLightDirection);
  
  // Key light: bright highlight on edges facing the light
  // TWEAK: pow exponent (8.0) controls sharpness - higher = tighter highlight
  float keyHighlight = pow(max(edgeLightCatch, 0.0), 8.0) * uLightIntensity * 2.0;
  
  // Kick light: subtle highlight on opposite edge (back-reflection)
  // TWEAK: pow exponent (12.0) is higher for tighter back-reflection
  float kickHighlight = pow(max(-edgeLightCatch, 0.0), 12.0) * uLightIntensity * 0.5;
  
  // TWEAK: ambientRim - minimum rim brightness regardless of light direction
  float ambientRim = 0.1;
  float rimBrightness = ambientRim + keyHighlight + kickHighlight;
  
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
  
  // Thin bright line at the very edge of the pill
  float borderMask = 1.0 - smoothstep(0.0, smoothing * 1.5, distFromEdge - 0.5);
  vec3 rimColor = vec3(1.0) * rimBrightness;
  
  // ==========================================================================
  // COMPOSITE FINAL COLOR
  // ==========================================================================
  
  // Start with background, slightly brightened (glass adds luminosity)
  // TWEAK: multiplier (0.6) - increase for brighter glass
  vec3 finalColor = bg * 0.6;
  
  // Add rim highlight
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
  float baseAlpha = (uHasBackground > 0.5) ? 0.7 : 0.2;
  
  // TWEAK: edgeAlpha - edge opacity (higher = more solid edges)
  float edgeAlpha = 0.95;
  
  // Blend from center to edge
  float glassAlpha = mix(baseAlpha, edgeAlpha, edgeInfluence);
  glassAlpha = max(glassAlpha, borderMask * 0.9);
  
  float alpha = glassAlpha * mask;
  
  // Premultiplied alpha output
  fragColor = vec4(finalColor * alpha, alpha);
}
