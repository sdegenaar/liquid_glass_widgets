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
Glass in the iOS 26 design system is reserved for the **navigation and control layer** — floating chrome that sits above content.
- **DO use glass for:** Navigation bars (`GlassAppBar`), tab bars (`GlassTabBar`), floating buttons (`GlassButton`, `GlassIconButton`), toolbars, modal sheets (`GlassModalSheet`), dialogs (`GlassDialog`), and standalone floating cards (`GlassContainer.card`).
- **DO NOT use glass for:** Full-screen backgrounds, dense list view items, video players, image galleries, or text article bodies. Backgrounds should be rich wallpapers or gradients; content cards should be clean and readable. Cards and inputs inside scrolling lists should use `surfaceStyle: GlassSurfaceStyle.solid` (on `GlassContainer.card`, `GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`, `GlassDatePicker`, `GlassMultiDatePicker`, `GlassTextField`, `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, or `GlassPicker`): a flat opaque card or translucent input well matching native iOS inset-grouped lists. Inputs and pickers placed inside a solid card/section inherit `solid` automatically via `InheritedGlassSurfaceStyle`. `glass` is the 1.x default; `solid` becomes the default in 2.0.0.

### Rule 2: NEVER Nest Refractive Glass inside Refractive Glass
Placing refractive glass widgets inside another refractive glass container is an optical and performance anti-pattern.
- **CRITICAL ANTI-PATTERN:** Placing `GlassButton`, `GlassIconButton` or `GlassChip` inside a `GlassContainer.card`, `GlassGroupedSection`, or `GlassContainer`.
- **Why?** These controls provide their own persistent refractive surface. Nesting creates severe double-refraction distortion, clips spring jelly animations, and wastes GPU fill-rate.
- **Exception — `GlassSwitch`, `GlassSlider`, `GlassSegmentedControl`:** their glass is transient (only the thumb or pill turns to glass while it is touched or moving; at rest they look flat), so they are safe inside a `GlassContainer.card` / `GlassGroupedSection` with `surfaceStyle: GlassSurfaceStyle.solid`, which has no glass layer at all. This is the native iOS Settings pattern. On a default `glass` card, prefer placing them outside the card.
- **Correct Pattern:**
  - In a `solid` card or `GlassGroupedSection`: standard text and icons, `GlassListTile`, `GlassTextField` / `GlassSearchBar` / `GlassTextArea` / `GlassPasswordField` / `GlassPicker` (auto-inherit `solid` well styling), `GlassSwitch`, `GlassSlider` and `GlassSegmentedControl`.
  - In a `glass` card: standard text, icons, and non-refractive controls (or `GlassListTile`, which has no internal glass layer).
  - Outside the card / on the page platter: `GlassSegmentedControl`, `GlassButton`, `GlassSlider`, or standalone `GlassSwitch(useOwnLayer: true)`.

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
  - Transient overlays (`GlassDialog`, `showGlassActionSheet`, `GlassMenu`, `GlassPopover`, `GlassToast`).
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

      // Choose one of three built-in design-era presets:
      // - const GlassThemeData() or const GlassThemeData.ios27() (default iOS 27 optics)
      // - const GlassThemeData.ios26() (iOS 26.0 optics)
      // - const GlassThemeData.classic() (v1.x classic look & GlassQuality.standard defaults)
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
          // Content cards stay opaque or use GlassContainer.card for grouping
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
| `Scaffold` | `GlassScaffold` | Handles z-order, edge fading, content-aware brightness, and native rounded page clipping during route transitions (`transitionCornerRadius`). |
| `AppBar` / `CupertinoNavigationBar` | `GlassAppBar` | Transparent iOS 26 style by default. Supports `.pinned` for gel morph. |
| `BottomNavigationBar` / `CupertinoTabBar` | `GlassTabBar.bottom` | Unified glass navigation pill (`GlassBottomBar` is deleted). `settings:` styles the bar platter; `indicatorSettings:` (e.g. `LiquidGlassSettings.classicIndicator`) styles the animated pill. |
| Bottom nav that collapses to selected tab on scroll | `GlassTabBar.minimizable` | Minimizes to a single pill on scroll; supports an optional trailing action button. |
| `ElevatedButton` / `CupertinoButton` | `GlassButton` | Refractive button with squeeze & stretch physics, touch glow, and optional `pressLightColor` (or `GlassGlowColors.pressLight` on `GlassThemeData`). |
| `IconButton` | `GlassIconButton` | Refractive circular/squircle button with `onPressed`. |
| `PopupMenuButton` / Pull-Down Menu | `GlassPullDownButton` | Combined trigger button and `GlassMenu` (`menuSemanticLabel` names the open panel; `GlassMenu` also supports `opaqueColor` and `border`). |
| `CupertinoSegmentedControl` | `GlassSegmentedControl<T>` | Fluid animated glass indicator with jelly physics (`settings:` for track, `indicatorSettings:` for pill). Fine inside `solid` cards; on a `glass` card place it outside. |
| `Switch` / `CupertinoSwitch` | `GlassSwitch` | Fluid spring jump animation, RTL-aware, honours `MediaQuery.onOffSwitchLabelsOf` (`onLabelColor` / `offLabelColor`). Use `useOwnLayer: true` when standalone. |
| `Slider` / `CupertinoSlider` | `GlassSlider` | Glass track with draggable jelly thumb and haptic snaps. |
| `Card` | `GlassContainer.card` | Container for grouping content (`surfaceStyle: GlassSurfaceStyle.solid` for flat list cards). Content inside stays opaque. |
| Grouped `ListView` | `GlassGroupedSection` | Inset grouped list container with automatic dividers between `GlassListTile`s. |
| `ListTile` | `GlassListTile` | Grouped row item. Shares parent glass layer inside `GlassGroupedSection`. |
| `Divider` | `GlassDivider` | Refractive subtle separator line. |
| `Dismissible` / SwiftUI `.swipeActions` | `GlassSwipeActions` (or `GlassListTile.trailingSwipeActions` / `leadingSwipeActions`) | Leading/trailing circular action buttons with full-swipe. Wrap the list in `GlassSwipeActionScope` so only one row is open. See Section 6. |
| `ExpansionTile` / SwiftUI `DisclosureGroup` | `GlassDisclosureGroup` | Rotating-chevron accordion. Use inside `GlassGroupedSection`, or `GlassDisclosureGroup.standalone(surfaceStyle: ...)` for its own card. |
| `ReorderableListView` + edit toggle | `GlassEditScope` + `GlassEditButton` + `GlassReorderableList.grouped` | Edit mode with delete badges, reorder grabbers, selection. See Section 6. |
| Long-press context menu / SwiftUI `.contextMenu` | `GlassContextMenu` (or `.glassContextMenu()`, `GlassListTile.contextMenuActions`) | Row-lift menu with optional `previewBuilder`. Use `GlassPullDownButton` for tap-triggered menus. |
| Full-screen `showDialog` / `.fullScreenCover` | `showGlassFullScreenCover` + `GlassFullScreenCover` | Edge-to-edge slide-up cover with swipe-down dismiss. |
| `showDatePicker` / `CupertinoDatePicker` | `GlassDatePicker` (`.compact`, `.graphical`, `.wheel`), `GlassMultiDatePicker` | `showGlassDatePicker(...)` returns `DateTime?`. |
| `Navigator.push` rows / SwiftUI `NavigationStack` | `GlassNavigationStack` + `GlassNavigationLink` + `GlassPageRoute` | Typed `value` routing via `destinations`, or a `destination` builder. Automatically clips pages with rounded superellipse corners during push/pop and swipe-back (`transitionCornerRadius`; use `GlassPageTransitionsBuilder` in `MaterialApp.theme.pageTransitionsTheme`). |
| `TextField` / `CupertinoTextField` | `GlassTextField` / `GlassSearchBar` / `GlassTextArea` / `GlassPasswordField` / `GlassPicker` | Refractive glass input with press glow/scale (`glass`), or shader-free iOS `tertiarySystemFill` well (`surfaceStyle: GlassSurfaceStyle.solid` or auto-inherited inside a solid card). |
| `showModalBottomSheet` | `GlassModalSheet.show` | Multi-detent fluid sheet (peek, half, full) with spring physics. |
| `showDialog` / `CupertinoAlertDialog` | `GlassDialog.show` | Centered 320 pt iOS 26/27 alert platter with 48 pt capsule `GlassDialogAction` buttons (280 pt on `GlassStyle.classic`). |
| `showCupertinoModalPopup` / `CupertinoActionSheet` | `showGlassActionSheet` | Centered 320 pt iOS 26/27 action sheet platter with stacked capsule `GlassActionSheetAction` buttons (bottom-docked sheet on `GlassStyle.classic`). |
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
- Do **not** build nested menus by opening a second `GlassMenu` from an item's `onTap`; use `submenu`.
- Use `GlassMenuItem.semanticsSelected: true` (alongside a checkmark `trailing`) to announce the active choice to VoiceOver/TalkBack (`semanticsChecked` on macOS where VoiceOver expects radio checked state) without keeping the hover highlight visible, and `semanticLabel` when `trailing` adds visual-only text like keyboard shortcuts.

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

## 6. Lists, Pickers & Declarative Navigation

Use `surfaceStyle: GlassSurfaceStyle.solid` on list cards (`GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`, date pickers) and standalone scrolling inputs (`GlassTextField`, `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, `GlassPicker`). Inputs placed inside a `solid` card or `GlassGroupedSection` inherit `GlassSurfaceStyle.solid` automatically via `InheritedGlassSurfaceStyle`. For an app-wide iOS 27 material pass `theme: const GlassThemeData.ios27()` to `LiquidGlassWidgets.wrap()` (or wrap a subtree in `GlassTheme(data: const GlassThemeData.ios27(), ...)`).

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
  title: const Text('Detail'),
  actions: [
    // GlassBarItem.icon uses `onTap` (not `onPressed`)
    GlassBarItem.icon(
      icon: const Icon(CupertinoIcons.square_and_arrow_up),
      onTap: () => _share(),
    ),
    // Tinted capsule (iOS 26 prominent action): set tintColor + separate background.
    // The capsule fills with the colour; foreground icon auto-flips to white/black.
    GlassBarItem.icon(
      icon: const Icon(CupertinoIcons.checkmark),
      onTap: _save,
      background: GlassBarItemBackground.separate,
      tintColor: CupertinoColors.activeBlue,
    ),
  ],
)
```

> **Note:** Without `GlassNavigationShell`, `GlassAppBar.pinned` falls back gracefully — items render inside the bar in-route, so all screens work either way.

> **iPhone Duo:** Under the shell, pinned bars, `GlassTabBar.bottom` / `.searchable`, `GlassToolbar` and `GlassLargeTitle` move into the vertical bar strip on their own; pass a large title's controller to its `GlassAppBar.pinned`, which draws the title there. A `GlassAppBar.pinned` inside a `GlassModalSheet` follows the sheet, whose `placement` mirrors `presentationPlacement(_:)`. Use `GlassBarItem.custom(axisBehavior: GlassBarItemAxisBehavior.verticalPreferred)` for custom content that should go with them, and read `GlassVerticalBar.maybeOf(context)` to fit a bar the package does not draw.

---

## 8. Common Agent Pitfalls (Checklist before outputting code)

- [ ] **Did you import the public API only?** (`import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';`). Never import `src/`.
- [ ] **Did you call `await LiquidGlassWidgets.initialize()` in `main()`?** Shaders must be pre-warmed.
- [ ] **Did you wrap your app in `LiquidGlassWidgets.wrap()`?** Required for theme and accessibility scaling.
- [ ] **Are you using `GlassScaffold` instead of `Scaffold`?** Prevents z-index glitches with glass nav bars.
- [ ] **Did you avoid nesting glass in glass?** Never put `GlassButton`, `GlassIconButton` or `GlassChip` directly inside `GlassContainer.card` or `GlassGroupedSection`. `GlassSwitch`, `GlassSlider` and `GlassSegmentedControl` are fine inside `solid` cards (their glass is transient); on `glass` cards keep them outside.
- [ ] **Did you use `GlassTabBar.bottom` instead of `GlassBottomBar`?** `GlassBottomBar` is deleted.
- [ ] **`GlassButton` uses `onTap`, not `onPressed`.** (`GlassButton(onTap: () {})`) — the opposite of `ElevatedButton`.
- [ ] **`GlassIconButton` uses `onPressed`, not `onTap`.** (`GlassIconButton(onPressed: () {})`).
- [ ] **`GlassAppBar` uses `actions: [...]` (a List), not `trailing:`.** There is no `trailing` parameter.
- [ ] **`GlassChip.label` is a `String`, not a `Widget`.** Pass `label: 'text'`, not `label: Text('text')`.
- [ ] **`GlassBarItem.icon` uses `onTap` (required), not `onPressed`.**
- [ ] **`GlassBarItem.custom` takes an optional `onTap` — omit it when the child is already a button.** Omitting `onTap` leaves the slot passive; passing a no-op `onTap: () {}` wraps the child in a second, unlabelled button for screen readers.
- [ ] **Nested menus use `GlassMenuItem(submenu: [...])`.** The parent row still needs `onTap: () {}` (required, never called). Don't open a second `GlassMenu` from `onTap`.
- [ ] **`tintColor` on `GlassBarItem` requires `background: GlassBarItemBackground.separate`.** A shared-background item cannot be tinted (asserts in debug mode). The foreground icon colour is flipped automatically — do not also set a manual `Icon(color:)` on the child.
- [ ] **`GlassSwipeAction` uses `onTap`; `GlassContextMenuAction` uses `child` + `onPressed`.** Wrap swipeable lists in `GlassSwipeActionScope`.
- [ ] **Don't hand-roll `Dismissible`, `ExpansionTile`, `showDatePicker` or a `ReorderableListView` edit mode** — use `GlassSwipeActions`, `GlassDisclosureGroup`, `GlassDatePicker` and `GlassEditScope` + `GlassReorderableList`.
- [ ] **`GlassReorderableList` items need a stable `key`**, and either `onReorder` or `onReorderItem` must be provided.
- [ ] **`GlassCard` is deprecated.** Use `GlassContainer.card`.
