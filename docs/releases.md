<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Image tags and production releases

## Version source and tags

ARG JANUS_VERSION in the Dockerfile is the only source of the upstream Janus version; ARG JANUS_COMMIT pins its exact upstream source. Version changes go through reviewed PRs.

Git release tags are formatted as v<upstream>-r<revision>, for example v1.4.3-r1. Increment the revision for packaging-only changes without changing Janus itself. No separate version file or release script is needed; the release workflow validates the Git tag against Dockerfile. The post-merge workflow publishes a `sha-<full-commit>` image automatically; the release workflow only adds the reviewed version tag to that existing digest.

OCI references are `sha-<full-commit>` after each successful push to main and a human-readable release (for example `1.4.3-r1`) after an approved Git tag. Both reference the same immutable multi-platform manifest. We do not publish latest or floating major/minor release aliases.

## Release procedure

1. Review upstream compatibility and pass all security, policy and image checks.
2. Merge a reviewed DCO-compliant PR.
3. Wait for the successful main-branch image workflow: the commit image must exist in GHCR, include amd64/arm64, and have passed the security gate against its exact digest.
4. Create a **new annotated and signed release tag** from that approved commit on main.
5. The tag workflow verifies upstream version and main ancestry, rejects an existing release tag, and promotes the already published SHA image **without recompilation**. SBOM and provenance are preserved with the original index. Record the unchanged digest.

Production must select the version tag **and immutable manifest digest**. Rollback preserves the old digest and configuration. Replacing Janus interrupts active calls: rehearse with actual signaling and client networks and schedule a window.

Release tags created before the corresponding commit image is published will fail safely; retry after main succeeds. The sample docker-compose.yml only demonstrates consuming published digest-pinned images. It cannot be used to configure the ADA deployment.
