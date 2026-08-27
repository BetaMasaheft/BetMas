#!/usr/bin/env bats

# App-image contracts for expand consumers (expanded re-expand CI, etc.).
# Asserted against the published betamasaheft image here — not re-checked in
# every consumer workflow.
#
# Run: npm run test:app-image
# Requires: `docker compose up -d betmas` healthy, host port 8082 (see
# docker-compose.yml).

EXIST_REST="${EXIST_REST:-http://localhost:8082/exist/rest/db/}"

query() {
	curl -fsS -u admin: --get "$EXIST_REST" \
		--data-urlencode "_query=$1" \
		--data-urlencode '_wrap=no'
}

@test "EthioStudies biblStruct cache is non-empty" {
	count=$(query 'count(collection("/db/apps/EthioStudies")//*[local-name()="biblStruct"])')
	[[ "$count" =~ ^[1-9][0-9]*$ ]]
}

@test "BetMasWeb ships batchExpand.xqm" {
	run query 'doc-available("/db/apps/BetMasWeb/modules/batchExpand.xqm")'
	[ "$output" = "true" ]
}

@test "BetMasWeb ships makeExpand.xql" {
	run query 'doc-available("/db/apps/BetMasWeb/modules/makeExpand.xql")'
	[ "$output" = "true" ]
}
