import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/liquid_glass.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // LiquidShape base class
  // ──────────────────────────────────────────────────────────────────────────

  group('LiquidShape', () {
    test('LiquidOval equality and hashCode', () {
      const shape = LiquidOval();
      expect(shape.hashCode, equals(const LiquidOval().hashCode));
    });

    test('LiquidOval equality', () {
      const a = LiquidOval();
      const b = LiquidOval();
      expect(a, equals(b));
    });

    test('LiquidOval with side inequality', () {
      const a = LiquidOval();
      const b = LiquidOval(side: BorderSide(color: Colors.red));
      expect(a, isNot(equals(b)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // LiquidOval
  // ──────────────────────────────────────────────────────────────────────────

  group('LiquidOval', () {
    test('can be instantiated', () {
      const shape = LiquidOval();
      expect(shape, isA<LiquidOval>());
      expect(shape.side, BorderSide.none);
    });

    test('copyWith returns correct type', () {
      const shape = LiquidOval();
      final copy = shape.copyWith(side: const BorderSide(color: Colors.blue));
      expect(copy, isA<LiquidOval>());
    });

    test('copyWith preserves null side', () {
      const shape = LiquidOval();
      final copy = shape.copyWith();
      expect(copy.side, BorderSide.none);
    });

    test('scale returns LiquidOval', () {
      const shape = LiquidOval();
      final scaled = shape.scale(0.5);
      expect(scaled, isA<LiquidOval>());
    });

    test('getOuterPath returns a Path', () {
      const shape = LiquidOval();
      final path = shape.getOuterPath(const Rect.fromLTWH(0, 0, 100, 100));
      expect(path, isA<Path>());
    });

    test('getInnerPath returns a Path', () {
      const shape = LiquidOval();
      final path = shape.getInnerPath(const Rect.fromLTWH(0, 0, 100, 100));
      expect(path, isA<Path>());
    });

    test('paint does not throw', () {
      const shape = LiquidOval();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      shape.paint(canvas, const Rect.fromLTWH(0, 0, 100, 100));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // LiquidRoundedSuperellipse
  // ──────────────────────────────────────────────────────────────────────────

  group('LiquidRoundedSuperellipse', () {
    test('stores borderRadius', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 20);
      expect(shape.borderRadius, 20);
    });

    test('equality holds for same values', () {
      const a = LiquidRoundedSuperellipse(borderRadius: 20);
      const b = LiquidRoundedSuperellipse(borderRadius: 20);
      expect(a, equals(b));
    });

    test('inequality for different borderRadius', () {
      const a = LiquidRoundedSuperellipse(borderRadius: 10);
      const b = LiquidRoundedSuperellipse(borderRadius: 20);
      expect(a, isNot(equals(b)));
    });

    test('hashCode holds for same values', () {
      const a = LiquidRoundedSuperellipse(borderRadius: 15);
      const b = LiquidRoundedSuperellipse(borderRadius: 15);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith creates new instance with updated borderRadius', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 10);
      final copy = shape.copyWith(borderRadius: 30);
      expect(copy.borderRadius, 30);
    });

    test('copyWith preserves existing values when null passed', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 10);
      final copy = shape.copyWith();
      expect(copy.borderRadius, 10);
      expect(copy.side, BorderSide.none);
    });

    test('copyWith with side override', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 10);
      final copy =
          shape.copyWith(side: const BorderSide(color: Colors.red, width: 2));
      expect(copy.side.color, Colors.red);
    });

    test('scale multiplies borderRadius', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 20);
      final scaled = shape.scale(2.0);
      expect((scaled as LiquidRoundedSuperellipse).borderRadius,
          closeTo(40.0, 1e-10));
    });

    test('getOuterPath returns a Path', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 10);
      final path = shape.getOuterPath(const Rect.fromLTWH(0, 0, 100, 100));
      expect(path, isA<Path>());
    });

    test('getInnerPath returns a Path', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 10);
      final path = shape.getInnerPath(const Rect.fromLTWH(0, 0, 100, 100));
      expect(path, isA<Path>());
    });

    test('paint does not throw', () {
      const shape = LiquidRoundedSuperellipse(borderRadius: 10);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      shape.paint(canvas, const Rect.fromLTWH(0, 0, 100, 100));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // LiquidRoundedRectangle
  // ──────────────────────────────────────────────────────────────────────────

  group('LiquidRoundedRectangle', () {
    test('stores borderRadius', () {
      const shape = LiquidRoundedRectangle(borderRadius: 8);
      expect(shape.borderRadius, 8);
    });

    test('equality holds for same values', () {
      const a = LiquidRoundedRectangle(borderRadius: 8);
      const b = LiquidRoundedRectangle(borderRadius: 8);
      expect(a, equals(b));
    });

    test('inequality for different borderRadius', () {
      const a = LiquidRoundedRectangle(borderRadius: 4);
      const b = LiquidRoundedRectangle(borderRadius: 8);
      expect(a, isNot(equals(b)));
    });

    test('hashCode holds for same values', () {
      const a = LiquidRoundedRectangle(borderRadius: 12);
      const b = LiquidRoundedRectangle(borderRadius: 12);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith updates borderRadius', () {
      const shape = LiquidRoundedRectangle(borderRadius: 8);
      final copy = shape.copyWith(borderRadius: 16);
      expect(copy.borderRadius, 16);
    });

    test('copyWith preserves values when null passed', () {
      const shape = LiquidRoundedRectangle(borderRadius: 8);
      final copy = shape.copyWith();
      expect(copy.borderRadius, 8);
    });

    test('copyWith updates side', () {
      const shape = LiquidRoundedRectangle(borderRadius: 8);
      final copy = shape.copyWith(side: const BorderSide(color: Colors.blue));
      expect(copy.side.color, Colors.blue);
    });

    test('scale multiplies borderRadius', () {
      const shape = LiquidRoundedRectangle(borderRadius: 10);
      final scaled = shape.scale(0.5);
      expect(
          (scaled as LiquidRoundedRectangle).borderRadius, closeTo(5.0, 1e-10));
    });

    test('getOuterPath returns a Path', () {
      const shape = LiquidRoundedRectangle(borderRadius: 8);
      final path = shape.getOuterPath(const Rect.fromLTWH(0, 0, 100, 100));
      expect(path, isA<Path>());
    });

    test('getInnerPath returns a Path', () {
      const shape = LiquidRoundedRectangle(borderRadius: 8);
      final path = shape.getInnerPath(const Rect.fromLTWH(0, 0, 100, 100));
      expect(path, isA<Path>());
    });

    test('paint does not throw', () {
      const shape = LiquidRoundedRectangle(borderRadius: 8);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      shape.paint(canvas, const Rect.fromLTWH(0, 0, 100, 100));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // LiquidGlass factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  group('LiquidGlass widget constructors', () {
    test('LiquidGlass default constructor creates widget', () {
      const widget = LiquidGlass(
        shape: LiquidOval(),
        child: SizedBox.square(dimension: 100),
      );
      expect(widget, isA<Widget>());
    });

    test('LiquidGlass.grouped creates widget', () {
      const widget = LiquidGlass.grouped(
        shape: LiquidRoundedSuperellipse(borderRadius: 20),
        child: SizedBox.square(dimension: 100),
      );
      expect(widget, isA<Widget>());
    });

    test('LiquidGlass.withOwnLayer creates widget', () {
      final widget = LiquidGlass.withOwnLayer(
        shape: const LiquidRoundedRectangle(borderRadius: 12),
        settings: const LiquidGlassSettings(thickness: 20),
        child: const SizedBox.square(dimension: 100),
      );
      expect(widget, isA<Widget>());
    });

    test('LiquidGlass stores glassContainsChild', () {
      const widget = LiquidGlass(
        shape: LiquidOval(),
        glassContainsChild: true,
        child: SizedBox.square(dimension: 50),
      );
      expect(widget.glassContainsChild, isTrue);
    });

    test('LiquidGlass has defaults', () {
      const widget = LiquidGlass(
        shape: LiquidOval(),
        child: SizedBox.square(dimension: 50),
      );
      expect(widget.glassContainsChild, isFalse);
    });
  });
}
