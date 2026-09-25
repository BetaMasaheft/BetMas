#!/usr/bin/env bash
# HP6 coverage: external place refs in expanded must be in place-labels.xml
# or scripts/place-labels/exceptions.txt. Warn-only until artifact is seeded.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
expanded="${EXPANDED_ROOT:-${root}/../expanded}"
artifact="${ARTIFACT:-${root}/db/apps/catalogs/place-labels.xml}"
exceptions="${root}/scripts/place-labels/exceptions.txt"
strict="${PLACE_LABELS_STRICT:-}"

if [ ! -d "${expanded}" ]; then
  echo "WARN: expanded checkout missing at ${expanded}; skipping place-labels coverage" >&2
  exit 0
fi
if [ ! -f "${artifact}" ]; then
  echo "ERROR: artifact missing: ${artifact}" >&2
  exit 1
fi

missing_file="$(mktemp)"
trap 'rm -f "${missing_file}"' EXIT

python3 "${root}/scripts/place-labels/scan_missing.py" \
  --expanded "${expanded}" \
  --artifact "${artifact}" > "${missing_file}"

count="$(wc -l < "${missing_file}" | tr -d ' ')"
if grep -qE 'corresp="(wd:|gn:|pleiades:)' "${artifact}"; then
  populated=yes
else
  populated=no
fi

if [ "${populated}" = "no" ]; then
  echo "WARN: place-labels artifact not populated yet (${count} refs missing in expanded); warn mode" >&2
  exit 0
fi

if [ "${count}" -eq 0 ]; then
  echo "place-labels coverage OK (artifact populated)"
  exit 0
fi

if [ -z "${strict}" ]; then
  echo "WARN: artifact populated but ${count} expanded refs still missing; set PLACE_LABELS_STRICT=1 to enforce" >&2
  exit 0
fi

while IFS= read -r ref; do
  [ -n "${ref}" ] || continue
  if ! grep -Fxq "${ref}" "${exceptions}" 2>/dev/null; then
    echo "MISSING: ${ref} (not in artifact or ${exceptions})" >&2
    exit 1
  fi
done < "${missing_file}"

echo "place-labels coverage OK (${count} missing refs listed in exceptions.txt)"
exit 0
