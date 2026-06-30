#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_DIR="${INPUT_DIR:-"$ROOT_DIR/input"}"
OUTPUT_DIR="${OUTPUT_DIR:-"$ROOT_DIR/output"}"
IMAGE="${NERD_FONTS_PATCHER_IMAGE:-nerdfonts/patcher}"
LOG_FILE="${PATCH_LOG:-"$OUTPUT_DIR/patch.log"}"
VERBOSE="${PATCH_VERBOSE:-0}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required to run the Nerd Fonts patcher image" >&2
  exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
  echo "error: input directory not found: $INPUT_DIR" >&2
  exit 1
fi

if ! find "$INPUT_DIR" -maxdepth 1 -type f \( -name '*.ttf' -o -name '*.otf' \) | grep -q .; then
  echo "error: no .ttf or .otf files found in $INPUT_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

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
