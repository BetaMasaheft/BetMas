Replace-only catalog artifacts baked into `catalogs.xar` for `/db/apps/catalogs`. The data image build copies `retired-ids.xml` from `expanded/config/retired-ids.xml` at `EXPANDED_REF` and sets that artifact's manifest `@expanded-sha`, plus the `bibl-exceptions.xml` pin, to the same value written into `expanded-sha.txt`. `place-labels.xml` keeps the pin from the last scan.

`bibl-exceptions.xml` is the Phase 4 allowlist: serving-path bibl may fall back to `lists/bibliography.xml` only for entries with `lists-fallback="true"`. Re-triaged 2026-10-13 against bibliography `83f1118`: leftovers are four pending exports, two TEI retags, and `bm:Turaev1909ZaraBuruk` ([bibliography#27](https://github.com/BetaMasaheft/bibliography/issues/27) / [#28](https://github.com/BetaMasaheft/bibliography/issues/28)).

The committed `expanded-sha.txt` is a dev/default seed. The data image build overwrites it from the `EXPANDED_REF` build arg immediately before packaging `catalogs.xar`. **CI must pass a resolved expanded commit SHA** as `EXPANDED_REF` (see `build-data.yml`); the stale gate compares manifest `@expanded-sha` to this file. Local ad-hoc builds may pass `EXPANDED_REF=main`, which pins the literal string `main` and is not meaningful for freshness checks.

## App-image generated artifacts

`institutions.xml` and `labels.xml` are **not** in this directory and not in
`catalogs.xar`. `docker/app.Dockerfile` runs `scripts/catalogs/generate_artifacts.xq`
after the app boot; it writes both into `/db/apps/catalogs/` through BetMasWeb's
`catalog.xqm` (`catalog:institutions("catalog")`, `catalog:full-title`) and adds
manifest rows pinned to the image's `expanded-sha.txt`. They are therefore exact
for their image. Regenerate locally with
`xst run --file scripts/catalogs/generate_artifacts.xq` against a running stack.
