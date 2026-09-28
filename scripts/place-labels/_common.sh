#!/usr/bin/env bash
# Shared helpers for HP6 place-labels scripts (bash + xmllint; no Python).
# shellcheck shell=bash

xml_escape() {
  # Escape XML text / attribute content (amp first).
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g'
}

nfc_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  if command -v uconv >/dev/null 2>&1; then
    printf '%s' "$s" | uconv -f utf-8 -t utf-8 -x any-nfc
  else
    printf '%s' "$s"
  fi
}

# Map prefixed ids and common full URIs to canonical wd:/gn:/pleiades: form.
# Prints nothing (exit 1) when the value is not an external place authority ref.
# Ignores geonames ontology predicates (…/ontology#…).
normalize_external_ref() {
  local raw
  raw=$(nfc_trim "$1")
  [ -n "$raw" ] || return 1

  case "$raw" in
    wd:Q[0-9]*|wd:q[0-9]*)
      printf 'wd:Q%s\n' "${raw##*[Qq]}"
      return 0
      ;;
    gn:[0-9]*)
      printf '%s\n' "$raw"
      return 0
      ;;
    pleiades:[0-9]*)
      printf '%s\n' "$raw"
      return 0
      ;;
  esac

  local qid pid gid
  if [[ "$raw" =~ ^https?://(www\.)?wikidata\.org/(entity|wiki)/([Qq][0-9]+)(/.*)?$ ]]; then
    qid="${BASH_REMATCH[3]}"
    printf 'wd:Q%s\n' "${qid#[Qq]}"
    return 0
  fi
  if [[ "$raw" =~ ^https?://pleiades\.stoa\.org/places/([0-9]+)(/.*)?$ ]]; then
    pid="${BASH_REMATCH[1]}"
    printf 'pleiades:%s\n' "$pid"
    return 0
  fi
  if [[ "$raw" =~ ^https?://sws\.geonames\.org/([0-9]+)/?$ ]]; then
    gid="${BASH_REMATCH[1]}"
    printf 'gn:%s\n' "$gid"
    return 0
  fi
  if [[ "$raw" =~ ^https?://(www\.)?geonames\.org/([0-9]+)(/.*)?$ ]]; then
    # Numeric geonames place pages only — not ontology# predicates.
    gid="${BASH_REMATCH[2]}"
    printf 'gn:%s\n' "$gid"
    return 0
  fi
  return 1
}

is_external_ref() {
  normalize_external_ref "$1" >/dev/null
}

# Emit sorted unique canonical refs found in ref=/sameAs= attributes under a tree.
scan_expanded_refs() {
  local expanded_root="$1"
  local tmp out
  tmp=$(mktemp)
  out=$(mktemp)

  if [ ! -d "$expanded_root" ]; then
    rm -f "$tmp" "$out"
    echo "expanded root not found: ${expanded_root}" >&2
    return 1
  fi

  # ripgrep preferred; grep -R fallback for minimal environments.
  if command -v rg >/dev/null 2>&1; then
    rg -oN --no-filename -g '*.xml' \
      '(ref|sameAs)="[^"]+"' "$expanded_root" 2>/dev/null \
      | sed -E 's/^(ref|sameAs)="//; s/"$//' >>"$tmp" || true
  else
    find "$expanded_root" -type f -name '*.xml' -print0 2>/dev/null \
      | xargs -0 grep -hoE '(ref|sameAs)="[^"]+"' 2>/dev/null \
      | sed -E 's/^(ref|sameAs)="//; s/"$//' >>"$tmp" || true
  fi

  local raw canon
  while IFS= read -r raw || [ -n "$raw" ]; do
    [ -n "$raw" ] || continue
    if canon=$(normalize_external_ref "$raw"); then
      printf '%s\n' "$canon"
    fi
  done <"$tmp" | sort -u >"$out"
  cat "$out"
  rm -f "$tmp" "$out"
}

# Emit sorted unique canonical corresp values from place-labels artifact.
artifact_corresps() {
  local artifact="$1"
  if [ ! -f "$artifact" ]; then
    echo "artifact not found: ${artifact}" >&2
    return 1
  fi
  local raw canon
  grep -oE 'corresp="[^"]+"' "$artifact" 2>/dev/null \
    | sed -E 's/^corresp="//; s/"$//' \
    | while IFS= read -r raw || [ -n "$raw" ]; do
        [ -n "$raw" ] || continue
        if canon=$(normalize_external_ref "$raw"); then
          printf '%s\n' "$canon"
        fi
      done | sort -u
}

artifact_is_populated() {
  local artifact="$1"
  grep -qE 'corresp="(wd:|gn:|pleiades:)' "$artifact" 2>/dev/null
}

# Print TSV: corresp<TAB>label (canonical corresp only).
read_artifact_items_tsv() {
  local artifact="$1"
  if ! command -v xmllint >/dev/null 2>&1; then
    echo "xmllint is required (libxml2-utils)" >&2
    return 2
  fi
  local count i corresp label canon
  count=$(xmllint --xpath 'count(//*[local-name()="item"])' "$artifact" 2>/dev/null || echo 0)
  count=${count%.*}
  i=1
  while [ "$i" -le "$count" ]; do
    corresp=$(xmllint --xpath "string((//*[local-name()=\"item\"])[$i]/@corresp)" "$artifact" 2>/dev/null || true)
    label=$(xmllint --xpath "normalize-space(string((//*[local-name()=\"item\"])[$i]))" "$artifact" 2>/dev/null || true)
    if canon=$(normalize_external_ref "$corresp"); then
      printf '%s\t%s\n' "$canon" "$label"
    fi
    i=$((i + 1))
  done
}

# Write place-labels TEI from TSV on stdin (corresp<TAB>label). Dedupes by corresp.
write_artifact_from_tsv() {
  local path="$1"
  local source_note="$2"
  local tmp sorted corresp label canon
  tmp=$(mktemp)
  sorted=$(mktemp)

  cat >"$tmp"
  # Keep first label per corresp; sort by corresp (case-insensitive).
  awk -F '\t' 'NF >= 1 && !seen[$1]++ { print }' "$tmp" \
    | LC_ALL=C sort -t $'\t' -k1,1f >"$sorted"

  mkdir -p "$(dirname "$path")"
  {
    printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
    printf '%s\n' '<TEI xmlns="http://www.tei-c.org/ns/1.0">'
    printf '%s\n' '  <teiHeader>'
    printf '%s\n' '    <fileDesc>'
    printf '%s\n' '      <titleStmt><title>Place labels (catalog artifact)</title></titleStmt>'
    printf '%s\n' '      <publicationStmt><p>HP6 place-labels workflow; resolve in CI only.</p></publicationStmt>'
    printf '      <sourceDesc><p>%s</p></sourceDesc>\n' "$(xml_escape "$source_note")"
    printf '%s\n' '    </fileDesc>'
    printf '%s\n' '  </teiHeader>'
    printf '%s\n' '  <text><body><list xml:id="placeLabels">'
    while IFS=$'\t' read -r corresp label || [ -n "$corresp" ]; do
      [ -n "$corresp" ] || continue
      if ! canon=$(normalize_external_ref "$corresp"); then
        continue
      fi
      [ -n "$label" ] || label="$canon"
      printf '      <item corresp="%s">%s</item>\n' \
        "$(xml_escape "$canon")" "$(xml_escape "$label")"
    done <"$sorted"
    printf '%s\n' '  </list></body></text>'
    printf '%s\n' '</TEI>'
  } >"$path"
  rm -f "$tmp" "$sorted"
}
