import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class InputsPage extends StatelessWidget {
  const InputsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLiquidGlassLayer(
      // Widgets inside use LightweightLiquidGlass (standard) or full shader (premium)
      settings: RecommendedGlassSettings.input,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(
          title: Text(
            'Inputs',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forms & Inputs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New iOS 26 style input primitives.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Form Example
              const _SectionHeader('Input Form'),
              GlassCard(
                child: Column(
                  children: [
                    const GlassFormField(
                      label: 'Account Email',
                      child: GlassTextField(
                        placeholder: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(CupertinoIcons.mail,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const GlassFormField(
                      label: 'Password',
                      helperText: 'Must be at least 8 characters',
                      child: GlassPasswordField(),
                    ),
                    const SizedBox(height: 16),
                    GlassFormField(
                      label: 'Role',
                      child: GlassPicker(
                        value: 'Administrator',
                        icon: CupertinoIcons.briefcase,
                        useOwnLayer: true, // Demo specific layer usage
                        quality: GlassQuality.premium,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Text Area Example
              const _SectionHeader('Multi-line Text'),
              GlassCard(
                child: GlassFormField(
                  label: 'Bio / Description',
                  child: GlassTextArea(
                    placeholder: 'Write a short description...',
                    minLines: 4,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Search Bar Example
              const _SectionHeader('Search'),
              const GlassSearchBar(
                placeholder: 'Search documentation...',
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
