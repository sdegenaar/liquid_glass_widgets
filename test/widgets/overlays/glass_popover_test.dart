import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('GlassPopover opens on trigger tap and shows content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              trigger: Container(
                width: 50,
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Open')),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Popover Content'),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state: Popover closed
    expect(find.text('Popover Content'), findsNothing);

    // Tap trigger
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Popover content should be present
    expect(find.text('Popover Content'), findsOneWidget);
  });

  testWidgets('GlassPopover closes on barrier tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              trigger: const SizedBox(
                width: 50,
                height: 50,
                child: Text('Open'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Content'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open popover
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsOneWidget);

    // Tap outside (barrier)
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pumpAndSettle();

    // Popover closed
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('GlassPopover close callback from contentBuilder works',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              popoverHeight: 150,
              trigger: const SizedBox(
                width: 50,
                height: 50,
                child: Text('Open'),
              ),
              contentBuilder: (context, close) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Content'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: close,
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Open
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsOneWidget);

    // Tap the Done button (uses close callback)
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Popover closed
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('GlassPopover triggerBuilder provides working toggle callback',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              triggerBuilder: (context, toggle) => GlassButton.custom(
                onTap: toggle,
                useOwnLayer: true,
                child: const Text('Interactive'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Builder Content'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Builder Content'), findsNothing);

    await tester.tap(find.text('Interactive'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Builder Content'), findsOneWidget);
  });

  testWidgets(
      'GlassPopover closes when tapping trigger area (barrier intercepts)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              trigger: const SizedBox(
                width: 60,
                height: 40,
                child: Text('Toggle'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Toggle Content'),
              ),
            ),
          ),
        ),
      ),
    );

    // First tap — opens
    await tester.tap(find.text('Toggle'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Toggle Content'), findsOneWidget);

    // Tap outside to close (barrier intercepts)
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Toggle Content'), findsNothing);
  });

  testWidgets('GlassPopover onClose fires when closing',
      (WidgetTester tester) async {
    int closeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              onClose: () => closeCalls++,
              trigger: const SizedBox(
                width: 60,
                height: 40,
                child: Text('Open'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Closeable'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(closeCalls, 0);

    // Close via barrier tap
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(closeCalls, 1);
  });

  testWidgets('GlassPopover onOpen fires when opening',
      (WidgetTester tester) async {
    int openCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              onOpen: () => openCalls++,
              trigger: const SizedBox(
                width: 60,
                height: 40,
                child: Text('Open'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Content'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(openCalls, 0);

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(openCalls, 1);
  });

  testWidgets('GlassPopover at bottom of screen flips vertical alignment',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                bottom: 10,
                left: 20,
                child: GlassPopover(
                  trigger: const SizedBox(
                    width: 60,
                    height: 40,
                    child: Text('BottomPopover'),
                  ),
                  contentBuilder: (context, close) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Flipped Content'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('BottomPopover'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Flipped Content'), findsOneWidget);
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('GlassPopover on right side of screen aligns correctly',
      (WidgetTester tester) async {
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
                child: GlassPopover(
                  trigger: const SizedBox(
                    width: 50,
                    height: 50,
                    child: Text('RightBtn'),
                  ),
                  contentBuilder: (context, close) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Right Content'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('RightBtn'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Right Content'), findsOneWidget);
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('GlassPopover with explicit popoverHeight constrains content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              popoverHeight: 200,
              popoverWidth: 200,
              trigger: const SizedBox(
                width: 50,
                height: 50,
                child: Text('Open'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Constrained'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Constrained'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GlassPopover with explicit alignment',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              alignment: GlassMenuAlignment.bottomCenter,
              trigger: const SizedBox(
                width: 60,
                height: 40,
                child: Text('Aligned'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bottom Center'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aligned'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Bottom Center'), findsOneWidget);
  });

  testWidgets('GlassPopover autoAdjustToScreen does not crash at screen edge',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: GlassPopover(
              autoAdjustToScreen: true,
              screenPadding: const EdgeInsets.all(12),
              trigger: const SizedBox(
                width: 60,
                height: 40,
                child: Text('EdgePopover'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Edge Content'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('EdgePopover'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Edge Content'), findsOneWidget);
    expect(tester.takeException(), isNull);
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('GlassPopover onClose not called when not provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassPopover(
              trigger: const SizedBox(
                width: 60,
                height: 40,
                child: Text('NoCallback'),
              ),
              contentBuilder: (context, close) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('SafeContent'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('NoCallback'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Close — must not throw
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('GlassPopover asserts when neither trigger nor triggerBuilder provided',
      () {
    expect(
      () => GlassPopover(
        contentBuilder: (context, close) => const Text('Test'),
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('GlassPopover default values', () {
    final popover = GlassPopover(
      trigger: const SizedBox(width: 40, height: 40),
      contentBuilder: (context, close) => const Text('Test'),
    );

    expect(popover.popoverWidth, 280);
    expect(popover.popoverHeight, isNull);
    expect(popover.popoverBorderRadius, 24.0);
    expect(popover.alignment, isNull);
    expect(popover.autoAdjustToScreen, isTrue);
    expect(popover.barrierDismissible, isTrue);
    expect(popover.stretch, 0.3);
    expect(popover.interactionScale, 1.02);
    expect(popover.stretchResistance, 0.08);
    expect(popover.enableInteractionGlow, isTrue);
    expect(popover.glowOnTapOnly, isTrue);
    expect(popover.glowRadius, 0.6);
    expect(popover.glowIntensity, 0.0);
    expect(popover.onClose, isNull);
    expect(popover.onOpen, isNull);
  });
}
