import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../shared/adaptive_glass.dart';
import '../shared/inherited_liquid_glass.dart';

/// A glass text field widget following Apple's input field design.
///
/// [GlassTextField] provides a text input field with glass morphism effect,
/// matching iOS design patterns with customizable styling.
///
/// ## Usage Modes
///
/// ### Grouped Mode (default)
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: Column(
///     children: [
///       GlassTextField(
///         placeholder: 'Email',
///         keyboardType: TextInputType.emailAddress,
///       ),
///       GlassTextField(
///         placeholder: 'Password',
///         obscureText: true,
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassTextField(
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(...),
///   placeholder: 'Search...',
///   prefixIcon: Icon(Icons.search, size: 20, color: Colors.white70),
/// )
/// ```
///
/// ## Customization Examples
///
/// ### With prefix and suffix icons:
/// ```dart
/// GlassTextField(
///   placeholder: 'Search',
///   prefixIcon: Icon(Icons.search, size: 20, color: Colors.white70),
///   suffixIcon: Icon(Icons.clear, size: 20, color: Colors.white70),
///   onSuffixTap: () => controller.clear(),
/// )
/// ```
///
/// ### Multiline text area:
/// ```dart
/// GlassTextField(
///   placeholder: 'Enter your message...',
///   maxLines: 5,
///   minLines: 3,
/// )
/// ```
class GlassTextField extends StatefulWidget {
  /// Creates a glass text field.
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textStyle,
    this.placeholderStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.iconSpacing = 12.0,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 10),
    this.settings,
    this.useOwnLayer = false,
    this.quality,
  });

  // ===========================================================================
  // Text Field Properties
  // ===========================================================================

  /// Controls the text being edited.
  ///
  /// If null, a controller will be created internally.
  final TextEditingController? controller;

  /// Controls the focus state of the text field.
  ///
  /// If null, a focus node will be created internally.
  final FocusNode? focusNode;

  /// Placeholder text shown when the field is empty.
  final String? placeholder;

  /// Widget displayed at the start of the field.
  final Widget? prefixIcon;

  /// Widget displayed at the end of the field.
  final Widget? suffixIcon;

  /// Callback when suffix icon is tapped.
  final VoidCallback? onSuffixTap;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// The type of keyboard to display.
  final TextInputType? keyboardType;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Maximum number of lines for the text field.
  ///
  /// Defaults to 1 for single-line input.
  final int maxLines;

  /// Minimum number of lines for the text field.
  final int? minLines;

  /// Maximum number of characters allowed.
  final int? maxLength;

  /// Whether the text field is enabled.
  final bool enabled;

  /// Whether the text field is read-only.
  final bool readOnly;

  /// Whether the text field should auto-focus.
  final bool autofocus;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the text.
  final ValueChanged<String>? onSubmitted;

  /// Input formatters for the text field.
  final List<TextInputFormatter>? inputFormatters;

  // ===========================================================================
  // Style Properties
  // ===========================================================================

  /// The style of the text being edited.
  final TextStyle? textStyle;

  /// The style of the placeholder text.
  final TextStyle? placeholderStyle;

  /// Padding inside the text field.
  ///
  /// Defaults to 16px horizontal, 12px vertical.
  final EdgeInsetsGeometry padding;

  /// Spacing between the icons and the text field.
  ///
  /// Defaults to 12.
  final double iconSpacing;

  /// Shape of the text field.
  ///
  /// Defaults to [LiquidRoundedSuperellipse] with 10px border radius.
  final LiquidShape shape;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings (only used when [useOwnLayer] is true).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses backdrop filter rendering.
  /// This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for shader-based glass in static layouts only.
  final GlassQuality? quality;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    // Only dispose if we created the focus node
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  static const _defaultTextStyle = TextStyle(
    color: Color.fromRGBO(255, 255, 255, 0.9), // Colors.white with 0.9 alpha
    fontSize: 16,
  );

  static const _defaultPlaceholderStyle = TextStyle(
    color: Color.fromRGBO(255, 255, 255, 0.5), // Colors.white with 0.5 alpha
    fontSize: 16,
  );

  @override
  Widget build(BuildContext context) {
    // Use static constants for default styles
    final defaultTextStyle = _defaultTextStyle;
    final defaultPlaceholderStyle = _defaultPlaceholderStyle;

    // Build text field content
    final textFieldContent = Padding(
      padding: widget.padding,
      child: Row(
        children: [
          // Prefix icon
          if (widget.prefixIcon != null) ...[
            widget.prefixIcon!,
            SizedBox(width: widget.iconSpacing),
          ],

          // Text field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              inputFormatters: widget.inputFormatters,
              style: widget.textStyle ?? defaultTextStyle,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: widget.placeholderStyle ?? defaultPlaceholderStyle,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterText: '', // Hide character counter
              ),
            ),
          ),

          // Suffix icon
          if (widget.suffixIcon != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onSuffixTap,
              child: widget.suffixIcon,
            ),
          ],
        ],
      ),
    );

    // Inherit quality from parent layer if not explicitly set
    final inherited =
        context.dependOnInheritedWidgetOfExactType<InheritedLiquidGlass>();
    final effectiveQuality =
        widget.quality ?? inherited?.quality ?? GlassQuality.standard;

    // Apply glass effect
    final glassWidget = AdaptiveGlass(
      shape: widget.shape,
      settings: widget.settings ?? InheritedLiquidGlass.ofOrDefault(context),
      quality: effectiveQuality,
      useOwnLayer: widget.useOwnLayer,
      child: textFieldContent,
    );

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: glassWidget,
    );
  }
}
