// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Final rendering pass for liquid glass with pre-computed geometry.
// Reads surface normal data from the geometry texture (V1 encoding) and applies
// the liquid glass effect: refraction, chromatic aberration, tint, and edge lighting.
//
// Geometry texture layout (displacement_encoding.glsl):
//   R: normal.x  [-1, 1] → [0, 1]
//   G: normal.y  [-1, 1] → [0, 1]
//   B: height    normalized to thickness
//   A: foreground alpha (SDF AA)

#version 460 core
precision highp float; // mediump causes colour banding (10-bit mantissa on mobile)

#define DEBUG_GEOMETRY 0

#include <flutter/runtime_effect.glsl>
#include "displacement_encoding.glsl"
#include "render.glsl"

// Slot 0-1:  uSize           — physical-pixel size of the backdrop capture
// Slots 2-3: uGeometryOffset — top-left of geometry matte in physical pixels
// Slots 4-5: uGeometrySize   — size of geometry matte in physical pixels
// Slots 6-9: uGlassColor
// Slots 10-12: uOpticalProps (refractiveIndex, chromaticAberration, thickness)
// Slots 13-15: uLightConfig  (lightIntensity, ambientStrength, saturation)
// Slots 16-17: uLightDirection
// Slot 18: uWhiten
// Slot 19: uWhitenGated
// Slot 20: uTintBlend
uniform vec2 uSize;          // physical-pixel size of the backdrop capture
uniform vec2 uGeometryOffset;
uniform vec2 uGeometrySize;

uniform vec4 uGlassColor;
uniform vec3 uOpticalProps;
uniform vec3 uLightConfig;
uniform vec2 uLightDirection;

// Slot 18: uWhiten — whitening ("legibility veil") amount [0..1]. Lifts the
// glass toward white (result = mix(glass, white, uWhiten)). A single
// control-wide value (not spatially varying), so there is no spatial seam and
// therefore no halo/outline artifacts. Models iOS 26 light-mode glass, which
// places an even whitening veil over the refracted content for legibility on
// light backgrounds. 0 = pure glass (no-op); higher = whiter.
uniform float uWhiten;

// Slot 19: uWhitenGated. 1 = the whiten is luminance-gated (protects dark
// pixels — the light-mode behaviour, keeps text/icons beneath the glass dark);
// 0 = ungated, uniform whiten across the whole control (the dark-mode
// behaviour, gives dark glass a small even lift toward white).
uniform float uWhitenGated;

// Slot 20: uTintBlend — how uGlassColor blends with the refracted backdrop
// (mirrors GlassTintBlend in Dart). 0 = auto: pick the path from the tint's
// chroma (the historical behavior). 1 = always luminosity-preserving — for
// near-neutral tints that must keep the glassy look instead of falling to
// the flat film. 2 = always flat blend — for dimming layers and backing
// scrims, where imposing the tint's brightness is the point.
uniform float uTintBlend;

uniform sampler2D uBackgroundTexture;
uniform sampler2D uGeometryTexture;

layout(location = 0) out vec4 fragColor;

void main() {
    // Unpacked here rather than at global scope: global non-constant initialisers
    // (e.g. float x = uniform.y) are valid in desktop GLSL 4.6 but rejected by
    // SkSL / glslang on Windows (SPIR-V path). Same fix as 0.7.10 geometry shader.
    float uRefractiveIndex     = uOpticalProps.x;
    float uChromaticAberration = uOpticalProps.y;
    float uThickness           = uOpticalProps.z;
    float uLightIntensity      = uLightConfig.x;
    float uAmbientStrength     = uLightConfig.y;
    float uSaturation          = uLightConfig.z;

    vec2 fragCoord = FlutterFragCoord().xy;

    // Use the explicit uSize uniform for UV derivation. textureSize() was tried
    // but can return (0,0) on the first frame before GPU texture upload completes
    // in Impeller's BackdropFilterLayer context, causing 1/0 = Infinity UVs and
    // an invisible first-frame render. uSize (physical pixels of the backdrop
    // capture, equal to desiredMatteSize * devicePixelRatio) is always valid.
    vec2 invTexSize = 1.0 / uSize;
    vec2 screenUV = fragCoord * invTexSize;

    #ifdef IMPELLER_TARGET_OPENGLES
        screenUV.y = 1.0 - screenUV.y;
    #endif

    vec2 geometryUV = (fragCoord - uGeometryOffset) / uGeometrySize;
    #ifdef IMPELLER_TARGET_OPENGLES
        geometryUV.y = 1.0 - geometryUV.y;
    #endif

    // Any fragment whose geometryUV falls outside [0,1] is outside the glass
    // pill boundary entirely.  Without this early-out the sampler clamps to the
    // edge pixel (UV.x=0 → left boundary pixel, alpha ≈ 0.5 from SDF AA), which
    // renders a faint glass stripe in the _clipExpansion zone (20 px on each
    // side). That stripe is visible at the pill's vertical midpoint as a short
    // line protruding left and right from the pill edges.
    if (any(lessThan(geometryUV, vec2(0.0))) || any(greaterThan(geometryUV, vec2(1.0)))) {
        fragColor = vec4(0.0);
        return;
    }

    vec4 geometryData = texture(uGeometryTexture, geometryUV);

    #if DEBUG_GEOMETRY
        fragColor = geometryData;
        return;
    #endif

    if (geometryData.a < 0.01) {
        fragColor = vec4(0);
        return;
    }

    // --- V1: Decode true surface normal from geometry texture ---
    //
    // The geometry pass stores the SDF-gradient-derived normal in RG.
    // Before V1 this stored displacement XY, and the render pass called
    // normalize(displacement) as a proxy for the normal — which diverges
    // from the true normal in blend-group neck zones (smooth-union joins).
    // The true normal is now decoded and used for both refraction and lighting.
    vec2 normalXY = decodeNormalXY(geometryData);
    float normalZSq = max(0.0, 1.0 - dot(normalXY, normalXY));
    float normalZ   = sqrt(normalZSq);
    vec3  normal    = vec3(normalXY, normalZ);   // unit-length surface normal

    // Recompute refraction displacement from the true normal.
    // This is the same refract() call used in the geometry pass — exact, not
    // approximated.  Height is still read from the B channel.
    float height = decodeHeight(geometryData, uThickness);
    float baseHeight = uThickness * 8.0;
    vec3  incident   = vec3(0.0, 0.0, -1.0);
    float invN       = 1.0 / max(uRefractiveIndex, 0.001);
    vec3  baseRefract = refract(incident, normal, invN);
    float refractLen  = (height + baseHeight) / max(0.001, abs(baseRefract.z));
    vec2  displacement = baseRefract.xy * refractLen;

    // On OpenGL ES, screenUV.y is already flipped to (1.0 - y) to compensate
    // for the bottom-left texture-origin convention.  The displacement is
    // computed in Flutter's native Y-down space (outward normal at the bottom
    // edge has +Y), but adding a positive Y delta to the flipped UV moves the
    // sample TOWARD the centre rather than away — inverting the refraction.
    // Negating displacement.y re-aligns it with the Y-up UV sampling space.
    #ifdef IMPELLER_TARGET_OPENGLES
        displacement.y = -displacement.y;
    #endif

    // Apply refraction — with optional chromatic aberration.
    // PP1 optimisation: when the surface normal is flat (pointing straight up,
    // i.e. normalXY ≈ 0), refract() always produces displacement = vec2(0) and
    // the refracted UV is identical to screenUV.  Skip refract() entirely and
    // take a single background sample.  This covers the majority of pixels on
    // large surfaces (GlassAppBar, GlassPanel), where the edge zone is a small
    // fraction of the total area.
    //
    // Threshold chosen conservatively: 1e-4 in squared magnitude corresponds to
    // a normal tilted < 0.6° from vertical — visually indistinguishable from a
    // zero-displacement sample at any display resolution.
    vec4 refractColor;
    if (dot(normalXY, normalXY) < 1e-4) {
        // Flat interior — surface is pointing straight at the camera.
        // Displacement is mathematically zero; sample the background directly.
        refractColor = texture(uBackgroundTexture, screenUV);
    } else if (uChromaticAberration < 0.01) {
        vec2 refractedUV = screenUV + displacement * invTexSize;
        refractColor = texture(uBackgroundTexture, refractedUV);
    } else {
        float dispersionStrength = uChromaticAberration * 0.5;
        vec2 redOffset  = displacement * (1.0 + dispersionStrength);
        vec2 blueOffset = displacement * (1.0 - dispersionStrength);

        vec2 redUV   = screenUV + redOffset   * invTexSize;
        vec2 greenUV = screenUV + displacement * invTexSize;
        vec2 blueUV  = screenUV + blueOffset  * invTexSize;

        float red         = texture(uBackgroundTexture, redUV).r;
        vec4  greenSample = texture(uBackgroundTexture, greenUV);
        float blue        = texture(uBackgroundTexture, blueUV).b;

        refractColor = vec4(red, greenSample.g, blue, greenSample.a);
    }

    vec4 finalColor = applyGlassColor(refractColor, uGlassColor, uTintBlend);

    // VQ4: Content-adaptive glass strength.
    //
    // iOS 26 glass dynamically adjusts its material intensity based on the
    // luminance of the content beneath it.  Dark backdrops produce richer,
    // more vivid glass; bright or uniform backdrops produce a subtler material
    // to avoid overwhelming the UI.
    //
    // Implementation: dot-product backdrop luminance from refractColor —
    // the already-sampled background at the refracted UV.  Zero extra texture
    // reads; the sample is already in the register file.
    //
    // LUMA_WEIGHTS = vec3(0.299, 0.587, 0.114) (BT.601, defined in render.glsl)
    //
    // adaptiveStrength range [0.8, 1.2]:
    //   • backdropLuma = 0.0 (black)  → strength 1.2 (richer glass)
    //   • backdropLuma = 1.0 (white)  → strength 0.8 (subtler glass)
    //
    // Cost: 1 dot product + 1 mix() + 1 extra mix() for tint = 3 MADs.
    // Effectively free on modern GPUs.
    float backdropLuma     = dot(refractColor.rgb, LUMA_WEIGHTS);
    float adaptiveStrength = mix(1.2, 0.8, backdropLuma);

    // Apply saturation with adaptive scaling.
    // adaptiveStrength > 1.0 → more vivid (dark backdrop).
    // adaptiveStrength < 1.0 → more muted (bright/uniform backdrop).
    // uSaturation is the artist-set base; we only modulate it, never replace it.
    finalColor.rgb = applySaturation(finalColor.rgb, uSaturation * adaptiveStrength);

    // Modulate glass tint blend weight by adaptiveStrength.
    // On dark backgrounds the tint reads heavier (+20%); on bright backgrounds
    // it reads lighter (-20%).  The delta is small (max ±20% of the 12% base
    // weight = ±2.4%) — within a single JND step, noticeable as a property
    // not a glitch.  Uses mix() to re-blend toward uGlassColor.rgb over the
    // already-tinted finalColor, scaled by the adaptive delta only.
    finalColor.rgb = mix(finalColor.rgb,
                         uGlassColor.rgb,
                         uGlassColor.a * 0.12 * (adaptiveStrength - 1.0));

    // Whitening veil — applied here, right after the body tint and BEFORE the
    // rim/fresnel passes. Applying it before the edge lighting means the rim
    // and fresnel highlights are drawn on top of the whitened body, so the
    // bright edges stay crisp even when the body is heavily whitened —
    // matching iOS 26's light-mode bar, where the white ring / edge
    // reflections stay sharp over a whitened interior.
    //
    // Luminance-gated mode: scale the whiten by how bright this pixel already
    // is, so near-white content beneath the glass lifts to pure white while
    // darks (text, icons) are left untouched — instead of a uniform veil that
    // grays the darks too. This is a point operation (per-pixel, depending
    // only on this pixel's own luminance — no neighbourhood sampling), so
    // unlike a spatial content detector it cannot produce a halo or seam; at
    // a dark-on-light edge it just steepens the existing gradient (crisper
    // edge, no gray ring).
    //
    // WHITEN_LO / WHITEN_HI are content-classification thresholds (what
    // luminance counts as "a dark to protect" vs "a white to push"), not
    // aesthetic per-recipe values — so they are hardcoded rather than passed
    // as uniforms. The single tunable lever is uWhiten (the strength).
    //   below WHITEN_LO → gate 0 (fully protected, stays dark)
    //   above WHITEN_HI → gate 1 (fully whitened, lifts to white)
    const float WHITEN_LO = 0.40;
    const float WHITEN_HI = 0.80;
    float whitenLuma = dot(finalColor.rgb, LUMA_WEIGHTS);
    // uWhitenGated 1 → gate by luminance (light mode, protects darks);
    // uWhitenGated 0 → gate = 1, uniform whiten (dark mode, even lift).
    float whitenGate =
        mix(1.0, smoothstep(WHITEN_LO, WHITEN_HI, whitenLuma), uWhitenGated);
    finalColor.rgb =
        mix(finalColor.rgb, vec3(1.0), clamp(uWhiten, 0.0, 1.0) * whitenGate);

    // Edge lighting — uses the true normal.xy (V1; was normalize(displacement))
    float normalizedHeight = geometryData.b;
    float thicknessScale   = clamp(40.0 / max(uThickness, 1.0), 1.0, 4.0);
    float edgeThreshold    = mix(0.8, 0.5, 1.0 / thicknessScale);
    float edgeFactor       = uThickness < 0.01 ? 0.0 : 1.0 - smoothstep(0.0, edgeThreshold, normalizedHeight);


    if (edgeFactor > 0.01) {
        // VQ1: Anisotropic specular — stretch the highlight lobe 20% along the
        // surface tangent, producing an oval iOS 26 highlight instead of a dot.
        //
        // Pre-baked constant: normalXY from the geometry texture is unit-length
        // by construction (stored as a unit normal in the geometry pass).
        // The tangent vec2(-n.y, n.x) is therefore perp and also unit-length.
        // length(normalXY + tangent * 0.20) = sqrt(1.0 + 0.04) = 1.0198039
        // 1.0 / 1.0198039 = 0.9805806
        // This eliminates max(length(normalXY), 0.01), division, and normalize().
        // The edgeFactor > 0.01 gate above already guards the near-zero interior.
        vec2  anisoN  = normalXY; // True non-chiral normal for symmetric highlights

        float mainLight     = max(0.0, dot(anisoN, uLightDirection));
        float oppositeLight = max(0.0, dot(anisoN, -uLightDirection));
        float totalInfluence = mainLight + oppositeLight * 0.8;

        // PP2 follow-up: pow(x, 1.5) = x·√x. sqrt() is a single hardware SFU
        // instruction on all Metal/Vulkan/OpenGLES targets — not a transcendental.
        // This replaces the last pow() in the Impeller path with zero exp/log ops.
        float directional = totalInfluence * sqrt(totalInfluence) * uLightIntensity * 3.0;
        float ambient     = uAmbientStrength * 0.5;

        // Soft-clamp brightness with x/(1+x) to prevent mix() extrapolating
        // beyond highlightColor. The original * 3.0 drove the corner brightness
        // to ~9.6, causing a blinding "leading dot". The soft clamp maps all
        // values to [0, 1) so corners and edges converge gracefully.
        float brightnessRaw = (directional + ambient) * edgeFactor * thicknessScale * 0.8;
        float brightness    = brightnessRaw / (1.0 + brightnessRaw);

        vec3 highlightColor = getHighlightColor(refractColor.rgb, 1.0);
        finalColor.rgb = mix(finalColor.rgb, highlightColor, brightness);
    }

    // VQ2: Fresnel edge luminosity ramp.
    //
    // iOS 26 glass is subtly brighter at grazing angles (the rim) even when
    // no directional specular highlight lands there.  This is the Fresnel term:
    // at near-normal incidence (flat interior) reflected light is minimal;
    // at grazing incidence (edges) it increases.
    //
    // normalZ → 0 at the rim (surface nearly perpendicular to view ray),
    // normalZ → 1 at flat interior (surface facing the camera directly).
    // So (1.0 - normalZ) gives a smooth 0→1 ramp from interior to rim.
    //
    // Gated by edgeFactor so the effect is naturally confined to the rim zone
    // and doesn't accumulate on interior pixels where edgeFactor ≈ 0.
    //
    // Strength 0.10 produces a gentle brightening calibrated against Apple
    // reference screenshots.  Fully branchless — no extra GPU divergence.
    float fresnel = (1.0 - normalZ) * edgeFactor * 0.10;
    finalColor.rgb = clamp(finalColor.rgb + vec3(fresnel), 0.0, 1.0);

    float alpha  = geometryData.a;
    fragColor    = vec4(finalColor.rgb * alpha, alpha);
}

