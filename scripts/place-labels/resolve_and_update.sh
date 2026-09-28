#!/usr/bin/env bash
# Resolve missing external place refs via HTTP APIs (CI only).
# curl + jq; per-ref failures are non-fatal.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./_common.sh
source "${here}/_common.sh"

USER_AGENT='BetMas-place-labels-bot/1.0 (BetaMasaheft catalog workflow)'
DEFAULT_DELAY_SEC=0.35

missing=""
artifact=""
delay="$DEFAULT_DELAY_SEC"
# Optional override: executable that prints a label for one ref on stdout.
resolver=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --missing) missing=$2; shift 2 ;;
    --artifact) artifact=$2; shift 2 ;;
    --delay) delay=$2; shift 2 ;;
    --resolver) resolver=$2; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --missing FILE --artifact FILE [--delay SEC] [--resolver CMD]" >&2
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

: "${missing:?--missing required}"
: "${artifact:?--artifact required}"

if [ ! -f "$missing" ]; then
  echo "missing file not found: ${missing}" >&2
  exit 1
fi
if [ ! -f "$artifact" ]; then
  echo "artifact not found: ${artifact}" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 2
fi

http_get_json() {
  local url="$1"
  curl -fsS -A "$USER_AGENT" --max-time 30 "$url"
}

resolve_wikidata() {
  local ref="$1"
  local qid="${ref#wd:}"
  local url data label
  url="https://www.wikidata.org/w/api.php?action=wbgetentities&ids=${qid}&props=labels&languages=en%7Cam%7Cde&format=json"
  data=$(http_get_json "$url")
  for lang in en am de; do
    label=$(printf '%s' "$data" | jq -r --arg id "$qid" --arg lang "$lang" \
      '.entities[$id].labels[$lang].value // empty')
    if [ -n "$label" ]; then
      printf '%s\n' "$label"
      return 0
    fi
  done
  label=$(printf '%s' "$data" | jq -r --arg id "$qid" \
    '[.entities[$id].labels[].value][0] // empty')
  if [ -n "$label" ]; then
    printf '%s\n' "$label"
    return 0
  fi
  echo "no label for ${ref}" >&2
  return 1
}

resolve_pleiades() {
  local ref="$1"
  local place_id="${ref#pleiades:}"
  local data title
  data=$(http_get_json "https://pleiades.stoa.org/places/${place_id}/json")
  title=$(printf '%s' "$data" | jq -r '.title // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [ -n "$title" ]; then
    printf '%s\n' "$title"
    return 0
  fi
  title=$(printf '%s' "$data" | jq -r '.names[0].romanized // empty')
  if [ -n "$title" ]; then
    printf '%s\n' "$title"
    return 0
  fi
  echo "no title for ${ref}" >&2
  return 1
}

resolve_geonames() {
  local ref="$1"
  local username="${GEONAMES_USERNAME:-}"
  local geoname_id data name
  username=$(nfc_trim "$username")
  if [ -z "$username" ]; then
    echo "GEONAMES_USERNAME not set" >&2
    return 1
  fi
  geoname_id="${ref#gn:}"
  data=$(http_get_json "https://secure.geonames.org/getJSON?geonameId=${geoname_id}&username=${username}")
  name=$(printf '%s' "$data" | jq -r '.name // .toponymName // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [ -n "$name" ]; then
    printf '%s\n' "$name"
    return 0
  fi
  name=$(printf '%s' "$data" | jq -r '.status.message // empty')
  if [ -n "$name" ]; then
    echo "$name" >&2
    return 1
  fi
  echo "no name for ${ref}" >&2
  return 1
}

resolve_ref() {
  local ref="$1"
  if [ -n "$resolver" ]; then
    "$resolver" "$ref"
    return $?
  fi
  case "$ref" in
    wd:*) resolve_wikidata "$ref" ;;
    pleiades:*) resolve_pleiades "$ref" ;;
    gn:*) resolve_geonames "$ref" ;;
    *)
      echo "unsupported ref: ${ref}" >&2
      return 1
      ;;
  esac
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures_path="${here}/failures.txt"
: >"$tmp/failures"
successes=0

read_artifact_items_tsv "$artifact" >"$tmp/items.tsv"
cut -f1 "$tmp/items.tsv" | sort -u >"$tmp/have"

while IFS= read -r line || [ -n "$line" ]; do
  ref=$(nfc_trim "$line")
  [ -n "$ref" ] || continue
  case "$ref" in \#*) continue ;; esac
  if ! ref=$(normalize_external_ref "$ref"); then
    echo "skip non-external ref: ${line}" >&2
    continue
  fi
  if grep -Fxq "$ref" "$tmp/have"; then
    continue
  fi
  if label=$(resolve_ref "$ref"); then
    label=$(nfc_trim "$label")
    printf '%s\t%s\n' "$ref" "$label" >>"$tmp/items.tsv"
    printf '%s\n' "$ref" >>"$tmp/have"
    successes=$((successes + 1))
    echo "resolved ${ref} -> ${label}"
    if awk "BEGIN { exit !(${delay} > 0) }"; then
      sleep "$delay"
    fi
  else
    printf '%s: resolve failed\n' "$ref" >>"$tmp/failures"
  fi
done <"$missing"

if [ "$successes" -gt 0 ]; then
  write_artifact_from_tsv "$artifact" \
    'Updated by resolve_and_update.sh (CI network resolve).' <"$tmp/items.tsv"
  echo "artifact updated (${successes} new label(s))"
fi

if [ -s "$tmp/failures" ]; then
  echo "resolve failures (non-fatal for CI PR):" >&2
  while IFS= read -r fline || [ -n "$fline" ]; do
    [ -n "$fline" ] || continue
    echo "  ${fline}" >&2
  done <"$tmp/failures"
  cp "$tmp/failures" "$failures_path"
  echo "wrote $(wc -l <"$tmp/failures" | tr -d ' ') failure(s) to ${failures_path}" >&2
  if [ "$successes" -eq 0 ]; then
    echo "WARN: no refs resolved; artifact unchanged (create-pull-request may skip)." >&2
  fi
  exit 0
fi

if [ "$successes" -eq 0 ]; then
  echo "no new refs to resolve (already in artifact or empty after filter)"
fi
exit 0
