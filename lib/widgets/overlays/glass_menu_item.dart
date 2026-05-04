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
    this.subtitle,
    this.isPressed,
    this.isSelected = false,
    this.enabled = true,
  });

  /// The primary text of the item.
  final String title;

  /// The icon widget displayed before the title.
  final Widget? icon;

  /// Optional subtitle text displayed below the title.
  final String? subtitle;

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

  /// External override for the pressed state.
  final bool? isPressed;

  /// Whether the item is currently selected (e.g. by a sliding pill).
  final bool isSelected;

  /// Whether the item should handle its own interactions.
  final bool enabled;

  @override
  State<GlassMenuItem> createState() => _GlassMenuItemState();
}

/// A separator line for use within a [GlassMenu].
class GlassMenuDivider extends StatelessWidget {
  /// The height of the divider area (line + spacing).
  final double height;

  /// Custom color for the divider line.
  final Color? color;

  /// Horizontal padding for the divider line.
  final double indent;

  /// Creates a glass menu divider.
  const GlassMenuDivider({
    super.key,
    this.height = 12.0,
    this.color,
    this.indent = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: 0.5,
          margin: EdgeInsets.symmetric(horizontal: indent),
          color: color ?? const Color(0x26FFFFFF), // 15% white line default
        ),
      ),
    );
  }
}

class _GlassMenuItemState extends State<GlassMenuItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Performance: Cache static colors to avoid recalculation on every build
    final Color textColor = widget.isDestructive
        ? const Color(0xFFEF5350) // Colors.red.shade400 cached
        : const Color(0xE6FFFFFF); // Colors.white.withValues(alpha: 0.9) cached

    final Color iconColor = widget.isDestructive
        ? const Color(0xFFEF5350)
        : const Color(0xB3FFFFFF); // Colors.white.withValues(alpha: 0.7) cached

    // Dynamic background for hover/press states
    // We use a subtle white overlay to "brighten" the glass
    final bool effectivePressed = widget.isPressed ?? _isPressed;
    final bool effectiveSelected = widget.isSelected;

    final Color backgroundColor = effectiveSelected
        ? Colors.transparent // Parent renders the sliding pill
        : effectivePressed
            ? const Color(0x26FFFFFF) // Standalone press
            : _isHovered
                ? const Color(0x1AFFFFFF)
                : Colors.transparent;

    // Scale effect on press (subtle squash like iOS buttons)
    final double scale = effectivePressed ? 0.98 : 1.0;

    // Performance: RepaintBoundary isolates this item from siblings
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
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
                borderRadius: BorderRadius.circular(24), // Match sliding pill
              ),
              child: Row(
                children: [
                  // Icon
                  if (widget.icon != null) ...[
                    IconTheme(
                      data: IconThemeData(color: iconColor, size: 20),
                      child: widget.icon!,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Text Content (Title & Subtitle)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Trailing
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
