#!/usr/bin/env bash
# Seed db/apps/catalogs/place-labels.xml from lists/placeNamesLabels.xml.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./_common.sh
source "${here}/_common.sh"

lists=""
out=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --lists) lists=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --lists FILE --out FILE" >&2
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

: "${lists:?--lists required}"
: "${out:?--out required}"

if [ ! -f "$lists" ]; then
  echo "lists file not found: ${lists}" >&2
  exit 1
fi
if ! command -v xmllint >/dev/null 2>&1; then
  echo "xmllint is required (libxml2-utils)" >&2
  exit 2
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

count=$(xmllint --xpath 'count(//*[local-name()="item"])' "$lists" 2>/dev/null || echo 0)
count=${count%.*}
i=1
: >"$tmp"
while [ "$i" -le "$count" ]; do
  corresp=$(xmllint --xpath "string((//*[local-name()=\"item\"])[$i]/@corresp)" "$lists" 2>/dev/null || true)
  label=$(xmllint --xpath "normalize-space(string((//*[local-name()=\"item\"])[$i]))" "$lists" 2>/dev/null || true)
  if canon=$(normalize_external_ref "$corresp"); then
    printf '%s\t%s\n' "$canon" "$label" >>"$tmp"
  fi
  i=$((i + 1))
done

n=$(awk -F '\t' 'NF >= 1 && !seen[$1]++ { c++ } END { print c+0 }' "$tmp")
write_artifact_from_tsv "$out" "Seeded from ${lists} (${n} external refs)." <"$tmp"
echo "Wrote ${n} items to ${out}"
