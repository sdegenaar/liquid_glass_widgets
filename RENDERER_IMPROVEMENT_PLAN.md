# Renderer Improvement Plan

Deep-dive analysis of the vendored `liquid_glass_renderer` source (0.2.0-dev.4)
as it lives in `lib/src/renderer/` and `shaders/`.

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Done |
| 🔄 | In progress |
| ⬜ | Planned |
| ❌ | Won't fix / out of scope |

---

## Architecture Recap

Two rendering paths:

```
AdaptiveGlass
  ├── Impeller  → LiquidGlassLayer
  │                 ├── BackdropFilterLayer (blur, clip-path'd to shape)
  │                 └── BackdropFilterLayer (liquid_glass_final_render.frag)
  │               LiquidGlassBlendGroup
  │                 └── liquid_glass_geometry_blended.frag → GeometryCache
  └── Skia/Web → LightweightLiquidGlass
                   └── lightweight_glass.frag (no backdrop sampling)
```

Two GLSL passes on Impeller:
1. **Geometry pass** (`liquid_glass_geometry_blended.frag`) — SDF → displacement +
   height → texture. Runs once per geometry change (cached).
2. **Render pass** (`liquid_glass_final_render.frag`) — reads geometry texture +
   backdrop → refraction + edge lighting + glass tint.

---

## Bugs

### ✅ B1. `LiquidGlassBlendGroup` builds `ShaderBuilder` unconditionally

`LiquidGlassBlendGroup.build()` had no `ImageFilter.isShaderFilterSupported` guard,
causing a SkSL compilation crash on Skia / web. Fixed by adding the same guard
that `LiquidGlassLayer` already had.

**Files changed:** `lib/src/renderer/liquid_glass_blend_group.dart`

---

### ✅ B2. `shared.glsl` is orphaned dead code

`shared.glsl` in `shaders/` is a copy of the original upstream shared utilities.
`liquid_glass_final_render.frag` was updated to `#include "render.glsl"` (our
optimised version) but `shared.glsl` was never deleted. Nothing includes it.

**Fix:** Deleted `shaders/shared.glsl`.

---

### ✅ B3. `precision mediump float` in geometry shader causes banding

`liquid_glass_geometry_blended.frag` declared `precision mediump float`.
On mobile, mediump has a 10-bit mantissa. For `maxDisplacement = thickness * 10`
at thickness=20, each displacement step is ≈1.56 logical pixels, producing visible
quantisation banding in the refraction field.

**Fix:** Changed to `precision highp float`. The geometry shader is cached and
only re-runs on layout changes, so the performance impact is negligible.

**Files changed:** `shaders/liquid_glass_geometry_blended.frag`

---

### ⬜ B4. `uSize` is never set in `liquid_glass_final_render.frag` [needs device investigation]

`uniform vec2 uSize` occupies float slots 0–1 in the final render shader.
`_updateShaderSettings()` starts at `initialIndex: 6`. `paint()` starts at
`initialIndex: 2`. Slots 0–1 are never written.

The shader divides `fragCoord` by `uSize` to compute `screenUV` for background
texture sampling. With `uSize = (0,0)`, this produces `Inf`/`NaN` UVs.

**Suspected effect:** Refraction/lensing samples a degenerate UV (edge pixel or
black) rather than the displaced background position. The glass still looks
"glass-like" because edge lighting reads from `geometryData.b` (unaffected), but
the actual displacement/lensing of background content is broken.

**Needs device verification** before fixing — Impeller's BackdropFilter may
normalise fragCoord in a way that makes this tolerable, or the bug may be
masked by mirror tiling.

**Suspected fix:** In `paint()` or `_updateShaderSettings()`, set slots 0–1 to
the physical size of the BackdropFilter region:
```dart
renderShader.setFloatUniforms(initialIndex: 0, (value) {
  value.setSize(desiredMatteSize);  // physical screen/region size
});
```

---

### ✅ B5. `calculateDispersiveIndex` is defined but never called

Deleted from `render.glsl`. The function implemented a Cauchy wavelength-based
dispersion formula but was never called by `calculateRefraction` — the shader
used a simpler linear displacement scale instead.

**Files changed:** `shaders/render.glsl`

---

### ✅ B6. `blurRadius` dead parameter in `calculateRefraction`

Removed from `calculateRefraction` signature and its single call site in
`renderLiquidGlass`. The parameter was never read inside the function body.

**Files changed:** `shaders/render.glsl`

---

## Visual Quality

### ⬜ V1. Edge normals approximated from displacement (wrong in blend zones)

In `liquid_glass_final_render.frag`:
```glsl
vec2 normalXY = normalize(displacement);  // proxy for surface normal
```
For blended shapes (smooth-union SDF), the displacement direction diverges from
the true surface normal in the blend "neck". The true normal is computed in the
geometry pass but only `height` (B channel) is stored — the XY components are
discarded.

**Fix:** Store `normal.xy` in the geometry texture instead of height. Height can
be approximated from displacement magnitude for the common single-shape case, or
removed in favour of normal-derived height.

---

### ⬜ V2. `sdfSquircle` is not a superellipse

`sdfSquircle` in `sdf.glsl` is mathematically identical to `sdfRRect` — both
compute an L²-rounded rectangle. A true squircle/superellipse satisfies
`|x/a|^n + |y/b|^n = 1` with `n ≥ 4`. iOS 26 uses `n ≈ 4–5` for its UI shapes.

`LiquidRoundedSuperellipse` creates user expectation of a superellipse but
delivers a rounded rect, which diverges visually at large corner radii.

**Fix:** Implement true n=4 superellipse SDF:
```glsl
// Approximate: fast, good enough for n=4
float sdfSuperellipse(vec2 p, vec2 b) {
    vec2 q = abs(p) / b;
    float k = pow(q.x*q.x*q.x*q.x + q.y*q.y*q.y*q.y, 0.25);
    return (k - 1.0) * min(b.x, b.y);
}
```

---

### ⬜ V3. Saturation applied at different pipeline stages

`render.glsl::renderLiquidGlass` applies saturation *after* adding lighting.
`liquid_glass_final_render.frag` applies saturation *before* edge lighting.
The final render pass is correct (specular highlights should be white, not
desaturated), but the inconsistency means the two paths behave differently when
`saturation ≠ 1.0`.

---

### ✅ V4. Duplicate highlight colour implementations

Replaced the inline 8-line highlight colour block in `liquid_glass_final_render.frag`
with a call to `getHighlightColor(refractColor.rgb, 1.0)` from `render.glsl`
(which is already `#include`d). The inline version was a rougher approximation
that diverged from the shared utility over time.

**Files changed:** `shaders/liquid_glass_final_render.frag`

---

### ⬜ V5. Glass tint uses Overlay blend — not iOS 26's luminosity model

`applyGlassColor` uses Photoshop Overlay mode (multiply-dark / screen-light).
iOS 26 glass tinting is closer to a luminosity-preserving hue/chroma shift.
A semi-transparent blue glass should tint the background blue while preserving
luminance, not darken it.

---

## Performance

### ✅ P1. Two `BackdropFilterLayer` blits per glass layer — blur sharing wired

Every `LiquidGlassLayer` pushes two framebuffer captures per frame:
1. Blur `BackdropFilterLayer` (inside `ClipPath`)
2. Shader `BackdropFilterLayer` (inside `ClipRect`)

At 120 Hz with multiple glass widgets: 2N blits/frame. Each blit breaks
Impeller's tile-based deferred rendering pipeline.

**Audit result (2026-03-29):** `useBackdropGroup` was never activated by any
widget. `AdaptiveLiquidGlassLayer` created `LiquidGlassLayer` without it, and
no `BackdropGroup` ancestor was ever inserted in the tree.

**Fix applied:**
- `AdaptiveLiquidGlassLayer` now passes `useBackdropGroup: true` — safe because
  when no `BackdropGroup` ancestor is present, `BackdropGroup.of(context)`
  returns null and behaviour is identical to `false`.
- Added `GlassBackdropScope` widget (thin wrapper around `BackdropGroup`) that
  users place around their `Scaffold` (or equivalent). All glass surfaces inside
  share one GPU blur capture, halving blur blit count.

**Remaining:** The shader `BackdropFilterLayer` (blit 2) is still per-layer.
Merging blur + shader into a single pass would eliminate the remaining blit.
Tracked as post-v1.

**Files changed:** `lib/widgets/shared/adaptive_liquid_glass_layer.dart`,
`lib/widgets/shared/glass_backdrop_scope.dart` (new)

---

### ⬜ P2. `calculateLighting` has three branchy early exits

Three `if (...) return vec3(0)` guards in `calculateLighting` cause warp
divergence on pixels at the glass boundary. Replace with a single branchless
`enable` multiplier computed via `step()`.

---

### ⬜ P3. `toImageSync` blocks the render thread

`UnrenderedGeometryCache.render()` calls `Picture.toImageSync()` — a synchronous
GPU command that stalls the render thread. For animated content (scrolling lists
with glass overlays), this causes per-layout frame hitches.

**Fix:** Use `renderAsync()` with a `markNeedsPaint()` callback; show previous
geometry until new one is ready (one-frame latency, invisible for static layouts).

---

### ⬜ P4. Double Picture+Image composite per geometry update

Two GPU round-trips on every geometry rebuild: per-shape geometry picture
(`_buildGeometryPicture`) + assembled geometry image (`_buildGeometryImage`).
The per-shape step is redundant for single-shape layers (the assembly is trivial).

---

## Architecture

### ✅ A1. `GeometryRenderLink.markRebuilt` has inverted naming

Renamed to `notifyGeometryChanged`. The original name implied "I am clean" but
the method set `_dirty = true`. Both call sites in
`render_liquid_glass_geometry.dart` updated.

**Files changed:** `lib/src/renderer/rendering/liquid_glass_render_object.dart`,
`lib/src/renderer/internal/render_liquid_glass_geometry.dart`

---

### ⬜ A2. `requiresGeometryRebuild` checks too few properties

Only checks `effectiveThickness` and `refractiveIndex`. `blend` changes
(which DO require a geometry rebuild) are handled via a separate setter on
`RenderLiquidGlassBlendGroup` — correct but fragile if blend is ever pulled
into `LiquidGlassSettings`.

---

### ⬜ A3. `LiquidGlassSettings.figma()` constructor has misleading semantics

`depth` is passed directly as `thickness` (raw pixels), but Figma's depth
is a 0–100 percentage of their internal units — not Flutter logical pixels.
This gives users false confidence that they're getting Figma parity.

---

## iOS 26 Parity

### ⬜ I1. No dynamic light angle from device orientation

iOS 26 glass adapts specular highlight position to device tilt via CoreMotion.
Our `lightAngle` is static. Can be driven from Dart via `sensors_plus` →
update `LiquidGlassSettings.lightAngle` → `markNeedsPaint` (cheap uniform-only
repaint).

---

### ⬜ I2. `LiquidRoundedSuperellipse` shape doesn't match iOS 26

See V2. The SDF is a rounded rect, not a superellipse. The divergence is subtle
at small radii but pronounced at `borderRadius > 0.3 * min(width, height)`.

---

## Test Coverage

### ✅ T1. `LiquidGlassSettings` unit tests

`test/renderer/liquid_glass_settings_test.dart` — covers all `effectiveXxx`
computed properties, `visibility` scaling, `copyWith`, `figma()` constructor
mapping, and Equatable equality.

---

### ✅ T2. Renderer structural tests (from upstream)

`test/renderer/liquid_glass_test.dart` — golden smoke tests for shape variants
and blend values (Skia: renders fallback; Impeller: full glass).

`test/renderer/liquid_glass_blend_group_test.dart` — lifecycle tests for geometry
cache state machine, shape registration, blend property propagation, and dispose.

---

## v1 Checklist

### Blocking
- [ ] Verify / fix `uSize` uniform (B4) — device test required
- [x] `useBackdropGroup` wired + `GlassBackdropScope` added (P1 audit ✅)
- [ ] All 281+ tests passing on CI

### Non-blocking but recommended before v1
- [x] Delete dead `calculateDispersiveIndex` and `blurRadius` param (B5, B6 ✅)
- [x] Rename `markRebuilt` → `notifyGeometryChanged` (A1 ✅)
- [x] Unify highlight colour implementations (V4 ✅)

### Post-v1
- [ ] True superellipse SDF (V2 / I2)
- [ ] Normal XY storage in geometry texture (V1)
- [ ] Branchless `calculateLighting` (P2)
- [ ] Async geometry rasterization (P3)
- [ ] Dynamic light angle via `sensors_plus` (I1)
- [ ] iOS 26 glass tint model (V5)
- [ ] Merge blur+shader into single blit pass (P1)
