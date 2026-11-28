import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// With a hardware keyboard (a Mac, an iPad), a focused slider moves one
/// step per arrow key and reports the change as Flutter's Slider does:
/// onChangeStart, onChanged, onChangeEnd.
void main() {
  final log = <String>[];

  Future<FocusNode> pumpSlider(
    WidgetTester tester, {
    TextDirection textDirection = TextDirection.ltr,
    bool enabled = true,
  }) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(CupertinoApp(
      home: Directionality(
        textDirection: textDirection,
        child: CupertinoPageScaffold(
          child: Center(
            child: SizedBox(
              width: 300,
              child: _Host(log: log, focusNode: focusNode, enabled: enabled),
            ),
          ),
        ),
      ),
    ));
    focusNode.requestFocus();
    await tester.pump();
    return focusNode;
  }

  setUp(log.clear);

  group('GlassSlider arrow keys', () {
    testWidgets('move it one step and report start, change and end',
        (tester) async {
      final focusNode = await pumpSlider(tester);
      expect(focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(log, ['start 0.50', 'changed 0.60', 'end 0.60']);

      log.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(log, ['start 0.60', 'changed 0.70', 'end 0.70']);

      log.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(log, [
        'start 0.70', 'changed 0.60', 'end 0.60', //
        'start 0.60', 'changed 0.50', 'end 0.50',
      ]);
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('right to left, the left arrow increases', (tester) async {
      await pumpSlider(tester, textDirection: TextDirection.rtl);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(log, ['start 0.50', 'changed 0.60', 'end 0.60']);

      log.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(log, ['start 0.60', 'changed 0.50', 'end 0.50']);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a disabled slider takes no focus and ignores the keys',
        (tester) async {
      final focusNode = await pumpSlider(tester, enabled: false);
      expect(focusNode.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(log, isEmpty);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });
}

/// A slider whose parent rebuilds it with each value it reports, and logs
/// the callbacks.
class _Host extends StatefulWidget {
  const _Host({
    required this.log,
    required this.focusNode,
    required this.enabled,
  });
  final List<String> log;
  final FocusNode focusNode;
  final bool enabled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  double value = 0.5;

  @override
  Widget build(BuildContext context) {
    String fixed(double v) => v.toStringAsFixed(2);
    return GlassSlider(
      value: value,
      label: 'Volume',
      focusNode: widget.focusNode,
      onChangeStart: (v) => widget.log.add('start ${fixed(v)}'),
      onChanged: widget.enabled
          ? (v) {
              widget.log.add('changed ${fixed(v)}');
              setState(() => value = v);
            }
          : null,
      onChangeEnd: (v) => widget.log.add('end ${fixed(v)}'),
    );
  }
}
