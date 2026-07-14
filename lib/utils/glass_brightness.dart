// Package-private brightness resolution utility.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Resolves the effective brightness for glass widgets using a priority cascade:
///
/// 1. **Explicit [CupertinoThemeData.brightness] (CupertinoApp only)** — a
///    developer-pinned brightness on a true [CupertinoThemeData]. Skipped when
///    inside a [MaterialApp] because Flutter implicitly wraps the tree in a
///    [MaterialBasedCupertinoThemeData], which derives its brightness from the
///    Material theme — making the Cupertino read redundant and potentially wrong.
/// 2. **Material [Theme] brightness** — honours [ThemeMode.light],
///    [ThemeMode.dark], and [ThemeMode.system] via [Theme.maybeBrightnessOf].
///    This is the primary authority inside a [MaterialApp]. Returns null in a
///    pure [CupertinoApp] (no Material ancestor), so it is a safe no-op there.
/// 3. **Defensive [MaterialBasedCupertinoThemeData] brightness (MaterialApp)**
///    — in practice unreachable because [Theme.maybeBrightnessOf] always
///    returns non-null inside a [MaterialApp]. Retained as a robustness guard
///    in case a future Flutter change causes Level 2 to return null.
/// 4. **[MediaQuery.platformBrightnessOf]** — the device/OS system setting.
///    This is the historical default and the ultimate safe fallback.
///
/// The [GlassThemeData.brightness] explicit glass-theme override is checked
/// by [GlassTheme.brightnessOf] **before** calling this function, so that this
/// function remains free of glass-package imports (avoiding circular
/// dependencies in the theme hierarchy).
///
/// **Never call this function directly from widgets.** Always use
/// [GlassTheme.brightnessOf] so the glass-theme override is correctly honoured.
Brightness resolveGlassBrightness(BuildContext context) {
  final cupertinoTheme = CupertinoTheme.of(context);
  final isMaterialBased = cupertinoTheme is MaterialBasedCupertinoThemeData;

  // Level 1: explicit Cupertino brightness pin (CupertinoApp only).
  //
  // If the cupertinoTheme is not Material-based, it means we are in a pure
  // CupertinoApp. We check its brightness first because in a CupertinoApp,
  // the Material Theme is implicitly derived from it.
  if (!isMaterialBased) {
    final cupertinoBrightness = cupertinoTheme.brightness;
    if (cupertinoBrightness != null) return cupertinoBrightness;
  }

  // Level 2: Material ThemeMode.
  //
  // Honours [ThemeMode.light], [ThemeMode.dark], and [ThemeMode.system] via
  // [Theme.maybeBrightnessOf]. This is the primary authority in MaterialApp.
  final materialBrightness = Theme.maybeBrightnessOf(context);
  if (materialBrightness != null) return materialBrightness;

  // Level 3: Defensive guard — MaterialBasedCupertinoThemeData (MaterialApp).
  //
  // In practice this branch is never reached: Theme.maybeBrightnessOf() always
  // returns non-null inside a MaterialApp tree, so Level 2 short-circuits first.
  // This guard is retained for robustness against future Flutter engine changes.
  //
  // Note: MaterialBasedCupertinoThemeData.brightness is non-nullable (it reads
  // directly from the Material theme), so this return is unconditional — Level 4
  // is unreachable in any MaterialApp context.
  if (isMaterialBased) {
    return cupertinoTheme.brightness;
  }

  // Level 4: device/OS system brightness.
  //
  // This is the safe fallback and the historical behaviour before this fix.
  return MediaQuery.platformBrightnessOf(context);
}
