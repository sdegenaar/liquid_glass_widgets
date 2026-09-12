# Agent Guide for `liquid_glass_widgets`

This document is for AI agents interacting with the **`liquid_glass_widgets` repository itself** — contributing code, running tests, fixing bugs, or reviewing PRs.

**Two audiences — two documents:**

| Your goal | Read |
| :--- | :--- |
| Contribute to this repo (fix bugs, add widgets, modify shaders) | This file |
| Build a Flutter app that *uses* this package | **[skills/liquid-glass-widgets/SKILL.md](skills/liquid-glass-widgets/SKILL.md)** |

---

## 1. Environment & Requirements

- **Flutter SDK**: Requires Flutter ≥ 3.41.0 (Dart ≥ 3.5.0) for Impeller shader support.
- **Single Public Entry Point**: All public APIs must be exported from `lib/liquid_glass_widgets.dart`. Internal implementations live under `lib/src/`. Never expose private engine internals.

---

## 2. Standard Commands

Always verify changes using these commands before finalising:

```bash
# Analyse code for lint and type errors
flutter analyze

# Run unit and widget tests
flutter test

# Format all Dart files
dart format .

# Validate documentation comments
dart doc --dry-run
```

---

## 3. Shader Development Rules (GLSL / Impeller / SkSL)

When modifying fragment shaders in `shaders/`:

- **Dual-Pipeline Compatibility**: Shaders must compile on both **Impeller** (Metal/Vulkan) and **SkSL / SPIR-V** (Windows/Linux fallback).
- **No Dynamic Array Indexing**: Avoid indexing uniform arrays with variable expressions (`lights[i]` where `i` is a non-constant loop index without unrolling).
- **Loop Bounds**: All loops must have static, compile-time constant bounds.
- **No Forbidden Builtins**: `dFdx`, `dFdy`, `fwidth` are unavailable on some SPIR-V targets — avoid them in shared shaders.
- **Shader Validation**: Validate locally using `glslangValidator` or `flutter test` before opening a PR.

---

## 4. Git & Release Conventions

- **No Direct Commits to `main`**: All features and fixes must go through feature branches and pull requests.
- **CHANGELOG Updates**: Non-trivial changes must be documented in `CHANGELOG.md` following the established release format.
- **Zero Hallucination Rule**: Never introduce speculative parameters or undocumented imports. Verify against the actual Dart source in `lib/`.

---

## 5. Building UI with `liquid_glass_widgets`

All widget rules, component API patterns, app setup lifecycle, and anti-hallucination checklists live in the canonical consumer skill:

> 👉 **[skills/liquid-glass-widgets/SKILL.md](skills/liquid-glass-widgets/SKILL.md)**

Read that file before generating or reviewing any Flutter UI code that uses this package.

---

## Further Reference

- **[Architecture & Guidelines](docs/ARCHITECTURE.md)** — Core design principles and internal architecture.
- **[Platform Support](docs/PLATFORM_SUPPORT.md)** — Platform matrices and rendering pipeline compatibility.
- **[Migration Guide (0.x → 1.0)](docs/MIGRATION_0.x_TO_1.0.md)** — Step-by-step upgrade guide for 1.0.0 breaking changes.

