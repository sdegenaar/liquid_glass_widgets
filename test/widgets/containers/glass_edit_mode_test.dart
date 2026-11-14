import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassEditScope & GlassEditButton', () {
    testWidgets('toggles edit mode ambiently and changes button text', (
      tester,
    ) async {
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

    testWidgets('GlassEditScope didUpdateWidget swaps controller', (
      tester,
    ) async {
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

    testWidgets(
      'explicit GlassEditButton respects external state and callback',
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
      },
    );
  });

  group('GlassListTile Edit Mode', () {
    testWidgets('shows delete minus badge in edit mode and confirms deletion', (
      tester,
    ) async {
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

    testWidgets('tapping tile body cancels delete confirmation', (
      tester,
    ) async {
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

    testWidgets(
      'renders both edit badge and selection accessory in edit mode',
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
      },
    );

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
      },
    );

    testWidgets('shows insertion plus badge when onInsert is provided', (
      tester,
    ) async {
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

    testWidgets('tapping the row body toggles selection in edit mode', (
      tester,
    ) async {
      bool? selected;

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

      await tester.tap(find.text('Selectable Item'));
      expect(selected, isTrue);
    });

    testWidgets(
      'delete confirmation shows the trash icon with Delete beneath',
      (tester) async {
        var deleted = false;

        await tester.pumpWidget(
          createTestApp(
            child: GlassListTile(
              isEditing: true,
              title: const Text('Row'),
              onDelete: () => deleted = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(CupertinoIcons.minus_circle_fill));
        await tester.pumpAndSettle();

        final icon = find.byIcon(CupertinoIcons.trash);
        final label = find.text('Delete');
        expect(icon, findsOneWidget);
        expect(label, findsOneWidget);
        // The caption sits underneath the button, not inline beside it.
        expect(
          tester.getTopLeft(label).dy,
          greaterThan(tester.getBottomLeft(icon).dy),
        );

        await tester.tap(label);
        await tester.pumpAndSettle();
        expect(deleted, isTrue);
      },
    );

    testWidgets('shows reorder bars handle when canReorder is true', (
      tester,
    ) async {
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

      expect(find.byType(CustomPaint), findsWidgets);
      expect(_reorderGrabber(), findsOneWidget);
    });

    testWidgets('pressing the grabber lifts the row before any movement', (
      tester,
    ) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: GlassReorderableList.grouped(
            itemCount: 3,
            itemBuilder: (context, index) => GlassListTile(
              key: ValueKey('item $index'),
              isEditing: true,
              title: Text('Item $index'),
              canReorder: true,
              reorderIndex: index,
            ),
            onReorder: (oldIndex, newIndex) {},
          ),
        ),
      );

      final handle = _reorderGrabber().first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();

      // No pointer movement yet: the lift (and its haptic tick) has begun.
      expect(haptics, contains('HapticFeedbackType.selectionClick'));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('press-and-hold on the row body lifts it; a tap does not', (
      tester,
    ) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: GlassReorderableList.grouped(
            itemCount: 3,
            itemBuilder: (context, index) => GlassListTile(
              key: ValueKey('item $index'),
              isEditing: true,
              title: Text('Item $index'),
              canReorder: true,
              reorderIndex: index,
            ),
            onReorder: (oldIndex, newIndex) {},
          ),
        ),
      );

      // A quick tap on the body never lifts the row.
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);

      // Holding the body past the long-press delay does.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Item 1')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(haptics, contains('HapticFeedbackType.selectionClick'));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('inherits edit mode from ambient GlassEditScope', (
      tester,
    ) async {
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

    testWidgets('standard GlassReorderableList with padding, header, footer', (
      tester,
    ) async {
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
      final handle = _reorderGrabber().first;
      await tester.drag(handle, const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(reorderedOld, isNotNull);
      expect(reorderedNew, isNotNull);
    });

    testWidgets('GlassReorderableList with classic onReorder callback', (
      tester,
    ) async {
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

      final handle = _reorderGrabber().first;
      await tester.drag(handle, const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(reorderedOld, isNotNull);
      expect(reorderedNew, isNotNull);
    });

    testWidgets(
      'solid grouped GlassReorderableList inside GlassEditScope splits segments around middle dragged item',
      (tester) async {
        final editController = GlassEditController(
          initialMode: GlassEditMode.active,
        );
        addTearDown(editController.dispose);
        final items = ['Row 0', 'Row 1', 'Row 2'];

        await tester.pumpWidget(
          createTestApp(
            child: GlassEditScope(
              controller: editController,
              child: GlassReorderableList.grouped(
                surfaceStyle: GlassSurfaceStyle.solid,
                itemCount: items.length,
                onReorderItem: (oldIdx, newIdx) {},
                itemBuilder: (context, index) => GlassListTile(
                  key: ValueKey(items[index]),
                  title: Text(items[index]),
                  canReorder: true,
                  reorderIndex: index,
                ),
              ),
            ),
          ),
        );

        // Drag the middle item (index 1) so both isAbove (index 0) and !isAbove (index 2) build
        final middleHandle = _reorderGrabber().at(1);
        final gesture = await tester.startGesture(
          tester.getCenter(middleHandle),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'GlassListTile delete confirmation toggles off on second minus tap, resets when exiting edit mode, and animates removal',
      (tester) async {
        final editController = GlassEditController(
          initialMode: GlassEditMode.active,
        );
        addTearDown(editController.dispose);
        bool deleted = false;
        late StateSetter outerSetState;

        await tester.pumpWidget(
          createTestApp(
            child: GlassEditScope(
              controller: editController,
              child: StatefulBuilder(
                builder: (context, setState) {
                  outerSetState = setState;
                  return GlassListTile(
                    title: const Text('Confirmable Row'),
                    canSelect: true,
                    isSelected: true,
                    onTap: _noop,
                    onDelete: () => deleted = true,
                  );
                },
              ),
            ),
          ),
        );

        // Tap minus to open confirmation, then tap minus immediately before slide clips it to reverse it
        await tester.tap(find.byIcon(CupertinoIcons.minus_circle_fill));
        await tester.pump();
        await tester.tap(find.byIcon(CupertinoIcons.minus_circle_fill));
        await tester.pumpAndSettle();

        // Open confirmation again, then exit ambient edit mode via GlassEditController so build() resets it
        await tester.tap(find.byIcon(CupertinoIcons.minus_circle_fill));
        await tester.pumpAndSettle();
        editController.stopEditing();
        await tester.pumpAndSettle();

        // Test tap down + cancel highlight in light mode when not editing
        final gHighlight = await tester.startGesture(
          tester.getCenter(find.text('Confirmable Row')),
        );
        await tester.pump();
        await gHighlight.cancel();
        await tester.pump();

        // Re-enter edit mode, open confirmation, tap Delete, and trigger rebuild mid-removal animation
        editController.startEditing();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(CupertinoIcons.minus_circle_fill));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pump(const Duration(milliseconds: 50));
        outerSetState(() {});
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();
        expect(deleted, isTrue);
      },
    );
  });
}

void _noop() {}

/// Matches the reorder grabber, including subclasses of
/// [ReorderableDragStartListener] (`find.byType` only matches the exact type).
Finder _reorderGrabber() =>
    find.byWidgetPredicate((w) => w is ReorderableDragStartListener);
