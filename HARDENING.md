<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/581.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/581.0.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Two `run:` blocks in upgrader.yaml directly interpolate `${{ secrets.GH_TOKEN }}` inside shell command strings. Per the script-injection check, ANY `${{ ... }}` expression inside a `run:` block is a violation (sub-rule a), regardless of the context source. The offending lines are:
  - `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"` (in the 'Checkout repo' step)
  - Same pattern repeated in the 'Modify Dockerfile' step.
The fix is to pass the token via an `env:` variable and reference `$GH_TOKEN` in the shell.

Locations:

- `.github/workflows/upgrader.yaml:11`
- `.github/workflows/upgrader.yaml:62`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step writes `SDK_VERSION` and `LATEST_VERSION` — values fetched from external APIs via `curl` and therefore untrusted — directly to `$GITHUB_ENV` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). A malicious API response containing newlines could inject arbitrary environment variables into subsequent steps.
  Offending lines:
  - `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV`
  - `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV`

Locations:

- `.github/workflows/upgrader.yaml:36`
- `.github/workflows/upgrader.yaml:37`

### unpinned-uses (severity: high)

Multiple `uses:` references are pinned to mutable tags rather than immutable 40-character commit SHAs, making the workflow vulnerable to supply-chain attacks if the tag is moved:
  - `actions/checkout@v2` (used 4 times in test.yaml)
  - `actions/create-release@v1` (used in upgrader.yaml)
All should be pinned to a full SHA, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4`.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:22`
- `.github/workflows/test.yaml:35`
- `.github/workflows/test.yaml:48`
- `.github/workflows/upgrader.yaml:79`

### missing-permissions (severity: medium)

Neither `test.yaml` nor `upgrader.yaml` declares a top-level `permissions:` key, and no individual job within either file declares job-level permissions. Without explicit permissions, workflows run with the repository's default token permissions (often `write-all` for older repositories), violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all four findings across two workflow files:

1. **script-injection** (upgrader.yaml): Moved `${{ secrets.GH_TOKEN }}` from inline shell strings into `env:` blocks (as `GH_TOKEN`) for both the 'Checkout repo' and 'Modify Dockerfile' steps. Shell now references `$GH_TOKEN` instead.

2. **github-env-injection** (upgrader.yaml): Added `printf '%s' "$VAR" | tr -d '\n\r'` sanitization for `SDK_VERSION` and `LATEST_VERSION` before writing them to `$GITHUB_ENV`, preventing newline-based injection from malicious API responses.

3. **unpinned-uses**: Pinned `actions/checkout@v2` → `@0717577d45739eb3c851188b29f50ed6c0b2194e # v2` (4 occurrences in test.yaml) and `actions/create-release@v1` → `@0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e # v1` (upgrader.yaml).

4. **missing-permissions**: Added `permissions: {}` top-level block to both `test.yaml` and `upgrader.yaml`.

