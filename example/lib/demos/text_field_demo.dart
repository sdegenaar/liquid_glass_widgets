/// Demo: GlassTextField v0.12.5 — visual verification of all user-reported issues.
///
/// WHAT TO CHECK IN THIS DEMO:
///
///   [A] Fixed 44pt — text centred at any system font size.
///       Turn on Accessibility → Larger Text and verify placeholder stays centred.
///
///   [B] The exact user pattern:
///       height: _lines > 1 ? null : (hasFocus ? 46 : 50)
///       • Unfocused: 50px pill
///       • Focused:   46px pill
///       • Multi-line: free height (null)
///       Tap away, tap back, type more → MUST keep animating (stale state fix).
///
///   [C] iconAlignment: .end in fixed-height mode with large system text.
///       Icons must pin to the bottom of the container even when
///       the system text scaling is large. Previously they would drift
///       downward because the whole Row was Align(center)-wrapped.
///
///   [D] Bottom panel — action bar + text area share one glass card.
///       Composer with attachments + send button.
///
/// To run: flutter run -t lib/demos/text_field_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const TextFieldDemoApp()));
}

class TextFieldDemoApp extends StatelessWidget {
  const TextFieldDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TextFieldDemo(),
    );
  }
}

class TextFieldDemo extends StatefulWidget {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  // ── [A] Fixed-height search field ─────────────────────────────────────
  final _searchController = TextEditingController();

  // ── [B] Exact user pattern: height: _lines > 1 ? null : (hasFocus ? 46 : 50)
  final _patternController = TextEditingController();
  final _patternFocusNode = FocusNode();
  int _patternLines = 1;
  bool _patternHasFocus = false;

  // ── [C] iconAlignment: .end + fixed height + large text ───────────────
  final _iconAlignController = TextEditingController();
  int _iconAlignLines = 1;

  // ── [D] Bottom-panel composer ─────────────────────────────────────────
  final _composerController = TextEditingController();
  int _composerLineCount = 1;
  final List<String> _messages = [
    'Hey! Have you tried the new glass widgets?',
    'Yes! The liquid glass looks amazing on iOS 26 🤩',
    'Try the new GlassTextField — it has height constraints now',
    'And onLineCountChanged! Watch the border radius animate...',
    'v0.12.5: check out the conditional height field above 👆',
  ];

  @override
  void initState() {
    super.initState();
    _patternFocusNode.addListener(() {
      setState(() => _patternHasFocus = _patternFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _patternController.dispose();
    _patternFocusNode.dispose();
    _iconAlignController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _composerController.clear();
      _composerLineCount = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── [B] Exact user pattern ──
    final patternHeight = _patternLines > 1
        ? null
        : (_patternHasFocus ? 46.0 : 50.0);
    final patternRadius = _patternLines <= 1 ? 22.0 : 12.0;

    // ── [C] Icon alignment demo — dynamic radius ──
    final iconAlignRadius = _iconAlignLines <= 1 ? 22.0 : 12.0;
    final iconAlignHeight = _iconAlignLines > 1 ? null : 50.0;

    // ── [D] Composer border-radius ──
    final composerRadius = _composerLineCount <= 1 ? 22.0 : 12.0;

    return GlassPage(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
              Color(0xFF533483),
            ],
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: const Text('TextField v0.12.5 Verification'),
          quality: GlassQuality.premium,
          useOwnLayer: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ════════════════════════════════════════════════════════════
              // [A] Fixed-height — text centred under Large Text
              // ════════════════════════════════════════════════════════════
              _sectionLabel(
                '[A] Fixed height: 44 — text centred at any font size.\n'
                'Enable Accessibility → Larger Text and verify.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: GlassTextField.search(
                  controller: _searchController,
                  placeholder: 'Fixed 44pt — text centred at any font size',
                  prefixIcon: const Icon(
                    CupertinoIcons.search,
                    size: 20,
                    color: Colors.white60,
                  ),
                  useOwnLayer: true,
                  quality: GlassQuality.premium,
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: Colors.white12, indent: 16, endIndent: 16),

              // ════════════════════════════════════════════════════════════
              // [B] Exact user pattern
              // ════════════════════════════════════════════════════════════
              _sectionLabel(
                '[B] Exact user pattern:\n'
                'height: _lines > 1 ? null : (hasFocus ? 46 : 50)\n'
                '• Unfocused: 50px pill\n'
                '• Focused:   46px pill\n'
                '• Multi-line: free height (null)',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: GlassTextField(
                    controller: _patternController,
                    focusNode: _patternFocusNode,
                    placeholder: 'Type here until text wraps…',
                    maxLines: 5,
                    height: patternHeight,
                    onLineCountChanged: (lines) {
                      setState(() => _patternLines = lines);
                    },
                    shape: LiquidRoundedSuperellipse(
                      borderRadius: patternRadius,
                    ),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    interactionBehavior: GlassInteractionBehavior.full,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              // Live debug readout for [B].
              _debugReadout(
                'focus=${_patternHasFocus ? 'Y' : 'N'}  '
                'lines=$_patternLines  '
                'height=${patternHeight?.toInt() ?? 'null (free)'}  '
                'radius=${patternRadius.toInt()}',
                highlight: _patternLines > 1,
              ),

              const SizedBox(height: 8),
              const Divider(color: Colors.white12, indent: 16, endIndent: 16),

              // ════════════════════════════════════════════════════════════
              // [C] iconAlignment: .end under large text
              // ════════════════════════════════════════════════════════════
              _sectionLabel(
                '[C] iconAlignment: .end + fixed height.\n'
                'Icons must pin to BOTTOM of container, not drift\n'
                'downward when system text is large. Type to expand.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: GlassTextField(
                    controller: _iconAlignController,
                    placeholder: 'Icons stay at bottom…',
                    maxLines: 5,
                    height: iconAlignHeight,
                    iconAlignment: CrossAxisAlignment.end,
                    prefixIcon: const Icon(
                      CupertinoIcons.smiley,
                      size: 22,
                      color: Colors.white60,
                    ),
                    suffixIcon: const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      size: 26,
                      color: Colors.white70,
                    ),
                    onLineCountChanged: (lines) {
                      setState(() => _iconAlignLines = lines);
                    },
                    shape: LiquidRoundedSuperellipse(
                      borderRadius: iconAlignRadius,
                    ),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    interactionBehavior: GlassInteractionBehavior.full,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              // Live debug readout for [C].
              _debugReadout(
                'lines=$_iconAlignLines  '
                'height=${iconAlignHeight?.toInt() ?? 'null (free)'}  '
                'iconAlign=end',
                highlight: _iconAlignLines > 1,
              ),

              const SizedBox(height: 8),
              const Divider(color: Colors.white12, indent: 16, endIndent: 16),

              // ════════════════════════════════════════════════════════════
              // [D] Bottom panel composer
              // ════════════════════════════════════════════════════════════
              _sectionLabel(
                '[D] Bottom panel — action bar + text area share\n'
                'one glass card. Chat composer pattern.',
              ),

              // Message list.
              SizedBox(
                height: 160,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msgIndex = _messages.length - 1 - index;
                    final isMe = msgIndex % 2 == 0;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: GlassCard(
                          useOwnLayer: true,
                          quality: GlassQuality.premium,
                          shape: const LiquidRoundedSuperellipse(
                              borderRadius: 16),
                          settings: LiquidGlassSettings(
                            glassColor: isMe
                                ? Colors.blue.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              _messages[msgIndex],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Live debug readout for [D].
              _debugReadout(
                'lines=$_composerLineCount  radius=${composerRadius.toInt()}',
              ),

              // Bottom-panel composer.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: GlassTextField(
                  controller: _composerController,
                  placeholder: 'Message…',
                  maxLines: 6,
                  minHeight: 44,
                  maxHeight: 160,
                  iconAlignment: CrossAxisAlignment.end,
                  onLineCountChanged: (lines) {
                    setState(() => _composerLineCount = lines);
                  },
                  shape: LiquidRoundedSuperellipse(
                    borderRadius: composerRadius,
                  ),
                  useOwnLayer: true,
                  quality: GlassQuality.premium,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  interactionBehavior: GlassInteractionBehavior.full,
                  onChanged: (_) => setState(() {}),
                  bottom: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(CupertinoIcons.paperclip,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.6)),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.camera,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.6)),
                          onPressed: () {},
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                                scale: animation, child: child),
                          ),
                          child: IconButton(
                            key: ValueKey(
                                _composerController.text.isNotEmpty
                                    ? 'send'
                                    : 'idle'),
                            icon: Icon(
                              CupertinoIcons.arrow_up_circle_fill,
                              size: 28,
                              color: _composerController.text.isNotEmpty
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 11,
          height: 1.5,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _debugReadout(String text, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: highlight
              ? Colors.greenAccent.withValues(alpha: 0.9)
              : Colors.white38,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
        child: Text(text),
      ),
    );
  }
}
