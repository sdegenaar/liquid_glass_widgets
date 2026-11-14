import 'dart:ui' show SemanticsRole;

import 'package:cupertino_ui/cupertino_ui.dart';

import '../../constants/glass_defaults.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import '../../src/widgets/overlays/glass_alert_platter.dart';

import '../../theme/glass_theme_data.dart';
import '../../theme/glass_theme.dart';
import '../../theme/glass_theme_helpers.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_style.dart';
import '../shared/adaptive_glass.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/glass_focus_region.dart';
import '../shared/glass_interaction_state_mixin.dart';

/// Style of action sheet action.
enum GlassActionSheetStyle {
  /// Default action style (white text)
  defaultStyle,

  /// Destructive action style (red text, indicates deletion/removal)
  destructive,

  /// Cancel action style (bold text, typically for dismissal)
  cancel,
}

/// An action that can be taken from a [showGlassActionSheet] call.
class GlassActionSheetAction {
  /// Creates an action sheet action.
  const GlassActionSheetAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = GlassActionSheetStyle.defaultStyle,
  });

  /// The label text for the action
  final String label;

  /// Callback when the action is pressed
  final VoidCallback onPressed;

  /// Optional icon widget to display before the label
  final Widget? icon;

  /// Visual style of the action
  final GlassActionSheetStyle style;
}

/// A glass morphism action sheet following iOS 26 liquid glass design.
///
/// This action sheet provides an iOS-style bottom action sheet with:
/// - iOS 26 liquid glass backdrop effect
/// - Bottom-anchored action list
/// - Destructive action styling (red text/icon)
/// - Cancel button always at bottom with separator
/// - Tap outside to dismiss
/// - Slide-up animation
/// - Optional title and message
///
/// ## Usage
///
/// ### Basic Action Sheet
/// ```dart
/// showGlassActionSheet(
///   context: context,
///   title: 'Delete Photo?',
///   message: 'This action cannot be undone',
///   actions: [
///     GlassActionSheetAction(
///       label: 'Delete',
///       style: GlassActionSheetStyle.destructive,
///       onPressed: () {
///         // Delete logic
///         Navigator.pop(context);
///       },
///     ),
///   ],
/// );
/// ```
///
/// ### Multiple Actions
/// ```dart
/// showGlassActionSheet(
///   context: context,
///   title: 'Choose Action',
///   actions: [
///     GlassActionSheetAction(
///       label: 'Save to Photos',
///       icon: Icon(CupertinoIcons.photo),
///       onPressed: () => save(),
///     ),
///     GlassActionSheetAction(
///       label: 'Share',
///       icon: Icon(CupertinoIcons.share),
///       onPressed: () => share(),
///     ),
///     GlassActionSheetAction(
///       label: 'Delete',
///       icon: Icon(CupertinoIcons.delete),
///       style: GlassActionSheetStyle.destructive,
///       onPressed: () => delete(),
///     ),
///   ],
/// );
/// ```
///
/// ### Custom Cancel Label
/// ```dart
/// showGlassActionSheet(
///   context: context,
///   title: 'Select Option',
///   actions: [...],
///   cancelLabel: 'Dismiss', // Custom cancel button text
/// );
/// ```
///
/// ### No Cancel Button
/// ```dart
/// showGlassActionSheet(
///   context: context,
///   title: 'Select Option',
///   actions: [...],
///   showCancelButton: false,
/// );
/// ```
///
/// ## iOS 26 / iOS 27 vs classic presentation
///
/// - **`GlassStyle.ios26` / `GlassStyle.ios27`** (default): matches the native
///   `UIAlertController` action sheet on iOS 26/27 — the same 320 pt platter as
///   [GlassDialog], centred on screen, with a leading-aligned header, stacked
///   filled capsule actions and Cancel inside the same platter.
/// - **`GlassStyle.classic`**: the original bottom-anchored sheet with a
///   separate Cancel card.
///
/// ## Design principles (classic)
///
/// - **Bottom-anchored**: Always slides up from bottom
/// - **Grouped layout**: Actions in one card, cancel button separated
/// - **Destructive styling**: Red text for dangerous actions
/// - **Glass backdrop**: Liquid glass effect on action cards
/// - **Modal dismissal**: Tap outside or cancel to dismiss
/// - **Safe area aware**: Respects bottom safe area
///
/// ## Differences from GlassSheet
///
/// - **GlassActionSheet**: Predefined action list (like iOS UIAlertController)
/// - **GlassSheet**: Custom content (like iOS UISheetPresentationController)
///
/// Use [showGlassActionSheet] when you need a simple action picker.
/// Use [GlassSheet] when you need custom content or forms.
Future<T?> showGlassActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<GlassActionSheetAction> actions,
  String cancelLabel = 'Cancel',
  bool showCancelButton = true,
  bool barrierDismissible = true,
  LiquidGlassSettings? settings,
  GlassQuality? quality,
}) {
  final capturedGlassTheme = GlassTheme.maybeOf(context)?.data;
  final capturedCupertinoTheme = CupertinoTheme.of(context);
  final style = GlassThemeHelpers.resolveStyle(context);
  final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;

  Widget withAmbientThemes(Widget sheet) {
    sheet = CupertinoTheme(data: capturedCupertinoTheme, child: sheet);
    if (capturedGlassTheme != null) {
      sheet = GlassTheme(data: capturedGlassTheme, child: sheet);
    }
    return sheet;
  }

  if (style != GlassStyle.classic) {
    // ios26 / ios27: the native action sheet is the alert platter with
    // stacked actions (Cancel included), centred on screen.
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: glassAlertBarrierColor(isDark: isDark),
      builder: (modalContext) {
        void dismiss() => Navigator.of(modalContext).pop();
        return withAmbientThemes(
          GlassAlertPlatter(
            title: title,
            message: message,
            settings: settings,
            quality: quality,
            forceStacked: true,
            semanticsRole: SemanticsRole.dialog,
            actions: [
              for (final action in actions)
                GlassAlertPlatterAction(
                  label: action.label,
                  icon: action.icon,
                  isDestructive:
                      action.style == GlassActionSheetStyle.destructive,
                  onPressed: () {
                    action.onPressed();
                    if (action.style != GlassActionSheetStyle.cancel) {
                      dismiss();
                    }
                  },
                ),
              if (showCancelButton)
                GlassAlertPlatterAction(label: cancelLabel, onPressed: dismiss),
            ],
          ),
        );
      },
    );
  }

  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: GlassDefaults.barrierColor,
    builder: (modalContext) => withAmbientThemes(
      _GlassActionSheetContent(
        title: title,
        message: message,
        actions: actions,
        cancelLabel: cancelLabel,
        showCancelButton: showCancelButton,
        settings: settings,
        quality: quality,
      ),
    ),
  );
}

const _kDefaultActionSheetSettings = LiquidGlassSettings(
  thickness: 30.0,
  blur: 5.0,
  refractiveIndex: 1.15,
  saturation: 1.2,
);

/// Internal widget for action sheet content.
class _GlassActionSheetContent extends StatelessWidget {
  const _GlassActionSheetContent({
    required this.actions,
    required this.cancelLabel,
    required this.showCancelButton,
    this.title,
    this.message,
    this.settings,
    this.quality,
  });

  final String? title;
  final String? message;
  final List<GlassActionSheetAction> actions;
  final String cancelLabel;
  final bool showCancelButton;
  final LiquidGlassSettings? settings;
  final GlassQuality? quality;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main actions card
              _buildActionsCard(context),

              // Spacing between actions and cancel
              if (showCancelButton) const SizedBox(height: 8),

              // Cancel button (separated)
              if (showCancelButton) _buildCancelButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    final themeData = GlassThemeData.of(context);
    final glowColors = themeData.glowColorsFor(context);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final cardColor = themeData.style == GlassStyle.classic
        ? (isDark
              ? CupertinoColors.black.withValues(alpha: 0.65)
              : CupertinoColors.white.withValues(alpha: 0.65))
        : null;
    final dividerColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.2)
        : CupertinoColors.black.withValues(alpha: 0.1);
    final effectiveSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: settings,
      fallback: _kDefaultActionSheetSettings,
      isOverlayPlatter: true,
    );
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );

    return AdaptiveLiquidGlassLayer(
      settings: effectiveSettings,
      quality: effectiveQuality,
      child: AdaptiveGlass(
        shape: const LiquidRoundedSuperellipse(borderRadius: 14),
        settings: effectiveSettings,
        quality: effectiveQuality,
        useOwnLayer: false,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and message
                if (title != null || message != null) _buildHeader(context),

                // Actions list
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0 || (title != null || message != null))
                    // Replaces Material Divider — identical pixel output.
                    SizedBox(
                      height: 1,
                      child: Center(
                        child: Container(height: 0.5, color: dividerColor),
                      ),
                    ),
                  _ActionSheetButton(
                    action: actions[i],
                    glowColors: glowColors,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          if (title != null && message != null) const SizedBox(height: 4),
          if (message != null)
            Text(
              message!,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    final themeData = GlassThemeData.of(context);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final cardColor = themeData.style == GlassStyle.classic
        ? (isDark
              ? CupertinoColors.black.withValues(alpha: 0.65)
              : CupertinoColors.white.withValues(alpha: 0.65))
        : null;
    final effectiveSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: settings,
      fallback: _kDefaultActionSheetSettings,
      isOverlayPlatter: true,
    );
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );

    return AdaptiveLiquidGlassLayer(
      settings: effectiveSettings,
      quality: effectiveQuality,
      child: AdaptiveGlass(
        shape: const LiquidRoundedSuperellipse(borderRadius: 14),
        settings: effectiveSettings,
        quality: effectiveQuality,
        useOwnLayer: false,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _ActionSheetButton(
              action: GlassActionSheetAction(
                label: cancelLabel,
                style: GlassActionSheetStyle.cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
              glowColors: null,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single action button within the action sheet — manages its own pressed
/// state to provide iOS-style opacity highlight on tap-down.
class _ActionSheetButton extends StatefulWidget {
  const _ActionSheetButton({required this.action, required this.glowColors});

  final GlassActionSheetAction action;
  final GlassGlowColors? glowColors;

  @override
  State<_ActionSheetButton> createState() => _ActionSheetButtonState();
}

class _ActionSheetButtonState extends State<_ActionSheetButton>
    with GlassInteractionStateMixin {
  // Interaction state (isPressed, isFocused, pressedAndFocused)
  // is provided by GlassInteractionStateMixin.

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final Color textColor = _getTextColor(action.style);
    final FontWeight fontWeight = action.style == GlassActionSheetStyle.cancel
        ? FontWeight.w600
        : FontWeight.w400;

    void handleTap() {
      action.onPressed();
      if (action.style != GlassActionSheetStyle.cancel) {
        Navigator.of(context).pop();
      }
    }

    return GlassFocusRegion(
      enabled: true,
      // No shape → background highlight pattern for sheet rows, not outset ring.
      isFocusedNotifier: isFocused,
      isButton: true,
      semanticLabel: action.label,
      onKeyboardActivate: handleTap,
      semanticOnTap: handleTap,
      child: GestureDetector(
        onTap: handleTap,
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        behavior: HitTestBehavior.opaque,
        // Semantics (label, role, tap) live on the GlassFocusRegion node.
        excludeFromSemantics: true,
        child: ListenableBuilder(
          listenable: pressedAndFocused,
          builder: (context, child) {
            final bool showHighlight = isPressed.value || isFocused.value;
            return AnimatedContainer(
              duration: isPressed.value
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              color: showHighlight
                  ? CupertinoColors.label
                        .resolveFrom(context)
                        .withValues(alpha: 0.06)
                  : const Color(0x00000000),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (action.icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: textColor, size: 20),
                  child: action.icon!,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                action.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: fontWeight,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTextColor(GlassActionSheetStyle style) {
    switch (style) {
      case GlassActionSheetStyle.defaultStyle:
      case GlassActionSheetStyle.cancel:
        return CupertinoColors.label.resolveFrom(context);
      case GlassActionSheetStyle.destructive:
        return widget.glowColors?.danger ?? CupertinoColors.destructiveRed;
    }
  }
}
