import 'package:flutter/cupertino.dart';

import '../../src/renderer/liquid_glass_renderer.dart';

import '../../types/glass_button_style.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_style.dart';
import '../../src/widgets/overlays/glass_alert_platter.dart';
import '../../src/widgets/overlays/modal_theme_capture.dart';
import '../containers/glass_container.dart';
import '../interactive/glass_button.dart';
import '../../theme/glass_theme.dart';
import '../../theme/glass_theme_helpers.dart';

/// A glass morphism alert dialog following Apple's iOS design patterns.
///
/// [GlassDialog] provides a modal dialog with liquid glass effect,
/// composing [GlassContainer.card] and [GlassButton] as building blocks.
///
/// ## Key Features
///
/// - Liquid glass backdrop with blur effect
/// - Composable design using GlassContainer.card + GlassButton
/// - iOS-style alert layout
/// - 1-3 action buttons with smart layout
/// - Customizable glass settings
/// - Optional custom content
///
/// ## Usage
///
/// ### Basic Alert
/// ```dart
/// GlassDialog.show(
///   context: context,
///   title: 'Delete Item?',
///   message: 'This action cannot be undone.',
///   actions: [
///     GlassDialogAction(
///       label: 'Cancel',
///       onPressed: () => Navigator.pop(context),
///     ),
///     GlassDialogAction(
///       label: 'Delete',
///       isDestructive: true,
///       onPressed: () {
///         // Delete logic
///         Navigator.pop(context);
///       },
///     ),
///   ],
/// );
/// ```
///
/// ### Primary & Secondary Actions
/// ```dart
/// GlassDialog.show(
///   context: context,
///   title: 'Subscribe to Pro?',
///   message: 'Unlock offline syncing across all of your devices.',
///   actions: [
///     GlassDialogAction(
///       label: 'Not Now',
///       onPressed: () => Navigator.pop(context, false),
///     ),
///     GlassDialogAction(
///       label: 'Continue',
///       isPrimary: true, // Filled with CupertinoTheme.primaryColor + contrast text
///       onPressed: () => Navigator.pop(context, true),
///     ),
///   ],
/// );
/// ```
///
/// ### Custom Accent Color
/// ```dart
/// GlassDialog.show(
///   context: context,
///   title: 'Upgrade Plan?',
///   message: 'Use a custom brand accent on the recommended action.',
///   actions: [
///     GlassDialogAction(
///       label: 'Cancel',
///       onPressed: () => Navigator.pop(context),
///     ),
///     GlassDialogAction(
///       label: 'Upgrade',
///       isPrimary: true,
///       tintColor: CupertinoColors.systemPurple,
///       onPressed: () => Navigator.pop(context, true),
///     ),
///   ],
/// );
/// ```
///
/// ### Single Action
/// ```dart
/// GlassDialog.show(
///   context: context,
///   title: 'Success',
///   message: 'Your changes have been saved.',
///   actions: [
///     GlassDialogAction(
///       label: 'OK',
///       onPressed: () => Navigator.pop(context),
///     ),
///   ],
/// );
/// ```
///
/// ### Three Actions
/// ```dart
/// GlassDialog.show(
///   context: context,
///   title: 'Save Changes?',
///   message: 'You have unsaved changes.',
///   actions: [
///     GlassDialogAction(
///       label: 'Don\'t Save',
///       onPressed: () => Navigator.pop(context, false),
///     ),
///     GlassDialogAction(
///       label: 'Cancel',
///       onPressed: () => Navigator.pop(context),
///     ),
///     GlassDialogAction(
///       label: 'Save',
///       isPrimary: true,
///       onPressed: () => Navigator.pop(context, true),
///     ),
///   ],
/// );
/// ```
///
/// ### Custom Content
/// ```dart
/// GlassDialog.show(
///   context: context,
///   title: 'Enter Name',
///   content: Padding(
///     padding: EdgeInsets.symmetric(vertical: 16),
///     child: TextField(
///       decoration: InputDecoration(
///         hintText: 'Name',
///       ),
///     ),
///   ),
///   actions: [
///     GlassDialogAction(
///       label: 'Cancel',
///       onPressed: () => Navigator.pop(context),
///     ),
///     GlassDialogAction(
///       label: 'OK',
///       isPrimary: true,
///       onPressed: () => Navigator.pop(context),
///     ),
///   ],
/// );
/// ```
///
/// ### Custom Glass Settings
/// ```dart
/// GlassDialog.show(
///   context: context,
///   title: 'Custom Dialog',
///   message: 'With custom glass effect',
///   settings: LiquidGlassSettings(
///     thickness: 40,
///     blur: 15,
///     glassColor: Colors.purple,
///   ),
///   actions: [
///     GlassDialogAction(
///       label: 'OK',
///       onPressed: () => Navigator.pop(context),
///     ),
///   ],
/// );
/// ```
class GlassDialog extends StatelessWidget {
  /// Creates a glass dialog widget.
  ///
  /// Typically not instantiated directly - use [GlassDialog.show] instead.
  const GlassDialog({
    required this.actions,
    super.key,
    this.title,
    this.message,
    this.content,
    this.settings,
    this.quality,
    this.maxWidth,
    this.shape,
    this.actionShape,
    this.actionTextStyle,
  }) : assert(
          actions.length > 0 && actions.length <= 3,
          'GlassDialog must have 1-3 actions',
        );

  static const double _classicWidth = 280;

  static const _actionButtonShape = LiquidRoundedSuperellipse(borderRadius: 12);

  // Cache default colors to avoid allocations
  static const _defaultGlowColor =
      Color(0x4DFFFFFF); // white.withValues(alpha: 0.3)
  static const _destructiveGlowColor =
      Color(0x4DFF0000); // red.withValues(alpha: 0.3)
  static const _primaryGlowColor =
      Color(0x4D0000FF); // blue.withValues(alpha: 0.3)

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// Title of the dialog.
  ///
  /// Displayed in bold at the top of the dialog. If null, no title is shown.
  final String? title;

  /// Message text of the dialog.
  ///
  /// Displayed below the title in a lighter color. If null, no message is
  /// shown.
  final String? message;

  /// Custom content widget.
  ///
  /// Displayed between the message and actions. Use this for custom content
  /// like text fields, pickers, or other interactive widgets.
  ///
  /// If both [message] and [content] are provided, content is shown below
  /// the message.
  final Widget? content;

  /// Maximum width of the dialog in logical pixels.
  ///
  /// If null, follows the active [GlassStyle]: 320 for [GlassStyle.ios26] and
  /// [GlassStyle.ios27] (the native iOS 26/27 alert width) and 280 for
  /// [GlassStyle.classic] (the original iOS alert width).
  final double? maxWidth;

  // ===========================================================================
  // Action Properties
  // ===========================================================================

  /// Action buttons to display at the bottom of the dialog.
  ///
  /// Must have 1-3 actions. Layout automatically adjusts:
  /// - 1-2 actions: Horizontal layout
  /// - 3 actions: Vertical layout (iOS pattern)
  final List<GlassDialogAction> actions;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings for the dialog.
  ///
  /// Controls the visual appearance of the glass effect including thickness,
  /// blur radius, color tint, lighting, and more.
  ///
  /// If null, uses [LiquidGlassSettings] defaults.
  final LiquidGlassSettings? settings;

  /// The dialog's shape.
  ///
  /// Null keeps the style's default: 34 pt continuous corners on the `ios26`
  /// and `ios27` alert platter, a 12 pt superellipse on `classic`.
  final LiquidShape? shape;

  /// The action buttons' shape.
  ///
  /// Null keeps the style's default: the native capsule on `ios26` / `ios27`
  /// (32 pt corners when an accessibility text size wraps the label) and a
  /// 12 pt superellipse on `classic`. A given shape is kept at every text
  /// size.
  final LiquidShape? actionShape;

  /// Merged over the action labels' text style (size, weight, family).
  ///
  /// The label's color still follows its role (default, primary/tinted
  /// contrast, [GlassDialogAction.foregroundColor], destructive, or disabled).
  /// On `ios26` / `ios27`, `isPrimary` (or an explicit `tintColor`) is
  /// distinguished by `FontWeight.w600` (and `FontWeight.bold` on `classic`),
  /// so leaving [TextStyle.fontWeight] null preserves the primary action's
  /// emphasis.
  final TextStyle? actionTextStyle;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.premium] on [GlassStyle.ios27] and
  /// [GlassStyle.ios26] ([GlassStyle.classic] defaults to
  /// [GlassQuality.standard]).
  final GlassQuality? quality;

  // ===========================================================================
  // Static Show Method
  // ===========================================================================

  /// Shows a glass dialog.
  ///
  /// Returns a [Future] that resolves to the value (if any) passed to
  /// [Navigator.pop] when the dialog is dismissed.
  ///
  /// Parameters:
  /// - [context]: Build context for showing the dialog
  /// - [title]: Title text (optional)
  /// - [message]: Message text (optional)
  /// - [content]: Custom content widget (optional)
  /// - [actions]: Action buttons (required, 1-3 actions)
  /// - [settings]: Glass effect settings (null uses defaults)
  /// - [quality]: Rendering quality (null inherits from the ambient layer or
  ///   [GlassTheme], falling back to standard)
  /// - [barrierDismissible]: Whether tapping outside dismisses (default: false)
  /// - [barrierColor]: Color of the modal barrier (defaults to the native
  ///   dimming on `ios26`/`ios27`, and the Cupertino modal barrier color on
  ///   `classic`)
  /// - [maxWidth]: Maximum width of dialog (null follows the active style:
  ///   320 on `ios26`/`ios27`, 280 on `classic`)
  /// - [shape]: Custom dialog shape (null uses the style default)
  /// - [actionShape]: Custom action button shape (null uses the style default)
  /// - [actionTextStyle]: Merged over action label styles (role colors still
  ///   apply)
  ///
  /// Example:
  /// ```dart
  /// final result = await GlassDialog.show<bool>(
  ///   context: context,
  ///   title: 'Confirm',
  ///   message: 'Are you sure?',
  ///   actions: [
  ///     GlassDialogAction(
  ///       label: 'Cancel',
  ///       onPressed: () => Navigator.pop(context, false),
  ///     ),
  ///     GlassDialogAction(
  ///       label: 'Confirm',
  ///       onPressed: () => Navigator.pop(context, true),
  ///     ),
  ///   ],
  /// );
  /// ```
  static Future<T?> show<T>({
    required BuildContext context,
    required List<GlassDialogAction> actions,
    String? title,
    String? message,
    Widget? content,
    LiquidGlassSettings? settings,
    GlassQuality? quality,
    bool barrierDismissible = false,
    Color? barrierColor,
    double? maxWidth,
    LiquidShape? shape,
    LiquidShape? actionShape,
    TextStyle? actionTextStyle,
  }) {
    final capturedThemes = CapturedModalThemes.forNavigator(
      context,
      useRootNavigator: true,
    );
    final isNative =
        GlassThemeHelpers.resolveStyle(context) != GlassStyle.classic;
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final resolvedBarrierColor = barrierColor != null
        ? CupertinoDynamicColor.resolve(barrierColor, context)
        : (isNative
            ? glassAlertBarrierColor(isDark: isDark)
            : CupertinoDynamicColor.resolve(
                kCupertinoModalBarrierColor,
                context,
              ));
    return pushGlassAlertRoute<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: resolvedBarrierColor,
      builder: (dialogContext) => capturedThemes.wrap(
        GlassDialog(
          title: title,
          message: message,
          content: content,
          actions: actions,
          settings: settings,
          quality: quality,
          maxWidth: maxWidth,
          shape: shape,
          actionShape: actionShape,
          actionTextStyle: actionTextStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (GlassThemeHelpers.resolveStyle(context) != GlassStyle.classic) {
      // ios26 / ios27: the native alert platter.
      return GlassAlertPlatter(
        title: title,
        message: message,
        content: content,
        settings: settings,
        quality: quality,
        maxWidth: maxWidth,
        shape: shape,
        actionShape: actionShape,
        actionTextStyle: actionTextStyle,
        actions: [
          for (final action in actions)
            GlassAlertPlatterAction(
              label: action.label,
              onPressed: action.onPressed,
              isPrimary: action.isPrimary,
              isDestructive: action.isDestructive,
              tintColor: action.tintColor,
              foregroundColor: action.foregroundColor,
            ),
        ],
      );
    }

    return wrapGlassAlertSyncedBrightness(
      context,
      builder: _buildClassic,
    );
  }

  Widget _buildClassic(BuildContext context) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
    );
    final platterSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: settings,
      isOverlayPlatter: true,
    );
    // The action buttons sit flat on the platter, so they resolve the ambient
    // surface optics minus the surface's exterior shadow.
    final buttonSettings = settings ??
        GlassThemeHelpers.resolveSettings(context)
            .copyWith(shadow: const [], shadowElevation: 0);
    final primaryActions = [
      for (final action in actions)
        if (action.isPrimary) action,
    ];
    final hasSinglePrimary = primaryActions.length == 1;
    final primaryCallback =
        hasSinglePrimary ? primaryActions.single.onPressed : null;

    return GlassDialogDefaultActionScope(
      hasPrimaryAction: hasSinglePrimary,
      onActivatePrimary: primaryCallback,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? _classicWidth),
          child: GlassContainer.card(
            useOwnLayer: true,
            settings: platterSettings,
            quality: effectiveQuality,
            shape: shape,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],

                // Message
                if (message != null) ...[
                  Text(
                    message!,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],

                // Custom content
                if (content != null) ...[
                  content!,
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 12),

                // Actions
                _buildActions(context, buttonSettings, effectiveQuality),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Whether every label fits on one line in half the dialog's width.
  ///
  /// Mirrors iOS: two actions whose labels would wrap are stacked instead.
  bool _labelsFitSideBySide(BuildContext context, double width) {
    if (actions.length < 2) return true;
    // Two buttons and the 8 pt gap between them; the label keeps clear of
    // the button's 12 pt corners on both sides.
    final labelWidth = (width - 8) / 2 - 2 * 12;
    final baseStyle = DefaultTextStyle.of(context).style;
    for (final action in actions) {
      final painter = TextPainter(
        text: TextSpan(
          text: action.label,
          style: baseStyle.merge(_labelStyle(action)),
        ),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final fits = painter.width <= labelWidth;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }

  TextStyle _labelStyle(GlassDialogAction action) => TextStyle(
        fontSize: 16,
        fontWeight: (action.isPrimary || action.tintColor != null)
            ? FontWeight.bold
            : FontWeight.w600,
      ).merge(actionTextStyle);

  Widget _buildActions(
    BuildContext context,
    LiquidGlassSettings buttonSettings,
    GlassQuality effectiveQuality,
  ) =>
      LayoutBuilder(
        builder: (context, constraints) => _buildActionsIn(
          context,
          constraints.maxWidth,
          buttonSettings,
          effectiveQuality,
        ),
      );

  Widget _buildActionsIn(
    BuildContext context,
    double width,
    LiquidGlassSettings buttonSettings,
    GlassQuality effectiveQuality,
  ) {
    // 1-2 actions: Horizontal layout, unless a label does not fit
    if (actions.length <= 2 && _labelsFitSideBySide(context, width)) {
      return Row(
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: index > 0 ? 8 : 0,
              ),
              child: _buildActionButton(
                action,
                context,
                buttonSettings,
                effectiveQuality,
              ),
            ),
          );
        }).toList(),
      );
    }

    // 3 actions, or labels too long for a row: Vertical layout (iOS pattern)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            top: index > 0 ? 8 : 0,
          ),
          child: _buildActionButton(
            action,
            context,
            buttonSettings,
            effectiveQuality,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
    GlassDialogAction action,
    BuildContext context,
    LiquidGlassSettings buttonSettings,
    GlassQuality effectiveQuality,
  ) {
    final enabled = action.onPressed != null;
    final (accentFill: resolvedTint, foregroundColor: labelColor) =
        resolveGlassAlertActionColors(
      context,
      enabled: enabled,
      isPrimary: action.isPrimary,
      isDestructive: action.isDestructive,
      tintColor: action.tintColor,
      foregroundColor: action.foregroundColor,
      isClassic: true,
    );
    final hasProminentFill = resolvedTint != null;

    // Determine button glow color based on action type
    var glowColor = _defaultGlowColor;
    if (action.isDestructive && resolvedTint == null) {
      glowColor = _destructiveGlowColor;
    } else if (action.isPrimary && resolvedTint == null) {
      glowColor = _primaryGlowColor;
    }

    return GlassButton.custom(
      onTap: action.onPressed ?? () {},
      enabled: enabled,
      height: 44,
      style: hasProminentFill
          ? GlassButtonStyle.prominent
          : GlassButtonStyle.filled,
      tintColor: resolvedTint,
      shape: actionShape ?? _actionButtonShape,
      settings: buttonSettings,
      quality: effectiveQuality,
      glowColor: glowColor,
      child: Text(
        action.label,
        style: _labelStyle(action).copyWith(color: labelColor),
      ),
    );
  }
}

/// Configuration for a dialog action button.
///
/// Used with [GlassDialog] to define action buttons.
class GlassDialogAction {
  /// Creates a dialog action configuration.
  const GlassDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.tintColor,
    this.foregroundColor,
  });

  /// Label text for the button.
  final String label;

  /// Callback when the button is pressed.
  ///
  /// If null, the action is disabled: it stays in place, ignores taps, and is
  /// reported as disabled to assistive technology. On [GlassStyle.ios27] and
  /// [GlassStyle.ios26] a disabled action (including a primary or tinted
  /// action) reverts to the neutral capsule wash and draws its title in
  /// [CupertinoColors.tertiaryLabel], matching a disabled `UIAlertAction`; on
  /// [GlassStyle.classic] the button is dimmed like any disabled [GlassButton].
  final VoidCallback? onPressed;

  /// Whether this is the primary (recommended) action.
  ///
  /// Mirrors UIKit's `UIAlertController.preferredAction` and SwiftUI's
  /// `.keyboardShortcut(.defaultAction)` inside `.alert`:
  /// - On [GlassStyle.ios27] and [GlassStyle.ios26], an enabled non-destructive
  ///   primary action fills its capsule with [tintColor] (defaulting to
  ///   `CupertinoTheme.of(context).primaryColor`) and draws `FontWeight.w600`
  ///   luminance-contrasted white or black text (overridable via
  ///   [foregroundColor]).
  /// - If [isDestructive] is also true (and [tintColor] is null), the action
  ///   keeps the neutral capsule with `FontWeight.w600` red text, matching
  ///   native iOS 26/27.
  /// - When disabled (`onPressed == null`), the capsule reverts to the neutral
  ///   wash with [CupertinoColors.tertiaryLabel] text.
  /// - When a single primary action is present and enabled, pressing the
  ///   hardware `Return` / `Enter` key activates it directly (unless another
  ///   button or a text input inside [GlassDialog.content] handles the key).
  /// - On [GlassStyle.classic], renders a prominent tinted [GlassButton].
  ///
  /// Apple HIG recommends marking at most one action per dialog as primary.
  ///
  /// Defaults to false.
  final bool isPrimary;

  /// Whether this is a destructive action.
  ///
  /// Destructive actions are displayed with red text inside the neutral capsule
  /// on [GlassStyle.ios27] / [GlassStyle.ios26] (and red text/glow on
  /// [GlassStyle.classic]), unless an explicit [tintColor] is also supplied.
  /// Typically used for delete, remove, or other dangerous actions.
  ///
  /// Defaults to false.
  final bool isDestructive;

  /// Optional custom accent fill color for this action.
  ///
  /// Supports [CupertinoDynamicColor], resolved against the active
  /// [BuildContext].
  /// - When [isPrimary] is true (and [isDestructive] is false), [tintColor]
  ///   overrides the default `CupertinoTheme.of(context).primaryColor` fill.
  /// - When set on a non-primary or destructive action, explicitly fills that
  ///   action's capsule with [tintColor] while enabled.
  /// - When disabled (`onPressed == null`), ignored so disabled actions revert
  ///   to the neutral capsule wash on `ios27`/`ios26` (and neutral dimmed glass
  ///   on `classic`).
  ///
  /// In `MaterialApp`, `CupertinoTheme.of(context).primaryColor` already
  /// bridges `Theme.of(context).colorScheme.primary` automatically, so
  /// `isPrimary: true` follows your Material theme without setting [tintColor];
  /// set [tintColor] to override it with any custom color.
  final Color? tintColor;

  /// Optional label color override when this action is enabled.
  ///
  /// Supports [CupertinoDynamicColor], resolved against the active
  /// [BuildContext]. When null, filled capsules with alpha `> 0.5`
  /// automatically select high-contrast [CupertinoColors.white] or
  /// [CupertinoColors.black] based on luminance (`> 0.55` flips to black),
  /// destructive neutral actions use [CupertinoColors.systemRed], and plain
  /// actions use [CupertinoColors.label].
  ///
  /// Ignored when disabled (`onPressed == null`), where [GlassStyle.ios27] and
  /// [GlassStyle.ios26] use [CupertinoColors.tertiaryLabel].
  final Color? foregroundColor;
}
