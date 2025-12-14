import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A form field wrapper for glass inputs.
///
/// [GlassFormField] provides a standard way to display labels, helper text, and
/// validation errors around a glass input widget (like [GlassTextField]).
class GlassFormField extends StatelessWidget {
  /// Creates a form field wrapper.
  const GlassFormField({
    required this.child,
    super.key,
    this.label,
    this.helperText,
    this.errorText,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// The input widget (e.g., GlassTextField).
  final Widget child;

  /// Label displayed above the input.
  final String? label;

  /// Helper text displayed below the input.
  final String? helperText;

  /// Error text displayed below the input (replaces helperText).
  final String? errorText;

  /// Cross alignment of the column.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Wrap child in Theme or similar if we wanted to cascade error state,
        // but for now we just render it.
        child,

        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.redAccent.shade100,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
