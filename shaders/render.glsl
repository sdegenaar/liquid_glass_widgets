// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Shared rendering functions for liquid glass shaders

// Constants
const vec3 LUMA_WEIGHTS = vec3(0.299, 0.587, 0.114);

// Utility functions
mat2 rotate2d(float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

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

// Calculate height/depth of the liquid surface
float getHeight(float sd, float thickness) {
    if (sd >= 0.0 || thickness <= 0.0) {
        return 0.0;
    }
    if (sd < -thickness) {
        return thickness;
    }
    
    float x = thickness + sd;
    return sqrt(max(0.0, thickness * thickness - x * x));
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

    // If we're outside the shape, no lighting.
    if (shape < 0.01) {
        return vec3(0.0);
    }

    // Smoothly fade in the entire lighting effect based on thickness
    float thicknessFactor = clamp((thickness - 5.0) * 0.5, 0.0, 1.0);
    if (thicknessFactor < 0.01) {
        return vec3(0.0);
    }

    // --- Rim lighting ---
    // Fast rational approximation: 1/(1+k*x^2)
    float rimWidth = 1.5;
    float k = 0.89;
    float x = sd / rimWidth;
    float rimFactor = 1.0 / (1.0 + k * x * x);

    // Early reject for minimal lighting effects to save expensive highlight calculations
    if (rimFactor < 0.01 || lightIntensity < 0.01) {
        return vec3(0.0);
    }

    // Use pre-computed light direction
    vec2 normalXY = normal.xy;
    float mainLightInfluence = max(0.0, dot(normalXY, lightDirection));

    // Add a secondary, weaker light from the opposite direction.
    float oppositeLightInfluence = max(0.0, dot(normalXY, -lightDirection));

    // Increase strength of opposite light
    float totalInfluence = mainLightInfluence + oppositeLightInfluence * 0.8;

    // Compute highlight color once at max brightness, then scale for different uses
    vec3 highlightColor = getHighlightColor(backgroundColor, 1.0);

    // Directional component with 0.7 brightness factor
    vec3 directionalRim = (highlightColor * 0.7) * (totalInfluence * totalInfluence) * lightIntensity * 2.0;

    // Ambient component with 0.4 brightness factor
    vec3 ambientRim = (highlightColor * 0.4) * ambientStrength;

    // Combine directional and ambient rim light, and apply rim falloff
    vec3 totalRimLight = (directionalRim + ambientRim) * rimFactor;

    // Apply shape mask like the original version
    return totalRimLight * thicknessFactor * shape;
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

// Apply glass color tinting to the liquid color
vec4 applyGlassColor(vec4 liquidColor, vec4 glassColor) {
    vec4 finalColor = liquidColor;
    
    if (glassColor.a > 0.0) {
        float glassLuminance = dot(glassColor.rgb, LUMA_WEIGHTS);
        
        if (glassLuminance < 0.5) {
            vec3 darkened = liquidColor.rgb * (glassColor.rgb * 2.0);
            finalColor.rgb = mix(liquidColor.rgb, darkened, glassColor.a);
        } else {
            vec3 invLiquid = vec3(1.0) - liquidColor.rgb;
            vec3 invGlass = vec3(1.0) - glassColor.rgb;
            vec3 screened = vec3(1.0) - (invLiquid * invGlass);
            finalColor.rgb = mix(liquidColor.rgb, screened, glassColor.a);
        }
        
        finalColor.a = liquidColor.a;
    }
    
    return finalColor;
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
    
    // Apply realistic glass color influence
    vec4 finalColor = applyGlassColor(refractColor, glassColor);
    
    // Add lighting effects to final color
    finalColor.rgb += lighting;
    
    // Apply saturation adjustment to the final color after tinting
    finalColor.rgb = applySaturation(finalColor.rgb, saturation);
    
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
