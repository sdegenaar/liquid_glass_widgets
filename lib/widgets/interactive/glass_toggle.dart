import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../theme/glass_theme.dart';
import '../../types/glass_button_style.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../shared/glass_solid_surface.dart';
import 'glass_button.dart';

/// A Liquid Glass toggle button mirroring SwiftUI's `Toggle(...).toggleStyle(.button)`.
///
/// [GlassToggle.button] is a pressed/unpressed capsule toggle control that
/// transitions between standard refractive glass ([GlassButtonStyle.filled])
/// when off and accent-tinted prominent glass ([GlassButtonStyle.prominent])
/// when on — matching native iOS 26/27 `.toggleStyle(.button).buttonStyle(.glass)`.
///
/// It is the native SwiftUI primitive superseding Material-style chips and
/// horizontal filter strips: compose multiple [GlassToggle.button] widgets in a
/// `Wrap` or horizontal `SingleChildScrollView` / `ListView` for filter bars,
/// formatting toolbars, and multi-select option rows.
///
/// ## Visual Behavior (iOS 26 / iOS 27 Calibrated)
///
/// - **Off (`value: false`)**:
///   - In [GlassSurfaceStyle.glass] mode: clear refractive Liquid Glass pill
///     with [CupertinoColors.label] foreground.
///   - In [GlassSurfaceStyle.solid] mode (explicit or inherited via
///     [InheritedGlassSurfaceStyle]): recessed iOS `tertiarySystemFill` pill
///     well ([resolveGlassSolidWellColor]) or explicit [color] with
///     [CupertinoColors.label] (or luminance-contrasted) foreground.
/// - **On (`value: true`)**:
///   - In [GlassSurfaceStyle.glass] mode: prominent tinted Liquid Glass
///     ([GlassButtonStyle.prominent] + [activeColor], defaulting to
///     `CupertinoTheme.of(context).primaryColor`) with automatic
///     luminance-contrasted white/black foreground.
///   - In [GlassSurfaceStyle.solid] mode: opaque solid [activeColor] pill with
///     automatic luminance-contrasted foreground and zero shader cost.
/// - **Disabled (`onChanged: null`)**: renders at 50% opacity, ignores touch
///   and keyboard input without press stretch/glow, and reports disabled +
///   toggled semantics on a single accessibility node.
///
/// ## Accessibility
///
/// - The toggle reads as a switch that is on or off on iOS, macOS and
///   Android. For one option of a set where exactly one is chosen, such as a
///   choice chip, set [semanticsInMutuallyExclusiveGroup]: it then reads as
///   a radio button, checked or not.
/// - Its semantics node is at least 44 x 44 pt, centred on the capsule,
///   without changing its layout; the touch area extends that far only
///   within the parent's bounds.
/// - A [label] that does not fit wraps onto more lines, as at large text
///   sizes, unless [height] fixes the toggle's height.
///
/// ## Usage
///
/// ### Text & Icon Filter Toggle
/// ```dart
/// GlassToggle.button(
///   value: isStarred,
///   onChanged: (next) => setState(() => isStarred = next),
///   icon: Icon(isStarred ? CupertinoIcons.star_fill : CupertinoIcons.star),
///   label: 'Starred',
/// )
/// ```
///
/// ### Icon-Only Toggle
/// ```dart
/// GlassToggle.button(
///   value: isMuted,
///   onChanged: (next) => setState(() => isMuted = next),
///   icon: Icon(isMuted ? CupertinoIcons.speaker_slash_fill : CupertinoIcons.speaker_2),
///   semanticLabel: 'Mute',
/// )
/// ```
///
/// ### Custom Tint & Solid Surface
/// ```dart
/// GlassToggle.button(
///   value: isFilterActive,
///   onChanged: (next) => setState(() => isFilterActive = next),
///   label: 'Unread',
///   activeColor: CupertinoColors.systemOrange,
///   surfaceStyle: GlassSurfaceStyle.solid,
/// )
/// ```
class GlassToggle extends StatelessWidget {
  /// Creates a capsule toggle button matching SwiftUI `Toggle(.button)`.
  ///
  /// At least one of [label], [icon], or [child] must be provided. [child]
  /// cannot be combined with [label] or [icon].
  const GlassToggle.button({
    required this.value,
    required this.onChanged,
    super.key,
    this.label,
    this.icon,
    this.child,
    this.activeColor,
    this.foregroundColor,
    this.activeForegroundColor,
    this.labelStyle,
    this.iconSize = 17.0,
    this.spacing = 6.0,
    this.padding,
    this.minHeight = 34.0,
    this.width,
    this.height,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 100),
    this.surfaceStyle,
    this.color,
    this.settings,
    this.useOwnLayer = false,
    this.quality,
    this.platformViewBackdrop = false,
    this.enableHaptics = true,
    this.interactionScale,
    this.stretch = 0.3,
    this.glowRadius,
    this.anchorStretch = true,
    this.anchorStretchSettings,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.semanticLabel,
    this.semanticsInMutuallyExclusiveGroup = false,
    this.textDirection,
  })  : assert(
          child != null || label != null || icon != null,
          'GlassToggle.button requires at least one of label, icon, or child.',
        ),
        assert(
          child == null || (label == null && icon == null),
          'GlassToggle.button cannot combine child with label or icon.',
        );

  // ===========================================================================
  // Toggle State & Callbacks
  // ===========================================================================

  /// Whether the toggle button is currently on (`true`) or off (`false`).
  final bool value;

  /// Called with the toggled boolean value (`!value`) when the user activates
  /// the button via touch, keyboard (Space/Enter), or assistive technology.
  ///
  /// If `null`, the toggle button is disabled.
  final ValueChanged<bool>? onChanged;

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// Optional text label displayed inside the capsule.
  ///
  /// Mutually exclusive with [child]. Can be paired with [icon]. A label
  /// wider than the space the toggle gets wraps onto more lines, as at
  /// large text sizes, and the capsule grows to fit; with an explicit
  /// [height] it stays on one line and ends in an ellipsis.
  final String? label;

  /// The direction of [label], such as [TextDirection.rtl] for a name the
  /// user typed in Arabic or Hebrew in a left-to-right app.
  ///
  /// When `null` (the default), the label takes the ambient
  /// [Directionality]. The icon and the padding keep following the ambient
  /// direction. Screen readers get the label with this direction, unless
  /// [semanticLabel] names the toggle.
  final TextDirection? textDirection;

  /// Optional leading icon widget (or standalone icon when [label] is null).
  ///
  /// Standard [Icon] widgets inherit [iconSize] and the resolved foreground
  /// color via [IconTheme]. Mutually exclusive with [child].
  final Widget? icon;

  /// Optional custom content widget replacing [label] and [icon].
  ///
  /// Receives the resolved foreground color via [DefaultTextStyle] and
  /// [IconTheme]. Mutually exclusive with [label] and [icon].
  final Widget? child;

  /// Text style override merged onto the default iOS 26/27 17 pt body style.
  final TextStyle? labelStyle;

  /// Size of [icon] in logical pixels.
  ///
  /// Defaults to `17.0` (matching iOS `.body` SF Symbol scale).
  final double iconSize;

  /// Horizontal gap between [icon] and [label] when both are provided.
  ///
  /// Defaults to `6.0`.
  final double spacing;

  // ===========================================================================
  // Visual & Color Properties
  // ===========================================================================

  /// Accent fill/tint color used when [value] is `true`.
  ///
  /// Supports [CupertinoDynamicColor]. If `null`, defaults to
  /// `CupertinoTheme.of(context).primaryColor`.
  final Color? activeColor;

  /// Foreground color for text and icon when [value] is `false`.
  ///
  /// Supports [CupertinoDynamicColor]. If `null`, defaults to
  /// [CupertinoColors.label] (or luminance-contrasted black/white when a
  /// high-alpha solid [color] is supplied).
  final Color? foregroundColor;

  /// Foreground color for text and icon when [value] is `true`.
  ///
  /// Supports [CupertinoDynamicColor]. If `null`, automatically selects
  /// [CupertinoColors.black] or [CupertinoColors.white] using Rec. 709 relative
  /// luminance (`> 0.55`) against [activeColor].
  final Color? activeForegroundColor;

  /// Explicit resting fill color override when [value] is `false` and the
  /// resolved [surfaceStyle] is [GlassSurfaceStyle.solid].
  ///
  /// Supports [CupertinoDynamicColor]. Defaults to [resolveGlassSolidWellColor]
  /// (`tertiarySystemFill`) when `null`. Ignored in [GlassSurfaceStyle.glass]
  /// mode.
  final Color? color;

  // ===========================================================================
  // Layout & Shape Properties
  // ===========================================================================

  /// Internal padding around the toggle content.
  ///
  /// When `null`, defaults to `EdgeInsetsDirectional.symmetric(horizontal: 12,
  /// vertical: 7)` for text/label toggles (yielding iOS 27's calibrated 34.3 pt
  /// capsule height) or `EdgeInsetsDirectional.symmetric(horizontal: 13,
  /// vertical: 7)` for icon-only toggles.
  final EdgeInsetsGeometry? padding;

  /// Minimum height of the capsule in logical pixels when [height] is `null`.
  ///
  /// Defaults to `34.0`, matching native iOS 26/27 `.toggleStyle(.button)`
  /// compact glass pills.
  final double minHeight;

  /// Optional explicit width override in logical pixels.
  ///
  /// When `null` (the default), the toggle shrink-wraps its content and
  /// padding (with a 44 pt minimum width for icon-only toggles).
  final double? width;

  /// Optional explicit height override in logical pixels.
  ///
  /// When `null` (the default), sizes to content + [padding] with at least
  /// [minHeight].
  final double? height;

  /// Shape of the toggle button.
  ///
  /// Defaults to a continuous superellipse capsule
  /// (`LiquidRoundedSuperellipse(borderRadius: 100)`).
  final LiquidShape shape;

  // ===========================================================================
  // Glass Surface & Rendering Properties
  // ===========================================================================

  /// How the toggle's surface is painted.
  ///
  /// If `null` (the default), inherits from the nearest ancestor
  /// [InheritedGlassSurfaceStyle] (e.g. a solid card or grouped section),
  /// falling back to [GlassSurfaceStyle.glass].
  final GlassSurfaceStyle? surfaceStyle;

  /// Glass effect settings forwarded to [GlassButton.custom].
  final LiquidGlassSettings? settings;

  /// Whether to create its own [LiquidGlassLayer] or share an ancestor layer.
  ///
  /// Defaults to `false`. When [value] is `true` in [GlassSurfaceStyle.glass]
  /// mode, [GlassButton] automatically promotes the tinted prominent pill to an
  /// isolated layer (unless nested inside a glass surface with
  /// `avoidsRefraction`) so the accent tint is always preserved.
  final bool useOwnLayer;

  /// Rendering quality override for the glass effect.
  final GlassQuality? quality;

  /// Forces the live [BackdropFilter] fallback path when floating over an iOS
  /// PlatformView (map, camera, video). Forwarded to [GlassButton.custom].
  final bool platformViewBackdrop;

  // ===========================================================================
  // Interaction & Accessibility Properties
  // ===========================================================================

  /// Whether to emit a [HapticFeedback.selectionClick] when toggled.
  ///
  /// Defaults to `true`.
  final bool enableHaptics;

  /// Scale factor applied when pressed. Forwarded to [GlassButton.custom].
  ///
  /// When `null` (the default), uses native iOS 26/27 press inflation sizing.
  final double? interactionScale;

  /// Drag-stretch intensity forwarded to [GlassButton.custom].
  ///
  /// Defaults to `0.3` (subtle tactile feedback suited to compact pills).
  final double stretch;

  /// Specular touch glow radius forwarded to [GlassButton.custom].
  ///
  /// When `null` (the default), uses native iOS 26/27 shape-clipped specular.
  final double? glowRadius;

  /// Whether the toggle anchors in place while stretching toward the finger.
  ///
  /// Defaults to `true`.
  final bool anchorStretch;

  /// Fine-tuning for anchor stretch behavior. Forwarded to [GlassButton.custom].
  final AnchorStretchSettings? anchorStretchSettings;

  /// Externally provided focus node for keyboard navigation.
  final FocusNode? focusNode;

  /// Whether this toggle requests keyboard focus automatically on mount.
  ///
  /// Defaults to `false`.
  final bool autofocus;

  /// Whether this toggle can receive keyboard focus.
  ///
  /// Defaults to `true`.
  final bool canRequestFocus;

  /// Explicit semantic label for assistive technology (VoiceOver, TalkBack).
  ///
  /// Recommended for icon-only toggles that have no visible [label]. When
  /// `null`, screen readers read [label] or the semantics of [child].
  final String? semanticLabel;

  /// Whether this toggle is one option of a set where exactly one is on,
  /// such as a choice chip or a single-choice filter, rather than an
  /// independent on/off toggle; for assistive technologies only.
  ///
  /// When `false` (the default), the toggle reads as a switch that is on or
  /// off. When `true`, it reads as a radio button of a mutually exclusive
  /// group, checked when [value] is `true`, in place of the switch: iOS
  /// reads a toggled node outside such a group as a switch, which says
  /// nothing of the other options. On iOS and macOS the checked toggle is
  /// also reported as selected, as Flutter's radio buttons are, since iOS
  /// reads a radio button's selected trait rather than its checked state.
  ///
  /// [onChanged] still receives `!value`: a set where the chosen option
  /// stays chosen when tapped again ignores `false`.
  final bool semanticsInMutuallyExclusiveGroup;

  static const _defaultTextPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 7);
  static const _defaultIconOnlyPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 13, vertical: 7);

  static void _noOp() {}

  /// Resolves a [Color] (including [CupertinoDynamicColor]) against the
  /// package's single brightness authority ([GlassTheme.brightnessOf]) and
  /// active high-contrast setting so local [GlassTheme] and
  /// [GlassContentAwareScope] brightness overrides are always honoured.
  static Color _resolveDynamicColor(
    Color color,
    bool isDark,
    bool highContrast,
  ) {
    if (color is CupertinoDynamicColor) {
      if (isDark) {
        return highContrast ? color.darkHighContrastColor : color.darkColor;
      }
      return highContrast ? color.highContrastColor : color.color;
    }
    return color;
  }

  void _handleTap() {
    final handler = onChanged;
    if (handler == null) return;
    if (enableHaptics) {
      HapticFeedback.selectionClick();
    }
    handler(!value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final effectiveSurfaceStyle = surfaceStyle ??
        InheritedGlassSurfaceStyle.maybeOf(context) ??
        GlassSurfaceStyle.glass;
    final isSolid = effectiveSurfaceStyle == GlassSurfaceStyle.solid;

    Color resolve(Color c) => _resolveDynamicColor(c, isDark, highContrast);

    final resolvedColor = color != null ? resolve(color!) : null;
    final resolvedActiveColor = resolve(
      activeColor ?? CupertinoTheme.of(context).primaryColor,
    );

    // Native iOS 26/27: a disabled ON toggle desaturates to a muted neutral
    // shaded pill rather than vibrant accent fill, while staying visibly
    // distinct from a disabled OFF pill. Both glass tintColor and solid
    // Opacity(0.5) attenuate disabled fills by 0.5, so passing 0.32 (light) /
    // 0.56 (dark) lands both modes at the calibrated 0.16 / 0.28 rest alpha.
    final Color? disabledOnFill = (!isEnabled && value)
        ? resolve(CupertinoColors.systemGrey)
            .withValues(alpha: isDark ? 0.56 : 0.32)
        : null;

    final Color effectiveForeground;
    if (!isEnabled) {
      effectiveForeground = foregroundColor != null
          ? resolve(foregroundColor!)
          : resolve(CupertinoColors.label);
    } else if (value) {
      effectiveForeground = activeForegroundColor != null
          ? resolve(activeForegroundColor!)
          : (resolvedActiveColor.computeLuminance() > 0.55
              ? CupertinoColors.black
              : CupertinoColors.white);
    } else {
      final explicitFg =
          foregroundColor != null ? resolve(foregroundColor!) : null;
      if (explicitFg != null) {
        effectiveForeground = explicitFg;
      } else if (isSolid && resolvedColor != null && resolvedColor.a > 0.5) {
        effectiveForeground = resolvedColor.computeLuminance() > 0.55
            ? CupertinoColors.black
            : CupertinoColors.white;
      } else {
        effectiveForeground = resolve(CupertinoColors.label);
      }
    }

    final defaultLabelStyle = TextStyle(
      fontSize: 17.0,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.41,
      color: effectiveForeground,
    );
    final effectiveLabelStyle = labelStyle != null
        ? defaultLabelStyle.merge(labelStyle)
        : defaultLabelStyle;

    final isIconOnly = child == null && icon != null && label == null;
    final effectivePadding = padding ??
        (height != null
            ? EdgeInsetsDirectional.symmetric(horizontal: isIconOnly ? 13 : 12)
            : (isIconOnly ? _defaultIconOnlyPadding : _defaultTextPadding));

    final Widget innerContent;
    if (child != null) {
      innerContent = DefaultTextStyle.merge(
        style: defaultLabelStyle,
        child: IconTheme.merge(
          data: IconThemeData(color: effectiveForeground, size: iconSize),
          child: child!,
        ),
      );
    } else if (isIconOnly) {
      innerContent = IconTheme(
        data: IconThemeData(color: effectiveForeground, size: iconSize),
        child: icon!,
      );
    } else {
      innerContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: effectiveForeground, size: iconSize),
              child: icon!,
            ),
            SizedBox(width: spacing),
          ],
          Flexible(
            child: Text(
              label!,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              // A label that does not fit wraps rather than being cut, as
              // a SwiftUI button's does at large text sizes. Only a fixed
              // height keeps it to one line.
              maxLines: height == null ? null : 1,
              overflow:
                  height == null ? TextOverflow.clip : TextOverflow.ellipsis,
              style: effectiveLabelStyle,
            ),
          ),
        ],
      );
    }

    final paddedContent = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width ?? (isIconOnly ? 44.0 : 0.0),
        minHeight: height ?? minHeight,
      ),
      child: Padding(
        padding: effectivePadding,
        child: Center(
          widthFactor: width == null ? 1.0 : null,
          heightFactor: height == null ? 1.0 : null,
          child: innerContent,
        ),
      ),
    );

    // One option of a mutually exclusive set reads as a radio button; Apple
    // platforms read its state from `selected`, as Flutter's own radio
    // buttons report it there.
    final exclusive = semanticsInMutuallyExclusiveGroup;
    final reportsSelected = exclusive &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    final button = GlassButton.custom(
      onTap: isEnabled ? _handleTap : _noOp,
      enabled: isEnabled,
      isToggled: exclusive ? null : value,
      isChecked: exclusive ? value : null,
      isSelected: reportsSelected ? value : null,
      label: semanticLabel ?? '',
      width: width,
      height: height,
      shape: shape,
      style: (value && isEnabled)
          ? GlassButtonStyle.prominent
          : GlassButtonStyle.filled,
      surfaceStyle: surfaceStyle,
      color: value ? (isSolid ? disabledOnFill : null) : color,
      tintColor:
          value ? (isEnabled ? resolvedActiveColor : disabledOnFill) : null,
      settings: settings,
      useOwnLayer: useOwnLayer,
      quality: quality,
      platformViewBackdrop: platformViewBackdrop,
      interactionScale: isEnabled ? interactionScale : 1.0,
      stretch: isEnabled ? stretch : 0.0,
      glowRadius: isEnabled ? glowRadius : 0.0,
      isStationary: !isEnabled,
      anchorStretch: anchorStretch,
      anchorStretchSettings: anchorStretchSettings,
      focusNode: focusNode,
      autofocus: autofocus,
      canRequestFocus: canRequestFocus,
      child: paddedContent,
    );

    // The 34 pt capsule is smaller than the 44 x 44 pt minimum target: the
    // semantics node extends around it to that size, and the touch area as
    // far as the parent's bounds allow, while the toggle keeps its size in
    // the layout.
    return _ToggleTapTarget(child: button);
  }
}

/// Gives the toggle a semantics node of at least
/// [kMinInteractiveDimensionCupertino] (44 pt) on each side, centred on the
/// capsule, and extends its touch area towards that size, without changing
/// its layout.
///
/// It owns the toggle's single semantics node (merging the button's node
/// into it), so the node spans the target everywhere. The touch area
/// reaches past the capsule only as far as the parent's bounds allow, since
/// a hit test stops at any ancestor that does not contain the touch. A
/// touch that lands around the capsule is moved onto its centre line by a
/// translation only, so the press feedback follows it as on the capsule.
class _ToggleTapTarget extends SingleChildRenderObjectWidget {
  const _ToggleTapTarget({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderToggleTapTarget();
}

class _RenderToggleTapTarget extends RenderProxyBox {
  Rect get _target => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: math.max(size.width, kMinInteractiveDimensionCupertino),
        height: math.max(size.height, kMinInteractiveDimensionCupertino),
      );

  @override
  Rect get semanticBounds => _target;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null || !_target.contains(position)) return false;
    // The nearest point on the capsule's centre line, inside its round ends.
    final radius = size.height / 2;
    final onCapsule = Offset(
      position.dx.clamp(radius, math.max(radius, size.width - radius)),
      radius,
    );
    final hit = result.addWithPaintOffset(
      offset: position - onCapsule,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}
