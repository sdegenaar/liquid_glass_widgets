import 'dart:math' as math;
import 'dart:ui' show ImageFilter, SemanticsRole, TileMode, lerpDouble;

import 'package:flutter/cupertino.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../src/utils/glass_localizations.dart';
import '../../src/widgets/overlays/glass_alert_platter.dart';
import '../../src/widgets/overlays/glass_morph_anchor.dart';
import '../../src/widgets/overlays/modal_theme_capture.dart';
import '../../theme/glass_theme.dart';
import '../../theme/glass_theme_helpers.dart';
import '../../types/glass_quality.dart';
import '../../utils/glass_morph_controller.dart';
import '../../utils/liquid_morph_physics.dart';
import '../containers/glass_container.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/glass_accessibility_scope.dart';
import 'glass_menu.dart' show GlassMenuAlignment;

/// A single action button displayed inside [showGlassConfirmationDialog].
///
/// Mirrors SwiftUI's `Button` roles inside `.confirmationDialog()` and UIKit's
/// `UIAlertAction`:
/// - Pass [onPressed] as `null` to keep the action visible in a disabled state
///   (neutral capsule wash with [CupertinoColors.tertiaryLabel] text).
/// - Set [isDestructive] to `true` for dangerous actions (e.g. Delete), which
///   render with [CupertinoColors.systemRed] text.
/// - Set [isPrimary] to `true` for a prominent default action filled with
///   [tintColor] (or `CupertinoTheme.of(context).primaryColor`), auto-contrasted
///   label text, and hardware `Return`/`Enter` key activation when a single
///   primary action is present.
class GlassConfirmationDialogAction {
  /// Creates a confirmation dialog action.
  const GlassConfirmationDialogAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.isPrimary = false,
    this.tintColor,
    this.foregroundColor,
    this.dismissOnPress = true,
  });

  /// Label text displayed inside the action capsule.
  final String label;

  /// Callback invoked when the action is tapped or activated from the keyboard.
  ///
  /// When `null`, the action is disabled: it stays in place, ignores input,
  /// reverts to the neutral capsule wash, and announces as disabled to
  /// assistive technology.
  final VoidCallback? onPressed;

  /// Optional leading icon widget displayed before [label].
  final Widget? icon;

  /// Whether this is a destructive action (e.g. delete or discard).
  ///
  /// Renders with [CupertinoColors.systemRed] text in the neutral capsule
  /// unless an explicit [tintColor] is provided.
  final bool isDestructive;

  /// Whether this is the primary (recommended) action.
  ///
  /// When enabled and non-destructive, fills the capsule with [tintColor]
  /// (defaulting to `CupertinoTheme.of(context).primaryColor`) and binds
  /// hardware `Return`/`Enter` activation when a single primary action is
  /// present.
  final bool isPrimary;

  /// Optional custom accent fill color for this action.
  ///
  /// Supports [CupertinoDynamicColor]. Ignored when [onPressed] is `null`.
  final Color? tintColor;

  /// Optional foreground text/icon color override when this action is enabled.
  ///
  /// Supports [CupertinoDynamicColor]. When `null`, automatically chooses
  /// high-contrast white/black on filled capsules, red for destructive actions,
  /// and [CupertinoColors.label] for default actions.
  final Color? foregroundColor;

  /// Whether tapping this action automatically dismisses the confirmation
  /// dialog after [onPressed] runs.
  ///
  /// Defaults to `true`, matching SwiftUI `.confirmationDialog()` and
  /// `UIAlertController`. If [onPressed] already pops the confirmation route
  /// (for example to return a value via `Navigator.pop(context, result)`), the
  /// automatic dismissal is skipped so the route is never double-popped.
  final bool dismissOnPress;
}

/// Presents a native iOS 26/27 Liquid Glass confirmation dialog, mirroring
/// SwiftUI's `.confirmationDialog()` and UIKit's
/// `UIAlertController(preferredStyle: .actionSheet)`.
///
/// ## Source-anchored vs. unanchored presentation
///
/// - **Source-anchored** (`morphFrom` via [GlassMorphTrigger], or explicit
///   `morphFromRect`): liquid-morphs directly out of the source trigger into a
///   calibrated `240 pt` floating Liquid Glass popover platter with a clear
///   dismiss barrier, **omitting the Cancel button by default** (since tapping
///   outside dismisses), and retracts back into the trigger with catch recoil
///   on dismissal.
/// - **Unanchored** (`morphFrom == null && morphFromRect == null`): presents
///   the calibrated `320 pt` centered Liquid Glass platter with stacked
///   `48 pt` capsule actions and a **Cancel button included by default** at the
///   bottom.
///
/// Pass [showCancelButton] explicitly (`true` or `false`) to override the
/// automatic anchored/unanchored Cancel button rule.
///
/// ## Usage
///
/// ### Anchored to a trigger button (recommended on iOS 26/27)
/// ```dart
/// GlassMorphTrigger(
///   builder: (context, anchor) => GlassIconButton(
///     icon: const Icon(CupertinoIcons.trash),
///     onPressed: () => showGlassConfirmationDialog<void>(
///       context: context,
///       morphFrom: anchor,
///       title: 'Delete Draft?',
///       message: 'This draft cannot be recovered once deleted.',
///       actions: [
///         GlassConfirmationDialogAction(
///           label: 'Save Draft',
///           onPressed: _saveDraft,
///         ),
///         GlassConfirmationDialogAction(
///           label: 'Delete Draft',
///           isDestructive: true,
///           onPressed: _deleteDraft,
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// ### Unanchored (centered platter with Cancel)
/// ```dart
/// await showGlassConfirmationDialog<void>(
///   context: context,
///   title: 'Choose Action',
///   message: 'Pick what to do with this item.',
///   actions: [
///     GlassConfirmationDialogAction(label: 'Share', onPressed: _share),
///     GlassConfirmationDialogAction(
///       label: 'Delete',
///       isDestructive: true,
///       onPressed: _delete,
///     ),
///   ],
/// );
/// ```
Future<T?> showGlassConfirmationDialog<T>({
  required BuildContext context,
  required List<GlassConfirmationDialogAction> actions,
  String? title,
  String? message,
  String? cancelLabel,
  bool? showCancelButton,
  GlassMorphAnchor? morphFrom,
  Rect? morphFromRect,
  GlassMenuAlignment? alignment,
  MorphSpeed morphSpeed = MorphSpeed.normal,
  bool barrierDismissible = true,
  Color? barrierColor,
  double? maxWidth,
  LiquidGlassSettings? settings,
  GlassQuality? quality,
  bool platformViewBackdrop = false,
  LiquidShape? shape,
  LiquidShape? actionShape,
  TextStyle? actionTextStyle,
  bool useRootNavigator = true,
}) {
  assert(
    morphFrom == null || morphFromRect == null,
    'Pass either morphFrom (the GlassMorphAnchor from a GlassMorphTrigger) '
    'or morphFromRect (an explicit global rect) — not both.',
  );

  final capturedThemes = CapturedModalThemes.forNavigator(
    context,
    useRootNavigator: useRootNavigator,
  );
  final triggerRect = resolveMorphTriggerRect(
    morphFrom,
    morphFromRect,
    callerName: 'showGlassConfirmationDialog',
  );
  final effectiveShowCancel = showCancelButton ?? (triggerRect == null);
  assert(
    actions.isNotEmpty || effectiveShowCancel,
    'showGlassConfirmationDialog requires at least one action when '
    'showCancelButton is false.',
  );

  final localizations = glassCupertinoLocalizationsOf(context);
  final effectiveCancelLabel = cancelLabel ?? localizations.cancelButtonLabel;

  if (triggerRect != null) {
    final reduceMotion = GlassAccessibilityData.of(context).reduceMotion;

    return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
      _GlassConfirmationPopoverRoute<T>(
        triggerRect: triggerRect,
        anchor: morphFrom,
        alignment: alignment,
        morphSpeed: morphSpeed,
        reduceMotionAtPush: reduceMotion,
        barrierDismissible: barrierDismissible,
        barrierColorValue: barrierColor,
        barrierLabelValue: localizations.modalBarrierDismissLabel,
        capturedThemes: capturedThemes,
        title: title,
        message: message,
        actions: actions,
        cancelLabel: effectiveCancelLabel,
        showCancelButton: effectiveShowCancel,
        maxWidth: maxWidth,
        glassSettings: settings,
        quality: quality,
        platformViewBackdrop: platformViewBackdrop,
        shape: shape,
        actionShape: actionShape,
        actionTextStyle: actionTextStyle,
      ),
    );
  }

  // Unanchored: calibrated 320 pt centered platter with Cancel by default.
  final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
  final resolvedBarrierColor = barrierColor != null
      ? CupertinoDynamicColor.resolve(barrierColor, context)
      : glassAlertBarrierColor(isDark: isDark);

  return pushGlassAlertRoute<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierColor: resolvedBarrierColor,
    builder: (modalContext) {
      final route = ModalRoute.of(modalContext);
      void dismissIfActive() {
        if (route != null && route.isCurrent && route.isActive) {
          Navigator.of(modalContext).pop();
        }
      }

      return capturedThemes.wrap(
        GlassAlertPlatter(
          title: title,
          message: message,
          settings: settings,
          quality: quality,
          maxWidth: maxWidth,
          forceStacked: true,
          semanticsRole: SemanticsRole.dialog,
          shape: shape,
          actionShape: actionShape,
          actionTextStyle: actionTextStyle,
          actions: _buildPlatterActions(
            actions: actions,
            showCancelButton: effectiveShowCancel,
            cancelLabel: effectiveCancelLabel,
            dismissIfActive: dismissIfActive,
          ),
        ),
      );
    },
  );
}

List<GlassAlertPlatterAction> _buildPlatterActions({
  required List<GlassConfirmationDialogAction> actions,
  required bool showCancelButton,
  required String cancelLabel,
  required VoidCallback dismissIfActive,
}) {
  return [
    for (final action in actions)
      GlassAlertPlatterAction(
        label: action.label,
        icon: action.icon,
        isDestructive: action.isDestructive,
        isPrimary: action.isPrimary,
        tintColor: action.tintColor,
        foregroundColor: action.foregroundColor,
        onPressed: action.onPressed == null
            ? null
            : () {
                action.onPressed!();
                if (action.dismissOnPress) {
                  dismissIfActive();
                }
              },
      ),
    if (showCancelButton)
      GlassAlertPlatterAction(
        label: cancelLabel,
        onPressed: dismissIfActive,
      ),
  ];
}

// =============================================================================
// Source-anchored Liquid Glass confirmation dialog route & morph presenter
// =============================================================================

/// Native screen-edge margin for anchored confirmation dialog popovers
/// (measured on iOS 27.2: 240 pt platter at x = 152 on 402 pt display → 10 pt).
const double _kAnchoredScreenPadding = 10.0;

/// Extracts a scalar corner radius from a custom [LiquidShape] for morph
/// corner interpolation, falling back to [kGlassAlertPlatterCornerRadius].
double _resolveTargetCornerRadius(LiquidShape? shape) {
  if (shape is LiquidRoundedSuperellipse) return shape.borderRadius;
  if (shape is LiquidRoundedRectangle) return shape.borderRadius;
  return kGlassAlertPlatterCornerRadius;
}

class _GlassConfirmationPopoverRoute<T> extends PopupRoute<T> {
  _GlassConfirmationPopoverRoute({
    required this.triggerRect,
    required this.anchor,
    required this.alignment,
    required this.morphSpeed,
    required this.reduceMotionAtPush,
    required this.barrierDismissible,
    required this.barrierColorValue,
    required this.barrierLabelValue,
    required this.capturedThemes,
    required this.title,
    required this.message,
    required this.actions,
    required this.cancelLabel,
    required this.showCancelButton,
    required this.maxWidth,
    required this.glassSettings,
    required this.quality,
    required this.platformViewBackdrop,
    required this.shape,
    required this.actionShape,
    required this.actionTextStyle,
  });

  final Rect triggerRect;
  final GlassMorphAnchor? anchor;
  final GlassMenuAlignment? alignment;
  final MorphSpeed morphSpeed;
  final bool reduceMotionAtPush;
  @override
  final bool barrierDismissible;
  final Color? barrierColorValue;
  final String barrierLabelValue;
  final CapturedModalThemes capturedThemes;
  final String? title;
  final String? message;
  final List<GlassConfirmationDialogAction> actions;
  final String cancelLabel;
  final bool showCancelButton;
  final double? maxWidth;
  final LiquidGlassSettings? glassSettings;
  final GlassQuality? quality;
  final bool platformViewBackdrop;
  final LiquidShape? shape;
  final LiquidShape? actionShape;
  final TextStyle? actionTextStyle;

  double get _speedMultiplier => switch (morphSpeed) {
        MorphSpeed.slow => 0.65,
        MorphSpeed.normal => 1.0,
        MorphSpeed.fast => 1.35,
        MorphSpeed.instant => 2.5,
      };

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => barrierLabelValue;

  @override
  Duration get transitionDuration => reduceMotionAtPush
      ? Duration.zero
      : Duration(milliseconds: (360 / _speedMultiplier).round());

  @override
  Duration get reverseTransitionDuration => reduceMotionAtPush
      ? Duration.zero
      : Duration(milliseconds: (300 / _speedMultiplier).round());

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    void dismissIfActive() {
      if (isCurrent && isActive) {
        navigator?.pop();
      }
    }

    return capturedThemes.wrap(
      _GlassConfirmationMorphPresenter(
        routeAnimation: animation,
        triggerRect: triggerRect,
        anchor: anchor,
        alignment: alignment,
        morphSpeed: morphSpeed,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColorValue,
        barrierLabel: barrierLabelValue,
        onBarrierDismiss: dismissIfActive,
        title: title,
        message: message,
        actions: _buildPlatterActions(
          actions: actions,
          showCancelButton: showCancelButton,
          cancelLabel: cancelLabel,
          dismissIfActive: dismissIfActive,
        ),
        maxWidth: maxWidth,
        glassSettings: glassSettings,
        quality: quality,
        platformViewBackdrop: platformViewBackdrop,
        shape: shape,
        actionShape: actionShape,
        actionTextStyle: actionTextStyle,
      ),
    );
  }
}

class _GlassConfirmationMorphPresenter extends StatefulWidget {
  const _GlassConfirmationMorphPresenter({
    required this.routeAnimation,
    required this.triggerRect,
    required this.anchor,
    required this.alignment,
    required this.morphSpeed,
    required this.barrierDismissible,
    required this.barrierColor,
    required this.barrierLabel,
    required this.onBarrierDismiss,
    required this.title,
    required this.message,
    required this.actions,
    required this.maxWidth,
    required this.glassSettings,
    required this.quality,
    required this.platformViewBackdrop,
    required this.shape,
    required this.actionShape,
    required this.actionTextStyle,
  });

  final Animation<double> routeAnimation;
  final Rect triggerRect;
  final GlassMorphAnchor? anchor;
  final GlassMenuAlignment? alignment;
  final MorphSpeed morphSpeed;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String barrierLabel;
  final VoidCallback onBarrierDismiss;
  final String? title;
  final String? message;
  final List<GlassAlertPlatterAction> actions;
  final double? maxWidth;
  final LiquidGlassSettings? glassSettings;
  final GlassQuality? quality;
  final bool platformViewBackdrop;
  final LiquidShape? shape;
  final LiquidShape? actionShape;
  final TextStyle? actionTextStyle;

  @override
  State<_GlassConfirmationMorphPresenter> createState() =>
      _GlassConfirmationMorphPresenterState();
}

class _GlassConfirmationMorphPresenterState
    extends State<_GlassConfirmationMorphPresenter>
    with TickerProviderStateMixin {
  late final GlassMorphController _morph;
  final GlobalKey _contentKey = GlobalKey();

  bool _opened = false;
  bool _triggerHidden = false;
  bool _contentMeasured = false;
  bool _isClosing = false;
  bool _handedBackToTrigger = false;
  double _measuredWidth = 0.0;
  double _measuredHeight = 0.0;
  double _closeStartWidthProgress = 0.0;

  Rect _localTriggerRect = Rect.zero;
  Alignment _morphAlignment = Alignment.topRight;
  Rect _restingRect = Rect.zero;
  Offset _travelDelta = Offset.zero;

  @override
  void initState() {
    super.initState();
    _morph = GlassMorphController(
      vsync: this,
      speed: widget.morphSpeed,
    )..verticalOnlyRecoil = true;
    // Listen solely for the close-handoff latch — per-frame repainting is
    // driven by AnimatedBuilder so cardBody and theme/MediaQuery lookups never
    // rebuild at 120 Hz.
    _morph.addListener(_syncTriggerHandBack);
    widget.routeAnimation.addStatusListener(_onRouteStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _morph
        .setDisableAnimations(GlassAccessibilityData.of(context).reduceMotion);
    if (!_opened) {
      _opened = true;
      if (widget.anchor != null) {
        morphAnchorEmpty(widget.anchor!);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _measureAndOpen();
      });
    }
  }

  @override
  void dispose() {
    widget.routeAnimation.removeStatusListener(_onRouteStatus);
    _morph.removeListener(_syncTriggerHandBack);
    _morph.dispose();
    // Safety net: restore the trigger if the route was torn down abruptly
    // without running the closing morph.
    if (widget.anchor != null) {
      morphAnchorRestore(widget.anchor!);
    }
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.reverse || _isClosing) return;
    _isClosing = true;
    if (!_contentMeasured || _morph.disableAnimations) {
      _handBackImmediately();
    }
    _closeStartWidthProgress =
        _morph.computeState(finalDx: 0.0, finalDy: 0.0).triggerWidthProgress;
    _morph.close();
  }

  void _handBackImmediately() {
    final anchor = widget.anchor;
    if (anchor == null || _handedBackToTrigger) return;
    _handedBackToTrigger = true;
    morphAnchorRestore(anchor);
  }

  void _syncTriggerHandBack() {
    final anchor = widget.anchor;
    if (anchor == null || !_isClosing || _handedBackToTrigger) return;
    if (!_morph.hasHandedOff) return;
    _handedBackToTrigger = true;
    morphAnchorHandBack(
      anchor,
      travel: _travelDelta,
      elapsedSeconds: _morph.phaseElapsedSeconds,
      speedMultiplier: _morph.speedMultiplier,
      startWidthProgress: _closeStartWidthProgress,
      disableAnimations: _morph.disableAnimations,
    );
  }

  double _effectivePlatterWidth(Size screenSize, EdgeInsets padding) {
    final availableWidth = math.max(
      120.0,
      screenSize.width -
          padding.left -
          padding.right -
          _kAnchoredScreenPadding * 2,
    );
    final requested = widget.maxWidth ?? kGlassConfirmationPopoverWidth;
    return math.min(requested, availableWidth);
  }

  double _maxAvailableHeight(Size screenSize, EdgeInsets padding) {
    final topEdge = math.max(padding.top, _kAnchoredScreenPadding);
    return math.max(
      120.0,
      screenSize.height - topEdge - padding.bottom - _kAnchoredScreenPadding,
    );
  }

  void _measureAndOpen() {
    if (!mounted || _contentMeasured) return;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final selfBox = context.findRenderObject() as RenderBox?;
    final localTopLeft = selfBox != null && selfBox.hasSize
        ? selfBox.globalToLocal(widget.triggerRect.topLeft)
        : widget.triggerRect.topLeft;
    _localTriggerRect = localTopLeft & widget.triggerRect.size;

    final screenSize = selfBox != null && selfBox.hasSize
        ? selfBox.size
        : MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final width = _effectivePlatterWidth(screenSize, padding);
    final maxHeight = _maxAvailableHeight(screenSize, padding);
    final height = math.min(box.size.height, maxHeight);

    _computeRestingGeometry(
      screenSize: screenSize,
      safePadding: padding,
      platterWidth: width,
      platterHeight: height,
    );

    setState(() {
      _measuredWidth = width;
      _measuredHeight = height;
      _triggerHidden = true;
      _contentMeasured = true;
    });

    if (!_isClosing) {
      _morph.open();
    }
  }

  Alignment? _resolveExplicitAlignment(GlassMenuAlignment? align) {
    if (align == null) return null;
    switch (align) {
      case GlassMenuAlignment.none:
        return null;
      case GlassMenuAlignment.topLeft:
        return Alignment.topLeft;
      case GlassMenuAlignment.topCenter:
        return Alignment.topCenter;
      case GlassMenuAlignment.topRight:
        return Alignment.topRight;
      case GlassMenuAlignment.centerLeft:
        return Alignment.centerLeft;
      case GlassMenuAlignment.center:
        return Alignment.center;
      case GlassMenuAlignment.centerRight:
        return Alignment.centerRight;
      case GlassMenuAlignment.bottomLeft:
        return Alignment.bottomLeft;
      case GlassMenuAlignment.bottomCenter:
        return Alignment.bottomCenter;
      case GlassMenuAlignment.bottomRight:
        return Alignment.bottomRight;
    }
  }

  void _computeRestingGeometry({
    required Size screenSize,
    required EdgeInsets safePadding,
    required double platterWidth,
    required double platterHeight,
  }) {
    final trigger = _localTriggerRect;
    final explicit = _resolveExplicitAlignment(widget.alignment);

    if (explicit != null) {
      _morphAlignment = explicit;
    } else {
      final safeTop = math.max(safePadding.top, _kAnchoredScreenPadding);
      final safeBottom =
          screenSize.height - safePadding.bottom - _kAnchoredScreenPadding;
      final spaceBelow = safeBottom - trigger.top;
      final spaceAbove = trigger.bottom - safeTop;
      final flipUpward = spaceBelow < platterHeight && spaceAbove > spaceBelow;

      final isCenteredX = (trigger.center.dx - screenSize.width * 0.5).abs() <=
          math.max(24.0, screenSize.width * 0.08);
      final isRightHalf = trigger.center.dx > screenSize.width * 0.5;

      if (isCenteredX) {
        _morphAlignment =
            flipUpward ? Alignment.bottomCenter : Alignment.topCenter;
      } else {
        _morphAlignment = flipUpward
            ? (isRightHalf ? Alignment.bottomRight : Alignment.bottomLeft)
            : (isRightHalf ? Alignment.topRight : Alignment.topLeft);
      }
    }

    final anchorAlignX = (1.0 + _morphAlignment.x) * 0.5;
    final anchorAlignY = (1.0 + _morphAlignment.y) * 0.5;

    final rawLeft =
        trigger.left + anchorAlignX * (trigger.width - platterWidth);
    final rawTop =
        trigger.top + anchorAlignY * (trigger.height - platterHeight);

    _restingRect = _clampRectToViewport(
      rawLeft: rawLeft,
      rawTop: rawTop,
      platterWidth: platterWidth,
      platterHeight: platterHeight,
      screenSize: screenSize,
      safePadding: safePadding,
      viewInsets: EdgeInsets.zero,
    );
    _travelDelta = _restingRect.center - trigger.center;
  }

  Rect _clampRectToViewport({
    required double rawLeft,
    required double rawTop,
    required double platterWidth,
    required double platterHeight,
    required Size screenSize,
    required EdgeInsets safePadding,
    required EdgeInsets viewInsets,
  }) {
    final effectiveBottomInset =
        math.max(safePadding.bottom, viewInsets.bottom);
    final minLeft = safePadding.left + _kAnchoredScreenPadding;
    final maxLeft = math.max(
      minLeft,
      screenSize.width -
          safePadding.right -
          _kAnchoredScreenPadding -
          platterWidth,
    );
    final minTop = math.max(safePadding.top, _kAnchoredScreenPadding);
    final maxTop = math.max(
      minTop,
      screenSize.height -
          effectiveBottomInset -
          _kAnchoredScreenPadding -
          platterHeight,
    );
    return Rect.fromLTWH(
      rawLeft.clamp(minLeft, maxLeft),
      rawTop.clamp(minTop, maxTop),
      platterWidth,
      platterHeight,
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return GlassAlertPlatterCard(
      title: widget.title,
      message: widget.message,
      actions: widget.actions,
      settings: widget.glassSettings,
      quality: widget.quality,
      forceStacked: true,
      shape: widget.shape,
      actionShape: widget.actionShape,
      actionTextStyle: widget.actionTextStyle,
      wrapInGlassContainer: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return wrapGlassAlertSyncedBrightness(
      context,
      builder: _buildSynced,
    );
  }

  Widget _buildSynced(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final platterWidth = _effectivePlatterWidth(screenSize, safePadding);
    final maxHeight = _maxAvailableHeight(screenSize, safePadding);

    final primaryActions = [
      for (final action in widget.actions)
        if (action.isPrimary) action,
    ];
    final hasSinglePrimary = primaryActions.length == 1;
    final primaryCallback =
        hasSinglePrimary ? primaryActions.single.onPressed : null;

    final cardBody = DefaultTextStyle(
      style: CupertinoTheme.of(context).textTheme.textStyle,
      child: _buildCardContent(context),
    );

    // Phase 1: Offstage measurement pass before launching the morph spring.
    if (!_contentMeasured) {
      return Stack(
        children: [
          Offstage(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: platterWidth,
                  maxWidth: platterWidth,
                  maxHeight: maxHeight,
                ),
                child: KeyedSubtree(
                  key: _contentKey,
                  child: cardBody,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Re-clamp both axes & dimensions live on rotation, window resize, or
    // keyboard appearance so the platter can never be stranded off-screen.
    final liveWidth = platterWidth;
    final liveHeight = math.min(_measuredHeight, maxHeight);
    if ((liveWidth - _measuredWidth).abs() > 0.5) {
      _measuredWidth = liveWidth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_contentMeasured) return;
        final box =
            _contentKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final updated = math.min(box.size.height, maxHeight);
          if ((updated - _measuredHeight).abs() > 0.5) {
            setState(() => _measuredHeight = updated);
          }
        }
      });
    }
    final restingRect = _clampRectToViewport(
      rawLeft: _restingRect.left,
      rawTop: _restingRect.top,
      platterWidth: liveWidth,
      platterHeight: liveHeight,
      screenSize: screenSize,
      safePadding: safePadding,
      viewInsets: viewInsets,
    );

    // Hoist all InheritedWidget lookups outside AnimatedBuilder so they are
    // never repeated on every 120 Hz animation tick.
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
      fallback: GlassThemeHelpers.nativeStyleQuality(context),
    );
    final platterSettings = resolveGlassAlertPlatterSettings(
      context,
      explicit: widget.glassSettings,
      effectiveQuality: effectiveQuality,
    );
    final isPremium = !widget.platformViewBackdrop &&
        effectiveQuality == GlassQuality.premium &&
        ImageFilter.isShaderFilterSupported;
    final bool useBlendGroup = effectiveQuality == GlassQuality.premium &&
        !widget.platformViewBackdrop;
    final bool reduceTransparency =
        GlassAccessibilityData.of(context).reduceTransparency;
    final bool usesLightweightGlass =
        effectiveQuality != GlassQuality.minimal &&
            !widget.platformViewBackdrop &&
            !reduceTransparency &&
            !isPremium;
    final outerScope = GlassMaterializeScope.maybeOf(context);
    final resolvedBarrierColor = widget.barrierColor != null
        ? CupertinoDynamicColor.resolve(widget.barrierColor!, context)
        : const Color(0x00000000);
    final dialogSemanticLabel =
        glassCupertinoLocalizationsOf(context).alertDialogLabel;

    final tw = _localTriggerRect.width;
    final th = _localTriggerRect.height;
    final compactCore = math.min(tw, th);
    final triggerCenter = _localTriggerRect.center;
    final travelDx = restingRect.center.dx - triggerCenter.dx;
    final travelDy = restingRect.center.dy - triggerCenter.dy;
    _travelDelta = Offset(travelDx, travelDy);
    final targetRadius = _resolveTargetCornerRadius(widget.shape);
    final triggerRadius = compactCore * 0.5;
    final scaleDelta = LiquidMorphPhysics.computeScaleDelta(
      sourceSize: Size(math.max(1.0, compactCore), math.max(1.0, compactCore)),
      targetSize: Size(restingRect.width, math.max(1.0, restingRect.height)),
    );
    final contentAlignX = restingRect.width > 0
        ? (((triggerCenter.dx - restingRect.left) / restingRect.width) * 2.0 -
                1.0)
            .clamp(-1.0, 1.0)
        : _morphAlignment.x;
    final contentAlignY = restingRect.height > 0
        ? (((triggerCenter.dy - restingRect.top) / restingRect.height) * 2.0 -
                1.0)
            .clamp(-1.0, 1.0)
        : _morphAlignment.y;
    final contentAnchor = Alignment(contentAlignX, contentAlignY);

    final Widget stableCard = ConstrainedBox(
      key: _contentKey,
      constraints: BoxConstraints(
        minWidth: restingRect.width,
        maxWidth: restingRect.width,
        maxHeight: maxHeight,
      ),
      child: cardBody,
    );

    return GlassDialogDefaultActionScope(
      hasPrimaryAction: hasSinglePrimary,
      onActivatePrimary: primaryCallback,
      child: AnimatedBuilder(
        animation: _morph,
        child: stableCard,
        builder: (context, hoistedCard) {
          final state = _morph.computeState(
            finalDx: travelDx,
            finalDy: travelDy,
            scaleDelta: scaleDelta,
            adaptiveDamping: true,
          );

          final rawValue = _morph.value;
          final clampedValue = rawValue.clamp(0.0, 1.0);
          final bool showPlatter = !_morph.isClosing || state.isPlatterActive;
          final bool isSettled = !_morph.isClosing &&
              (_morph.disableAnimations ||
                  (!_morph.animation.isAnimating && clampedValue >= 0.95));

          late final Rect currentRect;
          late final double currentRadius;
          double blobADriftX = 0.0;
          double blobADriftY = 0.0;

          if (isSettled) {
            currentRect = restingRect;
            currentRadius = targetRadius;
          } else if (_morph.isClosing && isPremium) {
            final closedGeo = LiquidMorphPhysics.computeClosingTeardropGeometry(
              rawValue: rawValue,
              pathT: state.pathT,
              triggerCenter: triggerCenter,
              triggerSize: Size(tw, th),
              restingRect: restingRect,
              targetRadius: targetRadius,
              effectivePush: Offset(state.triggerPushDx, state.triggerPushDy),
              elapsedSeconds: _morph.phaseElapsedSeconds,
              closeStartProgress: _morph.closeStartProgress,
              alignX: _morphAlignment.x,
              disableAnimations: _morph.disableAnimations,
            );
            currentRect = closedGeo.rect;
            currentRadius = closedGeo.borderRadius;
          } else if (_morph.isClosing) {
            final sizeProgress =
                ((state.pathT + state.sizeT) * 0.5).clamp(0.0, 1.0);
            final w = math.max(
              1.0,
              lerpDouble(compactCore, restingRect.width, sizeProgress)!,
            );
            final h = math.max(
              1.0,
              lerpDouble(compactCore, restingRect.height, sizeProgress)!,
            );
            final closePathT = state.pathT.clamp(0.0, 1.0);
            final recoilCatch = 1.0 - clampedValue;
            final cx = triggerCenter.dx +
                travelDx * closePathT +
                state.triggerPushDx * recoilCatch;
            final cy = triggerCenter.dy +
                travelDy * closePathT +
                state.triggerPushDy * recoilCatch;
            currentRect =
                Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
            currentRadius = LiquidMorphPhysics.computeCornerRadius(
              currentSize: Size(w, h),
              triggerRadius: triggerRadius,
              targetRadius: targetRadius,
              progress: sizeProgress,
            );
          } else {
            final sizeProgress = state.sizeT.clamp(0.0, 1.25);
            final w = math.max(
              1.0,
              lerpDouble(compactCore, restingRect.width, sizeProgress)!,
            );
            final h = math.max(
              1.0,
              lerpDouble(compactCore, restingRect.height, sizeProgress)!,
            );
            final detachRelease = 1.0 - state.anchorScale * 0.55;
            final effectivePathT =
                state.sizeT + (state.pathT - state.sizeT) * detachRelease;
            final left = triggerCenter.dx + travelDx * effectivePathT - w * 0.5;
            final top = triggerCenter.dy + travelDy * effectivePathT - h * 0.5;
            blobADriftX = travelDx *
                (state.pathT - state.sizeT) *
                (1.0 - state.anchorScale) *
                0.35;
            blobADriftY = travelDy *
                (state.pathT - state.sizeT) *
                (1.0 - state.anchorScale) *
                0.35;
            currentRect = Rect.fromLTWH(left, top, w, h);
            currentRadius = LiquidMorphPhysics.computeCornerRadius(
              currentSize: Size(w, h),
              triggerRadius: triggerRadius,
              targetRadius: targetRadius,
              progress: sizeProgress.clamp(0.0, 1.0),
            );
          }

          // Trigger anchor blob (Blob A) — only drawn when morphFrom emptied
          // the real trigger, so morphFromRect never duplicates an unhidden
          // button.
          final bool hasAnchor = widget.anchor != null && _triggerHidden;
          final bool isWideTrigger = tw > th * 1.15;
          final double blobAWidth = math.max(
            1.0,
            compactCore + (tw - compactCore) * state.triggerWidthProgress,
          );
          final double blobAHeight = isWideTrigger
              ? math.max(1.0, th)
              : math.max(
                  1.0,
                  compactCore + (th - compactCore) * state.triggerWidthProgress,
                );
          final double blobARadius = math.min(
            triggerRadius,
            math.min(blobAWidth, blobAHeight) * 0.5,
          );

          final bool showBlobA;
          final double blobAScale;
          if (!hasAnchor || _morph.disableAnimations) {
            showBlobA = false;
            blobAScale = 0.0;
          } else if (_morph.isClosing) {
            if (!isPremium || !state.isPlatterActive) {
              showBlobA = false;
              blobAScale = 0.0;
            } else if (isWideTrigger) {
              showBlobA = true;
              blobAScale = state.triggerImpactScale;
            } else {
              final closeBlobAGrow =
                  LiquidMorphPhysics.computeCloseBlobAEmergence(
                platterRect: currentRect,
                platterRadius: currentRadius,
                triggerCenter: Offset(
                  triggerCenter.dx + state.triggerPushDx,
                  triggerCenter.dy + state.triggerPushDy,
                ),
                rawValue: rawValue,
              );
              showBlobA = closeBlobAGrow > 0.001;
              blobAScale = closeBlobAGrow * state.triggerImpactScale;
            }
          } else {
            final openAnchorScale = isWideTrigger
                ? (1.0 - ((clampedValue - 0.25) / 0.35).clamp(0.0, 1.0))
                : state.anchorScale;
            showBlobA = openAnchorScale > 0.20;
            blobAScale = openAnchorScale * state.triggerImpactScale;
          }

          final double layerBlend = (_morph.isClosing && showBlobA)
              ? LiquidMorphPhysics.computeCloseBlend(rawValue: rawValue)
              : state.blend;

          final double platterGlassOpacity = _morph.disableAnimations
              ? 1.0
              : (_morph.isClosing ? state.platterOpacity.clamp(0.0, 1.0) : 1.0);
          final double rawContentOpacity = _morph.disableAnimations
              ? 1.0
              : (_morph.isClosing
                  ? state.contentOpacity
                  : ((state.sizeT - 0.22) / 0.63).clamp(0.0, 1.0));
          final double effectiveContentOpacity = usesLightweightGlass
              ? (platterGlassOpacity > 1e-4
                  ? (rawContentOpacity / platterGlassOpacity).clamp(0.0, 1.0)
                  : 0.0)
              : rawContentOpacity;

          final double contentScale = restingRect.width > 0
              ? (currentRect.width / restingRect.width).clamp(0.20, 1.2)
              : 1.0;

          final LiquidShape activeShape = widget.shape != null && isSettled
              ? widget.shape!
              : LiquidRoundedSuperellipse(borderRadius: currentRadius);

          final double barrierAlphaFactor =
              _morph.disableAnimations ? 1.0 : clampedValue;
          final Color effectiveBarrierColor = resolvedBarrierColor.withValues(
            alpha:
                (resolvedBarrierColor.a * barrierAlphaFactor).clamp(0.0, 1.0),
          );

          // Settled platter renders hoistedCard directly with zero Opacity,
          // Transform.scale, OverflowBox, or ImageFiltered overhead.
          final Widget platterChild;
          if (isSettled) {
            platterChild = hoistedCard!;
          } else {
            Widget animatedContent = hoistedCard!;
            if (!_morph.disableAnimations && state.contentBlurSigma >= 0.05) {
              animatedContent = ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: state.contentBlurSigma,
                  sigmaY: state.contentBlurSigma,
                  tileMode: TileMode.decal,
                ),
                child: animatedContent,
              );
            }
            if ((contentScale - 1.0).abs() >= 0.001) {
              animatedContent = Transform.scale(
                scale: contentScale,
                alignment: contentAnchor,
                child: animatedContent,
              );
            }
            if (effectiveContentOpacity < 0.999) {
              animatedContent = Opacity(
                opacity: effectiveContentOpacity,
                child: animatedContent,
              );
            }

            final Widget clippedStack = Stack(
              alignment: contentAnchor,
              clipBehavior: Clip.none,
              children: [
                if (rawContentOpacity > 0.01)
                  OverflowBox(
                    alignment: contentAnchor,
                    minWidth: restingRect.width,
                    maxWidth: restingRect.width,
                    minHeight: restingRect.height,
                    maxHeight: restingRect.height,
                    child: animatedContent,
                  ),
              ],
            );

            platterChild = (!_morph.disableAnimations &&
                    (state.containerScale - 1.0).abs() >= 0.001)
                ? Transform.scale(
                    scale: state.containerScale,
                    alignment: Alignment.center,
                    child: clippedStack,
                  )
                : clippedStack;
          }

          final Widget platterWidget = GlassMaterializeScope(
            glassProgress:
                platterGlassOpacity * (outerScope?.glassProgress ?? 1.0),
            contentOpacity: outerScope?.contentOpacity ?? 1.0,
            contentSigma: outerScope?.contentSigma ?? 0.0,
            child: GlassContainer(
              useOwnLayer: false,
              settings: platterSettings,
              quality: effectiveQuality,
              platformViewBackdrop: widget.platformViewBackdrop,
              allowElevation: false,
              width: currentRect.width,
              height: currentRect.height,
              shape: activeShape,
              clipBehavior: Clip.antiAlias,
              child: platterChild,
            ),
          );

          return Stack(
            children: [
              // Tap-to-dismiss or blocking modal barrier
              Positioned.fill(
                child: BlockSemantics(
                  child: Semantics(
                    container: true,
                    label:
                        widget.barrierDismissible ? widget.barrierLabel : null,
                    onDismiss: widget.barrierDismissible
                        ? widget.onBarrierDismiss
                        : null,
                    onTap: widget.barrierDismissible
                        ? widget.onBarrierDismiss
                        : null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onTap: widget.barrierDismissible && !_isClosing
                          ? widget.onBarrierDismiss
                          : null,
                      child: ColoredBox(color: effectiveBarrierColor),
                    ),
                  ),
                ),
              ),

              // Morphing Liquid Glass platter (+ optional trigger Blob A)
              if (showPlatter)
                Positioned.fill(
                  child: AdaptiveLiquidGlassLayer(
                    settings: platterSettings,
                    quality: effectiveQuality,
                    blendAmount: layerBlend,
                    platformViewBackdrop: widget.platformViewBackdrop,
                    child: Builder(
                      builder: (layerContext) {
                        final blobStack = Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (showBlobA)
                              Positioned(
                                left: triggerCenter.dx -
                                    blobAWidth * 0.5 +
                                    blobADriftX +
                                    state.triggerPushDx,
                                top: triggerCenter.dy -
                                    blobAHeight * 0.5 +
                                    blobADriftY +
                                    state.triggerPushDy,
                                child: Transform.scale(
                                  scale: blobAScale,
                                  alignment: Alignment.center,
                                  child: GlassContainer(
                                    useOwnLayer: false,
                                    settings: platterSettings,
                                    quality: effectiveQuality,
                                    platformViewBackdrop:
                                        widget.platformViewBackdrop,
                                    width: blobAWidth,
                                    height: blobAHeight,
                                    shape: LiquidRoundedSuperellipse(
                                      borderRadius: blobARadius,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: currentRect.left,
                              top: currentRect.top,
                              child: Semantics(
                                role: SemanticsRole.dialog,
                                scopesRoute: true,
                                namesRoute: true,
                                explicitChildNodes: true,
                                label: dialogSemanticLabel,
                                child: IgnorePointer(
                                  ignoring: (!_morph.disableAnimations &&
                                          clampedValue < 0.8) ||
                                      _isClosing,
                                  child: platterWidget,
                                ),
                              ),
                            ),
                          ],
                        );

                        final needsInnerBlendGroup = useBlendGroup &&
                            LiquidGlassBlendGroup.maybeOf(layerContext) == null;
                        return needsInnerBlendGroup
                            ? LiquidGlassBlendGroup(
                                blend: layerBlend,
                                child: blobStack,
                              )
                            : blobStack;
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
