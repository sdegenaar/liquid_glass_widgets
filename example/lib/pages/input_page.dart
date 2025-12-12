import 'dart:math' as math;

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      fake: true, // Use backdrop filter for scrollable content
      settings: const LiquidGlassSettings(
          blur: 6,
          thickness: 30,
          ambientStrength: 0.5,
          lightAngle: 0.25 * math.pi,
          glassColor: Color.fromRGBO(255, 255, 255, 0.10),
          lightIntensity: .5),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Input',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Glass text input widgets',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // GlassTextField Section
                    const _SectionTitle(title: 'GlassTextField'),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Text Input',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            controller: _usernameController,
                            placeholder: 'Username',
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            controller: _emailController,
                            placeholder: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            controller: _passwordController,
                            placeholder: 'Password',
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'With Icons',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            controller: _searchController,
                            placeholder: 'Search...',
                            prefixIcon: const Icon(CupertinoIcons.search,
                                size: 20, color: Colors.white70),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? const Icon(CupertinoIcons.xmark_circle_fill,
                                    size: 20, color: Colors.white70)
                                : null,
                            onSuffixTap: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Multiline Input',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            controller: _messageController,
                            placeholder: 'Enter your message...',
                            maxLines: 5,
                            minLines: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Different Shapes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            placeholder: 'Rounded Rectangle',
                            shape: const LiquidRoundedRectangle(
                              borderRadius: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            placeholder: 'Rounded Superellipse (default)',
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 10,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            placeholder: 'Highly Rounded',
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'States',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            placeholder: 'Enabled field',
                            enabled: true,
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            placeholder: 'Disabled field',
                            enabled: false,
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            placeholder: 'Read-only field',
                            readOnly: true,
                            controller: TextEditingController(
                              text: 'This text cannot be edited',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // GlassSearchBar Section
                    const _SectionTitle(title: 'GlassSearchBar'),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Search',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassSearchBar(
                            placeholder: 'Search',
                            onChanged: (value) {
                              // Handle search
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'With Cancel Button',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassSearchBar(
                            placeholder: 'Search messages',
                            showsCancelButton: true,
                            onCancel: () {
                              // Handle cancel
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Styling',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassSearchBar(
                            placeholder: 'Search products...',
                            searchIconColor: Colors.blue,
                            clearIconColor: Colors.blue,
                            cancelButtonColor: Colors.blue,
                            showsCancelButton: true,
                            height: 48,
                          ),
                          const SizedBox(height: 12),
                          GlassSearchBar(
                            placeholder: 'Search music',
                            searchIconColor: Colors.pink,
                            clearIconColor: Colors.pink,
                            cancelButtonColor: Colors.pink,
                            showsCancelButton: true,
                            height: 40,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Example',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassSearchBar(
                            placeholder: 'Search contacts',
                            showsCancelButton: true,
                            autofocus: false,
                            onChanged: (value) {
                              // Filter contacts
                            },
                            onSubmitted: (value) {
                              // Perform search
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Try typing to see the clear button appear, or focus to see the cancel button slide in.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form Example
                    const _SectionTitle(title: 'Example Form'),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const GlassTextField(
                            placeholder: 'Full Name',
                            prefixIcon: Icon(CupertinoIcons.person,
                                size: 20, color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          const GlassTextField(
                            placeholder: 'Email Address',
                            prefixIcon: Icon(CupertinoIcons.mail,
                                size: 20, color: Colors.white70),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          const GlassTextField(
                            placeholder: 'Phone Number',
                            prefixIcon: Icon(CupertinoIcons.phone,
                                size: 20, color: Colors.white70),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          const GlassTextField(
                            placeholder: 'Password',
                            prefixIcon: Icon(CupertinoIcons.lock,
                                size: 20, color: Colors.white70),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          const GlassTextField(
                            placeholder: 'Confirm Password',
                            prefixIcon: Icon(CupertinoIcons.lock_fill,
                                size: 20, color: Colors.white70),
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: GlassButton.custom(
                              onTap: () {},
                              height: 56,
                              child: const Center(
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Already have an account? Sign In',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Features Card
                    const GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Glass morphism effect',
                          ),
                          SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Prefix and suffix icon support',
                          ),
                          SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Multiline text input',
                          ),
                          SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Customizable shapes',
                          ),
                          SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Enabled/disabled states',
                          ),
                          SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Read-only mode',
                          ),
                          SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Keyboard type configuration',
                          ),
                          SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Input formatters support',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
