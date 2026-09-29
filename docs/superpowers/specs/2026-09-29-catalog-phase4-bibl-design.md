# Catalog from TEI — Phase 4 design (EthioStudies bibl)

Date: 2026-09-29  
Parent: [catalog-from-tei.md](../../../.cursor/plans/catalog-from-tei.md) · Evidence: [catalog-from-tei.evidence.md](../../../.cursor/plans/catalog-from-tei.evidence.md)  
Handoff: [HANDOFF-phase3.md](../../.superpowers/sdd/HANDOFF-phase3.md)

Approved in session: prepare **B** (spec + bibliography hygiene in parallel); coverage **B** (reviewed exception allowlist); runtime **B** (lists fallback only for allowlisted ids); allowlist home **A** (`/db/apps/catalogs/` artifact); delivery **1** (two-track).

## 1. Goal and gates

Serving-path bibliography resolution reads **EthioStudies first**. `lists/bibliography.xml` is used only for ids listed in a baked exception artifact. Live Zotero is not part of the serving path. `expand:syncBibliography` / page-load writers that mutate `bibliography.xml` leave the serving path.

### Phase 4 gate

| Check | Rule |
|-------|------|
| HP4 | p95 ≤ Phase 1 baseline (warm bibl page) |
| Coverage | every distinct expanded `bm:` ∈ EthioStudies tags ∪ `bibl-exceptions.xml` |
| Oracle | bibl mismatches 0 unreviewed |
| Call sites | `viewItem`, `list.xqm` bibl page, `zc:bibl-page-entry` resolve only via `catalog:bibl` (no direct lists/Zotero on those paths) |

Success criteria S2 from the parent plan: 100% of `bm:` ptrs resolve from EthioStudies **or** the exception list.

## 2. Two tracks

| Track | Repo | Work | Blocks merge of |
|-------|------|------|-----------------|
| **H** (hygiene) | `bibliography` + BetMas catalogs | Close #27/#28 where possible; seed/maintain `bibl-exceptions.xml` for leftovers | Web flip can land with non-empty exceptions |
| **W** (Web) | BetMasWeb (+ e2e gate) | EthioStudies-first `catalog:bibl`; wire call sites; stop serving-path sync; CI coverage gate | Phase 4 complete |

Phase 3 leftovers (e2e #113/#114, data image, Api #57) stay on the prior runway; they are not prerequisites to **start** Track H or draft Track W, but the Web flip should ship against an image that includes the exceptions artifact.

## 3. Artifact — `bibl-exceptions.xml`

### Location

`BetMas/db/apps/catalogs/bibl-exceptions.xml` → baked into `/db/apps/catalogs/` (same package as `retired-ids.xml` / `place-labels.xml`).

### Shape

```xml
<bibl-exceptions version="1"
  xmlns="https://betamasaheft.eu/catalogs">
  <entry bm="bm:Kamil1957Sinai"
    disposition="pending-export"
    lists-fallback="true"
    issue="https://github.com/BetaMasaheft/bibliography/issues/28">
    <reason>Present in lists/bibliography.xml; absent from EthioStudies citations export.</reason>
  </entry>
  <entry bm="bm:bm:bausi2016colof"
    disposition="malformed-source"
    lists-fallback="false"
    issue="https://github.com/BetaMasaheft/bibliography/issues/28">
    <reason>Double bm: prefix in expanded TEI; fix source pointer, not Zotero.</reason>
  </entry>
</bibl-exceptions>
```

**Dispositions:** `pending-export` | `malformed-source` | `wont-fix`  
**`lists-fallback`:** when `true`, serving path may read `lists/bibliography.xml` for that id only.

### Manifest

Add to `manifest.xml`:

```xml
<artifact name="bibl-exceptions.xml" required="true" expanded-sha="…"/>
```

Pin policy matches other catalogs artifacts (stale → `catalog:artifact` empty → no allowlist → EthioStudies-only with no lists escape). Prefer keeping exceptions `required="true"` so a missing file fails closed rather than silently dropping fallbacks.

## 4. Runtime — `catalog:bibl`

Today (Phase 2/3): catalog backend prefers artifact `bibliography.xml` then `$catalog:bibliography` (lists). That is **not** EthioStudies.

**Phase 4 algorithm** (backend `catalog` and the default once flipped; legacy backend unchanged until Phase 5 canary if still needed):

1. Normalize tag (`bm:` / `bm_`).
2. Lookup EthioStudies (`citations.xml` / existing `zc:` helpers) → return if hit.
3. Else if id ∈ `catalog:artifact("bibl-exceptions.xml")` with `lists-fallback="true"` → lookup `lists/bibliography.xml` → return if hit.
4. Else → empty / bare id (no live Zotero on serving path).

`zc:bibl-page-entry` becomes a thin wrapper over `catalog:bibl` (or shared private helper) so the bibliography HTML page does not reimplement the chain or call Zotero.

## 5. Call sites and writers

| Site | Change |
|------|--------|
| `viewItem.xqm` | Drop direct `$viewItem:bibliography`; use `catalog:bibl` |
| `list.xqm` | Drop direct `$list:bibliography` for resolution; use `catalog:bibl` |
| `zc:bibl-page-entry` | EthioStudies → allowlisted lists only; **remove** live Zotero fallback on this path |
| `expand:syncBibliography` | Not invoked from serving/page-load expand; keep only for explicit admin/CI expand if still required for shard builds, or delete once unused |
| `generateFormattedBibliography.xqm` | Same: off serving path |

No-writes gate: serving modules must not `xmldb:store` / update `bibliography.xml`.

## 6. CI / coverage gate

- Input: distinct `bm:` from expanded (same method as Phase 1 coverage JSON).
- Pass if each id ∈ EthioStudies tag set ∪ exception `@bm`.
- Fail on any new miss not on the allowlist.
- Shrinking the allowlist (export landed) is encouraged; adding entries requires issue link + disposition in the PR.

Host: prefer `betmas-e2e` coverage job and/or BetMasWeb bats against compose; exact wiring is an implementation-plan detail.

## 7. Track H — initial triage (2026-09-24 coverage)

Source: `betmas-e2e` `benchmarks/catalog-phase1-bibliography-coverage.json` (3742 ptrs; 23 missing; 12 lists-only). Issues: [bibliography#27](https://github.com/BetaMasaheft/bibliography/issues/27), [#28](https://github.com/BetaMasaheft/bibliography/issues/28).

| Bucket | Ids | Disposition seed |
|--------|-----|------------------|
| Missing ∩ lists-only (11) | ChernetsovBafana, Bollini2023Fondi, Erho2025Homiliary, Habtamu2021Fragility, Kamil1957Sinai, Ludolf1661lexicon, MercierArt2001, Pedersen2007Masasa, Perruchon1894EskEnder, Spencer1974Luke, Tasfa1954DersanaM | `pending-export`, `lists-fallback=true` |
| Lists-only not in missing (1) | Mazzei2017RM | `pending-export`, `lists-fallback=true` (lists hygiene; not an expanded ptr gap) |
| Missing, not in lists (11) | ComboniHanriot, ConTuristica1935Guida, Conti1919Harari, Derat2006Royal, ElleroBlogUfficiale, EzraGebrem2014Roden, Guidi1935Vocabolario2nd, Martinez2005EAeEllero, Rubenson2003AliAlula, Tedros2005EAEFeqraMG, Turaev1909ZaraBuruk | `pending-export`, `lists-fallback=false` until export or TEI fix |
| Malformed (1) | `bm:bm:bausi2016colof` | `malformed-source`, `lists-fallback=false` |

Hygiene work: add/fix Zotero records + re-export EthioStudies; fix malformed TEI pointer in expanded; remove exception rows as exports land.

## 8. Out of scope

- Phase 5 canary order / gutting mutable lists.
- Changing EthioStudies export mechanics (only its input data / re-export).
- HP2 institution oracle triage.
- Flipping other `CATALOG_BACKEND_*` flags.

## 9. Self-review

- No placeholders for decisions already taken (A/B choices recorded above).
- Exceptions artifact path and runtime chain are concrete.
- Track H can start before Track W merge; Track W must not assume empty exceptions.
- Stale/missing exceptions file fails closed (no silent universal lists fallback).
