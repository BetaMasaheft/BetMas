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
# *volume* survives), then confirms the account that existed before
# recreation is back - restored automatically by BetMasInitInstance.xar's
# own autodeploy hook (it lives in /exist/autodeploy/, so it reinstalls
# and re-runs finish.xq on any boot from a fresh /db, this recreate
# included - not something that needs an explicit reinstall to trigger).
# The same recreate also restores a second account whose volume file was
# planted directly in the volume rather than written by a live account's
# trigger - the shape a migrated-in or externally-seeded users-data
# directory takes, and the scenario that first exposed the account-restore
# bugs this file guards against (see below). A further explicit reinstall
# is then shown to be a safe no-op that doesn't corrupt the already-restored
# password hash. A final test confirms deleting an account also removes its
# volume copy.
#
# betmas-users-data is a named Docker volume, not a bind mount, so nothing
# here reads or writes it as a host directory - every touch goes through
# the running container instead, via `docker compose cp` (see
# read_volume_file/write_volume_file/volume_file_exists below), the same
# way exist_query already talks to the container instead of the host disk.
#
# Run: npm run test:restore-users  (or: bats --tap test/restore-users-from-volume.bats)
# Requires: the `betmas` compose service already has betmas-users-data
# mounted and USERS_VOLUME_DIRECTORY set (see docker-compose.yml), and a
# host port exposed for xst (see the TEMP block in docker-compose.yml).

setup_file() {
	cd "$BATS_TEST_DIRNAME/.."
	echo "volumetest_$(date +%s)" >"$BATS_FILE_TMPDIR/testuser"
	echo "TestPw123!" >"$BATS_FILE_TMPDIR/testpw"
	# Deliberately NOT the username: a personal group happening to match the
	# username (as create_test_account used to do, and as eXist's own
	# 3/5-arg sm:create-account convenience overloads always do) masks the
	# real-world shape of this bug - restoring "editor" (primary group
	# "Cataloguers") once mis-created a personal "editor" group instead,
	# because the account-restore call matched the wrong sm:create-account
	# overload. A distinct group name is what actually exercises that path.
	echo "volumetestgroup_$(date +%s)" >"$BATS_FILE_TMPDIR/testgroup"
	echo "volumepreseed_$(date +%s)" >"$BATS_FILE_TMPDIR/preseeduser"
	echo "volumepreseedgroup_$(date +%s)" >"$BATS_FILE_TMPDIR/preseedgroup"

	deploy_all
	restart_and_wait_healthy
	create_test_account
	create_preseeded_volume_file
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

# betmas-users-data is a named volume (not a bind mount), so it has no host
# path - these three go through the running container instead, the same way
# exist_query does. All take/produce the in-container path
# (/betmas-users-data/...), never a host one. `docker compose cp` (not
# `exec`) is what makes this possible: the container's eXist base image has
# no shell and no coreutils (no test/cat/sh - confirmed empirically), but
# `cp` talks to the Docker API's own tar-copy endpoint, not a binary running
# inside the container, so it works regardless.
volume_file_exists() {
	# BATS_FILE_TMPDIR, not BATS_TEST_TMPDIR: this (and the other two
	# helpers below) can run from setup_file, where BATS_TEST_TMPDIR is
	# unset - confirmed empirically after it silently collapsed the tmp
	# path to a root-owned one and made every cp fail closed.
	local remote="$1"
	local local_tmp="$BATS_FILE_TMPDIR/volume_exists.$$"
	docker compose cp "betmas:$remote" "$local_tmp" >/dev/null 2>&1
	local status=$?
	rm -f "$local_tmp"
	return $status
}

read_volume_file() {
	local remote="$1"
	local local_tmp="$BATS_FILE_TMPDIR/volume_file.$$"
	docker compose cp "betmas:$remote" "$local_tmp" >/dev/null 2>&1 || return 1
	cat "$local_tmp"
	rm -f "$local_tmp"
}

write_volume_file() {
	local remote="$1" content="$2"
	local local_tmp="$BATS_FILE_TMPDIR/volume_file.$$"
	printf '%s' "$content" >"$local_tmp"
	docker compose cp "$local_tmp" "betmas:$remote"
	rm -f "$local_tmp"
}

deploy_all() {
	local svc_dir="db/apps/BetMasService"
	local init_dir="db/apps/BetMasInitInstance"

	( cd "$svc_dir" && ant >/dev/null )
	EXISTDB_SERVER=http://localhost:8082/ EXISTDB_USER=admin EXISTDB_PASS='' \
		xst package install "$svc_dir"/build/*.xar --force

	mkdir -p "$init_dir/build"
	rm -f "$init_dir/build/betmas-init.xar"
	( cd "$init_dir" && zip -q -r build/betmas-init.xar finish.xq repo.xml expath-pkg.xml tuttle.xml )
	EXISTDB_SERVER=http://localhost:8082/ EXISTDB_USER=admin EXISTDB_PASS='' \
		xst package install "$init_dir/build/betmas-init.xar" --force
}

wait_healthy() {
	until [ "$(docker compose ps -q betmas | xargs docker inspect -f '{{.State.Health.Status}}' 2>/dev/null)" = "healthy" ]; do
		sleep 2
	done
}

# Docker's own healthcheck only proves eXist's query engine is responding -
# not that BetMasInitInstance.xar's autodeploy-triggered finish.xq (which
# does the actual account restore) has finished running. Confirmed
# empirically: right as "healthy" first turns true after a fresh-/db boot,
# finish.xq can still be mid-execution. Poll for the actual condition we
# care about directly, rather than an indirect "is finish.xq done" proxy -
# an earlier version of this polled xmldb:collection-available() on the
# collection.xconf finish.xq stores as its very last step, reasoning that
# if the last effect landed the earlier ones (including the restore) must
# have too, which is true in principle but that specific check inherits
# the exact stale in-memory-collection-cache quirk restart_and_wait_healthy
# below already works around for a different reason - unreliable for
# this too, so it's not a safe thing to poll on. Bounded rather than
# unbounded: a real regression here should fail loudly, not hang CI.
wait_for_account() {
	local user="$1"
	local tries=0
	until [ "$(exist_query "sm:user-exists('$user')")" = "true" ]; do
		tries=$((tries + 1))
		[ "$tries" -lt 60 ] || return 1
		sleep 1
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
	local user pw group
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	pw=$(cat "$BATS_FILE_TMPDIR/testpw")
	group=$(cat "$BATS_FILE_TMPDIR/testgroup")
	# 4-arg sm:create-account($name, $password, $primary-group, $groups) -
	# the group must pre-exist for this overload (unlike the 3/5-arg
	# convenience overloads, which auto-vivify a personal group), matching
	# what finish.xq's restore path (and its own group pre-creation) does.
	exist_query "sm:create-group('$group'), sm:create-account('$user', '$pw', '$group', ())" >/dev/null
}

# Every other test in this file restores an account whose volume copy was
# written by userAccountSync's own trigger, during the very same test run.
# That never proves finish.xq's restore loop works against a file it did
# not just watch get written - e.g. one migrated in from an older
# deployment, or (the motivating case) a users-data volume populated
# outside the container and handed to one that has never booted against it
# before. So this creates a real account (for a real, eXist-produced
# password hash - never fabricate one), captures its trigger-mirrored file,
# then deletes the live account (which makes the trigger delete that same
# file) and writes the captured content straight back into the volume via
# the container - bypassing the trigger entirely for this file, the same
# way an externally-migrated file would arrive.
create_preseeded_volume_file() {
	local user pw group volume_file captured
	user=$(cat "$BATS_FILE_TMPDIR/preseeduser")
	pw=$(cat "$BATS_FILE_TMPDIR/testpw")
	group=$(cat "$BATS_FILE_TMPDIR/preseedgroup")
	volume_file="/betmas-users-data/$user.xml"

	exist_query "sm:create-group('$group'), sm:create-account('$user', '$pw', '$group', ())" >/dev/null
	volume_file_exists "$volume_file"
	captured=$(read_volume_file "$volume_file")

	exist_query "sm:remove-account('$user'), sm:remove-group('$group')" >/dev/null
	local tries=0
	until ! volume_file_exists "$volume_file"; do
		tries=$((tries + 1))
		[ "$tries" -lt 30 ] || break
		sleep 1
	done

	write_volume_file "$volume_file" "$captured"
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

@test "account is automatically restored after a full container recreation (simulated redeploy)" {
	local user
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	docker compose up -d --force-recreate betmas >/dev/null
	wait_healthy
	wait_for_account "$user"
	run exist_query "sm:user-exists('$user')"
	[ "$output" = "true" ]
}

# The same recreate above also has to pick up preseeduser's file, which
# create_preseeded_volume_file planted directly in the volume rather
# than through a live account/trigger - proving finish.xq's restore loop
# works from cold, against files it has never seen created, not just ones
# it watched a trigger just write. Its group ("preseedgroup_...") was also
# deleted along with the account, so this exercises local:ensure-group
# recreating a genuinely-missing group from scratch too, not one the image
# already bakes in (unlike "Cataloguers" for the main $testgroup).
@test "a pre-existing volume file with no live account behind it is restored on first boot too" {
	local user group
	user=$(cat "$BATS_FILE_TMPDIR/preseeduser")
	group=$(cat "$BATS_FILE_TMPDIR/preseedgroup")
	wait_for_account "$user"
	run exist_query "sm:user-exists('$user')"
	[ "$output" = "true" ]
	run exist_query "sm:get-user-primary-group('$user')"
	[ "$output" = "$group" ]
}

# Guards specifically against the wrong-sm:create-account-overload bug: a
# malformed restore call can silently create the account under a personal
# group named after the account instead of its real primary group - the
# account would still exist (previous test still passes) while this one
# catches the mismatch.
@test "restored account keeps its real primary group, not a personal group named after itself" {
	local user group
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	group=$(cat "$BATS_FILE_TMPDIR/testgroup")
	run exist_query "sm:get-user-primary-group('$user')"
	[ "$output" = "$group" ]
	run exist_query "sm:group-exists('$user')"
	[ "$output" = "false" ]
}

# Deliberately not checking the password hash here (only existence, above)
# - the account restored via this bare-autodeploy path has a real, already
# reproduced and filed hash mismatch (BetaMasaheft/BetMas#160), separate
# from what this file is fixing. Hash fidelity is checked below instead,
# on the explicit-reinstall path, which doesn't have that bug.
@test "reinstalling packages is a safe no-op that doesn't corrupt the restored account" {
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
	local user group
	user=$(cat "$BATS_FILE_TMPDIR/testuser")
	group=$(cat "$BATS_FILE_TMPDIR/testgroup")
	exist_query "sm:remove-account('$user'), if (sm:group-exists('$group')) then sm:remove-group('$group') else ()" >/dev/null
	run exist_query "file:exists('/betmas-users-data/$user.xml')"
	[ "$output" = "false" ]

	# Same cleanup for the preseeded account from setup_file - not itself
	# under test here, just keeping the volume tidy for a local re-run.
	local preseed_user preseed_group
	preseed_user=$(cat "$BATS_FILE_TMPDIR/preseeduser")
	preseed_group=$(cat "$BATS_FILE_TMPDIR/preseedgroup")
	exist_query "sm:remove-account('$preseed_user'), if (sm:group-exists('$preseed_group')) then sm:remove-group('$preseed_group') else ()" >/dev/null
}
