// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Geometry precomputation shader for blended liquid glass shapes
// This shader pre-computes the surface normal and encodes it into a texture.
// Only needs to be re-run when shape geometry or layout changes.
//
// Texture layout (slots → displacement_encoding.glsl):
//   R: normal.x  [-1, 1] → [0, 1]
//   G: normal.y  [-1, 1] → [0, 1]
//   B: height    normalized to thickness
//   A: foreground alpha (SDF anti-aliasing)

#version 460 core
precision highp float; // mediump caused ~1.5px displacement banding on mobile (10-bit mantissa)

#include <flutter/runtime_effect.glsl>

// MAX_SHAPES must be defined before uShapeData so the array size is known.
// sdf.glsl uses an #ifndef guard so this definition takes precedence.
#define MAX_SHAPES 16

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform vec4 uOpticalProps;
layout(location = 2) uniform float uNumShapes;
layout(location = 3) uniform float uShapeData[MAX_SHAPES * 6];

// sdf.glsl functions access uShapeData as a global (no array-by-value parameters,
// which are rejected by glslang on Windows/Vulkan SPIR-V compilation).
#include "sdf.glsl"
#include "displacement_encoding.glsl"

float uThickness = uOpticalProps.z;
float uRefractiveIndex = uOpticalProps.x;
float uBlend = uOpticalProps.w;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    float sd = sceneSDF(fragCoord, int(uNumShapes), uBlend);

    float foregroundAlpha = 1.0 - smoothstep(-2.0, 0.0, sd);
    if (foregroundAlpha < 0.01) {
        fragColor = vec4(0.0);
        return;
    }

    // Compute the SDF gradient (true surface normal XY).
    // dFdx/dFdy give the rate of change of the SDF across neighbouring pixels,
    // which is the outward surface normal direction in screen space.
    float dx = dFdx(sd);
    float dy = dFdy(sd);

    float n_cos = max(uThickness + sd, 0.0) / uThickness;
    float n_sin = sqrt(max(0.0, 1.0 - n_cos * n_cos));

    // True surface normal from the SDF gradient — this is what we store.
    // In blend-group neck zones the displacement vector diverges from this
    // normal, which is why storing the normal (not displacement) fixes lighting.
    vec3 normal = normalize(vec3(dx * n_cos, dy * n_cos, n_sin));

    if (sd >= 0.0 || uThickness <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float x = uThickness + sd;
    float sqrtTerm = sqrt(max(0.0, uThickness * uThickness - x * x));
    float height = mix(sqrtTerm, uThickness, float(sd < -uThickness));

    // Encode normal.xy + height + alpha.
    // The render pass recomputes displacement = refract(incident, normal, 1/n)
    // so there is no information loss compared to storing displacement directly.
    fragColor = encodeGeometryData(normal.xy, height, uThickness, foregroundAlpha);
}
