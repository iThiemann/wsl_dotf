#!/usr/bin/env bash
set -euo pipefail

main() {
  local env="${1:-dev}"
  echo "deploying to ${env}"
}

main "$@"
