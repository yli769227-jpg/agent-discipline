#!/usr/bin/env bash
# install.sh — copy the agent-discipline skills into your Claude Code skills directory.
# Usage:  ./install.sh [target_dir]
# Default target: ~/.claude/skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills"
DEST="${1:-$HOME/.claude/skills}"

echo "[agent-discipline] source: $SRC"
echo "[agent-discipline] target: $DEST"

if [ ! -d "$SRC" ]; then
  echo "[agent-discipline] ERROR: skills/ not found next to this script." >&2
  exit 1
fi

mkdir -p "$DEST"

count=0
for skill in "$SRC"/*/; do
  name="$(basename "$skill")"
  if [ -e "$DEST/$name" ]; then
    echo "[agent-discipline] skip (already exists): $name"
    continue
  fi
  cp -r "$skill" "$DEST/$name"
  echo "[agent-discipline] installed: $name"
  count=$((count + 1))
done

echo "[agent-discipline] done — $count skill(s) installed into $DEST"
echo "[agent-discipline] restart your agent (or reload skills) to pick them up."
