<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/575.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **actions-hub--gcloud/575.0.1** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): The `${{ secrets.GH_TOKEN }}` expression is directly interpolated inside `run:` shell command strings in two steps of upgrader.yaml. Any `${{ ... }}` expression inside a run block is a script injection risk because the value is substituted into the shell command string before the shell parses it. If the token value contained shell metacharacters, it could alter command execution. Offending lines: `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/"...` in both the 'Checkout repo' step (line 13) and the 'Modify Dockerfile' step (line 68).

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:68`

### unpinned-uses (severity: high)

Multiple `uses:` references are pinned to mutable version tags rather than immutable 40-character commit SHAs, making the workflow vulnerable to supply-chain attacks if the tag is moved. Failing references: `actions/checkout@v2` (test.yaml, 4 occurrences) and `actions/create-release@v1` (upgrader.yaml).

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/upgrader.yaml:85`

### missing-permissions (severity: medium)

Neither workflow file has a top-level `permissions:` key, and no job within either file defines its own `permissions:` block. Without explicit permissions, workflows run with the default token permissions (which may be overly broad, e.g. write access to repository contents). Both test.yaml and upgrader.yaml are affected.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across both workflow files:

1. **script-injection** (upgrader.yaml lines 13 and 68): Moved `${{ secrets.GH_TOKEN }}` out of `run:` shell strings and into `env:` blocks as `GH_TOKEN`. The shell commands now reference `${GH_TOKEN}` as a plain environment variable, preventing shell metacharacter injection.

2. **unpinned-uses**: Pinned all mutable tag references to full 40-character commit SHAs:
   - `actions/checkout@v2` → `actions/checkout@ee0669bd1cc54295c223e0bb666b733df41de1c5 # v2` (4 occurrences in test.yaml)
   - `actions/create-release@v1` → `actions/create-release@0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e # v1` (upgrader.yaml)

3. **missing-permissions**: Added top-level `permissions:` blocks to both files:
   - `upgrader.yaml`: `contents: write` (needed to push commits and create releases)
   - `test.yaml`: `contents: read` (only needs to check out code)

