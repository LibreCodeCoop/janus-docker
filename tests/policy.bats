#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
  PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
}

@test "both stages pin Alpine version and OCI multiarch digest" {
  count=$(grep -Ec '^FROM alpine:[0-9]+\.[0-9]+\.[0-9]+@sha256:[a-f0-9]{64}( AS [a-z]+)?$' "$PROJECT_ROOT/Dockerfile")
  [ "$count" -eq 2 ]
}

@test "upstream Janus version and immutable Git commit are declared together" {
  grep -Eq '^ARG JANUS_VERSION=[0-9]+\.[0-9]+\.[0-9]+$' "$PROJECT_ROOT/Dockerfile"
  grep -Eq '^ARG JANUS_COMMIT=[a-f0-9]{40}$' "$PROJECT_ROOT/Dockerfile"
  grep -Fq "git rev-parse 'FETCH_HEAD^{commit}'" "$PROJECT_ROOT/Dockerfile"
  [ "$(grep -c 'ARG JANUS_VERSION=' "$PROJECT_ROOT/Dockerfile")" -eq 1 ]
}

@test "Renovate monitors OCI digests Janus commits and Trivy" {
  run jq -e '
    (.enabledManagers | index("dockerfile") != null) and
    (.enabledManagers | index("custom.regex") != null) and
    (.customManagers | any(.[]; .depNameTemplate == "meetecho/janus-gateway" and .datasourceTemplate == "github-tags")) and
    (.customManagers | any(.[]; .managerFilePatterns | any(.[]; contains("docker-image"))))
  ' "$PROJECT_ROOT/renovate.json"
  [ "$status" -eq 0 ]
  [ "$output" = true ]
}

@test "Dependabot checks GitHub Actions daily without duplicate Docker PRs" {
  grep -Eq 'package-ecosystem: github-actions' "$PROJECT_ROOT/.github/dependabot.yml"
  grep -Eq 'interval: daily' "$PROJECT_ROOT/.github/dependabot.yml"
  ! grep -Eq 'package-ecosystem: docker' "$PROJECT_ROOT/.github/dependabot.yml"
}

@test "release policy uses Git tags without helper scripts or version files" {
  [ ! -e "$PROJECT_ROOT/IMAGE_REVISION" ]
  [ ! -e "$PROJECT_ROOT/scripts/release-tag.sh" ]
  grep -Fq 'type=match,pattern=^v(.*)$,group=1' "$PROJECT_ROOT/.github/workflows/docker-image.yml"
  grep -Fq 'latest=false' "$PROJECT_ROOT/.github/workflows/docker-image.yml"
  grep -Fq 'GITHUB_REF_NAME' "$PROJECT_ROOT/.github/workflows/docker-image.yml"
}

@test "build inputs reject floating versions" {
  ! grep -Eq '^FROM .*:latest' "$PROJECT_ROOT/Dockerfile"
  ! grep -Eq '^ARG JANUS_VERSION=main$' "$PROJECT_ROOT/Dockerfile"
  ! grep -Eq '^[[:space:]]+image:.*:latest' "$PROJECT_ROOT/docker-compose.yml"
}

@test "Compose consumes an immutable GHCR image without building on production" {
  grep -Fq 'JANUS_IMAGE_TAG' "$PROJECT_ROOT/docker-compose.yml"
  grep -Fq 'JANUS_IMAGE_DIGEST' "$PROJECT_ROOT/docker-compose.yml"
  ! grep -Eq '^[[:space:]]+build:' "$PROJECT_ROOT/docker-compose.yml"
  ! grep -Eq '^[[:space:]]+network_mode: host' "$PROJECT_ROOT/docker-compose.yml"
}

@test "REUSE annotates only JSON which cannot carry comment headers" {
  run python3 -c 'import tomllib,sys; d=tomllib.load(open(sys.argv[1],"rb")); assert len(d["annotations"]) == 1; assert d["annotations"][0]["path"] == ["renovate.json"]' "$PROJECT_ROOT/REUSE.toml"
  [ "$status" -eq 0 ]
}

@test "Trivy SARIF SBOM and provenance are configured" {
  grep -Fq 'upload-sarif' "$PROJECT_ROOT/.github/workflows/docker-image.yml"
  grep -Fq 'packages: write' "$PROJECT_ROOT/.github/workflows/docker-image.yml"
  grep -Fq 'provenance: mode=max' "$PROJECT_ROOT/.github/workflows/docker-image.yml"
  grep -Fq 'sbom: true' "$PROJECT_ROOT/.github/workflows/docker-image.yml"
}
