import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  // ===========================================================================
  // GlassDivider
  // ===========================================================================

  group('GlassDivider', () {
    testWidgets('renders a horizontal Divider by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassDivider()),
        ),
      );
      expect(find.byType(GlassDivider), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders a VerticalDivider when axis is vertical',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 100,
              child: Row(children: [GlassDivider.vertical()]),
            ),
          ),
        ),
      );
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('applies custom colour', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassDivider(color: Colors.red)),
        ),
      );
      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.color, Colors.red);
    });

    testWidgets('applies indent and endIndent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassDivider(indent: 16, endIndent: 8),
          ),
        ),
      );
      final padding = tester.widget<Padding>(find.byType(Padding).first);
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.left, 16);
      expect(edgeInsets.right, 8);
    });
  });

  // ===========================================================================
  // GlassListTile
  // ===========================================================================

  group('GlassListTile', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassListTile(title: Text('Hello'))),
        ),
      );
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders leading, subtitle, and trailing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassListTile(
              leading: const Icon(Icons.star),
              title: const Text('Title'),
              subtitle: const Text('Sub'),
              trailing: GlassListTile.chevron,
              isLast: true,
            ),
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Sub'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassListTile(
              title: const Text('Tap me'),
              onTap: () => tapped = true,
              isLast: true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GlassListTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows divider when not last', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassListTile(title: Text('Item'), showDivider: true),
          ),
        ),
      );
      expect(find.byType(GlassDivider), findsOneWidget);
    });

    testWidgets('suppresses divider when isLast is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassListTile(title: Text('Last'), isLast: true),
          ),
        ),
      );
      expect(find.byType(GlassDivider), findsNothing);
    });
  });

  // ===========================================================================
  // GlassStepper  (iOS 26 UIStepper — numeric +/- control)
  // ===========================================================================

  group('GlassStepper', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(value: 5, onChanged: (_) {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GlassStepper), findsOneWidget);
    });

    testWidgets('shows decrement and increment icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(value: 5, onChanged: (_) {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onChanged with incremented value on + tap',
        (tester) async {
      double result = 5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(
              value: result,
              step: 1,
              onChanged: (v) => result = v,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      expect(result, 6);
    });

    testWidgets('calls onChanged with decremented value on − tap',
        (tester) async {
      double result = 5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(
              value: result,
              step: 1,
              onChanged: (v) => result = v,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      expect(result, 4);
    });

    testWidgets('does not decrement below min', (tester) async {
      double result = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(
              value: result,
              min: 0,
              onChanged: (v) => result = v,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      expect(result, 0); // unchanged
    });

    testWidgets('does not increment above max', (tester) async {
      double result = 10;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(
              value: result,
              max: 10,
              onChanged: (v) => result = v,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      expect(result, 10); // unchanged
    });

    testWidgets('respects custom step size', (tester) async {
      double result = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(
              value: result,
              step: 5,
              max: 100,
              onChanged: (v) => result = v,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      expect(result, 5);
    });

    testWidgets('wraps below min when wraps is true', (tester) async {
      double result = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassStepper(
              value: result,
              min: 0,
              max: 10,
              step: 1,
              wraps: true,
              onChanged: (v) => result = v,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      expect(result, greaterThan(0)); // wrapped to near max
    });
  });

  // ===========================================================================
  // GlassWizard  (multi-step flow — not an iOS 26 native equivalent)
  // ===========================================================================

  group('GlassWizard', () {
    List<GlassWizardStep> makeSteps() => const [
          GlassWizardStep(title: Text('Step 1')),
          GlassWizardStep(title: Text('Step 2')),
          GlassWizardStep(
            title: Text('Step 3'),
            subtitle: Text('Final'),
            isCompleted: true,
          ),
        ];

    testWidgets('renders all step titles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GlassWizard(steps: makeSteps())),
        ),
      );
      await tester.pump();
      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 3'), findsOneWidget);
      expect(find.text('Final'), findsOneWidget);
    });

    testWidgets('renders step numbers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GlassWizard(steps: makeSteps())),
        ),
      );
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows checkmark for completed steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassWizard(steps: makeSteps(), currentStep: 2),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('fires onStepTapped', (tester) async {
      int? tappedStep;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassWizard(
              steps: makeSteps(),
              onStepTapped: (i) => tappedStep = i,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Step 2'));
      expect(tappedStep, 1);
    });

    testWidgets('shows active step content', (tester) async {
      final steps = [
        const GlassWizardStep(
          title: Text('Step 1'),
          content: Text('Content Here'),
        ),
        const GlassWizardStep(title: Text('Step 2')),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GlassWizard(steps: steps, currentStep: 0)),
        ),
      );
      await tester.pump();
      expect(find.text('Content Here'), findsOneWidget);
    });

    testWidgets('hides non-active step content', (tester) async {
      final steps = [
        const GlassWizardStep(
          title: Text('Step 1'),
          content: Text('Content A'),
        ),
        const GlassWizardStep(
          title: Text('Step 2'),
          content: Text('Content B'),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GlassWizard(steps: steps, currentStep: 1)),
        ),
      );
      await tester.pump();
      expect(find.text('Content A'), findsNothing);
      expect(find.text('Content B'), findsOneWidget);
    });

    testWidgets('can be instantiated with zero steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassWizard(steps: [])),
        ),
      );
      await tester.pump();
      expect(find.byType(GlassWizard), findsOneWidget);
    });
  });
}
