# Liquid Morph Engine

The Liquid Morph Engine is the centralised physics and animation system powering the iOS 27 liquid glass morphing effect across all `liquid_glass_widgets` (`GlassMenu`, `GlassPullDownButton`, `GlassPopover`, and `GlassModalSheet`).

---

## Overview

Calibrated directly against 60 fps `CADisplayLink` `CALayer.presentation()` traces of native iOS 27 `_UIMorphAnimationContainerView`, `MagicMorphView`, and `_UIContextMenuView`, the engine coordinates two coupled glass bodies:

- **Blob A / Trigger Morph (`MagicMorphView` #2)** — centered on `trigger.center`. On wide/pill triggers (`tw > th`), its width contracts horizontally in place from `tw → min(tw, th)` (`triggerWidthProgress`: `1.0 → 0.0`, `ω₀ = 25 rad/s, ζ = 0.94`) during open, and re-expands outward from the middle (`0.0 → 1.0`, `ω₀ = 13 rad/s, ζ = 0.795`) during close — crossing full width around `~320 ms` and splashing `+1.6 %` wider around `~400 ms`.
- **Blob B / Platter Body (`_UIContextMenuView` / `MagicMorphView` #1)** — expands from `trigger.center` along a J-curve trajectory (`ω₀ = 17 rad/s, ζ ≈ 0.76`) on open, and collapses directly back into `trigger.center` (`ω₀ = 18 rad/s, ζ ≈ 0.86`, `platterScale` `1.0 → 0.20`, vanishing at `~280 ms`) on close.
- **Parallel Close Trigger Recoil (`_kickView`)** — starts immediately at `t = 0 ms` of `close()` (in parallel with platter contraction rather than waiting for `rawValue <= 0`), peaking around `~183 ms` (`triggerPushDx`, `triggerPushDy`, `triggerImpactScale`) with smooth soft-saturation (`~5–16 px` across all menu, popover, and sheet travel distances) and settling around `~530–550 ms`.

---

## Key Types

| Type | Role |
|---|---|
| `GlassMorphController` | Lifecycle owner — manages the springs, phase clock, and `open()` / `close()` |
| `LiquidMorphState` | Immutable per-frame value object containing all pre-computed render values |
| `MorphPhase` | Semantic lifecycle enum (`idle`, `detaching`, `travelling`, `arriving`, `settled`) |
| `MorphSpeed` | Speed profile enum (`slow`, `normal`, `fast`, `instant`) |
| `MorphStyle` | Shape variant enum (`teardrop`, `bloom`) |
| `LiquidMorphPhysics` | Stateless math engine — use via `GlassMorphController.computeState()` |

---

## GlassMorphController

### Control methods & accessors

| Member | Type | Description |
|---|---|---|
| `open()` | `void` | Drives the open morph (`0.0 → 1.0`). Safe to call mid-close. |
| `close()` | `void` | Drives the close morph (`1.0 → 0.0`) with parallel trigger recoil (`~183 ms` peak) and centered width re-expansion (`~400 ms` splash). |
| `reset()` | `void` | Immediately resets to idle (`0.0`) without animating. |
| `setDisableAnimations(bool)` | `void` | Syncs Reduce Motion (`MediaQuery.of(context).disableAnimations`). |
| `isShowing` | `bool` | `true` from `open()` until both the platter (`~280 ms`) and the trigger recoil/splash (`~550 ms`) have settled. |
| `hasHandedOff` | `bool` | Latches `true` when the closing platter spring crosses `0.0` (`~280 ms`). |
| `phaseElapsedSeconds` | `double` | Speed-scaled elapsed seconds in the active open/close phase (`0.0` under Reduce Motion). |
| `speedMultiplier` | `double` | Frequency multiplier vs `MorphSpeed.normal` (`0.65`, `1.0`, `1.35`, `2.5`). |

### Static geometry helpers

- `GlassMorphController.computeScaleDelta(sourceSize:, targetSize:)` — `√(targetArea / sourceArea)`.
- `GlassMorphController.computeCornerRadius(currentSize:, triggerRadius:, targetRadius:, progress:)` — monotonic corner radius clamped to `min(shortestSide / 2, max(triggerRadius, targetRadius))` so mid-flight corners never balloon above `targetRadius`.

---

## LiquidMorphState Fields

```dart
final LiquidMorphState state = _morph.computeState(
  finalDx: platterCentreX - triggerCentreX,
  finalDy: platterCentreY - triggerCentreY,
  horizontalOffset: _horizontalClampOffset,
  verticalOffset:   _verticalClampOffset,
  scaleDelta: GlassMorphController.computeScaleDelta(
    sourceSize: triggerSize,
    targetSize: platterSize,
  ),
);
```

| Field | Type | Description |
|---|---|---|
| `pathT` | `double` | J-curve position interpolation on open; coupled contraction on close. |
| `sizeT` | `double` | Coupled size interpolation (`[0, 1]`). |
| `currentDx` / `currentDy` | `double` | Platter center displacement (`finalDx * pathT`, `finalDy * pathT`). |
| `triggerPushDx` / `triggerPushDy` | `double` | Parallel close recoil offset (px) for the trigger, peaking at `~183 ms` (`~5–16 px`). |
| `triggerImpactScale` | `double` | Tactile compression pulse (`~0.96–1.0`) for the trigger, peaking at `~183 ms`. |
| `triggerWidthProgress` | `double` | Wide-trigger centered width progress (`1.0` full width → `0.0` circle on open → `1.0` with `+1.6 %` splash at `~400 ms` on close). |
| `platterScale` | `double` | Uniform platter scale (`1.0 → 0.20` around `trigger.center` on close). |
| `platterOpacity` | `double` | Platter glass visibility (`1.0` while open and down to `rawValue = 0.25` / `~165 ms` on close so the shrinking droplet stays dense liquid glass, then dissolving `1.0 → 0.0` over the final `rawValue ∈ [0.0, 0.25]` SDF merge window `~165–283 ms`). Drive via `GlassMaterializeScope(glassProgress:)`, **never** a fractional `Opacity` widget over `AdaptiveLiquidGlassLayer`. |
| `contentOpacity` | `double` | Platter inner content opacity (`clamp((platterScale - 0.20) / 0.80, 0, 1)` on close). |
| `isPlatterActive` | `bool` | `true` while Blob B should be painted; turns `false` at `~280 ms` on close while the trigger finishes rebounding until `~550 ms`. |
| `anchorScale` | `double` | Anchor blob scale in `[0, 1]`. |
| `blend` | `double` | SDF metaball merge radius in `[0, 28]`. |
| `containerScale` | `double` | Subtle container scale pulse. |
| `phase` | `MorphPhase` | Semantic lifecycle phase. |

---

## Calibrated iOS 27 Physics Reference

| Component | Profile (`MorphSpeed.normal`) | Behavior |
|---|---|---|
| **Open Platter (`openSpring`)** | `ω₀ = 17.0 rad/s, ζ ≈ 0.76` (`k = 289, c = 25.8`) | Crisp J-curve launch, `+2.5 %` arrival settle, completes `~420 ms`. |
| **Close Platter (`closeSpring`)** | `ω₀ = 18.0 rad/s, ζ ≈ 0.86` (`k = 324, c = 31.0`) | Collapses `1.0 → 0.20` around `trigger.center`, vanishes at `~280 ms`. |
| **Open Wide-Trigger Collapse** | `ω₀ = 25.0 rad/s, ζ = 0.94` | Contracts `tw → min(tw, th)` centered on `trigger.center`. |
| **Close Wide-Trigger Splash** | `ω₀ = 13.0 rad/s, ζ = 0.795` | Re-expands `min(tw, th) → tw`, crosses `1.0` at `~320 ms`, `+1.6 %` splash at `~400 ms`. |
| **Close Trigger Recoil** | Coupled `S(17, 0.70) − S(18, 1.0)` | Parallel kick from `t = 0 ms`, peaks at `~183 ms`, settles `~530–550 ms`. |

---

## See Also

- [GLASS_MODAL_SHEETS_GUIDE.md](GLASS_MODAL_SHEETS_GUIDE.md) — complete reference for `GlassModalSheet`
- [ARCHITECTURE.md](ARCHITECTURE.md) — package architecture, quality system, release process
