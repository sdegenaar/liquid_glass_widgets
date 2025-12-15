# Liquid Glass Widgets

A comprehensive Flutter package implementing Apple's Liquid Glass design system with 26 beautiful, composable glass-morphic widgets.

[![pub package](https://img.shields.io/pub/v/liquid_glass_widgets.svg)](https://pub.dev/packages/liquid_glass_widgets)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **26 Widgets** organized into five categories
- **Two Quality Modes** for performance optimization
- **Flexible Layer System** for efficient rendering
- **Highly Customizable** appearance with extensive glass settings
- **Apple Design Guidelines** faithful implementation
- **Fully Tested** with widget tests and golden visual regression tests

## Widget Categories

### Containers
Foundation primitives for content layout:
- `GlassContainer` - Base primitive with configurable dimensions and shape
- `GlassCard` - Elevated card with shadow for content grouping
- `GlassPanel` - Larger surface for major UI sections

### Interactive
User interaction components:
- `GlassButton` - Primary action button
- `GlassIconButton` - Icon-based button
- `GlassChip` - Tag/category indicator
- `GlassSwitch` - Toggle control
- `GlassSlider` - Range selection
- `GlassSegmentedControl` - Multi-option selector
- `GlassPullDownButton` - Menu trigger button with dropdown
- `GlassButtonGroup` - Container for grouping related buttons

### Input
Text input components:
- `GlassTextField` - Text input field
- `GlassTextArea` - Multi-line text input area
- `GlassPasswordField` - Secure text input with visibility toggle
- `GlassSearchBar` - Search-specific input
- `GlassPicker` - Scrollable item selector
- `GlassFormField` - Form field wrapper for validation

### Overlays
Modal and floating UI:
- `GlassDialog` - Modal dialog
- `GlassSheet` - Bottom sheet / modal sheet
- `GlassMenu` - iOS 26 morphing context menu
- `GlassMenuItem` - Individual menu action item

### Surfaces
Navigation and app structure:
- `GlassAppBar` - Top app bar
- `GlassBottomBar` - Bottom navigation bar
- `GlassTabBar` - Tab navigation bar
- `GlassSideBar` - Vertical navigation sidebar
- `GlassToolbar` - Action toolbar for tools and controls

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  liquid_glass_widgets: ^0.1.5-dev.7
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: GlassContainer(
            width: 200,
            height: 100,
            child: Text('Hello, Glass!'),
          ),
        ),
      ),
    );
  }
}
```

### Grouped Widgets (Recommended for Multiple Glass Elements)

When you have multiple glass widgets, wrap them in a `LiquidGlassLayer` for better performance:

```dart
LiquidGlassLayer(
  settings: LiquidGlassSettings(
    thickness: 0.8,
    blur: 12.0,
    glassColor: Colors.white.withOpacity(0.1),
  ),
  child: Column(
    children: [
      GlassContainer(
        child: Text('First glass widget'),
      ),
      GlassButton(
        onPressed: () {},
        child: Text('Click me'),
      ),
      GlassCard(
        child: Text('Another glass widget'),
      ),
    ],
  ),
)
```

### Standalone Widget (For Single Glass Elements)

For a single glass widget or when you need different settings per widget:

```dart
GlassContainer(
  useOwnLayer: true,
  settings: LiquidGlassSettings(
    thickness: 1.0,
    blur: 15.0,
  ),
  child: Text('Standalone glass widget'),
)
```

## Glass Quality Modes

The package provides two quality modes optimized for different use cases:

### Standard Quality (Default)
```dart
GlassContainer(
  quality: GlassQuality.standard,
  child: Text('Great for scrollable content'),
)
```

- Uses Flutter's `BackdropFilter`
- Lightweight and reliable
- **Use for**: Lists, forms, scrollable content, interactive widgets
- **Recommended default** for most use cases

### Premium Quality
```dart
GlassAppBar(
  quality: GlassQuality.premium,
  title: Text('Static header with premium quality'),
)
```

- Uses custom shaders and texture capture
- Higher visual quality with enhanced lighting effects
- More computationally expensive
- **Use only for**: Static, non-scrollable layouts (headers, footers, hero sections)
- **Warning**: May not render correctly in scrollable contexts

## Customization

All glass widgets accept a `settings` parameter (in standalone mode) or inherit from parent `LiquidGlassLayer`:

```dart
LiquidGlassSettings(
  thickness: 0.8,              // Material thickness (0.0-1.0)
  blur: 12.0,                  // Blur radius
  refractiveIndex: 1.5,        // Light refraction (1.0-2.0)
  glassColor: Colors.white.withOpacity(0.1), // Tint color
  lightAngle: 45.0,            // Directional lighting angle
  lightIntensity: 0.8,         // Lighting strength
  ambientStrength: 0.3,        // Ambient light contribution
  saturation: 1.2,             // Color saturation multiplier
  chromaticAberration: 0.002,  // Color separation effect
)
```

## Widget Examples

### Button with Action

```dart
GlassButton(
  onPressed: () {
    print('Button pressed!');
  },
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  child: Text('Click Me'),
)
```

### Text Input Field

```dart
GlassTextField(
  hintText: 'Enter your name',
  onChanged: (value) {
    print('Text changed: $value');
  },
)
```

### Modal Dialog

```dart
showDialog(
  context: context,
  builder: (context) => GlassDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      GlassButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      GlassButton(
        onPressed: () {
          // Handle confirm
          Navigator.pop(context);
        },
        child: Text('OK'),
      ),
    ],
  ),
);
```

### Bottom Sheet

```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (context) => GlassSheet(
    child: Column(
      children: [
        ListTile(title: Text('Option 1')),
        ListTile(title: Text('Option 2')),
        ListTile(title: Text('Option 3')),
      ],
    ),
  ),
);
```

### Segmented Control

```dart
GlassSegmentedControl(
  segments: ['Day', 'Week', 'Month'],
  selectedIndex: 0,
  onChanged: (index) {
    print('Selected segment: $index');
  },
)
```

## Complete Example

See the [example](example/) directory for a full showcase app demonstrating all widgets with a beautiful wallpaper background. Run it with:

```bash
cd example
flutter run
```

## Architecture

### Layer System

All widgets support two rendering modes:

- **Grouped Mode** (`useOwnLayer: false`, default): Multiple widgets share the same rendering context via parent `LiquidGlassLayer`. More performant for many glass elements.

- **Standalone Mode** (`useOwnLayer: true`): Each widget creates its own independent rendering context. Use for single widgets or different settings per widget.

### Shape System

Widgets use `LiquidShape` for customizable shapes, with `LiquidRoundedSuperellipse` (16px radius) as the default for a smooth, modern appearance.

## Performance Tips

1. **Use Grouped Mode** when you have multiple glass widgets - wrap them in `LiquidGlassLayer`
2. **Use Standard Quality** for scrollable content and interactive widgets
3. **Reserve Premium Quality** for static elements like app bars and hero sections
4. **Limit glass widget depth** - avoid deeply nesting glass effects

## Dependencies

This package builds on the excellent work of:

### liquid_glass_renderer
The core rendering engine that powers all glass effects in this package. This sophisticated renderer provides custom shader-based glass rendering with advanced features like refraction, lighting, and chromatic aberration.

- **Package**: [`liquid_glass_renderer`](https://pub.dev/packages/liquid_glass_renderer)
- **Repository**: [flutter_liquid_glass](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer)
- **Author**: [whynotmake-it](https://github.com/whynotmake-it)

A huge thank you to the whynotmake-it team for creating this powerful rendering foundation that makes high-quality glass morphism possible in Flutter.

### Other Dependencies
- [`motor`](https://pub.dev/packages/motor) - Animation utilities

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## Testing

```bash
# Run all tests
flutter test

# Run excluding golden tests
flutter test --exclude-tags golden

# Run golden tests only (macOS)
flutter test --tags golden
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

This package implements Apple's Liquid Glass design guidelines as a high-level widget library.

**Special Thanks:**
- The [whynotmake-it](https://github.com/whynotmake-it) team for creating the [`liquid_glass_renderer`](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer) package, which provides the sophisticated shader-based rendering engine that powers all the glass effects in this library. Their work on custom shaders, texture capture, and advanced glass rendering techniques made this widget library possible.

## Links

- [Homepage](https://github.com/sdegenaar/liquid_glass_widgets)
- [Repository](https://github.com/sdegenaar/liquid_glass_widgets)
- [Issue Tracker](https://github.com/sdegenaar/liquid_glass_widgets/issues)
- [Pub.dev Package](https://pub.dev/packages/liquid_glass_widgets)