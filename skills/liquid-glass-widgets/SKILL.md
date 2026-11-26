---
name: liquid-glass-widgets
description: "Mastery guide and architectural rules for liquid_glass_widgets. Trigger whenever generating, refactoring, or reviewing Flutter UI code using liquid glass, iOS 26/27 aesthetics, GlassScaffold, GlassTabBar, GlassModalSheet, or any Glass* components."
---

# Liquid Glass Widgets — AI Agent Guide

This skill defines the architecture, design principles, API dictionary, and strict implementation rules for building Flutter applications with `liquid_glass_widgets`.

Follow this guide strictly when writing, refactoring, or reviewing UI code to ensure high visual fidelity, 60/120 fps GPU performance, and zero hallucinations.

---

## 1. Golden Architectural Rules (Mandatory)

### Rule 1: Glass is a Platter, Not a Wrapper
Glass in the iOS 26/27 design system is reserved for the **navigation and control layer** — floating chrome that sits above content.
- **DO use glass for:** Navigation bars (`GlassAppBar`), tab bars (`GlassTabBar`), floating chrome buttons (`GlassButton`, `GlassIconButton`, optionally tinted with `tintColor`), toolbars, modal sheets (`GlassModalSheet`), dialogs (`GlassDialog`), and standalone floating cards (`GlassContainer.card`).
- **DO NOT use glass for:** Full-screen backgrounds, dense list view items, video players, image galleries, or text article bodies. Backgrounds should be rich wallpapers or gradients; content cards should be clean and readable. Cards, toggle buttons, buttons, and inputs inside scrolling lists should use `surfaceStyle: GlassSurfaceStyle.solid` (on `GlassContainer.card`, `GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`, `GlassDatePicker`, `GlassMultiDatePicker`, `GlassTextField`, `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, `GlassPicker`, `GlassToggle.button`, `GlassButton`, `GlassButton.custom`, or `GlassIconButton`; `GlassModalSheet` takes it too, for a sheet that is opaque at every detent): a flat opaque card or translucent input/pill/button well matching native iOS inset-grouped lists. Inputs, pickers, toggle buttons, and buttons placed inside a solid card/section inherit `solid` automatically via `InheritedGlassSurfaceStyle`. `glass` is the 1.x default; `solid` becomes the default for list sections, date pickers, and `GlassContainer.card` in 2.0.0.

### Rule 2: NEVER Nest Refractive Glass inside Refractive Glass
Placing refractive glass widgets inside another refractive glass container is an optical and performance anti-pattern.
- **CRITICAL ANTI-PATTERN:** Placing glass-mode `GlassButton`, `GlassIconButton`, or `GlassToggle.button` inside a glass-mode `GlassContainer.card`, `GlassGroupedSection`, `GlassDialog`, or `GlassContainer`.
- **Why?** These controls provide their own persistent refractive surface. Nesting creates severe double-refraction distortion, clips spring jelly animations, and wastes GPU fill-rate.
- **Exception — `GlassSwitch`, `GlassSlider`, `GlassSegmentedControl`:** their glass is transient (only the thumb or pill turns to glass while it is touched or moving; at rest they look flat), so they are safe inside a `GlassContainer.card` / `GlassGroupedSection` with `surfaceStyle: GlassSurfaceStyle.solid`, which has no glass layer at all. This is the native iOS Settings pattern. On a default `glass` card, prefer placing them outside the card.
- **Correct Pattern:**
  - In a `solid` card or `GlassGroupedSection`: standard text and icons, `GlassListTile`, `GlassTextField` / `GlassSearchBar` / `GlassTextArea` / `GlassPasswordField` / `GlassPicker` / `GlassToggle.button` / `GlassButton` / `GlassButton.custom` / `GlassIconButton` (all auto-inherit `solid` styling at zero shader cost via `InheritedGlassSurfaceStyle`), `GlassSwitch`, `GlassSlider`, and `GlassSegmentedControl`.
  - In a `GlassModalSheet` with dense controls or filter toggles (`1.x`): pass `surfaceStyle: GlassSurfaceStyle.solid` to the sheet when it should be opaque, or else wrap the sheet's `builder` content in `InheritedGlassSurfaceStyle(surfaceStyle: GlassSurfaceStyle.solid, child: ...)`, so nested buttons, toggles, inputs, and pickers inherit zero-shader solid wells instead of double-refracting over the sheet or allocating per-control shader layers during drags (becomes the default in `2.0.0`).
  - In a `glass` card: standard text, icons, and non-refractive controls (or `GlassListTile`, which has no internal glass layer).
  - Outside the card / on the page platter: `GlassSegmentedControl`, `GlassButton`, `GlassIconButton`, `GlassSlider`, or standalone `GlassSwitch(useOwnLayer: true)`.

### Rule 3: Single Public Import
- **ALWAYS**: `import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';`
- **NEVER** import `package:liquid_glass_widgets/src/...`.
- **NEVER** instantiate `LiquidGlass(...)` directly — it is an internal Impeller-only renderer. Always use `AdaptiveGlass` or the high-level `Glass*` widgets.

### Rule 4: Ban Obsolete Pre-1.0 APIs
- `GlassBottomBar` and `GlassSearchableBottomBar` were **deleted** in v1.0.0.
- **ALWAYS USE**: `GlassTabBar.bottom(...)` or `GlassTabBar.searchable(...)`.

### Rule 5: Honor Quality Tiers
- **`GlassQuality.premium`**: Multi-pass Impeller shader with chromatic dispersion, realistic refraction, and dynamic specular highlights. Default under `GlassStyle.ios27` (default) and `GlassStyle.ios26` for:
  - Persistent navigation chrome (`GlassAppBar`, `GlassTabBar`, `GlassToolbar`, `GlassScaffold.bodyOverlays` — automatically wrapped in `GlassIsolationScope(defaultQuality: GlassQuality.premium)`).
  - Transient overlays (`GlassDialog`, `showGlassConfirmationDialog`, `GlassMenu`, `GlassPopover`, `GlassToast`).
  - Hero interactive lenses (`GlassSwitch`, `GlassSlider`, `GlassSegmentedControl` — where `GlassSwitch` and `GlassSlider` lazy-mount `LiquidGlass.withOwnLayer` only while pressed/dragged so resting list rows mount zero shader layers).
- **`GlassQuality.standard`**: Highly optimized single-pass fragment shader. Default for cards, containers, standalone body buttons, input fields, and all widgets when `GlassThemeData(style: GlassStyle.classic)` is active.
- **`GlassQuality.minimal`**: Lightweight shader-free fallback (`BackdropFilter` only). Use for ultra-dense scrolling lists or low-power modes.
- **Avoid setting `quality: GlassQuality.standard` globally on `GlassThemeData`** unless you intentionally want to downgrade navigation bars, overlays, and hero lenses across the app.

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

      // Choose one of the built-in presets:
      // - const GlassThemeData() or const GlassThemeData.ios27() (default iOS 27 optics)
      // - const GlassThemeData.ios26() (iOS 26.0 optics)
      // - const GlassThemeData.classic() (v1.x classic look & GlassQuality.standard defaults)
      // - const GlassThemeData.minimal() (shader-free BackdropFilter with neutral light/dark tints)
      // Or customize via GlassThemeData.simple(style: GlassStyle.ios27, ...):
      theme: const GlassThemeData(),
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
2. **Edge Fading & iOS 27 Scroll-Under Coordination**: Coordinates automatically with `GlassAppBar`'s iOS 27 scroll-under blur + hairline (`GlassAppBarSurfaceStyle.automatic`) while keeping bottom-bar and iOS 26 soft/blur/hard edge fading (`.scrollEdgeEffectStyle`).
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
          // Content cards in scrolling lists use GlassSurfaceStyle.solid
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
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
| `Scaffold` | `GlassScaffold` | Handles z-order, edge fading, content-aware brightness, and native rounded page clipping during route transitions (`transitionCornerRadius`). |
| `AppBar` / `CupertinoNavigationBar` | `GlassAppBar` | Supports `.pinned` for gel morph and `surfaceStyle` (`GlassAppBarSurfaceStyle.automatic` default: iOS 27 scroll-under full-width blur + 1px hairline under `GlassStyle.ios27`, transparent under `GlassStyle.ios26`/`classic`; override with `.fullBlur` / `.transparent`, `automaticSurfaceVisibility`, `surfaceAppearanceExtent`, `backdropBlurSigma`, `backdropTint`, `bottomBorder`, `notificationPredicate`). |
| `BottomNavigationBar` / `CupertinoTabBar` | `GlassTabBar.bottom` | Unified glass navigation pill (`GlassBottomBar` is deleted). `settings:` styles the bar platter; `indicatorSettings:` (e.g. `LiquidGlassSettings.classicIndicator`) styles the animated pill; `indicatorJelly:` tunes native iOS 26/27 travel stretch & landing squish (`IndicatorJellyPhysics.native` default, `.disabled` for classic velocity squash); `indicatorLens:` tunes native iOS 26/27 lifted lens content-fold & spectral-fringe optics (`IndicatorLensOptics.native` default on Impeller `premium`, `.disabled` for single-pass refraction; `magnification` defaults to `1.16`). Optional `extraButton: GlassTabBarExtraButton(..., selected: true)` marks a destination extra button as active and suppresses the pill's selection state. |
| Bottom nav that collapses to selected tab on scroll | `GlassTabBar.minimizable` | Minimizes to a single pill on scroll; supports an optional trailing action button. |
| `ElevatedButton` / `CupertinoButton` | `GlassButton` / `GlassButton.custom` | Refractive glass button (`style`: `filled`, `prominent`, `transparent`; optional `tintColor` via `GlassBodyMode.clear` and `pressLightColor`), or zero-shader solid button (`surfaceStyle: GlassSurfaceStyle.solid` + optional `color`, or auto-inherited inside a solid card/section) preserving `LiquidStretch` bounce and contrast-aware foregrounds. |
| `IconButton` | `GlassIconButton` | Circular or continuous superellipse (`GlassIconButtonShape.roundedSquare`) button with `onPressed`, `style` (`filled`, `prominent`, `transparent`), `iconColor`, `tintColor`, and `surfaceStyle: GlassSurfaceStyle.solid` + `color` (or auto-inherited inside a solid card). |
| `FilterChip` / `ToggleButton` / SwiftUI `Toggle(.button)` | `GlassToggle.button` | Native iOS 26/27 capsule toggle (`value`, `onChanged` nullable to disable, optional `label`, `icon`, or custom `child`, `activeColor`, `foregroundColor`, `activeForegroundColor`, `surfaceStyle`). Transitions from clear refractive glass (off) to prominent tinted glass (on) with auto-contrasted foreground and single-node `toggled` semantics, or auto-inherits `GlassSurfaceStyle.solid` inside solid cards/sections. Supersedes deprecated `GlassChip`. |
| `PopupMenuButton` / Pull-Down Menu | `GlassPullDownButton` | Combined trigger button and `GlassMenu`. `buttonWidth` is nullable (`44.0` icon-only default; intrinsic capsule width when `label` is set); `onSelected` recurses into `submenu`s; forwards `menuPadding` (default `horizontal: 12`), `menuBorderRadius`, `morphSpeed`, `controller`, `onClose`, and `menuSemanticLabel` (`GlassMenu` also supports `opaqueColor` and `border`). |
| Custom popover card / SwiftUI `.popover` | `GlassPopover` | Liquid-morphs custom content (`contentBuilder: (ctx, close) => ...`) from `trigger` or `triggerBuilder`; supports `controller` (`GlassPopoverController` with `open`/`close`/`toggle`/`isOpen`), `morphSpeed`, and `platformViewBackdrop`. |
| `CupertinoSegmentedControl` | `GlassSegmentedControl<T>` | Fluid animated glass indicator with native iOS 26/27 jelly physics (`settings:` for track, `indicatorSettings:` for pill, `indicatorJelly:` for `IndicatorJellyPhysics.native` / `.disabled`, horizontal only). Fine inside `solid` cards; on a `glass` card place it outside. |
| `Switch` / `CupertinoSwitch` | `GlassSwitch` | Fluid spring jump animation, RTL-aware, honours `MediaQuery.onOffSwitchLabelsOf` (`onLabelColor` / `offLabelColor`). Pass `onChanged: null` to disable. Use `useOwnLayer: true` when standalone. |
| `Slider` / `CupertinoSlider` | `GlassSlider` | Glass track with draggable jelly thumb and haptic snaps. |
| `Card` | `GlassContainer.card` | Container for grouping content (`surfaceStyle: GlassSurfaceStyle.solid` for flat list cards). Content inside stays opaque. |
| Grouped `ListView` | `GlassGroupedSection` | Inset grouped list container with automatic dividers between `GlassListTile`s. |
| `ListTile` | `GlassListTile` | Grouped row item. Shares parent glass layer inside `GlassGroupedSection`. |
| `Divider` | `GlassDivider` | Refractive subtle separator line. |
| `Dismissible` / SwiftUI `.swipeActions` | `GlassSwipeActions` (or `GlassListTile.trailingSwipeActions` / `leadingSwipeActions`) | Leading/trailing circular action buttons with full-swipe (`enabled` toggles drag without remounting `child`; `backgroundColor` / `swipeBackgroundColor` overrides the swiped-row highlight). Wrap the list in `GlassSwipeActionScope` so only one row is open. See Section 6. |
| `ExpansionTile` / SwiftUI `DisclosureGroup` | `GlassDisclosureGroup` | Rotating-chevron accordion. Use inside `GlassGroupedSection`, or `GlassDisclosureGroup.standalone(surfaceStyle: ...)` for its own card. |
| `ReorderableListView` + edit toggle | `GlassEditScope` + `GlassEditButton` + `GlassReorderableList.grouped` | Edit mode with delete badges, reorder grabbers, selection. See Section 6. |
| Long-press context menu / SwiftUI `.contextMenu` | `GlassContextMenu` (or `.glassContextMenu()`, `GlassListTile.contextMenuActions`) | Row-lift menu with optional `previewBuilder`. Use `GlassPullDownButton` for tap-triggered menus. |
| Full-screen `showDialog` / `.fullScreenCover` | `showGlassFullScreenCover` + `GlassFullScreenCover` | Edge-to-edge slide-up cover with swipe-down dismiss. |
| `showDatePicker` / `CupertinoDatePicker` | `GlassDatePicker` (`.compact`, `.graphical`, `.wheel`), `GlassMultiDatePicker` | `showGlassDatePicker(...)` returns `DateTime?` (caps modal width to `maxWidth = 400` on desktop/iPad by default and tints header actions via `tintColor`). |
| `Navigator.push` rows / SwiftUI `NavigationStack` | `GlassNavigationStack` + `GlassNavigationLink` + `GlassPageRoute` | Typed `value` routing via `destinations`, or a `destination` builder. Automatically clips pages with rounded superellipse corners during push/pop and swipe-back (`transitionCornerRadius`; use `GlassPageTransitionsBuilder` in `MaterialApp.theme.pageTransitionsTheme`). |
| `TextField` / `CupertinoTextField` | `GlassTextField` / `GlassSearchBar` / `GlassTextArea` / `GlassPasswordField` / `GlassPicker` | Refractive glass input with press glow/scale (`glass`), or shader-free iOS `tertiarySystemFill` well (`surfaceStyle: GlassSurfaceStyle.solid` or auto-inherited inside a solid card). Forwards `autofillHints`, `autocorrect`, `enableSuggestions`, and `selectionControls` (e.g. `materialTextSelectionHandleControls` on Android); `GlassSearchBar` also supports `cancelButtonAlwaysVisible`. |
| `showModalBottomSheet` | `GlassModalSheet.show` | Multi-detent fluid sheet (peek, half, full, or fitted to its content) with spring physics, optional `morphFrom` (`GlassMorphTrigger`) liquid-morph presentation, and `surfaceStyle: GlassSurfaceStyle.solid` for a sheet that is opaque at every detent. |
| `showDialog` / `CupertinoAlertDialog` | `GlassDialog.show` | Centered 320 pt iOS 26/27 alert platter with 48 pt capsule `GlassDialogAction` buttons (280 pt on `GlassStyle.classic`); `isPrimary: true` renders a solid accent capsule (`tintColor ?? CupertinoTheme.primaryColor`, auto-contrast white/black or explicit `foregroundColor`, hardware `Return`/`Enter` activation, reverting to neutral when disabled); optional `shape`, `actionShape`, and `actionTextStyle` overrides. |
| `showCupertinoModalPopup` / `CupertinoActionSheet` / `.confirmationDialog()` | `showGlassConfirmationDialog` | Native iOS 26/27 confirmation dialog (`GlassConfirmationDialogAction`): anchors and liquid-morphs as a `240 pt` floating popover platter from `morphFrom` (`GlassMorphTrigger`) or `morphFromRect` (omitting Cancel by default), or falls back to the centered `320 pt` platter with Cancel when unanchored. Supersedes deprecated `showGlassActionSheet`. |
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
    // Wrap dense controls, chips, or inputs in InheritedGlassSurfaceStyle
    // (1.x opt-in; scheduled to become the default in 2.0.0) so nested controls
    // render shader-free solid wells instead of double-refracting during drags.
    return InheritedGlassSurfaceStyle(
      surfaceStyle: GlassSurfaceStyle.solid,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Modal Sheet Content',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  },
);
```

For a sheet that follows its content height, pass
`detents: const {GlassSheetDetent.fitted}`. The sheet is never taller than
`fullSize`; `halfSize` has no effect. `GlassSheetDetent.fitted` must be the
only detent, in `GlassSheetMode.dismissible`; any other set that holds it
asserts in debug.
The sheet opens at its fitted height for any `initialState` except `hidden`,
and reports `GlassSheetState.half`. The same detent works on the embedded
sheet, its scaffold, and `GlassModalSheet.show`, including morph
presentations. Use a `Column(mainAxisSize: MainAxisSize.min)` for naturally
sized content. For longer content, put a scroll view inside `Flexible` and use
the controller and physics from `ScrollControllerProvider.of(context)!`.
Bottom safe-area or keyboard padding supplied by the child counts toward the
fitted height. For a minimum height, wrap the child in a `ConstrainedBox` with
a `minHeight`.

The sheet's surface is set by `surfaceStyle`. The default,
`GlassSurfaceStyle.glass`, is glass that turns opaque toward the large detent.
`GlassSurfaceStyle.solid` is opaque at every detent, and while the sheet
moves, in `expandedColor` (or `expandedDarkColor` in dark mode). The
per-state settings and `fillThreshold` then do not change the surface. A solid
sheet publishes `GlassSurfaceStyle.solid` to its content, so you do not need
the `InheritedGlassSurfaceStyle` wrapper shown above. A glass sheet publishes
nothing; keep the wrapper there. For an always-opaque fitted sheet:

```dart
GlassModalSheet.show(
  context: context,
  detents: const {GlassSheetDetent.fitted},
  surfaceStyle: GlassSurfaceStyle.solid,
  builder: (sheetContext) => const MySheetBody(),
);
```

### GlassDialog
Presents a native alert dialog:

```dart
GlassDialog.show(
  context: context,
  title: 'Save Changes?',
  message: 'Your edits will be saved to iCloud.',
  actions: [
    GlassDialogAction(
      label: 'Cancel',
      onPressed: () => Navigator.of(context).pop(),
    ),
    GlassDialogAction(
      label: 'Continue',
      isPrimary: true, // Native iOS 26/27 prominent filled capsule (CupertinoTheme.primaryColor; override with tintColor / foregroundColor)
      onPressed: () {
        Navigator.of(context).pop();
        _saveChanges();
      },
    ),
  ],
);
```

- Set `isPrimary: true` (matching `UIAlertController.preferredAction` / SwiftUI `.keyboardShortcut(.defaultAction)`) to fill the action capsule with `tintColor ?? CupertinoTheme.of(context).primaryColor` (which automatically bridges `Theme.of(context).colorScheme.primary` in `MaterialApp`), render high-contrast `FontWeight.w600` text, and bind the hardware `Return`/`Enter` key when a single enabled primary action is present (at most one primary action per dialog). Pass `tintColor` (supporting `CupertinoDynamicColor`) and optional `foregroundColor` to override the accent or text color.
- Destructive actions (`isDestructive: true`) keep the neutral capsule with `CupertinoColors.systemRed` text (even when `isPrimary: true`, matching native iOS 26/27) unless an explicit `tintColor` is supplied.
- Pass `onPressed: null` on a `GlassDialogAction` to keep it in place as a disabled action (for example, while waiting on valid input); disabled primary/tinted actions revert to the neutral capsule wash with `CupertinoColors.tertiaryLabel` text.

### showGlassConfirmationDialog
Presents an iOS 26/27 confirmation dialog (`.confirmationDialog()`), superseding deprecated `showGlassActionSheet`:

```dart
// Source-anchored (recommended on iOS 26/27): 240 pt liquid-morphing popover,
// omitting Cancel by default because tapping outside dismisses.
GlassMorphTrigger(
  builder: (context, anchor) => GlassIconButton(
    icon: const Icon(CupertinoIcons.trash),
    onPressed: () => showGlassConfirmationDialog<void>(
      context: context,
      morphFrom: anchor,
      title: 'Delete Draft?',
      message: 'This draft cannot be recovered once deleted.',
      actions: [
        GlassConfirmationDialogAction(
          label: 'Save Draft',
          onPressed: _saveDraft,
        ),
        GlassConfirmationDialogAction(
          label: 'Delete Draft',
          isDestructive: true,
          onPressed: _deleteDraft,
        ),
      ],
    ),
  ),
)
```

- Omit `morphFrom` / `morphFromRect` for an unanchored centered `320 pt` platter with a localized Cancel button included by default (`showCancelButton` overrides either default).
- Actions auto-dismiss on tap by default (`dismissOnPress: true`) without double-popping if `onPressed` calls `Navigator.pop(context, value)`. Supports `isDestructive`, `isPrimary` (`Return`-key activation), `tintColor`, `foregroundColor`, and disabled (`onPressed: null`) actions.

### GlassMenu Submenus
Give a `GlassMenuItem` a `submenu` list to open a native iOS-style card over the parent (the parent recedes and dims; tapping the card's header or the exposed parent collapses one level). Submenus nest. Works in `GlassMenu` and `GlassPullDownButton`:

```dart
GlassPullDownButton(
  icon: const Icon(CupertinoIcons.ellipsis_circle),
  items: [
    GlassMenuItem(
      title: 'Share…',
      icon: const Icon(CupertinoIcons.share),
      // onTap is required but never called on a submenu row:
      // activating it opens the card instead.
      onTap: () {},
      submenu: [
        GlassMenuItem(title: 'Messages', icon: const Icon(CupertinoIcons.chat_bubble_fill), onTap: _sendMessage),
        GlassMenuItem(title: 'Mail', icon: const Icon(CupertinoIcons.mail_solid), onTap: _sendMail),
      ],
    ),
    const GlassMenuDivider(),
    GlassMenuItem(title: 'Delete', icon: const Icon(CupertinoIcons.trash), isDestructive: true, onTap: _delete),
  ],
)
```

- A submenu row shows a chevron automatically unless you pass `trailing`.
- `GlassPullDownButton.onSelected` fires for both top-level items and nested `submenu` items, and omitting `buttonWidth` sizes labeled buttons intrinsically as a capsule (`44.0` when icon-only).
- Do **not** build nested menus by opening a second `GlassMenu` from an item's `onTap`; use `submenu`.
- Use `GlassMenuItem.semanticsSelected: true` (alongside a checkmark `trailing`) to announce the active choice to VoiceOver/TalkBack (`semanticsChecked` on macOS where VoiceOver expects radio checked state) without keeping the hover highlight visible, and `semanticLabel` when `trailing` adds visual-only text like keyboard shortcuts.

### GlassMaterialize
For widgets appearing or disappearing dynamically, use `GlassMaterialize` to match iOS 26's progressive defogging transition:

```dart
GlassMaterialize(
  visible: _showFilterPill,
  child: GlassToggle.button(
    value: _filterActive,
    onChanged: (next) => setState(() => _filterActive = next),
    icon: const Icon(CupertinoIcons.line_horizontal_3_decrease),
    label: 'Active Filters',
  ),
)
```

---

## 6. Lists, Pickers & Declarative Navigation

Use `surfaceStyle: GlassSurfaceStyle.solid` on list cards (`GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`, date pickers) and standalone scrolling inputs/toggles/buttons (`GlassTextField`, `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, `GlassPicker`, `GlassToggle.button`, `GlassButton`, `GlassButton.custom`, `GlassIconButton`). Inputs, pickers, toggle buttons, and buttons placed inside a `solid` card or `GlassGroupedSection` inherit `GlassSurfaceStyle.solid` automatically via `InheritedGlassSurfaceStyle`. For an app-wide iOS 27 material pass `theme: const GlassThemeData.ios27()` to `LiquidGlassWidgets.wrap()` (or wrap a subtree in `GlassTheme(data: const GlassThemeData.ios27(), ...)`).

### Swipe actions, context menu, disclosure
```dart
GlassSwipeActionScope(               // one open row at a time; wrap the whole list
  child: ListView(children: [
    GlassGroupedSection(
      surfaceStyle: GlassSurfaceStyle.solid,
      children: [
        GlassListTile(
          title: const Text('Alex Rivera'),
          trailingSwipeActions: [
            GlassSwipeAction(
              icon: const Icon(CupertinoIcons.trash),
              label: const Text('Delete'),
              isDestructive: true,
              onTap: _delete,        // GlassSwipeAction uses onTap
            ),
          ],
          onDismissed: _delete,      // full-swipe collapse
          contextMenuActions: [
            GlassContextMenuAction(
              icon: const Icon(CupertinoIcons.star),
              child: const Text('Favorite'),   // label is `child`, handler is `onPressed`
              onPressed: _favorite,
            ),
          ],
        ),
        GlassDisclosureGroup(
          title: const Text('Privacy'),
          children: [
            GlassListTile(
              title: const Text('AirDrop'),
              trailing: GlassSwitch(value: _airDrop, onChanged: (v) => setState(() => _airDrop = v)),
            ),
          ],
        ),
      ],
    ),
  ]),
)
```

### Edit mode and reordering
`GlassEditScope` provides ambient edit state; `GlassEditButton` toggles it. `GlassListTile` reacts via `canDelete`/`onDelete`, `canReorder`/`reorderIndex`, `canSelect`/`isSelected`/`onSelectedChanged`:
```dart
GlassEditScope(
  child: Column(children: [
    const GlassEditButton(),
    GlassReorderableList.grouped(
      surfaceStyle: GlassSurfaceStyle.solid,
      itemCount: items.length,
      onReorderItem: (oldIndex, newIndex) =>
          setState(() => items.insert(newIndex, items.removeAt(oldIndex))),
      itemBuilder: (context, i) => GlassListTile(
        key: ValueKey(items[i]),      // key required
        title: Text(items[i]),
        canReorder: true,
        reorderIndex: i,
        canDelete: true,
        onDelete: () => setState(() => items.removeAt(i)),
      ),
    ),
  ]),
)
```

### Full-screen cover and date pickers
```dart
showGlassFullScreenCover<void>(
  context: context,
  builder: (ctx) => GlassFullScreenCover(
    title: const Text('New Contact'),
    closeButtonLabel: 'Done',
    child: const ContactForm(),
  ),
);

GlassDatePicker.compact(
  initialDateTime: DateTime.now(),
  mode: GlassDatePickerMode.dateAndTime,
  surfaceStyle: GlassSurfaceStyle.solid,
  onDateTimeChanged: (d) => setState(() => _date = d),
)
```
`GlassDatePicker.graphical` and `.wheel` share these parameters; `GlassMultiDatePicker(selectedDates: Set<DateTime>, onDatesChanged: ...)` selects multiple days.

### Navigation stack
```dart
GlassNavigationStack(
  path: _path,                                     // optional GlassNavigationPath; _path.append(value) pushes
  destinations: {String: (context, value) => DetailPage(value as String)},
  root: const HomePage(),
)

// Inside a GlassGroupedSection on the root page:
GlassNavigationLink<String>(value: 'Optics', title: const Text('Optics'))
// or: GlassNavigationLink(destination: (ctx) => const DetailPage(), title: ...)

// Inside a page, `.navigationTitle('Detail')` supplies the title of a GlassAppBar / GlassAppBar.pinned that has `title: null`.
```

---

## 7. Advanced Navigation: Gel Morph with `GlassNavigationShell`

To achieve the signature iOS 26 navigation bar transition — where the capsule swells, bounces, and cross-fades icons between routes:

1. **Wrap the Navigator** in `GlassNavigationShell` (typically in `CupertinoApp.builder`):

```dart
CupertinoApp(
  builder: (context, child) => GlassNavigationShell(
    swipeCommitTransition: GlassSwipeCommitTransition.crossFade, // optional: plain cross-fade on back-swipe
    verticalBarBehavior: GlassVerticalBarBehavior.automatic,     // optional: iPhone Duo vertical strip
    child: child!,
  ),
  home: const HomeScreen(),
)
```

2. Use `GlassAppBar.pinned` on destination screens. Items are declared as `GlassBarItem` data (not arbitrary widgets), which allows the shell to hoist them above the `Navigator` and morph them across routes:

```dart
GlassAppBar.pinned(
  title: const Text('New Event'),
  leading: [
    // Titled bar item (UIBarButtonItem(title:)): plain style shares background
    GlassBarItem.text(
      title: 'Cancel',
      onTap: () => Navigator.of(context).pop(),
    ),
  ],
  actions: [
    // GlassBarItem.icon uses `onTap` (not `onPressed`)
    GlassBarItem.icon(
      icon: const Icon(CupertinoIcons.share),
      onTap: () => _share(),
    ),
    // Prominent confirmation action (iOS 26/27 UIBarButtonItem.Style.prominent / .glassProminent):
    // automatically separates its capsule, floods with tintColor ?? primaryColor at 85% alpha,
    // renders semibold contrast text/icons, and reverts to neutral glass when enabled: false.
    GlassBarItem.text(
      title: 'Save',
      style: GlassBarItemStyle.prominent,
      onTap: _save,
    ),
  ],
)
```

> **Note:** `GlassBarItemStyle.prominent` works on all five action constructors (`.icon`, `.text`, `.custom`, `.menu`, `.sheet`). Pass `tintColor` to override `CupertinoTheme.of(context).primaryColor`; `background` defaults to `GlassBarItemBackground.separate` when prominent (combining `prominent` with `shared` asserts in debug mode). Without `GlassNavigationShell`, `GlassAppBar.pinned` falls back gracefully — items render inside the bar in-route, so all screens work either way.

> **iPhone Duo:** Under the shell, pinned bars, `GlassTabBar.bottom` / `.searchable`, `GlassToolbar` and `GlassLargeTitle` move into the vertical bar strip on their own; pass a large title's controller to its `GlassAppBar.pinned`, which draws the title there. A `GlassAppBar.pinned` inside a `GlassModalSheet` follows the sheet, whose `placement` mirrors `presentationPlacement(_:)`. `GlassBarItem.text` and `GlassBarItem.custom` stay in the horizontal row by default; pass `axisBehavior: GlassBarItemAxisBehavior.verticalPreferred` for items that should go into the 48pt strip, and read `GlassVerticalBar.maybeOf(context)` to fit a bar the package does not draw.

---

## 8. Common Agent Pitfalls (Checklist before outputting code)

- [ ] **Did you import the public API only?** (`import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';`). Never import `src/`.
- [ ] **Did you call `await LiquidGlassWidgets.initialize()` in `main()`?** Shaders must be pre-warmed.
- [ ] **Did you wrap your app in `LiquidGlassWidgets.wrap()`?** Required for theme and accessibility scaling.
- [ ] **Are you using `GlassScaffold` instead of `Scaffold`?** Prevents z-index glitches with glass nav bars.
- [ ] **Did you avoid nesting glass in glass?** Never put glass-mode `GlassButton`, `GlassIconButton`, or `GlassToggle.button` inside a `glass`-mode `GlassContainer.card` or `GlassGroupedSection`. Inside a `solid` card/section (`surfaceStyle: GlassSurfaceStyle.solid`) or a `GlassModalSheet` with `surfaceStyle: GlassSurfaceStyle.solid` or wrapped in `InheritedGlassSurfaceStyle(surfaceStyle: GlassSurfaceStyle.solid, child: ...)`, `GlassSwitch`, `GlassSlider`, and `GlassSegmentedControl` are safe (their glass is transient) and `GlassButton`, `GlassIconButton`, `GlassToggle.button`, `GlassTextField`, and `GlassPicker` auto-inherit `solid`.
- [ ] **Did you use `GlassTabBar.bottom` instead of `GlassBottomBar`?** `GlassBottomBar` is deleted.
- [ ] **`GlassButton` uses `onTap`, not `onPressed`.** (`GlassButton(onTap: () {})`) — the opposite of `ElevatedButton`.
- [ ] **`GlassIconButton` uses `onPressed`, not `onTap`.** (`GlassIconButton(onPressed: () {})`).
- [ ] **`GlassToggle.button` uses `value` + `onChanged` (nullable to disable), and `label` is a `String?`, not a `Widget`.** Pass `child:` for arbitrary custom content, and `semanticLabel:` for icon-only toggles.
- [ ] **`GlassAppBar` uses `actions: [...]` (a List), not `trailing:`.** There is no `trailing` parameter.
- [ ] **`GlassBarItem.icon` and `GlassBarItem.text` use `onTap` (required), not `onPressed`.**
- [ ] **`GlassBarItem.text` uses `title:` (a `String`), not `child:` or `label:`.** Optional `label:` overrides only the screen-reader accessible name and Duo overflow menu entry.
- [ ] **`GlassBarItem.custom` takes an optional `onTap` — omit it when the child is already a button.** Omitting `onTap` leaves the slot passive; passing a no-op `onTap: () {}` wraps the child in a second, unlabelled button for screen readers.
- [ ] **Nested menus use `GlassMenuItem(submenu: [...])`.** The parent row still needs `onTap: () {}` (required, never called). Don't open a second `GlassMenu` from `onTap`.
- [ ] **Use `style: GlassBarItemStyle.prominent` for iOS 26/27 confirmation/primary bar actions.** It automatically defaults `background` to `separate` and fills with `tintColor ?? CupertinoTheme.of(context).primaryColor` (reverting to neutral glass when `enabled: false`). Combining `prominent` or `tintColor` with `background: GlassBarItemBackground.shared` asserts in debug mode. The foreground icon/text colour flips automatically — do not also set a manual `Icon(color:)` or `textStyle` colour unless overriding contrast.
- [ ] **`GlassSwipeAction` uses `onTap`; `GlassContextMenuAction` uses `child` + `onPressed`.** Wrap swipeable lists in `GlassSwipeActionScope`.
- [ ] **Don't hand-roll `Dismissible`, `ExpansionTile`, `showDatePicker` or a `ReorderableListView` edit mode** — use `GlassSwipeActions`, `GlassDisclosureGroup`, `GlassDatePicker` and `GlassEditScope` + `GlassReorderableList`.
- [ ] **`GlassReorderableList` items need a stable `key`**, and either `onReorder` or `onReorderItem` must be provided.
- [ ] **Deprecated widgets (removed in 2.0.0):** Use `GlassContainer.card` instead of `GlassCard`, `showGlassConfirmationDialog` instead of `showGlassActionSheet`, `GlassToggle.button` (or capsule `GlassButton.custom`) instead of `GlassChip`, and `GlassModalSheet` instead of `GlassSheet`.
