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

// The warped content at a point of the lens' own space: read from further
// in near the rim, and empty where that lands outside the lens.
vec4 warpedContent(vec2 local, mat2 jelly, vec2 scale) {
    vec2 normal;
    float d = max(-lensDistance(local, normal), 0.0);
    float t = clamp(1.0 - d / max(uWarp.z, 1e-3), 0.0, 1.0);
    float profile = 1.0 - sqrt(max(0.0, 1.0 - t * t));
    vec2 source = local + normal * (uWarp.y * profile);
    vec2 unused;
    float inside = step(lensDistance(source, unused), 0.0);
    vec2 point = jelly * source + uJellyT;
    vec2 uv = clamp(point * scale / uSize, vec2(0.0), vec2(1.0));
    return texture(uTexture, uv) * inside;
}

void main() {
    vec2 scale = uSize / max(uLogicalSize, vec2(1.0));
    float pxPerPoint = 0.5 * (scale.x + scale.y);
    vec2 point = FlutterFragCoord().xy / scale;

    mat2 jelly = mat2(uJelly.x, uJelly.y, uJelly.z, uJelly.w);
    float det = jelly[0][0] * jelly[1][1] - jelly[1][0] * jelly[0][1];
    det = abs(det) < 1e-6 ? 1e-6 : det;
    mat2 inverseJelly = mat2(jelly[1][1], -jelly[0][1], -jelly[1][0], jelly[0][0]) / det;
    float jellyScale = min(length(jelly[0]), length(jelly[1]));

    vec2 local = inverseJelly * (point - uJellyT);
    vec2 normal;
    float sd = lensDistance(local, normal);
    float coverage = clamp(0.5 - sd * jellyScale * pxPerPoint, 0.0, 1.0);
    if (coverage <= 0.0) {
        fragColor = vec4(0.0);
    } else {
        vec4 color = warpedContent(local, jelly, scale);
        float amount = uAberration.x
                     * clamp(1.0 + sd / max(uAberration.y, 1e-3), 0.0, 1.0);
        if (amount > 0.001) {
            vec2 rel = (local - uLens.xy) / max(uLens.zw, vec2(0.5));
            vec2 dir = vec2(rel.y, rel.x);
            float dirLength = length(dir);
            dir = dirLength > 1e-4 ? dir / dirLength : vec2(0.0);
            // Five taps across the split, weighted toward red on one side and
            // blue on the other, blend the fringe through the spectrum.
            // 1.355 puts the red and blue centroids at +-amount; alpha follows
            // green.
            vec3 premultiplied = vec3(0.0);
            vec3 coverage3 = vec3(0.0);
            vec3 weights = vec3(0.0);
            for (int i = 0; i < 5; i++) {
                float t = float(i) * 0.5 - 1.0;
                vec3 w = max(vec3(0.0),
                             vec3(1.0) - abs(vec3(t) - vec3(1.0, 0.0, -1.0)) / 1.2);
                vec4 tap = warpedContent(local + dir * (amount * 1.355 * t), jelly, scale);
                premultiplied += tap.rgb * w;
                coverage3 += vec3(tap.a) * w;
                weights += w;
            }
            premultiplied /= weights;
            coverage3 /= weights;
            // Composite each channel over the backdrop, then hand back a
            // premultiplied colour whose alpha covers the widest channel.
            float alpha = max(coverage3.r, max(coverage3.g, coverage3.b));
            color = vec4(premultiplied + (vec3(alpha) - coverage3) * uBackdrop, alpha);
        }
        fragColor = color * coverage;
    }
}
