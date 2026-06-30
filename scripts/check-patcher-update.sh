#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH_SCRIPT="$ROOT_DIR/scripts/patch.sh"
LATEST_IMAGE="${NERD_FONTS_PATCHER_LATEST_IMAGE:-nerdfonts/patcher:latest}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required to check the patcher image" >&2
  exit 1
fi

PINNED_IMAGE="$(grep '^IMAGE=' "$PATCH_SCRIPT" | sed 's/^IMAGE="${NERD_FONTS_PATCHER_IMAGE:-//; s/}"$//')"

if [[ "$PINNED_IMAGE" != *@sha256:* ]]; then
  echo "error: pinned patcher image does not include a digest: $PINNED_IMAGE" >&2
  exit 1
fi

PINNED_DIGEST="${PINNED_IMAGE##*@}"

echo "Checking Nerd Fonts patcher image..."
docker pull "$LATEST_IMAGE" >/dev/null

LATEST_REPO_DIGEST="$(docker image inspect "$LATEST_IMAGE" --format '{{index .RepoDigests 0}}')"
LATEST_DIGEST="${LATEST_REPO_DIGEST##*@}"

echo "Pinned: $PINNED_IMAGE"
echo "Latest: $LATEST_REPO_DIGEST"

if [ "$PINNED_DIGEST" = "$LATEST_DIGEST" ]; then
  echo "Pinned patcher image is up to date."
else
  echo "Newer patcher image is available."
  echo "Test with:"
  echo "  NERD_FONTS_PATCHER_IMAGE=$LATEST_REPO_DIGEST ./scripts/patch.sh"
  echo "If the output is good, update the pinned digest in scripts/patch.sh."
fi
