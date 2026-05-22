/// Demo: GlassTextField 0.12.2 features.
///
/// Showcases:
///   - `height` — fixed 44pt field matching GlassSearchBar
///   - `minHeight` / `maxHeight` — auto-growing chat composer
///   - `onLineCountChanged` — drives animated border-radius reduction
///   - `iconAlignment: CrossAxisAlignment.end` — icons pinned to bottom
///
/// To run: flutter run -t lib/demos/text_field_demo.dart
///
/// Run on a physical iOS device (Impeller) for best visual results.
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
  // ── Chat composer state ──────────────────────────────────────────────────
  final _composerController = TextEditingController();
  int _composerLineCount = 1;
  final List<String> _messages = [
    'Hey! Have you tried the new glass widgets?',
    'Yes! The liquid glass looks amazing on iOS 26 🤩',
    'Try the new GlassTextField — it has height constraints now',
    'And onLineCountChanged! Watch the border radius animate...',
  ];

  // ── Fixed-height field state ─────────────────────────────────────────────
  final _searchController = TextEditingController();

  @override
  void dispose() {
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
    // Animate border radius from pill (1 line) to rounded rect (multi-line).
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
          title: const Text('TextField Demo'),
          quality: GlassQuality.premium,
          useOwnLayer: true,
        ),
        body: Column(
          children: [
            // ── Fixed-height search field (Feature 1) ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GlassTextField.search(
                controller: _searchController,
                placeholder: 'Search messages…',
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  size: 20,
                  color: Colors.white60,
                ),
                useOwnLayer: true,
                quality: GlassQuality.premium,
              ),
            ),

            // ── Feature label ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '↑ height: 44  •  ↓ minHeight/maxHeight + onLineCountChanged',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ── Message list ─────────────────────────────────────────────
            Expanded(
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
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: GlassCard(
                        useOwnLayer: true,
                        quality: GlassQuality.premium,
                        shape: LiquidRoundedSuperellipse(borderRadius: 16),
                        settings: LiquidGlassSettings(
                          glassColor: isMe
                              ? Colors.blue.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            _messages[msgIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Line count indicator ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _composerLineCount > 1
                          ? Colors.white70
                          : Colors.white38,
                      fontSize: 11,
                    ),
                    child: Text(
                      'Lines: $_composerLineCount  •  '
                      'borderRadius: ${composerRadius.toInt()}  •  '
                      'iconAlignment: end',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Chat composer (Features 1+2+3) ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: GlassTextField(
                  controller: _composerController,
                  placeholder: 'Type a message…',
                  maxLines: 6,
                  minHeight: 44, // ← Feature 1: min constraint
                  maxHeight: 160, // ← Feature 1: max constraint
                  iconAlignment: CrossAxisAlignment.end, // ← Feature 3
                  onLineCountChanged: (lines) {
                    // ← Feature 2
                    setState(() => _composerLineCount = lines);
                  },
                  shape: LiquidRoundedSuperellipse(
                    borderRadius: composerRadius,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.smiley,
                    size: 24,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  suffixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      key: ValueKey(
                        _composerController.text.isNotEmpty ? 'send' : 'idle',
                      ),
                      size: 28,
                      color: _composerController.text.isNotEmpty
                          ? Colors.white
                          : Colors.white38,
                    ),
                  ),
                  onSuffixTap: _sendMessage,
                  onChanged: (_) => setState(() {}), // refresh suffix icon
                  useOwnLayer: true,
                  quality: GlassQuality.premium,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  iconSpacing: 8,
                  interactionBehavior: GlassInteractionBehavior.glowOnly,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
