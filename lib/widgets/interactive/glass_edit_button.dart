import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../shared/glass_edit_scope.dart';
import 'glass_button.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

/// A button that toggles edit mode, directly matching SwiftUI's `EditButton()`.
///
/// When pressed, [GlassEditButton] toggles the ambient [GlassEditScope]
/// between [GlassEditMode.inactive] and [GlassEditMode.active].
///
/// - Displays **Edit** when inactive.
/// - Displays **Done** in bold text when active.
///
/// Rendered as a liquid glass capsule with a black label, matching the iOS 26
/// toolbar button style.
///
/// ## Usage
///
/// Typically placed in a [GlassAppBar] or navigation bar:
///
/// ```dart
/// GlassAppBar.pinned(
///   title: const Text('Contacts'),
///   actions: const [
///     GlassEditButton(),
///   ],
/// )
/// ```
class GlassEditButton extends StatelessWidget {
  /// Creates a standard [GlassEditButton] bound to the nearest [GlassEditScope].
  const GlassEditButton({
    super.key,
    this.editLabel = 'Edit',
    this.doneLabel = 'Done',
    this.color,
    this.onPressed,
    this.enableHaptics = true,
  })  : _isExplicit = false,
        _explicitIsEditing = false;

  /// Creates a standalone [GlassEditButton] with an explicit [isEditing] state.
  const GlassEditButton.explicit({
    super.key,
    required bool isEditing,
    required this.onPressed,
    this.editLabel = 'Edit',
    this.doneLabel = 'Done',
    this.color,
    this.enableHaptics = true,
  })  : _isExplicit = true,
        _explicitIsEditing = isEditing;

  /// Label shown when inactive (defaults to 'Edit').
  final String editLabel;

  /// Label shown when active (defaults to 'Done').
  final String doneLabel;

  /// Tint color for the button text (defaults to [CupertinoColors.label],
  /// matching iOS 26 glass toolbar buttons).
  final Color? color;

  /// Optional override callback for when the button is tapped.
  /// If null in standard mode, automatically calls [GlassEditController.toggle].
  final VoidCallback? onPressed;

  /// Whether to trigger a selection haptic feedback tick on tap.
  final bool enableHaptics;

  final bool _isExplicit;
  final bool _explicitIsEditing;

  @override
  Widget build(BuildContext context) {
    final controller = _isExplicit ? null : GlassEditScope.maybeOf(context);
    final isEditing =
        _isExplicit ? _explicitIsEditing : (controller?.isEditing ?? false);

    final effectiveColor = color ?? CupertinoColors.label.resolveFrom(context);

    return GlassButton.custom(
      label: isEditing ? doneLabel : editLabel,
      height: 44,
      useOwnLayer: true,
      shape: const LiquidRoundedSuperellipse(borderRadius: 22),
      stretch: 0.15,
      onTap: () {
        if (enableHaptics) {
          HapticFeedback.selectionClick();
        }
        if (onPressed != null) {
          onPressed!();
        } else {
          controller?.toggle();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            isEditing ? doneLabel : editLabel,
            key: ValueKey<bool>(isEditing),
            style: TextStyle(
              fontSize: 17,
              fontWeight: isEditing ? FontWeight.w600 : FontWeight.w400,
              color: effectiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
