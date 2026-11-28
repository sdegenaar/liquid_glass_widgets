import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// An app that saves the value in onChangeEnd (as a drag invites) must get
/// every change there: a screen-reader adjustment, and the last value of a
/// drag, as Flutter's Slider reports them.
void main() {
  final log = <String>[];

  Widget slider() => CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: SizedBox(width: 300, child: _Host(log: log)),
          ),
        ),
      );

  setUp(log.clear);

  group('GlassSlider change callbacks', () {
    testWidgets(
        'a screen-reader increment or decrement reports start, change and '
        'end', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(slider());

      tester.semantics.performAction(
          find.semantics.byLabel('Volume'), SemanticsAction.increase);
      await tester.pump();
      expect(log, ['start 0.50', 'changed 0.60', 'end 0.60']);

      log.clear();
      tester.semantics.performAction(
          find.semantics.byLabel('Volume'), SemanticsAction.decrease);
      await tester.pump();
      expect(log, ['start 0.60', 'changed 0.50', 'end 0.50']);
      handle.dispose();
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets(
        'onChangeEnd gets the last value of a drag even before the slider '
        'rebuilt with it', (tester) async {
      await tester.pumpWidget(slider());
      final center = tester.getCenter(find.byType(GlassSlider));

      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      // The last move and the lift arrive with no frame in between.
      await gesture.moveBy(const Offset(20, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      final changes = log.where((e) => e.startsWith('changed')).toList();
      expect(changes, hasLength(greaterThanOrEqualTo(2)));
      expect(log.last, 'end ${changes.last.split(' ').last}');
    });
  });
}

/// A slider whose parent rebuilds it with each value it reports, and logs
/// the callbacks.
class _Host extends StatefulWidget {
  const _Host({required this.log});
  final List<String> log;

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
      onChangeStart: (v) => widget.log.add('start ${fixed(v)}'),
      onChanged: (v) {
        widget.log.add('changed ${fixed(v)}');
        setState(() => value = v);
      },
      onChangeEnd: (v) => widget.log.add('end ${fixed(v)}'),
    );
  }
}
