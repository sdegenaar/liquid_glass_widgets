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
// - a UIKit action sheet shown without a source view is this same platter with
//   stacked actions (Cancel included), centred on screen.
//
// Behaviour, measured on the iOS 26.5 and iOS 27.0 simulators:
//
// - a header too tall for the screen scrolls (title and message together)
//   while the actions stay pinned below it;
// - with the keyboard up, the platter re-centres in the space above it;
// - action titles are one line, and wrap only at accessibility text sizes.

import 'dart:ui' show SemanticsRole;

import 'package:flutter/cupertino.dart';

import '../../../src/renderer/liquid_glass_renderer.dart';
import '../../../src/utils/glass_localizations.dart';
import '../../../theme/glass_theme.dart';
import '../../../theme/glass_theme_helpers.dart';
import '../../../types/glass_quality.dart';
import '../../../types/glass_style.dart';
import '../../../widgets/containers/glass_container.dart';
import '../../../widgets/shared/glass_focus_region.dart';

/// Native alert platter width on iOS 26 / iOS 27.
const double kGlassAlertPlatterWidth = 320;

/// The modal barrier behind a native alert / action sheet on iOS 26 / iOS 27.
///
/// Derived from the same screen point with and without a native alert on both
/// runtimes: white → `#CACACA` in light mode (≈ 0.21 black) and `#1C1C1E` →
/// `#0F0F10` in dark mode (≈ 0.47 black).
Color glassAlertBarrierColor({required bool isDark}) =>
    isDark ? const Color(0x77000000) : const Color(0x35000000);

/// Whether text is scaled into the accessibility sizes, where native action
/// titles wrap instead of truncating. Same threshold as `CupertinoAlertDialog`.
bool _isInAccessibilityMode(BuildContext context) {
  const defaultFontSize = 14.0;
  final scaled = MediaQuery.maybeTextScalerOf(context)?.scale(defaultFontSize);
  return scaled != null && scaled > defaultFontSize * 1.4;
}

/// One action row of a [GlassAlertPlatter].
class GlassAlertPlatterAction {
  const GlassAlertPlatterAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
  });

  final String label;

  /// Null disables the action.
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final Widget? icon;
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

  /// The platter's glass settings.
  ///
  /// The shared overlay-platter preset is calibrated on menus and sheets. The
  /// native iOS 26 dark alert is a much thinner tint than that preset (≈ +4
  /// levels over its backdrop against ≈ +26), so when the app has not changed
  /// the preset's tint, the alert uses the measured one. Measured on the
  /// iOS 26 simulator at both `standard` and `premium` quality: premium's frost
  /// does not remove the preset's tint.
  LiquidGlassSettings _platterSettings(BuildContext context) {
    final resolved = GlassThemeHelpers.resolveSettings(
      context,
      explicit: settings,
      isOverlayPlatter: true,
    );
    if (settings == null &&
        GlassThemeHelpers.resolveStyle(context) == GlassStyle.ios26 &&
        GlassTheme.brightnessOf(context) == Brightness.dark &&
        resolved.glassColor == LiquidGlassSettings.ios26Dark.glassColor) {
      return resolved.copyWith(glassColor: const Color(0x05FFFFFF));
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );
    final platterSettings = _platterSettings(context);
    final hasHeader = title != null || message != null || content != null;

    final messageColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    // Native centres the platter in the safe area (its centre sits at
    // (safeTop + height - safeBottom) / 2, i.e. y = 451 on a 874 pt iPhone),
    // and in the space above the keyboard while one is up.
    return AnimatedPadding(
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
              constraints:
                  BoxConstraints(maxWidth: maxWidth ?? kGlassAlertPlatterWidth),
              child: Semantics(
                role: semanticsRole,
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: glassCupertinoLocalizationsOf(context).alertDialogLabel,
                // Replaces the host app's default text style, which under a
                // MaterialApp is the red, underlined error style.
                child: DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                  child: GlassContainer.card(
                    useOwnLayer: true,
                    settings: platterSettings,
                    quality: effectiveQuality,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 34),
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Native scrolls the title and message together when
                        // they outgrow the screen, keeping the actions visible.
                        if (hasHeader)
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  30, 22, 30, 4.33),
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
                                          color: CupertinoColors.label
                                              .resolveFrom(context),
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
                                    // Plain text in custom content reads as
                                    // message text.
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
                          padding: EdgeInsets.fromLTRB(
                              16, hasHeader ? 16 : 22, 16, 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                _buildActions(context, constraints.maxWidth),
                          ),
                        ),
                      ],
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

  Widget _buildActions(BuildContext context, double width) {
    if (!forceStacked &&
        actions.length <= 2 &&
        _labelsFitSideBySide(context, width)) {
      return Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _GlassAlertPlatterButton(action: actions[i])),
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
            child: _GlassAlertPlatterButton(action: actions[i]),
          ),
      ],
    );
  }

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
}

TextStyle _labelStyle(GlassAlertPlatterAction action) => TextStyle(
      fontSize: 17,
      fontWeight: action.isPrimary ? FontWeight.w600 : FontWeight.w500,
    );

/// A flat, filled capsule action (`_UIAlertControllerFilledBackgroundView`):
/// 48 pt tall, fully rounded, filled with a translucent wash that darkens the
/// platter in light mode and lightens it in dark mode.
class _GlassAlertPlatterButton extends StatefulWidget {
  const _GlassAlertPlatterButton({required this.action});

  final GlassAlertPlatterAction action;

  @override
  State<_GlassAlertPlatterButton> createState() =>
      _GlassAlertPlatterButtonState();
}

class _GlassAlertPlatterButtonState extends State<_GlassAlertPlatterButton> {
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant _GlassAlertPlatterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.action.onPressed == null && _pressed) {
      _pressed = false;
    }
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
    final fill = isDark
        ? CupertinoColors.white
            .withValues(alpha: isPressed ? restDark + 0.085 : restDark)
        : CupertinoColors.black
            .withValues(alpha: isPressed ? restLight + 0.10 : restLight);
    // A disabled action keeps its fill and weight and dims its title to
    // tertiaryLabel, which UIKit reports for a disabled UIAlertAction.
    final textColor = !enabled
        ? CupertinoColors.tertiaryLabel.resolveFrom(context)
        : action.isDestructive
            ? CupertinoColors.systemRed.resolveFrom(context)
            : CupertinoColors.label.resolveFrom(context);
    // One line, as native, except at accessibility sizes where native wraps the
    // title and grows the button rather than truncating it.
    final wraps = _isInAccessibilityMode(context);
    final label = Text(
      action.label,
      maxLines: wraps ? null : 1,
      overflow: wraps ? null : TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: _labelStyle(action).copyWith(color: textColor),
    );
    // A capsule, except that a button grown by a wrapped title takes ≈ 32 pt
    // continuous corners (measured on iOS 27.0 at AX-XXXL) instead of
    // ballooning into an oval.
    final ShapeBorder shape = wraps
        ? const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
          )
        : const StadiumBorder();

    return GlassFocusRegion(
      enabled: enabled,
      isButton: true,
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
        child: Container(
          // 48 pt at regular text sizes; taller only when a wrapped title
          // needs the room.
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: ShapeDecoration(color: fill, shape: shape),
          child: action.icon == null
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
                ),
        ),
      ),
    );
  }
}
