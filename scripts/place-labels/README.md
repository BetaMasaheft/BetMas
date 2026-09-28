# Place labels (HP6)

Offline catalog artifact at `db/apps/catalogs/place-labels.xml`. Network resolve runs only in `.github/workflows/place-labels.yml`.

Stack: **bash + xmllint + curl + jq** (same family as expanded retired-ids CI). No Python.

## Commands

```bash
bash scripts/place-labels/seed_from_lists.sh \
  --lists db/apps/lists/placeNamesLabels.xml \
  --out db/apps/catalogs/place-labels.xml

bash scripts/place-labels/scan_missing.sh \
  --expanded /path/to/expanded \
  --artifact db/apps/catalogs/place-labels.xml

EXPANDED_ROOT=/path/to/expanded bash scripts/place-labels/check_coverage.sh
PLACE_LABELS_STRICT=1 EXPANDED_ROOT=/path/to/expanded bash scripts/place-labels/check_coverage.sh

bats scripts/place-labels/test_place_labels.bats
```

`scan_missing.sh` canonicalizes full Wikidata / Pleiades / GeoNames place URIs to `wd:` / `pleiades:` / `gn:` (and ignores geonames ontology predicates).

`check_coverage.sh` warns while the artifact is empty, warns while a backlog remains after seed, and fails only when `PLACE_LABELS_STRICT=1` and refs are missing outside `exceptions.txt`.

After scan/resolve, CI runs `bump_manifest_pin.sh` to set `manifest.xml` artifact `place-labels.xml` `@expanded-sha` to the expanded checkout HEAD (does not change `retired-ids.xml` or committed `expanded-sha.txt`).

## CI resolve (`resolve_and_update.sh`)

The scheduled workflow resolves missing external refs over the network (`curl` + `jq`). **Per-ref resolve failures are non-fatal:** successful lookups are written to the artifact and the step exits `0` so `create-pull-request` can land partial updates. Failed refs are logged to stderr and appended to `scripts/place-labels/failures.txt` (gitignored) for Actions log review. The step exits `1` only for fatal errors (missing input files, bad arguments).
