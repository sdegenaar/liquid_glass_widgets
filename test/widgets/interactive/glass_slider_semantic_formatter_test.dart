import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A screen reader reads the slider's value, and the value it moves to on
/// an increment or decrement. A percentage of the range means nothing for a
/// speed of 0.5x to 2x, so the app formats the value, as with Flutter's
/// `Slider.semanticFormatterCallback`.
void main() {
  Widget speed({String Function(double value)? format}) => CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: SizedBox(
              width: 300,
              child: GlassSlider(
                value: 1.0,
                min: 0.5,
                max: 2.0,
                label: 'Speed',
                onChanged: (_) {},
                semanticFormatterCallback: format,
              ),
            ),
          ),
        ),
      );

  group('GlassSlider.semanticFormatterCallback', () {
    testWidgets('formats the value and the values an adjustment reaches',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(speed(format: (v) => '${v.toStringAsFixed(2)}x'));

      final data = tester
          .getSemantics(find.bySemanticsLabel('Speed'))
          .getSemanticsData();
      expect(data.value, '1.00x');
      expect(data.increasedValue, '1.15x');
      expect(data.decreasedValue, '0.85x');
      handle.dispose();
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('without it the value is a percentage of the range',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(speed());

      final data = tester
          .getSemantics(find.bySemanticsLabel('Speed'))
          .getSemanticsData();
      expect(data.value, '33%');
      expect(data.increasedValue, '43%');
      expect(data.decreasedValue, '23%');
      handle.dispose();
    });
  });

  testWidgets('has no English default name', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: SizedBox(
              width: 300,
              child: GlassSlider(value: 0.5, onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );

    // The slider's own node: the one that carries its value.
    SemanticsData? slider;
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      if (data.hasFlag(SemanticsFlag.isSlider)) slider = data;
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    expect(slider, isNotNull, reason: 'the slider is its own element');
    expect(slider!.label, isEmpty);
    expect(slider!.value, '50%');
    handle.dispose();
  });
}
