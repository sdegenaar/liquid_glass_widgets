import 'package:flutter/widgets.dart';

import '../../theme/glass_theme.dart';
import '../../types/glass_surface_style.dart';

/// Fill of a `GlassSurfaceStyle.solid` card in light mode (`#FFFFFF`).
const Color kGlassSolidSurfaceLight = Color(0xFFFFFFFF);

/// Fill of a `GlassSurfaceStyle.solid` card in dark mode (`#1C1C1E`).
const Color kGlassSolidSurfaceDark = Color(0xFF1C1C1E);

/// Resolves the fill of a `GlassSurfaceStyle.solid` card.
///
/// Mirrors iOS `secondarySystemGroupedBackground` (without its elevated-dark
/// variant). Brightness comes from [GlassTheme.brightnessOf], the package's
/// single brightness authority, so the card always agrees with the text and
/// highlight colours of `GlassListTile` and friends.
Color resolveGlassSolidSurfaceColor(BuildContext context) =>
    GlassTheme.brightnessOf(context) == Brightness.dark
        ? kGlassSolidSurfaceDark
        : kGlassSolidSurfaceLight;

/// An inherited widget that exposes the active [GlassSurfaceStyle] to
/// descendant widgets (e.g. allowing [GlassListTile] to automatically default to
/// [GlassSwipeActionStyle.solidVibrancy] when inside a solid card).
class InheritedGlassSurfaceStyle extends InheritedWidget {
  /// Creates an inherited widget providing [surfaceStyle] to descendants.
  const InheritedGlassSurfaceStyle({
    required this.surfaceStyle,
    required super.child,
    super.key,
  });

  /// The surface style configured on the nearest ancestor container.
  final GlassSurfaceStyle surfaceStyle;

  /// Retrieves the nearest ambient [GlassSurfaceStyle], or null if none is present.
  static GlassSurfaceStyle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedGlassSurfaceStyle>()
        ?.surfaceStyle;
  }

  @override
  bool updateShouldNotify(InheritedGlassSurfaceStyle oldWidget) =>
      surfaceStyle != oldWidget.surfaceStyle;
}
