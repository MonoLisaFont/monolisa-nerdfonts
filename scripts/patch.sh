#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_DIR="${INPUT_DIR:-"$ROOT_DIR/input"}"
OUTPUT_DIR="${OUTPUT_DIR:-"$ROOT_DIR/output"}"
IMAGE="${NERD_FONTS_PATCHER_IMAGE:-nerdfonts/patcher@sha256:5d7ffcb702a7c14eeda9b107f9dadd6d250dedf9d1f0993d966b4fd8337c47a6}"
LOG_FILE="${PATCH_LOG:-"$OUTPUT_DIR/patch.log"}"
CLEAN="${PATCH_CLEAN:-0}"
VERBOSE="${PATCH_VERBOSE:-0}"

print_usage() {
  cat <<USAGE
Usage:
  ./scripts/patch.sh [font-patcher-options...]

Inputs:
  Put MonoLisa Code .ttf or .otf files in:
    $INPUT_DIR

Outputs:
  Generated fonts:
    $OUTPUT_DIR
  Full patcher log:
    $LOG_FILE

Common environment variables:
  PATCH_CLEAN=1                 Remove old generated .ttf and .otf files first.
  PATCH_VERBOSE=1               Show raw FontForge and patcher output.
  PATCH_LOG=/path/to/patch.log  Write the captured patcher log elsewhere.
  NERD_FONTS_PATCHER_IMAGE=...  Override the pinned patcher image.

Examples:
  ./scripts/patch.sh
  PATCH_CLEAN=1 ./scripts/patch.sh
  PATCH_VERBOSE=1 ./scripts/patch.sh --debug

Docs:
  docs/patcher-options.md
  docs/maintenance.md
USAGE
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required to run the Nerd Fonts patcher image" >&2
  echo >&2
  print_usage >&2
  exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
  echo "error: input directory not found: $INPUT_DIR" >&2
  echo >&2
  print_usage >&2
  exit 1
fi

if ! find "$INPUT_DIR" -maxdepth 1 -type f \( -name '*.ttf' -o -name '*.otf' \) | grep -q .; then
  echo "error: no .ttf or .otf files found in $INPUT_DIR" >&2
  echo >&2
  print_usage >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

if [ "$CLEAN" = "1" ]; then
  find "$OUTPUT_DIR" -maxdepth 1 -type f \( -name '*.ttf' -o -name '*.otf' \) -delete
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/monolisa-nerdfonts.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

find "$INPUT_DIR" -maxdepth 1 -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp -p {} "$WORK_DIR"/ \;

DOCKER_CMD=(
  docker run --rm
  -v "$WORK_DIR:/in"
  -v "$OUTPUT_DIR:/out"
  "$IMAGE"
  --complete
  --careful
  --quiet
  --no-progressbars
  "$@"
)

if [ "$VERBOSE" = "1" ]; then
  "${DOCKER_CMD[@]}"
else
  echo "Patching fonts..."
  if "${DOCKER_CMD[@]}" >"$LOG_FILE" 2>&1; then
    echo "Generated fonts in $OUTPUT_DIR"
    echo "Full patcher log: $LOG_FILE"
  else
    status=$?
    echo "error: Nerd Fonts patcher failed; full log follows: $LOG_FILE" >&2
    cat "$LOG_FILE" >&2
    exit "$status"
  fi
fi
