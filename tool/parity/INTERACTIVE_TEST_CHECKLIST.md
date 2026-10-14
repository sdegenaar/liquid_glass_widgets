# iOS 26 / 27 Liquid Glass — Interactive Parity Test Protocol

This checklist guides manual interactive and motion testing on a physical iOS device or simulator. Static frames verify colour and layout; this protocol verifies **physics, spring curves, touch tracking, gestures, and haptic feedback** against native iOS 26 / 27.

---

## Testing Setup

```bash
# 1. Boot simulator or plug in iOS device (iOS 26+ / 27+)
# 2. Run the Flutter Parity Harness:
cd example
flutter run -t lib/harnesses/ios_parity_harness.dart -d <device-id>

# 3. (Optional) Run the native SwiftUI Reference App side-by-side:
cd tool/parity/ios_reference
./build_and_run.sh
```

---

## Feature 1: Swipe Actions (`GlassSwipeActions`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **SW-01** | **Slow Drag (Trailing)** | Drag left slowly. Orange (Flag) and Red (Delete) buttons emerge with proportional width. Action buttons stay pinned within the card corner radius (no spillover). | [ ] | |
| **SW-02** | **Flick / Snap Open** | Quick flick left. Buttons snap open cleanly with an authentic iOS spring (`GlassSpring.snappy()`), settling without oscillation. | [ ] | |
| **SW-03** | **Full Swipe Execution** | Drag past 65% of the card width. Delete button stretches across the entire row; releasing triggers the delete action and dismisses the row. | [ ] | |
| **SW-04** | **Leading Swipe (Pin)** | Drag right slowly. Blue Pin button reveals. Rubber-band resistance dampens drag beyond full platter reveal if full-swipe is disabled. | [ ] | |
| **SW-05** | **Mutual Exclusion** | With row 1 open, tap or swipe row 2. Row 1 automatically springs closed while row 2 responds to the touch. | [ ] | |
| **SW-06** | **Corner Clipping** | Swipe the first or last row in a solid `GlassGroupedSection`. The outer swipe button edge must clip smoothly to the card's 26pt continuous superellipse corner. | [ ] | |

---

## Feature 2: Context Menus (`GlassContextMenu`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **CM-01** | **Touch Compression** | Touch down on a contact row. The row immediately compresses to ~0.96× scale with subtle feedback. | [ ] | |
| **CM-02** | **Haptic Lift & Blur** | Hold touch for ~320ms. Device fires a medium impact haptic; background smoothly blurs with dark/light scrim; target lifts to 1.02× with superellipse shadow. | [ ] | |
| **CM-03** | **VIP Preview Card** | Rich preview card renders above the platter at its natural aspect ratio with continuous superellipse corners. | [ ] | |
| **CM-04** | **Glide-to-Select** | Without lifting finger after menu presentation, slide finger across menu actions. Each action highlights with a distinct selection haptic click. Releasing fires the selected action. | [ ] | |
| **CM-05** | **Tap Scrim Dismissal** | Tap outside the menu platter. Menu scales and fades smoothly back into the source row without flicker. | [ ] | |
| **CM-06** | **Desktop / Mac Right-Click**| Secondary-click / right-click immediately presents context menu without long-press delay. | [ ] | |

---

## Feature 3: Edit Mode & Reorderable List (`GlassEditScope` + `GlassReorderableList`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **EM-01** | **EditButton Toggle** | Tap the "Edit" glass button in top-right. Smoothly cross-fades into bold "Done" with a selection haptic tick. Rows slide right to reveal delete badges. | [ ] | |
| **EM-02** | **Delete Badge Rotation** | Tap the circular red minus badge on a row. Badge rotates 90° as an inline red "Delete" pill slides in from the right edge with spring physics. | [ ] | |
| **EM-03** | **Swipe Action Suppression**| While in Edit Mode, swiping left or right on rows must NOT trigger swipe actions (gestures are suppressed). | [ ] | |
| **EM-04** | **Drag-Reorder Lift** | Long press the 3-bar handle (`≡`) on a row. Row lifts with soft specular elevation shadow. On a solid card, the lifted row preserves the opaque card fill (#FFFFFF or #1C1C1E). | [ ] | |
| **EM-05** | **Drop & Gap Animation** | Drag row up/down. Other rows animate open smoothly to create insertion gaps. Releasing snaps the row into place with haptic tick. | [ ] | |
| **EM-06** | **Multi-Selection** | Tap the selection circle on rows. Checkmark toggles smoothly with selection state. | [ ] | |

---

## Feature 4: Disclosure Accordion Sections (`GlassDisclosureGroup`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **DC-01** | **Chevron Rotation** | Tap disclosure header row. Trailing chevron smoothly rotates 90° (downward) synchronously with the accordion expansion. | [ ] | |
| **DC-02** | **Expansion Physics** | Child sub-rows slide and fade in smoothly using authentic iOS cubic curve (`Curves.fastOutSlowIn`). No jumping or frame stutter. | [ ] | |
| **DC-03** | **Card Boundary Expansion** | The solid card's bottom edge expands smoothly to enclose the newly revealed children, maintaining continuous 26pt corners throughout motion. | [ ] | |
| **DC-04** | **Nested Disclosure** | In "Emergency & Medical", expand child groups. Sub-dividers animate in at correct 35pt / 70pt insets. | [ ] | |

---

## Feature 5: Full-Screen Covers (`GlassFullScreenCover`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **FS-01** | **Slide-Up Presentation** | Tap "Present Full-Screen Cover". Cover slides up from the screen bottom (`Offset(0, 1) -> 0`) using `Curves.easeOutCubic`. | [ ] | |
| **FS-02** | **Interactive Pull-Down** | Drag down on top bar. Cover tracks finger 1:1; top corners morph from 0 to 44pt superellipse; background card scales down to ~0.92×. | [ ] | |
| **FS-03** | **Overscroll Damping** | Drag upward beyond top edge. Rubber-band resistance engages ($y_{\text{damped}} = \frac{0.3 \Delta y}{1 + \Delta y / 200}$). | [ ] | |
| **FS-04** | **Flick / Velocity Dismiss** | Fast flick down dismisses the cover immediately. Slow drag released before threshold springs back to full screen. | [ ] | |
| **FS-05** | **Done / Cancel Buttons** | Glass capsule "Done" or "Cancel" button triggers clean dismissal. | [ ] | |

---

## Feature 6: Date & Multi-Date Pickers (`GlassDatePicker` + `GlassMultiDatePicker`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **DP-01** | **Wheel Picker Inertia** | Fling date/time wheels. Cylindrical 3D wheels decelerate with authentic Cupertino physics; haptic click fires on each passing item. | [ ] | |
| **DP-02** | **Compact Popover** | Tap date or time capsule pill. Sheet or popover opens presenting graphical calendar without glitching background layout. | [ ] | |
| **DP-03** | **Month Navigation** | Tap left / right chevrons on graphical calendar. Days transition smoothly with horizontal slide. | [ ] | |
| **DP-04** | **Month-Year Wheel** | Tap the "October 2026 ›" header. Compact month/year wheel reveals inline; selecting month/year updates calendar immediately. | [ ] | |
| **DP-05** | **Multi-Date Selection** | Tap multiple days on `GlassMultiDatePicker`. Each selected date receives an accent circle; tapping again unselects. | [ ] | |
| **DP-06** | **Solid Surface Card** | When `surfaceStyle: GlassSurfaceStyle.solid` is set, card fill is opaque white / #1C1C1E with no specular rim highlight. | [ ] | |

---

## Feature 7: Declarative Navigation Stack (`GlassNavigationStack` + `GlassNavigationLink`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **NV-01** | **Link Tap Push** | Tap "Optics Architecture". Pushes detail route with native horizontal slide transition (`Curves.easeInOutCubic`). | [ ] | |
| **NV-02** | **Interactive Back Swipe** | Swipe from the left screen edge. Detail screen drags smoothly with finger reveal of parent page; releasing past halfway pops route. | [ ] | |
| **NV-03** | **Back Button** | Tap back button on top navigation bar. Pops smoothly to parent page. | [ ] | |
| **NV-04** | **Title Synchronization** | Title in navigation bar transitions cleanly between parent and pushed route. | [ ] | |

---

## Deprecation & Surface Styles (`GlassSurfaceStyle.solid` & `GlassContainer.card`)

| Test ID | Interaction | Expected Native iOS Behavior | Pass / Fail | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **SS-01** | **Light Mode Fill** | In light mode, solid card background is pure flat `#FFFFFF` (exact match with native iOS Settings cards). | [ ] | |
| **SS-02** | **Dark Mode Fill** | In dark mode, solid card background is pure flat `#1C1C1E` (exact match with native iOS secondary grouped background). | [ ] | |
| **SS-03** | **Corner Radius (26pt)** | Continuous superellipse corner curvature matches native iOS inset-grouped tables to within 1px. | [ ] | |
| **SS-04** | **Row Pressed State** | Tap and hold any row in a solid card. The press overlay (8% opacity) stays strictly within the rounded card boundary. | [ ] | |
| **SS-05** | **Theme Override** | Wrap card in `GlassTheme(brightness: Brightness.dark)`. Card fill switches to `#1C1C1E` regardless of system/app theme. | [ ] | |

---

## Platform & Accessibility Matrix

- [ ] **Dynamic Type**: Set device text size to XXL in iOS Settings. Verify labels expand without clipping or card distortion.
- [ ] **Reduce Motion**: Turn on "Reduce Motion" in iOS Accessibility. Verify transitions become instant fades.
- [ ] **Dark Mode Toggle**: Toggle system Dark Mode while interacting. Verify all solid card fills update instantly.
- [ ] **Physical Device Test**: Confirm shaders and blur run smoothly at 60 / 120 FPS on Impeller (Metal).
