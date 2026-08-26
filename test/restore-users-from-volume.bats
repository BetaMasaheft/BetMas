#!/usr/bin/env bats

# Integration test for the account-persistence-across-redeploy feature:
#   1. BetMasService's modules/userAccountTrigger.xqm (delegating to
#      userAccountSync.xqm) mirrors every account document - verbatim,
#      including its real password hash - into the users volume via a
#      trigger on /db/system/security/exist/accounts, registered by
#      BetMasInitInstance's finish.xq.
#   2. That same finish.xq restores those accounts into a fresh container
#      on first boot.
#
# Proves both pieces together via the *real* deploy mechanism, not a
# reimplementation of finish.xq's logic: builds and installs the real
# BetMasService + betmas-init packages, simulates a redeploy by recreating
# the `betmas` compose service (which discards its ephemeral /db - accounts
# included, since nothing mounts /exist/data - while the betmas-users-data
# *volume* survives), then reinstalls both packages again (mirroring how a
# fresh image boot autodeploys everything) and confirms the account that
# existed before recreation is back, with the exact same password hash it
# had before (not a freshly re-hashed one). A final test confirms deleting
# an account also removes its volume copy.
#
# Run: npm run test:restore-users  (or: bats --tap test/restore-users-from-volume.bats)
# Requires: the `betmas` compose service already has betmas-users-data
# mounted and USERS_VOLUME_DIRECTORY set (see docker-compose.yml), and a
# host port exposed for xst (see the TEMP block in docker-compose.yml).

setup_file() {
	cd "$BATS_TEST_DIRNAME/.."
	echo "volumetest_$(date +%s)" >"$BATS_FILE_TMPDIR/testuser"
	echo "TestPw123!" >"$BATS_FILE_TMPDIR/testpw"

	deploy_all
	restart_and_wait_healthy
	create_test_account
}

# --- helpers (available to setup_file and every @test) ---

exist_query() {
	# -O writes the query's actual result to a file, cleanly separated from
	# the client's own startup/shutdown-hook log noise on stdout (which is
	# sometimes glued directly onto the result with no newline). The
	# container has no coreutils (no cat/find/etc.), so read it back via
	# `docker compose cp` instead of `docker compose exec cat`.
	local out_in_container=/tmp/exist_query_out.$$
	local out_local="$BATS_TEST_TMPDIR/exist_query_out.$$"
	docker compose exec -T betmas java org.exist.start.Main client --no-gui -u admin -P "" \
		-x "$1" -O "$out_in_container" >/dev/null 2>&1
	docker compose cp "betmas:$out_in_container" "$out_local" >/dev/null 2>&1 || true
	cat "$out_local" 2>/dev/null || true
	rm -f "$out_local"
}

deploy_all() {
	local svc_dir="db/apps/BetMasService"
	local init_dir="db/apps/BetMasInitInstance"

	( cd "$svc_dir" && ant >/dev/null )
	EXISTDB_SERVER=http://localhost:8082/ EXISTDB_PASS='' \
		xst package install "$svc_dir"/build/*.xar --force

	rm -f "$init_dir/build/betmas-init.xar"
	( cd "$init_dir" && zip -q -r build/betmas-init.xar finish.xq repo.xml expath-pkg.xml tuttle.xml )
	EXISTDB_SERVER=http://localhost:8082/ EXISTDB_PASS='' \
		xst package install "$init_dir/build/betmas-init.xar" --force
}

wait_healthy() {
	until [ "$(docker compose ps -q betmas | xargs docker inspect -f '{{.State.Health.Status}}' 2>/dev/null)" = "healthy" ]; do
		sleep 2
	done
}

# A collection's trigger config, once loaded into a long-running server's
# in-memory collection cache, does not reliably pick up a later
# collection.xconf change without a restart - confirmed empirically. This
# is a dev-hot-patching artifact only: in real deployment the config is
# already on disk (baked into the image) before the server boots for the
# first time, so the accounts collection is never loaded with a stale
# config in the first place. Restarting here keeps the test representative
# rather than flaky.
restart_and_wait_healthy() {
	docker compose restart betmas >/dev/null
	wait_healthy
}

create_test_account() {
	local user pw
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	pw=$(cat "$BATS_FILE_TMPDIR/testpw")
	exist_query "sm:create-account('$user', '$pw', '$user', '$user', 'restore test')" >/dev/null
}

# --- tests (bats runs @test blocks in file order) ---

@test "trigger mirrors a newly created account into the users volume" {
	local user
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	run exist_query "file:exists('/betmas-users-data/$user.xml')"
	[ "$output" = "true" ]
}

@test "mirrored copy carries a real, non-empty password hash" {
	local user hash
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	hash=$(exist_query "parse-xml(file:read('/betmas-users-data/$user.xml'))//*:password/string()")
	[ -n "$hash" ]
	echo "$hash" >"$BATS_FILE_TMPDIR/hash_before"
}

@test "account is gone after a full container recreation (simulated redeploy)" {
	local user
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	docker compose up -d --force-recreate betmas >/dev/null
	wait_healthy
	run exist_query "sm:user-exists('$user')"
	[ "$output" = "false" ]
}

@test "reinstalling packages restores the account with its original password hash" {
	local user hash_before hash_after
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	hash_before=$(cat "$BATS_FILE_TMPDIR/hash_before")

	deploy_all

	run exist_query "sm:user-exists('$user')"
	[ "$output" = "true" ]

	hash_after=$(exist_query "doc('/db/system/security/exist/accounts/$user.xml')//*:password/string()")
	[ "$hash_after" = "$hash_before" ]
}

@test "deleting the account removes its copy from the volume" {
	local user
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	exist_query "sm:remove-account('$user'), if (sm:group-exists('$user')) then sm:remove-group('$user') else ()" >/dev/null
	run exist_query "file:exists('/betmas-users-data/$user.xml')"
	[ "$output" = "false" ]
}
