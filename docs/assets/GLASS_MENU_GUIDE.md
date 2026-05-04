# Complete Guide to GlassMenu (Ultimate Edition)

This is the definitive technical reference for the `GlassMenu` widget suite. It documents the architecture of the morphing interaction model, the selection pill tracking engine, and the precise geometric constraints that define the iOS 26 "Liquid Glass" experience.

---

## 1. Core Anatomy & Triggering
The `GlassMenu` follows a "Trigger-to-Overlay" pattern where an initial widget morphs into a floating glass menu.

| Parameter | Type | Default | What it does (Technical Detail) |
| :--- | :--- | :--- | :--- |
| `items` | `List<Widget>` | **Required** | The payload of the menu. Supports `GlassMenuItem`, `GlassMenuDivider`, `GlassMenuLabel`, or any custom widget. |
| `trigger` | `Widget?` | `null` | A static widget that opens the menu on tap. Automatically wrapped in a gesture detector. |
| `triggerBuilder` | `TriggerBuilder?`| `null` | Functional builder `(context, toggle)` for complex triggers needing direct control over the animation state. |
| `menuWidth` | `double` | `200.0` | Target width of the expanded menu. |
| `menuHeight` | `double?` | `null` | Optional fixed height. Enables internal scrolling if content exceeds this value. |
| `menuBorderRadius`| `double` | `32.0` | Target corner radius. Uses `Radius = Margin + InnerRadius` harmony. |
| `quality` | `GlassQuality?` | `null` | Rendering tier. If null, inherits from `GlassQualityScope`. |
| `glassSettings` | `LiquidGlassSettings?` | `null` | Custom shader settings (blur, thickness, refractive index) for this specific menu. |

### 1.2 Interaction & Tactile Feedback
These parameters control how the menu responds to being touched and pressed.

| Parameter | Type | Default | What it does |
| :--- | :--- | :--- | :--- |
| `interactionScale`| `double` | `1.02` | Squeeze effect applied to the container during touch interactions. `1.0` = no scale. |
| `enableInteractionGlow`| `bool` | `true` | Enables/Disables the radial glare (glow) that follows the finger during touch. |
| `glowColor` | `Color?` | `null` | Custom color for the interaction glare. Defaults to a subtle white (15% opacity). |
| `glowRadius` | `double` | `0.6` | Size of the interaction glare relative to the container. |
| `selectionColor`| `Color` | `0x3DFFFFFF`| Custom color for the sliding selection pill background. |

### 1.3 Stretching & Elasticity
Control the "Liquid" physics of the menu when pulled beyond its boundaries or scrolled to the edge.

| Parameter | Type | Default | What it does |
| :--- | :--- | :--- | :--- |
| `stretch` | `double` | `0.5` | Elasticity factor. High values make the menu stretch more for the same drag distance. |
| `stretchResistance`| `double` | `0.08` | "Stickiness" of the pull. Higher values make the menu feel heavier and harder to stretch. |
| `stretchAxis` | `Axis?` | `null` | Constrain stretching to a single axis (`Axis.horizontal` or `Axis.vertical`). |
| `allowPositiveXStretch`| `bool?` | `null` | Override: Allow pulling to the **Right**. If null, auto-calculated based on edge distance. |
| `allowNegativeXStretch`| `bool?` | `null` | Override: Allow pulling to the **Left**. If null, auto-calculated based on edge distance. |
| `allowPositiveYStretch`| `bool?` | `null` | Override: Allow pulling **Down**. If null, auto-calculated based on edge distance. |
| `allowNegativeYStretch`| `bool?` | `null` | Override: Allow pulling **Up**. If null, auto-calculated based on edge distance. |

---

## 2. Mastering Menu Items (GlassMenuItem)
`GlassMenuItem` is the primary interactive element. It is designed to work in tandem with the parent's sliding selection pill.

### 2.1 Parameters
| Parameter | Type | Default | What it does |
| :--- | :--- | :--- | :--- |
| `title` | `String` | **Required** | Primary label (17px, w400). |
| `subtitle` | `String?` | `null` | Secondary text (13px, 60% opacity). Triggers a vertical layout (Column). |
| `icon` | `Widget?` | `null` | Leading widget (usually 20px icon). Centered vertically. |
| `trailing` | `Widget?` | `null` | Trailing widget (e.g., checkmark, shortcut). |
| `onTap` | `VoidCallback` | **Required** | Action to perform when the item is tapped. |
| `isDestructive` | `bool` | `false` | Renders text/icon in `SystemRed` and applies distinct press logic. |
| `enabled` | `bool` | `true` | When false, the item is grayed out and non-interactive. |
| `titleStyle` | `TextStyle?` | `null` | Custom style for primary text. Overrides defaults. |
| `subtitleStyle` | `TextStyle?` | `null` | Custom style for secondary text. Overrides defaults. |
| `iconColor` | `Color?` | `null` | Custom color for the leading icon. |
| `iconSize` | `double` | `20.0` | Custom size for the leading icon. |
| `height` | `double` | `44.0` | Base height. Used by the parent's `_updateHoveredIndex` for tracking. |

### 2.2 Smart Color Inheritance
To reduce boilerplate, `GlassMenuItem` implements a color propagation system:
*   **Priority**: `iconColor` > `titleStyle.color` > `isDestructive` (Red) > Default (White).
*   **Inheritance**: If you set `iconColor`, the title and subtitle will automatically use that color unless they have their own `TextStyle.color`.
*   **Subtitles**: Always inherit the base color but with **60% opacity** for visual hierarchy.

### 2.3 Visual Decoupling (Pixel Perfection)
To prevent "double-blur" artifacts, `GlassMenuItem` implements **Deferred Rendering**:
- When `isSelected == true`, the item renders its background as `Colors.transparent`.
- The parent `GlassMenu` renders a single `AnimatedPositioned` sliding pill at the item's coordinates.
- This ensures that as you drag your finger, the highlight "slides" smoothly without flickering or stacking layers.

---

## 3. Grouping with GlassMenuDivider
The `GlassMenuDivider` is a non-interactive horizontal line used to organize menu items into logical groups. It is visually designed to be nearly invisible—a subtle "break" in the glass rather than a heavy separator.

### 3.1 Parameters
| Parameter | Type | Default | What it does |
| :--- | :--- | :--- | :--- |
| `height` | `double` | `12.0` | Total vertical space. The line is centered within this height. |
| `color` | `Color?` | `null` | Custom color. Defaults to white with 15% opacity (hairline style). |
| `indent` | `double` | `8.0` | Leading/Trailing padding for the line. |

### 3.2 Visual Style
*   **Hairline thickness**: The divider is exactly `0.5px` thick, ensuring it looks sharp on Retina displays.
*   **Material Harmony**: It uses the same opacity logic as iOS 26 context menus, appearing as a translucent etch rather than a solid color.

### 3.3 Technical Behavior (The "Jump" Logic)
The `GlassMenu` selection engine is aware of dividers:
*   **Zero Interaction**: Dividers do not respond to hover or drag.
*   **Selection Skipping**: When you drag your finger across a divider, the selection pill "jumps" directly from the item above to the item below without stopping at the divider. This maintains the "Liquid" momentum.
*   **Layout Weight**: Each divider adds its `height` plus the standard `2px` item gap to the total menu height.

### 3.4 Usage Example
```dart
GlassMenu(
  items: [
    GlassMenuItem(title: 'Copy', icon: Icon(Icons.copy)),
    GlassMenuItem(title: 'Paste', icon: Icon(Icons.paste)),
    const GlassMenuDivider(height: 16, indent: 12), // Visual group break
    GlassMenuItem(title: 'Delete', isDestructive: true),
  ],
  ...
)
```

---

## 4. Organizing with GlassMenuLabel
`GlassMenuLabel` is a specialized, non-interactive widget designed for headers, section labels, or decorative content within the menu.

### 4.1 Parameters
| Parameter | Type | Default | What it does |
| :--- | :--- | :--- | :--- |
| `child` | `Widget` | **Required** | The label content (usually `Text` or `Icon`). |
| `style` | `TextStyle?` | `null` | Default: 13px, w500, 60% white. Tailored for iOS headers. |

### 4.2 Behavior
*   **Interaction-Free**: Labels are completely ignored by the selection pill. Dragging across a label will not highlight it or trigger any action.
*   **Logical Padding**: Automatically applies internal horizontal padding to align with `GlassMenuItem` text.

---

## 5. The Liquid Interaction Engine
The `GlassMenu` uses a specialized version of the `LiquidStretch` renderer with directional constraints and scroll-aware selection logic.

### 5.1 Constrained Stretch
The menu automatically detects its position on the screen and limits elastic deformation:
- **Vertical**: Stretches only **Down** (or **Up** if near the bottom of the screen).
- **Horizontal**: Stretches only **Away** from the nearest screen edge.
This prevents the menu from visually "breaking" the screen boundaries.

### 5.2 Interaction & Safety Zones
The menu implements a high-fidelity gesture engine that prioritizes physical play and prevents accidental closures:

- **Zone 1: Selection (0-20px)**
  - A small buffer around the glass container.
  - The selection pill tracks the finger.
  - **Tap Guard**: Releasing the finger ONLY triggers a tap if the displacement (drag distance) is less than **10px**. This ensures that even small stretches within the active zone don't trigger items.

- **Zone 2: Liquid Play (>20px)**
  - The extended interaction area.
  - The selection pill is deactivated.
  - **No Dismissal**: Pull-to-dismiss has been disabled. Users can stretch the menu indefinitely; releasing will always result in a smooth spring return to the original shape.

### 5.3 Scroll-Aware Selection
To support `menuHeight` (fixed-size) menus with long lists, the selection engine distinguishes between scrolling and tapping:
- **Displacement Check**: If the scroll offset changes by more than **10px** during a gesture, the selection pill is deactivated, and no `onTap` action is triggered upon release.
- **Pill Suppression**: In scrollable menus, the selection pill is automatically hidden during active finger movement (>10px) to prevent visual noise while navigating.
- **Pill Sync**: The selection pill position is calculated as `ItemOffset - ScrollOffset`, ensuring it stays pinned to the correct item in the viewport during stationary touches.
- **Edge-to-Edge Scrolling**: Vertical outer padding is eliminated in favor of internal spacers, allowing items to scroll seamlessly "under" the glass frame.

---

## 6. Visual Fidelity & Rendering Tiers
The menu utilizes the library's multi-tier rendering architecture.

| Quality | Feature Set | Implementation |
| :--- | :--- | :--- |
| **Minimal** | Basic Blur | `BackdropFilter` + `RRect` clipping. |
| **Standard** | Liquid Glow | `GlassEffect` shader with specular rim and ambient saturation. |
| **Premium** | Squircle (iOS) | `LiquidRoundedSuperellipse` math for perfect continuous curvature. |

---

## 6. The Recipe Book: Masterclass Scenarios

### 1. iOS Context Menu (Modern Style)
```dart
GlassMenu(
  menuWidth: 240,
  menuBorderRadius: 32,
  items: [
    GlassMenuItem(
      title: 'Open in New Window',
      icon: Icon(Icons.open_in_new),
      onTap: () {},
    ),
    GlassMenuItem(
      title: 'Download Linked File',
      icon: Icon(Icons.download),
      onTap: () {},
    ),
    const GlassMenuDivider(),
    GlassMenuItem(
      title: 'Delete',
      isDestructive: true,
      icon: Icon(Icons.delete),
      onTap: () {},
    ),
  ],
  trigger: Icon(Icons.more_horiz),
)
```

### 2. Information-Dense Menu (Subtitles)
```dart
GlassMenuItem(
  title: 'Personal Account',
  subtitle: 'sdegenar@liquid.design',
  icon: CircleAvatar(child: Text('K')),
  height: 60, // Taller for subtitle support
  onTap: () {},
)
```

### 3. Custom Trigger (Adaptive Morphing)
```dart
GlassMenu(
  triggerBuilder: (context, toggle) => GestureDetector(
    onTap: toggle,
    child: MyPremiumCard(), // This card will morph into the menu
  ),
  items: [...],
)
```

---

## 7. Performance Checklist
- [x] **RepaintBoundary**: Each `GlassMenuItem` is wrapped in a `RepaintBoundary` to isolate press animations from the rest of the menu.
- [x] **Shader Pre-caching**: Use `LiquidGlass.initialize()` at the app root to warm up the superellipse shaders.
- [x] **Scroll Synchronization**: The menu uses `ClampingScrollPhysics` to ensure that dragging to the edge of a long menu triggers the parent's `LiquidStretch` instead of a harsh scroll bounce.

---

## 8. Geometry Logic Summary
- **Item Gap**: `2.0px`.
- **Vertical Padding**: `12.0px` (Top & Bottom, refined for spaciousness).
- **Horizontal Padding**: `12.0px`.
- **Radius Harmony**: `OuterRadius - Margin = InnerRadius`.
- **Pill Animation**: `150ms` duration using `Curves.easeOutCubic` for a snappy, tactile feel.
