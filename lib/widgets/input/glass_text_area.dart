import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import 'glass_text_field.dart';

/// A multi-line glass text area.
///
/// [GlassTextArea] optimizes [GlassTextField] for multi-line input.
/// It exposes all standard text field and glass configuration options.
class GlassTextArea extends StatelessWidget {
  /// Creates a glass text area.
  const GlassTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.minLines = 3,
    this.maxLines = 5,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction = TextInputAction.newline,
    this.inputFormatters,
    this.textStyle,
    this.placeholderStyle,
    this.padding = const EdgeInsets.all(16),
    // Glass properties
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 10),
  });

  /// Controls the text.
  final TextEditingController? controller;

  /// Controls focus.
  final FocusNode? focusNode;

  /// Placeholder text.
  final String? placeholder;

  /// Minimum lines.
  final int minLines;

  /// Maximum lines.
  final int maxLines;

  /// Text change callback.
  final ValueChanged<String>? onChanged;

  /// Submit callback.
  final ValueChanged<String>? onSubmitted;

  /// Enabled state.
  final bool enabled;

  /// Read-only state.
  final bool readOnly;

  /// Autofocus state.
  final bool autofocus;

  /// Action button.
  final TextInputAction? textInputAction;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Text style.
  final TextStyle? textStyle;

  /// Placeholder style.
  final TextStyle? placeholderStyle;

  /// Padding. Defaults to EdgeInsets.all(16).
  final EdgeInsetsGeometry padding;

  /// Glass settings.
  final LiquidGlassSettings? settings;

  /// Own layer toggle.
  final bool useOwnLayer;

  /// Quality setting.
  final GlassQuality quality;

  /// Shape setting.
  final LiquidShape shape;

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      textStyle: textStyle,
      placeholderStyle: placeholderStyle,
      padding: padding,
      settings: settings,
      useOwnLayer: useOwnLayer,
      quality: quality,
      shape: shape,
    );
  }
}
