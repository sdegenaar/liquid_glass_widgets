import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassButtonGroup', () {
    testWidgets('renders children in horizontal direction by default',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: GlassButtonGroup(
              children: [
                GlassButton(
                  icon: const Icon(CupertinoIcons.add),
                  style: GlassButtonStyle.transparent,
                  onTap: () {},
                ),
                GlassButton(
                  icon: const Icon(CupertinoIcons.minus),
                  style: GlassButtonStyle.transparent,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GlassButtonGroup), findsOneWidget);
      expect(find.byType(GlassContainer), findsOneWidget);
      expect(find.byType(Flex), findsOneWidget);

      final Flex flex = tester.widget(find.byType(Flex));
      expect(flex.direction, Axis.horizontal);

      // Should find the two buttons
      expect(find.byType(GlassButton), findsNWidgets(2));

      // Should find the divider by default
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders children in vertical direction', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: GlassButtonGroup(
              direction: Axis.vertical,
              children: [
                GlassButton(
                  icon: const Icon(CupertinoIcons.add),
                  style: GlassButtonStyle.transparent,
                  onTap: () {},
                ),
                GlassButton(
                  icon: const Icon(CupertinoIcons.minus),
                  style: GlassButtonStyle.transparent,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final Flex flex = tester.widget(find.byType(Flex));
      expect(flex.direction, Axis.vertical);
    });

    testWidgets('suppresses dividers when showDividers is false',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: GlassButtonGroup(
              showDividers: false,
              children: [
                GlassButton(
                  icon: const Icon(CupertinoIcons.add),
                  style: GlassButtonStyle.transparent,
                  onTap: () {},
                ),
                GlassButton(
                  icon: const Icon(CupertinoIcons.minus),
                  style: GlassButtonStyle.transparent,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // In children mode with showDividers: false, no Container dividers should be added
      // Note: children might contain containers natively but the explicit divider is a Container with width/height 1
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasDivider = containers.any((c) =>
          (c.constraints?.maxWidth == 1.0) ||
          (c.constraints?.maxHeight == 1.0));
      expect(hasDivider, isFalse);
    });
  });

  group('GlassButtonGroup.icons', () {
    testWidgets('renders lightweight items properly', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: GlassButtonGroup.icons(
              items: [
                GlassGroupItem(
                  icon: const Icon(CupertinoIcons.bold),
                  onTap: () => tapCount++,
                  label: 'Bold',
                ),
                GlassGroupItem(
                  icon: const Icon(CupertinoIcons.italic),
                  onTap: () {},
                  enabled: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GlassButtonGroup), findsOneWidget);
      // It should wrap in a GlassButton.custom
      expect(find.byType(GlassButton), findsOneWidget);

      // Should find the icons
      expect(find.byIcon(CupertinoIcons.bold), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.italic), findsOneWidget);

      // Should find semantics
      expect(find.bySemanticsLabel('Bold'), findsOneWidget);

      // Tap the first item
      await tester.tap(find.byIcon(CupertinoIcons.bold));
      expect(tapCount, 1);

      // Tap the disabled item (should not trigger anything or crash)
      await tester.tap(find.byIcon(CupertinoIcons.italic));
      // Handled internally by ignoring taps on disabled
    });

    testWidgets('renders lightweight items with dividers if enabled',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: GlassButtonGroup.icons(
              showDividers: true,
              direction: Axis.vertical,
              items: [
                GlassGroupItem(
                  icon: const Icon(CupertinoIcons.bold),
                  onTap: () {},
                ),
                GlassGroupItem(
                  icon: const Icon(CupertinoIcons.italic),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasDivider = containers.any((c) => c.constraints?.maxHeight == 1.0);
      expect(hasDivider, isTrue);
    });
  });
}
