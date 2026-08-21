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
| `GlassBottomBarCollapseConfig` | `GlassTabBarCollapseConfig` | Scoped to the canonical tab bar |
| `GlassBottomBarCollapseDirection` | `GlassTabBarCollapseDirection` | Scoped to the canonical tab bar |
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
  collapseConfig: GlassTabBarCollapseConfig(
    direction: GlassTabBarCollapseDirection.towardsExtraButton,
  ),
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

If you encounter anything not covered here, open an issue at
[github.com/sdegenaar/liquid_glass_widgets/issues](https://github.com/sdegenaar/liquid_glass_widgets/issues).
