#!/usr/bin/env bash
# Bump place-labels.xml expanded-sha in catalog manifest (bot / CI).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./_common.sh
source "${here}/_common.sh"

manifest=""
sha=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --manifest) manifest=$2; shift 2 ;;
    --sha) sha=$2; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --manifest FILE --sha SHA" >&2
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

: "${manifest:?--manifest required}"
: "${sha:?--sha required}"

if [ ! -f "$manifest" ]; then
  echo "ERROR: manifest missing: ${manifest}" >&2
  exit 1
fi

sha=$(nfc_trim "$sha")
if ! grep -qE 'name="place-labels\.xml"' "$manifest"; then
  echo "ERROR: artifact name=\"place-labels.xml\" not found in ${manifest}" >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Only rewrite the place-labels.xml artifact's expanded-sha attribute.
# Portable awk: match name= then find expanded-sha on the same open tag
# (may span lines until />).
set +e
awk -v newsha="$sha" '
  BEGIN { changed = 0 }
  {
    line = $0
    if (line ~ /name="place-labels\.xml"/) {
      in_place = 1
    }
    if (in_place && line ~ /expanded-sha="/) {
      old = line
      sub(/expanded-sha="[^"]*"/, "expanded-sha=\"" newsha "\"", line)
      if (line != old) changed = 1
      in_place = 0
    }
    if (in_place && line ~ /\/>/) {
      in_place = 0
    }
    print line
  }
  END {
    if (changed) exit 10
    exit 0
  }
' "$manifest" >"$tmp"
status=$?
set -e

if [ "$status" -eq 10 ]; then
  mv "$tmp" "$manifest"
  echo "Updated place-labels.xml expanded-sha in ${manifest}"
  exit 0
fi
if [ "$status" -eq 0 ]; then
  echo "place-labels.xml expanded-sha already matches; no change"
  exit 0
fi
echo "ERROR: failed to update manifest" >&2
exit 1
