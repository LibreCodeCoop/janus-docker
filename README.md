<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Janus WebRTC for independent infrastructure

A maintained container image for the [Janus WebRTC Server](https://janus.conf.meetecho.com/), packaged by [LibreCode](https://librecode.coop/) for organizations operating their own real-time communication infrastructure.

Janus powers interactive audio and video applications. This project makes the official Meetecho server available as an independently managed container, without bundling an application, reverse proxy, TURN server, or signaling service.

**Official container image:** [`ghcr.io/librecodecoop/janus`](https://github.com/LibreCodeCoop/janus-docker/pkgs/container/janus), published by LibreCode in GitHub Container Registry (GHCR). The [source and Dockerfile](https://github.com/LibreCodeCoop/janus-docker/blob/main/Dockerfile) are in this repository; [GitHub Releases](https://github.com/LibreCodeCoop/janus-docker/releases) list the approved versions. See [image references and immutable deployment digests](docs/releases.md) before deploying. Do not use the third-party `sucwangsr/janus-webrtc-gateway-docker` image for new installations.

## Why use this image?

- **Infrastructure autonomy:** operate and upgrade the media gateway separately from other application services.
- **Security and traceability:** build from verified upstream source with reviewed dependencies, vulnerability scanning, and identifiable releases.
- **Interoperability:** include VideoRoom, WebSocket transport, and the WebSocket event handler for compatible signaling integrations.
- **Operational predictability:** independently test release images before selecting an immutable digest for deployment.

The image is intended for self-hosted collaboration environments and teams delivering real-time communication services. It is not a hosted meeting service or a complete Nextcloud Talk deployment.

## Documentation and participation

- [Technical capabilities and integration](docs/integration.md)
- [Build, tests, and CI](docs/build-and-publish.md)
- [Release tags and deployment policy](docs/releases.md)
- [Dependency and vulnerability management](docs/security.md)
- [Contributing](CONTRIBUTING.md) and [security reporting](SECURITY.md)

LibreCode provides open-source technology services and infrastructure support at [librecode.coop](https://librecode.coop/).
