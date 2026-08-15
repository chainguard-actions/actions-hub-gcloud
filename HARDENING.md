<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/574.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/574.0.0** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Two `run:` blocks in upgrader.yaml directly interpolate `${{ secrets.GH_TOKEN }}` inside shell command strings (sub-rule a). Even though `secrets.GH_TOKEN` is not attacker-controlled, any `${{ ... }}` expression interpolated directly into a `run:` block is a script-injection finding — the value flows through YAML template substitution before the shell ever sees it. The offending lines are:
- `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"` (Checkout repo step, line ~9)
- Same pattern repeated in the Modify Dockerfile step (line ~68)
Fix: move the token into an `env:` variable and reference it as `"$GH_TOKEN"` in the shell script.

Locations:

- `.github/workflows/upgrader.yaml:9`
- `.github/workflows/upgrader.yaml:68`

### unpinned-uses (severity: high)

Multiple `uses:` references are pinned to mutable tags rather than full 40-character commit SHAs, making the workflow vulnerable to supply-chain attacks if the tag is moved:
- `.github/workflows/test.yaml`: `actions/checkout@v2` (used 4 times)
- `.github/workflows/upgrader.yaml`: `actions/create-release@v1`
All should be pinned to a full SHA, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v2`.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:20`
- `.github/workflows/test.yaml:31`
- `.github/workflows/test.yaml:43`
- `.github/workflows/upgrader.yaml:79`

### missing-permissions (severity: medium)

Neither `test.yaml` nor `upgrader.yaml` declares a top-level `permissions:` key, and no job within either file declares job-level permissions. Without explicit permissions, workflows run with the default (often broad) `GITHUB_TOKEN` permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across two workflow files:

1. script-injection (upgrader.yaml lines 9 and 68): Moved `${{ secrets.GH_TOKEN }}` out of both `run:` blocks into `env:` variables (`GH_TOKEN: ${{ secrets.GH_TOKEN }}`), and updated the shell scripts to reference `$GH_TOKEN` instead.

2. unpinned-uses: Pinned all 4 `actions/checkout@v2` references in test.yaml to `actions/checkout@0717577d45739eb3c851188b29f50ed6c0b2194e # v2`, and pinned `actions/create-release@v1` in upgrader.yaml to `actions/create-release@0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e # v1`.

3. missing-permissions: Added `permissions: contents: read` to test.yaml (minimum needed for checkout) and `permissions: contents: write` to upgrader.yaml (needed for pushing commits and creating releases).

### Iteration 2

**Fixes applied:** script-injection, github-env-injection

**Notes:**

1. entrypoint.sh: Replaced `eval "$command $*"` with `"$command" "$@"` — eliminates eval and uses properly-quoted positional argument expansion, preventing shell command injection via user-controlled args input.
2. upgrader.yaml: Sanitized SDK_VERSION and LATEST_VERSION (from external API responses) before writing to $GITHUB_ENV using `printf '%s' "${VAR}" | tr -d '\n\r'`. Also sanitized SDK_VERSION before writing to $GITHUB_OUTPUT in the 'Modify Dockerfile' step using the same pattern.

