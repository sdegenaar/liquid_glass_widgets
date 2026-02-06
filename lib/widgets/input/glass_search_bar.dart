import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import 'glass_text_field.dart';

/// A glass morphism search bar following Apple's iOS 26 design patterns.
///
/// [GlassSearchBar] provides a sophisticated search field with pill shape,
/// animated clear button, and optional cancel button that slides in from the
/// right. It matches iOS's UISearchBar appearance and behavior with glass
/// morphism effects.
///
/// ## Key Features
///
/// - **Pill-Shaped Glass**: Rounded search field with glass effect
/// - **Animated Clear Button**: Appears/fades when text is entered
/// - **Cancel Button**: Optional slide-in cancel button (iOS pattern)
/// - **Search Icon**: Leading search icon with customizable color
/// - **Auto-focus Support**: Can auto-focus on appearance
/// - **Dual Mode**: Grouped or standalone rendering
///
/// ## Usage
///
/// ### Basic Usage
/// ```dart
/// String query = '';
///
/// GlassSearchBar(
///   placeholder: 'Search',
///   onChanged: (value) {
///     setState(() => query = value);
///   },
/// )
/// ```
///
/// ### With Cancel Button
/// ```dart
/// GlassSearchBar(
///   placeholder: 'Search messages',
///   showsCancelButton: true,
///   onCancel: () {
///     // Clear search and dismiss keyboard
///   },
/// )
/// ```
///
/// ### Within LiquidGlassLayer (Grouped Mode)
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 8,
///     refractiveIndex: 1.59,
///   ),
///   child: Column(
///     children: [
///       GlassSearchBar(
///         placeholder: 'Search',
///         onChanged: (value) => _performSearch(value),
///       ),
///       // Search results...
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassSearchBar(
///   placeholder: 'Search',
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 8,
///   ),
///   onChanged: (value) => _performSearch(value),
/// )
/// ```
///
/// ### Custom Styling
/// ```dart
/// GlassSearchBar(
///   placeholder: 'Search products...',
///   searchIconColor: Colors.blue,
///   clearIconColor: Colors.blue,
///   cancelButtonColor: Colors.blue,
///   textStyle: TextStyle(fontSize: 18, color: Colors.white),
///   height: 48,
/// )
/// ```
class GlassSearchBar extends StatefulWidget {
  /// Creates a glass search bar.
  const GlassSearchBar({
    super.key,
    this.controller,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.showsCancelButton = false,
    this.autofocus = false,
    this.enabled = true,
    this.searchIconColor,
    this.clearIconColor,
    this.cancelButtonColor,
    this.textStyle,
    this.placeholderStyle,
    this.height = 44.0,
    this.cancelButtonText = 'Cancel',
    this.settings,
    this.useOwnLayer = false,
    this.quality,
  });

  // ===========================================================================
  // Search Bar Properties
  // ===========================================================================

  /// Controls the text being edited.
  ///
  /// If null, a controller will be created internally.
  final TextEditingController? controller;

  /// Placeholder text shown when the field is empty.
  ///
  /// Defaults to 'Search'.
  final String placeholder;

  /// Called when the search text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search.
  final ValueChanged<String>? onSubmitted;

  /// Called when the cancel button is tapped.
  ///
  /// If [showsCancelButton] is true and this callback is provided,
  /// the cancel button will be shown.
  final VoidCallback? onCancel;

  /// Whether to show the cancel button.
  ///
  /// When true, the cancel button slides in from the right when the search
  /// bar is focused, matching iOS behavior.
  ///
  /// Defaults to false.
  final bool showsCancelButton;

  /// Whether the search field should auto-focus.
  ///
  /// Defaults to false.
  final bool autofocus;

  /// Whether the search field is enabled.
  ///
  /// Defaults to true.
  final bool enabled;

  // ===========================================================================
  // Style Properties
  // ===========================================================================

  /// Color of the search icon.
  ///
  /// Defaults to white with 60% opacity.
  final Color? searchIconColor;

  /// Color of the clear button icon.
  ///
  /// Defaults to white with 60% opacity.
  final Color? clearIconColor;

  /// Color of the cancel button text.
  ///
  /// Defaults to white with 90% opacity.
  final Color? cancelButtonColor;

  /// The style of the search text.
  final TextStyle? textStyle;

  /// The style of the placeholder text.
  final TextStyle? placeholderStyle;

  /// Height of the search bar.
  ///
  /// Defaults to 44 (iOS standard).
  final double height;

  /// Text for the cancel button.
  ///
  /// Defaults to 'Cancel'.
  final String cancelButtonText;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings (only used when [useOwnLayer] is true).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass.
  ///
  /// Defaults to false (grouped mode).
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses the lightweight fragment
  /// shader. This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for full-pipeline shader with texture capture
  /// and chromatic aberration (Impeller only) in static layouts.
  final GlassQuality? quality;

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar>
    with SingleTickerProviderStateMixin {
  // Cache default colors to avoid allocations
  static const _defaultSearchIconColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)
  static const _defaultClearIconColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)
  static const _defaultCancelButtonColor =
      Color(0xE6FFFFFF); // white.withValues(alpha: 0.9)

  late TextEditingController _controller;
  late AnimationController _clearButtonController;
  late FocusNode _focusNode;
  bool _showCancelButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    // Animation for clear button
    _clearButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Listen to text changes
    _controller.addListener(_onTextChanged);

    // Listen to focus changes for cancel button
    _focusNode.addListener(_onFocusChanged);

    // Initialize clear button animation state based on initial text
    if (_controller.text.isNotEmpty) {
      _clearButtonController.value = 1.0;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _clearButtonController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Animate clear button based on text presence
    if (_controller.text.isNotEmpty) {
      if (_clearButtonController.status != AnimationStatus.completed &&
          _clearButtonController.status != AnimationStatus.forward) {
        unawaited(_clearButtonController.forward());
      }
    } else {
      if (_clearButtonController.status != AnimationStatus.dismissed &&
          _clearButtonController.status != AnimationStatus.reverse) {
        unawaited(_clearButtonController.reverse());
      }
    }
  }

  void _onFocusChanged() {
    if (widget.showsCancelButton) {
      setState(() {
        _showCancelButton = _focusNode.hasFocus;
      });
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _handleCancel() {
    _controller.clear();
    _focusNode.unfocus();
    widget.onCancel?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final searchIconColor = widget.searchIconColor ?? _defaultSearchIconColor;
    final clearIconColor = widget.clearIconColor ?? _defaultClearIconColor;
    final cancelButtonColor =
        widget.cancelButtonColor ?? _defaultCancelButtonColor;

    return Row(
      children: [
        // Search field
        Expanded(
          child: SizedBox(
            height: widget.height,
            child: GlassTextField(
              controller: _controller,
              focusNode: _focusNode,
              placeholder: widget.placeholder,
              prefixIcon: Icon(
                CupertinoIcons.search,
                size: 20,
                color: searchIconColor,
              ),
              suffixIcon: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _clearButtonController,
                  builder: (context, child) {
                    final animation = CurvedAnimation(
                      parent: _clearButtonController,
                      curve: Curves.easeInOut,
                    );

                    return Opacity(
                      opacity: animation.value,
                      child: Transform.scale(
                        scale: animation.value,
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 18,
                          color: clearIconColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              onSuffixTap: _handleClear,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              textStyle: widget.textStyle,
              placeholderStyle: widget.placeholderStyle,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              iconSpacing: 8,
              shape: LiquidRoundedSuperellipse(
                borderRadius: widget.height / 2, // Pill shape
              ),
              settings: widget.settings,
              useOwnLayer: widget.useOwnLayer,
              quality: widget.quality,
            ),
          ),
        ),

        // Cancel button
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showCancelButton
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GestureDetector(
                    onTap: _handleCancel,
                    child: Text(
                      widget.cancelButtonText,
                      style: TextStyle(
                        color: cancelButtonColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
