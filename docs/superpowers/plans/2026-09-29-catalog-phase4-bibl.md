# Catalog Phase 4 Implementation Plan (EthioStudies bibl)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Serving-path bibliography resolves EthioStudies-first, with `lists/bibliography.xml` only for ids in the baked `bibl-exceptions.xml` allowlist; no live Zotero and no page-load `bibliography.xml` writes.

**Architecture:** Keep `catalog:bibl` return type `element(b:entry)?` (synthesize a `betmas.biblio` entry from EthioStudies HTML). Isolate bibl behind consumer `bibl` / `CATALOG_BACKEND_BIBL` so flipping it does not flip institutions/labels. Track H (exceptions artifact) lands in BetMas; Track W (Web + coverage gate) in BetMasWeb / betmas-e2e.

**Tech Stack:** XQuery (`catalog.xqm`, `zoteroCache.xqm`, `viewItem.xqm`, `list.xqm`, `expand.xqm`), EthioStudies `citations.xml`, catalogs XAR, bash coverage gate, XQSuite / bats, Cypress HP4.

**Spec:** [2026-09-29-catalog-phase4-bibl-design.md](../specs/2026-09-29-catalog-phase4-bibl-design.md)  
**Exceptions PR:** [BetMas#212](https://github.com/BetaMasaheft/BetMas/pull/212)  
**Parent plan:** [.cursor/plans/catalog-from-tei.md](../../../.cursor/plans/catalog-from-tei.md)

## Global Constraints

- Exception allowlist lives only at `/db/apps/catalogs/bibl-exceptions.xml` (BetMas bake); stale/missing → no lists fallback.
- `lists-fallback="true"` required before reading `lists/bibliography.xml`.
- No live Zotero on serving paths (`zc:bibl-page-entry`, `viewItem:bibl` / `viewItem:zot`).
- Do **not** flip `CATALOG_BACKEND_VIEW_ITEM` / `WEB_LIST` / institutions (HP2 still open).
- Default `CATALOG_BACKEND_BIBL=catalog` in Phase 4; `legacy` bibl remains lists-only for oracle A/B.
- Prettier: BetMasWeb → `npm run format:write` before every commit.
- Worktrees under each repo’s `.worktrees/`; create via `git worktree add` from the repo root.
- Index rule: never `@id = ($a, $b)` on bibliography/EthioStudies lookups — single-value equality only.

| Order | Branch | Repo | Depends on |
|-------|--------|------|------------|
| H | `dp-catalog-phase4-bibl-exceptions` | BetMas | — (PR #212 open) |
| W1 | `dp-catalog-phase4-bibl` | BetMasWeb | #212 merged or compose mounts that branch’s catalogs |
| W2 | `dp-catalog-phase4-bibl-coverage` | betmas-e2e | W1 (or parallel after contract stable) |

## File map

| Path | Role |
|------|------|
| `BetMas/db/apps/catalogs/bibl-exceptions.xml` | Allowlist (Track H; already seeded in #212) |
| `BetMas/db/apps/catalogs/manifest.xml` | Pin `bibl-exceptions.xml` |
| `BetMasWeb/modules/catalog.xqm` | EthioStudies-first `catalog:bibl` + exception helper |
| `BetMasWeb/modules/zoteroCache.xqm` | `zc:bibl-page-entry` → `catalog:bibl`; drop live Zotero |
| `BetMasWeb/modules/viewItem.xqm` | Call `catalog:bibl($t)` (bibl consumer); drop `viewItem:zot` fallback |
| `BetMasWeb/restviews/list.xqm` | Call `catalog:bibl($val)` for bibl consumer |
| `BetMasWeb/modules/expand.xqm` | Remove `expand:syncBibliography` from `expand:file` |
| `BetMasWeb/test/xqs/ts-catalog-contract.xqm` | Contract tests for EthioStudies / exception / miss |
| `BetMasWeb/docs/CATALOG.md` | Document `CATALOG_BACKEND_BIBL` |
| `betmas-e2e/scripts/check-bibl-coverage.sh` | Coverage gate |
| `betmas-e2e/.github/workflows/…` | Wire coverage on container/PR |
| `BetMas/.cursor/plans/catalog-from-tei.evidence.md` | Record Phase 4 facts |

---

### Task 1: Land Track H exceptions artifact (BetMas)

**Files:**
- Already on branch `dp-catalog-phase4-bibl-exceptions` / [PR #212](https://github.com/BetaMasaheft/BetMas/pull/212)
- Verify: `db/apps/catalogs/bibl-exceptions.xml`, `manifest.xml`

**Interfaces:**
- Consumes: Phase 1 coverage JSON triage (spec §7)
- Produces: `/db/apps/catalogs/bibl-exceptions.xml` with `@bm`, `@disposition`, `@lists-fallback`, `@issue`

- [ ] **Step 1: Confirm PR contents**

```bash
cd /Users/hal1000/Documents/Jinntec/betamasa/BetMas
git fetch origin dp-catalog-phase4-bibl-exceptions
git log origin/master..origin/dp-catalog-phase4-bibl-exceptions --oneline
rg 'bibl-exceptions' db/apps/catalogs/manifest.xml
xmllint --noout db/apps/catalogs/bibl-exceptions.xml
```

Expected: design doc + exceptions XML + manifest pin; xmllint exit 0.

- [ ] **Step 2: Merge #212 when CI green**

```bash
gh pr checks 212 --repo BetaMasaheft/BetMas
gh pr merge 212 --repo BetaMasaheft/BetMas --merge
```

Expected: merged into `master`; next data-image / local compose bake includes the artifact.

- [ ] **Step 3: Commit note only if follow-up edits**

No further commit if merge-only. If dispositions need editing after bibliography export, amend exceptions on a follow-up PR and shrink the allowlist (do not grow without issue links).

---

### Task 2: BetMasWeb worktree + failing bibl contract tests

**Files:**
- Create: `BetMasWeb/.worktrees/catalog-phase4-bibl/` (worktree)
- Modify: `test/xqs/ts-catalog-contract.xqm` (add failing tests)
- Modify: `docs/CATALOG.md` (document `CATALOG_BACKEND_BIBL` — can land with implementation task)

**Interfaces:**
- Consumes: `catalog:bibl($bm as xs:string, $backend as xs:string) as element(b:entry)?`
- Produces: XQSuite cases that fail on current catalog-backend implementation

- [ ] **Step 1: Create worktree from origin/main**

```bash
cd /Users/hal1000/Documents/Jinntec/betamasa/BetMasWeb
git fetch origin main
git worktree add -b dp-catalog-phase4-bibl .worktrees/catalog-phase4-bibl origin/main
cd .worktrees/catalog-phase4-bibl
```

- [ ] **Step 2: Add failing contract tests**

Append to `test/xqs/ts-catalog-contract.xqm` (keep existing IHABook557 tests):

```xquery
declare
	%test:args("catalog") %test:assertTrue
function tscatalog:bibl-catalog-prefers-ethiostudies($backend as xs:string) as xs:boolean {
	(: Known tag present in EthioStudies citations.xml on release-expanded. :)
	let $e := catalog:bibl("bm:IHABook557", $backend)
	return exists($e/self::b:entry) and exists($e/b:reference//*:div[@class = "csl-entry"])
};

declare
	%test:args("catalog") %test:assertTrue
function tscatalog:bibl-catalog-miss-without-exception-is-empty($backend as xs:string) as xs:boolean {
	empty(catalog:bibl("bm:definitely-not-a-real-tag-xyz", $backend))
};

declare
	%test:args("legacy") %test:assertTrue
function tscatalog:bibl-legacy-still-lists($backend as xs:string) as xs:boolean {
	exists(catalog:bibl("bm:IHABook557", $backend)[self::b:entry])
};
```

- [ ] **Step 3: Run contract suite; expect new catalog cases to fail or expose lists-only path**

```bash
# From BetMasWeb worktree against local compose (8081), same runner the repo already uses for XQSuite — e.g.:
npm test -- --grep catalog-contract
# or the project’s documented xqsuite / ant / bats invocation from README / package.json
```

Expected: `bibl-catalog-prefers-ethiostudies` fails or still passes only because lists also has IHABook557 — add a probe that **distinguishes** sources if needed by asserting the catalog path does **not** require `doc("/db/apps/lists/bibliography.xml")` (implementation will switch source). If IHABook557 cannot distinguish, add a temporary unit that mocks via documenting the intended code path in the next task’s review.

Minimum bar before Task 3: `bibl-catalog-miss-without-exception-is-empty` must fail today if catalog backend still scans lists for unknown ids that happen to be absent — it should already be empty; keep it as a regression lock.

- [ ] **Step 4: Commit tests**

```bash
git add test/xqs/ts-catalog-contract.xqm
git commit -m "$(cat <<'EOF'
test(catalog): Phase 4 bibl EthioStudies contract cases

EOF
)"
```

---

### Task 3: Implement EthioStudies-first `catalog:bibl`

**Files:**
- Modify: `modules/catalog.xqm` (`catalog:bibl` and private helpers)
- Modify: `docs/CATALOG.md`

**Interfaces:**
- Consumes: EthioStudies `citations.xml` `@tag`; `catalog:artifact("bibl-exceptions.xml")`; `$catalog:bibliography`
- Produces:
  - `catalog:bibl-normalize($bm as xs:string) as xs:string`
  - `catalog:bibl-exception($id as xs:string) as element()?` (entry with `@lists-fallback`)
  - `catalog:bibl-from-ethio($id as xs:string) as element(b:entry)?`
  - `catalog:bibl-from-lists($id as xs:string) as element(b:entry)?`
  - `catalog:bibl($bm, $backend)` — legacy → lists only; catalog → Ethio → allowlisted lists → empty

- [ ] **Step 1: Write helpers + new `catalog:bibl` body**

Replace the catalog-backend branch of `catalog:bibl` in `modules/catalog.xqm` with (exact algorithm):

```xquery
declare %private function catalog:bibl-normalize($bm as xs:string) as xs:string {
	if (starts-with($bm, "bm_")) then
		"bm:" || substring-after($bm, "bm_")
	else if (starts-with($bm, "bm:")) then
		$bm
	else
		"bm:" || $bm
};

declare %private function catalog:bibl-from-lists($id as xs:string) as element(b:entry)? {
	let $exact := ($catalog:bibliography//b:entry[@id = $id])[1]
	return if ($exact) then
		$exact
	else
		($catalog:bibliography//b:entry[@id = replace($id, ":", "_")])[1]
};

declare %private function catalog:bibl-from-ethio($id as xs:string) as element(b:entry)? {
	try {
		let $cit := (doc("/db/apps/EthioStudies/citations.xml")//*[@tag = $id])[1]
		let $div := ($cit//*:div[@class = "csl-entry"])[1]
		return if (empty($div)) then
			()
		else
			<entry xmlns="betmas.biblio" id="{ $id }">
				<citation>{ normalize-space(string-join($div//text(), "")) }</citation>
				<reference>{ $div }</reference>
			</entry>
	} catch * {
		()
	}
};

declare %private function catalog:bibl-exception($id as xs:string) as element()? {
	let $doc := catalog:artifact("bibl-exceptions.xml")
	return if (empty($doc)) then
		()
	else
		($doc//*:entry[@bm = $id])[1]
};

declare function catalog:bibl($bm as xs:string, $backend as xs:string) as element(b:entry)? {
	let $id := catalog:bibl-normalize($bm)
	return if ($backend != "catalog") then
		catalog:bibl-from-lists($id)
	else
		let $ethio := catalog:bibl-from-ethio($id)
		return if (exists($ethio)) then
			$ethio
		else
			let $ex := catalog:bibl-exception($id)
			return if (exists($ex) and $ex/@lists-fallback = "true") then
				catalog:bibl-from-lists($id)
			else
				()
};
```

Keep one-arg `catalog:bibl($bm)` → `catalog:bibl($bm, catalog:backend("bibl"))`.

- [ ] **Step 2: Document consumer in `docs/CATALOG.md`**

Add under current consumers:

```markdown
- bibliography resolution: `CATALOG_BACKEND_BIBL` (Phase 4; default flip to `catalog`)
```

Note: `viewItem` / `list` bibl call sites must use the `bibl` consumer (Task 4), not `view-item` / `web-list`.

- [ ] **Step 3: Re-run contract tests**

```bash
npm test -- --grep catalog-contract   # or project equivalent
```

Expected: new catalog cases PASS; legacy cases PASS.

- [ ] **Step 4: Format + commit**

```bash
npm run format:write
git add modules/catalog.xqm docs/CATALOG.md
git commit -m "$(cat <<'EOF'
feat(catalog): EthioStudies-first bibl with exception lists fallback

EOF
)"
```

---

### Task 4: Wire call sites + remove serving Zotero / syncBibliography

**Files:**
- Modify: `modules/viewItem.xqm` (bibl calls + remove zot fallback)
- Modify: `restviews/list.xqm` (bibl calls)
- Modify: `modules/zoteroCache.xqm` (`zc:bibl-page-entry`)
- Modify: `modules/expand.xqm` (drop sync from `expand:file`)
- Modify: deployment / `services.xml` env example so `CATALOG_BACKEND_BIBL=catalog` (if an env template exists; else document in CATALOG.md that missing defaults to legacy until set — **set default via config:service-url second arg change only if project already defaults other backends; prefer explicit env in compose/CI**)

**Interfaces:**
- Consumes: `catalog:bibl($id)` / `catalog:backend("bibl")`
- Produces: serving HTML without live Zotero; expand no longer mutates `bibliography.xml`

- [ ] **Step 1: Switch viewItem bibl resolution**

In `modules/viewItem.xqm`:

1. Add `declare variable $viewItem:bibl-backend := catalog:backend("bibl");`
2. Replace every `catalog:bibl($…, $viewItem:catalog-backend)` used for bibliography with `catalog:bibl($…, $viewItem:bibl-backend)`.
3. Change `viewItem:bibl` miss path from `viewItem:zot($t)` to empty / bare tag text:

```xquery
let $bib := catalog:bibl($t, $viewItem:bibl-backend)/b:reference/*:div/node()
return if (count($bib) ge 1) then
	$bib
else
	$t
```

Do **not** call `zc:full-url-doi` / live HTTP from this serving function.

- [ ] **Step 2: Switch list.xqm**

Replace `catalog:bibl($val, $list:catalog-backend)` with `catalog:bibl($val, catalog:backend("bibl"))` (or a `$list:bibl-backend` variable).

- [ ] **Step 3: Rewrite `zc:bibl-page-entry`**

```xquery
declare function zc:bibl-page-entry($tag as xs:string) as node()* {
	let $t := zc:normalize-tag($tag)
	let $entry := catalog:bibl($t)  (: uses CATALOG_BACKEND_BIBL :)
	return $entry/b:reference/*:div/node()
};
```

Add `import module namespace catalog = …` if missing. Remove lists doc() and `zc:live-bib` from this function.

- [ ] **Step 4: Stop bibliography writes from `expand:file`**

In `modules/expand.xqm` `expand:file`, remove:

```xquery
let $syncBib := expand:syncBibliography($expanded)
```

Leave `expand:syncBibliography` defined but unused (or delete in the same commit if no other callers — `rg syncBibliography` must be empty outside its definition). Update the function comment on `expand:file` accordingly.

- [ ] **Step 5: Ensure CI/compose sets `CATALOG_BACKEND_BIBL=catalog`**

```bash
rg -n 'CATALOG_BACKEND' docker-compose.yml .github/ ../BetMas/docker-compose.yml || true
```

Add `CATALOG_BACKEND_BIBL: catalog` beside other service env vars on the betmas service (BetMas compose and e2e CI override if present).

- [ ] **Step 6: no-writes check still green**

```bash
./scripts/check-no-serving-writes.sh
```

Expected: exit 0 (`generateFormattedBibliography.xqm` / `expand.xqm` remain allow-listed; serving modules must not gain new `xmldb:store` on bibliography).

- [ ] **Step 7: Format + commit**

```bash
npm run format:write
git add modules/viewItem.xqm restviews/list.xqm modules/zoteroCache.xqm modules/expand.xqm docs/CATALOG.md
# plus compose/env files touched
git commit -m "$(cat <<'EOF'
feat(bibl): wire CATALOG_BACKEND_BIBL; drop serving Zotero and syncBibliography

EOF
)"
```

---

### Task 5: Coverage gate (betmas-e2e)

**Files:**
- Create: `betmas-e2e/scripts/check-bibl-coverage.sh`
- Create: `betmas-e2e/scripts/fixtures/mini-bibl-coverage/` (tiny EthioStudies tags file + exceptions + ptr list) for offline unit run
- Modify: `.github/workflows/test-container.yml` (or a dedicated workflow) to run the gate against the compose stack after provision

**Interfaces:**
- Consumes: distinct `bm:` from expanded (REST/xq or precomputed list); EthioStudies tags; `/db/apps/catalogs/bibl-exceptions.xml` `@bm`
- Produces: exit 0 iff every ptr ∈ tags ∪ exceptions; prints misses on stderr

- [ ] **Step 1: Worktree / branch**

```bash
cd /Users/hal1000/Documents/Jinntec/betamasa/betmas-e2e
git fetch origin main
git worktree add -b dp-catalog-phase4-bibl-coverage .worktrees/catalog-phase4-bibl-coverage origin/main
cd .worktrees/catalog-phase4-bibl-coverage
```

- [ ] **Step 2: Write the gate script**

`scripts/check-bibl-coverage.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
# Usage:
#   EXIST_REST=http://localhost:8081/exist/rest/db ./scripts/check-bibl-coverage.sh
# Queries eXist for distinct expanded bm: ptrs, EthioStudies @tag values, and
# exception @bm; fails if any ptr is in neither set.

EXIST_REST="${EXIST_REST:-http://localhost:8081/exist/rest/db}"
AUTH="${EXIST_AUTH:-admin:}"

query() {
  curl -sf -u "$AUTH" -G "$EXIST_REST" \
    --data-urlencode "_query=$1" \
    --data-urlencode "_wrap=no"
}

mapfile -t ptrs < <(query 'string-join(distinct-values(collection("/db/apps/expanded")//@target[starts-with(., "bm:")]), "&#10;")')
mapfile -t tags < <(query 'string-join(distinct-values(doc("/db/apps/EthioStudies/citations.xml")//@tag), "&#10;")')
mapfile -t excs < <(query 'string-join(doc("/db/apps/catalogs/bibl-exceptions.xml")//*:entry/@bm, "&#10;")')

declare -A ok=()
for t in "${tags[@]}"; do [[ -n "$t" ]] && ok["$t"]=1; done
for e in "${excs[@]}"; do [[ -n "$e" ]] && ok["$e"]=1; done

miss=0
for p in "${ptrs[@]}"; do
  [[ -z "$p" ]] && continue
  if [[ -z "${ok[$p]+x}" ]]; then
    printf 'uncovered bm: pointer: %s\n' "$p" >&2
    miss=1
  fi
done
exit "$miss"
```

Make executable: `chmod +x scripts/check-bibl-coverage.sh`.

- [ ] **Step 3: Local run against compose (after catalogs include #212)**

```bash
EXIST_REST=http://localhost:8081/exist/rest/db ./scripts/check-bibl-coverage.sh
echo exit:$?
```

Expected: exit 0 once exceptions artifact is present; exit 1 with `bm:bm:bausi2016colof` listed if exceptions missing.

- [ ] **Step 4: Wire into container workflow**

Add a step after “Provision test users” in `.github/workflows/test-container.yml`:

```yaml
      - name: Bibliography coverage gate
        run: EXIST_REST=http://localhost:8081/exist/rest/db ./scripts/check-bibl-coverage.sh
```

- [ ] **Step 5: Commit**

```bash
git add scripts/check-bibl-coverage.sh .github/workflows/test-container.yml
git commit -m "$(cat <<'EOF'
ci(bibl): fail if expanded bm: ptrs miss EthioStudies and exceptions

EOF
)"
```

---

### Task 6: Verify HP4 + oracle bibl + open Web PR

**Files:**
- Touch as needed: `BetMas/.cursor/plans/catalog-from-tei.evidence.md` (via BetMas checkout)
- Open BetMasWeb PR for `dp-catalog-phase4-bibl`

**Interfaces:**
- Consumes: green contract tests, coverage gate, local Cypress HP4 probe
- Produces: draft PR + evidence bullets

- [ ] **Step 1: HP4 smoke against local stack**

```bash
cd /Users/hal1000/Documents/Jinntec/betamasa/betmas-e2e/.worktrees/catalog-phase1
export CYPRESS_PASSWORD_CATALOGUER=…  # if needed
npx cypress run --browser firefox --config baseUrl=http://localhost:8080/ \
  --spec cypress/e2e/01-entities/bibliography.cy.js
# and/or
npm run bench:catalog   # confirm catalog-hp4-bibliography p95 ≤ baseline (~2ms warm in Phase 1)
```

Expected: bibliography specs pass; HP4 not regress beyond Phase 1 budget in `cypress/fixtures/perf-budgets.json`.

- [ ] **Step 2: Oracle bibl (if compose oracle job available)**

```bash
cd /Users/hal1000/Documents/Jinntec/betamasa/BetMasWeb/.worktrees/catalog-phase4-bibl
# Follow test/CATALOG_ORACLE.md — bibl section 0 unreviewed
CATALOG_BACKEND_A=legacy CATALOG_BACKEND_B=catalog ./scripts/run-catalog-oracle.sh
```

Expected: bibl mismatches empty or only reviewed exception-driven differences documented in `test/catalog-reviewed-mismatches.xml`.

- [ ] **Step 3: Push Web PR**

```bash
git push -u origin HEAD
gh pr create --title "feat(catalog): Phase 4 EthioStudies-first bibl" --body "$(cat <<'EOF'
## Summary
- EthioStudies-first \`catalog:bibl\` with catalogs \`bibl-exceptions.xml\` lists fallback
- Call sites use \`CATALOG_BACKEND_BIBL\`; no serving Zotero; no expand:syncBibliography on expand:file
- Depends on BetMas#212 (exceptions artifact)

## Test plan
- [ ] XQSuite catalog contract
- [ ] check-bibl-coverage.sh on compose
- [ ] bibliography.cy.js / HP4 budget
- [ ] oracle bibl 0 unreviewed
EOF
)"
```

- [ ] **Step 4: Evidence + handoff**

Append to `catalog-from-tei.evidence.md`: Phase 4 algorithm, exception count, coverage gate location, PR links. Update `HANDOFF-phase3.md` Phase 4 section with PR numbers.

- [ ] **Step 5: Commit evidence on BetMas if edited**

```bash
git add .cursor/plans/catalog-from-tei.evidence.md   # if not gitignored — else keep local / use force-add per repo norms
git commit -m "docs(evidence): Phase 4 bibl switch facts"
```

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| `bibl-exceptions.xml` + manifest | Task 1 (#212) |
| EthioStudies → allowlisted lists → empty | Task 3 |
| `viewItem` / `list` / `zc:bibl-page-entry` via `catalog:bibl` | Task 4 |
| No live Zotero on serving path | Task 4 |
| `expand:syncBibliography` off serving/expand:file | Task 4 |
| Coverage gate EthioStudies ∪ exceptions | Task 5 |
| HP4 + oracle bibl | Task 6 |
| Don’t flip other backends / HP2 | Global constraints + Task 4 consumer split |

## Placeholder scan

No TBD/TODO steps; scripts and XQuery included inline.

## Type consistency

- `catalog:bibl` remains `element(b:entry)?` with `b:reference` / `b:citation`.
- Exception nodes are `*:entry[@bm][@lists-fallback]`.
- Consumer name string is always `"bibl"` → env `CATALOG_BACKEND_BIBL`.
