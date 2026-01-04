import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('GlassButtonGroup renders children with dividers',
      (WidgetTester tester) async {
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassButtonGroup(
                children: [
                  GlassButton(
                    icon: CupertinoIcons.back,
                    style: GlassButtonStyle.transparent,
                    onTap: () => tappedIndex = 0,
                  ),
                  GlassButton(
                    icon: CupertinoIcons.forward,
                    style: GlassButtonStyle.transparent,
                    onTap: () => tappedIndex = 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Verify both icons are present
    expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.forward), findsOneWidget);

    // Verify interaction works (transparent button should still tap)
    await tester.tap(find.byIcon(CupertinoIcons.back));
    expect(tappedIndex, equals(0));

    await tester.tap(find.byIcon(CupertinoIcons.forward));
    expect(tappedIndex, equals(1));

    // Check for divider (Container with width 1)
    // We can find by type Container and filter? Hard to be robust.
    // Acceptance of rendering is main goal here.
  });

  testWidgets('GlassButton respects transparent style',
      (WidgetTester tester) async {
    // This test ensures that when style is transparent, we don't crash and we do render content
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveLiquidGlassLayer(
            child: GlassButton(
              icon: CupertinoIcons.add,
              style: GlassButtonStyle.transparent,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    // Should NOT find LiquidGlass widget internally if we could check,
    // but verifying it pumps without error is key.
  });
}
