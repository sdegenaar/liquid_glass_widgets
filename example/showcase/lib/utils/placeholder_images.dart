import 'package:flutter/material.dart';

/// Placeholder gradient images for testing before adding real photos
///
/// These gradients are designed to:
/// - Show layout and glass effects
/// - Provide variety in colors
/// - Be easily replaceable with real images
class PlaceholderImages {
  /// Santorini Villa - Blue/White Mediterranean
  static const LinearGradient santorini = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A90E2), // Sky blue
      Color(0xFF67B5E8), // Light blue
      Color(0xFFE8F4FA), // Almost white
    ],
  );

  /// Zermatt Chalet - White/Gray Alpine
  static const LinearGradient zermatt = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF7C8DA0), // Mountain gray
      Color(0xFFE0E7EE), // Snow white
      Color(0xFFF5F8FA), // Bright white
    ],
  );

  /// Marrakech Riad - Orange/Terracotta
  static const LinearGradient marrakech = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFE67E22), // Terracotta
      Color(0xFFD35400), // Deep orange
      Color(0xFFF39C12), // Gold
    ],
  );

  /// Bora Bora Bungalow - Turquoise/Tropical
  static const LinearGradient boraBora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00CED1), // Turquoise
      Color(0xFF48D1CC), // Medium turquoise
      Color(0xFF7FDBDA), // Light aqua
    ],
  );

  /// NYC Penthouse - Dark Blue/City Night
  static const LinearGradient nyc = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A2E), // Dark navy
      Color(0xFF2C3E50), // Slate blue
      Color(0xFF34495E), // Gray blue
    ],
  );

  /// Bali Treehouse - Green/Jungle
  static const LinearGradient bali = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF27AE60), // Jungle green
      Color(0xFF229954), // Dark green
      Color(0xFF52BE80), // Light green
    ],
  );

  /// Get gradient by destination ID
  static LinearGradient getById(String id) {
    switch (id) {
      case '1':
        return santorini;
      case '2':
        return zermatt;
      case '3':
        return marrakech;
      case '4':
        return boraBora;
      case '5':
        return nyc;
      case '6':
        return bali;
      default:
        return santorini;
    }
  }

  /// Build a gradient container for a destination
  static Widget buildPlaceholder({
    required String destinationId,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: getById(destinationId),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 80,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
