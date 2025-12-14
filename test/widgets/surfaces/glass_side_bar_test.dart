import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassSideBar', () {
    testWidgets('renders basic structure with header and footer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassSideBar(
              header: const Text('Header'),
              footer: const Text('Footer'),
              children: [
                GlassSideBarItem(
                  icon: Icons.home,
                  label: 'Home',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(GlassSideBarItem), findsOneWidget);
    });

    testWidgets('GlassSideBarItem handles selection state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassSideBar(
              children: [
                GlassSideBarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final item =
          tester.widget<GlassSideBarItem>(find.byType(GlassSideBarItem));
      expect(item.isSelected, isTrue);

      // Verify text style changes on selection (bold weight)
      final text = tester.widget<Text>(find.text('Settings'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('GlassSideBarItem triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassSideBar(
              children: [
                GlassSideBarItem(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassSideBarItem));
      expect(tapped, isTrue);
    });
  });
}
