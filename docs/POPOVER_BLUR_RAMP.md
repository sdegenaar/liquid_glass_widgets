# Popover blur ramp

`GlassPopover` eases its backdrop blur in over the opening morph instead of
rendering it at full strength from the first frame. This is a pure performance
optimisation for the open transition — it does not change the resting
appearance of the popover.

- **Added in:** `0.21.7`
- **Default:** on (`blurRampDuration: Duration(milliseconds: 260)`)
- **Opt out:** `blurRampDuration: Duration.zero`

## The problem

While a `GlassPopover` morphs out of its trigger, the popover body is redrawn
every frame at a new size, and a `BackdropFilter` blur is re-rasterised behind
it each of those frames. A gaussian backdrop blur is one of the most expensive
things a mobile GPU does per frame, and its cost scales with the blurred area
and the blur sigma.

Rendering that blur at **full strength from frame one** pays the maximum raster
cost during the *earliest* part of the morph — the frames where the blob is
still small and growing fastest, and where the rest of the metaball/teardrop
work is already competing for the same frame budget. That is precisely where
frames get dropped, so the transition stutters exactly when it is most visible.

## The fix

Ramp the blur sigma from `0` up to `settings.blur` over the opening morph:

```text
effective blur = settings.blur × curve(t),  t: 0 → 1 over blurRampDuration
```

- At the start of the open, `t ≈ 0` → the backdrop is (near) **sharp**, which is
  the cheapest thing the GPU can do, so the expensive early frames stay light.
- As the popover settles, `t → 1` → the blur reaches its full configured value.

Because the blur is animated continuously (not switched on after a fixed
delay), there is no visible on/off pop — the frost simply blooms in with the
glass. And because content only fades in from ~30 % of the morph (with an
`easeOut` ramp the blur is already most of the way to full by then), the popover
looks right by the time you can read it.

### Why a dedicated controller, not the morph spring

The morph is an **underdamped spring** — its value overshoots `1.0` and
oscillates before settling. If the blur were derived directly from the morph
value it would wobble ±a few percent around full strength as the spring rings
out. The ramp is therefore driven by its own short, monotonic
`AnimationController`, so the blur eases cleanly to full and holds. On close the
ramp is *frozen* (not wound back) so the blur stays coherent while the blob
collapses; it is reset to sharp once the overlay has fully hidden, ready for the
next open.

## Measured impact

On a mid-range Android device, ramping the blur roughly **halved the raster
time of the open transition** and eliminated the dropped frames at the start of
the morph, with no perceptible change to the final look. The numbers were taken
from `flutter driver` frame-timing captures of a popover opening on a physical
device (`integration_test` + `watchPerformance`).

> Note on the numbers: backdrop-blur cost is GPU-bound, so it is only meaningful
> when measured on a real device / emulator with a hardware rasteriser. Headless
> CI runners render in software and cannot reproduce these timings — treat any
> such measurement as a device/nightly report, not a CI gate.

## Usage

### Default — nothing to do

Every `GlassPopover` ramps its blur automatically:

```dart
GlassPopover(
  settings: const LiquidGlassSettings(blur: 24), // resting blur = ramp target
  trigger: const Icon(Icons.notifications),
  contentBuilder: (context, close) => const MyPopoverBody(),
)
```

### Tune the ramp

```dart
GlassPopover(
  blurRampDuration: const Duration(milliseconds: 320), // slower bloom
  blurRampCurve: Curves.easeOutCubic,
  settings: const LiquidGlassSettings(blur: 24),
  trigger: const Icon(Icons.notifications),
  contentBuilder: (context, close) => const MyPopoverBody(),
)
```

### Disable — render full blur immediately

Restores the pre-`0.21.7` behaviour:

```dart
GlassPopover(
  blurRampDuration: Duration.zero,
  settings: const LiquidGlassSettings(blur: 24),
  trigger: const Icon(Icons.notifications),
  contentBuilder: (context, close) => const MyPopoverBody(),
)
```

## Accessibility

When the platform **"reduce motion"** setting is active, the ramp is skipped and
the blur is shown at full strength on the first frame — the morph itself is
already near-instant in that mode, so there is nothing to ease in.

## Notes

- The ramp scales the `blur` field of the popover's effective
  `LiquidGlassSettings` only; all other glass properties (thickness, tint,
  lighting, refraction) are unchanged throughout.
- When the ramp is complete or disabled, the hoisted settings object is reused
  as-is — no per-frame `copyWith` allocation happens once the blur has settled.
