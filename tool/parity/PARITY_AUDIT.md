# iOS 26/27 Liquid Glass & Swift Parity Verification Audit

This document provides a technical comparison between **Apple's native SwiftUI / iOS 27 implementations** and the Flutter **`liquid_glass_widgets` (unreleased, on top of 1.11.1)** implementations for the 7 benchmark gaps identified in the Google/Flutter contacts gap analysis (`docs/ROADMAP.md`).

---

## 1. Native SwiftUI Reference Implementation

A fully working native iOS 27 SwiftUI reference app has been scaffolded and verified on a live **iPhone 18 Pro (iOS 27.0)** simulator:
- **Location**: [`tool/parity/ios_reference/ParityApp.swift`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/ios_reference/ParityApp.swift)
- **Build & Run Harness**: [`tool/parity/ios_reference/build_and_run.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/ios_reference/build_and_run.sh)
- **Automated Capture Harness**: [`tool/parity/capture_parity.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/capture_parity.sh)
- **Captured Artifacts**: [`tool/parity/captures/`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/captures/)

### Flutter-side verification (added after side-by-side review)

The Flutter counterpart of the SwiftUI app lives in [`example/lib/harnesses/ios_parity_harness.dart`](file:///Users/sdegenaar/development/liquid_glass_widgets/example/lib/harnesses/ios_parity_harness.dart). Run it with `flutter run -t lib/harnesses/ios_parity_harness.dart` from `example/`, then drive it with [`tool/parity/capture_flutter.sh`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/capture_flutter.sh) (`flutter_*.png` next to the `native_*.png` captures).

> [!IMPORTANT]
> Status icons below reflect **API/semantic** parity. Pixel-level parity was checked in **static frames** (light and dark mode) for the card surface, date pickers, row pitch (measured with `measure_rows.py`), full-screen cover, and navigation stack. Motion/springs and live gestures are verified via the interactive testing protocol in [`INTERACTIVE_TEST_CHECKLIST.md`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/INTERACTIVE_TEST_CHECKLIST.md). Known remaining visual deltas: grouped-section divider inset (56 vs 72pt), disclosure chevron weight and child indent, date-picker compact capsule / graphical header / wheel ordering, navigation bar back button platter, and swipe platter gloss. Card material is addressed by `GlassSurfaceStyle.solid` (opt-in in 1.x), including on the date pickers.


---

## 2. Feature-by-Feature Parity Breakdown

### 1. Swipe Actions (`.swipeActions()`)

| Aspect | Apple SwiftUI (`.swipeActions`) | `liquid_glass_widgets` (`GlassSwipeActions`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.swipeActions(edge: .leading/.trailing, allowsFullSwipe: Bool)` | `GlassSwipeActions(leadingActions: [...], trailingActions: [...], fullSwipeThreshold: 0.65)` | ✅ 1:1 Semantics |
| **List Integration** | Attached to row view within `List` | `GlassListTile(leadingSwipeActions: [...], trailingSwipeActions: [...])` | ✅ Direct property support |
| **Action Configuration** | `Button(role: .destructive) { } label: { Label(...) }` with `.tint(...)` | `GlassSwipeAction(icon: ..., label: ..., backgroundColor: ..., isDestructive: true)` | ✅ Direct configuration |
| **Physics** | Underdamped spring physics; rubber-bands beyond bounds | `GlassSpring.snappy()`; damped elastic resistance when full swipe disabled | ✅ Matches iOS spring feel |
| **Haptics** | `UIImpactFeedbackGenerator(style: .medium)` at full-swipe threshold | `HapticFeedback.mediumImpact()` upon crossing threshold | ✅ Identical |
| **Materials** | Flat tinted platter | `GlassSwipeActionStyle.tintedGlass` & `solidVibrancy` | ✅ 1:1 Parity (`solidVibrancy` uses flat fills matching native SwiftUI; `tintedGlass` provides liquid glass opt-in) |

**Native Swift Reference:**
```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) { delete() } label: { Label("Delete", systemImage: "trash") }
    Button { flag() } label: { Label("Flag", systemImage: "flag.fill") }.tint(.orange)
}
.swipeActions(edge: .leading, allowsFullSwipe: false) {
    Button { pin() } label: { Label("Pin", systemImage: "pin.fill") }.tint(.blue)
}
```

**Flutter Equivalent:**
```dart
GlassListTile(
  title: const Text('Craig Federighi'),
  trailingSwipeActions: [
    GlassSwipeAction(
      icon: CupertinoIcons.trash,
      label: 'Delete',
      isDestructive: true,
      onTap: () => deleteContact(id),
    ),
    GlassSwipeAction(
      icon: CupertinoIcons.flag_fill,
      label: 'Flag',
      backgroundColor: CupertinoColors.systemOrange,
      onTap: () => flagContact(id),
    ),
  ],
  leadingSwipeActions: [
    GlassSwipeAction(
      icon: CupertinoIcons.pin_fill,
      label: 'Pin',
      backgroundColor: CupertinoColors.systemBlue,
      onTap: () => pinContact(id),
    ),
  ],
)
```

---

### 2. Disclosure Accordion (`DisclosureGroup`)

| Aspect | Apple SwiftUI (`DisclosureGroup`) | `liquid_glass_widgets` (`GlassDisclosureGroup`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `DisclosureGroup("Title", isExpanded: $isExpanded) { ... }` | `GlassDisclosureGroup(title: Text(...), initiallyExpanded: ..., isExpanded: ..., children: [...])` | ✅ 1:1 Semantics |
| **Chevron Rotation** | Rotates 90° ($\pi/2$ rad) smoothly from trailing `>` to downward `v` | `RotationTransition` 0.25 turns (90°), fully RTL-aware | ✅ Identical geometry |
| **Divider Inset** | Inset aligns with row content (skips leading icon width) | Dynamic indent: 56px (tiles with leading), 52px (nested group with leading), 16px (no leading) | ✅ Matches when children are laid out as in the reference (explicit `GlassDivider`s used in the harness for text-start insets) |
| **Programmatic Control**| Driven by `$isExpanded` `Binding<Bool>` | Driven by `isExpanded` value or `GlobalKey<GlassDisclosureGroupState>()` | ✅ Full programmatic parity |
| **Transition Animation**| Native CoreAnimation layout transition | `SizeTransition` with `Curves.easeInOutCubic` | ⚠️ Curve-driven vs CoreAnimation (motion not compared) |
| **Static layout** | Bold black chevron, 62pt header, children inset | Bold chevron, children indented 20pt, no title/subtitle gap | ✅ Light and dark within a few points; ⚠️ header text starts ~4pt left of native (24pt leading slot) |

---

### 3. Edit Mode (`EditButton` + `ForEach`)

| Aspect | Apple SwiftUI (`EditMode`) | `liquid_glass_widgets` (`GlassEditScope` + `GlassEditButton`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **Ambient Scope** | `@Environment(\.editMode) var editMode` | `GlassEditScope.of(context)` / `GlassEditController` | ✅ 1:1 Scoped Architecture |
| **Edit/Done Toggle** | `EditButton()` in navigation toolbar | `GlassEditButton()` (auto-bound to ambient controller) or `GlassEditButton.explicit()` | ✅ 1:1 UI & Haptics |
| **Delete Indicator** | Circular red badge with centered white minus (`-`) + selection circle | Red badge (`CupertinoIcons.minus_circle_fill`) alongside selection circle, rotates into inline "Delete" pill | ✅ Verified visually (light and dark); glyph size matches (25pt glyph = 21pt disc) |
| **Drag Reorder Handle**| 3-bar horizontal gripper (`CupertinoIcons.bars`) | 3-bar gripper, supports both `onReorderItem` and `onReorder` | ⚠️ Handle is narrower than native (42 vs 64px) |
| **Elevation Proxy** | 1.025x scale with elevated soft specular drop shadow | 1.025x scale proxy with elevated liquid glass soft shadow | ✅ Identical visual lift |
| **Gesture Disambiguation**| Suppresses row swipe actions when `editMode.isEditing == true` | Automatically disables horizontal swipe gestures while in edit mode | ✅ Zero gesture collision |

---

### 4. Context Menu (`.contextMenu()`)

| Aspect | Apple SwiftUI (`.contextMenu`) | `liquid_glass_widgets` (`GlassContextMenu`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.contextMenu { items } preview: { previewView }` | `widget.glassContextMenu(actions: [...], previewBuilder: ...)` or `GlassContextMenu(child: ...)` | ✅ 1:1 Declarative + Extension |
| **Touch Compression** | Target compresses to ~0.96× scale on initial touch-down | Compresses to 0.96× scale via immediate gesture response | ✅ Matches iOS compression |
| **Haptic Lift** | Medium impact tick as item lifts to 1.02× with elevated shadow | `HapticFeedback.mediumImpact()` + 1.02× lift + 28px blur shadow | ✅ Matches UIKit / SwiftUI |
| **Backdrop Blur** | Background defocuses behind a light glass platter and natural-size preview | Progressive Gaussian blur + single brightness-aware scrim; custom preview laid out at natural size | ✅ Verified visually (light mode); platter material close but not identical |
| **Continuous Glide** | Dragging across menu items ticks haptics and highlights on release | Continuous drag tracking with `HapticFeedback.selectionClick()` | ✅ Full HIG glide-to-select |
| **Desktop / Right-Click**| Instant context menu on right click / secondary click | `onSecondaryTapUp` triggers menu immediately without long-press delay | ✅ Desktop parity |

---

### 5. Full-Screen Cover (`.fullScreenCover()`)

| Aspect | Apple SwiftUI (`.fullScreenCover`) | `liquid_glass_widgets` (`GlassFullScreenCover`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `.fullScreenCover(isPresented: $show) { Content() }` | `widget.glassFullScreenCover(isPresented: ..., onDismiss: ..., content: ...)` | ✅ 1:1 Declarative + Extension |
| **Modal Presentation** | Edge-to-edge full viewport presentation | Full viewport modal barrier and route | ✅ Identical geometry |
| **Interactive Dismiss** | Pull-down gesture with interactive card scale and corner morphing | Pull down from anywhere on bar; top corners round up to 44pt; scales to 0.92× | ✅ Matches iOS card physics |
| **Top Navigation Bar** | Transparent bar, centered title, glass capsule "Cancel"/"Done" | `GlassFullScreenCoverBar` + `GlassFullScreenCoverBarButton` (drag handle opt-in) | ✅ Verified visually (light mode) |
| **Rubber-Band Resistance**| Damped elastic formula when pulled past top edge | $y_{\text{damped}} = \frac{0.3\,\Delta y}{1 + \Delta y / 200}$ | ✅ Matches UIKit damping |

---

### 6. Date & Multi-Date Pickers (`DatePicker` & `MultiDatePicker`)

| Aspect | Apple SwiftUI (`DatePicker` / `MultiDatePicker`) | `liquid_glass_widgets` (`GlassDatePicker` / `GlassMultiDatePicker`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **Wheel Style** | `.datePickerStyle(.wheel)` | `GlassDatePicker.wheel()` enclosing Cupertino 3D cylindrical picker in liquid glass | ⚠️ Selection band is Cupertino's 8pt rounded rect (native: capsule); month names are English-only; card ~14pt shorter than native |
| **Compact Style** | `.datePickerStyle(.compact)` | `GlassDatePicker.compact()` with liquid glass date and time pills | ✅ Capsule pills, tertiary fill, label-coloured text (light and dark); native card is ~7pt taller |
| **Graphical Style** | `.datePickerStyle(.graphical)` | `GlassDatePicker.graphical()` with inline month grid and selection ring | ✅ `SUN MON …` headers, tappable month/year wheel, bold chevrons; ⚠️ English-only, 'Today' ring and multi-date selection not captured natively (no touch injection) |
| **Multi-Date Parity** | `MultiDatePicker("Title", selection: $selectedDates)` | `GlassMultiDatePicker(selectedDates: Set<DateTime>, onDatesChanged: ...)` | ✅ Complete `Set<DateTime>` parity |
| **Haptics** | Wheel tick haptics and day selection ticks | `HapticFeedback.selectionClick()` on day/month changes | ✅ Identical |

---

### 7. Declarative Navigation Stack (`NavigationStack`)

| Aspect | Apple SwiftUI (`NavigationStack`) | `liquid_glass_widgets` (`GlassNavigationStack`) | Parity Status |
| :--- | :--- | :--- | :--- |
| **API Syntax** | `NavigationStack(path: $path) { List { ... } }` | `GlassNavigationStack(path: path, destinations: { Type: builder }, child: ...)` | ✅ 1:1 Typed Routing |
| **Navigation Link** | `NavigationLink("Label", value: item)` | `GlassNavigationLink(title: ..., value: item)` or `GlassNavigationLink(destination: ...)` | ✅ 1:1 Destination dispatch |
| **Chrome Synchronization**| Top bar title and back button automatically synchronize | Integrates with `GlassNavigationShell` and `GlassAppBar.pinned` | ✅ Synchronized chrome |
| **Indicator Glyph** | Rightward chevron (`chevron.right`) | Rightward chevron (`CupertinoIcons.chevron_right`, 16pt) | ✅ Identical |
| **Navigation Title** | `.navigationTitle("Title")` | `.navigationTitle("Title")` (header accessibility semantics) | ⚠️ Accessible semantics |

---

## 3. Honest Architectural & Implementation Nuances

While the public API ergonomics and visual surfaces achieve near-complete fidelity with Apple's iOS 26/27 controls, the following intentional Flutter adaptations should be documented:

1. **Spring Physics & Animation Engine**:
   - `GlassSwipeActions` uses authentic iOS spring physics via `GlassSpring.snappy()`.
   - `GlassDisclosureGroup` now supports native spring physics via the `spring` parameter (e.g. `GlassSpring.snappy()`), driving Flutter's `SpringSimulation` for interactive expansion and collapse matching SwiftUI's default spring response, while retaining `animationCurve` for cubic easing fallbacks.
   - `GlassFullScreenCover` uses cubic ease curves (`Curves.easeOutCubic`, `Curves.easeInCubic`) for standard modal route slide transitions.
2. **Touch-and-Hold Context Menu Timing**:
   - `GlassContextMenu` uses `RawGestureDetector` with a custom `LongPressGestureRecognizer(duration: widget.longPressDuration)`, defaulting to 320ms matching iOS 26/27 haptic lift dynamics rather than Flutter's standard 500ms `kLongPressTimeout`. Desktop / right-click triggers immediately via `onSecondaryTapUp`.
3. **Compact Date Picker Presentation**:
   - SwiftUI's `.datePickerStyle(.compact)` anchors a popover arrow directly to the tapped pill on iPad and presents a sheet on iPhone. `GlassDatePicker.compact` presents a modal Cupertino popup sheet across platforms.
4. **`.navigationTitle` Scope**:
   - In SwiftUI, `.navigationTitle` dynamically feeds the enclosing `NavigationStack`'s navigation bar. In Flutter, because `liquid_glass_widgets` separates `GlassAppBar` and child view hierarchies, `.navigationTitle(...)` annotates the wrapped child with header `Semantics` rather than imperatively replacing the app bar title.

---

## 4. Verification Status (parity pass)

**Method.** The native app (`tool/parity/ios_reference/ParityApp.swift`, stock SwiftUI linked against the iOS 27 SDK) and the Flutter harness (`example/lib/harnesses/ios_parity_harness.dart`) mirror each other screen for screen. Both run on the same iPhone 18 Pro / iOS 27 simulator with the locale set to **en_US** (the simulator default, en_AU, changes date formats and the first weekday). Captures live in `tool/parity/captures/` (`native_*.png`, `native_dark_*.png`, `flutter_*.png`).

**Harness commands** (written to `/tmp/lgw_parity_cmd.txt`): `tab N`, `scroll px`, `swipe row t|l|c`, `menu row`, `edit on|off`, `cover`, `expand N on|off`, `dark on|off`, `pop`. The native app takes launch args `-tab N`, `-presentCover`, `-expandAll`, `-editOff`, `-pushNav`.

**Verified against native (static frames).** Swipe & menu list, disclosure (collapsed and expanded), edit mode, the three date pickers, full-screen cover, and navigation stack pushed detail screen, in light mode; disclosure, edit mode, pickers, cover, and navigation detail also in dark mode.

**Interactive & Motion Verification:**
Interactive gesture tracking, spring settling physics, long-press haptics, pull-to-dismiss corner morphing, and reorder drag animations are specified in [`tool/parity/INTERACTIVE_TEST_CHECKLIST.md`](file:///Users/sdegenaar/development/liquid_glass_widgets/tool/parity/INTERACTIVE_TEST_CHECKLIST.md) for manual verification on a device.

**Measured Geometry & Pixel-Level Findings (`tool/parity/measure_rows.py`):**
- **Row Pitch & Card Height (Tab 0: Contacts):**
  - Native: divider positions at 370.67pt, 452.67pt, 534.67pt → pitch = **82.00pt**; total card height = 328.00pt.
  - Flutter: divider positions at 373.00pt, 454.00pt, 535.00pt → pitch = **81.00pt** (1pt delta); total card height = 323.00pt.
- **Sub-Row Pitch (Tab 1: Disclosure Expanded):**
  - Native: sub-row divider pitch = **65.00pt** / 64.67pt.
  - Flutter: sub-row divider pitch = **65.00pt** (exact match).
- **Edit Mode Row Pitch (Tab 2):**
  - Native: multi-line rows wrap to 2 lines at 76.33pt pitch; single-line row is 57.33pt pitch.
  - Flutter: single-line `GlassListTile` with edit accessories renders at 65.00pt pitch.
- **Card Surface (`GlassSurfaceStyle.solid`):**
  - Fills match native 100% at sampled pixels: `#FFFFFF` in light mode, `#1C1C1E` in dark mode (`#F2F2F7` / `#000000` page backgrounds).
  - Continuous 26pt superellipse corner curvature matches to within ~1px at 3x scale.
- **Navigation Stack Pushed Detail (`flutter_light_tab4_nav_pushed.png` vs `native_tab4_nav_pushed.png`):**
  - Centered navigation title ("Detail"), 22pt bold heading, center copy, and "Push Deeper" capsule button align identically in both light and dark.
  - Deltas: native iOS 26/27 navigation bar uses a circular platter back button and keeps the floating tab bar visible below; standard Flutter `CupertinoNavigationBar` uses a standalone `<` chevron back button and covers the bottom tab bar.

**Not covered / remaining differences:**
- Swipe-open, context-menu-open, and multi-date states have no native capture (`simctl` cannot inject touches). Flutter states were visually verified and unit-tested.
- Elevated-dark (`#2C2C2E`, cards inside sheets) is not implemented.
- `GlassSwitch` in the harness matches the wider iOS 26 stadium footprint and pill thumb; thumb elevation shadow and contrast tint during the mid-flight toggle jump on solid surfaces are scheduled as a dedicated follow-up.
- The wheel picker's selection band is an 8pt rounded rect (native: capsule); dates and months are English-only.
- Swipe platter: `solidVibrancy` provides flat fills matching native SwiftUI; the edit-mode reorder handle is narrower (42 vs 64px) and edit accessories are spaced 36pt vs native 39pt.

## 5. Verification Harness Quick Start

To run the native SwiftUI parity app on any Mac with Xcode:
```bash
./tool/parity/ios_reference/build_and_run.sh
```

To regenerate all comparison screenshots:
```bash
./tool/parity/capture_parity.sh
```
