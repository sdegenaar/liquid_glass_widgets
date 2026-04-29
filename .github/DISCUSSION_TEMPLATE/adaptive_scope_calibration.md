---
title: "[Threshold Report] Device: YOUR_MODEL"
labels: ["adaptive-scope", "calibration-data"]
---

## 📊 GlassAdaptiveScope Threshold Calibration Report

Thanks for helping calibrate the `GlassAdaptiveScope` thresholds!
This data directly informs when we can remove `@experimental`.

---

### Device Details

| Field | Value |
|---|---|
| **Device model** | e.g. Pixel 6a / Samsung Galaxy A54 / OnePlus Nord 2 |
| **Android version** | e.g. Android 14 |
| **Flutter version** | output of `flutter --version` |
| **liquid_glass_widgets version** | e.g. 0.8.4 |

---

### Quality Result

**Quality tier selected by the library:** `minimal` / `standard` / `premium` *(delete as applicable)*

**Did this match your expectation?** Yes / No / Unsure

**If No — what did you expect and why?**
*(e.g. "Expected standard but got minimal — the app runs at 60fps smoothly")*

---

### Timing Data *(optional but very helpful)*

Add `onQualityChanged` to your `GlassAdaptiveScopeConfig` and open
**Flutter DevTools → Performance** while the warm-up benchmark runs (~3 seconds after launch):

```dart
onQualityChanged: (from, to) {
  debugPrint('📊 liquid_glass: $from → $to');
}
```

| Metric | Value |
|---|---|
| **P75 raster time (ms)** | from DevTools Performance tab |
| **P95 raster time (ms)** | from DevTools Performance tab |
| **Avg raster time (ms)** | from DevTools Performance tab |

---

### App Context *(optional)*

- Number of glass widgets visible during warm-up: ~
- Quality modes used: `standard` / `premium` / mixed
- `targetFrameMs` override (if any): 

---

### Console Output

Paste the `debugPrint` output from the snippet above:

```
📊 liquid_glass: premium → standard
   Device: Pixel 6a / Android 14
```
