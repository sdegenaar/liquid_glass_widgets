import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/src/widgets/overlays/overlay_semantics_host.dart';

void main() {
  group('OverlaySemanticsHost', () {
    SemanticsConfiguration describe(RenderOverlaySemanticsHost host) {
      final config = SemanticsConfiguration();
      host.describeSemanticsConfiguration(config);
      return config;
    }

    Widget host({bool? enabled}) => Directionality(
      textDirection: TextDirection.ltr,
      child: enabled == null
          ? const OverlaySemanticsHost(child: SizedBox())
          : OverlaySemanticsHost(enabled: enabled, child: const SizedBox()),
    );

    testWidgets('is enabled by default', (tester) async {
      await tester.pumpWidget(host());
      final render = tester.renderObject<RenderOverlaySemanticsHost>(
        find.byType(OverlaySemanticsHost),
      );

      expect(render.enabled, isTrue);
      expect(describe(render).childConfigurationsDelegate, isNotNull);
    });

    testWidgets('toggling enabled updates the render object in place', (
      tester,
    ) async {
      await tester.pumpWidget(host(enabled: true));
      final render = tester.renderObject<RenderOverlaySemanticsHost>(
        find.byType(OverlaySemanticsHost),
      );

      await tester.pumpWidget(host(enabled: false));
      expect(
        tester.renderObject(find.byType(OverlaySemanticsHost)),
        same(render),
      );
      expect(render.enabled, isFalse);
      expect(describe(render).childConfigurationsDelegate, isNull);

      await tester.pumpWidget(host(enabled: true));
      expect(render.enabled, isTrue);
      expect(describe(render).childConfigurationsDelegate, isNotNull);
    });

    test('the delegate puts child configurations in a sibling merge group', () {
      final render = RenderOverlaySemanticsHost(enabled: true);
      final delegate = describe(render).childConfigurationsDelegate!;
      final child = SemanticsConfiguration()..label = 'child';

      final result = delegate([child]);
      expect(result.siblingMergeGroups, [
        [child],
      ]);
      expect(result.mergeUp, isEmpty);

      final empty = delegate(const []);
      expect(empty.siblingMergeGroups, isEmpty);
      expect(empty.mergeUp, isEmpty);
    });
  });
}
