// SPDX-License-Identifier: MIT
//
// Content warp of the lifted iOS 26/27 tab-bar lens (IndicatorLensOptics).
//
// Applied with ImageFilter.shader to the selected-colour copy of the tab
// items, so it bends only that copy, as UIKit's
// `_UILiquidLensView.ClearGlassView.liftedContentWarpWrapper` does: a
// displacement map built from the lens SDF (CASDFGlassDisplacementEffect,
// height 11.2) and applied with inputAmount -17.5, over content clipped to
// the lens.
//
// A sample d points in from the rim reads the content at
//   p + n * displacement * (1 - sqrt(1 - t^2)),  t = clamp(1 - d / bevel, 0, 1)
// where n is the outward rim normal bent toward the normal of the inscribed
// ellipse by the ovalization (CASDFElementLayer.gradientOvalization). With a
// negative displacement the rim band reads from beyond the bevel, a mirrored
// and compressed copy of what lies further in.
//
// The glass above it (glassForeground) then splits red and blue across the
// outer band of that warped image: by amount * (1 - d / band) along the
// position's normalised (y, x), spread through the spectrum.
//
// The field lives in the lens' own space and follows its jelly transform;
// the content does not, so the lens is mapped back through the inverse of
// that transform. The shader also masks to the lens, since it needs the
// whole texture (a clip around the filter would crop its input).

#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Slots 0-1: uSize — size of the filtered texture in physical pixels. Set by
// the engine.
uniform vec2 uSize;
// Slots 2-3: uLogicalSize — the logical size that texture covers.
uniform vec2 uLogicalSize;
// Slots 4-7: uLens — lens centre (xy) and half size (zw) before the jelly
// transform, logical pixels.
uniform vec4 uLens;
// Slots 8-11: uWarp — x: corner radius, y: displacement at the rim
// (negative = inward), z: bevel width, w: ovalization [0, 1].
uniform vec4 uWarp;
// Slots 12-13: uAberration — x: red/blue split at the rim, y: band width.
uniform vec2 uAberration;
// Slots 14-17: uJelly — the jelly transform's linear part, column-major
// (m00, m10, m01, m11). Slots 18-19: uJellyT — its translation.
uniform vec4 uJelly;
uniform vec2 uJellyT;
// Slots 20-22: uBackdrop — the colour the lens shows behind the content.
// The glass splits the channels of the composite, so a dark glyph over a
// light lens fringes blue and orange; splitting the content alone, over
// nothing, would leave it grey.
uniform vec3 uBackdrop;

uniform sampler2D uTexture;

out vec4 fragColor;

// Pure signed distance to the lens in its own space (negative inside),
// skipping rim/ellipse normal math for source-mask checks.
float lensSd(vec2 local) {
    vec2 p = local - uLens.xy;
    vec2 halfSize = max(uLens.zw, vec2(0.5));
    float radius = min(uWarp.x, min(halfSize.x, halfSize.y));
    vec2 q = abs(p) - halfSize + vec2(radius);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

// Signed distance to the lens in its own space (negative inside), and the
// warp direction there: the outward rim normal bent toward the inscribed
// ellipse's normal.
float lensDistance(vec2 local, out vec2 normal) {
    vec2 p = local - uLens.xy;
    vec2 halfSize = max(uLens.zw, vec2(0.5));
    float radius = min(uWarp.x, min(halfSize.x, halfSize.y));
    vec2 q = abs(p) - halfSize + vec2(radius);
    float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    vec2 s = vec2(p.x >= 0.0 ? 1.0 : -1.0, p.y >= 0.0 ? 1.0 : -1.0);
    vec2 rimNormal;
    if (q.x > 0.0 && q.y > 0.0) {
        rimNormal = normalize(q) * s;
    } else if (q.x > q.y) {
        rimNormal = vec2(s.x, 0.0);
    } else {
        rimNormal = vec2(0.0, s.y);
    }
    vec2 ellipseNormal = p / (halfSize * halfSize);
    float ellipseLength = length(ellipseNormal);
    ellipseNormal = ellipseLength > 1e-6 ? ellipseNormal / ellipseLength : rimNormal;
    vec2 n = mix(rimNormal, ellipseNormal, uWarp.w);
    float nLength = length(n);
    normal = nLength > 1e-6 ? n / nLength : rimNormal;
    return sd;
}

// Samples a warped lens-space point at its pre-projected texture UV, masked
// cleanly to the lens interior using the branchless distance-only SDF.
vec4 sampleLensUV(vec2 source, vec2 uv, float aaScale) {
    float sourceMask = clamp(0.5 - lensSd(source) * aaScale, 0.0, 1.0);
    if (sourceMask <= 0.0) {
        return vec4(0.0);
    }
    return texture(uTexture, clamp(uv, vec2(0.0), vec2(1.0))) * sourceMask;
}

void main() {
    vec2 invSize = 1.0 / max(uSize, vec2(1.0));
    vec2 scale = uSize / max(uLogicalSize, vec2(1.0));
    vec2 uvScale = scale * invSize;
    float pxPerPoint = 0.5 * (scale.x + scale.y);
    vec2 point = FlutterFragCoord().xy / scale;

    mat2 jelly = mat2(uJelly.x, uJelly.y, uJelly.z, uJelly.w);
    float det = jelly[0][0] * jelly[1][1] - jelly[1][0] * jelly[0][1];
    det = abs(det) < 1e-6 ? 1e-6 : det;
    mat2 inverseJelly = mat2(jelly[1][1], -jelly[0][1], -jelly[1][0], jelly[0][0]) / det;
    float jellyScale = min(length(jelly[0]), length(jelly[1]));
    float aaScale = jellyScale * pxPerPoint;

    vec2 local = inverseJelly * (point - uJellyT);
    vec2 normal;
    float sd = lensDistance(local, normal);
    float coverage = clamp(0.5 - sd * aaScale, 0.0, 1.0);
    if (coverage <= 0.0) {
        fragColor = vec4(0.0);
    } else {
        float d = max(-sd, 0.0);
        // Preserve the outer glass hairline and glossy specular rim highlight
        // painted by the lens layer beneath: gently reveal warped content
        // inside the outer bezel as the lens lifts (scaled to 0 as lift -> 0
        // so there is no pop when the filter activates). This also prevents
        // the infinite-slope d -> 0 singularity from crushing glyphs into
        // razor-thin lines directly on top of the outer hairline.
        float liftFactor = clamp(abs(uWarp.y) / 4.0, 0.0, 1.0);
        float rimReveal = mix(1.0, smoothstep(0.65, 2.0, d), liftFactor);
        coverage *= rimReveal;
        if (coverage <= 0.0) {
            fragColor = vec4(0.0);
        } else {
            // Soften the infinite radial slope at t -> 1 (d -> 0) by easing the
            // circular dome with a small regulariser, matching the rasterised
            // SDF height map of UIKit's CASDFGlassDisplacementEffect.
            float t = clamp(1.0 - d / max(uWarp.z, 1e-3), 0.0, 1.0);
            float profile = (1.0198039 - sqrt(1.04 - t * t)) / 0.8198039;
            vec2 source = local + normal * (uWarp.y * profile);
            vec2 baseUV = (jelly * source + uJellyT) * uvScale;
            vec4 center = sampleLensUV(source, baseUV, aaScale);
            vec4 color = center;

            float amount = uAberration.x
                         * clamp(1.0 - d / max(uAberration.y, 1e-3), 0.0, 1.0);
            if (amount > 0.001) {
                vec2 rel = (local - uLens.xy) / max(uLens.zw, vec2(0.5));
                vec2 dir = vec2(rel.y, rel.x);
                float dirLength = length(dir);
                dir = dirLength > 1e-4 ? dir / dirLength : vec2(0.0);
                // Five overlapping spectral taps applied in warped source space
                // keep adjacent taps ~1.1 pt apart (finer than a glyph stroke)
                // so fringes blend continuously without discrete zebra stripes.
                // Hoist the linear jelly UV step out of the loop and reuse the
                // centre tap (i == 2, t == 0): 5 texture fetches total (down
                // from 6) and 0 per-tap matrix multiplies or divisions.
                vec2 sourceStep = dir * (amount * 0.85);
                vec2 uvStep = (jelly * sourceStep) * uvScale;
                vec3 premultiplied = vec3(0.0);
                vec3 coverage3 = vec3(0.0);
                for (int i = 0; i < 5; i++) {
                    float st = float(i) * 0.5 - 1.0;
                    vec3 w = max(vec3(0.0),
                                 vec3(1.0) - abs(vec3(st) - vec3(1.0, 0.0, -1.0)) / 1.2);
                    vec4 tap = (i == 2)
                        ? center
                        : sampleLensUV(
                            source + sourceStep * st,
                            baseUV + uvStep * st,
                            aaScale
                        );
                    premultiplied += tap.rgb * w;
                    coverage3 += vec3(tap.a) * w;
                }
                // Exact inverse weight sums for t in {-1, -0.5, 0, 0.5, 1} / 1.2:
                // R = 21/12 (1.75), G = 30/12 (2.50), B = 21/12 (1.75).
                const vec3 invWeights = vec3(0.57142857, 0.4, 0.57142857);
                premultiplied *= invWeights;
                coverage3 *= invWeights;
                // On light pills (bright uBackdrop), composite missing channels
                // over the backdrop so dark glyphs fringe cyan/orange instead
                // of grey. On dark pills (low-luma uBackdrop), keep separated
                // channels translucent over the live glass beneath instead of
                // painting opaque dark grey over colourful dark-mode backdrops.
                float backdropLuma = dot(uBackdrop, vec3(0.2126, 0.7152, 0.0722));
                float backdropFill = smoothstep(0.25, 0.65, backdropLuma);
                float maxCov = max(coverage3.r, max(coverage3.g, coverage3.b));
                float meanCov = (coverage3.r + coverage3.g + coverage3.b) * (1.0 / 3.0);
                float alpha = mix(meanCov, maxCov, backdropFill);
                vec3 fill = (vec3(maxCov) - coverage3) * (uBackdrop * backdropFill);
                color = vec4(min(premultiplied + fill, vec3(1.0)), alpha);
            }
            fragColor = color * coverage;
        }
    }
}
