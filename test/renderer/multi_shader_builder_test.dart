// Regression tests for MultiShaderBuilder's key handling and shader caching.
//
// The stale-load guard in _loadShaders has no test here: on the native engine
// FragmentProgram.fromAsset finishes on the next microtask, before keys can
// change in a later frame, so the race cannot be reproduced in a widget test.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/src/engine/multi_shader_builder.dart';
import 'package:liquid_glass_widgets/src/engine/shaders.dart';

const _built = ValueKey('built');

void main() {
  testWidgets('rebuilding with equal keys keeps the same shader',
      (tester) async {
    final key = ShaderKeys.blendedGeometry;
    await tester.runAsync(() => MultiShaderBuilder.precacheShader(key));

    final seen = <ui.FragmentShader>[];
    Widget build() => MultiShaderBuilder(
          (context, shaders, child) {
            seen.add(shaders.single);
            return const SizedBox(key: _built);
          },
          // A new list on every build, as ShaderBuilder passes.
          assetKeys: [key],
        );

    await tester.pumpWidget(build());
    await tester.pumpWidget(build());

    expect(seen, hasLength(2));
    expect(identical(seen[0], seen[1]), isTrue);
  });

  testWidgets('changing to different keys still reloads', (tester) async {
    final first = ShaderKeys.blendedGeometry;
    final second = ShaderKeys.liquidGlassRender;
    await tester.runAsync(
      () => MultiShaderBuilder.precacheShaders([first, second]),
    );

    final seen = <ui.FragmentShader>[];
    Widget build(String key) => MultiShaderBuilder(
          (context, shaders, child) {
            seen.add(shaders.single);
            return const SizedBox(key: _built);
          },
          assetKeys: [key],
        );

    await tester.pumpWidget(build(first));
    await tester.pumpWidget(build(second));

    expect(seen, hasLength(2));
    expect(identical(seen[0], seen[1]), isFalse);
  });
}
