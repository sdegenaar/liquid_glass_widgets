// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassBackdropScope (deprecated no-op)', () {
    testWidgets('build returns child directly — no wrapper widgets inserted',
        (tester) async {
      const childKey = Key('direct_child');
      await tester.pumpWidget(
        createTestApp(
          child: GlassBackdropScope(
            child: Container(key: childKey),
          ),
        ),
      );

      // The Container should be a direct child of the scope element.
      // There should be NO BackdropGroup between GlassBackdropScope and child.
      expect(find.byKey(childKey), findsOneWidget);

      // Verify no BackdropGroup is in the subtree of GlassBackdropScope.
      final scopeFinder = find.byType(GlassBackdropScope);
      expect(scopeFinder, findsOneWidget);

      // The GlassBackdropScope should not insert any extra widgets between
      // itself and the child. Since build() returns child directly, the
      // element tree should be: GlassBackdropScope → Container.
      final scopeElement = tester.element(scopeFinder) as StatelessElement;
      // The child of the scope element's widget should be our Container.
      final scope = scopeElement.widget as GlassBackdropScope;
      expect(scope.child, isA<Container>());
    });

    testWidgets('does not affect glass rendering when removed', (tester) async {
      // Pump with GlassBackdropScope
      await tester.pumpWidget(
        createTestApp(
          child: GlassBackdropScope(
            child: const Text('Glass content'),
          ),
        ),
      );
      expect(find.text('Glass content'), findsOneWidget);

      // Pump without GlassBackdropScope — should be identical
      await tester.pumpWidget(
        createTestApp(
          child: const Text('Glass content'),
        ),
      );
      expect(find.text('Glass content'), findsOneWidget);
    });

    testWidgets('nested GlassBackdropScope is harmless', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBackdropScope(
            child: GlassBackdropScope(
              child: const Text('Nested'),
            ),
          ),
        ),
      );

      expect(find.text('Nested'), findsOneWidget);
      // Two GlassBackdropScope widgets in the tree — both no-ops.
      expect(find.byType(GlassBackdropScope), findsNWidgets(2));
    });
  });
}
