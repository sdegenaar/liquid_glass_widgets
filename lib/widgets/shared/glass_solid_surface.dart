import 'package:flutter/cupertino.dart';

import '../../theme/glass_theme.dart';
import '../../types/glass_style.dart';
import '../../types/glass_surface_style.dart';

/// Fill of a `GlassSurfaceStyle.solid` card in light mode (`#FFFFFF`).
const Color kGlassSolidSurfaceLight = Color(0xFFFFFFFF);

/// Fill of a `GlassSurfaceStyle.solid` card in dark mode (`#1C1C1E`).
const Color kGlassSolidSurfaceDark = Color(0xFF1C1C1E);

/// Fill of a `GlassSurfaceStyle.solid` card in elevated dark mode (`#2C2C2E`),
/// used inside modal sheets and full-screen covers.
const Color kGlassSolidSurfaceDarkElevated = Color(0xFF2C2C2E);

/// Fill of a `GlassSurfaceStyle.solid` input well in light mode (`#1E767680`),
/// matching iOS `tertiarySystemFill`.
const Color kGlassSolidWellLight = Color(0x1E767680);

/// Fill of a `GlassSurfaceStyle.solid` input well in dark mode (`#3D767680`),
/// matching iOS `tertiarySystemFill`.
const Color kGlassSolidWellDark = Color(0x3D767680);

/// Resolves the fill of a `GlassSurfaceStyle.solid` card.
///
/// Mirrors iOS `secondarySystemGroupedBackground`: `#FFFFFF` in light mode,
/// `#1C1C1E` in base dark mode, and `#2C2C2E` in elevated dark mode (inside
/// [GlassModalSheet], [GlassFullScreenCover], or any subtree with
/// [CupertinoUserInterfaceLevelData.elevated]). Brightness comes from
/// [GlassTheme.brightnessOf], the package's single brightness authority, so
/// the card always agrees with the text and highlight colours of
/// `GlassListTile` and friends.
Color resolveGlassSolidSurfaceColor(BuildContext context) {
  if (GlassTheme.brightnessOf(context) != Brightness.dark) {
    return kGlassSolidSurfaceLight;
  }
  final isElevated = CupertinoUserInterfaceLevel.maybeOf(context) ==
      CupertinoUserInterfaceLevelData.elevated;
  return isElevated ? kGlassSolidSurfaceDarkElevated : kGlassSolidSurfaceDark;
}

/// Resolves the fill of a `GlassSurfaceStyle.solid` input well
/// (`GlassTextField`, `GlassTextArea`, `GlassPasswordField`, `GlassPicker`).
///
/// Mirrors iOS `tertiarySystemFill` ([kGlassSolidWellLight] in light mode,
/// [kGlassSolidWellDark] in dark mode) so the well stays recessed and visible
/// both inside a solid card (`#FFFFFF` / `#1C1C1E`) and directly on a grouped
/// page background. Brightness comes from [GlassTheme.brightnessOf].
Color resolveGlassSolidWellColor(BuildContext context) {
  if (GlassTheme.brightnessOf(context) == Brightness.dark) {
    return kGlassSolidWellDark;
  }
  final style = GlassTheme.maybeOf(context)?.data.style ?? GlassStyle.ios27;
  if (style == GlassStyle.ios26) {
    return const Color(0x66FFFFFF);
  }
  return kGlassSolidWellLight;
}

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

/// Exposes the corner shape of a row inside a grouped section card to
/// descendants.
///
/// [GlassGroupedSection] wraps each of its rows in this scope so a row's
/// lift/long-press presentation (e.g. [GlassListTile]'s context menu) can
/// match the card's silhouette: the first row carries the card's top corners,
/// the last row its bottom corners, and middle rows are square — exactly like
/// the cell of a native iOS inset-grouped list.
class InheritedGlassSectionRow extends InheritedWidget {
  /// Creates a scope describing the corners of the enclosed row.
  const InheritedGlassSectionRow({
    required this.corners,
    required super.child,
    super.key,
  });

  /// The corner radii of the enclosed row within its section card.
  final BorderRadius corners;

  /// Retrieves the corners of the nearest enclosing section row, or null when
  /// the widget is not inside a grouped section.
  static BorderRadius? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedGlassSectionRow>()
        ?.corners;
  }

  @override
  bool updateShouldNotify(InheritedGlassSectionRow oldWidget) =>
      corners != oldWidget.corners;
}
