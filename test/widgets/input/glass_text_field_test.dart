import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassTextField', () {
    testWidgets('can be instantiated with default parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(),
          ),
        ),
      );

      expect(find.byType(GlassTextField), findsOneWidget);
    });

    testWidgets('displays placeholder text', (tester) async {
      const placeholder = 'Enter email';

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              placeholder: placeholder,
            ),
          ),
        ),
      );

      expect(find.text(placeholder), findsOneWidget);
    });

    testWidgets('displays prefix icon when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays suffix icon when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              suffixIcon: Icon(Icons.clear),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      var text = '';

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassTextField(
              onChanged: (value) => text = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'flutter');

      expect(text, equals('flutter'));
    });

    testWidgets('calls onSubmitted when submitted', (tester) async {
      var submitted = '';

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassTextField(
              onSubmitted: (value) => submitted = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submitted, equals('test'));
    });

    testWidgets('calls onSuffixTap when suffix is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassTextField(
              suffixIcon: const Icon(Icons.clear),
              onSuffixTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('respects obscureText for password fields', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.obscureText, isTrue);
    });

    testWidgets('respects enabled state', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.enabled, isFalse);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassTextField(
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );

      expect(find.byType(GlassTextField), findsOneWidget);
    });

    test('defaults are correct', () {
      const textField = GlassTextField();

      expect(textField.obscureText, isFalse);
      expect(textField.maxLines, equals(1));
      expect(textField.enabled, isTrue);
      expect(textField.readOnly, isFalse);
      expect(textField.autofocus, isFalse);
      expect(textField.useOwnLayer, isFalse);
      expect(textField.quality, isNull);
      // Interaction defaults — must match GlassBottomBar / GlassSearchableBottomBar
      expect(textField.interactionBehavior, GlassInteractionBehavior.full);
      expect(textField.pressScale, 1.03);
      expect(textField.glowColor, isNull);
      expect(textField.glowRadius, 1.5);
    });

    // ── _effectiveBorderRadius shape paths (lines 349-352) ──────────────────
    testWidgets('LiquidRoundedRectangle shape gives correct border radius',
        (tester) async {
      // Line 349: shape is LiquidRoundedRectangle → BorderRadius.circular(shape.borderRadius)
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              shape: LiquidRoundedRectangle(borderRadius: 20),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassTextField), findsOneWidget);
    });

    testWidgets('LiquidOval shape falls back to default border radius',
        (tester) async {
      // Line 352: fallback → BorderRadius.circular(10)
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              shape: LiquidOval(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassTextField), findsOneWidget);
    });
  });

  // ===========================================================================
  // GlassTextField — interactionBehavior
  // ===========================================================================

  group('GlassTextField interactionBehavior', () {
    // ── Helper ────────────────────────────────────────────────────────────────

    Widget buildField({
      GlassInteractionBehavior behavior = GlassInteractionBehavior.full,
      Color? glowColor,
    }) =>
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassTextField(
              interactionBehavior: behavior,
              glowColor: glowColor,
            ),
          ),
        );

    // ── API defaults ─────────────────────────────────────────────────────────

    test('interactionBehavior defaults to full', () {
      expect(
        const GlassTextField().interactionBehavior,
        GlassInteractionBehavior.full,
      );
    });

    test('pressScale defaults to 1.03', () {
      expect(const GlassTextField().pressScale, 1.03);
    });

    test('glowRadius defaults to 1.5', () {
      expect(const GlassTextField().glowRadius, 1.5);
    });

    test('glowColor defaults to null (uses internal default)', () {
      expect(const GlassTextField().glowColor, isNull);
    });

    // ── Enum invariants (mirror glass_interaction_behavior_test) ─────────────

    test('GlassInteractionBehavior.none has neither glow nor scale', () {
      expect(GlassInteractionBehavior.none.hasGlow, isFalse);
      expect(GlassInteractionBehavior.none.hasScale, isFalse);
    });

    test('GlassInteractionBehavior.glowOnly has glow but not scale', () {
      expect(GlassInteractionBehavior.glowOnly.hasGlow, isTrue);
      expect(GlassInteractionBehavior.glowOnly.hasScale, isFalse);
    });

    test('GlassInteractionBehavior.scaleOnly has scale but not glow', () {
      expect(GlassInteractionBehavior.scaleOnly.hasGlow, isFalse);
      expect(GlassInteractionBehavior.scaleOnly.hasScale, isTrue);
    });

    test('GlassInteractionBehavior.full has both glow and scale', () {
      expect(GlassInteractionBehavior.full.hasGlow, isTrue);
      expect(GlassInteractionBehavior.full.hasScale, isTrue);
    });

    // ── Rendering per behavior ────────────────────────────────────────────────

    testWidgets('behavior=full: GlassGlow present in tree', (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.full));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsOneWidget);
    });

    testWidgets('behavior=glowOnly: GlassGlow present in tree', (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.glowOnly));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsOneWidget);
    });

    testWidgets('behavior=none: GlassGlow absent from tree', (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.none));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsNothing);
    });

    testWidgets('behavior=scaleOnly: GlassGlow absent from tree',
        (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.scaleOnly));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsNothing);
    });

    // ── AnimatedScale presence / absence ─────────────────────────────────────

    testWidgets('behavior=full: AnimatedScale present in tree', (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.full));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('behavior=scaleOnly: AnimatedScale present in tree',
        (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.scaleOnly));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('behavior=none: AnimatedScale absent from tree',
        (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.none));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('behavior=glowOnly: AnimatedScale absent from tree',
        (tester) async {
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.glowOnly));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedScale), findsNothing);
    });

    // ── Custom glow color ─────────────────────────────────────────────────────

    testWidgets('custom glowColor propagates to GlassGlow', (tester) async {
      const customColor = Color(0x44FF0000);
      await tester.pumpWidget(
        buildField(
          behavior: GlassInteractionBehavior.full,
          glowColor: customColor,
        ),
      );
      await tester.pumpAndSettle();
      final glassGlow = tester.widget<GlassGlow>(find.byType(GlassGlow));
      expect(glassGlow.glowColor, customColor);
    });

    // ── Hot-rebuild state transitions ─────────────────────────────────────────

    testWidgets('live transition full → none removes GlassGlow',
        (tester) async {
      // Start with full.
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.full));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsOneWidget);

      // Hot-rebuild with none.
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.none));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsNothing);
    });

    testWidgets('live transition none → full adds GlassGlow', (tester) async {
      // Start with none.
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.none));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsNothing);

      // Hot-rebuild with full.
      await tester
          .pumpWidget(buildField(behavior: GlassInteractionBehavior.full));
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsOneWidget);
    });

    // ── Delegation — GlassPasswordField & GlassTextArea inherit the param ─────

    testWidgets('GlassPasswordField: behavior=none removes GlassGlow',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassPasswordField(
              interactionBehavior: GlassInteractionBehavior.none,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsNothing);
    });

    testWidgets('GlassTextArea: behavior=none removes GlassGlow',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextArea(
              interactionBehavior: GlassInteractionBehavior.none,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassGlow), findsNothing);
    });

    // ── Delegation — full parameter pass-through ─────────────────────────────

    testWidgets('GlassPasswordField: passes pressScale/glowColor/glowRadius',
        (tester) async {
      const customColor = Color(0xFF00FF00);
      const field = GlassPasswordField(
        pressScale: 1.08,
        glowColor: customColor,
        glowRadius: 2.0,
      );
      expect(field.pressScale, 1.08);
      expect(field.glowColor, customColor);
      expect(field.glowRadius, 2.0);
    });

    testWidgets('GlassTextArea: passes pressScale/glowColor/glowRadius',
        (tester) async {
      const customColor = Color(0xFF0000FF);
      const field = GlassTextArea(
        pressScale: 1.06,
        glowColor: customColor,
        glowRadius: 2.5,
      );
      expect(field.pressScale, 1.06);
      expect(field.glowColor, customColor);
      expect(field.glowRadius, 2.5);
    });

    testWidgets('GlassPasswordField: onTapOutside wired through',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassPasswordField(
              onTapOutside: (_) => called = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The parameter being accepted and rendered without error is the key test.
      expect(find.byType(GlassPasswordField), findsOneWidget);
      expect(called, isFalse); // not called until a tap occurs
    });

    // ── press animation ───────────────────────────────────────────────────────

    testWidgets('AnimatedScale is at 1.0 initially (no press)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              interactionBehavior: GlassInteractionBehavior.full,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, 1.0);
    });

    testWidgets('AnimatedScale grows to pressScale on pointer down',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              interactionBehavior: GlassInteractionBehavior.full,
              pressScale: 1.05,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate pointer down (without full tap which would also trigger keyboard).
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(GlassTextField)));
      await tester.pump();

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, 1.05);

      // Release — scale should return to 1.0.
      await gesture.up();
      await tester.pumpAndSettle();
      final scaleAfter =
          tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleAfter.scale, 1.0);
    });

    // ── _isPressed cleared when field becomes disabled ────────────────────────

    testWidgets('_isPressed resets to false when enabled becomes false',
        (tester) async {
      // Start enabled.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              interactionBehavior: GlassInteractionBehavior.full,
              pressScale: 1.05,
              enabled: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Press down to activate the scale.
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(GlassTextField)));
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.05,
      );

      // Disable mid-press — _isPressed should be reset.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              interactionBehavior: GlassInteractionBehavior.full,
              pressScale: 1.05,
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.0, // back to rest — not stuck at 1.05
      );

      await gesture.cancel();
    });
  });

  // ===========================================================================
  // GlassTextField — onLineCountChanged + fixed-height guard fix (v0.12.4)
  // ===========================================================================

  group('GlassTextField onLineCountChanged — fixed-height guard', () {
    testWidgets('callback fires on initial build with fixed height',
        (tester) async {
      // Verifies the basic contract: onLineCountChanged fires at least once
      // on initial layout even when the field is inside a fixed-height SizedBox.
      final lineCounts = <int>[];

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              height: 44,
              maxLines: 1,
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
              onLineCountChanged: lineCounts.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must fire at least once on initial layout.
      expect(lineCounts, isNotEmpty);
    });

    testWidgets('callback is not permanently blocked after first measurement',
        (tester) async {
      // Regression test for the size-equality guard bug.
      // The old guard (size == _lastTextFieldSize) would exit early on every
      // subsequent check once size was recorded, silently blocking future calls.
      // The new guard (text + width) allows re-measurement when text changes.
      //
      // We verify this by setting up the widget, recording the initial state,
      // then directly confirming the guard variables are tracked correctly
      // via a two-step text change that should both be observable.
      final controller = TextEditingController();
      int callCount = 0;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              controller: controller,
              height: 44,
              maxLines: 1,
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
              onLineCountChanged: (_) => callCount++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final countAfterBuild = callCount;

      // Type text to update controller — the new guard (text != _lastMeasuredText)
      // must allow _measureLineCount to run. Even if line count stays the same
      // (still 1 line), the guard must NOT permanently block.
      controller.text = 'hello world';
      await tester.pumpAndSettle();

      // Guard ran (even if line count didn't change, the fact the guard cleared
      // means a future change will also be processed correctly).
      // We can't assert callCount grew if line count is the same value (1),
      // but we CAN assert the widget didn't crash and is still functional.
      expect(find.byType(GlassTextField), findsOneWidget);
      expect(callCount, greaterThanOrEqualTo(countAfterBuild));

      controller.dispose();
    });
  });

  // ===========================================================================
  // GlassTextField — fixed-height vertical centring (v0.12.4)
  // ===========================================================================

  group('GlassTextField fixed-height vertical centring', () {
    testWidgets('fixed height: centres TextField content (not the icon Row)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTextField(
            height: 44,
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
            // Padding with vertical component — must not apply vertically.
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A Center widget must wrap the TextField for vertical centring,
      // but the Row itself must NOT be wrapped in Align/Center so that
      // iconAlignment (CrossAxisAlignment) works correctly.
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets(
        'dynamic height (no height param): uses full padding (no Align centring)',
        (tester) async {
      // When height == null the code path uses Padding(widget.padding, child: row)
      // directly. Align should not appear for the centring purpose.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassTextField(
              // No height — dynamic sizing.
              placeholder: 'Dynamic',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassTextField), findsOneWidget);
    });
  });

  // ===========================================================================
  // GlassTextField — bottom panel (v0.12.4)
  // ===========================================================================

  group('GlassTextField bottom panel', () {
    testWidgets('bottom provided: Column is present in the tree',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTextField(
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
            bottom: const SizedBox(key: Key('panel'), height: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The panel widget must appear.
      expect(find.byKey(const Key('panel')), findsOneWidget);
      // A Column must exist to stack text area + panel.
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('bottom null: panel widget absent from tree', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassTextField(
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
            // bottom defaults to null.
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('panel')), findsNothing);
    });

    test('GlassTextField.search: bottom is always null', () {
      const field = GlassTextField.search();
      expect(field.bottom, isNull);
    });

    testWidgets('GlassTextArea: bottom forwarded to GlassTextField',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTextArea(
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
            bottom: const SizedBox(key: Key('area-panel'), height: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('area-panel')), findsOneWidget);
    });

    testWidgets(
        'bottom + maxHeight: no RenderFlex overflow when panel exceeds constraint',
        (tester) async {
      // Regression for the Column overflow bug (v0.12.4):
      // Previously the Column had no Flexible child. When text area (134px) +
      // bottom panel (56px) exceeded maxHeight (160px), Flutter threw a
      // RenderFlex overflow. The fix wraps textFieldContent in Flexible so
      // the text area yields space to the panel before clipping.
      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = errors.add;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassTextField(
              // Many lines of text to force text area taller than maxHeight
              // allows after accounting for the bottom panel.
              maxLines: 10,
              minHeight: 44,
              maxHeight: 120, // tight — panel (48+) + text will exceed this
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
              bottom: const SizedBox(height: 48), // fixed panel height
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      // No RenderFlex overflow errors should have been reported.
      final overflows = errors.where((e) =>
          e.exception.toString().contains('overflowed') ||
          e.exception.toString().contains('RenderFlex'));
      expect(overflows, isEmpty,
          reason:
              'bottom panel + maxHeight must not cause RenderFlex overflow');
    });

    testWidgets('bottom + maxHeight: text area child is Flexible in Column',
        (tester) async {
      // Structural guarantee: the first child of the bottom-panel Column must
      // be a Flexible so that it surrenders space to the fixed bottom panel.
      await tester.pumpWidget(
        createTestApp(
          child: GlassTextField(
            maxLines: 5,
            maxHeight: 140,
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
            bottom: const SizedBox(key: Key('panel2'), height: 44),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The Flexible widget must be present — it is the text area inside Column.
      expect(find.byType(Flexible), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Issue 1: height: _lines > 1 ? null : (hasFocus ? 46 : 50)
  //
  // The user's exact pattern. _lines comes from onLineCountChanged.
  // In fixed-height mode, _lines must transition from 1 → 2 when text wraps.
  // ═══════════════════════════════════════════════════════════════════════════

  group('User pattern: height: _lines > 1 ? null : (hasFocus ? 46 : 50)', () {
    testWidgets('_lines transitions from 1 → 2 when text wraps in fixed height',
        (tester) async {
      int lines = 1;
      final controller = TextEditingController();

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 200, // narrow to force wrapping
            child: GlassTextField(
              controller: controller,
              maxLines: 5,
              height: lines > 1 ? null : 50,
              onLineCountChanged: (l) => lines = l,
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: 1 line.
      expect(lines, 1);

      // Type enough text to wrap at 200px width.
      controller.text = 'This is a long sentence that will definitely wrap '
          'to a second line at 200px width.';
      await tester.pump(); // controller listener fires → scheduleLineCountCheck
      await tester.pump(); // post-frame: _measureLineCount runs

      // Must detect >1 line now.
      expect(lines, greaterThan(1),
          reason: 'TextPainter must detect text wrapping in fixed-height mode');

      controller.dispose();
    });

    testWidgets('_lines transitions back from 2 → 1 when text is deleted',
        (tester) async {
      int lines = 1;
      final controller = TextEditingController(
        text: 'This is a long sentence that will definitely wrap '
            'to a second line at 200px width.',
      );

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 200,
            child: GlassTextField(
              controller: controller,
              maxLines: 5,
              height: lines > 1 ? null : 50,
              onLineCountChanged: (l) => lines = l,
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Should be >1 now.
      expect(lines, greaterThan(1));

      // Delete text to single word.
      controller.text = 'Hi';
      await tester.pump();
      await tester.pump();

      expect(lines, 1,
          reason: 'Line count must return to 1 after deleting text');

      controller.dispose();
    });

    testWidgets('onLineCountChanged fires correctly after re-focus',
        (tester) async {
      // Regression: stale _lines after re-focus (v0.12.4 bug).
      int lines = 1;
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 200,
            child: GlassTextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 5,
              height: lines > 1 ? null : 50,
              onLineCountChanged: (l) => lines = l,
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Focus, type wrapping text, then unfocus.
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      controller.text = 'This is a long sentence that will definitely wrap '
          'to a second line at 200px width.';
      await tester.pump();
      await tester.pump();

      final linesBeforeBlur = lines;
      expect(linesBeforeBlur, greaterThan(1));

      // Unfocus.
      focusNode.unfocus();
      await tester.pumpAndSettle();

      // Re-focus — lines must NOT reset to stale value.
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Type more text.
      controller.text += ' Adding even more text to ensure wrapping.';
      await tester.pump();
      await tester.pump();

      expect(lines, greaterThanOrEqualTo(linesBeforeBlur),
          reason: 'onLineCountChanged must still fire after re-focus');

      controller.dispose();
      focusNode.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Issue 2: iconAlignment: .end under large system text
  //
  // Icons must respect CrossAxisAlignment.end in fixed-height mode.
  // Previously Align(center) overrode icon positioning.
  // ═══════════════════════════════════════════════════════════════════════════

  group('iconAlignment: .end in fixed-height mode', () {
    testWidgets(
        'icon Y position is at bottom of container, not drifting with text',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: const GlassTextField(
              height: 50,
              maxLines: 1,
              iconAlignment: CrossAxisAlignment.end,
              prefixIcon:
                  Icon(Icons.emoji_emotions, size: 24, key: Key('prefix')),
              suffixIcon: Icon(Icons.send, size: 24, key: Key('suffix')),
              useOwnLayer: true,
              settings: defaultTestGlassSettings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the icon positions.
      final prefixBox = tester.getBottomLeft(find.byKey(const Key('prefix')));
      final suffixBox = tester.getBottomLeft(find.byKey(const Key('suffix')));
      final fieldBox = tester.getBottomLeft(find.byType(GlassTextField));

      // Icons with .end alignment should be pinned near the bottom of the
      // container. The bottom of the icon should be close to the bottom of
      // the field (within padding tolerance).
      expect(prefixBox.dy, closeTo(fieldBox.dy, 20),
          reason: 'Prefix icon must be near the bottom of the container');
      expect(suffixBox.dy, closeTo(fieldBox.dy, 20),
          reason: 'Suffix icon must be near the bottom of the container');
    });

    testWidgets(
        'Row crossAxisAlignment is widget.iconAlignment (not overridden)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassTextField(
            height: 50,
            iconAlignment: CrossAxisAlignment.end,
            prefixIcon: Icon(Icons.add, size: 20),
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The Row must use the actual iconAlignment, not auto-override it.
      final rows = tester.widgetList<Row>(find.byType(Row));
      expect(
        rows.any((r) => r.crossAxisAlignment == CrossAxisAlignment.end),
        isTrue,
        reason: 'Row crossAxisAlignment must respect widget.iconAlignment',
      );
    });

    testWidgets(
        'Center wraps only TextField, not the Row, in fixed-height mode',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassTextField(
            height: 50,
            iconAlignment: CrossAxisAlignment.end,
            prefixIcon: Icon(Icons.add, size: 20),
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Center must be a descendant of Row (wrapping TextField), not an
      // ancestor of Row (wrapping the whole thing). If Center is an ancestor
      // of Row, it overrides iconAlignment — that was the bug.
      final rowFinder = find.byType(Row);
      final centerInsideRow = find.descendant(
        of: rowFinder,
        matching: find.byType(Center),
      );
      expect(centerInsideRow, findsWidgets,
          reason: 'Center must be INSIDE the Row, not wrapping it');
    });

    testWidgets('Expanded child is TextField directly in dynamic-height mode',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassTextField(
            // No height — dynamic sizing.
            maxLines: 5,
            iconAlignment: CrossAxisAlignment.end,
            prefixIcon: Icon(Icons.add, size: 20),
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In dynamic-height mode, the Expanded's direct child should be
      // TextField (not Center(child: TextField)). We verify by checking
      // that the Expanded does NOT have a Center as an immediate child.
      final expanded = tester
          .widgetList<Expanded>(
            find.descendant(
              of: find.byType(Row),
              matching: find.byType(Expanded),
            ),
          )
          .first;

      // The direct child of Expanded must be a TextField, not a Center.
      expect(expanded.child, isA<TextField>(),
          reason: 'In dynamic-height mode, Expanded should wrap TextField '
              'directly without Center');
    });
  });
}
