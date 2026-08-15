<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/571.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/571.0.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

In .github/workflows/upgrader.yaml, two `run:` steps directly interpolate `${{ secrets.GH_TOKEN }}` inside shell command strings. Per the script-injection check, ANY `${{ ... }}` expression inside a `run:` block is a violation (sub-rule a), regardless of whether the context appears attacker-controlled. The offending lines are:
- Step 'Checkout repo' (line 13): `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"`
- Step 'Modify Dockerfile' (line 71): `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"`
Fix: pass the token via an `env:` block and reference it as `$GH_TOKEN` (double-quoted) in the shell script.

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:71`

### unpinned-uses (severity: high)

Workflow files reference GitHub Actions by mutable tag instead of a full 40-character commit SHA, making them vulnerable to supply-chain attacks if the tag is moved.
- .github/workflows/test.yaml: `uses: actions/checkout@v2` (lines 9, 22, 33, 44)
- .github/workflows/upgrader.yaml: `uses: actions/create-release@v1` (line 82)
Fix: pin each reference to a full SHA, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v2`.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:22`
- `.github/workflows/test.yaml:33`
- `.github/workflows/test.yaml:44`
- `.github/workflows/upgrader.yaml:82`

### missing-permissions (severity: medium)

Neither workflow file declares a `permissions:` block at the top level, and no individual job declares one either. Without explicit permissions, the GITHUB_TOKEN is granted its default (potentially broad) permissions.
- .github/workflows/test.yaml: no top-level or job-level `permissions:` key across all 4 jobs (json-test, base64-test, multistep-test, multistep-different-config-test).
- .github/workflows/upgrader.yaml: no top-level or job-level `permissions:` key for the `check` job.
Fix: add a top-level `permissions: {}` block and grant only the minimum required scopes (e.g. `contents: write` for the upgrader that pushes commits and creates releases).

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across both workflow files:

1. **script-injection** (upgrader.yaml lines 13 & 71): Moved `${{ secrets.GH_TOKEN }}` out of both `run:` blocks into `env:` blocks as `GH_TOKEN: ${{ secrets.GH_TOKEN }}`. Shell scripts now reference `$GH_TOKEN` instead of the inline expression.

2. **unpinned-uses**: Pinned `actions/checkout@v2` → `actions/checkout@ee0669bd1cc54295c223e0bb666b733df41de1c5 # v2` (all 4 occurrences in test.yaml), and `actions/create-release@v1` → `actions/create-release@0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e # v1` in upgrader.yaml.

3. **missing-permissions**: Added `permissions: {}` to test.yaml (no GITHUB_TOKEN access needed) and `permissions: contents: write` to upgrader.yaml (required for pushing commits and creating releases).

