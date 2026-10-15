Replace-only catalog artifacts baked into `catalogs.xar` for `/db/apps/catalogs`.

`collection.xconf` defines a range index on `t:item/@corresp` for **labels** (and any other `@corresp` items). Institutions use `@xml:id` (same shape as `lists/institutions.xml`), not `@corresp`. Serving also uses BetMasWeb map-once indexes for labels; the range index is belt-and-suspenders for direct XPath.

- **Data image:** `collection.xconf` is packaged into `catalogs.xar` (`data.Dockerfile`).
- **App image:** `docker/app.Dockerfile` copies the same file to `/tmp/catalogs-collection.xconf`; `generate_artifacts.xq` installs it under `/db/system/config/db/apps/catalogs/` and reindexes `/db/apps/catalogs` so the index applies without waiting for a data rebuild.

The data image build copies `retired-ids.xml` from `expanded/config/retired-ids.xml` at `EXPANDED_REF` and sets that artifact's manifest `@expanded-sha`, plus the `bibl-exceptions.xml` pin, to the same value written into `expanded-sha.txt`. `place-labels.xml` keeps the pin from the last scan.

`bibl-exceptions.xml` is the Phase 4 allowlist: serving-path bibl may fall back to `lists/bibliography.xml` only for entries with `lists-fallback="true"`. Re-triaged 2026-10-13 against bibliography `83f1118`: leftovers are four pending exports, two TEI retags, and `bm:Turaev1909ZaraBuruk` ([bibliography#27](https://github.com/BetaMasaheft/bibliography/issues/27) / [#28](https://github.com/BetaMasaheft/bibliography/issues/28)).

The committed `expanded-sha.txt` is a dev/default seed. The data image build overwrites it from the `EXPANDED_REF` build arg immediately before packaging `catalogs.xar`. **CI must pass a resolved expanded commit SHA** as `EXPANDED_REF` (see `build-data.yml`); the stale gate compares manifest `@expanded-sha` to this file. Local ad-hoc builds may pass `EXPANDED_REF=main`, which pins the literal string `main` and is not meaningful for freshness checks.

## App-image generated artifacts

`institutions.xml` and `labels.xml` are **not** in this directory and not in
`catalogs.xar`. `docker/app.Dockerfile` runs `scripts/catalogs/generate_artifacts.xq`
after the app boot; it writes both into `/db/apps/catalogs/` through BetMasWeb's
`catalog.xqm` (`catalog:institutions("catalog")`, `catalog:full-title`) and adds
manifest rows pinned to the image's `expanded-sha.txt`. They are therefore exact
for their image.

`docker-compose.yml` Phase 5 `CATALOG_BACKEND_*` flips assume an app image that has
run this bake. Do not point compose at an older `release-expanded` without those
files — serving falls back to live TEI/`full-title` and is much slower.

### Regenerate locally

Package mode is often `rwxr-xr-x`. The generator chmods the catalogs collection
when run as admin. Prefer the same client the Dockerfile uses:

```bash
# against a stack whose BetMasWeb already has catalog:full-title (post-#242)
docker exec betmas-betmas-1 java org.exist.start.Main client --no-gui -l \
  -u admin -P '' -F /tmp/generate_artifacts.xq
```

Or via REST/xst as **admin** (not a restricted user):

```bash
EXISTDB_SERVER=http://127.0.0.1:8082/exist \
EXISTDB_USER=admin EXISTDB_PASS= \
  xst run --file scripts/catalogs/generate_artifacts.xq
```

If write still fails, as admin: `sm:chmod(xs:anyURI("/db/apps/catalogs"), "rwxrwxr-x")`.
For xconf install + reindex, the generator reads `/tmp/catalogs-collection.xconf`
(app-image bake) or falls back to `/db/apps/catalogs/collection.xconf` if that
document is already stored (upload the repo file first for local regen).
