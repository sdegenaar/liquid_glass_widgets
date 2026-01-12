// ignore_for_file: require_trailing_commas

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'inherited_liquid_glass.dart';

/// A lightweight, high-performance glass effect widget optimized for
/// scrollable lists and universal platform compatibility.
///
/// This widget uses a custom fragment shader to achieve iOS 26 liquid glass
/// aesthetics while being 5-10x faster than BackdropFilter-based approaches.
///
/// **Lightweight-Specific Parameters:**
/// - [glowIntensity]: Interactive glow strength (0.0-1.0, button press feedback)
/// - [densityFactor]: Elevation physics (0.0-1.0, simulates nested blur darkening)
///
/// These parameters are only used by the lightweight shader (Skia/Web).
/// On Impeller, glow is handled by [GlassGlow] widget and density is not needed.
class LightweightLiquidGlass extends StatefulWidget {
  /// Creates a lightweight liquid glass effect widget.
  const LightweightLiquidGlass({
    required this.child,
    required this.shape,
    this.settings = const LiquidGlassSettings(),
    this.glowIntensity = 0.0,
    this.densityFactor = 0.0,
    super.key,
  });

  /// Creates a lightweight glass widget that inherits settings from the
  /// nearest ancestor [LiquidGlassLayer].
  const LightweightLiquidGlass.inLayer({
    required this.child,
    required this.shape,
    this.glowIntensity = 0.0,
    this.densityFactor = 0.0,
    super.key,
  }) : settings = null;

  /// The widget to display inside the glass effect.
  final Widget child;

  /// The shape of the glass surface.
  final LiquidShape shape;

  /// The glass effect settings.
  final LiquidGlassSettings? settings;

  /// Interactive glow intensity for button press feedback (Skia/Web only).
  ///
  /// Range: 0.0 (no glow) to 1.0 (full glow)
  ///
  /// On Impeller, use [GlassGlow] widget instead. This parameter is ignored.
  /// On Skia/Web, this controls shader-based glow effect.
  ///
  /// Defaults to 0.0.
  final double glowIntensity;

  /// Density factor for elevation physics (Skia/Web only).
  ///
  /// Range: 0.0 (normal) to 1.0 (fully elevated)
  ///
  /// When a parent container provides blur (batch-blur optimization), elevated
  /// buttons use this to simulate the "double-darkening" effect of nested
  /// BackdropFilters without the O(n) performance cost.
  ///
  /// On Impeller, this is not needed as each widget can have its own blur.
  ///
  /// Defaults to 0.0.
  final double densityFactor;

  // Cache the FragmentProgram (compiled shader code) globally
  static ui.FragmentProgram? _cachedProgram;
  static bool _isPreparing = false;

  // On native: Share one shader instance (efficient)
  // On web: Each widget needs its own instance (CanvasKit requirement)
  static ui.FragmentShader? _sharedShader; // Native only

  /// Global pre-warm method - loads and compiles the shader program.
  static Future<void> preWarm() async {
    if (_cachedProgram != null || _isPreparing) return;
    _isPreparing = true;
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'packages/liquid_glass_widgets/shaders/lightweight_glass.frag',
      );
      _cachedProgram = program;

      // On native platforms, create the shared shader instance
      if (!kIsWeb) {
        _sharedShader = program.fragmentShader();
        debugPrint(
            '[LightweightGlass] ✓ Shader precached (native shared mode)');
      } else {
        debugPrint(
            '[LightweightGlass] ✓ Shader program loaded (web per-widget mode)');
      }
    } catch (e) {
      debugPrint('[LightweightGlass] Pre-warm failed: $e');
    } finally {
      _isPreparing = false;
    }
  }

  @override
  State<LightweightLiquidGlass> createState() => _LightweightLiquidGlassState();
}

class _LightweightLiquidGlassState extends State<LightweightLiquidGlass> {
  ui.FragmentShader? _webShader; // Web only: per-widget instance
  bool _loggedCreation = false;

  @override
  void initState() {
    super.initState();
    _initShader();
  }

  Future<void> _initShader() async {
    // Ensure program is loaded
    if (LightweightLiquidGlass._cachedProgram == null) {
      await LightweightLiquidGlass.preWarm();
    }

    // On web, create a per-widget shader instance
    if (kIsWeb && LightweightLiquidGlass._cachedProgram != null) {
      if (mounted) {
        setState(() {
          _webShader = LightweightLiquidGlass._cachedProgram!.fragmentShader();
          if (!_loggedCreation) {
            debugPrint(
                '[LightweightGlass] ✓ Created web shader for ${widget.shape.runtimeType}');
            _loggedCreation = true;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // On web, dispose this widget's shader instance
    if (kIsWeb && _webShader != null) {
      _webShader!.dispose();
      _webShader = null;
    }
    // Never dispose the shared shader on native
    super.dispose();
  }

  ui.FragmentShader? get _activeShader {
    return kIsWeb ? _webShader : LightweightLiquidGlass._sharedShader;
  }

  @override
  Widget build(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>();
    final settings =
        widget.settings ?? inherited?.settings ?? const LiquidGlassSettings();
    final shader = _activeShader;

    // Optimization: Skip local blur if provided by ancestor and settings match
    final bool skipBlur = (inherited?.isBlurProvidedByAncestor ?? false) &&
        (widget.settings == null ||
            widget.settings?.blur == inherited?.settings.blur);

    if (shader == null) {
      // Shader not ready yet - show fallback
      return ClipPath(
        clipper: ShapeBorderClipper(shape: widget.shape),
        child: Container(
          color: settings.effectiveGlassColor.withValues(alpha: 0.15),
          child: widget.child,
        ),
      );
    }

    return ClipPath(
      clipper: ShapeBorderClipper(shape: widget.shape),
      child: _LightweightGlassEffect(
        shader: shader,
        settings: settings,
        shape: widget.shape,
        skipBlur: skipBlur,
        glowIntensity: widget.glowIntensity,
        densityFactor: widget.densityFactor,
        child: widget.child,
      ),
    );
  }
}

class _LightweightGlassEffect extends SingleChildRenderObjectWidget {
  const _LightweightGlassEffect({
    required this.shader,
    required this.settings,
    required this.shape,
    required this.skipBlur,
    required this.glowIntensity,
    required this.densityFactor,
    required super.child,
  });

  final ui.FragmentShader shader;
  final LiquidGlassSettings settings;
  final LiquidShape shape;
  final bool skipBlur;
  final double glowIntensity;
  final double densityFactor;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLightweightGlass(
      shader: shader,
      settings: settings,
      shape: shape,
      skipBlur: skipBlur,
      glowIntensity: glowIntensity,
      densityFactor: densityFactor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderLightweightGlass renderObject,
  ) {
    renderObject
      ..shader = shader
      ..settings = settings
      ..shape = shape
      ..skipBlur = skipBlur
      ..glowIntensity = glowIntensity
      ..densityFactor = densityFactor;
  }
}

class _RenderLightweightGlass extends RenderProxyBox {
  _RenderLightweightGlass({
    required ui.FragmentShader shader,
    required LiquidGlassSettings settings,
    required LiquidShape shape,
    required bool skipBlur,
    required double glowIntensity,
    required double densityFactor,
  })  : _shader = shader,
        _settings = settings,
        _shape = shape,
        _skipBlur = skipBlur,
        _glowIntensity = glowIntensity,
        _densityFactor = densityFactor;

  ui.FragmentShader _shader;
  ui.FragmentShader get shader => _shader;
  set shader(ui.FragmentShader value) {
    if (_shader == value) return;
    _shader = value;
    markNeedsPaint();
  }

  LiquidGlassSettings _settings;
  LiquidGlassSettings get settings => _settings;
  set settings(LiquidGlassSettings value) {
    if (_settings == value) return;
    _settings = value;
    markNeedsPaint();
  }

  LiquidShape _shape;
  LiquidShape get shape => _shape;
  set shape(LiquidShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  bool _skipBlur;
  bool get skipBlur => _skipBlur;
  set skipBlur(bool value) {
    if (_skipBlur == value) return;
    _skipBlur = value;
    markNeedsPaint();
  }

  double _glowIntensity;
  double get glowIntensity => _glowIntensity;
  set glowIntensity(double value) {
    if (_glowIntensity == value) return;
    _glowIntensity = value;
    markNeedsPaint();
  }

  double _densityFactor;
  double get densityFactor => _densityFactor;
  set densityFactor(double value) {
    if (_densityFactor == value) return;
    _densityFactor = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      // 1. Establish the Backdrop Pass
      final blurSigma = _settings.effectiveBlur;
      if (blurSigma > 0 && !_skipBlur) {
        context.pushLayer(
          BackdropFilterLayer(
            filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          ),
          (context, offset) {
            // Paint Child & Shader inside the blur context
            _paintGlassContent(context, offset);
          },
          offset,
        );
      } else {
        // No blur needed or skip requested - just paint content
        _paintGlassContent(context, offset);
      }
    }
  }

  void _paintGlassContent(PaintingContext context, Offset offset) {
    // 2. Center Content Pass (Child content)
    super.paint(context, offset);

    // 3. Zero-Latency Matrix-Synced Shader Overlay
    final canvas = context.canvas;
    final matrix = canvas.getTransform();

    final canvasPhysicalX = matrix[12];
    final canvasPhysicalY = matrix[13];
    final scaleX = matrix[0];
    final scaleY = matrix[5];

    final uOrigin = Offset(
      canvasPhysicalX + (offset.dx * scaleX),
      canvasPhysicalY + (offset.dy * scaleY),
    );

    final uScale = Offset(scaleX, scaleY);

    _updateShaderUniforms(size, uOrigin, uScale);

    final paint = Paint()..shader = _shader;
    canvas.drawRect(offset & size, paint);
  }

  void _updateShaderUniforms(
      Size size, Offset physicalOrigin, Offset physicalScale) {
    int index = 0;

    // 0, 1: uSize (vec2) - Layout Pixels (Logical)
    _shader.setFloat(index++, size.width);
    _shader.setFloat(index++, size.height);

    // 2, 3: uOrigin (vec2) - Physical Pixels (Window Absolute)
    _shader.setFloat(index++, physicalOrigin.dx);
    _shader.setFloat(index++, physicalOrigin.dy);

    // 4, 5, 6, 7: uGlassColor (vec4)
    final color = _settings.effectiveGlassColor;
    _shader.setFloat(index++, (color.r * 255.0).round().clamp(0, 255) / 255.0);
    _shader.setFloat(index++, (color.g * 255.0).round().clamp(0, 255) / 255.0);
    _shader.setFloat(index++, (color.b * 255.0).round().clamp(0, 255) / 255.0);
    _shader.setFloat(index++, (color.a * 255.0).round().clamp(0, 255) / 255.0);

    // 8: uThickness (float)
    _shader.setFloat(index++, _settings.effectiveThickness);

    // 9: uLightAngle (float)
    _shader.setFloat(index++, _settings.lightAngle * 3.14159265359 / 180.0);

    // 10: uLightIntensity (float)
    _shader.setFloat(index++, _settings.effectiveLightIntensity);

    // 11: uAmbientStrength (float)
    _shader.setFloat(index++, _settings.effectiveAmbientStrength);

    // 12: uSaturation (float)
    _shader.setFloat(index++, _settings.effectiveSaturation);

    // 13: uRefractiveIndex (float)
    _shader.setFloat(index++, _settings.refractiveIndex);

    // 14: uChromaticAberration (float)
    // Keep range conservative: 0..1
    _shader.setFloat(
      index++,
      (_settings.chromaticAberration).clamp(0.0, 1.0),
    );

    // 15: uCornerRadius (float) - Logical
    double cornerRadius = 0.0;
    final dynamic dynShape = _shape;
    final shapeStr = _shape.runtimeType.toString().toLowerCase();

    // 1. Try dynamic property extraction (Highest Accuracy)
    try {
      if (dynShape.borderRadius is double) {
        cornerRadius = dynShape.borderRadius;
      } else if (dynShape.borderRadius is BorderRadius) {
        cornerRadius = dynShape.borderRadius.topLeft.x;
      } else if (dynShape.borderRadius is BorderRadiusGeometry) {
        final resolved = dynShape.borderRadius.resolve(TextDirection.ltr);
        cornerRadius = resolved.topLeft.x;
      } else if (dynShape.radius is double) {
        cornerRadius = dynShape.radius;
      } else if (dynShape.radius is Radius) {
        cornerRadius = dynShape.radius.x;
      }
    } catch (_) {}

    // 2. Class Name Heuristics (Robustness fallback)
    if (cornerRadius == 0.0) {
      if (shapeStr.contains('rounded') || shapeStr.contains('superellipse')) {
        cornerRadius = 16.0; // Standard pill/card radius
      } else if (shapeStr.contains('oval') ||
          shapeStr.contains('circle') ||
          shapeStr.contains('stadium')) {
        cornerRadius = math.min(size.width, size.height) / 2.0;
      }
    }

    final maxRadius = math.min(size.width, size.height) / 2.0;
    cornerRadius = cornerRadius.clamp(0.0, maxRadius);

    _shader.setFloat(index++, cornerRadius);

    // 16, 17: uScale (vec2) - Physical Scale (Includes DPR + Transforms)
    _shader.setFloat(index++, physicalScale.dx);
    _shader.setFloat(index++, physicalScale.dy);

    // 18: uGlowIntensity (float) - Interactive glow strength (0.0-1.0)
    _shader.setFloat(index++, _glowIntensity.clamp(0.0, 1.0));

    // 19: uDensityFactor (float) - Elevation physics (0.0-1.0)
    _shader.setFloat(index++, _densityFactor.clamp(0.0, 1.0));
  }
}
