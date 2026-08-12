<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/580.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/580.0.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): ${{ secrets.GH_TOKEN }} is interpolated directly inside run: shell command strings in two steps of upgrader.yaml. Any ${{ ... }} expression embedded in a run: block is a script-injection risk because the value is substituted into the shell command string before the shell parses it. Offending lines: (1) `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/"...` in the 'Checkout repo' step; (2) the same pattern in the 'Modify Dockerfile' step. The fix is to pass the token via an env: variable and reference it as $GH_TOKEN inside the script.

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:71`

### unpinned-uses (severity: high)

Multiple uses: references are pinned to mutable version tags rather than immutable 40-character commit SHAs, making the workflow vulnerable to supply-chain attacks if the tag is moved. Failing references: `actions/checkout@v2` (test.yaml lines 9, 22, 34, 47) and `actions/create-release@v1` (upgrader.yaml line 83). Each should be replaced with the full SHA, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v2`.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:22`
- `.github/workflows/test.yaml:34`
- `.github/workflows/test.yaml:47`
- `.github/workflows/upgrader.yaml:83`

### missing-permissions (severity: medium)

Neither workflow file declares a top-level permissions: key, and no individual job within either file declares its own permissions: block. Without explicit permissions, workflows run with the repository's default token permissions (which may be write-all), granting more access than necessary. A minimal permissions: block (e.g. `contents: read`) should be added at the top level or per-job level in both files.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across both workflow files:

1. script-injection (upgrader.yaml): Moved `${{ secrets.GH_TOKEN }}` from inline run: shell strings into env: blocks (as GH_TOKEN) in both the 'Checkout repo' step and the 'Modify Dockerfile' step. Shell scripts now reference ${GH_TOKEN} as a plain environment variable.

2. unpinned-uses: Pinned actions/checkout@v2 to SHA 0717577d45739eb3c851188b29f50ed6c0b2194e (all 4 occurrences in test.yaml) and actions/create-release@v1 to SHA 0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e (upgrader.yaml). Original tags preserved as comments.

3. missing-permissions: Added top-level `permissions: contents: write` to upgrader.yaml (required for git push and release creation) and `permissions: contents: read` to test.yaml (minimal read-only access for checkout and testing).

