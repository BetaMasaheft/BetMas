#!/usr/bin/env bash
# Print external place refs in expanded TEI missing from place-labels.xml.
# Canonicalizes full Wikidata / Pleiades / GeoNames URIs to wd:/pleiades:/gn:.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./_common.sh
source "${here}/_common.sh"

expanded=""
artifact=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expanded) expanded=$2; shift 2 ;;
    --artifact) artifact=$2; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --expanded DIR --artifact FILE" >&2
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

: "${expanded:?--expanded required}"
: "${artifact:?--artifact required}"

if [ ! -d "$expanded" ]; then
  echo "expanded root not found: ${expanded}" >&2
  exit 1
fi
if [ ! -f "$artifact" ]; then
  echo "artifact not found: ${artifact}" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

scan_expanded_refs "$expanded" >"$tmp/need"
artifact_corresps "$artifact" >"$tmp/have"
comm -23 "$tmp/need" "$tmp/have"
