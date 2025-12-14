import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';

/// A vertical navigation sidebar following Apple's iOS 26 liquid glass design guidelines.
///
/// [GlassSideBar] provides a floating, translucent navigation drawer or split-view
/// sidebar. It sits above or alongside content, providing a sense of depth and hierarchy.
///
/// ## Key Features
///
/// - **Liquid Glass Material**: Translucent, blurring background that floats over content.
/// - **Structure**: Optional header and footer with a scrollable list of children in between.
/// - **iOS 26 Compliance**: Matches the visual style of system sidebars (iPadOS/macOS).
///
/// ## Usage
///
/// ```dart
/// Row(
///   children: [
///     GlassSideBar(
///       width: 250,
///       header: Padding(
///         padding: const EdgeInsets.all(16.0),
///         child: Text('My App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
///       ),
///       children: [
///         GlassSideBarItem(
///           icon: Icons.home,
///           label: 'Home',
///           isSelected: _selectedIndex == 0,
///           onTap: () => _onItemTapped(0),
///         ),
///         GlassSideBarItem(
///           icon: Icons.settings,
///           label: 'Settings',
///           isSelected: _selectedIndex == 1,
///           onTap: () => _onItemTapped(1),
///         ),
///       ],
///       footer: GlassButton.icon(
///         icon: Icons.logout,
///         onTap: _logout,
///         label: 'Logout',
///       ),
///     ),
///     Expanded(child: _buildContent()),
///   ],
/// )
/// ```
class GlassSideBar extends StatelessWidget {
  /// Creates a glass sidebar.
  const GlassSideBar({
    required this.children,
    super.key,
    this.width = 280.0,
    this.header,
    this.footer,
    this.glassSettings,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.quality = GlassQuality.premium,
    this.backgroundColor,
    this.border,
  });

  /// The navigation items to display in the sidebar.
  ///
  /// Typically [GlassSideBarItem]s.
  final List<Widget> children;

  /// Width of the sidebar.
  ///
  /// Defaults to 280.0.
  final double width;

  /// Optional header widget (e.g., app logo, title).
  ///
  /// Placed at the top of the sidebar, above the scrollable children.
  final Widget? header;

  /// Optional footer widget (e.g., user profile, settings button).
  ///
  /// Placed at the bottom of the sidebar, pinned to the bottom.
  final Widget? footer;

  /// Glass effect settings.
  ///
  /// If null, uses optimized defaults for sidebars (typically lighter/cleaner).
  final LiquidGlassSettings? glassSettings;

  /// Padding around the content.
  ///
  /// Defaults to symmetric(horizontal: 16, vertical: 16).
  final EdgeInsetsGeometry padding;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.premium].
  final GlassQuality quality;

  /// Optional background color override.
  ///
  /// If provided, this color is mixed with the glass effect.
  /// If null, a default iOS-style translucent tint is used.
  final Color? backgroundColor;

  /// Optional border override.
  ///
  /// Defaults to a subtle right-side border.
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    // Standard sidebar glass settings (often slightly more opaque/different blur than toolbars)
    final effectiveSettings = glassSettings ??
        const LiquidGlassSettings(
          thickness: 30,
          blur: 25,
          chromaticAberration: 0.15,
          lightIntensity: 0.3,
          refractiveIndex: 1.45,
          saturation: 1.1,
          glassColor: Colors.white10,
        );

    final effectiveBackgroundColor =
        backgroundColor ?? Colors.grey.withAlpha(15);

    return SizedBox(
      width: width,
      child: LiquidGlassLayer(
        settings: effectiveSettings,
        fake: quality.usesBackdropFilter,
        child: Container(
          decoration: BoxDecoration(
            border: border ??
                const Border(
                  right: BorderSide(
                    color: Colors.white12,
                    width: 0.5,
                  ),
                ),
          ),
          child: Stack(
            children: [
              // Glass Background Layer
              Positioned.fill(
                child: LiquidGlass.grouped(
                  shape: const LiquidRoundedRectangle(borderRadius: 0),
                  child: Container(color: effectiveBackgroundColor),
                ),
              ),

              // Content Layer
              SafeArea(
                child: Column(
                  children: [
                    if (header != null) ...[
                      Padding(
                        padding: padding,
                        child: header,
                      ),
                      // Optional separator logic could go here
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        padding: padding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
                      ),
                    ),
                    if (footer != null)
                      Padding(
                        padding: padding,
                        child: footer,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list item designed for [GlassSideBar].
///
/// Features a rounded design that highlights when selected, with a subtle glass effect.
class GlassSideBarItem extends StatelessWidget {
  /// Creates a sidebar item.
  const GlassSideBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.isSelected = false,
    this.selectedColor,
    this.unselectedColor,
    this.height = 48.0,
    this.borderRadius = 12.0,
  });

  /// Icon to display.
  final IconData icon;

  /// Text label to display.
  final String label;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Whether the item is currently selected.
  final bool isSelected;

  /// Color for the icon and text when selected.
  ///
  /// Defaults to theme accent color or white.
  final Color? selectedColor;

  /// Color for the icon and text when not selected.
  ///
  /// Defaults to white70.
  final Color? unselectedColor;

  /// Height of the item.
  ///
  /// Defaults to 48.0.
  final double height;

  /// Border radius of the selection background.
  ///
  /// Defaults to 12.0.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSelectedColor =
        selectedColor ?? theme.colorScheme.primary.withValues(alpha: 0.8);
    final effectiveUnselectedColor = unselectedColor ?? Colors.white70;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isSelected
                ? (selectedColor?.withValues(alpha: 0.15) ??
                    Colors.white.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? effectiveSelectedColor
                    : effectiveUnselectedColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? effectiveSelectedColor
                        : effectiveUnselectedColor,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
