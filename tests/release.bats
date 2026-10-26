#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
  PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
  REPO="$BATS_TEST_TMPDIR/source"
  mkdir -p "$REPO"
  git -C "$REPO" init --quiet
  git -C "$REPO" config user.name "Image release tests"
  git -C "$REPO" config user.email "release-tests@example.invalid"
  git -C "$REPO" config commit.gpgsign false
  printf 'initial\n' > "$REPO/source"
  git -C "$REPO" add source
  git -C "$REPO" commit --quiet -m initial
  export GITHUB_OUTPUT="$BATS_TEST_TMPDIR/version-output"
  export GITHUB_SHA="$(git -C "$REPO" rev-parse HEAD)"
  # Exercise the actual release workflow's Git-tag selection, not a duplicate helper script.
  RELEASE_SELECTION="$(sed -n '/^          pattern=/,/^          printf /{s/^          //;p;}' "$PROJECT_ROOT/.github/workflows/image-release.yml")"
  [ -n "$RELEASE_SELECTION" ]
}

assert_release_tag() {
  local version="$1" expected="$2"
  : > "$GITHUB_OUTPUT"
  run env upstream="$version" GITHUB_SHA="$GITHUB_SHA" GITHUB_OUTPUT="$GITHUB_OUTPUT" \
    bash -euo pipefail -c "cd '$REPO'; $RELEASE_SELECTION"
  [ "$status" -eq 0 ]
  grep -Fxq "tag=$expected" "$GITHUB_OUTPUT"
}

@test "first version release starts at revision one" {
  assert_release_tag 1.4.3 v1.4.3-r1
}

@test "revisions increase numerically past nine, without lexical sorting" {
  git -C "$REPO" tag v1.4.3-r9
  git -C "$REPO" tag v1.4.3-r10
  printf 'next\n' >> "$REPO/source"
  git -C "$REPO" commit --quiet -am next
  GITHUB_SHA="$(git -C "$REPO" rev-parse HEAD)"
  assert_release_tag 1.4.3 v1.4.3-r11
}

@test "a different upstream version restarts at revision one" {
  git -C "$REPO" tag v1.4.3-r5
  assert_release_tag 1.4.4 v1.4.4-r1
}

@test "retrying the same commit reuses its existing release tag" {
  git -C "$REPO" tag v1.4.3-r2
  assert_release_tag 1.4.3 v1.4.3-r2
}

@test "invalid previous tag variants do not affect the revision" {
  git -C "$REPO" tag v1.4.3-r0
  git -C "$REPO" tag v1.4.3-r01
  git -C "$REPO" tag v1.4.3-r1-alpha
  git -C "$REPO" tag v1.4.3-r1
  printf 'next\n' >> "$REPO/source"
  git -C "$REPO" commit --quiet -am next
  GITHUB_SHA="$(git -C "$REPO" rev-parse HEAD)"
  assert_release_tag 1.4.3 v1.4.3-r2
}
