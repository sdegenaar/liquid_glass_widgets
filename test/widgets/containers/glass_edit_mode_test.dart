import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassEditScope & GlassEditButton', () {
    testWidgets('toggles edit mode ambiently and changes button text',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            child: Column(
              children: [
                const GlassEditButton(),
                Builder(
                  builder: (context) {
                    final isEditing = GlassEditScope.isEditing(context);
                    return Text(isEditing ? 'Editing Mode' : 'View Mode');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('View Mode'), findsOneWidget);

      // Tap Edit button to enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Editing Mode'), findsOneWidget);

      // Tap Done button to exit edit mode
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('View Mode'), findsOneWidget);
    });

    testWidgets('GlassEditScope.of and stopEditing helper', (tester) async {
      late GlassEditController controller;

      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            child: Builder(
              builder: (context) {
                controller = GlassEditScope.of(context);
                return Text('Mode: ${controller.mode.name}');
              },
            ),
          ),
        ),
      );

      expect(controller.mode, GlassEditMode.inactive);
      controller.startEditing();
      await tester.pumpAndSettle();
      expect(controller.mode, GlassEditMode.active);

      controller.stopEditing();
      await tester.pumpAndSettle();
      expect(controller.mode, GlassEditMode.inactive);
    });

    testWidgets('GlassEditScope didUpdateWidget swaps controller',
        (tester) async {
      final ctrl1 = GlassEditController(initialMode: GlassEditMode.inactive);
      final ctrl2 = GlassEditController(initialMode: GlassEditMode.active);

      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            controller: ctrl1,
            child: Builder(
              builder: (context) {
                final isEditing = GlassEditScope.isEditing(context);
                return Text(isEditing ? 'Editing' : 'Not Editing');
              },
            ),
          ),
        ),
      );

      expect(find.text('Not Editing'), findsOneWidget);

      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            controller: ctrl2,
            child: Builder(
              builder: (context) {
                final isEditing = GlassEditScope.isEditing(context);
                return Text(isEditing ? 'Editing' : 'Not Editing');
              },
            ),
          ),
        ),
      );

      expect(find.text('Editing'), findsOneWidget);

      // Swap controller to null (provisions internal controller)
      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            controller: null,
            child: Builder(
              builder: (context) {
                final isEditing = GlassEditScope.isEditing(context);
                return Text(isEditing ? 'Editing' : 'Not Editing');
              },
            ),
          ),
        ),
      );

      expect(find.text('Not Editing'), findsOneWidget);
    });

    testWidgets('standard GlassEditButton with custom labels', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            child: GlassEditButton(
              editLabel: 'Custom Edit',
              doneLabel: 'Custom Done',
              color: CupertinoColors.activeGreen,
            ),
          ),
        ),
      );

      expect(find.text('Custom Edit'), findsOneWidget);
    });

    testWidgets('explicit GlassEditButton respects external state and callback',
        (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassEditButton.explicit(
            isEditing: true,
            onPressed: () => toggled = true,
          ),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      expect(toggled, isTrue);
    });
  });

  group('GlassListTile Edit Mode', () {
    testWidgets('shows delete minus badge in edit mode and confirms deletion',
        (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Contact Name'),
            onDelete: () => deleted = true,
          ),
        ),
      );

      // Minus circle badge should be present
      final minusFinder = find.byIcon(CupertinoIcons.minus_circle_fill);
      expect(minusFinder, findsOneWidget);
      expect(find.text('Delete'), findsNothing);

      // Tap minus circle badge to reveal Delete button
      await tester.tap(minusFinder);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);

      // Tap Delete button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('tapping tile body cancels delete confirmation',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Contact Name'),
            onDelete: _noop,
          ),
        ),
      );

      final minusFinder = find.byIcon(CupertinoIcons.minus_circle_fill);
      await tester.tap(minusFinder);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      // Tap on title to cancel confirmation
      await tester.tap(find.text('Contact Name'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('exiting edit mode clears delete confirmation', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Contact Name'),
            onDelete: _noop,
          ),
        ),
      );

      final minusFinder = find.byIcon(CupertinoIcons.minus_circle_fill);
      await tester.tap(minusFinder);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      // Re-render with isEditing: false
      await tester.pumpWidget(
        createTestApp(
          child: const GlassListTile(
            isEditing: false,
            title: Text('Contact Name'),
          ),
        ),
      );

      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('renders both edit badge and selection accessory in edit mode',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            canSelect: true,
            isSelected: false,
            onDelete: _noop,
            title: const Text('Multi-Accessory Row'),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.minus_circle_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.circle), findsOneWidget);
    });

    testWidgets(
        'wraps content in GlassContextMenu when contextMenuActions provided',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            title: const Text('Tile With Context Menu'),
            contextMenuActions: [
              GlassContextMenuAction(
                trailing: const Text('Cmd+C'),
                onPressed: () {},
                child: const Text('Action 1'),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(GlassContextMenu), findsOneWidget);
    });

    testWidgets('shows insertion plus badge when onInsert is provided',
        (tester) async {
      var inserted = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Add Phone'),
            onInsert: () => inserted = true,
          ),
        ),
      );

      final plusFinder = find.byIcon(CupertinoIcons.plus_circle_fill);
      expect(plusFinder, findsOneWidget);

      await tester.tap(plusFinder);
      expect(inserted, isTrue);
    });

    testWidgets('shows selection checkbox in canSelect mode', (tester) async {
      var selected = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Selectable Item'),
            canSelect: true,
            isSelected: false,
            onSelectedChanged: (val) => selected = val,
          ),
        ),
      );

      final circleFinder = find.byIcon(CupertinoIcons.circle);
      expect(circleFinder, findsOneWidget);

      await tester.tap(circleFinder);
      expect(selected, isTrue);
    });

    testWidgets('shows reorder bars handle when canReorder is true',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassListTile(
            isEditing: true,
            title: Text('Reorderable Item'),
            canReorder: true,
            reorderIndex: 0,
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.bars), findsOneWidget);
      expect(find.byType(ReorderableDragStartListener), findsOneWidget);
    });

    testWidgets('inherits edit mode from ambient GlassEditScope',
        (tester) async {
      final controller = GlassEditController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            controller: controller,
            child: GlassListTile(
              title: const Text('Scoped Item'),
              onDelete: _noop,
            ),
          ),
        ),
      );

      // Inactive initially
      expect(find.byIcon(CupertinoIcons.minus_circle_fill), findsNothing);

      // Activate edit mode
      controller.startEditing();
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.minus_circle_fill), findsOneWidget);
    });
  });

  group('GlassReorderableList', () {
    testWidgets('renders list and grouped card with dividers', (tester) async {
      final items = ['Item A', 'Item B', 'Item C'];

      await tester.pumpWidget(
        createTestApp(
          child: GlassReorderableList.grouped(
            header: const Text('GROUPED REORDERABLE'),
            footer: const Text('Drag items to reorder'),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return GlassListTile(
                key: ValueKey(items[index]),
                title: Text(items[index]),
                canReorder: true,
                reorderIndex: index,
              );
            },
            onReorder: (oldIndex, newIndex) {},
          ),
        ),
      );

      expect(find.text('GROUPED REORDERABLE'), findsOneWidget);
      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);
      expect(find.byType(GlassContainer), findsOneWidget);
      expect(find.byType(GlassDivider), findsWidgets);
    });

    testWidgets('standard GlassReorderableList with padding, header, footer',
        (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];
      int? reorderedOld;
      int? reorderedNew;

      await tester.pumpWidget(
        createTestApp(
          child: GlassReorderableList(
            header: const Text('Header Text'),
            footer: const Text('Footer Text'),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            onReorderItem: (oldIdx, newIdx) {
              reorderedOld = oldIdx;
              reorderedNew = newIdx;
            },
            itemBuilder: (context, index) {
              return GlassListTile(
                key: ValueKey(items[index]),
                isEditing: true,
                title: Text(items[index]),
                canReorder: true,
                reorderIndex: index,
              );
            },
          ),
        ),
      );

      expect(find.text('Header Text'), findsOneWidget);
      expect(find.text('Footer Text'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);

      // Drag to reorder Item 1 downwards
      final handle = find.byIcon(CupertinoIcons.bars).first;
      await tester.drag(handle, const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(reorderedOld, isNotNull);
      expect(reorderedNew, isNotNull);
    });

    testWidgets('GlassReorderableList with classic onReorder callback',
        (tester) async {
      final items = ['Alpha', 'Beta', 'Gamma'];
      int? reorderedOld;
      int? reorderedNew;

      await tester.pumpWidget(
        createTestApp(
          child: GlassReorderableList(
            itemCount: items.length,
            onReorder: (oldIdx, newIdx) {
              reorderedOld = oldIdx;
              reorderedNew = newIdx;
            },
            itemBuilder: (context, index) {
              return GlassListTile(
                key: ValueKey(items[index]),
                isEditing: true,
                title: Text(items[index]),
                canReorder: true,
                reorderIndex: index,
              );
            },
          ),
        ),
      );

      final handle = find.byIcon(CupertinoIcons.bars).first;
      await tester.drag(handle, const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(reorderedOld, isNotNull);
      expect(reorderedNew, isNotNull);
    });
  });
}

void _noop() {}
