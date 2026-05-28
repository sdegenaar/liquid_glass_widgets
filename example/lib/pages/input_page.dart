import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';

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
    return GlassPage(
      background: buildShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.light,
      child: Scaffold(
        appBar: GlassAppBar(
          title: const Text(
            'Input',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: GlassButton(
            icon: const Icon(CupertinoIcons.back),
            onTap: () => Navigator.of(context).pop(),
            width: 40,
            height: 40,
            iconSize: 20,
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── GlassTextField ────────────────────────────────
                    const _SectionTitle(title: 'GlassTextField'),
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
                    const SizedBox(height: 24),

                    // With icons
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
                        setState(() => _searchController.clear());
                      },
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Multiline
                    GlassTextField(
                      controller: _messageController,
                      placeholder: 'Enter your message...',
                      maxLines: 5,
                      minLines: 3,
                    ),

                    const SizedBox(height: 40),

                    // ── GlassSearchBar ────────────────────────────────
                    const _SectionTitle(title: 'GlassSearchBar'),
                    const SizedBox(height: 16),
                    GlassSearchBar(
                      placeholder: 'Search',
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 12),
                    GlassSearchBar(
                      placeholder: 'Search messages',
                      showsCancelButton: true,
                      onCancel: () {},
                    ),

                    const SizedBox(height: 40),

                    // ── Example Form ─────────────────────────────────
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
                            placeholder: 'Password',
                            prefixIcon: Icon(CupertinoIcons.lock,
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
                                color:
                                    Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Helper Widgets
// =============================================================================

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
