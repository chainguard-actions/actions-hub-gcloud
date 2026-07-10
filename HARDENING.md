<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/575.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **actions-hub--gcloud/575.0.0** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple workflow steps use mutable tag references instead of pinned full-length SHA commits. In test.yaml, 'actions/checkout@v2' is used four times (lines 9, 21, 32, 44). In upgrader.yaml, 'actions/create-release@v1' is used (line 84). These should be pinned to a full 40-character commit SHA to prevent supply-chain attacks.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:21`
- `.github/workflows/test.yaml:32`
- `.github/workflows/test.yaml:44`
- `.github/workflows/upgrader.yaml:84`

### missing-permissions (severity: medium)

Neither test.yaml nor upgrader.yaml defines a top-level 'permissions:' key, and no job in either file defines job-level permissions. Without explicit permissions, the GITHUB_TOKEN is granted default (potentially broad) permissions. Each workflow should declare minimal required permissions.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### script-injection (severity: high)

Rule (a) violation: ${{ secrets.GH_TOKEN }} is interpolated directly inside run: shell command strings in upgrader.yaml. Line 13: `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf ...`. Line 75: same pattern in the 'Modify Dockerfile' step. Any ${{ ... }} expression directly inside a run: block is a script-injection risk because the value is substituted into the shell command string before the shell parses it, bypassing shell quoting.

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:75`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step writes SDK_VERSION and LATEST_VERSION to $GITHUB_ENV without sanitization. These values are sourced from external curl responses (Docker Hub and GitHub API) and are therefore untrusted. The values are written directly: `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV` and `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV`. A malicious registry response containing newlines could inject arbitrary environment variables. The required sanitization step (printf '%s' "$VAR" | tr -d '\n\r') is absent.

Locations:

- `.github/workflows/upgrader.yaml:31`
- `.github/workflows/upgrader.yaml:32`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection, github-env-injection

**Notes:**

Fixed all four findings: (1) unpinned-uses: pinned actions/checkout@v2 to SHA ee0669bd1cc54295c223e0bb666b733df41de1c5 in all 4 locations in test.yaml, and pinned actions/create-release@v1 to SHA 0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml; (2) missing-permissions: added 'permissions: {}' top-level block to both test.yaml and upgrader.yaml (upgrader.yaml job also has 'permissions: contents: write' since it pushes commits); (3) script-injection: moved ${{ secrets.GH_TOKEN }} out of run: shell strings in both 'Checkout repo' and 'Modify Dockerfile' steps into env: blocks, referencing as ${GH_TOKEN} in shell; (4) github-env-injection: sanitized SDK_VERSION and LATEST_VERSION using 'printf | tr -d newlines' before writing to $GITHUB_ENV.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed all three findings in .github/workflows/upgrader.yaml:
1. github-env-injection (line 98): Added `safe_tag=$(printf '%s' "$SDK_VERSION" | tr -d '\n\r')` and changed the GITHUB_OUTPUT write to use `safe_tag` instead of raw `$SDK_VERSION`.
2. script-injection (lines 58, 66): Quoted `$SDK_VERSION` as `"$SDK_VERSION"` in the [[ ]] regex test, and quoted the curl URL as `"https://hub.docker.com/v2/repositories/google/cloud-sdk/tags/${SDK_VERSION}"`.
3. script-injection (lines 90-95): Used `${LATEST_VERSION}` and `${SDK_VERSION}` inside double-quoted strings for the sed FROM_LINE/TO_LINE variables and git commit message, and quoted file path arguments.

