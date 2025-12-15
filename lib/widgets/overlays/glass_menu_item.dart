import 'package:flutter/material.dart';

/// A menu item for use within a [GlassMenu].
///
/// [GlassMenuItem] provides a standard layout for menu options, including
/// support for icons, labels, and "destructive" styling. It handles its own
/// hover and tap interactions with liquid glass effects.
class GlassMenuItem extends StatefulWidget {
  /// Creates a glass menu item.
  const GlassMenuItem({
    required this.title,
    required this.onTap,
    super.key,
    this.icon,
    this.isDestructive = false,
    this.trailing,
    this.height = 44.0,
  });

  /// The primary text of the item.
  final String title;

  /// The icon displayed before the title.
  final IconData? icon;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  /// Whether this is a destructive action (e.g., Delete).
  ///
  /// Renders with red text and distinct hover effect.
  final bool isDestructive;

  /// A widget to display after the title (e.g., shortcut key).
  final Widget? trailing;

  /// Height of the item.
  ///
  /// Defaults to 44.0 (standard iOS touch target).
  final double height;

  @override
  State<GlassMenuItem> createState() => _GlassMenuItemState();
}

class _GlassMenuItemState extends State<GlassMenuItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Determine colors based on state and destructive flag
    final Color textColor = widget.isDestructive
        ? Colors.red.shade400
        : Colors.white.withValues(alpha: 0.9);

    final Color iconColor = widget.isDestructive
        ? Colors.red.shade400
        : Colors.white.withValues(alpha: 0.7);

    // Dynamic background for hover/press states
    // We use a subtle white overlay to "brighten" the glass
    final Color backgroundColor = _isPressed
        ? Colors.white.withValues(alpha: 0.15)
        : _isHovered
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent;

    // Scale effect on press (subtle squash like iOS buttons)
    final double scale = _isPressed ? 0.98 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic, // Closer to spring feel than easeOut
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic, // iOS-style spring approximation
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10), // Inner radius
            ),
            child: Row(
              children: [
                // Icon
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 12),
                ],

                // Title
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                // Trailing
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
