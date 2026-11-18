import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/liquid_glass_renderer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassButton', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icon(CupertinoIcons.heart),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
    });

    testWidgets('displays icon correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icon(Icons.star),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icon(Icons.add),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icon(Icons.add),
              onTap: () => tapped = true,
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('renders with reduced opacity when disabled', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icon(Icons.add),
              onTap: () {},
              enabled: false,
            ),
          ),
        ),
      );

      final opacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(Opacity),
        ),
      );

      expect(opacities.any((o) => o.opacity == 0.5), isTrue);
    });

    testWidgets('GlassButton.custom displays custom child', (tester) async {
      const testText = 'Custom Button';

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton.custom(
              onTap: () {},
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('respects custom width and height', (tester) async {
      const customWidth = 100.0;
      const customHeight = 80.0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icon(Icons.star),
              onTap: () {},
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(GlassButton));

      expect(size.width, equals(customWidth));
      expect(size.height, equals(customHeight));
    });

    testWidgets('GlassButton.custom shrink-wraps to child when sizes are null',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Center(
              child: GlassButton.custom(
                onTap: () {},
                // No explicit width or height
                child: const SizedBox(width: 40, height: 20),
              ),
            ),
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(GlassButton));

      // Should perfectly wrap the 40x20 child, not expand to fill the screen
      expect(buttonSize.width, equals(40));
      expect(buttonSize.height, equals(20));
    });

    testWidgets('has proper semantics', (tester) async {
      const semanticLabel = 'Add Item';

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icon(Icons.add),
              onTap: () {},
              label: semanticLabel,
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(GlassButton),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.label, equals(semanticLabel));
      expect(semantics.properties.enabled, isTrue);
    });

    testWidgets('works in standalone mode with useOwnLayer', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassButton(
            icon: Icon(Icons.star),
            onTap: () {},
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
    });

    testWidgets('uses correct glass quality', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassButton(
            icon: Icon(Icons.star),
            onTap: () {},
            useOwnLayer: true,
            quality: GlassQuality.premium,
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
    });

    test('defaults are correct', () {
      final button = GlassButton(
        icon: Icon(Icons.star),
        onTap: () {},
      );

      expect(button.width, equals(56));
      expect(button.height, equals(56));
      expect(button.iconSize, equals(24.0));
      expect(button.enabled, isTrue);
      expect(button.useOwnLayer, isFalse);
      expect(button.quality, isNull);
      expect(button.surfaceStyle, isNull);
      expect(button.color, isNull);
      expect(button.tintColor, isNull);
      expect(button.style, equals(GlassButtonStyle.filled));
      expect(button.interactionScale, isNull);
      expect(button.anchorStretchSettings, isNull);
      expect(button.stretch, equals(0.5));
      expect(button.resistance, equals(0.01));

      final customButton = GlassButton.custom(
        onTap: () {},
        child: const Text('Custom'),
      );
      expect(customButton.surfaceStyle, isNull);
      expect(customButton.color, isNull);
      expect(customButton.tintColor, isNull);
      expect(customButton.style, equals(GlassButtonStyle.filled));
    });
  });

  group('GlassButton interaction resolution', () {
    /// The LiquidStretch the button builds from its params and the theme.
    LiquidStretch stretchOf(WidgetTester tester) =>
        tester.widget<LiquidStretch>(
          find.descendant(
            of: find.byType(GlassButton),
            matching: find.byType(LiquidStretch),
          ),
        );

    Widget themed({
      required GlassInteractionSettings interaction,
      required Widget child,
    }) =>
        createTestApp(
          child: GlassTheme(
            data: GlassThemeData(interaction: interaction),
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: child,
            ),
          ),
        );

    testWidgets('defaults to the native sizing', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () {},
            ),
          ),
        ),
      );

      final stretch = stretchOf(tester);
      expect(stretch.pressGrowth, equals(17));
      expect(stretch.interactionScale, equals(1.0));
      expect(stretch.anchorStretchSettings.intensity, equals(0.1));
      expect(stretch.anchorStretchSettings.squashFactor, equals(0.1));
      expect(stretch.anchorStretchSettings.translationDamping, equals(0.1));
      expect(stretch.anchorStretchSettings.bounciness, equals(0.0));
    });

    testWidgets('an explicit interactionScale is a fixed factor',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () {},
              interactionScale: 1.15,
            ),
          ),
        ),
      );

      final stretch = stretchOf(tester);
      expect(stretch.interactionScale, equals(1.15));
      expect(stretch.pressGrowth, isNull);
    });

    testWidgets('the theme supplies a fixed factor and stretch settings',
        (tester) async {
      await tester.pumpWidget(
        themed(
          interaction: const GlassInteractionSettings(
            interactionScale: 1.2,
            anchorStretchSettings: AnchorStretchSettings(intensity: 0.7),
          ),
          child: GlassButton(
            icon: const Icon(Icons.star),
            onTap: () {},
          ),
        ),
      );

      final stretch = stretchOf(tester);
      expect(stretch.interactionScale, equals(1.2));
      expect(stretch.pressGrowth, isNull);
      expect(stretch.anchorStretchSettings.intensity, equals(0.7));
    });

    testWidgets('explicit anchorStretchSettings win over the theme',
        (tester) async {
      await tester.pumpWidget(
        themed(
          interaction: const GlassInteractionSettings(
            anchorStretchSettings: AnchorStretchSettings(intensity: 0.7),
          ),
          child: GlassButton(
            icon: const Icon(Icons.star),
            onTap: () {},
            anchorStretchSettings: const AnchorStretchSettings(intensity: 0.4),
          ),
        ),
      );

      expect(stretchOf(tester).anchorStretchSettings.intensity, equals(0.4));
    });
  });

  // ── _handleTapCancel (lines 436-438) ────────────────────────────────────────
  group('GlassButton tap-cancel', () {
    testWidgets('tap-cancel on enabled button reverses animation',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () {},
            ),
          ),
        ),
      );

      // Start tap then cancel — exercises _handleTapCancel (line 436-438)
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassButton)),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(find.byType(GlassButton), findsOneWidget);
    });

    testWidgets('tap-cancel on disabled button is a no-op (line 437 guard)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () {},
              enabled: false, // exercises `if (!widget.enabled) return;`
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassButton)),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(find.byType(GlassButton), findsOneWidget);
    });
  });

  // ── persistPressOnDrag (lines 596-620) ──────────────────────────────────────
  group('GlassButton persistPressOnDrag', () {
    test('default value is true', () {
      final button = GlassButton(
        icon: const Icon(Icons.star),
        onTap: () {},
      );
      expect(button.persistPressOnDrag, isTrue);
    });

    test('GlassButton.custom default value is true', () {
      final button = GlassButton.custom(
        onTap: () {},
        child: const Text('test'),
      );
      expect(button.persistPressOnDrag, isTrue);
    });

    testWidgets('persistPressOnDrag: true — uses Listener (pointer events)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () {},
              persistPressOnDrag: true,
            ),
          ),
        ),
      );

      // The tree should contain a Listener wrapping a GestureDetector
      final listenerFinder = find.descendant(
        of: find.byType(GlassButton),
        matching: find.byType(Listener),
      );
      expect(listenerFinder, findsWidgets); // At least our Listener

      // Test that tap still fires onTap
      var tapped = false;
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () => tapped = true,
              persistPressOnDrag: true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GlassButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
        'persistPressOnDrag: false — uses GestureDetector tap callbacks',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () => tapped = true,
              persistPressOnDrag: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('persistPressOnDrag: false — cancel reverses animation',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(Icons.star),
              onTap: () {},
              persistPressOnDrag: false,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassButton)),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(find.byType(GlassButton), findsOneWidget);
    });
  });

  // ===========================================================================
  // Keyboard focus & accessibility template tests
  //
  // These tests validate the behaviour added in the a11y-keyboard-focus branch
  // and serve as the specification that all other interactive widgets must
  // satisfy when the template is applied to them.
  // ===========================================================================
  group('GlassButton keyboard focus & accessibility', () {
    // -------------------------------------------------------------------------
    // ActivateIntent (Space / Enter)
    // -------------------------------------------------------------------------
    testWidgets('Space key fires onTap when button is focused', (tester) async {
      var tapped = false;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart),
              onTap: () => tapped = true,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Enter key fires onTap when button is focused', (tester) async {
      var tapped = false;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart),
              onTap: () => tapped = true,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Space key does NOT fire onTap when disabled', (tester) async {
      var tapped = false;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart),
              onTap: () => tapped = true,
              focusNode: focusNode,
              enabled: false,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    // -------------------------------------------------------------------------
    // focusNode parameter
    // -------------------------------------------------------------------------
    testWidgets('focusNode parameter allows programmatic focus',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart),
              onTap: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      expect(focusNode.hasFocus, isFalse);
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
    });

    // -------------------------------------------------------------------------
    // autofocus parameter
    // -------------------------------------------------------------------------
    testWidgets('autofocus: true focuses button on mount', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart),
              onTap: () {},
              focusNode: focusNode,
              autofocus: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
    });

    // -------------------------------------------------------------------------
    // Focus ring visual presence
    // -------------------------------------------------------------------------
    testWidgets('focus ring CustomPaint NOT in tree when button is not focused',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart),
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // CustomPaint for the focus ring is only inserted when focused.
      // When not focused, ValueListenableBuilder returns child directly —
      // no Stack, no CustomPaint for the ring.
      // We look for a CustomPaint that is a descendant of the GlassButton's
      // Stack — if none exist, the ring is correctly absent.
      expect(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
        reason: 'Focus ring CustomPaint must not be present when button is '
            'unfocused (zero GPU cost for touch users)',
      );
    });

    testWidgets('focus ring CustomPaint IS in tree when button is focused',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart),
              onTap: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Switch FocusManager to keyboard highlight mode, then request focus.
      // This replicates Tab-key navigation which triggers onShowFocusHighlight.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      focusNode.requestFocus();
      await tester.pump();
      addTearDown(() => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic);

      // After keyboard focus, ValueListenableBuilder inserts Stack + CustomPaint.
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
        reason: 'Focus ring CustomPaint must be present when keyboard-focused',
      );
    });

    // -------------------------------------------------------------------------
    // Reduce Motion
    // -------------------------------------------------------------------------
    testWidgets('keyboard activation works with reduceMotion enabled',
        (tester) async {
      var tapped = false;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      // Override MediaQuery to signal reduceMotion / disableAnimations.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassButton(
                icon: const Icon(CupertinoIcons.heart),
                onTap: () => tapped = true,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      // Should fire onTap without running the animation (no exception thrown).
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(tapped, isTrue,
          reason: 'onTap must fire even when reduceMotion is enabled');
    });

    // -------------------------------------------------------------------------
    // Semantics
    // -------------------------------------------------------------------------
    testWidgets('exposes button semantics', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassButton(
                icon: const Icon(CupertinoIcons.heart),
                onTap: () {},
                label: 'Like',
              ),
            ),
          ),
        );

        await tester.pump();

        // Find the Semantics widget with the button role directly.
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Like'),
          ),
          matchesSemantics(
            isButton: true,
            label: 'Like',
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            hasFocusAction: true, // focus merges into the labelled node (#381)
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('semantics shows disabled state', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassButton(
                icon: const Icon(CupertinoIcons.heart),
                onTap: () {},
                label: 'Like',
                enabled: false,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Like'),
          ),
          matchesSemantics(
            isButton: true,
            label: 'Like',
            hasEnabledState: true,
            isEnabled: false,
            // isFocusable is absent when enabled:false — FocusableActionDetector
            // correctly removes the focusable flag for disabled controls.
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('excludeFromSemantics hides button from semantics tree',
        (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassButton(
                icon: const Icon(CupertinoIcons.heart),
                onTap: () {},
                label: 'Like',
                excludeFromSemantics: true,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.bySemanticsLabel('Like'), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });

  group('GlassButton press highlight', () {
    testWidgets('ambient base light is clipped to the button shape',
        (tester) async {
      const shape = LiquidRoundedSuperellipse(borderRadius: 40);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: const LiquidGlassSettings(blur: 0),
            child: GlassButton(
              icon: const Icon(Icons.star),
              shape: shape,
              width: 120,
              height: 80,
              onTap: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final overlay = find.descendant(
        of: find.byType(GlassButton),
        matching: find.byWidgetPredicate(
          (w) =>
              w is ColoredBox &&
              w.color.toARGB32() & 0x00FFFFFF == 0x00FFFFFF &&
              w.color.a > 0,
        ),
      );
      expect(overlay, findsOneWidget);

      final clips = find.ancestor(of: overlay, matching: find.byType(ClipPath));
      expect(clips, findsWidgets);
      final clip = tester.widget<ClipPath>(clips.first);
      expect(clip.clipper, isA<ShapeBorderClipper>());
      expect((clip.clipper! as ShapeBorderClipper).shape, shape);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    // The pressed light, found by its RGB: the shape-clipped ColoredBox the
    // button paints under its content while the finger is down.
    Finder pressLight(int rgb) => find.descendant(
          of: find.byType(GlassButton),
          matching: find.byWidgetPredicate(
            (w) =>
                w is ColoredBox &&
                w.color.toARGB32() & 0x00FFFFFF == rgb &&
                w.color.a > 0,
          ),
        );

    Color sheenOf(WidgetTester tester) => tester
        .widget<GlassGlow>(
          find.descendant(
            of: find.byType(GlassButton),
            matching: find.byType(GlassGlow),
          ),
        )
        .glowColor;

    /// Presses the button, waits for the light to ramp fully, and leaves the
    /// finger down.
    Future<TestGesture> pressAndHold(WidgetTester tester) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassButton)),
      );
      await tester.pumpAndSettle();
      return gesture;
    }

    /// A button under a glass theme pinned to [brightness], with optional
    /// press light colours on the light and dark variants.
    Widget host(
      Widget button, {
      required Brightness brightness,
      Color? lightPressLight,
      Color? darkPressLight,
    }) =>
        createTestApp(
          child: GlassTheme(
            data: GlassThemeData(
              brightness: brightness,
              light: GlassThemeVariant(
                glowColors: GlassGlowColors(pressLight: lightPressLight),
              ),
              dark: GlassThemeVariant(
                glowColors: GlassGlowColors(pressLight: darkPressLight),
              ),
            ),
            child: AdaptiveLiquidGlassLayer(
              settings: const LiquidGlassSettings(blur: 0),
              child: button,
            ),
          ),
        );

    GlassButton star({Color? pressLightColor, Color? glowColor}) => GlassButton(
          icon: const Icon(Icons.star),
          onTap: () {},
          pressLightColor: pressLightColor,
          glowColor: glowColor,
        );

    const page = Color(0xFFF2CB48);
    const darkPage = Color(0xFF5E4A10);

    for (final (brightness, strength, sheen) in [
      (
        Brightness.light,
        GlassDefaults.ambientBaseLight,
        const Color(0x1AFFFFFF)
      ),
      (
        Brightness.dark,
        GlassDefaults.ambientBaseLightDark,
        const Color(0x12FFFFFF)
      ),
    ]) {
      testWidgets('${brightness.name}: white at the native strength by default',
          (tester) async {
        await tester.pumpWidget(host(star(), brightness: brightness));

        expect(sheenOf(tester), sheen);
        final gesture = await pressAndHold(tester);
        final light = tester.widget<ColoredBox>(pressLight(0xFFFFFF));
        expect(light.color.a, closeTo(strength, 0.005));
        await gesture.up();
        await tester.pumpAndSettle();
      });
    }

    testWidgets("the theme's colour for the brightness lights the press",
        (tester) async {
      for (final (brightness, colour) in [
        (Brightness.light, page),
        (Brightness.dark, darkPage),
      ]) {
        await tester.pumpWidget(
          host(
            star(),
            brightness: brightness,
            lightPressLight: page,
            darkPressLight: darkPage,
          ),
        );

        final gesture = await pressAndHold(tester);
        final rgb = colour.toARGB32() & 0x00FFFFFF;
        expect(pressLight(0xFFFFFF), findsNothing, reason: brightness.name);
        final light = tester.widget<ColoredBox>(pressLight(rgb));
        // The colour changes, the strength doesn't.
        expect(
          light.color.a,
          closeTo(
            brightness == Brightness.dark
                ? GlassDefaults.ambientBaseLightDark
                : GlassDefaults.ambientBaseLight,
            0.005,
          ),
        );
        final sheen = sheenOf(tester);
        expect(sheen.toARGB32() & 0x00FFFFFF, rgb);
        expect(
          sheen.a,
          closeTo(
            brightness == Brightness.dark ? 0x12 / 0xFF : 0x1A / 0xFF,
            0.002,
          ),
        );
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('pressLightColor wins over the theme', (tester) async {
      await tester.pumpWidget(
        host(
          star(pressLightColor: const Color(0xFF34C759)),
          brightness: Brightness.light,
          lightPressLight: page,
        ),
      );

      final gesture = await pressAndHold(tester);
      expect(pressLight(0x34C759), findsOneWidget);
      expect(pressLight(0xF2CB48), findsNothing);
      expect(sheenOf(tester).toARGB32() & 0x00FFFFFF, 0x34C759);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets("the colour's alpha scales both lights", (tester) async {
      await tester.pumpWidget(
        host(
          star(pressLightColor: const Color(0x80F2CB48)),
          brightness: Brightness.light,
        ),
      );

      final half = 0x80 / 0xFF;
      expect(sheenOf(tester).a, closeTo(half * 0x1A / 0xFF, 0.002));
      final gesture = await pressAndHold(tester);
      final light = tester.widget<ColoredBox>(pressLight(0xF2CB48));
      expect(
          light.color.a, closeTo(half * GlassDefaults.ambientBaseLight, 0.005));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('an explicit glowColor still sets the sheen', (tester) async {
      await tester.pumpWidget(
        host(
          star(glowColor: const Color(0x3334C759)),
          brightness: Brightness.light,
          lightPressLight: page,
        ),
      );

      expect(sheenOf(tester), const Color(0x3334C759));
    });
  });

  // ===========================================================================
  // GlassSurfaceStyle.solid & tintColor tests
  // ===========================================================================
  group('GlassButton GlassSurfaceStyle.solid', () {
    Widget cupertinoHost({
      required Widget child,
      Brightness brightness = Brightness.light,
      Color primaryColor = CupertinoColors.activeBlue,
    }) {
      return GlassTheme(
        data: GlassThemeData(brightness: brightness),
        child: CupertinoApp(
          theme: CupertinoThemeData(
            brightness: brightness,
            primaryColor: primaryColor,
          ),
          home: CupertinoPageScaffold(
            child: Center(child: child),
          ),
        ),
      );
    }

    ShapeDecoration solidDecorationOf(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(DecoratedBox),
        ),
      );
      return box.decoration as ShapeDecoration;
    }

    void expectZeroGlassShaders(WidgetTester tester) {
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(AdaptiveGlass),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(LightweightLiquidGlass),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(GlassGlow),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(RepaintBoundary),
        ),
        findsNothing,
      );
    }

    testWidgets(
        'filled solid renders tertiarySystemFill well with zero shaders in light and dark modes',
        (tester) async {
      const shape = LiquidRoundedSuperellipse(borderRadius: 16);

      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.light,
          child: GlassButton(
            icon: const Icon(CupertinoIcons.add),
            shape: shape,
            surfaceStyle: GlassSurfaceStyle.solid,
            onTap: () {},
          ),
        ),
      );

      expectZeroGlassShaders(tester);
      expect(solidDecorationOf(tester).color, equals(kGlassSolidWellLight));
      expect(solidDecorationOf(tester).shape, equals(shape));

      final lightIconTheme = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byType(GlassButton),
              matching: find.byType(IconTheme),
            )
            .last,
      );
      expect(
        lightIconTheme.data.color!.toARGB32(),
        equals(CupertinoColors.label.color.toARGB32()),
      );

      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.dark,
          child: GlassButton(
            icon: const Icon(CupertinoIcons.add),
            shape: shape,
            surfaceStyle: GlassSurfaceStyle.solid,
            onTap: () {},
          ),
        ),
      );

      expectZeroGlassShaders(tester);
      expect(solidDecorationOf(tester).color, equals(kGlassSolidWellDark));

      final darkIconTheme = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byType(GlassButton),
              matching: find.byType(IconTheme),
            )
            .last,
      );
      expect(
        darkIconTheme.data.color!.toARGB32(),
        equals(CupertinoColors.label.darkColor.toARGB32()),
      );
    });

    testWidgets(
        'prominent solid resolves primaryColor, tintColor fallback, and explicit color',
        (tester) async {
      // 1. Default prominent solid -> resolved CupertinoTheme.primaryColor
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          child: GlassButton(
            icon: const Icon(CupertinoIcons.check_mark),
            style: GlassButtonStyle.prominent,
            surfaceStyle: GlassSurfaceStyle.solid,
            onTap: () {},
          ),
        ),
      );

      expectZeroGlassShaders(tester);
      expect(
        solidDecorationOf(tester).color,
        equals(CupertinoColors.systemBlue.darkColor),
      );

      // 2. tintColor acts as fallback accent when color is null
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.light,
          child: GlassButton(
            icon: const Icon(CupertinoIcons.check_mark),
            style: GlassButtonStyle.prominent,
            surfaceStyle: GlassSurfaceStyle.solid,
            tintColor: CupertinoColors.systemGreen,
            onTap: () {},
          ),
        ),
      );
      expect(
        solidDecorationOf(tester).color,
        equals(CupertinoColors.systemGreen.color),
      );

      // 3. Explicit color wins over tintColor and primaryColor
      const explicitPurple = Color(0xFF7B2CBF);
      await tester.pumpWidget(
        cupertinoHost(
          brightness: Brightness.light,
          child: GlassButton(
            icon: const Icon(CupertinoIcons.check_mark),
            style: GlassButtonStyle.prominent,
            surfaceStyle: GlassSurfaceStyle.solid,
            color: explicitPurple,
            tintColor: CupertinoColors.systemGreen,
            onTap: () {},
          ),
        ),
      );
      expect(solidDecorationOf(tester).color, equals(explicitPurple));
    });

    testWidgets(
        'transparent solid omits resting DecoratedBox unless color is provided',
        (tester) async {
      await tester.pumpWidget(
        cupertinoHost(
          child: GlassButton.custom(
            style: GlassButtonStyle.transparent,
            surfaceStyle: GlassSurfaceStyle.solid,
            onTap: () {},
            child: const Text('Borderless'),
          ),
        ),
      );

      expectZeroGlassShaders(tester);
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );

      const subtleFill = Color(0x22007AFF);
      await tester.pumpWidget(
        cupertinoHost(
          child: GlassButton.custom(
            style: GlassButtonStyle.transparent,
            surfaceStyle: GlassSurfaceStyle.solid,
            color: subtleFill,
            onTap: () {},
            child: const Text('Tinted Borderless'),
          ),
        ),
      );

      expect(solidDecorationOf(tester).color, equals(subtleFill));
    });

    testWidgets(
        'solid mode preserves onTap, keyboard Space/Enter, focus ring, disabled opacity, LiquidStretch, and persistPressOnDrag: false',
        (tester) async {
      var tapCount = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      await tester.pumpWidget(
        cupertinoHost(
          child: GlassButton(
            icon: const Icon(CupertinoIcons.play_fill),
            label: 'Play',
            surfaceStyle: GlassSurfaceStyle.solid,
            focusNode: focusNode,
            persistPressOnDrag: false,
            onTap: () => tapCount++,
          ),
        ),
      );

      // LiquidStretch is preserved
      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(LiquidStretch),
        ),
        findsOneWidget,
      );

      // Touch tap works
      await tester.tap(find.byType(GlassButton));
      await tester.pumpAndSettle();
      expect(tapCount, equals(1));

      // Keyboard focus ring + Space & Enter activation
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(tapCount, equals(2));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tapCount, equals(3));

      // Disabled solid button renders at 0.5 opacity and ignores tap/keys
      await tester.pumpWidget(
        cupertinoHost(
          child: GlassButton(
            icon: const Icon(CupertinoIcons.play_fill),
            label: 'Play',
            surfaceStyle: GlassSurfaceStyle.solid,
            enabled: false,
            onTap: () => tapCount++,
          ),
        ),
      );

      final opacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacities.any((o) => o.opacity == 0.5), isTrue);

      await tester.tap(find.byType(GlassButton));
      await tester.pump();
      expect(tapCount, equals(3));
    });

    testWidgets(
        'solid mode integrates with GlassMaterializeScope without remounting stateful children',
        (tester) async {
      var mountCount = 0;

      Widget buildUnderScope({
        required double glassProgress,
        required double contentOpacity,
        required double contentSigma,
      }) {
        return cupertinoHost(
          child: GlassMaterializeScope(
            glassProgress: glassProgress,
            contentOpacity: contentOpacity,
            contentSigma: contentSigma,
            child: GlassButton.custom(
              surfaceStyle: GlassSurfaceStyle.solid,
              style: GlassButtonStyle.prominent,
              color: const Color(0xFF007AFF),
              onTap: () {},
              child: _MountCounterChild(onInit: () => mountCount++),
            ),
          ),
        );
      }

      // Frame 0: fully dematerialized
      await tester.pumpWidget(
        buildUnderScope(
          glassProgress: 0.0,
          contentOpacity: 0.0,
          contentSigma: 8.0,
        ),
      );
      expectZeroGlassShaders(tester);
      expect(mountCount, equals(1));
      expect(solidDecorationOf(tester).color!.a, equals(0.0));

      final controlledOpacityAt0 = tester.widget<GlassControlledOpacity>(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(GlassControlledOpacity),
        ),
      );
      expect(controlledOpacityAt0.opacity, equals(0.0));

      // Mid-transition: 50% glassProgress, 40% contentOpacity
      await tester.pumpWidget(
        buildUnderScope(
          glassProgress: 0.5,
          contentOpacity: 0.4,
          contentSigma: 4.0,
        ),
      );
      expect(mountCount, equals(1), reason: 'Child must not remount mid-fade');
      expect(solidDecorationOf(tester).color!.a, closeTo(0.5, 0.005));

      final controlledOpacityAtHalf = tester.widget<GlassControlledOpacity>(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(GlassControlledOpacity),
        ),
      );
      expect(controlledOpacityAtHalf.opacity, closeTo(0.4, 0.005));

      // Settled: 100% materialized
      await tester.pumpWidget(
        buildUnderScope(
          glassProgress: 1.0,
          contentOpacity: 1.0,
          contentSigma: 0.0,
        ),
      );
      expect(mountCount, equals(1), reason: 'Child must not remount at settle');
      expect(solidDecorationOf(tester).color!.a, closeTo(1.0, 0.005));
    });

    testWidgets(
        'debug messages print cleanly when settings/quality passed in solid mode or color passed in glass mode',
        (tester) async {
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      await tester.pumpWidget(
        cupertinoHost(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassButton(
                icon: const Icon(CupertinoIcons.star),
                surfaceStyle: GlassSurfaceStyle.solid,
                settings: defaultTestGlassSettings,
                quality: GlassQuality.standard,
                onTap: () {},
              ),
              AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassButton(
                  icon: const Icon(CupertinoIcons.heart),
                  color: const Color(0xFFFF0000),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        logs.any((m) =>
            m.contains('settings') && m.contains('GlassSurfaceStyle.solid')),
        isTrue,
      );
      expect(
        logs.any((m) => m.contains('tintColor') && m.contains('color')),
        isTrue,
      );
    });

    testWidgets(
        'debug warning logs once across multiple rebuilds and logs zero warnings for GlassEditButton inside solid GlassContainer.card',
        (tester) async {
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(
          cupertinoHost(
            child: GlassMaterializeScope(
              glassProgress: 0.2 * (i + 1),
              contentOpacity: 1.0,
              contentSigma: 0.0,
              child: GlassButton(
                icon: Icon(i.isEven ? CupertinoIcons.star : CupertinoIcons.add),
                surfaceStyle: GlassSurfaceStyle.solid,
                settings: const LiquidGlassSettings(),
                onTap: () {},
              ),
            ),
          ),
        );
      }

      final solidLogs = logs
          .where((m) =>
              m.contains('settings') && m.contains('GlassSurfaceStyle.solid'))
          .toList();
      expect(
        solidLogs,
        hasLength(1),
        reason: 'Hint must log once rather than spamming on every rebuild',
      );

      logs.clear();
      final editController = GlassEditController();
      addTearDown(editController.dispose);

      await tester.pumpWidget(
        cupertinoHost(
          child: GlassEditScope(
            controller: editController,
            child: const GlassContainer.card(
              surfaceStyle: GlassSurfaceStyle.solid,
              child: GlassEditButton(enableHaptics: false),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassEditButton));
      await tester.pumpAndSettle();

      expect(
        logs,
        isEmpty,
        reason:
            'Composite buttons passing internal quality must not trigger false-positive warnings inside ambient solid containers',
      );
    });
  });

  group('GlassButton InheritedGlassSurfaceStyle inheritance', () {
    testWidgets(
        'auto-inherits GlassSurfaceStyle.solid inside solid GlassContainer.card and GlassGroupedSection',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContainer.card(
                surfaceStyle: GlassSurfaceStyle.solid,
                child: GlassButton(
                  key: const Key('card_btn'),
                  icon: const Icon(CupertinoIcons.add),
                  onTap: () {},
                ),
              ),
              GlassGroupedSection(
                surfaceStyle: GlassSurfaceStyle.solid,
                children: [
                  GlassButton.custom(
                    key: const Key('section_btn'),
                    onTap: () {},
                    child: const Text('In Section'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      for (final key in [const Key('card_btn'), const Key('section_btn')]) {
        expect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(AdaptiveGlass),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(GlassGlow),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(DecoratedBox),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets(
        'explicit surfaceStyle: GlassSurfaceStyle.glass overrides ambient solid card',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.sparkles),
              surfaceStyle: GlassSurfaceStyle.glass,
              useOwnLayer: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(GlassButton),
          matching: find.byType(AdaptiveGlass),
        ),
        findsOneWidget,
      );
    });
  });

  group('GlassButton tintColor in GlassSurfaceStyle.glass mode', () {
    AdaptiveGlass adaptiveGlassOf(WidgetTester tester, [Finder? scope]) =>
        tester.widget<AdaptiveGlass>(
          find.descendant(
            of: scope ?? find.byType(GlassButton),
            matching: find.byType(AdaptiveGlass),
          ),
        );

    testWidgets(
        'filled + tintColor applies GlassBodyMode.clear (~0.24 alpha) and promotes useOwnLayer inside grouped layer',
        (tester) async {
      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData.ios27(),
          child: CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.light),
            home: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: Center(
                child: GlassButton(
                  icon: const Icon(CupertinoIcons.bolt_fill),
                  tintColor: CupertinoColors.systemBlue,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final glass = adaptiveGlassOf(tester);
      expect(glass.useOwnLayer, isTrue);
      expect(glass.settings.bodyMode, equals(GlassBodyMode.clear));
      expect(
        glass.settings.glassColor.toARGB32() & 0x00FFFFFF,
        equals(CupertinoColors.systemBlue.color.toARGB32() & 0x00FFFFFF),
      );
      expect(glass.settings.glassColor.a, closeTo(0.24, 0.005));
    });

    testWidgets(
        'prominent + tintColor applies GlassBodyMode.clear (~0.85 alpha), promotes useOwnLayer, and resolves dynamic light/dark colors',
        (tester) async {
      for (final (brightness, expectedRgb) in [
        (
          Brightness.light,
          CupertinoColors.systemBlue.color.toARGB32() & 0x00FFFFFF
        ),
        (
          Brightness.dark,
          CupertinoColors.systemBlue.darkColor.toARGB32() & 0x00FFFFFF
        ),
      ]) {
        await tester.pumpWidget(
          GlassTheme(
            data: GlassThemeData(brightness: brightness),
            child: CupertinoApp(
              theme: CupertinoThemeData(brightness: brightness),
              home: AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: Center(
                  child: GlassButton(
                    icon: const Icon(CupertinoIcons.check_mark),
                    style: GlassButtonStyle.prominent,
                    tintColor: CupertinoColors.systemBlue,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        final glass = adaptiveGlassOf(tester);
        expect(glass.useOwnLayer, isTrue);
        expect(glass.settings.bodyMode, equals(GlassBodyMode.clear));
        expect(
          glass.settings.glassColor.toARGB32() & 0x00FFFFFF,
          equals(expectedRgb),
        );
        expect(glass.settings.glassColor.a, closeTo(0.85, 0.005));

        final iconTheme = tester.widget<IconTheme>(
          find
              .descendant(
                of: find.byType(GlassButton),
                matching: find.byType(IconTheme),
              )
              .last,
        );
        expect(iconTheme.data.color, equals(CupertinoColors.white));
      }
    });

    testWidgets(
        'tintColor with explicit alpha < 1.0 preserves caller alpha instead of default 0.24/0.85',
        (tester) async {
      const semiPink = Color(0x66FF2D55);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart_fill),
              tintColor: semiPink,
              onTap: () {},
            ),
          ),
        ),
      );

      final glass = adaptiveGlassOf(tester);
      expect(glass.settings.bodyMode, equals(GlassBodyMode.clear));
      expect(glass.settings.glassColor.a, closeTo(0x66 / 0xFF, 0.005));
    });

    testWidgets(
        'untinted prominent glass stays neutral adaptive frosted glass for 1.x compatibility',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: const Icon(CupertinoIcons.heart_fill),
              style: GlassButtonStyle.prominent,
              onTap: () {},
            ),
          ),
        ),
      );

      final glass = adaptiveGlassOf(tester);
      expect(glass.useOwnLayer, isTrue);
      expect(glass.settings.bodyMode, equals(GlassBodyMode.adaptive));
    });

    testWidgets(
        'tinted and prominent GlassButtons inside glass GlassContainer.card preserve avoidsRefraction vibrancy fast-path with zero descendant BackdropFilters',
        (tester) async {
      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData(brightness: Brightness.light),
          child: CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.light),
            home: CupertinoPageScaffold(
              child: Center(
                child: GlassContainer.card(
                  surfaceStyle: GlassSurfaceStyle.glass,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassButton(
                        key: const Key('nested_tinted_btn'),
                        icon: const Icon(CupertinoIcons.bolt_fill),
                        tintColor: CupertinoColors.systemBlue,
                        onTap: () {},
                      ),
                      GlassButton(
                        key: const Key('nested_prominent_btn'),
                        icon: const Icon(CupertinoIcons.check_mark),
                        style: GlassButtonStyle.prominent,
                        tintColor: CupertinoColors.systemBlue,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final expectedBlueRgb =
          CupertinoColors.systemBlue.color.toARGB32() & 0x00FFFFFF;

      for (final (key, expectedAlpha) in [
        (const Key('nested_tinted_btn'), 0.24),
        (const Key('nested_prominent_btn'), 0.85),
      ]) {
        final btnFinder = find.byKey(key);

        // Zero extra BackdropFilters or LightweightLiquidGlass shaders inside nested button
        expect(
          find.descendant(
            of: btnFinder,
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
          reason: '$key must use avoidsRefraction vibrancy fill without '
              'mounting a nested BackdropFilter',
        );
        expect(
          find.descendant(
            of: btnFinder,
            matching: find.byType(LightweightLiquidGlass),
          ),
          findsNothing,
        );

        final glass = adaptiveGlassOf(tester, btnFinder);
        expect(glass.useOwnLayer, isFalse);
        expect(glass.settings.bodyMode, equals(GlassBodyMode.clear));
        expect(
          glass.settings.glassColor.toARGB32() & 0x00FFFFFF,
          equals(expectedBlueRgb),
        );
        expect(glass.settings.glassColor.a, closeTo(expectedAlpha, 0.005));

        // Verify _VibrancyFill actually paints the tinted ShapeDecoration fill
        final vibrancyBoxes = tester.widgetList<DecoratedBox>(
          find.descendant(
            of: btnFinder,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is ShapeDecoration &&
                  (w.decoration as ShapeDecoration).color != null,
            ),
          ),
        );
        expect(vibrancyBoxes, isNotEmpty);
        final fillColor =
            (vibrancyBoxes.first.decoration as ShapeDecoration).color!;
        expect(fillColor.toARGB32() & 0x00FFFFFF, equals(expectedBlueRgb));
        expect(fillColor.a, closeTo(expectedAlpha, 0.005));
      }
    });
  });

  group('GlassButton contrast-aware foreground & solid press highlight', () {
    Finder pressOverlayWithRgb(Finder scope, int rgb) => find.descendant(
          of: scope,
          matching: find.byWidgetPredicate(
            (w) =>
                w is ColoredBox &&
                w.color.toARGB32() & 0x00FFFFFF == rgb &&
                w.color.a > 0,
          ),
        );

    testWidgets(
        'bright solid fill (#FFFFFF in dark mode) uses black icon/text and darkening press highlight',
        (tester) async {
      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData(brightness: Brightness.dark),
          child: CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.dark),
            home: CupertinoPageScaffold(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassButton(
                      key: const Key('white_icon_btn'),
                      icon: const Icon(CupertinoIcons.arrow_up),
                      surfaceStyle: GlassSurfaceStyle.solid,
                      color: const Color(0xFFFFFFFF),
                      onTap: () {},
                    ),
                    GlassButton.custom(
                      key: const Key('white_custom_btn'),
                      surfaceStyle: GlassSurfaceStyle.solid,
                      color: const Color(0xFFFFFFFF),
                      width: 200,
                      height: 48,
                      onTap: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.play_fill),
                          Text('Continue'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Icon button defaults to black foreground
      final iconBtnTheme = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byKey(const Key('white_icon_btn')),
              matching: find.byType(IconTheme),
            )
            .last,
      );
      expect(iconBtnTheme.data.color, equals(CupertinoColors.black));

      // Custom button merges black DefaultTextStyle + IconTheme
      final textCtx = tester.element(find.text('Continue'));
      expect(
        DefaultTextStyle.of(textCtx).style.color,
        equals(CupertinoColors.black),
      );
      expect(
        IconTheme.of(textCtx).color,
        equals(CupertinoColors.black),
      );

      // Press and hold on the white pill -> dark (black) overlay, never white-on-white
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('white_custom_btn'))),
      );
      await tester.pumpAndSettle();

      final darkOverlayFinder = pressOverlayWithRgb(
          find.byKey(const Key('white_custom_btn')), 0x000000);
      expect(darkOverlayFinder, findsOneWidget);
      expect(
        pressOverlayWithRgb(
            find.byKey(const Key('white_custom_btn')), 0xFFFFFF),
        findsNothing,
      );
      final darkOverlay = tester.widget<ColoredBox>(darkOverlayFinder);
      expect(darkOverlay.color.a, closeTo(0.12, 0.005));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'dark solid fill (#121316 in light mode) uses white icon/text and brightening press highlight',
        (tester) async {
      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData(brightness: Brightness.light),
          child: CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.light),
            home: CupertinoPageScaffold(
              child: Center(
                child: GlassButton.custom(
                  key: const Key('dark_custom_btn'),
                  surfaceStyle: GlassSurfaceStyle.solid,
                  color: const Color(0xFF121316),
                  width: 140,
                  height: 48,
                  onTap: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.lock_fill),
                      Text('Unlock'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final textCtx = tester.element(find.text('Unlock'));
      expect(
        DefaultTextStyle.of(textCtx).style.color,
        equals(CupertinoColors.white),
      );
      expect(
        IconTheme.of(textCtx).color,
        equals(CupertinoColors.white),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('dark_custom_btn'))),
      );
      await tester.pumpAndSettle();

      final lightOverlayFinder = pressOverlayWithRgb(
          find.byKey(const Key('dark_custom_btn')), 0xFFFFFF);
      expect(lightOverlayFinder, findsOneWidget);
      final lightOverlay = tester.widget<ColoredBox>(lightOverlayFinder);
      expect(
        lightOverlay.color.a,
        closeTo(GlassDefaults.ambientBaseLight, 0.005),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'explicit iconColor and child TextStyle.color win over automatic contrast fallback',
        (tester) async {
      const customAccent = Color(0xFFFF2D55);

      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData(brightness: Brightness.dark),
          child: CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.dark),
            home: CupertinoPageScaffold(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassButton(
                      key: const Key('explicit_icon_btn'),
                      icon: const Icon(CupertinoIcons.heart_fill),
                      iconColor: customAccent,
                      surfaceStyle: GlassSurfaceStyle.solid,
                      color: const Color(0xFFFFFFFF),
                      onTap: () {},
                    ),
                    GlassButton.custom(
                      key: const Key('explicit_text_btn'),
                      surfaceStyle: GlassSurfaceStyle.solid,
                      color: const Color(0xFFFFFFFF),
                      onTap: () {},
                      child: const Text(
                        'Custom Red',
                        style: TextStyle(color: customAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final iconBtnTheme = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byKey(const Key('explicit_icon_btn')),
              matching: find.byType(IconTheme),
            )
            .last,
      );
      expect(iconBtnTheme.data.color, equals(customAccent));

      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byKey(const Key('explicit_text_btn')),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style?.color, equals(customAccent));
    });
  });
}

class _MountCounterChild extends StatefulWidget {
  const _MountCounterChild({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_MountCounterChild> createState() => _MountCounterChildState();
}

class _MountCounterChildState extends State<_MountCounterChild> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('Materializing');
}
