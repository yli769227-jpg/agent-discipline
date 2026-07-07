#!/usr/bin/env bash
# install.sh — copy the agent-discipline skills into a Claude Code skills directory.
#
# Usage:
#   ./install.sh                 install globally into ~/.claude/skills
#   ./install.sh --project       install into ./.claude/skills (current repo)
#   ./install.sh --force         overwrite skills that already exist
#   ./install.sh [target_dir]    install into an explicit directory
#
# Flags compose, e.g.  ./install.sh --project --force
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills"

FORCE=0
SCOPE="global"          # global | project
TARGET_OVERRIDE=""

# --- parse args ---------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --project) SCOPE="project" ;;
    --global)  SCOPE="global" ;;
    --force)   FORCE=1 ;;
    -h|--help)
      sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --*)
      echo "[agent-discipline] ERROR: unknown flag: $1" >&2
      exit 2
      ;;
    *)
      TARGET_OVERRIDE="$1"
      ;;
  esac
  shift
done

# --- resolve destination ------------------------------------------------------
if [ -n "$TARGET_OVERRIDE" ]; then
  DEST="$TARGET_OVERRIDE"
elif [ "$SCOPE" = "project" ]; then
  DEST="$(pwd)/.claude/skills"
else
  DEST="$HOME/.claude/skills"
fi

echo "[agent-discipline] scope:  $SCOPE"
echo "[agent-discipline] source: $SRC"
echo "[agent-discipline] target: $DEST"
[ "$FORCE" -eq 1 ] && echo "[agent-discipline] force:  overwrite existing skills"

if [ ! -d "$SRC" ]; then
  echo "[agent-discipline] ERROR: skills/ not found next to this script." >&2
  exit 1
fi

mkdir -p "$DEST"

# --- copy ---------------------------------------------------------------------
installed=0
skipped=0
overwritten=0
for skill in "$SRC"/*/; do
  name="$(basename "$skill")"
  if [ -e "$DEST/$name" ]; then
    if [ "$FORCE" -eq 1 ]; then
      rm -rf "${DEST:?}/$name"
      cp -r "$skill" "$DEST/$name"
      echo "[agent-discipline] overwritten: $name"
      overwritten=$((overwritten + 1))
    else
      echo "[agent-discipline] skip (already exists, use --force): $name"
      skipped=$((skipped + 1))
    fi
    continue
  fi
  cp -r "$skill" "$DEST/$name"
  echo "[agent-discipline] installed: $name"
  installed=$((installed + 1))
done

echo "[agent-discipline] done — $installed new, $overwritten overwritten, $skipped skipped → $DEST"
if [ "$SCOPE" = "project" ]; then
  echo "[agent-discipline] project-local install. Commit .claude/skills/ to share with your team."
else
  echo "[agent-discipline] restart your agent (or reload skills) to pick them up."
fi
