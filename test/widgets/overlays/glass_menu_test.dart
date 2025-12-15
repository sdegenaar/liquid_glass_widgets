import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('GlassMenu toggles and renders items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: Container(
                width: 50,
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Open Menu')),
              ),
              items: [
                GlassMenuItem(
                  title: 'Option 1',
                  onTap: () {},
                ),
                GlassMenuItem(
                  title: 'Option 2',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Initial state: Menu closed
    expect(find.text('Option 1'), findsNothing);

    // Tap trigger
    await tester.tap(find.text('Open Menu'));
    await tester.pump(); // Start animation
    await tester
        .pumpAndSettle(); // Wait for animation to complete (content appears at 65%+)

    // Menu should be present (portal shown)
    expect(find.text('Option 1'), findsOneWidget);

    // Close menu (tap outside)
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Menu closed
    expect(find.text('Option 1'), findsNothing);
  });

  testWidgets('GlassMenu works with triggerBuilder (interactive trigger)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              triggerBuilder: (context, toggle) => GlassButton.custom(
                onTap: toggle,
                useOwnLayer: true,
                child: const Text('Interactive Menu'),
              ),
              items: [
                GlassMenuItem(
                  title: 'Action',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Action'), findsNothing);

    await tester.tap(find.text('Interactive Menu'));
    await tester.pump();
    await tester.pumpAndSettle(); // Wait for animation to complete

    expect(find.text('Action'), findsOneWidget);
  });

  testWidgets('GlassMenu aligns correctly when on right side of screen',
      (WidgetTester tester) async {
    // Set a wide screen
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                right: 20,
                top: 20,
                child: GlassMenu(
                  trigger: const SizedBox(
                      width: 50, height: 50, child: Text('RightBtn')),
                  items: [
                    GlassMenuItem(title: 'RightItem', onTap: () {}),
                  ],
                  menuWidth: 200,
                ),
              )
            ],
          ),
        ),
      ),
    );

    // Open menu
    await tester.tap(find.text('RightBtn'));
    await tester.pump();
    await tester.pumpAndSettle(); // Wait for animation to complete

    // Verify 'RightItem' is visible
    expect(find.text('RightItem'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
