import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:liquid_glass_renderer/src/internal/multi_shader_builder.dart';
import 'package:liquid_glass_renderer/src/shaders.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // SHADER PRECACHING
  // ------------------
  // Attempt to precache shaders for premium quality glass rendering.
  //
  // NOTE: You will see "Asset 'lib/assets/shaders/*.frag' not found" exceptions
  // during test execution. These are EXPECTED and HARMLESS. They occur because:
  // 1. Shader assets are compiled at app runtime, not available in test environments
  // 2. The liquid_glass_renderer package attempts to load shaders during initialization
  // 3. Tests automatically fall back to backdrop filter mode (GlassQuality.standard)
  // 4. All tests pass correctly despite these warnings
  //
  // The test infrastructure is designed to handle missing shaders gracefully.
  // These warnings do not indicate a problem and can be safely ignored.
  try {
    await MultiShaderBuilder.precacheShaders([
      ShaderKeys.blendedGeometry,
      ShaderKeys.liquidGlassRender,
      ShaderKeys.lighting,
      ShaderKeys.liquidGlassFilterShader,
      ShaderKeys.glassify,
    ]);
  } catch (e) {
    // Shader assets not available during testing - this is expected
    // Tests will use backdrop filter mode instead
  }

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      ciGoldensConfig: const CiGoldensConfig(enabled: false),
      platformGoldensConfig: PlatformGoldensConfig(
        platforms: {HostPlatform.macOS},
      ),
    ),
    run: testMain,
  );
}
