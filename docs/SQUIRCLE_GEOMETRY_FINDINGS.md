# Squircle & Geometry Shader Findings

This document records concrete findings from the investigation into shape geometry, visual quality, and the SDF shader architecture in `liquid_glass_widgets`. It serves as the authoritative reference for shape-assignment decisions.

---

## 1. Root Cause of "Flicker" During Scale Animations (GlassMenu, Extra Button)

- **Finding:** Flicker during scale animations was caused by sub-pixel aliasing in the surface normal calculations (`dx`, `dy`) within `liquid_glass_geometry_blended.frag`. Because the squircle SDF (L4 norm) is not perfectly Euclidean, computing its derivative over a narrow 1-pixel chord (`±0.5`) caused the gradient magnitude to oscillate when the shape boundary shifted across fractional physical pixels during an animation.
- **Failed Attempt:** A previous attempt to fix this involved rewriting the squircle math into a `C2-continuous bulge` approximation. This failed to stop the flicker and caused visual inaccuracies.
- **Fix Applied:** We restored the true mathematical squircle and increased the finite difference step in the shader from `±0.5` to `±1.0`. Computing the derivative over a 2-pixel chord acts as a mathematical low-pass filter, completely smoothing out sub-pixel normal jitter and eliminating the flicker, while keeping the razor-thin Apple aesthetic intact.

---

## 2. Tab Bar Flicker (Blend Group Interaction)

- **Finding:** The `GlassSearchableBottomBar` uses a single `AdaptiveLiquidGlassLayer` (Premium Blend Group) for both the `TabBar` background and the `GlassTabBarExtraButton`.
- **Impact:** When the `ExtraButton` scales down during a press, `LiquidStretch` modifies its paint transform. This triggers `anyShapeChangedInLayer`, causing the entire layer (including the TabBar's SDF) to be synchronously rebuilt via `toImageSync`.
- **Resolution:** With the 2-pixel chord derivative fix in §1, the normal is completely stable even when rebuilt every frame. The TabBar no longer flickers.

---

## 3. iOS 26 Corner Radius Matching

- **Finding:** `GlassMenu` was temporarily using a standard rectangle during debugging instead of the correct squircle.
- **Fix Applied:** Restored `LiquidRoundedSuperellipse` in `GlassMenu` to match Apple's iOS 26 continuous-curve corner aesthetic. The target corner radius is ~13–14pt, matching the measured iOS 26 context menu.

---

## 4. Critical Finding: The `sdfSquircle` Safety Valve

This is the most important architectural finding of the entire investigation.

### The Math

The GPU shader (`shaders/sdf.glsl`) computes squircle vs circular arc via a blend:

```glsl
float sdfSquircle(in vec2 p, in vec2 b, in float r) {
    float shortest = min(b.x, b.y);   // half the shorter dimension
    r = min(r, shortest);              // clamp radius to fit inside shape

    vec2  q    = abs(p) - b + r;
    vec2  qPos = max(q, 0.0);
    float l4   = sqrt(sqrt(qPos.x*qPos.x*qPos.x*qPos.x + qPos.y*qPos.y*qPos.y*qPos.y));
    float l2   = sqrt(qPos.x*qPos.x + qPos.y*qPos.y);

    // KEY LINE: blend between circular (l2) and squircle (l4)
    float blend  = min(sqrt((shortest - r) / max(shortest, 1e-5)), 1.0);
    float corner = mix(l2, l4, blend);
    return min(max(q.x, q.y), 0.0) + corner - r;
}
```

### When the Squircle Effect Is Zero

When `r == shortest` (i.e., the corner radius fills the full half-height — any pill/stadium shape), `blend = 0.0`. The shader returns the pure circular arc (`l2`) and discards the L4 math entirely. **`LiquidRoundedSuperellipse` and `LiquidRoundedRectangle` are indistinguishable at pill proportions.**

This is **by design** — applying the L4 bulge to a full-fill pill would produce an elliptical distortion, not a stadium shape.

### Practical Implication

Any widget using `LiquidRoundedSuperellipse` with `borderRadius >= height / 2` is silently using the same circular-arc math as `LiquidRoundedRectangle`. This was confirmed visually by the `ShapeDebugDemo`:
- At `r = 16` (height ≈ 100), the squircle corner is dramatically different from the rounded rect.
- At `r >= height/2` (pill), they are visually identical.

This is also why the original user-reported bug ("no visual difference between `LiquidRoundedSuperellipse` and `LiquidRoundedRectangle` at `borderRadius: 40` on a `height: 52` button") is a **correct observation, not a bug** — the shader is doing exactly the right thing.

---

## 5. Shape Assignment Rules (Canonical Reference)

### Rule 1: Use `LiquidRoundedSuperellipse` for static, fixed-aspect-ratio containers where corners are visible

The squircle effect is fully expressed only when `borderRadius < height / 2`. Cards, modals, sheets, icon buttons, grouped sections — all qualify.

### Rule 2: Use `LiquidRoundedRectangle` for anything that stretches, morphs, or is a pill

When a shape's aspect-ratio changes continuously (drag animations, tab switching, morph transitions), or when it is already a pill, use the rounded rect:
- It is SDF-stable across all aspect ratios
- The visual result is identical at pill proportions anyway
- It avoids the `dFdx/dFdy` gradient drift from the non-Euclidean L4 norm during animation

### Enforced Widget Assignments

| Widget / Component | Shape | Reason |
|---|---|---|
| `GlassCard`, `GlassContainer` | `LiquidRoundedSuperellipse` | Static card — corners fully visible |
| `GlassGroupedSection` | `LiquidRoundedSuperellipse` | Static container |
| `GlassIconButton.roundedSquare` | `LiquidRoundedSuperellipse` | Static square — squircle fully expressed |
| `GlassIconButton.circle` | `LiquidOval` | Circle — correct shape type |
| `GlassMenu` container | `LiquidRoundedSuperellipse` | Static container, iOS 26 continuous curve |
| `GlassMenu` morph blobs | `LiquidRoundedRectangle` | Dynamic morph — aspect changes every frame |
| `GlassPopover` morph blobs | `LiquidRoundedRectangle` | Dynamic morph |
| `GlassChip` | `LiquidRoundedRectangle(r=100)` | Pill shape — squircle blend = 0 |
| `GlassButtonGroup` indicator | `LiquidRoundedRectangle` | Stretching pill indicator |
| `GlassSlider` thumb | `LiquidOval` | Circle |
| `GlassPageControl` indicator | `LiquidRoundedRectangle` | Dynamic pill |
| `AnimatedGlassIndicator` | `LiquidRoundedRectangle` (default) | Dynamic stretching pill |

---

## 6. `AnimatedGlassIndicator.useSuperellipse` Default Fix

`AnimatedGlassIndicator.useSuperellipse` was defaulting to `true` (squircle). This was wrong:
- The indicator is a dynamic, morphing pill whose width changes on every drag frame
- At pill proportions the squircle SDF blend = 0 (pure circular arc anyway)
- The L4 gradient drift during animation caused subtle shape instability

**Fix:** Default changed to `false`. All internal call sites (tab bars, segmented controls) were also updated to explicitly pass `useSuperellipse: false`. The docstring was rewritten to explain the SDF math behind this decision.

---

## 7. Two-Tier Quality Architecture

### Premium (GPU SDF — `GlassQuality.premium`)

- Full `liquid_glass_renderer` shader pipeline
- `sdfSquircle` / `sdfRRectAsym` run per-pixel on GPU
- Rim lighting derived from `dFdx/dFdy` of the SDF — follows the squircle curve exactly
- True L4-norm continuous curvature — maximum iOS 26 fidelity
- **This is the ceiling. You cannot get closer to iOS 26 without modifying the Flutter engine.**

### Standard (CPU/Lightweight — `GlassQuality.standard`)

- `LightweightLiquidGlass` widget
- Clip boundary: `ClipPath(clipper: ShapeBorderClipper(shape: RoundedSuperellipseBorder(...)))` — this calls Flutter's native `Path()..addRSuperellipse(...)`, which IS a real squircle path (native engine, not Bézier approximation)
- Lightweight GLSL shader: applies blur/frost uniformly — **completely shape-type-blind**
- Rim lighting does not follow the squircle curve; it is uniform across the glass surface
- **Result:** Both `LiquidRoundedSuperellipse` and `LiquidRoundedRectangle` look nearly identical in Standard mode because the shader doesn't know which shape it is. The only difference is the clip boundary.

### Why Standard mode is not fixable without cost

Adding SDF shape-type awareness to the lightweight shader would require passing shape-type and radius uniforms, computing a simplified SDF per-fragment, and branching on shape type. This pushes the "cheap" Standard tier meaningfully toward Premium GPU cost — defeating its purpose. The two-tier gap is intentional.

### Standard mode banner (corrected)

Previously the demo incorrectly stated `"_SquircleClipper + lightweight shader (CPU L4/L2 path)"`. Corrected to `"ShapeBorderClipper + lightweight blur shader (shape-blind)"`.

---

## 8. Alignment with Upstream `liquid_glass_renderer`

`liquid_glass_renderer` (pub.dev, v0.2.0-dev.4, whynotmake.it) exposes exactly the same three shapes:
- `LiquidRoundedSuperellipse` — (recommended) smooth squircle
- `LiquidOval` — ellipse/circle
- `LiquidRoundedRectangle` — rounded rectangle

Our package's `lib/src/renderer/liquid_shape.dart` is a fork/extension of this renderer. We added two custom shapes for the tab-bar use case:
- `LiquidVerticalRoundedRectangle` — independent top/bottom radii, rect math
- `LiquidVerticalRoundedSuperellipse` — independent top/bottom radii, squircle math

The upstream README explicitly marks `LiquidRoundedSuperellipse` as "(recommended)" and notes all shapes take a single `double` for radius because their shaders don't support non-uniform radii. Our architecture is fully aligned.

---

## 9. Git Branch State

- All changes landed on `fix/standard-squircle-geometry`.
- The `main` branch has **not** been merged into this branch by us.
- Merge to `main` pending final visual quality verification.
