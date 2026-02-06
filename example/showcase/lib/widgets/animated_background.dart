import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Data model for an individual animated circle
class CircleData {
  final double radius;
  final double centerX;
  final double centerY;
  final double orbitRadius;

  CircleData({
    required this.radius,
    required this.centerX,
    required this.centerY,
    required this.orbitRadius,
  });
}

/// Custom painter for rendering animated circles with blur effects
class AnimatedCirclesPainter extends CustomPainter {
  final List<Animation<double>> animations;
  final List<CircleData> circles;

  AnimatedCirclesPainter(this.animations, this.circles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A90E2).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (int i = 0; i < circles.length; i++) {
      final circle = circles[i];
      final animation = animations[i];

      final centerX = size.width * circle.centerX;
      final centerY = size.height * circle.centerY;

      final x = centerX + circle.orbitRadius * math.cos(animation.value);
      final y = centerY + circle.orbitRadius * math.sin(animation.value);

      canvas.drawCircle(
        Offset(x, y),
        circle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// A widget that provides an animated circular background
///
/// Creates multiple circles that orbit around fixed points at different speeds,
/// creating a dynamic background effect that complements glass morphism UI.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<CircleData> _circles = [];

  @override
  void initState() {
    super.initState();
    _initializeCircles();
  }

  void _initializeCircles() {
    _controllers = [];
    _animations = [];

    // Create 6 animated circles with different properties
    for (int i = 0; i < 6; i++) {
      final controller = AnimationController(
        duration: Duration(seconds: 8 + i * 4),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0,
        end: 2 * math.pi,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));

      _controllers.add(controller);
      _animations.add(animation);

      _circles.add(CircleData(
        radius: 60.0 + (i * 25),
        centerX: 0.15 + (i * 0.18),
        centerY: 0.25 + (i * 0.12),
        orbitRadius: 40.0 + (i * 20),
      ));

      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_animations),
      builder: (context, child) {
        return CustomPaint(
          painter: AnimatedCirclesPainter(_animations, _circles),
          size: Size.infinite,
        );
      },
    );
  }
}

/// A widget that provides a gradient background
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1929), // Deep navy
            Color(0xFF1A2332), // Slate blue
            Color(0xFF0D1821), // Dark blue-black
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Combined background widget with gradient and animated circles
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const GradientBackground(),
        const AnimatedBackground(),
        child,
      ],
    );
  }
}
