<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Security, licensing and updates

- Dependabot scans GitHub Actions daily for version updates after a seven-day routine stabilization period; vulnerability-triggered security PRs operate independently when the repository enables Dependabot security updates.
- Renovate proposes upstream Janus version+commit, Alpine digest, and scanner version updates. Changes require review and tests; nothing auto-merges.
- Trivy checks HIGH and CRITICAL vulnerabilities with available fixes, fails on an end-of-life OS image, and exports SARIF reports on every image build.
- Daily image CI helps surface newly disclosed CVEs, even when the image repository itself has not changed. On main, images are staged by digest and scanned again before that exact digest receives a public SHA tag; versioned tags and GitHub Releases are generated automatically from that scanned manifest, without rebuilding or deploying to production. Responding to an alert still requires a new reviewed release and an explicitly controlled deployment.

Repository-owned packaging/documentation is AGPL-3.0-or-later. The unmodified Janus server included in the image is GPL-3.0-only. Repository licensing texts are in LICENSE and LICENSES/; the upstream Janus GPLv3 text is shipped separately in the image as COPYING. REUSE/SPDX metadata is required for each tracked file; only strictly non-commentable JSON is annotated via REUSE.toml.

A build passing Trivy once is not proof that an older running image is secure. Always monitor deployed digests, evaluate advisories, and preserve rollback capability.
