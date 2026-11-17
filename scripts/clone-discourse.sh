#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${ROOT}/discourse"
if [[ -d "${TARGET}/.git" ]]; then
  echo "Discourse already present at ${TARGET}"
  exit 0
fi
git clone --depth 1 https://github.com/discourse/discourse.git "${TARGET}"
echo "Cloned into ${TARGET}"
