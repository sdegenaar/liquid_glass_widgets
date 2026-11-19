// A chip without a handler is drawn disabled only by default; `enabled: true`
// draws it at full strength. Either way it is inert and read as text, not as
// a button.
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> _pump(WidgetTester t, GlassChip chip) => t.pumpWidget(
      CupertinoApp(home: Center(child: chip)),
    );

void main() {
  testWidgets('enabled follows the handlers unless given', (t) async {
    await _pump(t, const GlassChip(label: 'Info'));
    expect(t.widget<GlassButton>(find.byType(GlassButton)).enabled, isFalse);
    await _pump(t, const GlassChip(label: 'Info', enabled: true));
    expect(t.widget<GlassButton>(find.byType(GlassButton)).enabled, isTrue);
    await _pump(t, GlassChip(label: 'Tap', onTap: () {}));
    expect(t.widget<GlassButton>(find.byType(GlassButton)).enabled, isTrue);
  });

  testWidgets('a chip without a handler is text, not a button', (t) async {
    final handle = t.ensureSemantics();
    await _pump(t, const GlassChip(label: 'Info', enabled: true));
    final data =
        t.getSemantics(find.bySemanticsLabel('Info')).getSemanticsData();
    expect(data.flagsCollection.isButton, isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    await _pump(t, GlassChip(label: 'Tap', onTap: () {}));
    expect(
      t.getSemantics(find.bySemanticsLabel('Tap')).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
      isTrue,
    );
    handle.dispose();
  });
}
