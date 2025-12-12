# Apple Liquid Glass Widgets Showcase Example

This example app demonstrates all the widgets available in the `liquid_glass_widgets` package.

## Features Showcased

### Containers
- **GlassContainer**: Foundational glass container widget
- **GlassCard**: Card-style containers with default 16px padding
- **GlassPanel**: Larger surface areas with 24px padding

### Interactive
- **GlassButton**: Touch-responsive buttons with glass effect
  - Icon buttons with customizable shapes and sizes
  - Custom content support
  - Glow effects and stretch animations
  - Enabled/disabled states
- **GlassSegmentedControl**: Segmented control with an animated glass indicator, jelly physics, and smooth transitions between segments
   - Animated Glass Indicator**: Smoothly animates between segments
   - Jelly Physics**: Organic squash and stretch effects during movement
   - Drag Support**: Swipe between segments with velocity-based snapping
   - Sharp Text**: Selected text stays sharp above the glass
   - Flexible Sizing**: Automatically sizes segments evenly
   - Customizable Appearance**: Full control over colors, sizes, and effects
- **GlassSwitch**: Toggle switches with glass effect
  - iOS-style animations
  - Custom colors
  - Smooth spring-based transitions

### Surfaces
- **GlassAppBar**: Navigation bar with glass effect
  - Leading and trailing actions
  - Centered title support
  - Safe area handling
- **GlassBottomBar**: Bottom navigation with advanced features
  - Draggable indicator with jelly physics
  - Velocity-based snapping
  - Rubber band resistance
  - Per-tab glow colors
  - Optional extra button

### Input
- **GlassTextField**: Text input with glass effect
  - Prefix and suffix icon support
  - Multiline support
  - Custom shapes
  - Enabled/disabled/read-only states
  - Keyboard type configuration

## Running the Example

### Prerequisites
- Flutter SDK (>=3.5.0)
- Impeller rendering engine enabled (Skia is not supported)

### Steps

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app with Impeller enabled:
   ```bash
   flutter run --enable-impeller
   ```

## Navigation

The app uses a bottom navigation bar with 6 tabs:

1. **Home**: Overview and introduction
2. **Containers**: Showcase of container widgets
3. **Interactive**: Buttons and switches
4. **Overlays**: Modal dialogs and bottom sheets
5. **Surfaces**: Navigation bars
6. **Input**: Text input fields

## Interactive Features

Try these interactions:

- **Buttons**: Tap to see stretch animations and glow effects
- **Switches**: Toggle to see smooth spring animations
- **Bottom Bar**:
  - Tap tabs to switch pages
  - Drag the indicator left/right
  - Flick quickly to jump multiple tabs
  - Try dragging beyond edges to feel rubber band resistance

## Two Modes Pattern

Most widgets support both modes:

### Grouped Mode (Recommended)
Multiple glass widgets share a `LiquidGlassLayer` for better performance:

```dart
LiquidGlassLayer(
  settings: LiquidGlassSettings(...),
  child: Column(
    children: [
      GlassButton(...),
      GlassCard(...),
    ],
  ),
)
```

### Standalone Mode
Widgets create their own layer when needed:

```dart
GlassButton(
  useOwnLayer: true,
  settings: LiquidGlassSettings(...),
  ...
)
```

## Design Philosophy

This example follows Apple's design philosophy of **composable primitives**:

- Each widget is a reusable building block
- Widgets compose together in clear, explicit layers
- All parameters are exposed for full customization
- Complex widgets reuse simpler widgets as building blocks

## Platform Support

- ✅ iOS
- ✅ macOS
- ✅ Android (Impeller only)
- ❌ Web
- ❌ Windows
- ❌ Linux

## Learn More

- [Apple Liquid Glass Documentation](../README.md)
- [Liquid Glass Renderer](../../liquid_glass_renderer/README.md)