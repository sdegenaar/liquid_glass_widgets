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
