<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Janus integrations

This image contains upstream Janus, not an application, TURN server, or signaling backend.

## Modules validated in CI

- libjanus_videoroom.so: selective forwarding for multiparty video.
- libjanus_websockets.so: WebSocket transport for Janus APIs.
- libjanus_wsevh.so: WebSocket event handler for compatible signaling backends.

Bats verifies these modules start together in an isolated container. A local unavailable event receiver is intentional: the test proves module initialization, not successful external signaling or full media paths.

## Standalone Nextcloud Talk signaling

Follow the [upstream signaling setup instructions](https://github.com/strukturag/nextcloud-spreed-signaling#setup-of-janus).

1. Enable events.broadcast in janus.jcfg.
2. Enable janus.eventhandler.wsevh.jcfg, including the janus-events subprotocol and handles,media,webrtc events.
3. Bound the event queue used during backend interruptions.
4. Restrict Janus API and administration transport to private signaling networks.
5. Define public ICE/UDP range, NAT mapping, and TURN in the deployment project, not in this image.

Mount valid configuration files read-only. Do not mount a missing sample handler file, as the container runtime may create a directory in its place.

Full qualification requires real audio, video, screenshare and reconnection tests from separate networks.
