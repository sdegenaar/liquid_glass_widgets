import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import '../../theme/glass_theme_helpers.dart';
import '../../types/glass_quality.dart';
import '../shared/adaptive_glass.dart';

/// A navigation bar layout widget following Apple's iOS 26 design patterns.
///
/// By default, [GlassAppBar] renders a **transparent** bar with leading widget,
/// centered title, and trailing actions — matching iOS 26's navigation bar where
/// the glass effect is on the individual buttons, not the bar itself.
///
/// To add a glass surface behind the bar, pass explicit [settings]. This is
/// opt-in because most iOS 26 apps use transparent navigation bars.
///
/// This widget implements [PreferredSizeWidget] for use in [Scaffold.appBar].
///
/// ## Default (Transparent — iOS 26 style)
/// ```dart
/// Scaffold(
///   appBar: GlassAppBar(
///     title: Text('Messages'),
///     leading: GlassButton(
///       icon: Icon(CupertinoIcons.back),
///       onTap: () => Navigator.pop(context),
///     ),
///     actions: [
///       GlassButton(icon: Icon(Icons.edit), onTap: () {}),
///     ],
///   ),
///   body: Content(),
/// )
/// ```
///
/// ## With Glass Background (opt-in)
/// ```dart
/// GlassAppBar(
///   settings: LiquidGlassSettings(blur: 15, thickness: 10),
///   useOwnLayer: true,
///   title: Text('Blurred Nav'),
/// )
/// ```
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a glass app bar.
  ///
  /// By default renders a transparent navigation bar (no glass surface).
  /// Pass [settings] to opt in to a glass background.
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.preferredSize = const Size.fromHeight(44.0),
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.settings,
    this.useOwnLayer = false,
    this.quality,
  });

  // ===========================================================================
  // Properties
  // ===========================================================================

  /// The primary content of the app bar, typically a [Text] widget.
  final Widget? title;

  /// A widget to display before the title, typically a back button.
  final Widget? leading;

  /// A list of widgets to display after the title.
  final List<Widget>? actions;

  /// Whether the [title] should be centered.
  final bool centerTitle;

  /// The background color of the app bar.
  ///
  /// Defaults to [Colors.transparent] to match iOS 26's transparent
  /// navigation bar pattern.
  final Color backgroundColor;

  /// The preferred height of the app bar.
  @override
  final Size preferredSize;

  /// Padding around the app bar content.
  final EdgeInsetsGeometry padding;

  /// Glass effect settings for an optional glass background.
  ///
  /// When `null` (default), the app bar renders with a transparent background
  /// matching iOS 26's navigation bar pattern where glass effects are on
  /// individual buttons, not the bar itself.
  ///
  /// When provided, wraps the bar content in an [AdaptiveGlass] surface to
  /// create a frosted glass background.
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass within an existing
  /// layer. Only used when [settings] is provided.
  ///
  /// - `false` (default): Uses [LiquidGlass.grouped], rendering within the
  ///   parent [GlassPage] or [AdaptiveLiquidGlassLayer].
  ///
  /// - `true`: Uses [LiquidGlass.withOwnLayer], creating an independent glass
  ///   rendering context.
  ///
  /// Defaults to false. Ignored when [settings] is null.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect. Only used when [settings] is
  /// provided.
  ///
  /// If null, inherits from the ambient glass quality scope.
  final GlassQuality? quality;

  static const _appBarShape = LiquidRoundedRectangle(borderRadius: 0);

  @override
  Widget build(BuildContext context) {
    // Build the app bar content
    final appBarContent = SafeArea(
      bottom: false,
      child: Padding(
        padding: padding,
        child: SizedBox(
          height: preferredSize.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading widget
              if (leading != null) leading!,

              // Flexible title
              Expanded(
                child: centerTitle
                    ? Center(child: title ?? const SizedBox.shrink())
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: title ?? const SizedBox.shrink(),
                        ),
                      ),
              ),

              // Trailing actions
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: actions!,
                ),
            ],
          ),
        ),
      ),
    );

    // When no glass settings are provided, render a simple transparent bar
    // matching iOS 26's navigation pattern.
    if (settings == null) {
      return ColoredBox(
        color: backgroundColor,
        child: appBarContent,
      );
    }

    // When settings are provided, wrap in AdaptiveGlass for a frosted
    // glass background.
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
      fallback: GlassQuality.premium,
    );

    final glassWidget = AdaptiveGlass(
      shape: _appBarShape,
      settings: settings!,
      quality: effectiveQuality,
      useOwnLayer: useOwnLayer,
      allowElevation: false,
      child: appBarContent,
    );

    return ColoredBox(
      color: backgroundColor,
      child: glassWidget,
    );
  }
}
