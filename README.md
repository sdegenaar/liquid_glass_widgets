# Liquid Glass Widgets

Bring Apple's iOS 26 Liquid Glass to your Flutter app — 37 glass widgets with real shader-based blur, physics-driven jelly animations, and dynamic lighting. Works on every platform out of the box.

[![pub package](https://img.shields.io/pub/v/liquid_glass_widgets.svg)](https://pub.dev/packages/liquid_glass_widgets)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


https://github.com/user-attachments/assets/2fe28f46-96ad-459d-b816-e6d6001d90de

*[Wanderlust](example/showcase/) — a luxury travel showcase built entirely with `liquid_glass_widgets`*


## Features

- **37 glass widgets** — containers, interactive controls, inputs, feedback, overlays, and navigation surfaces
- **Real frosted glass** — native two-pass Gaussian blur + shader refraction on Impeller; lightweight shader on Skia/Web
- **Just works everywhere** — iOS, Android, macOS, Web, Windows, Linux; rendering path chosen automatically
- **Zero dependencies** — no third-party runtime libraries, just the Flutter SDK
- **One-line setup** — `LiquidGlassWidgets.wrap()` handles all performance optimization
- **Gyroscope lighting** — `GlassMotionScope` drives specular highlights from any `Stream<double>`
- **WCAG-compliant by default** — Reduce Motion and Reduce Transparency are respected automatically; no setup required


## Examples

### [Wanderlust](example/showcase/) — Luxury Travel Showcase

A premium app demonstrating `liquid_glass_widgets` in a real-world production context — full-bleed imagery, parallax scroll, hero transitions, and a concierge chat interface. **This is the app shown in the video above.**

```bash
cd example/showcase && flutter pub get && flutter run
```

### [Apple News Demo](example/lib/apple_news/) — iOS 26 Replica

A recreation of the Apple News app demonstrating `GlassSearchableBottomBar` with its morphing search pill, category chips, hero cards, and rounded article tiles.

```bash
cd example && flutter pub get && flutter run -t lib/apple_news/apple_news_demo.dart
```

<img width="390" alt="Apple News Demo" src="https://github.com/user-attachments/assets/8da8f118-e5f8-40e0-9b0e-d4cd5633a5cf" />

### [Widget Showcase](example/) — Full Component Library

A complete catalogue of all 37 widgets organized by category. Use it to explore every component, try live settings, and copy patterns directly into your app.

```bash
cd example && flutter pub get && flutter run
```

<img width="1280" height="589" alt="Widget Showcase" src="https://github.com/user-attachments/assets/b65551cf-7ee8-4494-9c0a-f3c870b5eb70" />


## Widget Categories

### Containers
`GlassCard` · `GlassPanel` · `GlassContainer` · `GlassDivider` · `GlassListTile` · `GlassStepper` · `GlassWizard`

### Interactive
`GlassButton` · `GlassIconButton` · `GlassChip` · `GlassSwitch` · `GlassSlider` · `GlassSegmentedControl` · `GlassPullDownButton` · `GlassButtonGroup` · `GlassBadge`

### Input
`GlassTextField` · `GlassTextArea` · `GlassPasswordField` · `GlassSearchBar` · `GlassPicker` · `GlassFormField`

### Feedback
`GlassProgressIndicator` · `GlassToast` · `GlassSnackBar`

### Overlays
`GlassDialog` · `GlassSheet` · `GlassActionSheet` · `GlassMenu` · `GlassMenuItem`

### Surfaces
`GlassAppBar` · `GlassBottomBar` · `GlassSearchableBottomBar` · `GlassTabBar` · `GlassSideBar` · `GlassToolbar`


## Installation

```yaml
dependencies:
  liquid_glass_widgets: ^0.7.9
```

```bash
flutter pub get
```


## Quick Start

Initialize the library once in `main.dart`. This pre-caches shaders (eliminates first-render flash) and activates GPU backdrop sharing for multi-glass screens:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();

  // wrap() ensures all glass surfaces share one GPU backdrop capture on Impeller.
  // Safe to use on all platforms — no-op on Skia/Web.
  runApp(LiquidGlassWidgets.wrap(const MyApp()));
}
```

> **Accessibility is on by default.** The library automatically reads the device's Reduce Motion and Reduce Transparency settings — no extra setup required. See [Accessibility](#accessibility) for details.

Then add any glass widget to your tree:

```dart
Scaffold(
  appBar: GlassAppBar(title: const Text('My App')),
  bottomNavigationBar: GlassBottomBar(
    tabs: [
      GlassBottomBarTab(label: 'Home', icon: const Icon(Icons.home)),
      GlassBottomBarTab(label: 'Profile', icon: const Icon(Icons.person)),
    ],
    selectedIndex: 0,
    onTabSelected: (i) {},
  ),
  body: const Center(child: GlassCard(child: Text('Hello, Glass!'))),
)
```


## Platform Support

| Platform | Renderer | Notes |
|---|---|---|
| iOS | Impeller (Metal) | Full shader pipeline, chromatic aberration |
| Android | Impeller (Vulkan) | Full shader pipeline, chromatic aberration |
| macOS | Impeller (Metal) | Full shader pipeline, chromatic aberration |
| Web | CanvasKit | Lightweight fragment shader |
| Windows | Skia | Lightweight fragment shader |
| Linux | Skia | Lightweight fragment shader |

Platform detection is automatic — no configuration required.


## Glass Quality Modes

### Standard — Default, Recommended

The right choice for 95% of use cases. Works on every platform with iOS 26-accurate glass effects.

```dart
GlassContainer(
  quality: GlassQuality.standard, // this is the default
  child: const Text('Great for scrollable content'),
)
```

### Premium — Impeller Only

Enables the full Impeller shader pipeline with texture capture and chromatic aberration. On Skia/Web, automatically falls back to Standard.

```dart
GlassAppBar(
  quality: GlassQuality.premium,
  title: const Text('Static header'),
)
```

> **Use Premium only for static, non-scrolling surfaces** (app bars, bottom bars, hero sections). It may not render correctly inside `ListView` or `CustomScrollView` on Impeller.


## Theming

All widgets automatically inherit from `GlassTheme` and adapt to light/dark mode:

```dart
GlassTheme(
  data: GlassThemeData(
    light: GlassThemeVariant(
      settings: LiquidGlassSettings(thickness: 30, blur: 12),
      quality: GlassQuality.standard,
    ),
    dark: GlassThemeVariant(
      settings: LiquidGlassSettings(thickness: 50, blur: 18),
      quality: GlassQuality.premium,
    ),
  ),
  child: MaterialApp(home: MyHomePage()),
)
```

Access the current theme variant programmatically:

```dart
final variant = GlassThemeData.of(context).variantFor(context);
```

### Specular Sharpness

Control the tightness of the specular highlight on any glass surface via `LiquidGlassSettings.specularSharpness`:

```dart
GlassCard(
  settings: LiquidGlassSettings(
    specularSharpness: GlassSpecularSharpness.sharp, // tight, mirror-like
  ),
  child: ...,
)
```

| Value | Look |
|---|---|
| `GlassSpecularSharpness.soft` | Wide, diffuse — frosted / matte glass |
| `GlassSpecularSharpness.medium` | **Default** — matches iOS 26 |
| `GlassSpecularSharpness.sharp` | Tight, polished — mirror-like surface |

Each value maps to a fixed power-of-2 exponent. The GPU uses a zero-transcendental multiply chain for each — no `pow()` overhead.


## Performance Tips

1. **`LiquidGlassWidgets.initialize()`** at startup — pre-caches shaders, eliminates the white flash on first render
2. **`LiquidGlassWidgets.wrap()`** in `main.dart` — all glass surfaces inside automatically share one GPU backdrop capture on Impeller (equivalent to wrapping with `GlassBackdropScope` directly, which also remains available for explicit scope control)
3. **Standard quality for scrollable content** — lists, forms, interactive widgets
4. **Premium quality for fixed surfaces** — app bars, bottom bars, and hero sections
5. **Accessibility fallbacks are zero-cost** — when Reduce Transparency is active, the glass shader is bypassed entirely; `BackdropFilter` blur runs in Flutter's own paint layer with no custom shader overhead


## Custom Refraction for Interactive Indicators

On Skia and Web, interactive widgets like `GlassSegmentedControl` can display
true liquid glass refraction. Use `GlassRefractionSource` to mark the capture
surface (or use the `LiquidGlassScope.stack()` shorthand for the common
wallpaper-behind-content pattern):

```dart
// Shorthand — wallpaper behind your Scaffold:
LiquidGlassScope.stack(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  content: Scaffold(
    body: Center(
      child: GlassSegmentedControl(
        segments: const ['Option A', 'Option B', 'Option C'],
        selectedIndex: 0,
        onSegmentSelected: (i) {},
        quality: GlassQuality.standard,
      ),
    ),
  ),
)

// Manual — granular control over which surface is sampled:
LiquidGlassScope(
  child: Stack(
    children: [
      Positioned.fill(
        child: GlassRefractionSource(
          child: Image.asset('assets/wallpaper.jpg'),
        ),
      ),
      Center(child: GlassSegmentedControl(...)),
    ],
  ),
)
```

On Impeller, `GlassQuality.premium` uses the native scene graph — no
`LiquidGlassScope` needed.

> **Migration note (0.7.0):** `LiquidGlassBackground` was renamed to
> `GlassRefractionSource`. The old name still compiles (deprecated typedef)
> and will be removed in 1.0.0.

| When | Recommendation |
|---|---|
| Skia / Web | `LiquidGlassScope.stack` with `GlassQuality.standard` |
| iOS / macOS (Impeller) | `GlassQuality.premium` — native scene graph |
| Multiple isolated sections | Separate `LiquidGlassScope` per section |


## Gyroscope Lighting

`GlassMotionScope` drives the specular highlight angle from any `Stream<double>`, including a device gyroscope via [`sensors_plus`](https://pub.dev/packages/sensors_plus):

```dart
GlassMotionScope(
  stream: gyroscopeEvents.map((e) => e.y * 0.5),
  child: Scaffold(
    appBar: GlassAppBar(title: const Text('My App')),
    body: ...,
  ),
)
```

No new dependencies required — connect any stream source (scroll position, mouse, gyroscope).


## Accessibility

Every glass widget in this package respects the user's system accessibility preferences **automatically** — no setup required.

| System Setting | Effect on glass widgets |
|---|---|
| **Reduce Motion** (iOS/macOS/Android) | All spring/jelly animations snap instantly to their target |
| **Reduce Transparency / High Contrast** | Glass shader replaced with a plain frosted `BackdropFilter` panel — zero GPU shader cost |

### No setup needed

Just ship your app. If the user has Reduce Motion on, your widgets snap. If they have Reduce Transparency on, they get a solid frosted fallback. Nothing to configure.

### Optional: `GlassAccessibilityScope`

Place `GlassAccessibilityScope` in your tree to **override** system defaults — useful for testing, showcases, or per-subtree customisation:

```dart
// In your app (optional — place inside MaterialApp.builder for full coverage)
MaterialApp(
  builder: (context, child) => GlassAccessibilityScope(
    child: child!, // reads system flags automatically
  ),
)

// Force a specific state (e.g. demo frosted fallback in a settings screen)
GlassAccessibilityScope(
  reduceTransparency: true,
  child: GlassSettingsPreview(),
)
```

`GlassAccessibilityScope` always wins over the system flag — it's the highest-priority override.

### Opting out globally

For experiences where full glass fidelity is intentional (games, creative tools):

```dart
await LiquidGlassWidgets.initialize(
  respectSystemAccessibility: false, // ignores system Reduce Motion / Reduce Transparency
);
```

This disables only the automatic system-flag bridge. An explicit `GlassAccessibilityScope` in the widget tree still works regardless.

### Priority order (highest wins)

1. `GlassAccessibilityScope` in the widget tree — explicit developer override
2. System `MediaQuery` flags — automatic, respects user's OS setting
3. `initialize(respectSystemAccessibility: false)` — disables (2) globally


## Architecture

On Impeller, every `GlassQuality.premium` surface uses a two-pass pipeline:

1. **Blur pass** — `BackdropFilterLayer(ImageFilter.blur)`, clipped to the exact widget shape. Shared across all surfaces inside a `GlassBackdropScope` (injected automatically by `LiquidGlassWidgets.wrap()`).
2. **Shader pass** — `BackdropFilterLayer(ImageFilter.shader)` — refraction, edge lighting, glass tint, and chromatic aberration.

On Skia/Web, `lightweight_glass.frag` runs as a single pass with no backdrop capture.

### Content-Adaptive Glass Strength (0.7.0)

Both render paths automatically adapt glass strength to background brightness:

- **Dark backgrounds** → richer, more opaque glass (1.2× strength, brighter Fresnel rim)
- **Light backgrounds** → subtler, more translucent glass (0.8× strength)

On Impeller, backdrop luminance is sampled directly from the refracted texture (zero extra reads).
On Skia/Web, `MediaQuery.platformBrightnessOf` provides a lightweight proxy.


## Testing

```bash
# All tests
flutter test

# Exclude golden tests
flutter test --exclude-tags golden

# macOS golden tests (require Impeller)
flutter test --tags golden
```


## Dependencies

Zero third-party runtime dependencies beyond the Flutter SDK.

The glass rendering pipeline builds on the open-source work of [whynotmake-it](https://github.com/whynotmake-it). Their [`liquid_glass_renderer`](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer) (MIT) has been vendored and extended with bug fixes, performance improvements, and shader optimisations.


## Contributing

Contributions are welcome. For major changes, open an issue first to discuss your proposal.


## License

MIT — see the [LICENSE](LICENSE) file for details.


## Credits

**Special thanks** to the [whynotmake-it](https://github.com/whynotmake-it) team for their [`liquid_glass_renderer`](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer) (MIT), whose shader pipeline, texture capture, and chromatic aberration work forms the foundation of the rendering engine in this library.

## Links

- [pub.dev](https://pub.dev/packages/liquid_glass_widgets)
- [Repository](https://github.com/sdegenaar/liquid_glass_widgets)
- [Issue Tracker](https://github.com/sdegenaar/liquid_glass_widgets/issues)
