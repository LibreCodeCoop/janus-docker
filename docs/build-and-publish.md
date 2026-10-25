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

GitHub Actions builds and tests linux/amd64 and linux/arm64. The image workflow performs vulnerability scanning with Trivy, saves SARIF reports, and publishes code scanning results for supported repositories. A daily scheduled image validation reevaluates vulnerabilities disclosed after the latest change.

Other workflows independently verify REUSE, Actionlint, Zizmor, and DCO.

## Packaging limitations

Janus and Alpine image references are pinned, but the APK repositories can supply new package builds when images are rebuilt. A digest refers to the actual tested, published artifact; source and base pins alone do not guarantee byte-for-byte identical rebuilds.

CI never deploys to production and publication remains a separate privileged tag-release job. See [releases](releases.md).
