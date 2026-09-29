import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('descendants share one key; none outside a group',
      (tester) async {
    BackdropKey? a, b, outside;
    await tester.pumpWidget(Column(
      children: [
        GlassBackdropGroup(
          child: Column(children: [
            Builder(builder: (context) {
              a = GlassBackdropGroup.keyOf(context);
              return const SizedBox();
            }),
            Builder(builder: (context) {
              b = GlassBackdropGroup.keyOf(context);
              return const SizedBox();
            }),
          ]),
        ),
        Builder(builder: (context) {
          outside = GlassBackdropGroup.keyOf(context);
          return const SizedBox();
        }),
      ],
    ));
    expect(a, isNotNull);
    expect(identical(a, b), isTrue);
    expect(outside, isNull);
  });

  testWidgets('the key survives rebuilds', (tester) async {
    BackdropKey? first, second;
    Widget app() => GlassBackdropGroup(
          child: Builder(builder: (context) {
            first ??= GlassBackdropGroup.keyOf(context);
            second = GlassBackdropGroup.keyOf(context);
            return const SizedBox();
          }),
        );
    await tester.pumpWidget(app());
    await tester.pumpWidget(app());
    expect(identical(first, second), isTrue);
  });
}
