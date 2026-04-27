# Complete Guide to GlassModalSheet

This document provides an exhaustive description of all parameters for the `GlassModalSheet` widget. It is intended for developers and AI agents to deeply understand the customization capabilities of the liquid glass modal sheet system.

---

## 1. Core Parameters (Content & Core)

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `child` | `Widget` | The primary content widget displayed inside the glass sheet. |
| `padding` | `EdgeInsetsGeometry?` | Internal padding for the sheet content. |
| `initialState` | `SheetState` | Initial state when opened: `peek`, `half`, or `full`. Defaults to `half`. |
| `controller` | `GlassModalSheetController?` | Controller for programmatic control (state switching, animations). |
| `onStateChanged` | `ValueChanged<SheetState>?` | Callback triggered when the sheet snaps to a new state. |

---

## 2. Geometry & Dimensions (Geometry)

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `halfSize` | `double` | Height in the `half` state. Can be a fraction (0.45) or absolute pixels. Defaults to `0.45`. |
| `fullSize` | `double?` | Maximum height in `full`. If `null`, defaults to iOS standard (screen height minus 90px). |
| `peekSize` | `double` | Fixed height of the "peek" (handle) state in pixels. Defaults to `90.0`. |
| `horizontalMargin` | `double` | Horizontal padding between the sheet and the screen edges. Defaults to `8.0`. |
| `bottomMargin` | `double` | Bottom padding from the screen edge. Defaults to `8.0`. |

### Border Radius
Logic:
1. If the parameter is explicitly provided — that value is used (**Custom**).
2. If the parameter is `null` — the system automatically calculates the ideal radius based on device geometry (**Adaptive**).

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `topBorderRadius` | `double?` | Base radius for top corners in `peek` and `half` states. |
| `bottomBorderRadius` | `double?` | Base radius for bottom corners. |
| `fullTopBorderRadius` | `double?` | Top corner radius when fully expanded (`full`). Defaults to `46.0`. |
| `fullBottomBorderRadius` | `double?` | Bottom corner radius when fully expanded. Defaults to `bottomBorderRadius`. |

---

## 3. Visual Effects (Appearance)

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `settings` | `LiquidGlassSettings?` | Base glass settings: `thickness`, `blur`, `refractiveIndex`, `chromaticAberration`, etc. |
| `quality` | `GlassQuality?` | Rendering quality: `standard`, `premium`, `minimal`. |
| `expandedColor` | `Color?` | Background color used when the sheet becomes opaque in `full` state. |
| `fillThreshold` | `double` | Progress threshold (0.0-1.0) for transition to solid color. Defaults to `0.60`. |
| `fillTransition` | `FillTransition` | Transition type: `instant` or `gradual`. Defaults to `instant`. |
| `forceSpecularRim` | `bool` | Whether to force the specular rim on Skia/Web. Defaults to `true`. |

### State-Specific Settings
- `peekSettings`, `halfSettings`, `fullSettings`: Overrides base `settings` for specific states.

---

## 4. Keyboard Handling & Focus

- **Automatic Expansion**: When a user taps a `TextField` inside the sheet, the sheet will automatically and smoothly snap to the `full` state.
- **Integration**: Works "out of the box" via an internal `Focus` bridge.

---

## 5. Advanced Content Handling (Lists & Scrolling)

### Top Fade Effect
- `enableTopFade`: Enables gradient content fading at the top in `full` mode. Defaults to `false`.
- `topFadeHeight`: Height of the fade zone. Defaults to `40.0`.

### Vibrancy in Full State
- `maintainContentGlass`: Maintains glass effect for internal elements even if the sheet becomes opaque. Defaults to `true`.
- `fullStateContentSettings`: Custom glass settings for content specifically for the `full` state.

---

## 6. Interaction & Tactile Feedback (Interaction)

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `interactionScale` | `double` | Scale factor applied on touch. Defaults to `1.01`. |
| `enableInteractionGlow` | `bool` | Enables a dynamic light glow at the touch point. Defaults to `true`. |
| `enableSaturationGlow` | `bool` | Enables a saturation/lighting pulse on touch. Defaults to `true`. |
| `glowColor` | `Color?` | Custom color for the tactile interaction glow. |
| `glowRadius` | `double` | Radius of the interaction glow. Defaults to `1.5`. |
| `suppressInteractionOnChildren` | `bool` | **Smart Silence**: interacting with internal elements won't scale the whole sheet. |

---

## 7. Physics & Gestures (Physics)

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `mode` | `SheetMode` | `dismissible` or `persistent`. Defaults to `dismissible`. |
| `enablePeek` | `bool?` | Whether the `peek` state is allowed. Defaults based on `mode`. |
| `stretch` | `double` | Elasticity multiplier. Defaults to `0.5`. |
| `resistance` | `double` | Resistance when dragging beyond bounds. Defaults to `0.08`. |
| `snapThreshold` | `double` | Threshold to snap to the next state. Defaults to `0.4`. |
| `velocityThreshold` | `double` | Velocity threshold for flick gestures. Defaults to `700.0`. |

---

## 8. Usage Examples

### Example 1: Lists with Fade
```dart
GlassModalSheet.show(
  context: context,
  enableTopFade: true,
  maintainContentGlass: true,
  builder: (context) => ListView(...),
);
```

### Example 2: Maps-Style Mode
```dart
GlassModalSheet.show(
  context: context,
  mode: SheetMode.persistent,
  suppressInteractionOnChildren: true,
  builder: (context) => MyContent(),
);
```

---

## 9. show() Method Parameters

- `context`: BuildContext (required).
- `builder`: WidgetBuilder (required).
- `isDismissible`: Close by tapping the barrier. Defaults to `true`.
- `barrierColor`: Overlay background color. Defaults to `black54`.
- `useRootNavigator`: Whether to use the root navigator. Defaults to `false`.
