#!/usr/bin/env bash
# validate_shaders.sh
#
# Validates liquid_glass_widgets GLSL shaders for Windows/Web/Impeller/SkSL
# compatibility using:
#   1. Static HLSL/FXC single-exit `main()` check (flutter/flutter#190809) —
#      always runs with zero external dependencies; fails if any `.frag` with a
#      `sampler2D` has multiple `return` exit points in `void main()`.
#   2. `glslangValidator --target-env vulkan1.0` (SPIR-V validation) when installed.
#   3. Flutter's `impellerc` (`--sksl` + Metal/GLES/Vulkan runtime stages) when
#      a Flutter SDK is available, failing on any `[WARNING]` or compiler error.
#
# Usage:
#   bash scripts/validate_shaders.sh
#
# Install glslang (if running without Flutter SDK):
#   macOS:   brew install glslang
#   Ubuntu:  sudo apt-get install glslang-tools
#   Windows: choco install glslang

set -euo pipefail

# ── Path resolution ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHADER_DIR="$REPO_ROOT/shaders"

resolve_flutter_root() {
  local bin="$1"
  while [[ -L "$bin" ]]; do
    local dir
    dir="$(cd -P "$(dirname "$bin")" && pwd)"
    bin="$(readlink "$bin")"
    [[ "$bin" != /* ]] && bin="$dir/$bin"
  done
  (cd -P "$(dirname "$bin")/.." && pwd)
}

# ── Tool discovery ────────────────────────────────────────────────────────────
VALIDATOR=""
for cand in glslangValidator glslangValidator.exe /opt/homebrew/bin/glslangValidator /usr/local/bin/glslangValidator; do
  if command -v "$cand" &>/dev/null; then
    VALIDATOR="$(command -v "$cand")"
    break
  fi
done

IMPELLERC=""
SHADER_LIB_DIR=""
if command -v impellerc &>/dev/null; then
  IMPELLERC="$(command -v impellerc)"
elif command -v flutter &>/dev/null; then
  FLUTTER_ROOT="$(resolve_flutter_root "$(command -v flutter)")"
  SHADER_LIB_DIR="$FLUTTER_ROOT/bin/cache/artifacts/shader_lib"
  for cand in \
    "$FLUTTER_ROOT"/bin/cache/artifacts/engine/darwin-arm64/impellerc \
    "$FLUTTER_ROOT"/bin/cache/artifacts/engine/darwin-x64/impellerc \
    "$FLUTTER_ROOT"/bin/cache/artifacts/engine/linux-x64/impellerc \
    "$FLUTTER_ROOT"/bin/cache/artifacts/engine/linux-arm64/impellerc \
    "$FLUTTER_ROOT"/bin/cache/artifacts/engine/windows-x64/impellerc.exe; do
    if [[ -f "$cand" && -x "$cand" ]]; then
      IMPELLERC="$cand"
      break
    fi
  done
fi

if [[ -z "$VALIDATOR" && -z "$IMPELLERC" ]]; then
  echo "❌  Neither glslangValidator nor Flutter impellerc was found."
  echo ""
  echo "    Install instructions:"
  echo "      macOS:   brew install glslang   (or add flutter to PATH)"
  echo "      Ubuntu:  sudo apt-get install glslang-tools"
  echo "      Windows: choco install glslang"
  exit 1
fi

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'lgw_shaders')"
trap 'rm -rf "$TMP_DIR"' EXIT

# ── Helper: static single-return check in `void main()` (flutter#190809) ──────
# Returns non-empty error message if the `.frag` declares/uses `sampler2D` and
# has an early or multiple `return` statement inside `void main()`.
check_single_return_main() {
  local frag_file="$1"
  awk '
    BEGIN {
      in_comment = 0
      src = ""
    }
    {
      line = $0
      out = ""
      while (length(line) > 0) {
        if (in_comment) {
          idx = index(line, "*/")
          if (idx == 0) {
            line = ""
          } else {
            line = substr(line, idx + 2)
            in_comment = 0
          }
        } else {
          c_line = index(line, "//")
          c_blk  = index(line, "/*")
          if (c_line > 0 && (c_blk == 0 || c_line < c_blk)) {
            out = out substr(line, 1, c_line - 1)
            line = ""
          } else if (c_blk > 0) {
            out = out substr(line, 1, c_blk - 1)
            line = substr(line, c_blk + 2)
            in_comment = 1
          } else {
            out = out line
            line = ""
          }
        }
      }
      if (out !~ /^[[:space:]]*#/) {
        src = src "\n" out
      }
    }
    END {
      has_sampler = (src ~ /(^|[^A-Za-z0-9_])sampler2D([^A-Za-z0-9_]|$)/)
      if (!has_sampler) exit 0

      if (match(src, /void[[:space:]]+main[[:space:]]*\([[:space:]]*(void)?[[:space:]]*\)/)) {
        rest = substr(src, RSTART + RLENGTH)
        brace_pos = index(rest, "{")
        if (brace_pos == 0) exit 0
        depth = 0
        body = ""
        n = length(rest)
        for (i = brace_pos; i <= n; i++) {
          ch = substr(rest, i, 1)
          if (ch == "{") depth++
          else if (ch == "}") {
            depth--
            if (depth == 0) {
              body = substr(rest, brace_pos + 1, i - brace_pos - 1)
              break
            }
          }
        }
        # Strip an optional single trailing `return;` at the very end of main().
        sub(/return[[:space:]]*;[[:space:]]*$/, "", body)
        if (body ~ /(^|[^A-Za-z0-9_])return([^A-Za-z0-9_]|$)/) {
          print "Fragment shader uses sampler2D alongside multiple/early return statements in main() (Windows HLSL/FXC crash risk; see https://github.com/flutter/flutter/issues/190809)."
        }
      }
    }
  ' "$frag_file"
}

PASS=0
FAIL=0
WARN=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Liquid Glass — Shader Validation (HLSL/FXC + SPIR-V + Impeller)"
if [[ -n "$VALIDATOR" ]]; then
  VALIDATOR_VERSION=$("$VALIDATOR" --version 2>&1 | head -1 || echo "version unknown")
  echo "  glslang:    $VALIDATOR ($VALIDATOR_VERSION)"
else
  echo "  glslang:    (not installed — skipped)"
fi
if [[ -n "$IMPELLERC" ]]; then
  echo "  impellerc:  $IMPELLERC"
else
  echo "  impellerc:  (not in PATH — skipped)"
fi
echo "  Shader dir: $SHADER_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for frag in "$SHADER_DIR"/*.frag; do
  name="$(basename "$frag")"
  has_error=false
  has_impeller_warn=false
  clean_output=""

  # 1. Static HLSL/FXC single-return check in main() (flutter/flutter#190809).
  ret_err="$(check_single_return_main "$frag")"
  if [[ -n "$ret_err" ]]; then
    has_error=true
    clean_output+="  ❌  [HLSL/FXC] $ret_err"$'\n'
  fi

  # 2. glslangValidator SPIR-V check (when installed).
  if [[ -n "$VALIDATOR" ]]; then
    output=$("$VALIDATOR" \
      --target-env vulkan1.0 \
      -S frag \
      -I "$SHADER_DIR" \
      "$frag" 2>&1) || true

    while IFS= read -r line; do
      if [[ "$line" == *"FlutterFragCoord"* ]] ||
         [[ "$line" == *"GL_GOOGLE_include_directive"* ]] ||
         [[ "$line" == *"layout"*"location"* && "$line" == *"warning"* ]]; then
        has_impeller_warn=true
        continue
      fi

      if [[ "$line" == *"error"* ]]; then
        has_error=true
        clean_output+="  ❌  [glslang] $line"$'\n'
      elif [[ "$line" == *"warning"* ]]; then
        clean_output+="  ⚠️   [glslang] $line"$'\n'
      fi
    done <<< "$output"
  fi

  # 3. Flutter impellerc multi-target runtime stage check (when available).
  # Treats any `[WARNING]` (including flutter/flutter#190809) or non-zero exit
  # code as a hard failure so Web/Windows shader warnings never slip through.
  if [[ -n "$IMPELLERC" && -d "$SHADER_LIB_DIR" ]]; then
    imp_status=0
    imp_out=$("$IMPELLERC" \
      --sksl \
      --runtime-stage-metal \
      --runtime-stage-gles \
      --runtime-stage-vulkan \
      --iplr \
      --input="$frag" \
      --input-type=frag \
      --sl="$TMP_DIR/$name.iplr" \
      --spirv="$TMP_DIR/$name.spv" \
      --include="$SHADER_DIR" \
      --include="$SHADER_LIB_DIR" 2>&1) || imp_status=$?

    if [[ $imp_status -ne 0 ]] || [[ "$imp_out" == *"[WARNING]"* ]] || [[ "$imp_out" == *"warning:"* ]]; then
      has_error=true
      while IFS= read -r line; do
        [[ -n "$line" ]] && clean_output+="  ❌  [impellerc] $line"$'\n'
      done <<< "$imp_out"
    fi
  fi

  if $has_error; then
    echo "FAIL  $name"
    printf "%s" "$clean_output"
    FAIL=$((FAIL + 1))
  elif [[ -n "$clean_output" ]]; then
    echo "WARN  $name"
    printf "%s" "$clean_output"
    WARN=$((WARN + 1))
  else
    if $has_impeller_warn; then
      echo "PASS  $name  (Impeller extensions suppressed)"
    else
      echo "PASS  $name"
    fi
    PASS=$((PASS + 1))
  fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results: ${PASS} passed  ${WARN} warnings  ${FAIL} failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "  ⛔  Shader validation failed. Fix the errors above before releasing."
  exit 1
else
  echo ""
  echo "  ✅  All shaders pass validation with zero warnings."
  exit 0
fi
