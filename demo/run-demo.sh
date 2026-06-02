#!/usr/bin/env bash
# Reproducible demo for the `test-is-truth` discipline.
# Every ✅/❌ below is a REAL test run (see test.mjs) — nothing is faked.
# Pacing: set DEMO_SPEED to scale pauses; NO_SLEEP=1 disables them (for CI).
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

B="\033[1m"; D="\033[2m"; R="\033[31m"; G="\033[32m"; Y="\033[33m"; C="\033[36m"; X="\033[0m"
pause() { [ -n "${NO_SLEEP:-}" ] || sleep "$(echo "${DEMO_SPEED:-1} * ${1:-1}" | bc -l 2>/dev/null || echo "${1:-1}")"; }
say() { printf "%b\n" "$1"; }

say "${B}Task:${X} write parsePrice() so \"\$1,299.50\" → 1299.50"; pause 1.5
say ""
say "${R}${B}── WITHOUT agent-discipline ──${X}"; pause 1
say "${D}agent:${X} ${B}Done!${X} parsePrice handles currency strings. ✨"; pause 1.5
say "${Y}…but it was never actually run. Here's what ships:${X}"; pause 1
node test.mjs ./src/parse-price.mjs; pause 2
say ""
say "${G}${B}── WITH agent-discipline / test-is-truth ──${X}"; pause 1
say "${D}agent:${X} \"Done\" means a verified test result. Let me run it."; pause 1.5
node test.mjs ./src/parse-price.mjs; pause 2
say "${C}agent:${X} ❌ caught before claiming done. Stripping the comma, retrying…"; pause 2
node test.mjs ./src/parse-price.fixed.mjs; pause 2
say ""
say "${B}Same agent. Same task. One shipped a bug confidently;${X}"
say "${B}the other was forced to prove it. ${C}github.com/yli769227-jpg/agent-discipline${X}"; pause 2
