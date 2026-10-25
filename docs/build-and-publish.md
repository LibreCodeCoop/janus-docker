<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Build and CI

The Dockerfile declares the upstream Janus version once and a Git commit that must match the upstream tag. Both Alpine stages use an immutable version-and-digest OCI reference.

## Local checks

Dependencies: Docker Engine/Buildx, Bats, jq and ShellCheck. After building the image as janus-ci:verify, the same runtime tests can run locally:

    bats tests/policy.bats
    shellcheck scripts/scan-images.sh
    docker build --pull -t janus-ci:verify .
    JANUS_TEST_IMAGE=janus-ci:verify bats tests/image.bats

GitHub Actions now uses three focused workflows: `image-ci.yml` builds and Bats-tests linux/amd64 and linux/arm64, scans with Trivy and archives SARIF; `image-publish.yml` invokes that reusable CI on a reviewed push to main, then stages, scans, and publishes a commit-addressed image; `image-release.yml` promotes the already published commit manifest to a human-readable version tag without rebuilding. The CI also runs on PRs and daily to reevaluate newly disclosed vulnerabilities.

Separate workflows validate REUSE, Actionlint, and Zizmor. The installed DCO Probot checks contributor sign-offs directly; no duplicate DCO workflow is maintained.

## Packaging limitations

Janus and Alpine image references are pinned, but the APK repositories can supply new package builds when images are rebuilt. A digest refers to the actual tested, published artifact; source and base pins alone do not guarantee byte-for-byte identical rebuilds.

CI never deploys to production. Registry write access is restricted to the separate publishing jobs, and release promotion never recompiles a potentially different artifact. See [releases](releases.md).
