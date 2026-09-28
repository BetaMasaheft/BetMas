#!/usr/bin/env bats
# Place-labels HP6 script tests (fixtures only; no network).

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  FIXTURES="${DIR}/fixtures"
  TMPDIR_TEST="$(mktemp -d)"
}

teardown() {
  rm -rf "${TMPDIR_TEST}"
  rm -f "${DIR}/failures.txt" "${FIXTURES}/out-place-labels.xml"
}

@test "bump_manifest_pin updates place-labels only" {
  cp "${FIXTURES}/mini-manifest.xml" "${TMPDIR_TEST}/manifest.xml"
  new_sha='ccc3333333333333333333333333333333333333333'
  run bash "${DIR}/bump_manifest_pin.sh" \
    --manifest "${TMPDIR_TEST}/manifest.xml" \
    --sha "${new_sha}"
  [ "$status" -eq 0 ]
  grep -q "expanded-sha=\"${new_sha}\"" "${TMPDIR_TEST}/manifest.xml"
  grep -q 'expanded-sha="aaa1111111111111111111111111111111111111111"' "${TMPDIR_TEST}/manifest.xml"
  ! grep -q 'expanded-sha="bbb2222222222222222222222222222222222222222"' "${TMPDIR_TEST}/manifest.xml"

  run bash "${DIR}/bump_manifest_pin.sh" \
    --manifest "${TMPDIR_TEST}/manifest.xml" \
    --sha "  ${new_sha}  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"already matches"* ]]
}

@test "seed_from_lists writes external items only" {
  out="${FIXTURES}/out-place-labels.xml"
  rm -f "$out"
  run bash "${DIR}/seed_from_lists.sh" \
    --lists "${FIXTURES}/mini-lists.xml" \
    --out "$out"
  [ "$status" -eq 0 ]
  grep -q 'corresp="wd:Q1"' "$out"
  grep -q 'corresp="pleiades:99"' "$out"
  ! grep -q 'LOC0001' "$out"
}

@test "scan_missing canonicalizes full URIs and reports gaps" {
  run bash "${DIR}/scan_missing.sh" \
    --expanded "${FIXTURES}/mini-expanded" \
    --artifact "${FIXTURES}/mini-artifact.xml"
  [ "$status" -eq 0 ]
  # wd:Q9 from entity URI; pleiades:99 from full URI; not in mini-artifact
  [[ "$output" == *$'\n'* ]] || true
  printf '%s\n' "$output" | grep -Fxq 'wd:Q9'
  printf '%s\n' "$output" | grep -Fxq 'pleiades:99'
  ! printf '%s\n' "$output" | grep -Fxq 'wd:Q1'
  ! printf '%s\n' "$output" | grep -q 'geonames.org/ontology'
}

@test "resolve_and_update partial failure exits zero" {
  cp "${FIXTURES}/mini-artifact.xml" "${TMPDIR_TEST}/artifact.xml"
  printf '%s\n' 'wd:Q9' 'wd:Q99999' >"${TMPDIR_TEST}/missing.txt"
  cat >"${TMPDIR_TEST}/fake-resolver" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  wd:Q9) echo 'Resolved Nine'; exit 0 ;;
  *) echo "mock failure" >&2; exit 1 ;;
esac
EOF
  chmod +x "${TMPDIR_TEST}/fake-resolver"

  run bash "${DIR}/resolve_and_update.sh" \
    --missing "${TMPDIR_TEST}/missing.txt" \
    --artifact "${TMPDIR_TEST}/artifact.xml" \
    --delay 0 \
    --resolver "${TMPDIR_TEST}/fake-resolver"
  [ "$status" -eq 0 ]
  grep -q 'corresp="wd:Q9">Resolved Nine</item>' "${TMPDIR_TEST}/artifact.xml"
  [ -f "${DIR}/failures.txt" ]
  grep -q 'wd:Q99999' "${DIR}/failures.txt"
}
