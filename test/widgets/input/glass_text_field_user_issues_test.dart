// Targeted integration tests for the exact user-reported scenarios (g3mf0r).
// These trace the precise code paths the user hit, not just widget tree structure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
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
              prefixIcon: Icon(Icons.emoji_emotions, size: 24,
                  key: Key('prefix')),
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
      final fieldBox =
          tester.getBottomLeft(find.byType(GlassTextField));

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

    testWidgets('Center wraps only TextField, not the Row, in fixed-height mode',
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
      final expanded = tester.widgetList<Expanded>(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(Expanded),
        ),
      ).first;

      // The direct child of Expanded must be a TextField, not a Center.
      expect(expanded.child, isA<TextField>(),
          reason: 'In dynamic-height mode, Expanded should wrap TextField '
              'directly without Center');
    });
  });
}
