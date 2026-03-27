# 0.4.1-dev.2

### Bug Fixes

- **FIX**: `GlassBottomBar` (and other surfaces) now correctly respond to dynamic `glassSettings` changes on `GlassQuality.standard`
  - `AdaptiveGlass` in grouped mode was using empty default settings instead of inheriting from the parent `AdaptiveLiquidGlassLayer`, causing `glassColor` (including alpha) to be ignored entirely on the lightweight shader path
  - Fixed by reading settings from `InheritedLiquidGlass` in grouped mode, consistent with how the Impeller path behaves
- **FIX**: Luminance-aware ambient floor for white glass on `GlassQuality.standard`
  - `LiquidGlassSettings.figma()` hardcodes `ambientStrength: 0.1`, causing white glass to render as dark grey in the lightweight shader
  - Applied a `brightnessIntent = alpha × luminance × 0.6` floor so high-opacity white glass renders with appropriate brightness without affecting calibrated presets

---

# 0.4.1-dev.1

### Breaking Changes

**Library-wide `IconData` → `Widget` API migration.** All icon parameters across the library now accept any `Widget` — enabling SVG, PNG, and custom assets alongside standard `Icon()`. Standard `Icon` widgets automatically inherit the correct color and size via `IconTheme` with no visual change.

**Migration for all affected widgets:** wrap bare `IconData` values in `Icon()`:
```dart
// Before (all widgets)
GlassButton(icon: CupertinoIcons.heart, onTap: () {})

// After
GlassButton(icon: Icon(CupertinoIcons.heart), onTap: () {})

// Or use any custom widget (new capability)
GlassButton(icon: SvgPicture.asset('assets/heart.svg'), onTap: () {})
```

Affected widgets and parameters:

| Widget | Parameter(s) |
|--------|-------------|
| `GlassButton` | `icon: Widget?` (was `IconData?`) |
| `GlassIconButton` | `icon: Widget` (was `IconData`) |
| `GlassChip` | `icon: Widget?`, `deleteIcon: Widget?` (were `IconData?`) |
| `GlassPullDownButton` | `icon: Widget?` (was `IconData?`) |
| `GlassSideBarItem` | `icon: Widget` (was `IconData`) |
| `GlassMenuItem` | `icon: Widget?` (was `IconData?`) |
| `GlassActionSheetAction` | `icon: Widget?` (was `IconData?`) |
| `GlassTab` | `icon: Widget?` (was `IconData?`) |
| `GlassPicker` | `icon: Widget?` (was `IconData?`) |
| `GlassToast` / `GlassSnackBar` | `icon: Widget?` (was `IconData?`) |
| `GlassBottomBarTab` | `icon: Widget` (was `IconData`) |
| `GlassBottomBarExtraButton` | `icon: Widget` (was `IconData`) |

- **BREAKING**: `GlassBottomBarTab.selectedIcon` renamed to `activeIcon` (`Widget?`)
  - Aligns with Flutter's `BottomNavigationBarItem.activeIcon` naming convention
  - **Migration:** Replace `selectedIcon:` with `activeIcon:` at all call sites

### New Features

- **FEAT**: `GlassBottomBar.iconLabelSpacing` — configurable vertical gap between tab icon and label (contributed by @baneizalfe in PR #11 — thanks!)
  - Previously hardcoded to 4px; now exposed as a parameter (default: `4.0`)
  - Useful for aligning with iOS 26 tab bar design guidelines

---

# 0.4.0-dev.7


### Bug Fixes

- **FIX**: Corner radius extraction logic in `LightweightLiquidGlass` and `GlassEffect`
  - Added support for `int` values (e.g., `16`) previously causing silent extraction failures
  - Fixed heuristic issue where an explicit `0.0` radius was overridden by default `16.0` rounding
  - Improved `BorderRadiusGeometry` resolution using `TextDirection.ltr`
  - Ensures consistent "sharp corner" behavior across all rendering backends

### Examples

- **FEAT**: Added Shape and Radius debug example
  - New `example/lib/repro_issue.dart` for verifying button shapes and radii in isolation
  - Demonstrates `LiquidOval`, `LiquidRoundedRectangle`, and `LiquidRoundedSuperellipse` configurations

---

# 0.4.0-dev.6

### Bug Fixes

- **FIX**: Shader refactoring to resolve Impeller crashes on iOS Simulators
  - Packed uniforms into `vec4` arrays to stay under the Metal 14-binding limit
  - Resolved "Could not create render pipeline" errors on simulated devices
- **FIX**: Shader asset resolution in unit tests
  - Added fallback path mechanism to correctly load shaders in test environments
  - Eliminates "Asset not found" exceptions during `flutter test`

---

# 0.4.0-dev.5

### Bug Fixes

- **FIX**: Improve menu alignment logic and address visual flicker issues
  - Refined menu alignment for both horizontal and vertical axes to prevent overflow and ensure proper positioning
  - Fixed grey rectangle flickering in `GlassBottomBar` by making shader fallback transparent in `GlassEffect`
  - Resolved shader initialization timing issues to eliminate flicker and improve stability during first-frame rendering
  - Fixed `GlassTabBar` indicator alignment to center precisely under cursor during drag gestures

### Testing

- **TEST**: Add `resetForTesting()` to `LightweightLiquidGlass` (#9) - Thanks @friebetill!
  - Exposes static method to reset shader state between tests for consistent fallback rendering

---

# 0.4.0-dev.4

### Performance Improvements

- **PERF**: Impeller pipeline warm-up at app initialization
  - Pre-compiles Metal/Vulkan shaders during startup to eliminate first-frame jank
  - Only runs on Impeller (iOS/Android/macOS), gracefully skipped on Skia/Web

- **PERF**: Const settings caching for `GlassTabBar` and `GlassSideBar`
  - Reduces memory allocations during widget rebuilds

- **PERF**: RepaintBoundary hints for tile-based rendering
  - Helps Impeller skip rasterizing unchanged tiles in static surfaces

---

# 0.4.0-dev.3

### Bug Fixes

- **FIX**: Removed selection bounce effect from `GlassBottomBar` for iOS 26 authenticity
  - Removed sine-wave bounce animation on tab selection
  - Removed unused `AnimatedScale` wrapper
  - Tab transitions now match iOS 26 liquid glass design (smooth without scale jumps)

---

# 0.4.0-dev.2

### New Components

#### **GlassToast / GlassSnackBar** - iOS 26 Toast Notifications
- Toast notifications with liquid glass backdrop effect
- 5 types: success, error, info, warning, neutral with theme-aware colors
- 3 positions: top, center, bottom (respects safe areas)
- Auto-dismiss with configurable duration
- Swipe-to-dismiss gesture support
- Optional action buttons with callbacks
- Spring-based slide animations (iOS 26 curves)
- Accessibility support with live regions

#### **GlassBadge** - Notification & Status Indicators
- Count badges (auto-sizing: 1-2 digits small, 3+ wider, shows "99+" for large numbers)
- Dot badges for status indicators (online, away, busy, etc.)
- 4 positions: topRight, topLeft, bottomRight, bottomLeft
- Auto-hide when count is 0
- Theme-aware colors (uses danger color for notifications)
- Custom colors for status dots

#### **GlassActionSheet** - iOS Action Picker
- Bottom-anchored action list with iOS-style modal dismissal
- 3 action styles: default, destructive (red), cancel (bold)
- Optional icons for each action
- Title and message support
- Cancel button separated at bottom
- Safe area handling with scrolling for many actions
- Tap outside to dismiss

### Example App Updates
- Added toast demos to Feedback page (types, positions, actions)
- Added badge demos to Interactive page (count badges, status dots)
- Added action sheet demos to Overlays page (basic, destructive, multiple actions)

---

# 0.4.0-dev.1

### New Components

#### **GlassProgressIndicator** - iOS 26 Progress & Loading Feedback

Complete implementation of iOS 26 Liquid Glass progress indicators:

**Features:**
- ✅ **Circular Progress** (Indeterminate & Determinate)
  - Indeterminate: Rotating spinner for loading states
  - Determinate: Progress ring showing 0-100% completion
  - iOS 26 specs: 20pt diameter, 2.5pt stroke, 1.0s rotation
  - Sizes: Small (14pt), Medium (20pt), Large (28pt)

- ✅ **Linear Progress** (Indeterminate & Determinate)
  - Indeterminate: Moving bar animation for loading
  - Determinate: Fill-from-left progress bar
  - iOS 26 specs: 4pt height, rounded caps
  - Configurable heights: Thin (2pt), Standard (4pt), Thick (8pt)

- ✅ **Liquid Glass Effects**
  - Translucent glass background (15% white opacity)
  - Color glow with 4pt blur radius
  - Smooth spring-based animations
  - Theme-aware colors (uses primary glow color)

- ✅ **Full Theme Integration**
  - Automatically inherits `GlassThemeData.glowColors.primary`
  - Supports color overrides per instance
  - Light/dark mode adaptive

**Example Usage:**
```dart
// Circular spinner
GlassProgressIndicator.circular()

// Circular with progress
GlassProgressIndicator.circular(value: 0.7) // 70%

// Linear loading bar
GlassProgressIndicator.linear()

// Linear with progress
GlassProgressIndicator.linear(value: 0.5) // 50%
```

**Example App:**
- New "Feedback" page with 10+ interactive demos
- Circular spinners (3 sizes, 5 progress states, 4 colors)
- Linear progress bars (3 heights, 5 progress states, 4 colors)
- Real-world file upload simulation with animations

---

# 0.3.0-dev.2

### New Features

- **Comprehensive Theme System**
  - `GlassTheme` and `GlassThemeData` for global styling control
  - Automatic light/dark mode support via `MediaQuery`
  - Theme-aware glow colors for interactive widgets
  - All 27 widgets inherit theme settings automatically

```dart
// Wrap your app with GlassTheme
GlassTheme(
  data: GlassThemeData(
    light: GlassThemeVariant(
      settings: LiquidGlassSettings(thickness: 30),
      quality: GlassQuality.standard,
      glowColors: GlassGlowColors(primary: Colors.blue),
    ),
    dark: GlassThemeVariant(
      settings: LiquidGlassSettings(thickness: 50),
      quality: GlassQuality.premium,
      glowColors: GlassGlowColors(primary: Colors.cyan),
    ),
  ),
  child: MyApp(),
)

// Widgets inherit theme automatically
GlassButton(onPressed: () {}, child: Text('Themed'))
```

---

# 0.3.0-dev.1

### Breaking Changes

- **`quality` parameter is now nullable** across all widgets that support it
  - Previously: `quality: GlassQuality.standard` (required, with default)
  - Now: `quality: GlassQuality?` (nullable, inherits from parent layer)
  - **Migration:** Most code will work without changes. Only affects code that relied on the parameter being non-nullable.

### New Features

- **Quality Inheritance System**
  - All widgets now inherit `quality` from parent `AdaptiveLiquidGlassLayer`
  - Explicitly set `quality` on a widget to override inheritance
  - Simplifies code by setting quality once at the layer level

- **Showcase App**
  - New showcase app demonstrating liquid glass widgets in action
  - Centralized theme system with predefined glass settings
  - Real-world examples of quality inheritance patterns

### Bug Fixes

- **Critical: Fixed glass shader rendering order**
  - Glass shader now renders **behind** content, not on top
  - Fixes text appearing washed out with semi-transparent glass
  - Affects all widgets using `LightweightLiquidGlass`

### Migration Guide

**For most users, no code changes are required!**

#### If you don't specify `quality`:
```dart
// Before (0.2.x)
GlassButton(icon: Icons.star, onTap: () {})

// After (0.3.x) - No changes needed!
GlassButton(icon: Icons.star, onTap: () {})
```

#### If you explicitly set `quality`:
```dart
// Before (0.2.x)
GlassButton(quality: GlassQuality.premium, icon: Icons.star, onTap: () {})

// After (0.3.x) - No changes needed!
GlassButton(quality: GlassQuality.premium, icon: Icons.star, onTap: () {})
```

#### New: Use inheritance for cleaner code:
```dart
// Before (0.2.x) - Repetitive
AdaptiveLiquidGlassLayer(
  settings: settings,
  child: Column([
    GlassButton(quality: GlassQuality.premium, ...),
    GlassButton(quality: GlassQuality.premium, ...),
    GlassTextField(quality: GlassQuality.premium, ...),
  ]),
)

// After (0.3.x) - Set once, inherit everywhere
AdaptiveLiquidGlassLayer(
  quality: GlassQuality.premium,
  settings: settings,
  child: Column([
    GlassButton(...),  // Inherits premium
    GlassButton(...),  // Inherits premium
    GlassTextField(...),  // Inherits premium
  ]),
)
```

#### Only if you relied on non-nullable quality:
If your code explicitly checks for non-null quality (rare), add null checks:
```dart
// Before (0.2.x)
final quality = widget.quality; // Always GlassQuality

// After (0.3.x)
final quality = widget.quality ?? GlassQuality.standard;
```

---

# 0.2.1-dev.8

- **FEAT**: GlassBottomBar "magic lens" masking effect (contributed by @Earbaj in PR #3) Massive thanks and great job!
    - Selected content appears to glow through the glass indicator as it moves
    - Dual-layer rendering with synchronized jelly physics clipping
    - Content magnification and blur effects inside indicator
    - Smooth iOS-like transitions as indicator passes over tabs

- **FEAT**: Icon-only tab support in GlassBottomBar
    - `GlassBottomBarTab.label` is now nullable for icon-only tabs
    - Tabs automatically center icons when label is null
    - Perfect for FAB-style add buttons or minimalist designs

- **FEAT**: Added `MaskingQuality` control for rendering flexibility
    - `MaskingQuality.high` (default): Full jelly physics masking effect
    - `MaskingQuality.off`: Simplified rendering for maximum performance
    - Allows developers to optimize for their target devices and tab counts

- **IMPROVE**: Performance optimizations for high quality masking mode
    - Selective rendering for tabs near indicator
    - Clip path caching for smooth animations
    - Lazy evaluation when indicator is hidden

- **IMPROVE**: Enhanced visual parameters with recommended ranges
    - `magnification`: Zoom content inside indicator (recommended: 1.0-1.3)
    - `innerBlur`: Frosted glass effect on selected content (recommended: 0.0-3.0)

- **IMPROVE**: Glass refraction and visual effects in high quality masking mode
    - Content properly layered behind glass for authentic appearance
    - Impeller: True chromatic aberration and background refraction
    - Skia/Web: Glass rim lighting and specular highlights on icons
    - Optimized layer architecture with zero performance overhead

- **FIX**: Accessibility improvement for icon-only tabs
    - Empty semantic labels now default to 'Tab' for screen readers
    - Ensures WCAG 2.1 compliance

- **BREAKING**: `GlassBottomBarTab.label` is now nullable (`String?` instead of `required String`)
    - Most existing code will continue to work without changes
    - If you have code that assumes `label` is non-null, add null checks

# 0.2.1-dev.7

- **FEAT**: Added `GlassDefaults` constants class
    - Centralized default values for glass effects, dimensions, and animations
    - Includes: `thickness`, `blur`, `lightIntensity`, `borderRadius`, padding presets, etc.
    - Improves consistency and maintainability across all widgets
    - Accessible via `import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'`

- **IMPROVE**: Enhanced developer experience with debug assertions
    - `LiquidGlassScope`: Warns when nesting scopes (usually unintentional)
    - `LiquidGlassBackground`: Informs when used without a scope
    - `GlassEffect`: Validates background capture conditions
    - All assertions only run in debug mode (zero production overhead)

- **TEST**: 
    - 10 new tests for `LiquidGlassScope.stack` convenience constructor

- **FIX**: Fixed `LiquidGlassScope.stack` double-Positioned widget error
    - Removed unnecessary `Positioned.fill` wrapper from content
    - Fixes "Competing ParentDataWidgets" error when using Scaffold as content
    - Content now naturally fills available space (simpler, more flexible)

# 0.2.1-dev.6

- **FEAT**: Added `LiquidGlassScope.stack` convenience constructor (Skia/Web Premium)
    - Eliminates boilerplate for the common pattern of a background behind content
    - Example: `LiquidGlassScope.stack(background: Image.asset(...), content: Scaffold(...))`
    - Zero breaking changes - purely additive API improvement

# 0.2.1-dev.5

- **REFACTOR**: Major architectural refactoring of interactive widgets for consistency and quality
    - **Unified Interactive Indicator Architecture**: Extracted shared `AnimatedGlassIndicator` component
      - Eliminates 877 lines of duplicated code across `GlassBottomBar`, `GlassTabBar`, and `GlassSegmentedControl`
      - Provides consistent jelly physics, glass effects, and animation behavior
      - Single source of truth for indicator rendering logic
      - Easier to maintain and extend with new features
    
    - **GlassSlider
      - Fixed dynamic sizing to match `GlassSwitch` pattern (glass shell now grows with scale animation)
      - Implemented proper vertical centering during balloon animation
      - Aligned architecture with `GlassSwitch` using static `const` settings
    
    - **GlassSwitch Code Simplification**: Reduced complexity while maintaining quality
      - Simplified thumb rendering logic by 40% (309 lines → cleaner structure)
      - Removed redundant conditional logic
      - Improved code readability and maintainability
      - Improved visual for more ios26 aesthetics
    
    - **Architectural Consistency**: All interactive widgets now follow the same pattern
      - Static `const LiquidGlassSettings` (no per-frame allocations)
      - Dynamic sizing for proper premium rendering
      - Stable content structure (no `Transform.scale` wrapping `GlassEffect`)
      - `interactionIntensity` parameter drives all animations
      - Opacity-based glow control (no conditional mounting)

- **PERF**: Significant performance improvements across interactive widgets
    - **877 lines of code removed** through shared component extraction
    - Static `const` settings eliminate per-frame allocations in `GlassSlider`
    - Optimized `GlassEffect` shader uniform updates
    - Better RepaintBoundary placement for render isolation

- **FEAT**: Enhanced `GlassEffect` widget for better interactive indicator support
    - Improved background capture system with "Interaction Heartbeat"
    - Better coordinate synchronization for animated widgets
    - Optimized shader parameter passing
    - Support for dynamic shape sizing

# 0.2.1-dev.4


- **PERF**: Optimized `InteractiveIndicatorGlass` (Skia/Web path) with a new **"Interaction Heartbeat"** system. This reduces overhead by 80% when using `LiquidGlassScope` by throttling background captures while maintaining smooth 10fps live refraction during active dragging.
- **FEAT**: **Universal Aesthetic Fallback**: Interactive indicators now maintain their premium custom-shader lighting and rim structure even without a `LiquidGlassBackground`. Added a new "Synthetic Frost" mode that renders a high-fidelity glass material when no background is captured.
- **PERF**: GPU optimization across all custom shaders; light direction vectors are now pre-calculated on the CPU, reducing per-pixel complexity for all glass widgets on Skia/Web.

# 0.2.1-dev.3

- **FIX**: `GlassBottomBarExtraButton` now respects parent styling
    - Extra button icon color now inherits from `GlassBottomBar.unselectedIconColor` when not explicitly set
    - Extra button shape now matches parent's `barBorderRadius` (defaults to circular for standard 32px radius)
    - Added `iconColor` parameter to `GlassBottomBarExtraButton` for explicit color control
    - Thanks to @kermit83 for the contribution (#1)

# 0.2.1-dev.2

- **FEAT**: Custom Shader Refraction for Interactive Indicators
    - New `LiquidGlassScope` + `LiquidGlassBackground` widgets for background capture
    - Custom fragment shader (`interactive_indicator.frag`) provides iOS 26 liquid glass refraction on all platforms
    - Works on Web, Skia, and macOS where Impeller's scene graph isn't available
    - Dynamic edge distortion with quadratic falloff for realistic lens effect
    - Chromatic aberration at edges for authentic prism refraction
    - Directional rim lighting and fresnel glow matching Impeller aesthetics
    - Fully documented shader with `TWEAK:` markers for easy customization

- **PERF**: Parallel shader pre-warming in `LiquidGlassWidgets.initialize()`
    - Both `LightweightLiquidGlass` and `InteractiveIndicatorGlass` shaders now pre-warm in parallel
    - Eliminates cold start delay when first using segmented controls

- **TEST**: Added comprehensive tests for new widgets
    - 14 new tests covering `LiquidGlassScope` and `LiquidGlassBackground`
    - Tests InheritedWidget behavior, nested scopes, key stability, and integration

- **EXAMPLE**: Updated Shader Comparison demo
    - Side-by-side comparison of Impeller vs Custom Shader rendering
    - Simplified interactive page layout for mobile-friendly scrolling

# 0.2.1-dev.1

- **PERF**: Batch-Blur Optimization - **5-6x faster rendering** with multiple glass widgets
    - Containers now share a single `BackdropFilter` with all children (was: each widget had its own)
    - Card with 5 buttons: ~60ms → ~12ms (5x faster)
    - Scrolling lists: 25fps → 60fps (2.4x improvement)
    - Synthetic density physics in shader compensates for visual differences (imperceptible)
    - Automatic detection via `InheritedLiquidGlass.isBlurProvidedByAncestor`

- **FEAT**: User-customizable saturation for all widgets
    - `saturation` parameter now works for buttons and all interactive widgets
    - Users can control color vibrancy: `saturation: 0.7` (subtle) to `1.5` (vivid)
    - Matches Impeller's HSL-style saturation behavior across all platforms

- **REFACTOR**: Separated concerns architecture (matches Impeller)
    - Introduced `uGlowIntensity` (18) and `uDensityFactor` (19) shader uniforms
    - Restored `saturation` to original purpose: color adjustment (no longer overloaded)
    - Interactive glow now uses explicit `glowIntensity` parameter (0.0-1.0)
    - Elevation physics now uses explicit `densityFactor` parameter (0.0-1.0)
    - Added `glowIntensity` parameter to `AdaptiveGlass` and `LightweightLiquidGlass`

- **PERF**: GPU optimization - 8-12% faster shader execution
    - Branchless glow implementation eliminates warp divergence on mobile GPUs
    - Used `step()` function instead of conditional branches for parallel execution

- **FIX**: Button press feedback bugs
    - Fixed no-op alpha boost (was `interactionDelta * 0`, now `glowIntensity * 0.3`)
    - Restored correct glow power (was `0.2`, now `0.3` for visible feedback)
    - Button press now correctly increases opacity and brightness

# 0.2.0-dev.2

- **REFACTOR**: Standardized light angle to 120° for interactive widgets
    - Updated default `lightAngle` from 90° to 120° for improved visual depth
    - Applied consistently across `GlassInteractiveIndicator`, `GlassSegmentedControl`, and `GlassSwitch`
    - Better matches Apple's design aesthetics with enhanced depth perception

# 0.2.0-dev.1

- **FEAT**: Universal Platform Support with Lightweight Glass Shader
    - **Lightweight Fragment Shader**: High-performance shader-based rendering now works on all platforms (Web/CanvasKit, Skia, Impeller)
      - Faster than BackdropFilter while delivering iOS 26-accurate glass aesthetics
      - Matrix-synced coordinate system eliminates drift during parent transformations
      - Dual-specular highlights, rim lighting, and physics-based thickness response
      - Per-widget shader instances on Web (CanvasKit requirement), shared instance on native
    - **AdaptiveGlass**: Intelligent rendering path selection based on platform capabilities
      - Premium + Impeller → Full shader pipeline with texture capture and chromatic aberration
      - Premium + Skia/Web → Lightweight shader (automatic fallback)
      - Standard → Always lightweight shader (recommended default)
    - **AdaptiveLiquidGlassLayer**: Drop-in replacement for `LiquidGlassLayer` ensuring proper rendering on all platforms
      - Provides scope for grouped widgets while maintaining visual fidelity
    - **Interactive Glow Support**: Shader-based glow effects for button press states on Skia/Web
      - Matches Impeller's `GlassGlow` behavior using shader saturation parameter
      - Enables full interactive feedback across all platforms

- **REFACTOR**: Completed lightweight shader migration across all widgets
    - Migrated `GlassSideBar`, `GlassToolbar`, and `GlassSwitch` to use `AdaptiveGlass`
    - Standardized on `AdaptiveLiquidGlassLayer` throughout example app and documentation
    - All 26 widgets now deliver consistent glass quality on Web, Skia, and Impeller

- **DOCS**: Comprehensive documentation updates
    - Added Platform Support section to README (iOS, Android, macOS, Web, Windows, Linux)
    - Updated Quick Start with shader precaching guide (`LightweightLiquidGlass.preWarm()`)
    - Corrected quality mode descriptions across 5 widgets and README
    - Clarified that `GlassQuality.standard` uses lightweight shader, not BackdropFilter
    - Added platform-specific rendering behavior notes for premium quality

- **PERF**: Optimized web rendering pipeline
    - Per-widget shader lifecycle management on Web (CanvasKit requirement)
    - Eliminated coordinate drift with zero-latency physical coordinate mapping

- **FIX**: Resolved platform-specific rendering issues
    - Fixed glass widgets appearing as solid semi-transparent boxes on Web when using premium quality
    - Fixed coordinate synchronization during parent transformations (LiquidStretch, scroll, etc.)
    - Ensured draggable indicators and navigation bars maintain glass appearance on Web and Skia

# 0.1.5-dev.11

- **PERF**: Performance optimizations for `GlassBottomBar` and indicator animations
    - Eliminated expensive `context.findAncestorWidgetOfExactType()` call that was executed on every animation frame
    - Cached `LiquidRoundedSuperellipse` shape to avoid recreation during indicator animations
    - Cached default `LiquidGlassSettings` as static const to reduce allocations on every build
- **FIX**: Fixed indicator flash when setting `indicatorSettings` explicitly
    - Fixed `GlassInteractiveIndicator` to always apply visibility animation regardless of custom settings
    - Ensures smooth fade transitions when custom indicator settings are provided

## 0.1.5-dev.10 (Retracted)

# 0.1.5-dev.9

- **FIX**: Fixed `GlassBottomBar` indicator layering issue
    - Interactive indicator now renders above the glass bar background
    - Resolves z-index issue affecting both `GlassQuality.standard` and `GlassQuality.premium`
- **REFACTOR**: Improved `indicatorSettings` consistency across interactive widgets
    - Standardized indicator glass settings API in `GlassBottomBar`, `GlassTabBar`, and `GlassSegmentedControl`

# 0.1.5-dev.8

- **PERF**: Major performance optimization across all widgets
    - Eliminated 21 color allocations with cached `static const` values
    - Added strategic `RepaintBoundary` placements to prevent cascading repaints
    - Optimized 14 widgets: `GlassSearchBar`, `GlassFormField`, `GlassPicker`, `GlassIconButton`, `GlassChip`, `GlassSwitch`, `GlassSlider`, `GlassBottomBar`, `GlassTabBar`, `GlassSegmentedControl`, `GlassInteractiveIndicator`, `GlassDialog`, `GlassSheet`, `GlassSideBar`
    - Result: 5-20% FPS improvement across navigation, input, and interactive widgets

# 0.1.5-dev.7

 - **FEAT**: Added Liquid Glass Menu System
   - **GlassMenu**: iOS 26 liquid glass morphing context menu
     - True morphing animation: button seamlessly transforms into menu
     - Critically damped spring physics (Stiffness: 180, Damping: 27) - zero bounce
     - Liquid swoop effect: 8px downward curve with easeOutCubic timing
     - Triple-layer clipping with width constraints for zero visual artifacts
     - Position-aware: expands from button location with automatic alignment
     - Scrollable content support with iOS-style ClampingScrollPhysics
   - **GlassMenuItem**: Configurable menu action items
     - Support for icons, destructive styling, and trailing widgets
     - Customizable height (defaults to 44px iOS standard)
   - **GlassPullDownButton**: Convenient wrapper for menu triggers
     - Integrates GlassMenu with specialized button styling
     - Auto-closing menu behavior and onSelected callback
   - **GlassButtonGroup**: Cohesive container for grouping related actions
     - "Joined" style layout for toolbar commands (e.g., Bold/Italic/Underline)
     - Automatically manages dividers between items
   - **GlassButton**: Added `style` property with `GlassButtonStyle.transparent`
     - Allows buttons to blend into groups without double-glass rendering artifacts

# 0.1.5-dev.6

 - **PERF**: Comprehensive Allocation Optimization
   - Implemented `static const` defaults for Shapes, Settings, and Styles across 9 core widgets (`GlassButton`, `GlassIconButton`, `GlassChip`, `GlassTextField`, `GlassPasswordField`, `GlassCard`, `GlassAppBar`, `GlassToolbar`, `GlassDialog`).
   - Significantly reduced object allocation pressure during rebuilds and animations.
   - **GlassPicker**: Switched to `CupertinoPicker.builder` for efficient O(1) lazy loading of large item lists.
   - **GlassInteractiveIndicator**: Optimized physics settings allocation to reduce per-frame GC overhead.

# 0.1.5-dev.5

 - **CHORE**: Code cleanup and documentation improvements
   - Improved header documentation for `GlassFormField`
   - General code polish and comment updates across input widgets
   - Fixed layout regressions in surfaces/overlays

# 0.1.5-dev.4

 - **FEAT**: Added Liquid Glass Input Suite
   - `GlassFormField`: Wrapper for labels, error text, and helper content
   - `GlassPasswordField`: Secure input with built-in visibility toggle and lock icon
   - `GlassTextArea`: Optimized multi-line input with smart padding and scrolling
   - `GlassPicker`: iOS-style selector with glass container and modal integration
   - `GlassPicker`: Supports "own layer" mode for premium transparency effects

 - **FEAT**: Added `GlassSideBar` widget
   - Vertical navigation surface with glass effect
   - Supports header, footer, and scrollable item list
   - Auto-layout for standard sidebar items with icons and labels

 - **FEAT**: Enhanced Configurability
   - Refactored all input widgets to expose standard `TextField` properties (focus, actions, styles)
   - Updated `GlassTabBar` to support custom `borderRadius` and `indicatorBorderRadius`
   - Exposed granular `indicatorSettings` in `GlassTabBar` for fine-tuned glass effects

 - **FEAT**: Added `GlassToolbar` widget
   - Standard iOS-style action toolbar
   - Supports transparent background and safe area integration

 - **REFACTOR**: Shared Indicator Logic
   - Extracted `GlassInteractiveIndicator` to `lib/widgets/shared/`
   - Unified jelly physics implementation across BottomBar, TabBar, and SegmentedControl
   - Standardized on `LiquidRoundedSuperellipse` for smoother indicator shapes

# 0.1.5-dev.3

 - **FEAT**: Added `GlassTabBar` widget
   - Horizontal tab navigation bar for page switching
   - Support for icons, labels, or both (icons above labels)
   - Smooth animated indicator with bouncySpring motion
   - Scrollable mode for many tabs (5+)
   - Auto-scroll to selected tab when index changes
   - Sharp text rendering above glass effect
   - Customizable label styles, icon colors, and indicator appearance
   - Dual-mode rendering (grouped/standalone)
   - Supports both quality modes (standard/premium)
   - Comprehensive test coverage (widget + golden tests)
   - Integrated into example app surfaces page with interactive demos

# 0.1.5-dev.2

 - **TEST**: Added comprehensive test coverage for all widget categories
   - Widget behavior tests for all 15 components (containers, interactive, input, overlays, surfaces)
   - Golden visual regression tests using Alchemist
   - Test utilities and shared helpers for consistent testing patterns
   - Documented shader warnings as expected behavior in test environments

## 0.1.4

 - **FEAT**: Added `GlassSearchBar` widget
   - iOS-style search bar with pill-shaped glass design
   - Animated clear button (fades in/out based on text presence)
   - Optional cancel button with slide-in animation (iOS pattern)
   - Auto-focus support and keyboard handling
   - Custom styling options (icons, colors, height)
   - Supports both grouped and standalone modes

 - **FEAT**: Added `GlassSlider` widget with iOS 26 Liquid Glass behavior
   - Elongated pill-shaped thumb (2.5x wider for authentic iOS 26 look)
   - **Solid white → Pure transparent glass transformation when dragging**
   - "Balloons in size" when touched (scales to 135% with easeOutBack curve)
   - Dramatic liquid glass effects during interaction:
     - Refractive index: 1.15 → 1.15 (strong light bending)
     - Chromatic aberration: 0.2 → 0.5 (rainbow edges)
     - Glass transparency: alpha 1.0 → 0.1 (almost invisible)
     - Enhanced glow and shadow when dragging
   - Active track extends under thumb (visible through transparent glass)
   - Thumb positioned slightly below track center (iOS 26 alignment)
   - Jelly physics with dramatic squash/stretch (maxDistortion: 0.25)
   - Continuous and discrete value support with haptic feedback
   - Based on official Apple iOS 26 Liquid Glass specifications

 - **FEAT**: Added `GlassChip` widget
   - Pill-shaped chip for tags, filters, and selections
   - Optional leading icon and delete button
   - Selectable state for filter chips with highlight color
   - Dismissible variant with X button and onDeleted callback
   - Composes `GlassButton.custom` for consistent interaction behavior
   - Auto-sizes to content using IntrinsicWidth/Height
   - Full customization (icon size, spacing, colors, padding)
   - Supports both grouped and standalone modes

 - **FEAT**: Enhanced example app
   - Added comprehensive input page section for GlassSearchBar
     - Basic search demo
     - Cancel button demonstration
     - Custom styling examples (colors, heights)
     - Interactive search with instructions
   - Added GlassSlider demos to interactive page
     - Basic slider with percentage display
     - Discrete steps with level indicator
     - Custom colors (blue and pink variants)
   - Added GlassChip demos to interactive page
     - Basic chips demonstration
     - Chips with icons (heart, share, star)
     - Dismissible chips with dynamic removal
     - Filter chips with selection state management

## 0.1.3

 - **FEAT**: Implemented overlay widgets category
   - Added `GlassSheet` - iOS-style bottom sheet with glass effect and drag indicator
   - Added `GlassDialog` - Alert dialog with composable design (uses GlassCard + GlassButton)
   - Added `GlassDialogAction` configuration class for dialog buttons
   - Smart button layouts (horizontal for 1-2 actions, vertical for 3)
   - Support for primary and destructive action styles

 - **FEAT**: Added `GlassIconButton` widget
   - Icon-only button optimized for toolbars and app bars
   - Two shape options: circle (default) and rounded square
   - Supports both grouped and standalone modes
   - Full interaction effects (glow, stretch, disabled states)

 - **FIX**: Improved `GlassSegmentedControl` border radius calculation
   - Changed indicator radius from `borderRadius * 2` to `borderRadius - 3`
   - Indicator now properly insets from container edges
   - Matches iOS UISegmentedControl visual design

 - **FEAT**: Enhanced example app
   - Added wallpaper background support (replaces gradient)
   - Added comprehensive overlays page with 5 sheet demos and 4 dialog demos
   - Added icon button examples to interactive page (5 demo cards)
   - Updated glass settings across examples for better visual consistency

## 0.1.2

 - **FEAT**: Major enhancements to interactive widgets and code architecture
   - Created shared `DraggableIndicatorPhysics` utility class to eliminate code duplication
   - Fixed `GlassBottomBar` text rendering to appear above glass for sharp, clear labels
   - Fixed `GlassSegmentedControl` indicator border radius calculations
   - Added premium quality showcase in example app demonstrating both quality modes
   - Improved tap interaction feedback across all draggable widgets

## 0.1.1

 - **FEAT**: Implemented `GlassSegmentedControl` widget
   - iOS-style segmented control with animated glass indicator
   - Draggable indicator with jelly physics and rubber band resistance
   - Velocity-based snapping for natural gesture handling
   - Dual-mode support (grouped and standalone)
   - Full customization options for appearance and behavior

- ## 0.1.0

- **FEAT**: Initial widget library for Apple Liquid Glass
    - Implemented `GlassBottomBar` with draggable indicator and jelly physics
    - Implemented `GlassButton` with press effects and glow animations
    - Implemented `GlassSwitch` with tap toggle functionality
    - Added `GlassCard` container widget
    - Established dual-mode pattern (grouped and standalone rendering)
    - Added `GlassQuality` enum for quality mode selection
    - Created comprehensive example app with interactive demonstrations
