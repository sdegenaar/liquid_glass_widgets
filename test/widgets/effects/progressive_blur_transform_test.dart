import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/effects/progressive_blur.dart';

/// Hosts the shader-path render object directly: the widget only builds it
/// when `ImageFilter.isShaderFilterSupported`, which the headless test backend
/// never reports, so the fallback would be mounted instead.
class _Host extends SingleChildRenderObjectWidget {
  const _Host({required this.program, super.child});

  final ui.FragmentProgram program;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderProgressiveBlur(
        hShader: program.fragmentShader(),
        vShader: program.fragmentShader(),
        maxSigma: 12,
        falloff: 1,
        direction: ProgressiveBlurDirection.topToBottom,
        devicePixelRatio: 1,
      );
}

/// The blur bakes its region into shader uniforms at paint time. An animated
/// ancestor over a repaint boundary (a route transition) moves the boundary's
/// retained layer without repainting the blur, so the baked region must be
/// refreshed when the move is noticed while compositing.
///
/// `ImageFilter.shader` needs Impeller, so these run only under
/// `flutter test --enable-impeller` and are skipped otherwise.
void main() {
  final skip = !ui.ImageFilter.isShaderFilterSupported;
  late ui.FragmentProgram program;

  setUp(() async {
    program = await ui.FragmentProgram.fromAsset(
      'shaders/progressive_blur.frag',
    );
  });

  Widget app(double dy, {Widget? child}) => Directionality(
    textDirection: TextDirection.ltr,
    child: Transform.translate(
      offset: Offset(0, dy),
      child: RepaintBoundary(
        child: SizedBox(
          width: 200,
          height: 96,
          child: _Host(program: program, child: child),
        ),
      ),
    ),
  );

  testWidgets('repaints when an ancestor moves the retained layer', (
    tester,
  ) async {
    await tester.pumpWidget(app(300, child: const SizedBox.expand()));
    final blur = tester.renderObject<RenderBox>(find.byType(_Host));
    expect(blur.debugNeedsPaint, isFalse);

    // Only the Transform repaints; the RepaintBoundary reuses its layer.
    await tester.pumpWidget(app(0, child: const SizedBox.expand()));
    expect(
      blur.debugNeedsPaint,
      isTrue,
      reason: 'the blur still holds the origin from the offset paint',
    );

    await tester.pump();
    expect(blur.debugNeedsPaint, isFalse);
  }, skip: skip);

  testWidgets('does not repaint while nothing moves', (tester) async {
    await tester.pumpWidget(app(300, child: const SizedBox.expand()));
    final blur = tester.renderObject<RenderBox>(find.byType(_Host));

    await tester.pump();
    await tester.pump();
    expect(blur.debugNeedsPaint, isFalse);
  }, skip: skip);

  testWidgets('paints without a child', (tester) async {
    await tester.pumpWidget(app(300));
    await tester.pumpWidget(app(0));
    await tester.pump();

    expect(tester.takeException(), isNull);
  }, skip: skip);
}
