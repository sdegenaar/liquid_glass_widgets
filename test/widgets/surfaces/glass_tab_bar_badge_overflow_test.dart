// A GlassBadge on a tab sits above its icon and paints a soft halo that
// reaches past the top edge of the tab track. The lens masks that split
// selected from unselected content must not cut that overflow off.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _gestureRegion = ValueKey<String>('glass_tab_bar_gesture_region');

Widget _bar(GlobalKey capture) => RepaintBoundary(
      key: capture,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassTabBar.bottom(
              quality: GlassQuality.minimal,
              selectedIndex: 0,
              onTabSelected: (_) {},
              tabs: const [
                GlassTab(icon: Icon(Icons.home), label: 'Home'),
                GlassTab(
                  icon: GlassBadge(
                    count: 1,
                    quality: GlassQuality.minimal,
                    child: Icon(Icons.chat),
                  ),
                  label: 'Chat',
                ),
              ],
            ),
          ),
        ),
      ),
    );

/// How much redder the pixel just above the track is in the badge's column
/// than in the first tab's column, on the same row.
///
/// The badge is red, so its halo tints that pixel; a halo cut at the track's
/// edge leaves it the same colour as the rest of the row. Comparing against
/// the same row cancels the page background and the bar's own shadow.
Future<int> _haloRedness(WidgetTester tester, GlobalKey capture) async {
  final track = tester.getRect(find.byKey(_gestureRegion));
  final badgeColumn = tester.getCenter(find.text('1').first).dx.round();
  final plainColumn = (track.left + track.width / 4).round();
  final row = (track.top - 3).round();
  final boundary =
      capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late int redness;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final rgba =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      int redOverGreen(int column) {
        final pixel = (row * image.width + column) * 4;
        return rgba.getUint8(pixel) - rgba.getUint8(pixel + 1);
      }

      redness = redOverGreen(badgeColumn) - redOverGreen(plainColumn);
    } finally {
      image.dispose();
    }
  });
  return redness;
}

void main() {
  group('GlassTabBar badge overflow', () {
    // Tests paint shadows as solid blocks by default; the halo needs the real
    // blur. The flag has to be back to its default before the test body ends
    // (the binding checks it there), so it cannot live in setUp / tearDown.
    Future<void> withRealShadows(Future<void> Function() body) async {
      final wereDisabled = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await body();
      } finally {
        debugDisableShadows = wereDisabled;
      }
    }

    testWidgets('the badge halo shows above the track at rest', (tester) async {
      await withRealShadows(() async {
        final capture = GlobalKey();
        await tester.pumpWidget(_bar(capture));
        await tester.pumpAndSettle();

        expect(await _haloRedness(tester, capture), greaterThan(5));
      });
    });

    testWidgets('the badge halo is not cropped while the lens is lifted',
        (tester) async {
      await withRealShadows(() async {
        final capture = GlobalKey();
        await tester.pumpWidget(_bar(capture));
        await tester.pumpAndSettle();

        // Press and nudge the selected tab: the lens lifts and the icon
        // layers switch to their in-motion clip.
        final region = tester.getRect(find.byKey(_gestureRegion));
        final gesture = await tester.startGesture(
          Offset(region.left + region.width / 4, region.center.dy),
        );
        await tester.pump(const Duration(milliseconds: 120));
        await gesture.moveBy(const Offset(6, 0));
        await tester.pump(const Duration(milliseconds: 120));

        expect(await _haloRedness(tester, capture), greaterThan(5));

        await gesture.up();
        await tester.pumpAndSettle();
      });
    });
  });

  test('the inverse lens mask keeps content above and beside the track', () {
    const size = Size(400, 64);
    for (final alignment in [Alignment.centerLeft, Alignment.centerRight]) {
      Path mask({required bool inverse}) => JellyClipper(
            itemCount: 5,
            alignment: alignment,
            thickness: 0,
            expansion: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            transform: Matrix4.identity(),
            borderRadius: 32,
            inverse: inverse,
          ).getClip(size);
      final selected = mask(inverse: false);
      final unselected = mask(inverse: true);

      // A badge is anchored a few pixels above its icon: just outside the
      // track. Only the unselected layer may show it; the lens never does.
      for (final point in const [Offset(280, -6), Offset(360, -6)]) {
        expect(unselected.contains(point), isTrue);
        expect(selected.contains(point), isFalse);
      }
      // Inside the track the two masks stay complementary.
      for (final point in const [Offset(40, 32), Offset(360, 32)]) {
        expect(selected.contains(point), !unselected.contains(point));
      }
    }
  });
}
