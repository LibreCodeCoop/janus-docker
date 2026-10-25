#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

if [[ "$#" != 1 || "$1" != *@linux/*=* ]]; then
  printf 'Usage: %s janus@linux/amd64=image\n' "$0" >&2
  exit 2
fi
spec="$1"
label_and_platform="${spec%%=*}"
image="${spec#*=}"
label="${label_and_platform%@*}"
platform="${label_and_platform#*@}"
if [[ ! "$label" =~ ^[a-z0-9_-]+$ || ! "$platform" =~ ^linux/(amd64|arm64)$ || -z "$image" ]]; then
  printf 'Invalid image specification: %s\n' "$spec" >&2
  exit 2
fi
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
report_dir="${TRIVY_REPORT_DIR:-$root/trivy-results}"
mkdir -p "$report_dir"

# Always emit a report even when the severity gate fails.
trivy image --config "$root/trivy.yaml" --platform "$platform" --format sarif \
  --exit-code 0 --output "$report_dir/${label}-${platform//\//-}.sarif" "$image"
trivy image --config "$root/trivy.yaml" --platform "$platform" --format table "$image"
