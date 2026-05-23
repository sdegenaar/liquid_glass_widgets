/// Demo: GlassTextField v0.12.4 — visual verification of all 4 fixes.
///
/// WHAT TO CHECK IN THIS DEMO:
///   [1] Conditional height: single field starts at 44px pill, expands to
///       free-height once you type enough to wrap. Border-radius reduces live.
///   [2] Stale state: tap away from [1] (keyboard dismiss), tap back in, keep
///       typing → border-radius MUST keep animating (was broken before).
///   [3] Large Text: field [A] (fixed 44pt) must keep text centred when
///       device has "Larger Text" accessibility ON.
///   [4] Bottom panel: composer at the bottom shows text area + action bar
///       inside one glass card.
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
  // ── [Fix 1+2] Conditional height demo ───────────────────────────────────
  final _conditionalController = TextEditingController();
  int _conditionalLines = 1;

  // ── [Fix 4] Bottom-panel composer ────────────────────────────────────────
  final _composerController = TextEditingController();
  int _composerLineCount = 1;
  final List<String> _messages = [
    'Hey! Have you tried the new glass widgets?',
    'Yes! The liquid glass looks amazing on iOS 26 🤩',
    'Try the new GlassTextField — it has height constraints now',
    'And onLineCountChanged! Watch the border radius animate...',
    'v0.12.4: check out the conditional height field above 👆',
  ];

  // ── [Fix 3] Fixed-height search field ───────────────────────────────────
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _conditionalController.dispose();
    _composerController.dispose();
    _searchController.dispose();
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
    // Conditional border-radius: pill when 1 line, rounded rect when multi-line.
    final conditionalRadius = _conditionalLines <= 1 ? 22.0 : 12.0;
    final conditionalHeight = _conditionalLines > 1 ? null : 44.0;

    // Composer border-radius.
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
          title: const Text('TextField v0.12.4 Verification'),
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
              // ── Section header ──────────────────────────────────────────
              _sectionLabel('[A] Fix 3 — height: 44 (fixed). '
                  'Text must stay centred at any system font size.'),

              // Fixed 44pt search-style field — Issue 3 verification.
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

              // ── Section header ──────────────────────────────────────────
              _sectionLabel(
                  '[B] Fix 1+2 — conditional height + stale-state fix.\n'
                  'Type until text wraps → pill expands to free height.\n'
                  'Tap away, tap back, type more → MUST keep animating.'),

              // Conditional height field — Issue 1+2 verification.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: GlassTextField(
                    controller: _conditionalController,
                    placeholder: 'Type here until text wraps…',
                    maxLines: 3,
                    // THE KEY PATTERN: fixed pill when 1 line, free when multi.
                    height: conditionalHeight,
                    onLineCountChanged: (lines) {
                      setState(() => _conditionalLines = lines);
                    },
                    shape: LiquidRoundedSuperellipse(
                      borderRadius: conditionalRadius,
                    ),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    interactionBehavior: GlassInteractionBehavior.full,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

              // Live debug readout for [B].
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _conditionalLines > 1
                        ? Colors.greenAccent.withValues(alpha: 0.9)
                        : Colors.white38,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  child: Text(
                    'lines=$_conditionalLines  '
                    'height=${conditionalHeight?.toInt() ?? 'null (free)'}  '
                    'radius=${conditionalRadius.toInt()}',
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white12, indent: 16, endIndent: 16),
              const SizedBox(height: 4),

              // ── Section header ──────────────────────────────────────────
              _sectionLabel('[C] Fix 4 — bottom panel. Action bar and text\n'
                  'area share one glass card. Attachments + send in panel.'),

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
                          shape:
                              const LiquidRoundedSuperellipse(borderRadius: 16),
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

              // Live debug readout for [C].
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Text(
                  'lines=$_composerLineCount  radius=${composerRadius.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              // Bottom-panel composer — Issue 4 verification.
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  interactionBehavior: GlassInteractionBehavior.full,
                  onChanged: (_) => setState(() {}),
                  // ← Fix 4: bottom panel inside same glass card.
                  bottom: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            child:
                                ScaleTransition(scale: animation, child: child),
                          ),
                          child: IconButton(
                            key: ValueKey(_composerController.text.isNotEmpty
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
}
