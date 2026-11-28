// Copyright 2025, Tim Lehmann for whynotmake.it
// Copyright 2026, Sebastian Degenaar for pixel-innovations.com (liquid_glass_widgets)
//
// SPDX-License-Identifier: MIT
//
// Originally: SDF primitives (sdfRRect, sdfRect, sdfSquircle) and smoothUnion;
//             MAX_SHAPES=64, dynamic array indexing, for-loop scene composition.
// Modifications (2026):
//   - Added sdfEllipse(), sdfPolygon(), and sdfStar() primitives.
//   - Rewrote scene composition to fully unrolled sdf0()…sdf15() helpers with
//     literal-only indexing for Windows/SkSL SPIR-V compatibility.
//   - Replaced for-loop sceneSDF with symmetric bidirectional blend (fwd+bwd).
//   - Reduced MAX_SHAPES from 64 to 16 to fit Impeller's uniform buffer limit.
//   - Extended shape slot from 6 to 7 floats (added shape-type discriminant).
//
// SDF primitives and scene composition for liquid glass geometry shaders.
//
// ── Windows / SkSL compatibility ─────────────────────────────────────────────
// SkSL (Skia's shader language, used on Windows) compiles GLSL to SPIR-V via
// glslang.  glslang enforces the GLSL ES 1.0 rule that array indices MUST be
// constant-integral-expressions.  Computing `index * 6 + offset` at runtime
// and using the result to index uShapeData[] fails with:
//   error: index expression must be constant
//
// Fix: every uShapeData[] access uses a literal integer index only.
// getShapeSDFFromArray() is gone; sdf0()…sdf15() helpers expand each
// shape slot with hardcoded literal offsets so glslang sees only constants.
// sceneSDF is fully unrolled — no for-loops, no dynamic indexing.
//
// ── Backward pass correctness ─────────────────────────────────────────────────
// The symmetric bidirectional blend is a left-fold in both directions:
//   fwd(n) = leftFold(smoothUnion, [s0, s1, …, s_{n-1}], k)
//   bwd(n) = leftFold(smoothUnion, [s_{n-1}, s_{n-2}, …, s0], k)
// result  = mix(fwd, bwd, 0.5)
//
// The backward pass for each n is computed with named intermediate variables
// rather than deeply-nested call expressions, so the GLSL parser never sees
// expression depth > 3 regardless of n.  This avoids the "exceeded max parse
// depth" error that the user-attempted loop-expansion triggered.
//
// ── Shape slots ──────────────────────────────────────────────────────────────
// Each shape occupies 7 consecutive floats in uShapeData[]:
//   [base+0] type             1=squircle/superellipse  2=ellipse  3=roundrect
//   [base+1] center.x
//   [base+2] center.y
//   [base+3] size.x
//   [base+4] size.y
//   [base+5] cornerRadius     (top corners; or symmetric)
//   [base+6] bottomCornerRadius (bottom corners; equals [base+5] for symmetric)

#include "gles_compat.glsl"

#ifndef MAX_SHAPES
#define MAX_SHAPES 16
#endif

// ── SDF primitives ────────────────────────────────────────────────────────────

float sdfRRect(in vec2 p, in vec2 b, in float r) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Asymmetric rounded-rect SDF: independent top/bottom corner radii.
//
// Computes two `sdfRRect` evaluations (one with rTop applied to all corners,
// one with rBottom) and `mix`es them along p.y with a smooth `smoothstep`
// across the horizontal centerline. This keeps the SDF — and therefore its
// gradient — continuous across the centerline, which matters for the
// geometry-blended pipeline that derives surface normals from dFdx/dFdy of
// the SDF: a per-quadrant `r = p.y < 0 ? rTop : rBottom` lookup would emit
// garbage normals along the centerline. 2-pixel half-width matches the
// typical anti-aliasing band on Skia/Impeller.
//
// Outside the corner regions both inner SDFs agree (the radius doesn't enter
// the distance formula along the straight edges), so the blend is a no-op
// there and only the corner regions actually differ. When rTop == rBottom,
// dT == dB and `mix` returns either value unchanged — symmetric shapes are
// bit-exact identical to a plain `sdfRRect(p, b, r)` call.
float sdfRRectAsym(in vec2 p, in vec2 b, in float rTop, in float rBottom) {
    if (rTop == rBottom) return sdfRRect(p, b, rTop);
    float dT = sdfRRect(p, b, rTop);
    float dB = sdfRRect(p, b, rBottom);
    float t = smoothstep(-2.0, 2.0, p.y);
    return mix(dT, dB, t);
}

float sdfRect(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// ── Analytic Squircle SDF (Ln-Norm) ─────────────────────────────────────────
// Matches Flutter's native RoundedSuperellipseBorder (ClipRSuperellipse).
// Uses a pure Lamé curve (|x|^n + |y|^n = 1) instead of a piecewise seam.
// This completely eliminates the 45-degree seam blending artifacts.

float fastPow(float x, float n) { 
    return exp2(n * log2(max(x, 1e-4))); 
}

float squircleShape(vec2 p, vec2 b, float zone, float n) {
    vec2 q = abs(p) - b + zone;
    vec2 m = max(q, 0.0);
    float M = max(m.x, m.y);
    float corner = 0.0;
    if (M > 1e-4) {
        vec2 mNorm = m / M;
        corner = M * fastPow(fastPow(mNorm.x, n) + fastPow(mNorm.y, n), 1.0 / n);
    }
    return min(max(q.x, q.y), 0.0) + corner - zone;
}

// sdfSquircle: analytic squircle SDF with graceful degradation.
//
// CRITICAL: n (the Lamé exponent) is derived from the CLAMPED zone, not the
// raw r*1.528 zone. This ensures the SDF's lighting and gradient match
// Flutter's RoundedSuperellipseBorder path exactly:
//
//   Normal squircle  → zone = r*1.528 (unclamped) → n ≈ 3.26
//   Partial clamp    → zone < r*1.528              → n smoothly decreases
//   Full pill clamp  → zone = r (r ≥ half-height)  → n = 2.0 (pure circle)
//
// Without this, the shader draws a squarish SDF (n≈3.26) inside a clip that
// Flutter already forced to a circle (n=2), causing the lighting/glow to
// appear misaligned from the visual edge on pill-shaped squircles.
float sdfSquircle(in vec2 p, in vec2 b, in float r) {
    float boxShort = min(b.x, b.y);
    r    = min(r, boxShort);
    float zone = min(r * 1.528, boxShort);
    float base = 1.0 - 0.29289322 * (r / max(zone, 1e-4));
    float n    = -1.0 / log2(clamp(base, 0.5, 0.9999));
    return squircleShape(p, b, zone, n);
}

float sdfSquircleAsym(in vec2 p, in vec2 b, in float rTop, in float rBottom) {
    // Most shapes round all four corners alike, and then both halves below
    // are the same squircle: evaluate it once.
    if (rTop == rBottom) {
        return sdfSquircle(p, b, rTop);
    }
    float boxShort = min(b.x, b.y);
    rTop    = min(rTop,    boxShort);
    rBottom = min(rBottom, boxShort);

    float zoneT = min(rTop    * 1.528, boxShort);
    float baseT = 1.0 - 0.29289322 * (rTop    / max(zoneT, 1e-4));
    float nT    = -1.0 / log2(clamp(baseT, 0.5, 0.9999));
    float dT    = squircleShape(p, b, zoneT, nT);

    float zoneB = min(rBottom * 1.528, boxShort);
    float baseB = 1.0 - 0.29289322 * (rBottom / max(zoneB, 1e-4));
    float nB    = -1.0 / log2(clamp(baseB, 0.5, 0.9999));
    float dB    = squircleShape(p, b, zoneB, nB);

    float t = smoothstep(-2.0, 2.0, p.y);
    return mix(dT, dB, t);
}

float sdfEllipse(vec2 p, vec2 r) {
    r = max(r, 1e-4);
    vec2 invR   = 1.0 / r;
    vec2 invR2  = invR * invR;
    vec2 pInvR  = p * invR;
    float k1    = length(pInvR);
    vec2  pInvR2 = p * invR2;
    float k2    = length(pInvR2);
    return (k1 * (k1 - 1.0)) / max(k2, 1e-4);
}

// Branchless smooth-union.
// When k=0: e=0, result = min(d1,d2) — identical to the branching form.
float smoothUnion(float d1, float d2, float k) {
    float e = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - e * e * 0.25 / max(k, 1e-5);
}

// ── Shape distance + unit outward normal helpers ──────────────────────────────
// Returns vec3(signedDistance, normal.x, normal.y) for O(N) 2-nearest
// normal-weighted metaball smooth-union (CoreAnimation CASDFLayer law:
// k_eff = k * 0.5 * (1 - dot(n1, n2))). Facing edges (dot = -1) merge at
// full strength k; aligned parallel edges (dot = +1) keep zero bulge.

vec2 _safeSign(vec2 p) {
    return vec2(p.x < 0.0 ? -1.0 : 1.0, p.y < 0.0 ? -1.0 : 1.0);
}

vec3 sdfRRectGrad(in vec2 p, in vec2 b, in float r) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);
    vec2 q = abs(p) - b + r;
    vec2 m = max(q, 0.0);
    float mLen = length(m);
    float d = min(max(q.x, q.y), 0.0) + mLen - r;
    vec2 gLocal = (mLen > 1e-4)
        ? (m / mLen)
        : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
    return vec3(d, _safeSign(p) * gLocal);
}

vec3 sdfRRectAsymGrad(in vec2 p, in vec2 b, in float rTop, in float rBottom) {
    if (rTop == rBottom) return sdfRRectGrad(p, b, rTop);
    vec3 gT = sdfRRectGrad(p, b, rTop);
    vec3 gB = sdfRRectGrad(p, b, rBottom);
    float t = smoothstep(-2.0, 2.0, p.y);
    vec2 g = mix(gT.yz, gB.yz, t);
    float gLen = length(g);
    return vec3(mix(gT.x, gB.x, t), gLen > 1e-4 ? g / gLen : gT.yz);
}

vec3 sdfSquircleGrad(in vec2 p, in vec2 b, in float r) {
    float boxShort = min(b.x, b.y);
    r = min(r, boxShort);
    float zone = min(r * 1.528, boxShort);
    float base = 1.0 - 0.29289322 * (r / max(zone, 1e-4));
    float n = -1.0 / log2(clamp(base, 0.5, 0.9999));
    vec2 q = abs(p) - b + zone;
    vec2 m = max(q, 0.0);
    float M = max(m.x, m.y);
    float corner = 0.0;
    vec2 gLocal;
    if (M > 1e-4) {
        vec2 mNorm = m / M;
        float mx = fastPow(mNorm.x, n);
        float my = fastPow(mNorm.y, n);
        corner = M * fastPow(mx + my, 1.0 / n);
        vec2 dg = vec2(
            mNorm.x > 1e-4 ? fastPow(mNorm.x, n - 1.0) : 0.0,
            mNorm.y > 1e-4 ? fastPow(mNorm.y, n - 1.0) : 0.0);
        float dgLen = length(dg);
        gLocal = dgLen > 1e-4 ? (dg / dgLen) : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
    } else {
        gLocal = q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    }
    float d = min(max(q.x, q.y), 0.0) + corner - zone;
    return vec3(d, _safeSign(p) * gLocal);
}

vec3 sdfSquircleAsymGrad(in vec2 p, in vec2 b, in float rTop, in float rBottom) {
    if (rTop == rBottom) return sdfSquircleGrad(p, b, rTop);
    vec3 gT = sdfSquircleGrad(p, b, rTop);
    vec3 gB = sdfSquircleGrad(p, b, rBottom);
    float t = smoothstep(-2.0, 2.0, p.y);
    vec2 g = mix(gT.yz, gB.yz, t);
    float gLen = length(g);
    return vec3(mix(gT.x, gB.x, t), gLen > 1e-4 ? g / gLen : gT.yz);
}

vec3 sdfEllipseGrad(vec2 p, vec2 r) {
    r = max(r, 1e-4);
    vec2 invR   = 1.0 / r;
    vec2 invR2  = invR * invR;
    vec2 pInvR  = p * invR;
    float k1    = length(pInvR);
    vec2 pInvR2 = p * invR2;
    float k2    = length(pInvR2);
    float d = (k1 * (k1 - 1.0)) / max(k2, 1e-4);
    vec2 g = k2 > 1e-4 ? (pInvR2 / k2) : vec2(0.0, 1.0);
    return vec3(d, g);
}

// CoreAnimation CASDFElementLayer refraction normal for a single native
// frosted platter: evaluates the outward normal on a rounder 5/3 * r box so
// refraction turns smoothly before straight edges meet corners, and blends
// 50% ellipse gradient (gradientOvalization = 0.5) on large platters
// (shortestSide >= 66 pt, ramped smoothly across 64..72 pt).
vec2 nativePlatterNormal(
    vec2 p,
    vec2 center,
    vec2 size,
    float rTop,
    float rBottom,
    float dpr
) {
    vec2 pLocal = p - center;
    vec2 b = max(size * 0.5, vec2(1e-4));
    float boxShort = min(b.x, b.y);
    float rTopG = min(rTop * (5.0 / 3.0), boxShort);
    float rBotG = min(rBottom * (5.0 / 3.0), boxShort);
    vec2 roundN = sdfRRectAsymGrad(pLocal, b, rTopG, rBotG).yz;
    float shortSidePt = (2.0 * boxShort) / max(dpr, 1.0);
    float ovalWeight = 0.5 * smoothstep(64.0, 72.0, shortSidePt);
    if (ovalWeight > 1e-4) {
        vec2 ellipseN = sdfEllipseGrad(pLocal, b).yz;
        vec2 blended = mix(roundN, ellipseN, ovalWeight);
        float bLen = length(blended);
        return bLen > 1e-4 ? (blended / bLen) : roundN;
    }
    return roundN;
}

// ── Per-type dispatch ─────────────────────────────────────────────────────────

// rTop / rBottom collapse to a single radius for symmetric shapes (caller
// writes rBottom == rTop), so this dispatch is back-compat: routing through
// `sdfRRectAsym` with equal radii is bit-identical to `sdfRRect`.
float getShapeSDF(float type, vec2 p, vec2 center, vec2 size, float rTop, float rBottom) {
    if      (type == 1.0) return sdfSquircleAsym(p - center, size / 2.0, rTop, rBottom);
    else if (type == 2.0) return sdfEllipse  (p - center, size / 2.0);
    else if (type == 3.0) return sdfRRectAsym(p - center, size / 2.0, rTop, rBottom);
    return 0.0;
}

vec3 getShapeSDFGrad(float type, vec2 p, vec2 center, vec2 size, float rTop, float rBottom) {
    if      (type == 1.0) return sdfSquircleAsymGrad(p - center, size / 2.0, rTop, rBottom);
    else if (type == 2.0) return sdfEllipseGrad     (p - center, size / 2.0);
    else if (type == 3.0) return sdfRRectAsymGrad   (p - center, size / 2.0, rTop, rBottom);
    return vec3(1e9, 0.0, 1.0);
}

// ── Constant-index shape accessors ───────────────────────────────────────────
// Macro reads uShapeData[] with *literal* offsets only — satisfies the GLSL ES
// / SkSL / glslang requirement that array indices be constant expressions.
// uShapeData[] is declared by the including shader before #include "sdf.glsl".
//
// Stride: 7 floats per shape (was 6). Slot +6 is the bottom corner radius;
// see the layout comment near the top of this file.

#define SDF_SHAPE_N(BASE) \
    getShapeSDF(uShapeData[BASE], p, \
                vec2(uShapeData[BASE+1], uShapeData[BASE+2]), \
                vec2(uShapeData[BASE+3], uShapeData[BASE+4]), \
                uShapeData[BASE+5], \
                uShapeData[BASE+6])

#define SDF_GRAD_N(BASE) \
    getShapeSDFGrad(uShapeData[BASE], p, \
                    vec2(uShapeData[BASE+1], uShapeData[BASE+2]), \
                    vec2(uShapeData[BASE+3], uShapeData[BASE+4]), \
                    uShapeData[BASE+5], \
                    uShapeData[BASE+6])

float sdf0(vec2 p)  { return SDF_SHAPE_N(0);   }

vec3 sdfGrad0(vec2 p)  { return SDF_GRAD_N(0);   }
vec3 sdfGrad1(vec2 p)  { return SDF_GRAD_N(7);   }
vec3 sdfGrad2(vec2 p)  { return SDF_GRAD_N(14);  }
vec3 sdfGrad3(vec2 p)  { return SDF_GRAD_N(21);  }
vec3 sdfGrad4(vec2 p)  { return SDF_GRAD_N(28);  }
vec3 sdfGrad5(vec2 p)  { return SDF_GRAD_N(35);  }
vec3 sdfGrad6(vec2 p)  { return SDF_GRAD_N(42);  }
vec3 sdfGrad7(vec2 p)  { return SDF_GRAD_N(49);  }
#ifndef LGR_OPENGLES_CAP_SHAPES
vec3 sdfGrad8(vec2 p)  { return SDF_GRAD_N(56);  }
vec3 sdfGrad9(vec2 p)  { return SDF_GRAD_N(63);  }
vec3 sdfGrad10(vec2 p) { return SDF_GRAD_N(70);  }
vec3 sdfGrad11(vec2 p) { return SDF_GRAD_N(77);  }
vec3 sdfGrad12(vec2 p) { return SDF_GRAD_N(84);  }
vec3 sdfGrad13(vec2 p) { return SDF_GRAD_N(91);  }
vec3 sdfGrad14(vec2 p) { return SDF_GRAD_N(98);  }
vec3 sdfGrad15(vec2 p) { return SDF_GRAD_N(105); }
#endif

// ── sceneSDF — O(N) 2-nearest normal-weighted union, fully unrolled ──────────
//
// Tracks the two closest shapes (near1, near2) with their analytical unit
// outward normals in a single literal-indexed O(N) pass (16 shapes on
// Metal/Vulkan, 8 on OpenGL ES / ANGLE) and blends them via CoreAnimation's
// normal-weighted smooth union:
//   k_eff = k * clamp(0.5 * (1.0 - dot(near1.yz, near2.yz)), 0.0, 1.0)
//
// Properties:
//   • Order-independent (perfectly symmetric regardless of shape order).
//   • O(N) cost and compact AST (no O(N^2) pair loops, no dynamic indexing).
//   • Facing edges (dot = -1) merge at full strength k; aligned parallel
//     edges (dot = +1) keep k_eff = 0 with zero edge bulging.

#define TRACK_NEAR2(S) \
    if ((S).x < near1.x) { near2 = near1; near1 = (S); } \
    else if ((S).x < near2.x) { near2 = (S); }

float sceneSDF(vec2 p, int n, float k) {
    if (n <= 0) return 1e9;
    if (n == 1) return sdf0(p);

    vec3 near1 = sdfGrad0(p);
    vec3 near2 = vec3(1e9, 0.0, 1.0);

    vec3 s1 = sdfGrad1(p);
    TRACK_NEAR2(s1);
    if (n > 2) { vec3 s2 = sdfGrad2(p); TRACK_NEAR2(s2); }
    if (n > 3) { vec3 s3 = sdfGrad3(p); TRACK_NEAR2(s3); }
    if (n > 4) { vec3 s4 = sdfGrad4(p); TRACK_NEAR2(s4); }
    if (n > 5) { vec3 s5 = sdfGrad5(p); TRACK_NEAR2(s5); }
    if (n > 6) { vec3 s6 = sdfGrad6(p); TRACK_NEAR2(s6); }
    if (n > 7) { vec3 s7 = sdfGrad7(p); TRACK_NEAR2(s7); }
#ifndef LGR_OPENGLES_CAP_SHAPES
    if (n > 8)  { vec3 s8  = sdfGrad8(p);  TRACK_NEAR2(s8);  }
    if (n > 9)  { vec3 s9  = sdfGrad9(p);  TRACK_NEAR2(s9);  }
    if (n > 10) { vec3 s10 = sdfGrad10(p); TRACK_NEAR2(s10); }
    if (n > 11) { vec3 s11 = sdfGrad11(p); TRACK_NEAR2(s11); }
    if (n > 12) { vec3 s12 = sdfGrad12(p); TRACK_NEAR2(s12); }
    if (n > 13) { vec3 s13 = sdfGrad13(p); TRACK_NEAR2(s13); }
    if (n > 14) { vec3 s14 = sdfGrad14(p); TRACK_NEAR2(s14); }
    if (n > 15) { vec3 s15 = sdfGrad15(p); TRACK_NEAR2(s15); }
#endif

    if (k <= 0.0) return near1.x;
    float normalWeight = clamp(0.5 * (1.0 - dot(near1.yz, near2.yz)), 0.0, 1.0);
    // Smoothly revert to isotropic k when shapes overlap deeply so interior
    // medial-axis normal flips never introduce creases in finite-difference normals.
    float exteriorGate = smoothstep(-k, 0.0, max(near1.x, near2.x));
    float effectiveWeight = mix(1.0, normalWeight, exteriorGate);
    return smoothUnion(near1.x, near2.x, k * effectiveWeight);
}
