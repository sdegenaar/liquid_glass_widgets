// ignore_for_file: public_member_api_docs
// Internal: the native iOS 26 / iOS 27 alert platter shared by [GlassDialog]
// and [showGlassActionSheet].
//
// Measured from `UIAlertController` (`_UIAlertControllerPhoneTVMacView`) on the
// iOS 26.0 and iOS 27.0 simulators, which are identical:
//
// - platter: 320 pt wide, 34 pt continuous corner radius;
// - header: title SF Semibold 17 at (30, 22), message SF Regular 15 secondary
//   7.33 pt below it, both leading-aligned, 4.33 pt below the message;
// - actions: 48 pt tall filled capsules inset 16 pt on every side, 8 pt apart,
//   SF Medium 17 (Semibold for the preferred action); two actions share a row
//   when their labels fit, otherwise they stack;
// - preferredAction (iOS 26.0 & iOS 27.0): non-destructive preferred actions
//   fill their capsule with the alert's tint / systemBlue (`#0088FF` light /
//   `#0091FF` dark at 100% alpha, dropping to 40% alpha while pressed) and
//   draw Semibold contrast text; destructive preferred actions stay in the
//   neutral capsule with Semibold red text; disabled preferred actions revert
//   to the neutral capsule wash with Semibold `tertiaryLabel` text;
// - a UIKit action sheet shown without a source view is this same platter with
//   stacked actions (Cancel included), centred on screen.
//
// Behaviour, measured on the iOS 26.5 and iOS 27.0 simulators:
//
// - a header too tall for the screen scrolls (title and message together)
//   while the actions stay pinned below it;
// - with the keyboard up, the platter re-centres in the space above it;
// - action titles are one line, and wrap only at accessibility text sizes.

import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, LogicalKeyboardKey;

import '../../../src/renderer/liquid_glass_renderer.dart';
import '../../../src/utils/glass_localizations.dart';
import '../../../theme/glass_theme.dart';
import '../../../theme/glass_theme_helpers.dart';
import '../../../types/glass_quality.dart';
import '../../../types/glass_style.dart';
import '../../../widgets/containers/glass_container.dart';
import '../../../widgets/effects/shared/glass_materialize_effect.dart';
import '../../../widgets/shared/glass_focus_region.dart';
import 'modal_theme_capture.dart';

/// Native alert platter width on iOS 26 / iOS 27 (unanchored centered).
const double kGlassAlertPlatterWidth = 320;

/// Native anchored confirmation dialog popover width on iOS 26 / iOS 27
/// (measured from `_UIPopoverView` / `_UIAlertControllerPhoneTVMacView` on the
/// iOS 27.2 simulator: 240.0 pt wide with 30 pt header inset and 16 pt action
/// inset → 208 pt wide × 48 pt tall capsules).
const double kGlassConfirmationPopoverWidth = 240;

/// Native alert / confirmation dialog continuous corner radius on iOS 26 / 27.
const double kGlassAlertPlatterCornerRadius = 34;

/// The modal barrier behind a native alert / action sheet on iOS 26 / iOS 27.
///
/// Derived from the same screen point with and without a native alert on both
/// runtimes: white → `#CACACA` in light mode (≈ 0.21 black) and `#1C1C1E` →
/// `#0F0F10` in dark mode (≈ 0.47 black).
Color glassAlertBarrierColor({required bool isDark}) =>
    isDark ? const Color(0x77000000) : const Color(0x35000000);

/// Route transition for [GlassDialog.show] and native [showGlassActionSheet].
///
/// Dissolves the alert platter through [GlassMaterializeEffect] (shader
/// `visibility` + content channel) instead of `CupertinoDialogRoute`'s default
/// [FadeTransition], so no ancestor `OpacityLayer` ever wraps the platter's
/// `BackdropFilterLayer` while `0.0 < animation.value < 1.0`.
///
/// - **Entrance**: settles inward from `scaleFrom: 1.06` while materializing
///   the glass and sharpening content (`contentSigma: 4.0`).
/// - **Settled exit** (`AnimationStatus.reverse` after reaching rest): holds
///   `scale: 1.0` and co-dissolves glass and content together (`plain: true`)
///   so the Cupertino spring tail does not leave an empty frosted platter after
///   the labels vanish.
/// - **Mid-entrance cancel**: if dismissed before settling, rewinds the
///   entrance choreography continuously so scale, content opacity, and content
///   sigma never snap on reversal.
Widget buildGlassAlertTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return _GlassAlertTransition(
    animation: animation,
    child: child,
  );
}

class _GlassAlertTransition extends StatefulWidget {
  const _GlassAlertTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  State<_GlassAlertTransition> createState() => _GlassAlertTransitionState();
}

class _GlassAlertTransitionState extends State<_GlassAlertTransition> {
  bool _hasSettled = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      child: widget.child,
      builder: (context, child) {
        final value = widget.animation.value;
        final status = widget.animation.status;
        if (status == AnimationStatus.completed || value >= 0.99) {
          _hasSettled = true;
        } else if (status == AnimationStatus.dismissed) {
          _hasSettled = false;
        }
        final isSettledExit = _hasSettled && status == AnimationStatus.reverse;
        return GlassMaterializeEffect(
          progress: value,
          profile: isSettledExit
              ? GlassMaterializeProfile.exit
              : GlassMaterializeProfile.entrance,
          scaleFrom: isSettledExit ? 1.0 : 1.06,
          contentSigma: 4.0,
          plain: isSettledExit,
          child: child!,
        );
      },
    );
  }
}

/// Pushes a [CupertinoDialogRoute] onto the navigator using
/// [buildGlassAlertTransition] and a safe [CupertinoLocalizations] fallback.
Future<T?> pushGlassAlertRoute<T>({
  required BuildContext context,
  required bool barrierDismissible,
  required Color barrierColor,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    CupertinoDialogRoute<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel:
          glassCupertinoLocalizationsOf(context).modalBarrierDismissLabel,
      transitionBuilder: buildGlassAlertTransition,
      builder: builder,
    ),
  );
}

/// Whether text is scaled into the accessibility sizes, where native action
/// titles wrap instead of truncating. Same threshold as `CupertinoAlertDialog`.
bool _isInAccessibilityMode(BuildContext context) {
  const defaultFontSize = 14.0;
  final scaled = MediaQuery.maybeTextScalerOf(context)?.scale(defaultFontSize);
  return scaled != null && scaled > defaultFontSize * 1.4;
}

/// Luminance threshold above which prominent/tinted alert action foregrounds
/// flip from white to black (matches `GlassButton`, `GlassIconButton`, and
/// `GlassBarItem`).
const double _kAlertProminentContrastLuminanceThreshold = 0.55;

/// Alpha multiplier applied to a filled prominent alert capsule while pressed,
/// measured from `_UIAlertControllerFilledBackgroundView` on the iOS 27.0
/// simulator (`UIView.alpha = 0.400` in both light and dark modes).
const double _kAlertProminentPressedAlphaFactor = 0.40;

/// Subtle alpha multiplier applied to a filled prominent alert capsule on
/// desktop/iPad pointer hover.
const double _kAlertProminentHoverAlphaFactor = 0.85;

/// Resolves the resting fill and foreground colors for a dialog action button.
///
/// Shared between [GlassAlertPlatter] (`ios26`/`ios27`) and [GlassDialog]'s
/// `GlassStyle.classic` path so prominence, `CupertinoDynamicColor`
/// resolution, luminance contrast flipping, destructive rules, and disabled
/// fallbacks stay strictly aligned.
({Color? accentFill, Color foregroundColor}) resolveGlassAlertActionColors(
  BuildContext context, {
  required bool enabled,
  required bool isPrimary,
  required bool isDestructive,
  Color? tintColor,
  Color? foregroundColor,
  bool isClassic = false,
}) {
  // Prominent accent fill (measured on iOS 26.0 and iOS 27.0):
  // - Disabled actions always revert to the neutral capsule wash / glass.
  // - Explicit `tintColor` fills the capsule (even on destructive or
  //   non-primary actions).
  // - `isPrimary` without `isDestructive` fills with `CupertinoTheme`'s
  //   `primaryColor`, matching `UIAlertController.preferredAction`;
  //   destructive preferred actions stay in the neutral capsule with Semibold
  //   red text.
  final Color? accentFill;
  if (enabled && tintColor != null) {
    accentFill = CupertinoDynamicColor.resolve(tintColor, context);
  } else if (enabled && isPrimary && !isDestructive) {
    accentFill = CupertinoDynamicColor.resolve(
      CupertinoTheme.of(context).primaryColor,
      context,
    );
  } else {
    accentFill = null;
  }

  final resolvedForeground =
      CupertinoDynamicColor.maybeResolve(foregroundColor, context);
  final Color resolvedTextColor;
  if (!enabled && !isClassic) {
    // A disabled action keeps its weight, reverts to the neutral capsule, and
    // dims its title to tertiaryLabel, matching disabled UIAlertAction.
    resolvedTextColor = CupertinoColors.tertiaryLabel.resolveFrom(context);
  } else if (enabled && resolvedForeground != null) {
    resolvedTextColor = resolvedForeground;
  } else if (accentFill != null && accentFill.a > 0.5) {
    resolvedTextColor = accentFill.computeLuminance() >
            _kAlertProminentContrastLuminanceThreshold
        ? CupertinoColors.black
        : CupertinoColors.white;
  } else if (isDestructive) {
    resolvedTextColor =
        (isClassic ? CupertinoColors.destructiveRed : CupertinoColors.systemRed)
            .resolveFrom(context);
  } else {
    resolvedTextColor = CupertinoColors.label.resolveFrom(context);
  }

  return (accentFill: accentFill, foregroundColor: resolvedTextColor);
}

/// Keeps a dialog's descendant [CupertinoTheme] brightness synchronized with
/// [GlassTheme.brightnessOf] (the package's single brightness authority) even
/// when [GlassDialog] is mounted directly rather than through `GlassDialog.show`.
Widget wrapGlassAlertSyncedBrightness(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final resolvedBrightness = GlassTheme.brightnessOf(context);
  final currentCupertino = CupertinoTheme.of(context);
  final effectiveCupertinoBrightness =
      currentCupertino.brightness ?? MediaQuery.platformBrightnessOf(context);
  final effectiveCupertino = effectiveCupertinoBrightness == resolvedBrightness
      ? currentCupertino
      : currentCupertino.copyWith(brightness: resolvedBrightness);
  return GlassInternalCupertinoTheme(
    data: effectiveCupertino,
    child: Builder(builder: builder),
  );
}

/// Handles hardware-keyboard Return/Enter activation for a dialog's primary
/// action, mirroring UIKit's `UIAlertController.preferredAction` and SwiftUI's
/// `.keyboardShortcut(.defaultAction)`.
///
/// Only activates when a single `isPrimary` action is present and enabled,
/// plain Enter / Numpad Enter is pressed without modifiers, and no descendant
/// focused button or [EditableText] handles the key first.
class GlassDialogDefaultActionScope extends StatefulWidget {
  const GlassDialogDefaultActionScope({
    required this.hasPrimaryAction,
    required this.onActivatePrimary,
    required this.child,
    super.key,
  });

  final bool hasPrimaryAction;
  final VoidCallback? onActivatePrimary;
  final Widget child;

  @override
  State<GlassDialogDefaultActionScope> createState() =>
      _GlassDialogDefaultActionScopeState();
}

class _GlassDialogDefaultActionScopeState
    extends State<GlassDialogDefaultActionScope> {
  late final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'GlassDialogDefaultActionScope',
  );

  @override
  void dispose() {
    _scopeNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    // Only act as the dialog's fallback Return-key handler when no descendant
    // (such as a Tab-focused action button or a text input inside `content`)
    // holds primary focus; otherwise let the key bubble to WidgetsApp's
    // Shortcuts so the focused descendant handles it.
    if (FocusManager.instance.primaryFocus != _scopeNode) {
      return KeyEventResult.ignored;
    }
    final callback = widget.onActivatePrimary;
    if (callback == null) return KeyEventResult.ignored;
    callback();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _scopeNode,
      autofocus: widget.hasPrimaryAction,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

/// One action row of a [GlassAlertPlatter].
class GlassAlertPlatterAction {
  const GlassAlertPlatterAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.tintColor,
    this.foregroundColor,
    this.icon,
  });

  final String label;

  /// Null disables the action.
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final Color? tintColor;
  final Color? foregroundColor;
  final Widget? icon;
}

/// Resolves the platter's glass settings for alerts and confirmation dialogs.
///
/// Shared between [GlassAlertPlatter] (centered) and anchored
/// `showGlassConfirmationDialog` popovers so both render identical iOS 26/27
/// material optics across `premium`, `standard`, and `minimal` quality tiers.
LiquidGlassSettings resolveGlassAlertPlatterSettings(
  BuildContext context, {
  LiquidGlassSettings? explicit,
  required GlassQuality effectiveQuality,
}) {
  final resolved = GlassThemeHelpers.resolveSettings(
    context,
    explicit: explicit,
    isOverlayPlatter: true,
  );
  if (explicit != null) return resolved;

  final style = GlassThemeHelpers.resolveStyle(context);
  final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;

  // On GlassQuality.standard, lightweight_glass.frag lacks Premium's odd-row
  // frost cloud (frost: 14, frostOpacity: 1.0) and luminance-weighted frost
  // (frostWeight: 0.5, frostClamp: -0.45/-0.49). Preserve the full frost
  // sigma on standard alerts, and boost ambient darkening + tint floor on
  // dark ios26 (2% alpha) and ios27 (12% alpha) when using unmodified tints.
  if (effectiveQuality == GlassQuality.standard &&
      style != GlassStyle.classic) {
    if (isDark) {
      final defaultDarkTint = style == GlassStyle.ios26
          ? LiquidGlassSettings.ios26Dark.glassColor
          : LiquidGlassSettings.ios27Dark.glassColor;
      if (resolved.glassColor == defaultDarkTint) {
        return resolved.copyWith(
          blur: 18.0,
          ambientStrength: 0.75,
          glassColor: style == GlassStyle.ios26
              ? const Color(0x18FFFFFF)
              : const Color(0x22FFFFFF),
        );
      }
    }
    return resolved.copyWith(
      blur: math.max(resolved.blur, resolved.frost),
    );
  }

  if (style == GlassStyle.ios26 &&
      isDark &&
      resolved.glassColor == LiquidGlassSettings.ios26Dark.glassColor) {
    return resolved.copyWith(glassColor: const Color(0x05FFFFFF));
  }
  return resolved;
}

/// The inner card of an iOS 26/27 alert or confirmation dialog platter:
/// scrollable leading-aligned header (title/message/content) + 48 pt capsule
/// actions + hardware Return-key default-action scope.
///
/// Set [wrapInGlassContainer] to `false` when embedding inside an outer
/// morphing [GlassContainer] (such as an anchored confirmation dialog popover)
/// so the surface never nests glass inside glass.
class GlassAlertPlatterCard extends StatelessWidget {
  const GlassAlertPlatterCard({
    required this.actions,
    super.key,
    this.title,
    this.message,
    this.content,
    this.settings,
    this.quality,
    this.forceStacked = false,
    this.shape,
    this.actionShape,
    this.actionTextStyle,
    this.wrapInGlassContainer = true,
  });

  final List<GlassAlertPlatterAction> actions;
  final String? title;
  final String? message;
  final Widget? content;
  final LiquidGlassSettings? settings;
  final GlassQuality? quality;
  final bool forceStacked;
  final LiquidShape? shape;
  final OutlinedBorder? actionShape;
  final TextStyle? actionTextStyle;
  final bool wrapInGlassContainer;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || message != null || content != null;
    final messageColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Native scrolls the title and message together when they outgrow the
        // screen, keeping the actions visible.
        if (hasHeader)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(30, 22, 30, 4.33),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  if (title != null && message != null)
                    const SizedBox(height: 7.33),
                  if (message != null)
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        message!,
                        style: TextStyle(
                          fontSize: 15,
                          color: messageColor,
                        ),
                      ),
                    ),
                  if (content != null) ...[
                    if (title != null || message != null)
                      const SizedBox(height: 8),
                    // Plain text in custom content reads as message text.
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 15,
                        color: messageColor,
                      ),
                      child: content!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, hasHeader ? 16 : 22, 16, 16),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildActions(context, constraints.maxWidth),
          ),
        ),
      ],
    );

    if (!wrapInGlassContainer) {
      return body;
    }

    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );
    final platterSettings = resolveGlassAlertPlatterSettings(
      context,
      explicit: settings,
      effectiveQuality: effectiveQuality,
    );

    return GlassContainer.card(
      useOwnLayer: true,
      settings: platterSettings,
      quality: effectiveQuality,
      shape: shape ??
          const LiquidRoundedSuperellipse(
            borderRadius: kGlassAlertPlatterCornerRadius,
          ),
      padding: EdgeInsets.zero,
      child: body,
    );
  }

  Widget _buildActions(BuildContext context, double width) {
    if (!forceStacked &&
        actions.length <= 2 &&
        _labelsFitSideBySide(context, width)) {
      return Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _button(actions[i])),
          ],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
            child: _button(actions[i]),
          ),
      ],
    );
  }

  Widget _button(GlassAlertPlatterAction action) => _GlassAlertPlatterButton(
        action: action,
        shape: actionShape,
        textStyle: _styleOf(action),
      );

  TextStyle _styleOf(GlassAlertPlatterAction action) =>
      _labelStyle(action).merge(actionTextStyle);

  /// Whether every label fits on one line in half the platter's width.
  bool _labelsFitSideBySide(BuildContext context, double width) {
    if (actions.length < 2) return true;
    // Two buttons and the 8 pt gap between them; the label keeps clear of the
    // capsule's rounded ends on both sides.
    final labelWidth = (width - 8) / 2 - 2 * 16;
    final baseStyle = DefaultTextStyle.of(context).style;
    for (final action in actions) {
      final painter = TextPainter(
        text: TextSpan(
          text: action.label,
          style: baseStyle.merge(_styleOf(action)),
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
}

/// The `ios26` / `ios27` alert platter.
class GlassAlertPlatter extends StatelessWidget {
  const GlassAlertPlatter({
    required this.actions,
    super.key,
    this.title,
    this.message,
    this.content,
    this.settings,
    this.quality,
    this.maxWidth,
    this.forceStacked = false,
    this.semanticsRole = SemanticsRole.alertDialog,
    this.shape,
    this.actionShape,
    this.actionTextStyle,
  });

  final List<GlassAlertPlatterAction> actions;
  final String? title;
  final String? message;
  final Widget? content;
  final LiquidGlassSettings? settings;
  final GlassQuality? quality;
  final double? maxWidth;

  /// Stack the actions even when they would fit side by side (action sheets).
  final bool forceStacked;

  /// The route's semantics role: [SemanticsRole.alertDialog] for an alert, and
  /// [SemanticsRole.dialog] for an action sheet, as `CupertinoAlertDialog` and
  /// `CupertinoActionSheet` report them.
  final SemanticsRole semanticsRole;

  /// The platter's shape; null keeps the native 34 pt continuous corners.
  final LiquidShape? shape;

  /// The action capsules' shape; null keeps the native capsule (32 pt
  /// corners for a label wrapped at an accessibility text size).
  final OutlinedBorder? actionShape;

  /// Merged over the action labels' text style; the colour follows the role.
  final TextStyle? actionTextStyle;

  @override
  Widget build(BuildContext context) {
    return wrapGlassAlertSyncedBrightness(
      context,
      builder: _buildPlatter,
    );
  }

  Widget _buildPlatter(BuildContext context) {
    final primaryActions = [
      for (final action in actions)
        if (action.isPrimary) action,
    ];
    final hasSinglePrimary = primaryActions.length == 1;
    final primaryCallback =
        hasSinglePrimary ? primaryActions.single.onPressed : null;

    // Native centres the platter in the safe area (its centre sits at
    // (safeTop + height - safeBottom) / 2, i.e. y = 451 on a 874 pt iPhone),
    // and in the space above the keyboard while one is up.
    return GlassDialogDefaultActionScope(
      hasPrimaryAction: hasSinglePrimary,
      onActivatePrimary: primaryCallback,
      child: AnimatedPadding(
        padding: MediaQuery.viewInsetsOf(context),
        duration: const Duration(milliseconds: 100),
        curve: Curves.decelerate,
        child: MediaQuery.removeViewInsets(
          context: context,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: maxWidth ?? kGlassAlertPlatterWidth),
                child: Semantics(
                  role: semanticsRole,
                  scopesRoute: true,
                  namesRoute: true,
                  explicitChildNodes: true,
                  label:
                      glassCupertinoLocalizationsOf(context).alertDialogLabel,
                  // Replaces the host app's default text style, which under a
                  // MaterialApp is the red, underlined error style.
                  child: DefaultTextStyle(
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    child: GlassAlertPlatterCard(
                      title: title,
                      message: message,
                      content: content,
                      actions: actions,
                      settings: settings,
                      quality: quality,
                      forceStacked: forceStacked,
                      shape: shape,
                      actionShape: actionShape,
                      actionTextStyle: actionTextStyle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _labelStyle(GlassAlertPlatterAction action) => TextStyle(
      fontSize: 17,
      fontWeight: (action.isPrimary || action.tintColor != null)
          ? FontWeight.w600
          : FontWeight.w500,
    );

/// A flat, filled capsule action (`_UIAlertControllerFilledBackgroundView`):
/// 48 pt tall, fully rounded, filled with either a prominent accent colour
/// (`tintColor` or `CupertinoTheme.primaryColor` for enabled non-destructive
/// primary actions) or a translucent neutral wash that darkens the platter in
/// light mode and lightens it in dark mode.
class _GlassAlertPlatterButton extends StatefulWidget {
  const _GlassAlertPlatterButton({
    required this.action,
    required this.shape,
    required this.textStyle,
  });

  final GlassAlertPlatterAction action;

  /// The caller's capsule shape; null keeps the native one.
  final OutlinedBorder? shape;
  final TextStyle textStyle;

  @override
  State<_GlassAlertPlatterButton> createState() =>
      _GlassAlertPlatterButtonState();
}

class _GlassAlertPlatterButtonState extends State<_GlassAlertPlatterButton> {
  bool _pressed = false;
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void didUpdateWidget(covariant _GlassAlertPlatterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.action.onPressed == null) {
      if (_pressed) {
        _pressed = false;
      }
      if (_hovered.value) {
        _hovered.value = false;
      }
    }
  }

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_pressed) {
      setState(() => _pressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (_pressed && mounted) {
      setState(() => _pressed = false);
    }
  }

  void _handleTapCancel() {
    if (_pressed && mounted) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    // The filled capsule wash differs between the two runtimes (measured):
    // iOS 27 darkens the light platter by ≈ 0.15 and lightens the dark one by
    // ≈ 0.115; iOS 26 is lighter in light mode (≈ 0.10) and stronger in dark
    // mode (≈ 0.13).
    final isIos26 = GlassThemeHelpers.resolveStyle(context) == GlassStyle.ios26;
    final restLight = isIos26 ? 0.10 : 0.15;
    final restDark = isIos26 ? 0.13 : 0.115;
    final action = widget.action;
    final enabled = action.onPressed != null;
    final isPressed = enabled && _pressed;

    final (:accentFill, foregroundColor: textColor) =
        resolveGlassAlertActionColors(
      context,
      enabled: enabled,
      isPrimary: action.isPrimary,
      isDestructive: action.isDestructive,
      tintColor: action.tintColor,
      foregroundColor: action.foregroundColor,
    );

    // One line, as native, except at accessibility sizes where native wraps the
    // title and grows the button rather than truncating it.
    final wraps = _isInAccessibilityMode(context);
    final label = Text(
      action.label,
      maxLines: wraps ? null : 1,
      overflow: wraps ? null : TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: widget.textStyle.copyWith(color: textColor),
    );
    final Widget buttonChild = action.icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: textColor, size: 20),
                child: action.icon!,
              ),
              const SizedBox(width: 12),
              Flexible(child: label),
            ],
          );

    // A capsule, except that a button grown by a wrapped title takes ≈ 32 pt
    // continuous corners (measured on iOS 27.0 at AX-XXXL) instead of
    // ballooning into an oval. A caller's shape is kept at every text size.
    final ShapeBorder shape = widget.shape ??
        (wraps
            ? const RoundedSuperellipseBorder(
                borderRadius: BorderRadius.all(Radius.circular(32)),
              )
            : const StadiumBorder());

    return GlassFocusRegion(
      enabled: enabled,
      isButton: true,
      isHoveredNotifier: _hovered,
      semanticLabel: action.label,
      shape: shape,
      onKeyboardActivate: action.onPressed,
      semanticOnTap: action.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: action.onPressed,
        onTapDown: enabled ? _handleTapDown : null,
        onTapUp: enabled ? _handleTapUp : null,
        onTapCancel: enabled ? _handleTapCancel : null,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          child: buttonChild,
          builder: (context, hovered, child) {
            final isHovered = enabled && hovered;
            final Color fill;
            if (accentFill != null) {
              if (isPressed) {
                fill = accentFill.withValues(
                  alpha: (accentFill.a * _kAlertProminentPressedAlphaFactor)
                      .clamp(0.0, 1.0),
                );
              } else if (isHovered) {
                fill = accentFill.withValues(
                  alpha: (accentFill.a * _kAlertProminentHoverAlphaFactor)
                      .clamp(0.0, 1.0),
                );
              } else {
                fill = accentFill;
              }
            } else {
              final restAlpha = isDark ? restDark : restLight;
              final effectiveAlpha = isPressed
                  ? restAlpha + (isDark ? 0.085 : 0.10)
                  : (isHovered ? restAlpha + 0.04 : restAlpha);
              fill = (isDark ? CupertinoColors.white : CupertinoColors.black)
                  .withValues(alpha: effectiveAlpha);
            }

            return Container(
              // 48 pt at regular text sizes; taller only when a wrapped title
              // needs the room.
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: ShapeDecoration(color: fill, shape: shape),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
