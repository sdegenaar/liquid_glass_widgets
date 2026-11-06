import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _opaque = Color(0xFF202124);
const _border = BorderSide(color: Color(0xFFFFFFFF), width: 1.5);

Future<GlassMenuController> _open(
  WidgetTester tester, {
  Color? opaqueColor,
  BorderSide? border,
  bool reduceTransparency = false,
}) async {
  final controller = GlassMenuController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GlassAccessibilityScope(
          reduceTransparency: reduceTransparency,
          child: Stack(
            children: [
              Positioned(
                left: 40,
                top: 80,
                child: GlassMenu(
                  controller: controller,
                  menuAlignment: GlassMenuAlignment.topLeft,
                  opaqueColor: opaqueColor,
                  border: border,
                  trigger: const SizedBox(width: 44, height: 44),
                  items: [
                    GlassMenuItem(title: 'Copy', onTap: () {}),
                    GlassMenuItem(
                      title: 'Share',
                      onTap: () {},
                      submenu: [GlassMenuItem(title: 'Mail', onTap: () {})],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  controller.open();
  await tester.pumpAndSettle();
  return controller;
}

/// Flat fills of [color] in the open menu.
Finder _fills(Color color) => find.byWidgetPredicate((widget) =>
    widget is DecoratedBox &&
    widget.decoration is ShapeDecoration &&
    (widget.decoration as ShapeDecoration).color == color);

/// Outlines drawn with [side] in the open menu.
Finder _outlines(BorderSide side) => find.byWidgetPredicate((widget) =>
    widget is DecoratedBox &&
    widget.decoration is ShapeDecoration &&
    (widget.decoration as ShapeDecoration).color == null &&
    ((widget.decoration as ShapeDecoration).shape as OutlinedBorder).side ==
        side);

Finder _glassAround(String row) =>
    find.ancestor(of: find.text(row), matching: find.byType(GlassContainer));

void main() {
  group('GlassMenu.opaqueColor', () {
    testWidgets('defaults to glass', (tester) async {
      await _open(tester);
      expect(_glassAround('Copy'), findsOneWidget);
      expect(_fills(_opaque), findsNothing);
    });

    testWidgets('draws the panel as a flat fill instead of glass',
        (tester) async {
      await _open(tester, opaqueColor: _opaque);
      expect(_glassAround('Copy'), findsNothing);
      expect(_fills(_opaque), findsOneWidget);
      // The fill covers the whole panel, behind the rows.
      final fill = tester.getRect(_fills(_opaque));
      expect(fill.contains(tester.getCenter(find.text('Copy'))), isTrue);
      expect(fill.width, closeTo(200, 0.01));
    });

    testWidgets('stays fully opaque under Reduce Transparency', (tester) async {
      await _open(tester, opaqueColor: _opaque, reduceTransparency: true);
      expect(_glassAround('Copy'), findsNothing);
      final fill = tester.widget<DecoratedBox>(_fills(_opaque));
      expect((fill.decoration as ShapeDecoration).color!.a, 1.0);
      expect(
        tester
            .widgetList<Opacity>(find.ancestor(
                of: _fills(_opaque), matching: find.byType(Opacity)))
            .every((o) => o.opacity == 1.0),
        isTrue,
      );
    });

    testWidgets('applies to submenu cards too', (tester) async {
      await _open(tester, opaqueColor: _opaque);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(_glassAround('Mail'), findsNothing);
      expect(_fills(_opaque), findsNWidgets(2));
    });

    testWidgets('rows still work', (tester) async {
      var tapped = 0;
      final controller = GlassMenuController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              controller: controller,
              opaqueColor: _opaque,
              trigger: const SizedBox(width: 44, height: 44),
              items: [GlassMenuItem(title: 'Copy', onTap: () => tapped++)],
            ),
          ),
        ),
      ));
      controller.open();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
      expect(controller.isOpen, isFalse);
    });
  });

  group('GlassMenu.border', () {
    testWidgets('draws no outline by default', (tester) async {
      await _open(tester);
      expect(_outlines(_border), findsNothing);
    });

    testWidgets('outlines the glass panel, over the rows', (tester) async {
      await _open(tester, border: _border);
      expect(_glassAround('Copy'), findsOneWidget);
      expect(_outlines(_border), findsOneWidget);
      expect(
        tester.getRect(_outlines(_border)),
        tester.getRect(_glassAround('Copy')),
      );
      // Painted after the surface in the same Stack, so it sits on top.
      final stack = tester.widget<Stack>(find
          .ancestor(of: _outlines(_border), matching: find.byType(Stack))
          .first);
      expect(stack.children, hasLength(2));
      expect(
        find.descendant(
            of: find.byWidget(stack.children.last),
            matching: _outlines(_border)),
        findsOneWidget,
      );
    });

    testWidgets('outlines an opaque panel and its submenu card',
        (tester) async {
      await _open(tester, opaqueColor: _opaque, border: _border);
      expect(_outlines(_border), findsOneWidget);
      expect(
        tester.getRect(_outlines(_border)),
        tester.getRect(_fills(_opaque)),
      );
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(_outlines(_border), findsNWidgets(2));
    });

    testWidgets('BorderSide.none draws nothing', (tester) async {
      await _open(tester, border: BorderSide.none);
      expect(_outlines(BorderSide.none), findsNothing);
    });
  });
}
