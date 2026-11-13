# Adaptive Quality — Threshold Calibration

`GlassAdaptiveScope` (enabled via `wrap(adaptiveQuality: true)`) automatically
benchmarks the device at startup and adjusts rendering quality in real time.
It is `@experimental` because its Phase 2 timing thresholds are based on limited
community data and have not yet been validated across the full Android device
landscape.

## Current defaults

| P75 warmup | Quality assigned |
|---|---|
| < 20 ms | `premium` *(based on 1 report — please share yours)* |
| 20–28 ms | `standard` *(provisional — no real-device data yet)* |
| > 28 ms | `minimal` |

## 📊 Help us tune the thresholds — takes 2 minutes

If you use `adaptiveQuality: true`, please post your results to our
[Threshold Calibration Discussion](https://github.com/sdegenaar/liquid_glass_widgets/discussions)
with the snippet below. Every report directly informs the threshold calibration
and gets us closer to removing `@experimental`.

```dart
// Add to your GlassAdaptiveScopeConfig while testing — remove before shipping:

// Option A: zero-wiring (recommended for quick reports)
GlassAdaptiveScopeConfig(
  debugLogDiagnostics: true, // prints to console in debug builds only
)

// Option B: custom handler for analytics
GlassAdaptiveScopeConfig(
  onDiagnostic: (d) {
    // d.reason, d.p75Ms, d.p95Ms, d.framesMeasured, d.phase are all set
    debugPrint('📊 ${d.from.name} → ${d.to.name} | reason: ${d.reason.name} | P75: ${d.p75Ms?.toStringAsFixed(1)}ms');
  },
)
```

Please include your **device model**, **Flutter version**, and **observed P75 ms**
in your discussion post. Thank you 🙏

---

## Persisting Settled Quality Across Cold Starts

Within a single app process, `GlassAdaptiveScope` caches the settled quality automatically. Across cold starts, use `onQualityChanged` + `initialQuality` with `SharedPreferences` (or your preferred storage) to skip the 3-second warm-up window on repeat launches:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('glass_quality');
  final initial = saved != null ? GlassQuality.values.byName(saved) : null;

  await LiquidGlassWidgets.initialize();

  runApp(LiquidGlassWidgets.wrap(
    child: const MyApp(),
    adaptiveQuality: true,
    adaptiveConfig: GlassAdaptiveScopeConfig(
      initialQuality: initial,
      allowStepUp: true,
      onQualityChanged: (_, to) => prefs.setString('glass_quality', to.name),
    ),
  ));
}
```

## Pausing Measurement During Heavy App Work

If your app performs heavy CPU/GPU work of its own (e.g., decoding a large file or loading an on-device model), pause frame measurement so the temporary slowdown is not mistaken for GPU pressure:

```dart
final hold = GlassAdaptiveScope.holdMeasurement();
try {
  await heavyWork();
} finally {
  hold.release();
}
```
