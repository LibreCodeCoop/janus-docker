<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Automated image versions and releases

## Source of truth

The upstream Janus version is declared once in Dockerfile as ARG JANUS_VERSION; ARG JANUS_COMMIT pins the upstream source commit. Renovate updates both together in a reviewed PR.

After every relevant change merges into main (documentation-only changes are excluded), the publisher invokes the same Bats, image-build and Trivy checks used for pull requests. It then stages a new multi-platform OCI image by digest, scans **that exact digest** for both architectures, and assigns the GHCR tag sha-<full-commit> only when every security gate succeeds.

## Automatic Git tags, GHCR tags and GitHub Releases

The successful main publisher directly calls image-release.yml as a reusable workflow. It does not depend on a tag-push event.

The release workflow:

1. Verifies that the image digest came from the preceding publish job and that the immutable commit tag still points to it, and checks both linux/amd64 and linux/arm64.
2. Reads the upstream version from Dockerfile; discovers existing v<upstream>-rN Git tags and selects the next revision. A new upstream version starts at r1.
3. Promotes the **unchanged OCI index** to the versioned GHCR tag; refuses to overwrite an existing tag with a different digest.
4. Creates the matching Git tag and GitHub Release with generated change notes and the exact deployable image digest.

Example: merging a reviewed dependency update publishes ghcr.io/librecodecoop/janus:sha-<commit>, then automatically publishes ghcr.io/librecodecoop/janus:1.4.3-r2 and GitHub Release v1.4.3-r2, referencing the identical digest. No IMAGE_REVISION, release-tag helper, or manual tagging is necessary.

GitHub Actions uses the built-in GITHUB_TOKEN with write permission only in the publish/release jobs. Tags created using this token **do not trigger another workflow**; the release is created in the same successful invocation. GitHub-created tags are not GPG-signed: verified signed commits, DCO, BuildKit provenance and SBOM remain separate controls. Cryptographic tag signatures would require dedicated credentials and a separate security decision.

## Failure handling and production

- A failing Bats build or HIGH/CRITICAL Trivy gate prevents image publication and the subsequent GitHub Release.
- Release tags advance monotonically per upstream version. Retrying a release for the same commit reuses its already assigned tag; it never overwrites a tag associated with a different digest.
- Main publishers are serialized by workflow concurrency. Failed release jobs can be retried without manual tag creation.
- This repository does **not** deploy to ADA or any other host. Real call testing, an approved maintenance window and a rollback plan remain separate.

The sample docker-compose.yml consumes only an already published image with both tag and immutable digest.
