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
