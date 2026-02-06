import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../widgets/animated_background.dart';
import '../theme/showcase_glass_theme.dart';

/// Travel Concierge Chat Page
///
/// A luxury travel assistant interface demonstrating:
/// - Glass prompt suggestion chips
/// - Glass text input area
/// - Glass buttons and interactive elements
/// - Practical use case for glass morphism
class ConciergePage extends StatefulWidget {
  const ConciergePage({super.key});

  @override
  State<ConciergePage> createState() => _ConciergePageState();
}

class _ConciergePageState extends State<ConciergePage> {
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  bool _voiceInputEnabled = false;
  bool _notificationsEnabled = true;

  /// Travel-themed suggested prompts
  final List<String> _promptSuggestions = [
    'Best time to visit Santorini?',
    'What should I pack for Bali?',
    'Recommend restaurants in NYC',
    'Plan my 3-day itinerary',
    'Book a spa treatment',
    'Arrange airport transfer',
  ];

  @override
  void dispose() {
    _chatController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  /// Handles prompt suggestion tap
  void _onPromptTap(String prompt) {
    setState(() {
      _chatController.text = prompt;
    });
    _chatFocusNode.requestFocus();
  }

  /// Handles send message
  void _onSendMessage() {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    // In a real app, this would send to an AI/concierge service
    debugPrint('Concierge query: $message');

    _chatController.clear();
  }

  /// Handles voice input
  void _onVoiceInput() {
    // In a real app, this would activate speech-to-text
    debugPrint('Voice input activated');
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildChatArea(),
              ),
              _buildPromptSuggestions(),
              const SizedBox(height: 16),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: AdaptiveLiquidGlassLayer(
        quality: ShowcaseGlassTheme.premiumQuality,
        settings: ShowcaseGlassTheme.headerButtons,
        child: Row(
          children: [
            GlassButton(
              icon: Icons.arrow_back_ios_new,
              iconSize: 20,
              width: 44,
              height: 44,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            GlassButton(
              icon: Icons.settings_outlined,
              iconSize: 20,
              width: 44,
              height: 44,
              onTap: () => _showSettingsSheet(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Concierge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Available 24/7',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            GlassButton(
              icon: Icons.more_horiz,
              iconSize: 22,
              width: 44,
              height: 44,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 64,
                color: const Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How can I help plan your trip?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me about destinations, activities, dining,\nor anything else you need',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Questions',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _promptSuggestions.map((prompt) {
              return _buildPromptChip(prompt);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () => _onPromptTap(prompt),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const LiquidRoundedSuperellipse(borderRadius: 16),
        settings: ShowcaseGlassTheme.promptChips,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 14,
              color: Color(0xFF4A90E2),
            ),
            const SizedBox(width: 6),
            Text(
              prompt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const LiquidRoundedSuperellipse(borderRadius: 24),
        settings: ShowcaseGlassTheme.chatInput,
        child: Row(
          children: [
            // Voice input button
            GestureDetector(
              onTap: _onVoiceInput,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text input field
            Expanded(
              child: TextField(
                controller: _chatController,
                focusNode: _chatFocusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: _onSendMessage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4A90E2),
                      Color(0xFF357ABD),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => GlassSheet(
          settings: ShowcaseGlassTheme.dialog,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Concierge Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                AdaptiveLiquidGlassLayer(
                  settings: ShowcaseGlassTheme.sheetSwitches,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Voice Input',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enable voice-to-text',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          GlassSwitch(
                            value: _voiceInputEnabled,
                            onChanged: (value) {
                              setSheetState(() {
                                _voiceInputEnabled = value;
                              });
                              setState(() {
                                _voiceInputEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get travel updates',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          GlassSwitch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setSheetState(() {
                                _notificationsEnabled = value;
                              });
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassButton(
                  icon: Icons.check,
                  label: 'Done',
                  height: 50,
                  width: 50,
                  settings: ShowcaseGlassTheme.doneButton,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
