#!/usr/bin/env bash
# ==============================================================================
# tests/run.sh — headless end-to-end test of the DevOps nvim config
#
#   tests/run.sh             test (fixtures copied to a temp dir, report printed)
#   tests/run.sh --install   sync plugins + install all Mason tools/parsers first
#   DEVOPS_TEST_ONLY=k8s tests/run.sh   only cases whose path contains "k8s"
#
# Exit code 0 = everything PASS/WARN, 1 = at least one FAIL.
# ==============================================================================
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ${1-} == --install ]]; then
  echo "==> plugins, parsers, Mason tools (first run takes several minutes)"
  nvim --headless -c "lua require('devops.install').run()"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -r "$here/fixtures/." "$tmp/"
(cd "$tmp/go" && git init -q 2>/dev/null || true)

echo "==> checkhealth"
nvim --headless "+checkhealth" "+w! $tmp/health.txt" +qa >/dev/null 2>&1 || true
if grep -q "ERROR" "$tmp/health.txt" 2>/dev/null; then
  echo "checkhealth reported errors (not fatal):"
  grep -B2 "ERROR" "$tmp/health.txt" | head -40
fi

echo "==> language tests"
cd "$tmp"
DEVOPS_TEST_FIXTURES="$tmp" nvim --headless -c "luafile $here/run.lua"
