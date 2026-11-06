import 'package:flutter/cupertino.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../shared/adaptive_glass.dart';
import '../shared/glass_solid_surface.dart';
import '../shared/inherited_liquid_glass.dart';
import '../../theme/glass_theme.dart';
import '../../theme/glass_theme_helpers.dart';

/// A glass picker widget following iOS design patterns.
///
/// [GlassPicker] displays a selected value in a glass container. Tapping it
/// opens a standard Cupertino picker in a modal bottom sheet.
class GlassPicker extends StatelessWidget {
  /// Creates a glass picker.
  const GlassPicker({
    required this.value,
    this.onTap,
    super.key,
    this.placeholder = 'Select',
    this.icon,
    this.height = 48.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.textStyle,
    this.placeholderStyle,
    this.settings,
    this.useOwnLayer = false,
    this.quality,
    this.surfaceStyle,
    this.color,
    this.shape = const LiquidRoundedRectangle(borderRadius: 10),
    this.semanticLabel,
  });

  /// The currently selected text value.
  final String? value;

  /// Placeholder when value is null.
  final String placeholder;

  /// Icon widget to display at the end (defaults to chevron down).
  final Widget? icon;

  /// Called when tapped.
  final VoidCallback? onTap;

  /// Height of the picker field.
  ///
  /// This is the field's minimum height: with a large system text size the
  /// field grows to fit the text instead of clipping it.
  final double height;

  /// Optional width.
  final double? width;

  /// Padding.
  final EdgeInsetsGeometry padding;

  /// Style for the value text.
  final TextStyle? textStyle;

  /// Style for the placeholder text.
  final TextStyle? placeholderStyle;

  /// Glass settings.
  final LiquidGlassSettings? settings;

  /// Whether to use its own layer (true) or grouped (false).
  final bool useOwnLayer;

  /// Quality.
  final GlassQuality? quality;

  /// How the picker's surface is painted.
  ///
  /// If null (the default), inherits from the nearest ancestor
  /// [InheritedGlassSurfaceStyle] (such as a `solid` `GlassContainer.card` or
  /// `GlassGroupedSection`), falling back to [GlassSurfaceStyle.glass].
  ///
  /// - [GlassSurfaceStyle.glass]: Renders the picker with [AdaptiveGlass].
  /// - [GlassSurfaceStyle.solid]: Renders a flat recessed well
  ///   ([resolveGlassSolidWellColor] by default, or [color] when provided)
  ///   with zero shader or backdrop-filter overhead. [settings],
  ///   [useOwnLayer], and [quality] are ignored.
  final GlassSurfaceStyle? surfaceStyle;

  /// Explicit fill color override for [GlassSurfaceStyle.solid] pickers.
  ///
  /// If null, a solid picker uses [resolveGlassSolidWellColor] (`#1E767680` in
  /// light mode, `#3D767680` in dark mode — matching iOS `tertiarySystemFill`).
  /// Ignored when the resolved surface style is [GlassSurfaceStyle.glass]
  /// (use [LiquidGlassSettings.glassColor] in [settings] to tint glass).
  final Color? color;

  /// Shape of the container.
  final LiquidShape shape;

  /// What the picker chooses, announced by screen readers (for example
  /// "Size"), with the current [value] read as the value.
  ///
  /// When null, the visible text ([value] or [placeholder]) is the label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    final effectiveTextStyle =
        TextStyle(fontSize: 16, color: labelColor).merge(textStyle);

    final effectivePlaceholderStyle =
        TextStyle(fontSize: 16, color: secondaryColor).merge(placeholderStyle);

    // A minimum height rather than a fixed one, so the value survives a
    // large system text size (SC 1.4.4); at the default scale it is the same.
    final child = Container(
      constraints: BoxConstraints(minHeight: height),
      width: width,
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? placeholder,
              style: value != null
                  ? effectiveTextStyle
                  : effectivePlaceholderStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(size: 16, color: secondaryColor),
            child: icon ?? const Icon(CupertinoIcons.chevron_up_chevron_down),
          ),
        ],
      ),
    );

    final effectiveSurfaceStyle = surfaceStyle ??
        InheritedGlassSurfaceStyle.maybeOf(context) ??
        GlassSurfaceStyle.glass;

    final Widget surfaceWidget;
    if (effectiveSurfaceStyle == GlassSurfaceStyle.solid) {
      assert(() {
        if (settings != null || quality != null) {
          debugPrint(
            'GlassPicker: `settings` / `quality` have no effect when '
            '`surfaceStyle` is GlassSurfaceStyle.solid (a solid picker is a '
            'flat recessed well and does not use the glass shader).',
          );
        }
        return true;
      }());

      surfaceWidget = DecoratedBox(
        decoration: ShapeDecoration(
          color: color ?? resolveGlassSolidWellColor(context),
          shape: shape,
        ),
        child: child,
      );
    } else {
      assert(() {
        if (settings != null && !useOwnLayer) {
          final inherited = InheritedLiquidGlass.of(context);
          if (inherited != null && inherited != settings) {
            debugPrint(
              'GlassPicker: `settings` provided without `useOwnLayer: true`. '
              'In grouped mode, per-widget settings are ignored — the parent '
              'layer\'s settings are used instead.\n'
              '  → To apply these settings, add `useOwnLayer: true` (creates a '
              'separate rendering layer).\n'
              '  → For better performance, set `settings` on GlassPage or '
              'AdaptiveLiquidGlassLayer so all grouped children inherit them.',
            );
          }
        }
        return true;
      }());

      // Inherit quality from parent layer if not explicitly set
      final effectiveQuality = GlassThemeHelpers.resolveQuality(
        context,
        widgetQuality: quality,
      );
      final effectiveSettings = GlassThemeHelpers.resolveSettings(
        context,
        explicit: settings,
      );

      surfaceWidget = AdaptiveGlass(
        shape: shape,
        settings: effectiveSettings,
        quality: effectiveQuality,
        useOwnLayer: useOwnLayer,
        child: child,
      );
    }

    final shownText = value ?? placeholder;
    // One node for the whole field: a button named by [semanticLabel] (or the
    // visible text) whose value is the current selection. The text below is
    // excluded so it is not read a second time.
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: semanticLabel ?? shownText,
      value: semanticLabel != null ? shownText : null,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: surfaceWidget,
      ),
    );
  }

  /// Helper to show a bottom sheet picker.
  static Future<T?> showSheet<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(T item) itemBuilder,
    String? title,
  }) {
    final capturedGlassTheme = GlassTheme.maybeOf(context)?.data;
    final capturedCupertinoTheme = CupertinoTheme.of(context);
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (modalContext) {
        Widget sheet = Container(
          height: 300,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(modalContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              if (title != null)
                Container(
                  // Minimum, not fixed, so a scaled-up title is not clipped.
                  constraints: const BoxConstraints(minHeight: 50),
                  alignment: Alignment.center,
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              Expanded(
                child: CupertinoPicker.builder(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    // Handle live update if needed
                  },
                  itemBuilder: (context, index) {
                    if (index < 0 || index >= items.length) return null;
                    return itemBuilder(items[index]);
                  },
                  childCount: items.length,
                ),
              ),
            ],
          ),
        );
        sheet = CupertinoTheme(
          data: capturedCupertinoTheme,
          child: sheet,
        );
        if (capturedGlassTheme != null) {
          sheet = GlassTheme(
            data: capturedGlassTheme,
            child: sheet,
          );
        }
        return sheet;
      },
    );
  }
}
