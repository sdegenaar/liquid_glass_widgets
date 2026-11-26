import 'package:flutter/cupertino.dart';
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
  /// Mutually exclusive with [child]. Can be paired with [icon].
  final String? label;

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

    return GlassButton.custom(
      onTap: isEnabled ? _handleTap : _noOp,
      enabled: isEnabled,
      isToggled: value,
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
  }
}
