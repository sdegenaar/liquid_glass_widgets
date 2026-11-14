import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/src/engine/internal/transform_tracking_repaint_boundary_mixin.dart';

/// A tracked render object whose composite-time update never succeeds: the
/// state a glass layer is in on the capture path, or before its matte exists.
class _RenderUnreconcilable extends RenderProxyBox
    with TransformTrackingRenderObjectMixin {
  int transformChanged = 0;
  int updateCalls = 0;
  int paints = 0;

  @override
  GeometryTransformTrackingLayer setUpLayer(Offset offset) =>
      super.setUpLayer(offset)
        ..updateAtComposite = () {
          updateCalls++;
          return false;
        };

  @override
  void paint(PaintingContext context, Offset offset) {
    paints++;
    super.paint(context, offset);
  }

  @override
  void onTransformChanged() {
    transformChanged++;
    markNeedsPaint();
  }
}

class _Unreconcilable extends SingleChildRenderObjectWidget {
  const _Unreconcilable({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderUnreconcilable();
}

/// `GeometryTransformTrackingLayer.addToScene` gives every tracked layer a
/// chance to reconcile at composite time. A layer that has nothing to update
/// returns false on every composite; that must not be mistaken for a move,
/// or the layer repaints, recomposites and repaints again on every frame for
/// as long as the app runs.
void main() {
  Widget at(Offset position, Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(
      children: [Positioned(left: position.dx, top: position.dy, child: child)],
    ),
  );

  testWidgets('a tracked layer whose composite update cannot succeed does not '
      'repaint every frame', (tester) async {
    await tester.pumpWidget(
      at(
        const Offset(10, 10),
        const _Unreconcilable(child: SizedBox(width: 50, height: 50)),
      ),
    );
    final ro = tester.renderObject<_RenderUnreconcilable>(
      find.byType(_Unreconcilable),
    );

    await tester.pump(const Duration(milliseconds: 16));
    final paints = ro.paints;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      ro.paints,
      paints,
      reason: 'nothing moved, so nothing is owed a repaint',
    );
    expect(ro.transformChanged, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a tracked layer that really moved still asks for a repaint', (
    tester,
  ) async {
    final position = ValueNotifier(const Offset(10, 10));
    await tester.pumpWidget(
      ValueListenableBuilder<Offset>(
        valueListenable: position,
        child: const _Unreconcilable(child: SizedBox(width: 50, height: 50)),
        builder: (context, value, child) => at(value, child!),
      ),
    );
    await tester.pump();
    final ro = tester.renderObject<_RenderUnreconcilable>(
      find.byType(_Unreconcilable),
    );

    final before = ro.transformChanged;
    position.value = const Offset(40, 25);
    await tester.pump();
    await tester.pump();
    expect(
      ro.transformChanged,
      greaterThan(before),
      reason: 'a move the layer could not follow must still repaint it',
    );
  });
}
