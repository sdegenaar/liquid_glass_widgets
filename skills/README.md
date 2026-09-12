# Agent Skills for `liquid_glass_widgets`

This directory ships inside the `liquid_glass_widgets` pub package and is the canonical source of AI agent guidance for developers building with this library.

---

## What is this?

When vibecoding or pair-programming with AI, coding models may hallucinate non-existent APIs, recreate widgets unnecessarily with raw `BackdropFilter`s, or violate iOS 26 liquid glass rules (such as nesting refractive glass controls inside glass cards).

The **`liquid-glass-widgets`** skill provides AI agents with complete context on:
- Golden architectural rules (e.g. "Glass is a platter, not a wrapper", no nesting of refractive controls)
- Setup and shader initialization (`LiquidGlassWidgets.initialize()` & `LiquidGlassWidgets.wrap()`)
- Screen layout architecture with `GlassScaffold`
- Full component dictionary & substitution guide
- Common hallucinations and their correct replacements
- Production-ready patterns for navigation (`GlassTabBar.bottom`, `GlassAppBar`), modals (`GlassModalSheet`), and controls

---

## Installing in your own Flutter project (consumers)

After running `flutter pub add liquid_glass_widgets`, the skills directory is available in your pub cache. Use one of these methods to activate it in your AI assistant:

### Antigravity / Gemini CLI
```bash
mkdir -p .agents/skills/liquid-glass-widgets
curl -sSL https://raw.githubusercontent.com/sdegenaar/liquid_glass_widgets/main/skills/liquid-glass-widgets/SKILL.md \
  -o .agents/skills/liquid-glass-widgets/SKILL.md
```

### Claude Code
```bash
mkdir -p .claude/skills/liquid-glass-widgets
curl -sSL https://raw.githubusercontent.com/sdegenaar/liquid_glass_widgets/main/skills/liquid-glass-widgets/SKILL.md \
  -o .claude/skills/liquid-glass-widgets/SKILL.md
```

### Cursor IDE
Create `.cursor/rules/liquid-glass.mdc` and paste the contents of `SKILL.md`, or add this to your `.cursorrules`:
```
# liquid_glass_widgets rules
@https://raw.githubusercontent.com/sdegenaar/liquid_glass_widgets/main/skills/liquid-glass-widgets/SKILL.md
```

### GitHub Copilot / VS Code
Add the skill contents to `.github/copilot-instructions.md` in your project.

---

## Contributing to this package (repo contributors)

If you are working inside the `liquid_glass_widgets` repo itself, refer to [AGENTS.md](../AGENTS.md) at the repository root for contributor workflows, testing commands, and shader development rules.
