#!/usr/bin/env bats

# Boot-with-userdata flow: the stack is booted with a users volume that
# already holds account files, and the accounts must come up restored by
# BetMasInitInstance's finish.xq - no manual seeding, no env flag.
#
# Fixtures (test/fixtures/users/*.xml) are real eXist account documents, i.e.
# exactly what userAccountSync mirrors into the volume, with real password
# hashes (RIPEMD160, so name-independent):
#   editor:editor         group Editors
#   everything:everything every group the codebase uses
# Groups: Cataloguers (chgrp in BetMasService and finish.xq), Editors (edit
# permissions), dba (admin). Add a new group to everything.xml and to
# ALL_GROUPS below when the codebase starts using one.
#
# The test places the fixtures into the (named) users volume via
# `docker compose cp` on the not-yet-started container, then boots betmas and
# verifies over XQuery with xst.
#
# Run: npm run test:seed-users
# Requires: dev overlay for host :8082 (COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml).
# NB: overwrites editor.xml/everything.xml in the users volume.

ALL_GROUPS="Cataloguers Editors dba"

setup_file() {
	cd "$BATS_TEST_DIRNAME/.."
	export EXISTDB_SERVER="${EXISTDB_SERVER:-http://localhost:8082/}"
	export EXISTDB_USER=admin
	export EXISTDB_PASS=''

	docker compose rm -sf betmas >/dev/null 2>&1
	docker compose create betmas >/dev/null
	docker compose cp test/fixtures/users/. betmas:/betmas-users-data/
	# Local convenience only (CI builds the image from this checkout instead):
	# overlay a freshly zipped BetMasInitInstance onto the stock image.
	if [ -n "${BETMAS_INIT_XAR:-}" ]; then
		docker compose cp "$BETMAS_INIT_XAR" betmas:/exist/autodeploy/BetMasInitInstance.xar
	fi
	docker compose up -d betmas >/dev/null

	# Healthy != users restored: finish.xq schedules the restore a while after
	# startup (see its comment), so wait for the job's own completion marker.
	local tries=0
	until docker compose logs betmas 2>&1 | grep -q 'restore-users job finished'; do
		tries=$((tries + 1))
		[ "$tries" -lt 150 ] || { echo "restore-users job never finished" >&2; return 1; }
		sleep 2
	done
}

xq() {
	xst run "$1" 2>/dev/null | tail -n 1
}

# true only when the password is right.
password_ok() {
	xq "xmldb:authenticate('/db', '$1', '$2')"
}

groups_of() {
	xq "string-join(sort(sm:get-user-groups('$1')), ' ')"
}

@test "editor exists and authenticates with password 'editor'" {
	[ "$(xq "sm:user-exists('editor')")" = "true" ]
	[ "$(password_ok editor editor)" = "true" ]
}

@test "editor rejects a wrong password" {
	[ "$(password_ok editor not-the-password)" = "false" ]
}

@test "editor is in the Editors group" {
	[[ " $(groups_of editor) " == *" Editors "* ]]
}

@test "everything exists and authenticates with password 'everything'" {
	[ "$(xq "sm:user-exists('everything')")" = "true" ]
	[ "$(password_ok everything everything)" = "true" ]
}

@test "everything rejects a wrong password" {
	[ "$(password_ok everything not-the-password)" = "false" ]
}

@test "everything is in every group used by the codebase" {
	local actual g
	actual=" $(groups_of everything) "
	for g in $ALL_GROUPS; do
		[[ "$actual" == *" $g "* ]] || { echo "everything is missing group $g (has:$actual)" >&2; return 1; }
	done
}

# Restore failures are caught and only logged by finish.xq (so one bad account
# can't abort the boot), which means the checks above can pass while a restore
# step threw halfway - e.g. skipping later group/metadata steps. Fail on the log.
@test "boot logs show no failed account restore" {
	run bash -c "docker compose logs betmas 2>&1 | grep -E 'BetMasInitInstance: could not (restore|create)'"
	if [ "$status" -eq 0 ]; then
		echo "$output" >&2
		return 1
	fi
}

# The hash must be persisted, not just held in memory: the original startup
# restore left the live server accepting the password while the stored hash was
# still the placeholder, so logins broke at the next restart. Runs last.
@test "passwords and groups survive a container restart" {
	docker compose restart betmas >/dev/null
	local tries=0
	until [ "$(xq "sm:user-exists('editor')")" = "true" ]; do
		tries=$((tries + 1))
		[ "$tries" -lt 100 ] || return 1
		sleep 3
	done
	[ "$(password_ok editor editor)" = "true" ]
	[ "$(password_ok everything everything)" = "true" ]
	local actual g
	actual=" $(groups_of everything) "
	for g in $ALL_GROUPS; do
		[[ "$actual" == *" $g "* ]]
	done
}
