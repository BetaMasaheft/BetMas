# Place labels (HP6)

Offline catalog artifact at `db/apps/catalogs/place-labels.xml`. Network resolve runs only in `.github/workflows/place-labels.yml`.

## Commands

```bash
python3 scripts/place-labels/seed_from_lists.py \
  --lists db/apps/lists/placeNamesLabels.xml \
  --out db/apps/catalogs/place-labels.xml

python3 scripts/place-labels/scan_missing.py \
  --expanded /path/to/expanded \
  --artifact db/apps/catalogs/place-labels.xml

EXPANDED_ROOT=/path/to/expanded bash scripts/place-labels/check_coverage.sh
PLACE_LABELS_STRICT=1 EXPANDED_ROOT=/path/to/expanded bash scripts/place-labels/check_coverage.sh
```

`check_coverage.sh` warns while the artifact is empty, warns while a backlog remains after seed, and fails only when `PLACE_LABELS_STRICT=1` and refs are missing outside `exceptions.txt`.

## CI resolve (`resolve_and_update.py`)

The scheduled workflow resolves missing external refs over the network. **Per-ref resolve failures are non-fatal:** successful lookups are written to the artifact and the step exits `0` so `create-pull-request` can land partial updates. Failed refs are logged to stderr and appended to `scripts/place-labels/failures.txt` (gitignored) for Actions log review. The step exits `1` only for fatal errors (missing input files, bad arguments, uncaught exceptions).
