# Migration Guide: Upgrading from 0.x to 1.0.0

`liquid_glass_widgets` 1.0.0 stabilizes the public API, removes deprecated transitional shims, and establishes a clean, unified architecture for production use.

This guide details all breaking changes between `0.30.x` and `1.0.0` and provides step-by-step instructions for upgrading your codebase.

---

## Summary of Breaking Changes

| Deprecated / Old API (0.x) | 1.0.0 Replacement | Rationale |
|---|---|---|
| `GlassBottomBar(...)` | `GlassTabBar.bottom(...)` | Unified under `GlassTabBar` navigation widget |
| `GlassSearchableBottomBar(...)` | `GlassTabBar.searchable(...)` | Unified under `GlassTabBar` navigation widget |
| `GlassBottomBarTab(...)` | `GlassTab(...)` | Canonical tab representation across all tab bars |
| `GlassBottomBarCollapseConfig` | Removed — use `GlassTabBar.minimizable` | Collapse-to-button pattern is not an iOS 26 design primitive |
| `GlassBottomBarCollapseDirection` | Removed — use `GlassTabBar.minimizable` | See above |
| `GlassModalSheet(enablePeek: ...)` | Removed (use `detents` and `mode`) | Sheet geometry derived directly from detents |
| `LiquidGlassWidgets.initialize(respectsAccessibility: ...)` | Removed (automatic) | System accessibility preferences detected natively |
| `LiquidGlassWidgets.initialize(warmUpImpellerPipeline: ...)` | Removed | Shaders are pre-warmed automatically via AOT runtime |
| `GlassQuality.usesBackdropFilter` | Removed | Redundant internal implementation detail |
| `LiquidGlassScope.stack` | `GlassPage` or `GlassBackgroundSource` | Modern layer composition architecture |
| `GlassBackdropScope` | Removed (no-op stub) | No longer required in Impeller/Skia pipelines |

---

## Detailed Migration Steps

### 1. Navigation Surface Unification: `GlassBottomBar` → `GlassTabBar`

In 1.0.0, navigation bars are consolidated into `GlassTabBar` via named constructors:
- `GlassTabBar.bottom(...)` replaces `GlassBottomBar(...)`
- `GlassTabBar.searchable(...)` replaces `GlassSearchableBottomBar(...)`
- `GlassTab` replaces `GlassBottomBarTab`

#### Before (0.x):
```dart
GlassBottomBar(
  tabs: const [
    GlassBottomBarTab(icon: Icon(Icons.home), label: 'Home'),
    GlassBottomBarTab(icon: Icon(Icons.search), label: 'Search'),
  ],
  selectedIndex: _selectedIndex,
  onTabSelected: (index) => setState(() => _selectedIndex = index),
  collapseConfig: GlassBottomBarCollapseConfig(
    direction: GlassBottomBarCollapseDirection.towardsExtraButton,
  ),
)
```

#### After (1.0.0):
```dart
GlassTabBar.bottom(
  tabs: const [
    GlassTab(icon: Icon(Icons.home), label: 'Home'),
    GlassTab(icon: Icon(Icons.search), label: 'Search'),
  ],
  selectedIndex: _selectedIndex,
  onTabSelected: (index) => setState(() => _selectedIndex = index),
)
```

---

### 2. Searchable Tab Bar: `GlassSearchableBottomBar` → `GlassTabBar.searchable`

#### Before (0.x):
```dart
GlassSearchableBottomBar(
  tabs: _tabs,
  selectedIndex: _selectedIndex,
  onTabSelected: (index) => setState(() => _selectedIndex = index),
  isSearchActive: _isSearchActive,
  searchConfig: GlassSearchBarConfig(
    onSearchToggle: (active) => setState(() => _isSearchActive = active),
    hintText: 'Search items...',
  ),
)
```

#### After (1.0.0):
```dart
GlassTabBar.searchable(
  tabs: _tabs,
  selectedIndex: _selectedIndex,
  onTabSelected: (index) => setState(() => _selectedIndex = index),
  isSearchActive: _isSearchActive,
  searchConfig: GlassSearchBarConfig(
    onSearchToggle: (active) => setState(() => _isSearchActive = active),
    hintText: 'Search items...',
  ),
)
```

---

### 3. Modal Sheet Geometry: `enablePeek` Removal

`enablePeek` was a legacy flag. In 1.0.0, sheet sizing and peeking behavior is controlled directly and declaratively by `detents` and `mode`.

#### Before (0.x):
```dart
GlassModalSheet.show(
  context: context,
  enablePeek: true,
  detents: const {
    GlassSheetDetent.medium,
    GlassSheetDetent.large,
  },
  builder: (context) => const MySheetContent(),
);
```

#### After (1.0.0):
```dart
GlassModalSheet.show(
  context: context,
  detents: const {
    GlassSheetDetent.medium,
    GlassSheetDetent.large,
  },
  builder: (context) => const MySheetContent(),
);
```

---

### 4. Initialization & Setup: `LiquidGlassWidgets.initialize`

The deprecated `respectsAccessibility` and `warmUpImpellerPipeline` parameters have been removed from `LiquidGlassWidgets.initialize()`.

- Accessibility (Reduce Motion, Reduce Transparency) is now **automatically respected** across all platforms according to system settings and `MediaQuery`.
- Pipeline warmup is handled natively at engine startup.

#### Before (0.x):
```dart
LiquidGlassWidgets.initialize(
  respectsAccessibility: true,
  warmUpImpellerPipeline: true,
);
```

#### After (1.0.0):
```dart
LiquidGlassWidgets.initialize();
```

---

### 5. `LiquidGlassScope.stack` and `GlassBackdropScope`

- `LiquidGlassScope.stack` and `GlassRefractionSource` have been replaced by `GlassPage` or `GlassBackgroundSource` for declarative background lighting and refraction.
- `GlassBackdropScope` (and the `glass_backdrop_scope.dart` file) has been deleted. Remove any imports or usages of `GlassBackdropScope`.

---

## Verification

After updating your code:

```bash
# 1. Confirm no stale imports or missing types
dart analyze

# 2. Run your test suite
flutter test

# 3. Quick smoke test — these should all compile and run without errors
flutter run
```

Common errors and their fixes:

| Error | Fix |
|---|---|
| `GlassBottomBar` undefined | Replace with `GlassTabBar.bottom(...)` |
| `GlassSearchableBottomBar` undefined | Replace with `GlassTabBar.searchable(...)` |
| `GlassBottomBarTab` undefined | Replace with `GlassTab(...)` |
| `enablePeek` named parameter not found | Remove it — sheet sizing is now via `detents:` |
| `GlassRefractionSource` undefined | Replace with `GlassBackgroundSource` |
| `LiquidGlassScope.stack` undefined | Replace with `GlassPage` |
| `collapseConfig` parameter not found | Remove it — use `GlassTabBar.minimizable` for scroll-collapse |
| `GlassTabBarCollapseConfig` undefined | Removed — see §7 below |
| `GlassTabBarCollapseDirection` undefined | Removed — see §7 below |

If you encounter anything not covered here, open an issue at
[github.com/sdegenaar/liquid_glass_widgets/issues](https://github.com/sdegenaar/liquid_glass_widgets/issues).

---

### 7. Collapse Config Removed: `GlassTabBarCollapseConfig` / `GlassTabBarCollapseDirection`

`GlassTabBarCollapseConfig` and `GlassTabBarCollapseDirection` have been **removed entirely** in 1.0.0.

The collapse-to-button pattern — where the tab pill slides sideways into a corner `+` button — is not an iOS 26 design primitive. Apple's tab bar has two states: static and minimized. The implementation was also unreliable on 120 Hz ProMotion displays.

#### Migration path

Use `GlassTabBar.minimizable` instead. It directly mirrors SwiftUI's `tabBarMinimizeBehavior(.onScrollDown)` with spring physics and works correctly on all devices.

```dart
// Before (0.x — no longer compiles):
GlassTabBar.bottom(
  tabs: _tabs,
  selectedIndex: _index,
  onTabSelected: (i) => setState(() => _index = i),
  extraButton: GlassTabBarExtraButton(icon: Icon(Icons.add), onTap: _onAdd),
  collapseConfig: GlassTabBarCollapseConfig(),
  scrollController: _controller,
)

// After (1.0.0):
NotificationListener<UserScrollNotification>(
  onNotification: (n) {
    if (n.direction == ScrollDirection.reverse && !_minimized) {
      setState(() => _minimized = true);
    } else if (n.direction == ScrollDirection.forward && _minimized) {
      setState(() => _minimized = false);
    }
    return false;
  },
  child: GlassTabBar.minimizable(
    tabs: _tabs,
    selectedIndex: _index,
    onTabSelected: (i) => setState(() => _index = i),
    minimized: _minimized,
    onMinimizedTabTap: () => setState(() => _minimized = false),
    // Optional persistent trailing button (replaces extraButton):
    trailingButton: GlassTabBarTrailingButton(
      icon: Icon(Icons.add),
      onTap: _onAdd,
    ),
  ),
)
```

If you need a **persistent action button on a static, non-collapsing bar**, `GlassTabBarExtraButton` remains available on `GlassTabBar.bottom` without any `collapseConfig`.

---

## Preparing for 2.0: `GlassCard` → `GlassContainer.card`, and `surfaceStyle`

These changes ship in 1.x and are **non-breaking**. They are listed here so you can
move early and see no deprecation warnings.

### `GlassCard` is deprecated

`GlassCard` is `@Deprecated` and will be removed in 2.0.0. It now forwards to
`GlassContainer.card`, which has identical defaults (16pt padding, 12pt superellipse)
and the same parameters, so migration is a rename.

#### Before:
```dart
GlassCard(
  padding: EdgeInsets.all(20),
  child: Text('Hello'),
)
```

#### After:
```dart
GlassContainer.card(
  padding: EdgeInsets.all(20),
  child: Text('Hello'),
)
```

### New `surfaceStyle` (glass or solid)

`GlassContainer.card`, `GlassGroupedSection`, `GlassReorderableList.grouped`,
`GlassDatePicker`, `GlassMultiDatePicker` and `showGlassDatePicker` accept
`surfaceStyle: GlassSurfaceStyle.glass | GlassSurfaceStyle.solid`.

- `glass` (default in 1.x): unchanged glass surface.
- `solid`: a flat opaque card (white in light mode, `#1C1C1E` in dark mode, 26pt corners
  by default) with no blur, rim light or shadow, like native iOS inset-grouped lists.
  It is a plain filled shape, not a shader, so `settings`, `quality` and `useOwnLayer`
  are ignored. Grouped sections and reorderable lists also clip their rows to the card's
  rounded corners. The brightness follows `GlassTheme` / your app theme like every other
  widget in the package. Dark `solid` is always `#1C1C1E`; the lighter elevated grey iOS
  uses inside sheets is not implemented.

iOS renders inset-grouped list cards flat, so opt in to match:

```dart
GlassGroupedSection(
  surfaceStyle: GlassSurfaceStyle.solid,
  children: [/* GlassListTile ... */],
)
```

### 2.0.0 default flip

In 2.0.0 the default `surfaceStyle` changes from `glass` to `solid` for
`GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDatePicker`,
`GlassMultiDatePicker` and `GlassContainer.card`
(`GlassContainer` itself stays glass-first). To keep today's look after upgrading,
pass `surfaceStyle: GlassSurfaceStyle.glass` explicitly.
