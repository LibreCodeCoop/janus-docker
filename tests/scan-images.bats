#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
  export TEST_ROOT="$BATS_TEST_TMPDIR"
  export TRIVY_REPORT_DIR="$TEST_ROOT/reports"
  export PATH="$TEST_ROOT:$PATH"
  export TEST_TRIVY_LOG="$TEST_ROOT/trivy.log"
  cat > "$TEST_ROOT/trivy" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_TRIVY_LOG"
case "$*" in
  *'--format sarif'*)
    while test "$#" -gt 0; do
      if test "$1" = '--output'; then
        shift
        printf '%s\n' '{"version":"2.1.0","runs":[]}' > "$1"
        break
      fi
      shift
    done
    exit 0 ;;
  *'--format table'*)
    exit "§{SCAN_STATUS:-0}" ;;
esac
exit 2
MOCK
  sed -i 's/§/\$/g' "$TEST_ROOT/trivy"
  chmod +x "$TEST_ROOT/trivy"
}

@test "reject invalid scan specs without calling Trivy" {
  run bash "$BATS_TEST_DIRNAME/../scripts/scan-images.sh" 'invalid-spec'
  [ "$status" -eq 2 ]
  [ ! -e "$TEST_TRIVY_LOG" ]
}

@test "emit SARIF and table for a supported architecture" {
  run bash "$BATS_TEST_DIRNAME/../scripts/scan-images.sh" 'janus@linux/amd64=image-ci:test'
  [ "$status" -eq 0 ]
  [ -f "$TRIVY_REPORT_DIR/janus-linux-amd64.sarif" ]
  grep -Fq -- '--format table' "$TEST_TRIVY_LOG"
  grep -Fq -- '--format sarif' "$TEST_TRIVY_LOG"
  grep -Fq -- '--config' "$TEST_TRIVY_LOG"
}

@test "preserve SARIF evidence when the vulnerability gate rejects the image" {
  export SCAN_STATUS=1
  run bash "$BATS_TEST_DIRNAME/../scripts/scan-images.sh" 'janus@linux/arm64=image-ci:test'
  [ "$status" -eq 1 ]
  [ -f "$TRIVY_REPORT_DIR/janus-linux-arm64.sarif" ]
}
