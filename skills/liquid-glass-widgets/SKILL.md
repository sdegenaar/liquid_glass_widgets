---
name: liquid-glass-widgets
description: "Mastery guide and architectural rules for liquid_glass_widgets. Trigger whenever generating, refactoring, or reviewing Flutter UI code using liquid glass, iOS 26 aesthetics, GlassScaffold, GlassTabBar, GlassModalSheet, or any Glass* components."
---

# Liquid Glass Widgets — AI Agent Guide

This skill defines the architecture, design principles, API dictionary, and strict implementation rules for building Flutter applications with `liquid_glass_widgets`.

Follow this guide strictly when writing, refactoring, or reviewing UI code to ensure high visual fidelity, 60/120 fps GPU performance, and zero hallucinations.

---

## 1. Golden Architectural Rules (Mandatory)

### Rule 1: Glass is a Platter, Not a Wrapper
Glass in the iOS 26 design system is reserved for the **navigation and control layer** — floating chrome that sits above content.
- **DO use glass for:** Navigation bars (`GlassAppBar`), tab bars (`GlassTabBar`), floating buttons (`GlassButton`, `GlassIconButton`), toolbars, modal sheets (`GlassModalSheet`), dialogs (`GlassDialog`), and standalone floating cards (`GlassCard`).
- **DO NOT use glass for:** Full-screen backgrounds, dense list view items, video players, image galleries, or text article bodies. Backgrounds should be rich wallpapers or gradients; content cards should be clean and readable.

### Rule 2: NEVER Nest Refractive Glass inside Refractive Glass
Placing refractive glass widgets inside another refractive glass container is an optical and performance anti-pattern.
- **CRITICAL ANTI-PATTERN:** Placing `GlassButton`, `GlassIconButton`, `GlassSegmentedControl`, `GlassSlider`, or `GlassSwitch` inside a `GlassCard`, `GlassGroupedSection`, or `GlassContainer`.
- **Why?** Interactive glass controls provide their own refractive surface. Nesting creates severe double-refraction distortion, clips spring jelly animations, and wastes GPU fill-rate.
- **Correct Pattern:**
  - In a `GlassCard` or `GlassGroupedSection`: Use standard text, icons, and non-refractive controls (or `GlassListTile` which is specifically designed without an internal glass layer).
  - Outside the card / on the page platter: Use `GlassSegmentedControl`, `GlassButton`, `GlassSlider`, or standalone `GlassSwitch(useOwnLayer: true)`.

### Rule 3: Single Public Import
- **ALWAYS**: `import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';`
- **NEVER** import `package:liquid_glass_widgets/src/...`.
- **NEVER** instantiate `LiquidGlass(...)` directly — it is an internal Impeller-only renderer. Always use `AdaptiveGlass` or the high-level `Glass*` widgets.

### Rule 4: Ban Obsolete Pre-1.0 APIs
- `GlassBottomBar` and `GlassSearchableBottomBar` were **deleted** in v1.0.0.
- **ALWAYS USE**: `GlassTabBar.bottom(...)` or `GlassTabBar.searchable(...)`.

### Rule 5: Honor Quality Tiers
- **`GlassQuality.standard`**: Default for 95% of controls, cards, and input fields. Uses a highly optimized single-pass fragment shader.
- **`GlassQuality.premium`**: Multi-pass Impeller shader with chromatic dispersion, realistic refraction, and dynamic specular highlights. Reserved for persistent navigation bars (`GlassAppBar`, `GlassTabBar`) and hero surfaces. `GlassScaffold` automatically promotes its bars to premium.
- **`GlassQuality.minimal`**: Lightweight shader-free fallback (`BackdropFilter` only). Use for ultra-dense scrolling lists or low-power modes.

---

## 2. App Lifecycle & Initialization

In `main.dart`, always initialize the shader pipeline before `runApp()`, and wrap the application with `LiquidGlassWidgets.wrap()`.

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-warms fragment shaders in parallel to prevent first-frame white flashes or shader jank
  await LiquidGlassWidgets.initialize();

  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true, // Dynamically benchmarks device raster budget and scales quality
      respectSystemAccessibility: true, // Automatically degrades on Reduce Motion / Reduce Transparency

      // CRITICAL FOR MATERIAL APPS: Bridges Material ThemeMode without importing flutter/material in the engine
      brightnessResolver: Theme.maybeBrightnessOf,

      // GlassThemeData.simple is the recommended constructor — applies the same settings to
      // both light and dark, overlaid on the library's built-in per-mode defaults.
      // Use GlassThemeData(light: ..., dark: ...) only for fine-grained per-mode control.
      theme: GlassThemeData.simple(
        blur: 12,
        thickness: 25,
        quality: GlassQuality.standard,
      ),
      child: const MyApp(),
    ),
  );
}
```

---

## 3. Screen Architecture: `GlassScaffold`

For any screen featuring liquid glass navigation bars or floating surfaces, **always use `GlassScaffold` instead of Flutter's built-in `Scaffold`**.

`GlassScaffold` solves complex compositing challenges automatically:
1. **Guaranteed Z-Ordering**: App bars and bottom bars paint above scrolling body content, preventing body cards from overlapping navigation buttons.
2. **Edge Fading**: Content fades smoothly as it scrolls under bars (`.scrollEdgeEffectStyle(.soft)` matching iOS 26).
3. **Content-Aware Brightness**: Dynamically flips app bar icons and typography between light and dark depending on the luminosity of the content scrolling underneath.
4. **Auto-Padding**: Automatically accounts for safe areas and bar heights.

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      // 1. Wallpaper background (image, gradient, or solid)
      background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
      contentAwareBrightness: true,

      // 2. Navigation Bar
      // GlassAppBar uses `actions` (List<Widget>), not `trailing`.
      appBar: GlassAppBar(
        title: const Text('Dashboard'),
        actions: [
          GlassIconButton(
            icon: const Icon(CupertinoIcons.bell_fill),
            onPressed: () => _openNotifications(),
          ),
        ],
      ),

      // 3. Unified Bottom Tab Bar
      bottomBar: GlassTabBar.bottom(
        selectedIndex: _selectedTab,
        onTabSelected: (index) => setState(() => _selectedTab = index),
        tabs: const [
          GlassTab(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
          GlassTab(icon: Icon(CupertinoIcons.chart_bar_fill), label: 'Stats'),
          GlassTab(icon: Icon(CupertinoIcons.gear_alt_fill), label: 'Settings'),
        ],
      ),

      // 4. Scrollable Body Content
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Content cards stay opaque or use GlassCard for grouping
          GlassGroupedSection(
            header: const Text('ACCOUNT'),
            children: [
              GlassListTile(
                leading: const Icon(CupertinoIcons.person_fill),
                title: const Text('Profile'),
                trailing: GlassListTile.chevron,
                onTap: () {},
              ),
              GlassListTile(
                leading: const Icon(CupertinoIcons.lock_shield_fill),
                title: const Text('Privacy & Security'),
                trailing: GlassListTile.chevron,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Component Dictionary & Substitution Table

When generating Flutter UI, replace standard Flutter widgets with their native liquid glass counterparts:

| Flutter Standard Widget | Liquid Glass Replacement | Key Usage Notes |
| :--- | :--- | :--- |
| `Scaffold` | `GlassScaffold` | Handles z-order, edge fading, content-aware brightness. |
| `AppBar` / `CupertinoNavigationBar` | `GlassAppBar` | Transparent iOS 26 style by default. Supports `.pinned` for gel morph. |
| `BottomNavigationBar` / `CupertinoTabBar` | `GlassTabBar.bottom` | Unified glass navigation pill. `GlassBottomBar` is deleted. |
| Bottom nav that collapses to selected tab on scroll | `GlassTabBar.minimizable` | Minimizes to a single pill on scroll; supports an optional trailing action button. |
| `ElevatedButton` / `CupertinoButton` | `GlassButton` | Refractive button with squeeze & stretch physics and touch glow. |
| `IconButton` | `GlassIconButton` | Refractive circular/squircle button with `onPressed`. |
| `PopupMenuButton` / Context Menu | `GlassPullDownButton` | Combined trigger button and `GlassMenu`. |
| `CupertinoSegmentedControl` | `GlassSegmentedControl<T>` | Fluid animated glass indicator with jelly physics. Do NOT wrap in `GlassCard`. |
| `Switch` / `CupertinoSwitch` | `GlassSwitch` | Fluid spring jump animation. Use `useOwnLayer: true` when standalone. |
| `Slider` / `CupertinoSlider` | `GlassSlider` | Glass track with draggable jelly thumb and haptic snaps. |
| `Card` | `GlassCard` | Glass container for grouping content. Content inside stays opaque. |
| Grouped `ListView` | `GlassGroupedSection` | Inset grouped list container with automatic dividers between `GlassListTile`s. |
| `ListTile` | `GlassListTile` | Grouped row item. Shares parent glass layer inside `GlassGroupedSection`. |
| `Divider` | `GlassDivider` | Refractive subtle separator line. |
| `TextField` / `CupertinoTextField` | `GlassTextField` | Input field with glowing refractive focus border. |
| `showModalBottomSheet` | `GlassModalSheet.show` | Multi-detent fluid sheet (peek, half, full) with spring physics. |
| `showDialog` / `CupertinoAlertDialog` | `GlassDialog.show` | Liquid glass modal alert with `GlassDialogAction` buttons. |
| `SnackBar` / Banner | `GlassToast` | Floating glass HUD banner. |

---

## 5. Overlays: Modal Sheets, Dialogs & Transitions

### GlassModalSheet
Presents an iOS 26 fluid modal sheet with detents:

```dart
GlassModalSheet.show(
  context: context,
  initialState: GlassSheetState.half,
  halfSize: 0.5,
  peekSize: 90.0,
  builder: (sheetContext) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Modal Sheet Content',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  },
);
```

### GlassDialog
Presents a native alert dialog:

```dart
GlassDialog.show(
  context: context,
  title: 'Discard Draft?',
  message: 'This action cannot be reversed.',
  actions: [
    GlassDialogAction(
      label: 'Cancel',
      onPressed: () => Navigator.of(context).pop(),
    ),
    GlassDialogAction(
      label: 'Discard',
      isDestructive: true,
      onPressed: () {
        Navigator.of(context).pop();
        _discardDraft();
      },
    ),
  ],
);
```

### GlassMaterialize
For widgets appearing or disappearing dynamically, use `GlassMaterialize` to match iOS 26's progressive defogging transition:

```dart
GlassMaterialize(
  visible: _showFilterPill,
  // GlassChip.label is a String, not a Widget
  child: GlassChip(
    label: 'Active Filters',
    onDeleted: () => setState(() => _showFilterPill = false),
  ),
)
```

---

## 6. Advanced Navigation: Gel Morph with `GlassNavigationShell`

To achieve the signature iOS 26 navigation bar transition — where the capsule swells, bounces, and cross-fades icons between routes:

1. **Wrap the Navigator** in `GlassNavigationShell` (typically in `CupertinoApp.builder`):

```dart
CupertinoApp(
  builder: (context, child) => GlassNavigationShell(child: child!),
  home: const HomeScreen(),
)
```

2. Use `GlassAppBar.pinned` on destination screens. Items are declared as `GlassBarItem` data (not arbitrary widgets), which allows the shell to hoist them above the `Navigator` and morph them across routes:

```dart
GlassAppBar.pinned(
  title: const Text('Detail'),
  actions: [
    // GlassBarItem.icon uses `onTap` (not `onPressed`)
    GlassBarItem.icon(
      icon: const Icon(CupertinoIcons.square_and_arrow_up),
      onTap: () => _share(),
    ),
  ],
)
```

> **Note:** Without `GlassNavigationShell`, `GlassAppBar.pinned` falls back gracefully — items render inside the bar in-route, so all screens work either way.

---

## 7. Common Agent Pitfalls (Checklist before outputting code)

- [ ] **Did you import the public API only?** (`import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';`). Never import `src/`.
- [ ] **Did you call `await LiquidGlassWidgets.initialize()` in `main()`?** Shaders must be pre-warmed.
- [ ] **Did you wrap your app in `LiquidGlassWidgets.wrap()`?** Required for theme and accessibility scaling.
- [ ] **Are you using `GlassScaffold` instead of `Scaffold`?** Prevents z-index glitches with glass nav bars.
- [ ] **Did you avoid nesting glass in glass?** Never put `GlassButton`, `GlassSlider`, or `GlassSwitch` directly inside `GlassCard` or `GlassGroupedSection`.
- [ ] **Did you use `GlassTabBar.bottom` instead of `GlassBottomBar`?** `GlassBottomBar` is deleted.
- [ ] **`GlassButton` uses `onTap`, not `onPressed`.** (`GlassButton(onTap: () {})`) — the opposite of `ElevatedButton`.
- [ ] **`GlassIconButton` uses `onPressed`, not `onTap`.** (`GlassIconButton(onPressed: () {})`).
- [ ] **`GlassAppBar` uses `actions: [...]` (a List), not `trailing:`.** There is no `trailing` parameter.
- [ ] **`GlassChip.label` is a `String`, not a `Widget`.** Pass `label: 'text'`, not `label: Text('text')`.
- [ ] **`GlassBarItem.icon` uses `onTap` (required), not `onPressed`.**
