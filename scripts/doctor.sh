#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_DIR="${INPUT_DIR:-"$ROOT_DIR/input"}"
OUTPUT_DIR="${OUTPUT_DIR:-"$ROOT_DIR/output"}"
IMAGE="${NERD_FONTS_PATCHER_IMAGE:-nerdfonts/patcher@sha256:5d7ffcb702a7c14eeda9b107f9dadd6d250dedf9d1f0993d966b4fd8337c47a6}"
LOG_FILE="${PATCH_LOG:-"$OUTPUT_DIR/patch.log"}"

FAILURES=0
WARNINGS=0

ok() {
  echo "ok: $1"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  echo "warn: $1"
}

fail() {
  FAILURES=$((FAILURES + 1))
  echo "fail: $1"
}

print_usage() {
  cat <<USAGE
Usage:
  ./scripts/doctor.sh

Checks local prerequisites for ./scripts/patch.sh without running the patcher,
pulling images, or writing generated fonts.

Environment overrides:
  INPUT_DIR=...
  OUTPUT_DIR=...
  PATCH_LOG=...
  NERD_FONTS_PATCHER_IMAGE=...
USAGE
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

echo "MonoLisa Nerd Fonts doctor"
echo

if command -v docker >/dev/null 2>&1; then
  ok "docker command found"
  if docker info >/dev/null 2>&1; then
    ok "docker daemon reachable"
  else
    fail "docker daemon is not reachable; start Docker and try again"
  fi
else
  fail "docker command not found; install Docker first"
fi

if [ -d "$INPUT_DIR" ]; then
  ok "input directory exists: $INPUT_DIR"
  FONT_COUNT="$(find "$INPUT_DIR" -maxdepth 1 -type f \( -name '*.ttf' -o -name '*.otf' \) | wc -l | tr -d '[:space:]')"
  if [ "$FONT_COUNT" -gt 0 ]; then
    ok "font files found: $FONT_COUNT"
    find "$INPUT_DIR" -maxdepth 1 -type f \( -name '*.ttf' -o -name '*.otf' \) -print | sort | sed 's/^/  - /'
  else
    fail "no .ttf or .otf files found in $INPUT_DIR"
  fi
else
  fail "input directory missing: $INPUT_DIR"
  echo "  Create it and add MonoLisa Code .ttf or .otf files."
fi

if [ -d "$OUTPUT_DIR" ]; then
  ok "output directory exists: $OUTPUT_DIR"
else
  warn "output directory does not exist yet: $OUTPUT_DIR"
  echo "  ./scripts/patch.sh will create it."
fi

if [ -d "$OUTPUT_DIR" ] && [ ! -w "$OUTPUT_DIR" ]; then
  fail "output directory is not writable: $OUTPUT_DIR"
fi

LOG_DIR="$(dirname "$LOG_FILE")"
if [ -d "$LOG_DIR" ]; then
  ok "log directory exists: $LOG_DIR"
else
  warn "log directory does not exist yet: $LOG_DIR"
  echo "  ./scripts/patch.sh will create it."
fi

if [[ "$IMAGE" == *@sha256:* ]]; then
  ok "patcher image is pinned by digest"
else
  warn "patcher image is not pinned by digest: $IMAGE"
fi

if command -v docker >/dev/null 2>&1 && docker image inspect "$IMAGE" >/dev/null 2>&1; then
  ok "patcher image available locally: $IMAGE"
else
  warn "patcher image is not available locally: $IMAGE"
  echo "  Docker will pull it during the first patch run if network access is available."
fi

echo
echo "Summary: $FAILURES failure(s), $WARNINGS warning(s)"

if [ "$FAILURES" -gt 0 ]; then
  echo "Fix the failures above, then run:"
  echo "  ./scripts/doctor.sh"
  exit 1
fi

echo "Ready to run:"
echo "  ./scripts/patch.sh"
