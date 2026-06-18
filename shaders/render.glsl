// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Shared rendering functions for liquid glass shaders

// Constants
const vec3 LUMA_WEIGHTS = vec3(0.299, 0.587, 0.114);

// NOTE: rotate2d() was removed — it was never called by any shader and was
// compiled into every shader binary that includes render.glsl for no benefit.

// Compute Y coordinate reversing it for OpenGL backend
float computeY(float coordY, vec2 size) {
    #ifdef IMPELLER_TARGET_OPENGLES
        return 1.0 - (coordY / size.y);
    #else
        return coordY / size.y;
    #endif
}


// Optimized highlight color - ~60% fewer operations than original
vec3 getHighlightColor(vec3 backgroundColor, float targetBrightness) {
    float luminance = dot(backgroundColor, LUMA_WEIGHTS);
    
    // Fast saturation approximation using max component only
    float maxComponent = max(max(backgroundColor.r, backgroundColor.g), backgroundColor.b);
    
    // Combined color influence factor using fast rational approximation
    // x/(1+x) is faster than smoothstep and visually similar
    float lum = luminance * 2.5;
    float lumFactor = lum / (1.0 + lum);
    
    float sat = maxComponent * 2.5;
    float satFactor = sat / (1.0 + sat);
    
    float colorInfluence = lumFactor * satFactor;
    
    // Normalize and tint in one step
    vec3 tinted = (backgroundColor / max(luminance, 0.001)) * targetBrightness;
    
    return mix(vec3(targetBrightness), tinted, colorInfluence);
}

// Calculate height/depth of the liquid surface.
// Fully branchless to prevent warp divergence at the edge-to-interior
// transition zone, where the two original `if` branches caused adjacent
// fragments in a warp to take different paths, serialising GPU execution.
//   sd >= 0      → outside glass → height = 0
//   sd < -thick  → deep interior → height = thickness (flat plateau)
//   otherwise    → curved surface → height from spherical cross-section
float getHeight(float sd, float thickness) {
    float safeT  = max(thickness, 1e-4);
    float x      = clamp(safeT + sd, 0.0, safeT);         // 0 when outside, safeT when deep
    float sphere = sqrt(max(0.0, safeT * safeT - x * x)); // spherical cross-section
    float deep   = step(sd, -safeT);                       // 1 when sd < -safeT (deep interior)
    float inside = step(sd, 0.0) * step(1e-5, thickness);  // 1 only when sd<=0 and thickness>0
    return inside * mix(sphere, safeT, deep);
}

// Calculate lighting effects based on displacement data
vec3 calculateLighting(
    vec2 uv,
    vec3 normal,
    float sd,
    float thickness,
    float height,
    vec2 lightDirection,
    float lightIntensity,
    float ambientStrength,
    vec3 backgroundColor
) {
    float normalizedHeight = thickness > 0.0 ? height / thickness : 0.0;
    float shape = clamp((1.0 - normalizedHeight) * 1.111, 0.0, 1.0);
    float thicknessFactor = clamp((thickness - 5.0) * 0.5, 0.0, 1.0);

    // Rim lighting — fast rational approximation: 1/(1+k*x^2)
    float rimWidth = 1.5;
    float k = 0.89;
    float x = sd / rimWidth;
    float rimFactor = 1.0 / (1.0 + k * x * x);

    // Single branchless enable multiplier — replaces three early-return branches
    // that caused warp divergence on pixels at the glass boundary (threads within
    // a warp took different paths, serialising execution).
    // All four inputs are guaranteed non-negative (from clamp, max, or rational
    // approximations on positive values) so multiplying first then stepping is
    // mathematically identical to four separate step() calls — 3 fewer multiplies.
    float enable = step(0.01, shape * thicknessFactor * rimFactor * lightIntensity);

    vec2 normalXY = normal.xy;
    float mainLightInfluence = max(0.0, dot(normalXY, lightDirection));
    float oppositeLightInfluence = max(0.0, dot(normalXY, -lightDirection));
    float totalInfluence = mainLightInfluence + oppositeLightInfluence * 0.8;

    vec3 highlightColor = getHighlightColor(backgroundColor, 1.0);

    vec3 directionalRim = (highlightColor * 0.7) * (totalInfluence * totalInfluence) * lightIntensity * 2.0;
    vec3 ambientRim = (highlightColor * 0.4) * ambientStrength;
    vec3 totalRimLight = (directionalRim + ambientRim) * rimFactor;

    return totalRimLight * thicknessFactor * shape * enable;
}

// Calculate refraction with physically-based chromatic aberration
vec4 calculateRefraction(vec2 screenUV, vec3 normal, float height, float thickness, float refractiveIndex, float chromaticAberration, vec2 uSize, sampler2D backgroundTexture, out vec2 refractionDisplacement) {
    float baseHeight = thickness * 8.0;
    vec3 incident = vec3(0.0, 0.0, -1.0);
    
    // Cache reciprocals to avoid repeated division
    float invRefractiveIndex = 1.0 / refractiveIndex;
    vec2 invUSize = 1.0 / uSize;
    
    // Pre-compute base refraction vector once
    vec3 baseRefract = refract(incident, normal, invRefractiveIndex);
    float baseRefractLength = (height + baseHeight) / max(0.001, abs(baseRefract.z));
    vec2 baseDisplacement = baseRefract.xy * baseRefractLength;
    refractionDisplacement = baseDisplacement;
    
    // Optimize for the most common case: no chromatic aberration
    if (chromaticAberration < 0.001) {
        vec2 refractedUV = screenUV + baseDisplacement * invUSize;
        return texture(backgroundTexture, refractedUV);
    }
    
    // Chromatic aberration path - 3 texture samples only
    float dispersionStrength = chromaticAberration * 0.5;
    vec2 redOffset = baseDisplacement * (1.0 + dispersionStrength);
    vec2 blueOffset = baseDisplacement * (1.0 - dispersionStrength);

    vec2 redUV = screenUV + redOffset * invUSize;
    vec2 greenUV = screenUV + baseDisplacement * invUSize;
    vec2 blueUV = screenUV + blueOffset * invUSize;

    // Single texture sample per channel - 3 samples total
    float red = texture(backgroundTexture, redUV).r;
    vec4 greenSample = texture(backgroundTexture, greenUV);
    float blue = texture(backgroundTexture, blueUV).b;

    return vec4(red, greenSample.g, blue, greenSample.a);
}

// Apply saturation adjustment to a color
vec3 applySaturation(vec3 color, float saturation) {
    // Convert to HSL-like adjustments
    float luminance = dot(color, LUMA_WEIGHTS);
    
    // Apply saturation adjustment (1.0 = no change)
    vec3 saturatedColor = mix(vec3(luminance), color, saturation);
    
    return clamp(saturatedColor, 0.0, 1.0);
}

// Apply glass color tinting to the liquid color.
// iOS 26 model: chromatic glass (blue, amber) preserves backdrop luminance while
// shifting hue — unlike Overlay which produced unintuitive darkening/brightening.
// Achromatic glass (white, grey, black) uses a direct alpha-composite mix so
// that white glass actually lifts toward white (brightness effect). Without this,
// whites collapse to a luminance-matched grey and can never frost the surface.
// The chroma factor blends smoothly between the two paths — fully branchless.
// glassColor.a = 0 naturally returns liquidColor via mix() in both paths.
//
// tintBlend selects the blending path (mirrors GlassTintBlend in Dart):
//   0 = auto — pick from the tint's chroma (the historical behavior)
//   1 = always luminosity-preserving (near-neutral tints that must stay glassy)
//   2 = always flat blend (dimming layers, backing scrims, frost films)
vec4 applyGlassColor(vec4 liquidColor, vec4 glassColor, float tintBlend) {
    float backdropLuminance = dot(liquidColor.rgb, LUMA_WEIGHTS);
    float glassLuminance    = dot(glassColor.rgb, LUMA_WEIGHTS);

    // Luminosity-preserving tint: shift chroma toward glass, keep backdrop brightness.
    vec3 tinted = clamp(glassColor.rgb + (backdropLuminance - glassLuminance), 0.0, 1.0);

    // Chroma of the glass colour: 0 = achromatic (white/grey/black), 1 = fully saturated.
    // Use a sharp ramp so anything with meaningful colour uses the luminosity path.
    float chroma = max(max(glassColor.r, glassColor.g), glassColor.b)
                 - min(min(glassColor.r, glassColor.g), glassColor.b);
    float autoWeight = clamp(chroma * 8.0, 0.0, 1.0);
    // Tri-state select: auto → chroma gate; 1 → force 1.0; 2 → force 0.0.
    float chromaWeight = tintBlend < 0.5 ? autoWeight
                       : (tintBlend < 1.5 ? 1.0 : 0.0);

    // achromatic path: direct mix toward the glass colour (white lifts to white)
    vec3 directMix     = mix(liquidColor.rgb, glassColor.rgb, glassColor.a);
    // chromatic path:  mix toward luminosity-shifted tint (hue shift, brightness held)
    vec3 luminosityMix = mix(liquidColor.rgb, tinted, glassColor.a);

    return vec4(mix(directMix, luminosityMix, chromaWeight), liquidColor.a);
}


// Complete liquid glass rendering pipeline
vec4 renderLiquidGlass(vec2 screenUV, vec2 p, vec2 uSize, float sd, float thickness, float refractiveIndex, float chromaticAberration, vec4 glassColor, vec2 lightDirection, float lightIntensity, float ambientStrength, sampler2D backgroundTexture, vec3 normal, float foregroundAlpha, float gaussianBlur, float saturation) {
    float height = getHeight(sd, thickness);
    
    // Calculate refraction & chromatic aberration
    vec2 refractionDisplacement;
    vec4 refractColor = calculateRefraction(screenUV, normal, height, thickness, refractiveIndex, chromaticAberration, uSize, backgroundTexture, refractionDisplacement);
    
    // Get background color for lighting calculations
    vec3 backgroundColor = refractColor.rgb;
    
    // Calculate lighting effects using background color
    vec3 lighting = calculateLighting(screenUV, normal, sd, thickness, height, lightDirection, lightIntensity, ambientStrength, backgroundColor);
    
    // Apply glass color tint (auto blend — the historical behavior; the live
    // pipeline in liquid_glass_final_render.frag passes the configured mode).
    vec4 finalColor = applyGlassColor(refractColor, glassColor, 0.0);

    // Saturation before lighting — specular highlights should remain white/neutral,
    // not be pushed towards the desaturated midpoint. Matches liquid_glass_final_render.frag.
    finalColor.rgb = applySaturation(finalColor.rgb, saturation);

    // Add lighting after saturation
    finalColor.rgb += lighting;
    
    // Use alpha for smooth transition at boundaries
    // Only sample background texture when we need to blend
    vec4 bgSample = texture(backgroundTexture, screenUV);
    return mix(bgSample, finalColor, foregroundAlpha);
}

// Debug function to visualize normals as colors
vec4 debugNormals(vec4 originalColor, vec3 normal, bool enableDebug) {
    if (enableDebug) {
        // Convert normal from [-1,1] to [0,1] range for color visualization
        vec3 normalColor = (normal + 1.0) * 0.5;
        // Mix with 99% normal visibility
        return mix(originalColor, vec4(normalColor, 1.0), 0.99);
    }
    return originalColor;
}
