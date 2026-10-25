<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Maintainer and agent guidance

This repository owns only the OCI packaging of unmodified Meetecho Janus. It must remain reusable by any application, without Nextcloud-specific implementation code.

## Boundaries

- Propose behavioral changes to the Janus project upstream first, rather than patching Janus in this image.
- Build only upstream tagged, commit-verified sources using digest-pinned base images.
- Never commit secrets, deployment configuration, call recordings, or production logs.
- No CI job may modify production or publish from an unreviewed pull request.
- Keep the README focused on value to users; implementation and operating details belong in docs/.

## Quality and governance

- Bats runtime/policy tests, ShellCheck, REUSE, Actionlint, Zizmor, and Trivy must pass.
- Both amd64 and arm64 images must be tested, including real module initialization.
- Every commentable source file must have SPDX metadata; do not use blanket REUSE annotations.
- Human commits require DCO Signed-off-by trailers and verified signatures where supported.
- Use reviewable Renovate and Dependabot PRs; no unattended production changes.
- Publish immutable images with SBOM and provenance; retain previous digests for rollback.

Read docs/build-and-publish.md, docs/releases.md, and docs/security.md before release changes.
