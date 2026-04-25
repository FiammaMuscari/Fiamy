#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <tag-del-release>" >&2
  exit 1
fi

TAG="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

gh release upload "${TAG}" \
  "${ROOT_DIR}"/dist/linux-portable/*.tar.gz \
  "${ROOT_DIR}"/dist/linux-deb/*.deb \
  --repo FiammaMuscari/Fiamy
