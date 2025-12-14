import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import 'glass_text_field.dart';

/// A secure glass text field for password entry.
///
/// [GlassPasswordField] wraps [GlassTextField] with a built-in visibility toggle.
/// It exposes all standard text field and glass configuration options.
class GlassPasswordField extends StatefulWidget {
  /// Creates a glass password field.
  const GlassPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder = 'Password',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction,
    this.inputFormatters,
    this.textStyle,
    this.placeholderStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.width,
    // Glass properties
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 10),
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Controls the focus state.
  final FocusNode? focusNode;

  /// Placeholder text.
  final String placeholder;

  /// Called when text changes.
  final ValueChanged<String>? onChanged;

  /// Called when submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether to autofocus.
  final bool autofocus;

  /// Action button on keyboard.
  final TextInputAction? textInputAction;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Style for the text.
  final TextStyle? textStyle;

  /// Style for the placeholder.
  final TextStyle? placeholderStyle;

  /// Padding inside the field.
  final EdgeInsetsGeometry padding;

  /// Optional fixed width.
  final double? width;

  /// Glass settings.
  final LiquidGlassSettings? settings;

  /// Whether to use its own layer (true) or grouped (false).
  final bool useOwnLayer;

  /// Rendering quality.
  final GlassQuality quality;

  /// Shape of the field.
  final LiquidShape shape;

  @override
  State<GlassPasswordField> createState() => _GlassPasswordFieldState();
}

class _GlassPasswordFieldState extends State<GlassPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      placeholder: widget.placeholder,
      obscureText: _obscureText,
      maxLines: 1,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      inputFormatters: widget.inputFormatters,
      textStyle: widget.textStyle,
      placeholderStyle: widget.placeholderStyle,
      padding: widget.padding,
      settings: widget.settings,
      useOwnLayer: widget.useOwnLayer,
      quality: widget.quality,
      shape: widget.shape,
      prefixIcon: const Icon(
        CupertinoIcons.lock_fill,
        size: 20,
        color: Colors.white70,
      ),
      suffixIcon: Icon(
        _obscureText ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
        size: 20,
        color: Colors.white70,
      ),
      onSuffixTap: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
