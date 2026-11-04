#!/usr/bin/env bats

# docker/nginx.conf became a full main config in #231 (worker_processes /
# events / http wrapper). Compose must mount it at /etc/nginx/nginx.conf,
# not conf.d/default.conf. Run: bats test/nginx-config.bats
# Needs only docker and network access to pull nginx:1.27-alpine.

CONF="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/docker/nginx.conf"
IMAGE=nginx:1.27-alpine

@test "docker/nginx.conf is a valid main nginx config" {
	# proxy_pass http://betmas:… is resolved at -t time; stub the compose
	# service name so a standalone container can validate the file.
	run docker run --rm \
		--add-host betmas:127.0.0.1 \
		-v "$CONF:/etc/nginx/nginx.conf:ro" \
		"$IMAGE" nginx -t
	[ "$status" -eq 0 ]
}

@test "docker/nginx.conf is not a valid conf.d fragment" {
	# Guards against reverting the compose mount to conf.d/default.conf.
	run docker run --rm -v "$CONF:/etc/nginx/conf.d/default.conf:ro" "$IMAGE" nginx -t
	[ "$status" -ne 0 ]
	[[ "$output" == *"worker_processes"*"not allowed here"* ]] ||
		[[ "$output" == *"is not allowed here"* ]]
}
