<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/582.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/582.0.0** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): ${{ secrets.GH_TOKEN }} is interpolated directly inside run: shell command strings in two steps of upgrader.yaml. Any ${{ ... }} expression inside a run: block is a script-injection risk because the value is substituted into the shell command string before the shell parses it. Offending lines: (line 13) `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/"...` and (line 72) the same pattern in the 'Modify Dockerfile' step.

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:72`

### github-env-injection (severity: high)

In the 'Check if new version exist' step of upgrader.yaml, SDK_VERSION and LATEST_VERSION are populated from external HTTP API responses (via curl | jq | grep | sed — effectively untrusted external input) and then written directly to $GITHUB_ENV without the required sanitization step (printf '%s' "$VAR" | tr -d '\n\r'). A malicious API response containing newlines could inject arbitrary environment variables into subsequent steps. Offending lines: `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV` and `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV`.

Locations:

- `.github/workflows/upgrader.yaml:31`
- `.github/workflows/upgrader.yaml:32`

### missing-permissions (severity: medium)

Neither test.yaml nor upgrader.yaml defines a top-level permissions: key, and no job within either file defines a job-level permissions: key. Without explicit permissions, workflows run with the default (potentially broad) GITHUB_TOKEN permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### unpinned-uses (severity: high)

Multiple workflow steps reference actions by mutable version tags instead of immutable full-length SHA digests, making the workflow vulnerable to supply-chain attacks if the tag is moved. Failing references: test.yaml uses `actions/checkout@v2` (lines 9, 21, 33, 45); upgrader.yaml uses `actions/create-release@v1` (line 87). These should be pinned to their full 40-character commit SHAs.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:21`
- `.github/workflows/test.yaml:33`
- `.github/workflows/test.yaml:45`
- `.github/workflows/upgrader.yaml:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, missing-permissions, unpinned-uses

**Notes:**

Fixed all four findings across test.yaml and upgrader.yaml:
1. script-injection: Moved secrets.GH_TOKEN from inline run: shell strings to env: blocks in both 'Checkout repo' and 'Modify Dockerfile' steps, referencing as ${GH_TOKEN} in shell.
2. github-env-injection: Added printf '%s' "$VAR" | tr -d '\n\r' sanitization before writing SDK_VERSION and LATEST_VERSION to $GITHUB_ENV.
3. missing-permissions: Added 'permissions: {}' to test.yaml and 'permissions: contents: write' to upgrader.yaml (needed for git push and release creation).
4. unpinned-uses: Pinned actions/checkout@v2 to SHA 0717577d45739eb3c851188b29f50ed6c0b2194e in all 4 locations in test.yaml, and actions/create-release@v1 to SHA 0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml.

### Iteration 2

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed two findings in hardened/action/.github/workflows/upgrader.yaml:
1. script-injection (lines 57, 65): Quoted $SDK_VERSION in the bash regex match LHS (`[[ "$SDK_VERSION" =~ ... ]]`) and wrapped the Docker Hub URL in double quotes to prevent shell metacharacter injection.
2. github-env-injection (line 97): Added `safe_tag=$(printf '%s' "$SDK_VERSION" | tr -d '\n\r')` immediately before writing to $GITHUB_OUTPUT, replacing the raw `${SDK_VERSION}` expansion with the sanitized `${safe_tag}` value.

