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

  /// Shows [items] on a wheel in a modal bottom sheet and completes with the
  /// item the user picks.
  ///
  /// The sheet follows `showGlassDatePicker`: a header with a **Cancel**
  /// button, the optional [title], and a **Done** button above a
  /// [CupertinoPicker] that builds each item with [itemBuilder].
  ///
  /// - **Done** completes the returned future with the item under the
  ///   selection band. If the user has not scrolled, that is the first item.
  ///   If [items] is empty, Done completes with `null`.
  /// - **Cancel**, a tap on the barrier, the system back gesture, and a
  ///   screen reader's dismiss action all complete it with `null`.
  ///
  /// Screen readers read the wheel as one adjustable element, named by
  /// [title] when it is given, with the selected item as its value.
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
      // Exposes the barrier's "Dismiss" action to screen readers, like the
      // package's other sheets and popovers.
      semanticsDismissible: true,
      builder: (modalContext) {
        Widget sheet = _GlassPickerSheet<T>(
          items: items,
          itemBuilder: itemBuilder,
          title: title,
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

/// The sheet [GlassPicker.showSheet] presents: a Cancel / title / Done header
/// above a [CupertinoPicker], styled like `showGlassDatePicker`'s sheet.
class _GlassPickerSheet<T> extends StatefulWidget {
  const _GlassPickerSheet({
    required this.items,
    required this.itemBuilder,
    this.title,
    super.key,
  });

  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final String? title;

  @override
  State<_GlassPickerSheet<T>> createState() => _GlassPickerSheetState<T>();
}

class _GlassPickerSheetState<T> extends State<_GlassPickerSheet<T>> {
  /// The wheel starts on the first item, so Done without scrolling picks it.
  int _selectedIndex = 0;

  void _done() {
    final items = widget.items;
    Navigator.of(context).pop<T>(
      items.isEmpty ? null : items[_selectedIndex.clamp(0, items.length - 1)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final title = widget.title;

    Widget picker = CupertinoPicker.builder(
      itemExtent: 40,
      onSelectedItemChanged: (index) => _selectedIndex = index,
      itemBuilder: (context, index) {
        if (index < 0 || index >= items.length) return null;
        return widget.itemBuilder(items[index]);
      },
      childCount: items.length,
    );
    if (title != null) {
      // CupertinoPicker is one adjustable node (the selected item as its
      // value, with increase and decrease) but takes no label, and a plain
      // Semantics label around it would be a separate parent node. Merging
      // reads them as one element: the title, then the selected item.
      picker = MergeSemantics(
        child: Semantics(label: title, child: picker),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              if (title != null)
                // Flexible so a long or scaled-up title wraps between the
                // buttons instead of overflowing the row.
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _done,
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // The standard iOS wheel height, as in GlassDatePicker's wheel style.
          SizedBox(height: 216, child: picker),
        ],
      ),
    );
  }
}
