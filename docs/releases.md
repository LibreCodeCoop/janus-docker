<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Image tags and production releases

## Version source and tags

ARG JANUS_VERSION in the Dockerfile is the only source of the upstream Janus version; ARG JANUS_COMMIT pins its exact upstream source. Version changes go through reviewed PRs.

Git release tags are formatted as v<upstream>-r<revision>, for example v1.4.3-r1. Increment the revision for packaging-only changes without changing Janus itself. No separate version file or release script is needed; the workflow validates the Git tag against Dockerfile and docker/metadata-action generates the OCI tags.

OCI tags include the human-readable release (for example 1.4.3-r1) and an immutable sha-prefixed source commit reference. We do not publish latest or floating major/minor release aliases.

## Release procedure

1. Review upstream compatibility and pass all security, policy and image checks.
2. Merge a reviewed DCO-compliant PR.
3. Create a **new annotated and signed release tag** from the approved commit on main.
4. The tag job checks version matching and main ancestry; it refuses an already published registry tag.
5. It publishes the amd64/arm64 manifest, SBOM and provenance. Record the published digest.

Production must select the version tag **and immutable manifest digest**. Rollback preserves the old digest and configuration. Replacing Janus interrupts active calls: rehearse with actual signaling and client networks and schedule a window.

The sample docker-compose.yml only demonstrates consuming published digest-pinned images. It cannot be used to configure the ADA deployment.
