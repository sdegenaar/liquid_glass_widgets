import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  final settings = LiquidGlassSettings.figma(
    refraction: 60,
    depth: 80,
    dispersion: 100,
    frost: 2,
    lightAngle: -45,
    lightIntensity: 70,
    glassColor: Colors.white.withValues(alpha: .6),
  );

  print('Blur: ${settings.blur}');
  print('Thickness: ${settings.thickness}');
  print('Refractive Index: ${settings.refractiveIndex}');
  print('Chromatic Aberration: ${settings.chromaticAberration}');
  print('Light Intensity: ${settings.lightIntensity}');
  print('Ambient Strength: ${settings.ambientStrength}');
  print('Saturation: ${settings.saturation}');
  print('Light Angle: ${settings.lightAngle}');
  print('Glass Color: ${settings.glassColor}');
}
