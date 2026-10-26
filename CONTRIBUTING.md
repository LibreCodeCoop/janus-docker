<!--
SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Contributing

Contributions to container security, reproducibility, test coverage, and documentation are welcome. Coordinate substantial changes through an issue first. Janus behavior and C source changes belong upstream at [Meetecho](https://github.com/meetecho/janus-gateway).

Include appropriate Bats coverage and document changes in docs/. Follow the [Developer Certificate of Origin](https://developercertificate.org/): each human commit must include a Signed-off-by trailer matching the author and should be cryptographically signed. The installed DCO Probot validates sign-offs on pull requests; there is no custom DCO script.

PRs must pass Bats, ShellCheck, REUSE, Actionlint, Zizmor, and the image vulnerability scan. Include a rationale, upstream links when applicable, and reproducible tests. Never disclose credentials or customer data.

For testing and release procedures, see [build](docs/build-and-publish.md) and [releases](docs/releases.md). Review the [security policy](SECURITY.md) for sensitive issues.
