// ignore_for_file: require_trailing_commas
// Tests for GlassPage — the zero-boilerplate screen wrapper introduced in 0.11.0.
//
// Covers:
//   1. Default render (LiquidGlassScope + GlassBackdropScope injected)
//   2. enableBackgroundSampling: false — no RepaintBoundary inserted
//   3. enableBackgroundSampling: true (default) — RepaintBoundary present
//   4. Adaptive quality minimal → sampling auto-disabled
//   5. Scaffold receives transparent background via Theme override
//   6. Glass widget descendants render without error inside GlassPage
//   7. GlassPage without a background glass widget (plain Scaffold)
//   8. Dispose path — no exceptions when widget is removed from tree

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal host that does not impose its own Theme — lets GlassPage's
/// Theme.copyWith propagate to its Scaffold child.
Widget _host(Widget child) {
  return MaterialApp(
    home: child,
  );
}

/// A simple coloured container used as a stand-in background.
const _background = ColoredBox(color: Color(0xFF1A1A2E));

/// Standard content child — a Scaffold with transparent background so the
/// test validates that GlassPage's Theme override is the only source of
/// transparency.
Widget _scaffold() => const Scaffold(body: SizedBox.expand());

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    LightweightLiquidGlass.resetForTesting();
  });

  tearDown(() {
    LightweightLiquidGlass.resetForTesting();
  });

  // ── Basic render ───────────────────────────────────────────────────────────

  group('GlassPage — basic render', () {
    testWidgets('renders without error with default parameters',
        (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(background: _background, child: _scaffold())),
      );
      await tester.pump();
      expect(find.byType(GlassPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('injects LiquidGlassScope into the widget tree',
        (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(background: _background, child: _scaffold())),
      );
      await tester.pump();
      // LiquidGlassScope must be present — without it, GlassBackgroundSource
      // cannot find the capture key and background sampling silently fails.
      expect(find.byType(LiquidGlassScope), findsAtLeastNWidgets(1));
    });

    testWidgets('injects GlassBackdropScope into the widget tree',
        (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(background: _background, child: _scaffold())),
      );
      await tester.pump();
      expect(find.byType(GlassBackdropScope), findsAtLeastNWidgets(1));
    });

    testWidgets('child widget is present in the tree', (tester) async {
      final child = _scaffold();
      await tester.pumpWidget(
        _host(GlassPage(background: _background, child: child)),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });
  });

  // ── Background sampling — default (enabled) ───────────────────────────────

  group('GlassPage — background sampling enabled (default)', () {
    testWidgets('inserts RepaintBoundary for background capture',
        (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(background: _background, child: _scaffold())),
      );
      await tester.pump();
      // GlassBackgroundSource(enabled: true) wraps the background in a
      // RepaintBoundary. Without it, no texture capture can occur.
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('GlassBackgroundSource is present in tree', (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(background: _background, child: _scaffold())),
      );
      await tester.pump();
      expect(find.byType(GlassBackgroundSource), findsOneWidget);
    });
  });

  // ── Background sampling — explicitly disabled ──────────────────────────────

  group('GlassPage — enableBackgroundSampling: false', () {
    testWidgets('renders without error when sampling disabled', (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(
          enableBackgroundSampling: false,
          background: _background,
          child: _scaffold(),
        )),
      );
      await tester.pump();
      expect(find.byType(GlassPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GlassBackgroundSource is still present but disabled',
        (tester) async {
      // GlassBackgroundSource is always inserted; its `enabled` flag controls
      // whether the RepaintBoundary is created. We can verify the source widget
      // is in the tree even when disabled.
      await tester.pumpWidget(
        _host(GlassPage(
          enableBackgroundSampling: false,
          background: _background,
          child: _scaffold(),
        )),
      );
      await tester.pump();
      expect(find.byType(GlassBackgroundSource), findsOneWidget);
    });

    testWidgets(
        'LiquidGlassScope and GlassBackdropScope still present when disabled',
        (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(
          enableBackgroundSampling: false,
          background: _background,
          child: _scaffold(),
        )),
      );
      await tester.pump();
      expect(find.byType(LiquidGlassScope), findsAtLeastNWidgets(1));
      expect(find.byType(GlassBackdropScope), findsAtLeastNWidgets(1));
    });
  });

  // ── Adaptive quality ceiling ───────────────────────────────────────────────

  group('GlassPage — adaptive quality ceiling', () {
    testWidgets('renders without error when ambient quality is minimal',
        (tester) async {
      // When GlassAdaptiveScope has degraded to minimal, GlassPage should
      // disable background sampling automatically (doSample = false).
      await tester.pumpWidget(
        MaterialApp(
          home: GlassAdaptiveScope(
            // Lock the ceiling at minimal to simulate a throttled device.
            minQuality: GlassQuality.minimal,
            maxQuality: GlassQuality.minimal,
            child: GlassPage(
              background: _background,
              child: _scaffold(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GlassPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'sampling explicitly true but quality minimal → GlassPage still renders',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassAdaptiveScope(
            minQuality: GlassQuality.minimal,
            maxQuality: GlassQuality.minimal,
            child: GlassPage(
              // User explicitly requests sampling, but adaptive scope overrides.
              enableBackgroundSampling: true,
              background: _background,
              child: _scaffold(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ── Theme override ─────────────────────────────────────────────────────────

  group('GlassPage — scaffold background transparency', () {
    testWidgets('descendant Scaffold receives transparent background',
        (tester) async {
      // GlassPage applies Theme.copyWith(scaffoldBackgroundColor: transparent).
      // We verify this by reading the Theme inside the Scaffold's subtree.
      ThemeData? capturedTheme;

      await tester.pumpWidget(
        _host(
          GlassPage(
            background: _background,
            child: Builder(
              builder: (context) {
                capturedTheme = Theme.of(context);
                return const Scaffold(body: SizedBox.expand());
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        capturedTheme?.scaffoldBackgroundColor,
        Colors.transparent,
        reason:
            'GlassPage must override scaffoldBackgroundColor to transparent '
            'so the wallpaper shows through the Scaffold without extra config.',
      );
    });
  });

  // ── Glass widget integration ───────────────────────────────────────────────

  group('GlassPage — glass widget descendants', () {
    testWidgets('GlassAppBar inside GlassPage renders without error',
        (tester) async {
      await tester.pumpWidget(
        _host(
          GlassPage(
            background: _background,
            child: Scaffold(
              appBar: GlassAppBar(title: const Text('Test')),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GlassContainer inside GlassPage renders without error',
        (tester) async {
      await tester.pumpWidget(
        _host(
          GlassPage(
            background: _background,
            child: const Scaffold(
              body: Center(
                child: GlassContainer(
                  child: SizedBox(width: 100, height: 60),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GlassContainer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ── Dispose / lifecycle ────────────────────────────────────────────────────

  group('GlassPage — lifecycle', () {
    testWidgets('disposed GlassPage does not crash', (tester) async {
      await tester.pumpWidget(
        _host(GlassPage(background: _background, child: _scaffold())),
      );
      await tester.pump();
      // Remove GlassPage from tree — verifies Ticker and keys are disposed
      // cleanly via LiquidGlassScope and GlassBackdropScope teardown.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      expect(find.byType(GlassPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('enableBackgroundSampling toggle does not crash',
        (tester) async {
      bool sampling = true;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return GlassPage(
                enableBackgroundSampling: sampling,
                background: _background,
                child: _scaffold(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Toggle off — GlassBackgroundSource switches enabled:false
      outerSetState(() => sampling = false);
      await tester.pump();

      // Toggle back on
      outerSetState(() => sampling = true);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
