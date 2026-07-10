<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/575.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **actions-hub--gcloud/575.0.0** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple action references use mutable version tags instead of full 40-character SHA commit hashes, making them vulnerable to supply-chain attacks. In test.yaml: 'actions/checkout@v2' is used four times. In upgrader.yaml: 'actions/create-release@v1' is used once.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:22`
- `.github/workflows/test.yaml:35`
- `.github/workflows/test.yaml:48`
- `.github/workflows/upgrader.yaml:88`

### missing-permissions (severity: medium)

Neither test.yaml nor upgrader.yaml has a top-level 'permissions:' key, and no job in either file defines job-level permissions. Without explicit permissions, workflows run with the default (potentially broad) token permissions.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### script-injection (severity: high)

Sub-rule (a): The expression ${{ secrets.GH_TOKEN }} is interpolated directly inside run: shell command strings in upgrader.yaml. Any ${{ }} expression inside a run: block undergoes YAML template substitution before the shell sees it, which is a script-injection risk. Affected steps: 'Checkout repo' (line 13) and 'Modify Dockerfile' (line 71).

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:71`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step writes SDK_VERSION and LATEST_VERSION — values derived from external HTTP API responses (curl to Docker Hub and GitHub API) — directly to $GITHUB_ENV and $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'). A malicious API response containing newlines could inject arbitrary environment variables or output values. Offending lines: 'echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV' and 'echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV'.

Locations:

- `.github/workflows/upgrader.yaml:33`
- `.github/workflows/upgrader.yaml:34`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection, github-env-injection

**Notes:**

Fixed all four findings: (1) unpinned-uses: pinned actions/checkout@v2 to SHA ee0669bd1cc54295c223e0bb666b733df41de1c5 in all 4 occurrences in test.yaml, and pinned actions/create-release@v1 to SHA 0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml; (2) missing-permissions: added top-level 'permissions: {}' to both test.yaml and upgrader.yaml, with a job-level 'permissions: contents: write' on the check job in upgrader.yaml (needed for git push and release creation); (3) script-injection: moved ${{ secrets.GH_TOKEN }} out of run: shell strings in both 'Checkout repo' and 'Modify Dockerfile' steps into their respective env: blocks, referencing as ${GH_TOKEN} in the shell; (4) github-env-injection: added sanitization using printf '%s' ... | tr -d '\n\r' for both SDK_VERSION and LATEST_VERSION before writing them to $GITHUB_ENV.

### Iteration 2

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three security findings: (1) entrypoint.sh: replaced `eval "$command $*"` with `"$command" "$@"` to eliminate eval and properly quote all arguments; (2) upgrader.yaml line 58: quoted $SDK_VERSION in bash regex test as `[[ "$SDK_VERSION" =~ ... ]]`; (3) upgrader.yaml line 66: quoted the curl URL containing $SDK_VERSION as `"https://hub.docker.com/v2/repositories/google/cloud-sdk/tags/$SDK_VERSION"`; (4) upgrader.yaml line 98: added sanitization `safe_tag=$(printf '%s' "$SDK_VERSION" | tr -d '\n\r')` before writing `tag=${safe_tag}` to $GITHUB_OUTPUT.

