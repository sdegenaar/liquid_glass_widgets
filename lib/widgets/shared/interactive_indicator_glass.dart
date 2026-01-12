// ignore_for_file: require_trailing_commas

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/scheduler.dart';
import '../../widgets/interactive/liquid_glass_scope.dart';
import 'inherited_liquid_glass.dart';

import '../../types/glass_quality.dart';
import 'lightweight_liquid_glass.dart';

/// Enhanced glass renderer specifically for interactive indicators.
///
/// Uses a specialized shader on Skia/Web to match Impeller's visual quality
/// with magnification effects, enhanced rim lighting, and radial brightness.
///
/// On Impeller with premium quality, it uses the native LiquidGlass renderer.
/// On Skia/Web or standard quality, it uses the enhanced InteractiveIndicator
/// shader with magnification and structural rim effects.
class InteractiveIndicatorGlass extends StatefulWidget {
  const InteractiveIndicatorGlass({
    required this.shape,
    required this.settings,
    required this.interactionIntensity,
    required this.child,
    this.quality = GlassQuality.standard,
    this.backgroundKey,
    super.key,
  });

  final Widget child;
  final LiquidShape shape;
  final LiquidGlassSettings settings;
  final GlassQuality quality;

  /// GlobalKey of a RepaintBoundary wrapping the background content.
  /// Used for Skia/Web background sampling.
  final GlobalKey? backgroundKey;

  /// Interaction intensity (0.0 = resting, 1.0 = fully active)
  /// Drives magnification and enhancement effects
  final double interactionIntensity;

  static ui.FragmentProgram? _cachedProgram;
  static bool _isPreparing = false;

  /// Detects if Impeller rendering engine is active
  static bool get _canUseImpeller => ui.ImageFilter.isShaderFilterSupported;

  static ui.Image? _dummyImage;

  static Future<void> preWarm() async {
    if (_cachedProgram != null || _isPreparing) return;
    _isPreparing = true;
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'packages/liquid_glass_widgets/shaders/interactive_indicator.frag',
      );
      _cachedProgram = program;

      if (!kIsWeb) {
        debugPrint('[InteractiveIndicatorGlass] ✓ Shader precached (native)');
      } else {
        debugPrint('[InteractiveIndicatorGlass] ✓ Shader program loaded (web)');
      }

      // Create a 1x1 transparent dummy image to satisfy sampler index 0
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0x00000000), BlendMode.src);
      final picture = recorder.endRecording();
      _dummyImage = await picture.toImage(1, 1);
    } catch (e) {
      debugPrint('[InteractiveIndicatorGlass] Pre-warm failed: $e');
    } finally {
      _isPreparing = false;
    }
  }

  @override
  State<InteractiveIndicatorGlass> createState() =>
      _InteractiveIndicatorGlassState();
}

class _InteractiveIndicatorGlassState extends State<InteractiveIndicatorGlass>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _localShader;
  bool _loggedCreation = false;
  ui.Image? _backgroundImage;
  late Ticker _ticker;
  bool _isCapturing = false;
  int _lastCaptureTime = 0;

  @override
  void initState() {
    super.initState();
    final bool useNativeRenderer = !kIsWeb &&
        InteractiveIndicatorGlass._canUseImpeller &&
        widget.quality == GlassQuality.premium;

    if (!useNativeRenderer) {
      _initShader();
    }

    _ticker = createTicker(_handleTick);
    _updateTicker();
  }

  @override
  void didUpdateWidget(covariant InteractiveIndicatorGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quality != widget.quality) {
      final bool useNativeRenderer = !kIsWeb &&
          InteractiveIndicatorGlass._canUseImpeller &&
          widget.quality == GlassQuality.premium;

      if (!useNativeRenderer && _activeShader == null) {
        _initShader();
      }
    }
    _updateTicker();
  }

  GlobalKey? _cachedScopeKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedScopeKey = LiquidGlassScope.of(context);
    _updateTicker();
  }

  GlobalKey? get _effectiveKey => widget.backgroundKey ?? _cachedScopeKey;

  void _updateTicker() {
    final bool shouldCapture =
        widget.interactionIntensity > 0.01 && _effectiveKey != null;
    if (shouldCapture) {
      if (!_ticker.isActive) {
        _ticker.start();
        debugPrint(
            '[InteractiveIndicatorGlass] 📸 Starting capture loop. Intensity: ${widget.interactionIntensity.toStringAsFixed(2)}');
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
        _backgroundImage?.dispose();
        _backgroundImage = null;
        debugPrint(
            '[InteractiveIndicatorGlass] 📸 Interaction finished, cleared snapshot.');
      }
    }
  }

  void _handleTick(Duration elapsed) {
    if (_isCapturing) return;

    // Only capture a few frames to get a stable background without flickering.
    // We capture on first frame and then every 200ms to stay relatively 'live'
    // without the 60fps thrashing.
    final now = DateTime.now().millisecondsSinceEpoch;
    const int captureIntervalMs = 200; // Capture every 200ms

    if (_backgroundImage == null ||
        (now - _lastCaptureTime) > captureIntervalMs) {
      _captureBackground();
      _lastCaptureTime = now;
    }
  }

  Future<void> _captureBackground() async {
    final key = _effectiveKey;
    if (key == null || !mounted) return;

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    _isCapturing = true;
    final dpr = View.of(context).devicePixelRatio;

    try {
      final image = await boundary.toImage(pixelRatio: dpr);
      if (mounted) {
        setState(() {
          _backgroundImage?.dispose();
          _backgroundImage = image;
        });
      }
    } catch (e) {
      // Intentionally ignore capture errors to prevent log spam
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _initShader() async {
    if (InteractiveIndicatorGlass._cachedProgram == null) {
      await InteractiveIndicatorGlass.preWarm();
    }

    if (InteractiveIndicatorGlass._cachedProgram != null) {
      if (mounted) {
        setState(() {
          // Always create a local shader instance for state isolation
          _localShader =
              InteractiveIndicatorGlass._cachedProgram!.fragmentShader();
          if (!_loggedCreation) {
            debugPrint(
                '[InteractiveIndicatorGlass] ✓ Created unique shader instance for ${widget.shape.runtimeType}');
            _loggedCreation = true;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _backgroundImage?.dispose();
    _localShader?.dispose();
    _localShader = null;
    super.dispose();
  }

  ui.FragmentShader? get _activeShader {
    // We only return the shader if the dummy image is ready,
    // to prevent "missing sampler" build errors.
    if (InteractiveIndicatorGlass._dummyImage == null) return null;
    return _localShader;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detect Environment & Constraints
    final bool isImpeller =
        !kIsWeb && InteractiveIndicatorGlass._canUseImpeller;
    final bool avoidsRefraction = context
            .dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>()
            ?.avoidsRefraction ??
        false;

    // 2. Resolve the background refraction source
    final effectiveKey = widget.backgroundKey ?? LiquidGlassScope.of(context);
    final shader = _activeShader;

    // 3. Selection Logic:
    // We use the High-Fidelity Refraction Shader (InteractiveIndicatorEffect)
    // if we have a background to refract and aren't explicitly avoiding
    // refraction (e.g. nested inside a GlassCard).

    final bool canUseRefraction = effectiveKey != null && !avoidsRefraction;

    // Path A: Native Impeller (Premium only)
    // On platforms with Impeller, "Premium" uses the native engine for best performance.
    // CRITICAL: We only use native if NOT nested (!avoidsRefraction) to prevent
    // rendering conflicts between the native pipeline and our custom shaders.
    if (isImpeller &&
        widget.quality == GlassQuality.premium &&
        !avoidsRefraction) {
      return LiquidGlass.withOwnLayer(
        shape: widget.shape,
        settings: widget.settings,
        fake: false,
        child: widget.child,
      );
    }

    // Path B: High-Fidelity Refraction Shader (Custom GLSL)
    // This is the "New Shader" featuring magnification and liquid distortion.
    // We use this as the primary path for Standard quality, or when Impeller is unavailable.
    if (canUseRefraction && shader != null) {
      return ClipPath(
        clipper: ShapeBorderClipper(shape: widget.shape),
        child: _InteractiveIndicatorEffect(
          shader: shader,
          settings: widget.settings,
          shape: widget.shape,
          interactionIntensity: widget.interactionIntensity,
          backgroundImage: _backgroundImage,
          backgroundKey: effectiveKey,
          devicePixelRatio: View.of(context).devicePixelRatio,
          child: widget.child,
        ),
      );
    }

    // Path C: Lightweight Fallback (Standard Quality or Nested Glass)
    // We disable the blur for nested glass to avoid the "hall of mirrors" flickering
    // caused by nested BackdropFilters on many platforms.
    return LightweightLiquidGlass(
      shape: widget.shape,
      settings: widget.settings.copyWith(blur: 0),
      child: widget.child,
    );
  }
}

class _InteractiveIndicatorEffect extends SingleChildRenderObjectWidget {
  const _InteractiveIndicatorEffect({
    required this.shader,
    required this.settings,
    required this.shape,
    required this.interactionIntensity,
    this.backgroundImage,
    this.backgroundKey,
    required this.devicePixelRatio,
    required super.child,
  });

  final ui.FragmentShader shader;
  final LiquidGlassSettings settings;
  final LiquidShape shape;
  final double interactionIntensity;
  final ui.Image? backgroundImage;
  final GlobalKey? backgroundKey;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderInteractiveIndicator(
      shader: shader,
      settings: settings,
      shape: shape,
      interactionIntensity: interactionIntensity,
      backgroundImage: backgroundImage,
      backgroundKey: backgroundKey,
      devicePixelRatio: devicePixelRatio,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderInteractiveIndicator renderObject,
  ) {
    renderObject
      ..shader = shader
      ..settings = settings
      ..shape = shape
      ..interactionIntensity = interactionIntensity
      ..backgroundImage = backgroundImage
      ..backgroundKey = backgroundKey
      ..devicePixelRatio = devicePixelRatio;
  }
}

class _RenderInteractiveIndicator extends RenderProxyBox {
  _RenderInteractiveIndicator({
    required ui.FragmentShader shader,
    required LiquidGlassSettings settings,
    required LiquidShape shape,
    required double interactionIntensity,
    ui.Image? backgroundImage,
    GlobalKey? backgroundKey,
    required double devicePixelRatio,
  })  : _shader = shader,
        _settings = settings,
        _shape = shape,
        _interactionIntensity = interactionIntensity,
        _backgroundImage = backgroundImage,
        _backgroundKey = backgroundKey,
        _devicePixelRatio = devicePixelRatio;

  ui.FragmentShader _shader;
  set shader(ui.FragmentShader value) {
    if (_shader == value) return;
    _shader = value;
    markNeedsPaint();
  }

  LiquidGlassSettings _settings;
  set settings(LiquidGlassSettings value) {
    if (_settings == value) return;
    _settings = value;
    markNeedsPaint();
  }

  LiquidShape _shape;
  set shape(LiquidShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  double _interactionIntensity;
  set interactionIntensity(double value) {
    if (_interactionIntensity == value) return;
    _interactionIntensity = value;
    markNeedsPaint();
  }

  ui.Image? _backgroundImage;
  set backgroundImage(ui.Image? value) {
    if (_backgroundImage == value) return;
    _backgroundImage = value;
    markNeedsPaint();
  }

  GlobalKey? _backgroundKey;
  set backgroundKey(GlobalKey? value) {
    if (_backgroundKey == value) return;
    _backgroundKey = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final blurSigma = _settings.effectiveBlur;
      if (blurSigma > 0) {
        context.pushLayer(
          BackdropFilterLayer(
            filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          ),
          (context, offset) {
            _paintGlassContent(context, offset);
          },
          offset,
        );
      } else {
        _paintGlassContent(context, offset);
      }
    }
  }

  void _paintGlassContent(PaintingContext context, Offset offset) {
    // 1. Paint Child content (glow etc)
    super.paint(context, offset);

    // 2. Prepare shader uniforms
    final canvas = context.canvas;
    final matrix = canvas.getTransform();

    final canvasPhysicalX = matrix[12];
    final canvasPhysicalY = matrix[13];
    final scaleX = matrix[0];
    final scaleY = matrix[5];

    final physicalOrigin = Offset(
      canvasPhysicalX + (offset.dx * scaleX),
      canvasPhysicalY + (offset.dy * scaleY),
    );

    // Keep uScale from canvas for shape calculations
    final uScale = Offset(scaleX, scaleY);

    // Relative Offset Mapping - ALL IN LOGICAL PIXELS
    Offset bgRelativeOffset = Offset.zero;
    Size bgSize = const Size(1, 1);

    if (_backgroundKey != null && _backgroundImage != null) {
      final boundary = _backgroundKey!.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        // Get screen positions (localToGlobal gives logical coords)
        final bgGlobalPos = boundary.localToGlobal(Offset.zero);
        final indGlobalPos = localToGlobal(Offset.zero);

        // Keep in LOGICAL pixels (don't multiply by DPR)
        bgRelativeOffset = indGlobalPos - bgGlobalPos;

        // Convert texture size from physical to LOGICAL pixels
        bgSize = Size(
          _backgroundImage!.width / _devicePixelRatio,
          _backgroundImage!.height / _devicePixelRatio,
        );
      }
    }

    _updateShaderUniforms(
        size, physicalOrigin, uScale, bgRelativeOffset, bgSize);

    // 3. Set Sampler
    final imageToBind =
        _backgroundImage ?? InteractiveIndicatorGlass._dummyImage;
    if (imageToBind != null) {
      _shader.setImageSampler(0, imageToBind);
    }

    // 4. Paint shader overlay
    final paint = Paint()..shader = _shader;
    canvas.drawRect(offset & size, paint);
  }

  void _updateShaderUniforms(Size size, Offset physicalOrigin,
      Offset physicalScale, Offset bgOrigin, Size bgSize) {
    int index = 0;
    _shader.setFloat(index++, size.width);
    _shader.setFloat(index++, size.height);
    _shader.setFloat(index++, physicalOrigin.dx);
    _shader.setFloat(index++, physicalOrigin.dy);

    final color = _settings.effectiveGlassColor;
    _shader.setFloat(index++, (color.r * 255.0).round().clamp(0, 255) / 255.0);
    _shader.setFloat(index++, (color.g * 255.0).round().clamp(0, 255) / 255.0);
    _shader.setFloat(index++, (color.b * 255.0).round().clamp(0, 255) / 255.0);
    _shader.setFloat(index++, (color.a * 255.0).round().clamp(0, 255) / 255.0);

    _shader.setFloat(index++, _settings.effectiveThickness);
    _shader.setFloat(index++, _settings.lightAngle * 3.14159265359 / 180.0);
    _shader.setFloat(index++, _settings.effectiveLightIntensity);
    _shader.setFloat(index++, _settings.effectiveAmbientStrength);
    _shader.setFloat(index++, _settings.effectiveSaturation);
    _shader.setFloat(index++, _settings.refractiveIndex);
    _shader.setFloat(index++, (_settings.chromaticAberration).clamp(0.0, 1.0));

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

    _shader.setFloat(index++, physicalScale.dx);
    _shader.setFloat(index++, physicalScale.dy);
    _shader.setFloat(index++, 0.0); // uGlowIntensity
    _shader.setFloat(index++, 0.0); // uDensityFactor
    _shader.setFloat(index++, _interactionIntensity.clamp(0.0, 1.0));

    // Background Mapping Uniforms
    _shader.setFloat(index++, bgOrigin.dx);
    _shader.setFloat(index++, bgOrigin.dy);
    _shader.setFloat(index++, bgSize.width);
    _shader.setFloat(index++, bgSize.height);
    _shader.setFloat(index++, _backgroundImage != null ? 1.0 : 0.0);
  }
}
