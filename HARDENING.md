<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/573.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/573.0.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Two `run:` blocks in upgrader.yaml directly interpolate `${{ secrets.GH_TOKEN }}` inside shell command strings (sub-rule a). Any `${{ ... }}` expression embedded directly in a `run:` script is a script-injection risk because YAML template substitution occurs before the shell ever sees the value. The offending lines are:
  - Line 13: `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"`
  - Line 75: same pattern in the 'Modify Dockerfile' step.
Fix: move the token into an `env:` variable and reference it as `$GH_TOKEN` in the shell script.

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:75`

### unpinned-uses (severity: high)

Workflow files reference GitHub Actions by mutable version tags instead of full 40-character commit SHAs, making the workflow vulnerable to supply-chain attacks if the tag is moved.
- test.yaml: `actions/checkout@v2` (used 4 times)
- upgrader.yaml: `actions/create-release@v1`
Fix: pin each action to its full SHA, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v2`.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/upgrader.yaml:76`

### missing-permissions (severity: medium)

Neither workflow file defines a `permissions:` block at the top level or on any individual job. Without explicit permissions, workflows run with the default (often broad) token permissions. Both test.yaml and upgrader.yaml are affected.
Fix: add a top-level `permissions: {}` or minimal per-job permissions (e.g. `contents: read`) to each workflow.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across both workflow files:

1. **script-injection** (upgrader.yaml lines 13 & 75): Moved `${{ secrets.GH_TOKEN }}` out of both `run:` shell strings and into `env:` blocks as `GH_TOKEN`. The shell scripts now reference `$GH_TOKEN` instead of the template expression.

2. **unpinned-uses**: Pinned all 4 occurrences of `actions/checkout@v2` in test.yaml to `actions/checkout@0717577d45739eb3c851188b29f50ed6c0b2194e # v2`, and pinned `actions/create-release@v1` in upgrader.yaml to `actions/create-release@0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e # v1`.

3. **missing-permissions**: Added `permissions: {}` at the top level of both test.yaml and upgrader.yaml to enforce least-privilege token access.

