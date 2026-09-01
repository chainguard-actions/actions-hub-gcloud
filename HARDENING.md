<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/583.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/583.0.0** was hardened automatically. 4 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): ${{ secrets.GH_TOKEN }} is directly interpolated inside run: shell command strings in upgrader.yaml. Any ${{ ... }} expression inside a run: block is a script-injection risk because YAML template substitution happens before the shell ever sees the value. This occurs in two separate steps: 'Checkout repo' (line 12) and 'Modify Dockerfile' (line 57). Offending lines: `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"`

Locations:

- `.github/workflows/upgrader.yaml:12`
- `.github/workflows/upgrader.yaml:57`

### github-env-injection (severity: high)

Values fetched from external URLs (Docker Hub API and GitHub API) via curl are stored in SDK_VERSION and LATEST_VERSION shell variables and then written directly to $GITHUB_ENV and $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'). A malicious response from either API could inject arbitrary environment variables or output values. Affected writes: `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV` (line 30), `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV` (line 31), and `echo "tag=${SDK_VERSION}" >> $GITHUB_OUTPUT` (line 71).

Locations:

- `.github/workflows/upgrader.yaml:30`
- `.github/workflows/upgrader.yaml:31`
- `.github/workflows/upgrader.yaml:71`

### unpinned-uses (severity: high)

Multiple workflow steps reference actions by mutable version tags instead of full 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved. Failing references: `actions/checkout@v2` (test.yaml, lines 9, 22, 35, 48) and `actions/create-release@v1` (upgrader.yaml, line 76).

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:22`
- `.github/workflows/test.yaml:35`
- `.github/workflows/test.yaml:48`
- `.github/workflows/upgrader.yaml:76`

### missing-permissions (severity: medium)

Neither test.yaml nor upgrader.yaml defines a top-level `permissions:` key, and no individual job within either file defines a `permissions:` block. Without explicit permissions, workflows run with the default (potentially broad) token permissions. Both files should declare minimal required permissions (e.g., `permissions: contents: read` or more specific scopes).

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all four findings in .github/workflows/upgrader.yaml and .github/workflows/test.yaml:

1. script-injection: Moved ${{ secrets.GH_TOKEN }} from run: shell strings into env: blocks (as GH_TOKEN) in both 'Checkout repo' and 'Modify Dockerfile' steps. Shell scripts now reference ${GH_TOKEN} as a plain env var.

2. github-env-injection: Added sanitization with `printf '%s' "$VAR" | tr -d '\n\r'` before writing SDK_VERSION and LATEST_VERSION to $GITHUB_ENV (lines 30-31) and SDK_VERSION as tag to $GITHUB_OUTPUT (line 71). Values are stored in safe_sdk, safe_latest, and safe_tag before writing.

3. unpinned-uses: Pinned actions/checkout@v2 to full SHA 0717577d45739eb3c851188b29f50ed6c0b2194e in all 4 occurrences in test.yaml; pinned actions/create-release@v1 to full SHA 0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml.

4. missing-permissions: Added top-level `permissions: contents: read` to test.yaml and `permissions: contents: write` to upgrader.yaml (write is required for pushing commits and creating releases).

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed two instances of unquoted $SDK_VERSION in hardened/action/.github/workflows/upgrader.yaml: (1) added double quotes around $SDK_VERSION in the bash [[ ]] conditional on line 54: `if [[ "$SDK_VERSION" =~ ^[0-9]+(\.[0-9]+){2,3}$ ]]`; (2) wrapped the curl URL in double quotes on line 62: `"https://hub.docker.com/v2/repositories/google/cloud-sdk/tags/$SDK_VERSION"`. Both changes prevent shell metacharacters in the variable value from being interpreted by the shell.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Fixed two script injection vulnerabilities:
1. entrypoint.sh line 76: Replaced `eval "$command $*"` with `"$command" "$@"`. The `eval` with `$*` allowed shell metacharacters in the `args` input to inject arbitrary commands. Using `"$command" "$@"` executes the command directly with each argument properly quoted and isolated.
2. upgrader.yaml line 57: Added sed-character escaping for `$LATEST_VERSION` and `$SDK_VERSION` before constructing the sed expression. Added `safe_latest_esc` and `safe_sdk_esc` variables that escape sed special characters (`]`, `/`, `$`, `*`, `.`, `^`, `[`) using `printf '%s' "$VAR" | sed 's/[]\/$*.^[]/\&/g'` before interpolating into the `FROM_LINE`/`TO_LINE` sed pattern, preventing injection from malicious API responses.

