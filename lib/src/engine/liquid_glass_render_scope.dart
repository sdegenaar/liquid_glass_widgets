// Copyright 2024-2025 Tim Lehmann for whynotmake.it
//
// SPDX-License-Identifier: MIT
//
// Originally from liquid_glass_renderer (whynotmake.it).
// Maintained and evolved in-tree for liquid_glass_widgets.
// See lib/src/engine/ATTRIBUTION.md for provenance and modification history.

// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import '../renderer/glass_materialize_scope.dart';
import 'liquid_glass_settings.dart';

class LiquidGlassRenderScope extends InheritedWidget {
  /// Creates a new [LiquidGlassRenderScope].
  const LiquidGlassRenderScope({
    required this.settings,
    LiquidGlassSettings? rawSettings,
    this.appliedMaterializeScope,
    required super.child,
    super.key,
  }) : rawSettings = rawSettings ?? settings;

  final LiquidGlassSettings settings;

  /// Layer settings prior to [appliedMaterializeScope] scaling, so descendant
  /// [LiquidGlass] shapes inside a nested [GlassMaterializeScope] (e.g. a
  /// menu trigger inside a shared tab-bar layer) can resolve their inner scope
  /// without compounding the outer scope twice.
  final LiquidGlassSettings rawSettings;

  /// The [GlassMaterializeScope] already folded into [settings] by the
  /// enclosing [LiquidGlassLayer], if any.
  final GlassMaterializeScope? appliedMaterializeScope;

  static LiquidGlassRenderScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LiquidGlassRenderScope>();
    assert(
      scope != null,
      'No liquid glass renderer found in context. '
      'Make sure to wrap your liquid glass widgets in a LiquidGlassLayer.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget is! LiquidGlassRenderScope ||
        oldWidget.settings != settings ||
        oldWidget.rawSettings != rawSettings ||
        !identical(oldWidget.appliedMaterializeScope, appliedMaterializeScope);
  }
}
