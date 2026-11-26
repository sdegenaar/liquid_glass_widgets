import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass_blend_group.dart';
import 'package:liquid_glass_widgets/src/engine/shaders.dart';

// The iOS 27 material's uniforms sit at the end of each shader. The Dart side
// sets them by float index, and an index one short would silently land in
// the uniform before them, so pin both to the last slot.
void main() {
  test('uNativeEdge is the float after the geometry shader shape array',
      () async {
    final shader =
        (await ui.FragmentProgram.fromAsset(ShaderKeys.blendedGeometry))
            .fragmentShader();
    const index = 8 + LiquidGlassBlendGroup.maxShapesPerLayer * 7;
    shader.setFloat(index, 1);
    expect(() => shader.setFloat(index + 1, 0), throwsA(anything));
  });

  test('uNativeAberration ends the render shader float uniforms at slot 53',
      () async {
    final shader =
        (await ui.FragmentProgram.fromAsset(ShaderKeys.liquidGlassRender))
            .fragmentShader();
    // uBodyShade (45), then uNativeLens (46-49) and uNativeAberration (50-53).
    shader.setFloat(45, 1);
    shader.setFloat(53, 1);
    expect(() => shader.setFloat(54, 0), throwsA(anything));
  });

  test('uRimConfig ends the lightweight glass shader float uniforms at slot 38',
      () async {
    final shader =
        (await ui.FragmentProgram.fromAsset('shaders/lightweight_glass.frag'))
            .fragmentShader();
    shader.setFloat(38, 1);
    expect(() => shader.setFloat(39, 0), throwsA(anything));
  });

  test(
      'uFresnelStrength ends the interactive indicator shader float uniforms at slot 38',
      () async {
    final shader = (await ui.FragmentProgram.fromAsset(
            'shaders/interactive_indicator.frag'))
        .fragmentShader();
    shader.setFloat(38, 1);
    expect(() => shader.setFloat(39, 0), throwsA(anything));
  });
}
