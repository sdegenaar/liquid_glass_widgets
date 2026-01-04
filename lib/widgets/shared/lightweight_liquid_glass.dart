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
class LightweightLiquidGlass extends StatefulWidget {
  /// Creates a lightweight liquid glass effect widget.
  const LightweightLiquidGlass({
    required this.child,
    required this.shape,
    this.settings = const LiquidGlassSettings(),
    super.key,
  });

  /// Creates a lightweight glass widget that inherits settings from the
  /// nearest ancestor [LiquidGlassLayer].
  const LightweightLiquidGlass.inLayer({
    required this.child,
    required this.shape,
    super.key,
  }) : settings = null;

  /// The widget to display inside the glass effect.
  final Widget child;

  /// The shape of the glass surface.
  final LiquidShape shape;

  /// The glass effect settings.
  final LiquidGlassSettings? settings;

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
    final settings =
        widget.settings ?? InheritedLiquidGlass.ofOrDefault(context);
    final shader = _activeShader;

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
    required super.child,
  });

  final ui.FragmentShader shader;
  final LiquidGlassSettings settings;
  final LiquidShape shape;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLightweightGlass(
      shader: shader,
      settings: settings,
      shape: shape,
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
      ..shape = shape;
  }
}

class _RenderLightweightGlass extends RenderProxyBox {
  _RenderLightweightGlass({
    required ui.FragmentShader shader,
    required LiquidGlassSettings settings,
    required LiquidShape shape,
  })  : _shader = shader,
        _settings = settings,
        _shape = shape;

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

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      // 1. Decoupled Backdrop Blur (Isolation Pass)
      final blurSigma = _settings.effectiveBlur;
      if (blurSigma > 0) {
        context.pushLayer(
          BackdropFilterLayer(
            filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          ),
          (context, offset) {},
          offset,
        );
      }

      // 2. Center Content Pass (Child content)
      super.paint(context, offset);

      // 3. Zero-Latency Matrix-Synced Shader Overlay
      // Instead of localToGlobal (which is unsafe in paint), we extract the
      // current canvas transformation. This includes all parent offsets,
      // scrolls, and scales (like from LiquidStretch).
      final canvas = context.canvas;
      final matrix = canvas.getTransform();

      // Extraction: 12, 13 are the physical window translation.
      // 0, 5 are the horizontal/vertical scale (includes DPR).
      final canvasPhysicalX = matrix[12];
      final canvasPhysicalY = matrix[13];
      final scaleX = matrix[0];
      final scaleY = matrix[5];

      // Calculate absolute screen physical origin of THIS widget
      // (Accounting for the 'offset' passed into the paint method)
      final uOrigin = Offset(
        canvasPhysicalX + (offset.dx * scaleX),
        canvasPhysicalY + (offset.dy * scaleY),
      );

      // The logical-to-physical ratio (includes DPR and any parent transforms like LiquidStretch)
      final uScale = Offset(scaleX, scaleY);

      _updateShaderUniforms(size, uOrigin, uScale);

      final paint = Paint()..shader = _shader;

      // We draw the shader at the SAME offset where the child was painted.
      // This ensures the clipping rect matches the widget bounds.
      canvas.drawRect(offset & size, paint);
    }
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
    double cornerRadius = 16.0;
    final shapeStr = _shape.runtimeType.toString();
    if (shapeStr.contains('Rounded') || shapeStr.contains('Superellipse')) {
      try {
        final dynamic dynamicShape = _shape;
        cornerRadius = (dynamicShape.borderRadius is double)
            ? dynamicShape.borderRadius
            : (dynamicShape.radius is double)
                ? dynamicShape.radius
                : 16.0;
      } catch (_) {}
    } else if (shapeStr.contains('Oval') || shapeStr.contains('Circle')) {
      cornerRadius = math.min(size.width, size.height) / 2.0;
    } else if (shapeStr.contains('Rectangle')) {
      cornerRadius = 0.0;
    }

    final maxRadius = math.min(size.width, size.height) / 2.0;
    cornerRadius = cornerRadius.clamp(0.0, maxRadius);

    _shader.setFloat(index++, cornerRadius);

    // 16, 17: uScale (vec2) - Physical Scale (Includes DPR + Transforms)
    _shader.setFloat(index++, physicalScale.dx);
    _shader.setFloat(index++, physicalScale.dy);
  }
}
