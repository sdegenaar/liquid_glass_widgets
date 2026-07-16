import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Regression tests for the two `GlassPopover` positioning fixes:
///
/// 1. **Nested-overlay offset** — the morphing overlay is placed with absolute,
///    root-relative coordinates, so it must render into the *root* overlay.
///    Rendering into a nearest/nested overlay (e.g. a `ShellRoute` content area
///    offset by a side rail) double-counts that overlay's origin and the popover
///    drifts off its trigger.
/// 2. **Frozen intrinsic height** — in intrinsic-height mode the popover used to
///    freeze the content height measured at open time; content that grew while
///    open overflowed. It must now re-measure and follow the live size.
void main() {
  group('GlassPopover renders into the root overlay', () {
    testWidgets('OverlayPortal targets OverlayChildLocation.rootOverlay',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassPopover(
                trigger:
                    const SizedBox(width: 50, height: 50, child: Text('Open')),
                contentBuilder: (context, close) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Body'),
                ),
              ),
            ),
          ),
        ),
      );

      final portal = tester.widget<OverlayPortal>(
        find.descendant(
          of: find.byType(GlassPopover),
          matching: find.byType(OverlayPortal),
        ),
      );

      expect(
        portal.overlayLocation,
        OverlayChildLocation.rootOverlay,
        reason: 'the absolutely-positioned morph must attach to the root '
            'overlay so a nested overlay does not double-offset it',
      );
    });
  });

  group('GlassPopover live re-measure (intrinsic height)', () {
    testWidgets('follows content that grows while open instead of overflowing',
        (tester) async {
      final height = ValueNotifier<double>(80);
      addTearDown(height.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassPopover(
                // Intrinsic height (no popoverHeight) — the mode the fix targets.
                popoverWidth: 220,
                trigger:
                    const SizedBox(width: 50, height: 50, child: Text('Open')),
                contentBuilder: (context, close) =>
                    ValueListenableBuilder<double>(
                  valueListenable: height,
                  builder: (context, h, _) => SizedBox(
                    key: const Key('popover-body'),
                    height: h,
                    child: const Text('Body'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pumpAndSettle();

      final body = find.byKey(const Key('popover-body'));
      expect(body, findsOneWidget);
      expect(tester.getSize(body).height, 80);

      // Grow the content while the popover is open.
      height.value = 260;
      await tester.pump(); // content rebuilds → SizeChangedLayoutNotifier fires
      await tester.pumpAndSettle(); // flush the post-frame re-measure

      // No overflow, and the popover followed the taller content.
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(body).height,
        260,
        reason: 'the popover must re-measure and grow to the live content '
            'height instead of clamping to the height frozen at open time',
      );
    });
  });
}
