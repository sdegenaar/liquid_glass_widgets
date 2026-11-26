import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassToggle.button', () {
    testWidgets('renders label-only toggle and fires onChanged on tap',
        (tester) async {
      bool? lastValue;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassToggle.button(
              value: false,
              onChanged: (v) => lastValue = v,
              label: 'Starred',
            ),
          ),
        ),
      );

      expect(find.text('Starred'), findsOneWidget);
      await tester.tap(find.byType(GlassToggle));
      await tester.pump();

      expect(lastValue, isTrue);
    });

    testWidgets('toggles from true to false on tap', (tester) async {
      bool current = true;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) => AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassToggle.button(
                value: current,
                onChanged: (v) => setState(() => current = v),
                label: 'Wi-Fi',
                icon: const Icon(CupertinoIcons.wifi),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.wifi), findsOneWidget);

      await tester.tap(find.byType(GlassToggle));
      await tester.pump();
      expect(current, isFalse);

      await tester.tap(find.byType(GlassToggle));
      await tester.pump();
      expect(current, isTrue);
    });

    testWidgets('renders icon-only toggle with calibrated min size (44x34)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Center(
              child: GlassToggle.button(
                value: false,
                onChanged: (_) {},
                icon: const Icon(CupertinoIcons.heart),
                semanticLabel: 'Favorite',
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(GlassToggle));
      expect(size.width, greaterThanOrEqualTo(44.0));
      expect(size.height, greaterThanOrEqualTo(34.0));
    });

    testWidgets('renders custom child and inherits foreground color',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassToggle.button(
              value: true,
              onChanged: (_) {},
              activeColor: CupertinoColors.systemBlue,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.sparkles),
                  SizedBox(width: 4),
                  Text('Custom'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.sparkles), findsOneWidget);

      final textStyle = DefaultTextStyle.of(
        tester.element(find.text('Custom')),
      ).style;
      expect(textStyle.color?.toARGB32(), CupertinoColors.white.toARGB32());
    });

    test('constructor asserts on invalid content combinations', () {
      expect(
        () => GlassToggle.button(
          value: false,
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );

      expect(
        () => GlassToggle.button(
          value: false,
          onChanged: (_) {},
          label: 'Both',
          child: const Text('Child'),
        ),
        throwsAssertionError,
      );

      expect(
        () => GlassToggle.button(
          value: false,
          onChanged: (_) {},
          icon: const Icon(CupertinoIcons.star),
          child: const Text('Child'),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('switches GlassButtonStyle and tintColor between off and on',
        (tester) async {
      Widget buildToggle(bool value) => createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassToggle.button(
                value: value,
                onChanged: (_) {},
                label: 'Filter',
                activeColor: CupertinoColors.systemOrange,
              ),
            ),
          );

      await tester.pumpWidget(buildToggle(false));
      var button = tester.widget<GlassButton>(find.byType(GlassButton));
      expect(button.style, GlassButtonStyle.filled);
      expect(button.tintColor, isNull);
      expect(button.isToggled, isFalse);

      await tester.pumpWidget(buildToggle(true));
      button = tester.widget<GlassButton>(find.byType(GlassButton));
      expect(button.style, GlassButtonStyle.prominent);
      expect(
        button.tintColor?.toARGB32(),
        CupertinoColors.systemOrange
            .resolveFrom(tester.element(find.byType(GlassToggle)))
            .toARGB32(),
      );
      expect(button.isToggled, isTrue);
    });

    testWidgets(
        'auto-contrasts foreground on bright activeColor and respects overrides',
        (tester) async {
      // Bright yellow (luminance > 0.55) flips foreground to black.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassToggle.button(
              value: true,
              onChanged: (_) {},
              label: 'Yellow',
              activeColor: const Color(0xFFFFEE00),
            ),
          ),
        ),
      );
      var text = tester.widget<Text>(find.text('Yellow'));
      expect(text.style?.color?.toARGB32(), CupertinoColors.black.toARGB32());

      // Explicit activeForegroundColor overrides contrast flip.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassToggle.button(
              value: true,
              onChanged: (_) {},
              label: 'Yellow',
              activeColor: const Color(0xFFFFEE00),
              activeForegroundColor: CupertinoColors.systemPurple,
            ),
          ),
        ),
      );
      text = tester.widget<Text>(find.text('Yellow'));
      expect(
        text.style?.color?.toARGB32(),
        CupertinoColors.systemPurple
            .resolveFrom(tester.element(find.byType(GlassToggle)))
            .toARGB32(),
      );

      // Explicit foregroundColor applies when off.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassToggle.button(
              value: false,
              onChanged: (_) {},
              label: 'Off',
              foregroundColor: CupertinoColors.systemPink,
            ),
          ),
        ),
      );
      text = tester.widget<Text>(find.text('Off'));
      expect(
        text.style?.color?.toARGB32(),
        CupertinoColors.systemPink
            .resolveFrom(tester.element(find.byType(GlassToggle)))
            .toARGB32(),
      );
    });

    testWidgets('supports GlassSurfaceStyle.solid directly and via inheritance',
        (tester) async {
      // Direct solid mode (off & on) mounts zero AdaptiveGlass.
      await tester.pumpWidget(
        createTestApp(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassToggle.button(
                value: false,
                onChanged: (_) {},
                label: 'Solid Off',
                surfaceStyle: GlassSurfaceStyle.solid,
                color: const Color(0xFFE5E5EA),
              ),
              GlassToggle.button(
                value: true,
                onChanged: (_) {},
                label: 'Solid On',
                surfaceStyle: GlassSurfaceStyle.solid,
                color: const Color(0xFFE5E5EA),
                activeColor: CupertinoColors.systemGreen,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(AdaptiveGlass), findsNothing);
      final buttons =
          tester.widgetList<GlassButton>(find.byType(GlassButton)).toList();
      expect(buttons[0].style, GlassButtonStyle.filled);
      expect(buttons[0].color, const Color(0xFFE5E5EA));
      expect(buttons[1].style, GlassButtonStyle.prominent);
      expect(buttons[1].color, isNull);
      expect(
        buttons[1].tintColor?.toARGB32(),
        CupertinoColors.systemGreen
            .resolveFrom(tester.element(find.text('Solid On')))
            .toARGB32(),
      );

      // Inherited solid mode via InheritedGlassSurfaceStyle.
      await tester.pumpWidget(
        createTestApp(
          child: InheritedGlassSurfaceStyle(
            surfaceStyle: GlassSurfaceStyle.solid,
            child: GlassToggle.button(
              value: false,
              onChanged: (_) {},
              label: 'Inherited Solid',
            ),
          ),
        ),
      );
      expect(find.byType(AdaptiveGlass), findsNothing);
    });

    testWidgets('disabled state (onChanged: null) is inert and reports toggled',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: const GlassToggle.button(
                value: true,
                onChanged: null,
                label: 'Locked',
              ),
            ),
          ),
        );

        final button = tester.widget<GlassButton>(find.byType(GlassButton));
        expect(button.enabled, isFalse);
        expect(button.style, GlassButtonStyle.filled);
        expect(button.stretch, 0.0);
        expect(button.interactionScale, 1.0);
        expect(button.glowRadius, 0.0);
        expect(button.isStationary, isTrue);

        // Regression guard: in glass mode, AdaptiveGlass must NEVER sit beneath
        // an ancestor Opacity saveLayer (which drops backdrop refraction on
        // Impeller Metal); only the interior content is dimmed at 0.5.
        expect(
          find.ancestor(
            of: find.byType(AdaptiveGlass),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(AdaptiveGlass),
            matching: find.byWidgetPredicate(
              (w) => w is Opacity && w.opacity == 0.5,
            ),
          ),
          findsOneWidget,
        );

        final node = tester.getSemantics(find.bySemanticsLabel('Locked'));
        expect(
          node,
          matchesSemantics(
            label: 'Locked',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            hasToggledState: true,
            isToggled: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('emits toggled button semantics on a single node',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassToggle.button(
                value: false,
                onChanged: (_) {},
                icon: const Icon(CupertinoIcons.bell),
                semanticLabel: 'Notifications',
              ),
            ),
          ),
        );

        final node =
            tester.getSemantics(find.bySemanticsLabel('Notifications'));
        expect(
          node,
          matchesSemantics(
            label: 'Notifications',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasToggledState: true,
            isToggled: false,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('activates via keyboard Space and Enter when focused',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final values = <bool>[];

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassToggle.button(
              value: false,
              onChanged: values.add,
              label: 'Bold',
              focusNode: focusNode,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(values, [true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(values, [true, true]);
    });

    testWidgets('respects enableHaptics flag on tap', (tester) async {
      final hapticCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassToggle.button(
                  value: false,
                  onChanged: (_) {},
                  label: 'With Haptics',
                ),
                GlassToggle.button(
                  value: false,
                  onChanged: (_) {},
                  label: 'Silent',
                  enableHaptics: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('With Haptics'));
      await tester.pump();
      expect(hapticCalls, ['HapticFeedbackType.selectionClick']);

      hapticCalls.clear();
      await tester.tap(find.text('Silent'));
      await tester.pump();
      expect(hapticCalls, isEmpty);
    });

    testWidgets('handles explicit compact height without overflow',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: Center(
              child: GlassToggle.button(
                value: false,
                onChanged: (_) {},
                label: 'Compact',
                height: 28,
                width: 110,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(GlassToggle));
      expect(size, const Size(110, 28));
    });

    testWidgets('GlassButton.isToggled forwards toggle semantics directly',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassButton(
                icon: const Icon(CupertinoIcons.mic),
                label: 'Mute',
                isToggled: true,
                onTap: () {},
              ),
            ),
          ),
        );

        final node = tester.getSemantics(find.bySemanticsLabel('Mute'));
        expect(
          node,
          matchesSemantics(
            label: 'Mute',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasToggledState: true,
            isToggled: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        'GlassInteractionSilence is exported cleanly from main entrypoint',
        (tester) async {
      var received = false;

      await tester.pumpWidget(
        createTestApp(
          child: NotificationListener<InteractionNotification>(
            onNotification: (_) {
              received = true;
              return true;
            },
            child: GlassInteractionSilence(
              child: GlassToggle.button(
                value: false,
                onChanged: (_) {},
                label: 'Silenced',
                surfaceStyle: GlassSurfaceStyle.solid,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Silenced'));
      await tester.pump();
      expect(received, isTrue);
    });
  });
}
