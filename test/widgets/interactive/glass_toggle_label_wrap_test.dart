import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// At iOS's largest text size (AX5, 53 pt body text over 17 pt) a filter
/// label is wider than a phone: it wraps onto more lines, as a SwiftUI
/// button's does, rather than ending in an ellipsis.
void main() {
  Widget host(Widget child, {TextScaler? textScaler}) => CupertinoApp(
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: app!,
        ),
        home: CupertinoPageScaffold(child: Center(child: child)),
      );

  RenderParagraph paragraphOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text));

  group('GlassToggle.button label', () {
    testWidgets('wraps at the largest text size instead of being cut',
        (tester) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final label in ['10 s', 'Weekdays', 'Recently Added'])
              GlassToggle.button(
                value: label == 'Weekdays',
                onChanged: (_) {},
                label: label,
              ),
          ]),
        ),
        textScaler: const TextScaler.linear(53 / 17),
      ));

      expect(tester.takeException(), isNull);
      for (final label in ['10 s', 'Weekdays', 'Recently Added']) {
        final paragraph = paragraphOf(tester, label);
        expect(paragraph.didExceedMaxLines, isFalse,
            reason: '"$label" is cut off');
      }
      // The capsule grows to hold the lines.
      final wrapped = paragraphOf(tester, 'Recently Added');
      expect(
        tester.getSize(find.byType(GlassToggle).last).height,
        greaterThan(wrapped.size.height),
      );
    });

    testWidgets('a label that fits stays on one line', (tester) async {
      await tester.pumpWidget(host(
        GlassToggle.button(value: false, onChanged: (_) {}, label: 'Unread'),
      ));

      expect(tester.getSize(find.byType(GlassToggle)).height, 34);
      expect(paragraphOf(tester, 'Unread').didExceedMaxLines, isFalse);
    });

    testWidgets('an explicit height keeps the label on one line',
        (tester) async {
      await tester.pumpWidget(host(SizedBox(
        width: 110,
        child: GlassToggle.button(
          value: false,
          onChanged: (_) {},
          label: 'Very Long Filter Label',
          height: 28,
        ),
      )));

      expect(tester.takeException(), isNull);
      final paragraph = paragraphOf(tester, 'Very Long Filter Label');
      expect(paragraph.maxLines, 1);
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.byType(GlassToggle)).height, 28);
    });
  });
}
