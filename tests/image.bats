#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
setup() {
  JANUS_TEST_IMAGE="${JANUS_TEST_IMAGE:-janus-ci:verify}"
  PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
}

@test "Janus runtime reports the upstream version from Dockerfile" {
  expected=$(sed -n 's/^ARG JANUS_VERSION=\(.*\)$/\1/p' "$PROJECT_ROOT/Dockerfile")
  [ -n "$expected" ]
  run docker run --rm "$JANUS_TEST_IMAGE" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"($expected)"* ]]
}


@test "OCI image version label follows the pinned Janus tag" {
  expected=$(sed -n 's/^ARG JANUS_VERSION=//p' "$PROJECT_ROOT/Dockerfile" | head -1)
  [ -n "$expected" ]
  run docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$JANUS_TEST_IMAGE"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "image runs as the unprivileged janus user and ships no distro Janus binary" {
  run docker image inspect --format '{{.Config.User}}' "$JANUS_TEST_IMAGE"
  [ "$status" -eq 0 ]
  [ "$output" = "janus" ]
  run docker run --rm --entrypoint /bin/sh "$JANUS_TEST_IMAGE" -ec '
    test "$(id -un)" = janus
    test ! -e /usr/bin/janus
    test -x /usr/local/bin/janus
  '
  [ "$status" -eq 0 ]
}

@test "VideoRoom WebSockets and wsevh shared libraries are packaged" {
  run docker run --rm --entrypoint /bin/sh "$JANUS_TEST_IMAGE" -ec '
    for module in \
      /usr/local/lib/janus/plugins/libjanus_videoroom.so \
      /usr/local/lib/janus/transports/libjanus_websockets.so \
      /usr/local/lib/janus/events/libjanus_wsevh.so; do
      test -e "$module"
    done
    ldd /usr/local/bin/janus > /tmp/ldd.txt
    ! grep -E "not found|Error loading" /tmp/ldd.txt
  '
  [ "$status" -eq 0 ]
}

@test "Janus initializes VideoRoom WebSocket transport and event handler" {
  run docker run --rm --entrypoint /bin/sh "$JANUS_TEST_IMAGE" -ec '
    mkdir -p /tmp/janus-ci
    for source in /usr/local/etc/janus/*.jcfg /usr/local/etc/janus/*.jcfg.sample; do
      test -f "$source" || continue
      filename=$(basename "$source" .sample)
      test -f "/tmp/janus-ci/$filename" || cp "$source" "/tmp/janus-ci/$filename"
    done
    test -f /tmp/janus-ci/janus.eventhandler.wsevh.jcfg
    sed -i "s@configs_folder = \"/usr/local/etc/janus\"@configs_folder = \"/tmp/janus-ci\"@" /tmp/janus-ci/janus.jcfg
    sed -i "s/#broadcast = true/broadcast = true/" /tmp/janus-ci/janus.jcfg
    sed -i \
      -e "s/enabled = false/enabled = true/" \
      -e "s@ws://your.websocket.here@ws://127.0.0.1:65534@" \
      -e "s@# subprotocol = \"your-subprotocol\"@subprotocol = \"janus-events\"@" \
      -e "s/events = \"all\"/events = \"handles,media,webrtc\"/" \
      /tmp/janus-ci/janus.eventhandler.wsevh.jcfg
    timeout -s TERM 20 /usr/local/bin/janus -F /tmp/janus-ci --debug-level=4 > /tmp/janus-ci.log 2>&1 || true
    cat /tmp/janus-ci.log
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Setup of WebSockets event handler completed"* ]]
  [[ "$output" == *"JANUS VideoRoom plugin initialized!"* ]]
  [[ "$output" == *"Websockets server started (port 8188)"* ]]
}
