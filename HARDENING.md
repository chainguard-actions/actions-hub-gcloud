<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/570.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/570.0.0** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Workflow files reference actions by mutable version tags instead of full 40-character commit SHAs. In test.yaml, 'actions/checkout@v2' is used in all four jobs. In upgrader.yaml, 'actions/create-release@v1' is used. These tags can be moved to point to different (potentially malicious) commits at any time, enabling supply-chain attacks.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:21`
- `.github/workflows/test.yaml:33`
- `.github/workflows/test.yaml:46`
- `.github/workflows/upgrader.yaml:83`

### permissions (severity: medium)

Neither workflow file defines a top-level 'permissions:' key, and no individual job defines job-level permissions. Without explicit permissions, workflows run with the default (potentially broad) token permissions. Both test.yaml and upgrader.yaml are affected.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### script-injection (severity: high)

Sub-rule (a): ${{ secrets.GH_TOKEN }} is interpolated directly inside run: shell command strings in upgrader.yaml. Although secrets are not attacker-controlled, any ${{ ... }} expression interpolated directly into a run: block is a script-injection risk — the value is substituted into the shell command before the shell parses it, meaning special characters in the secret value could alter the command. Affected lines: 'git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/"...' appears in both the 'Checkout repo' step (line 13) and the 'Modify Dockerfile' step (line 68).

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:68`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step writes SDK_VERSION and LATEST_VERSION — values derived from external HTTP responses (curl to Docker Hub and GitHub API) — directly to $GITHUB_ENV and $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'). A malicious response from those endpoints could inject newlines to poison the environment file. Similarly, the 'Modify Dockerfile' step writes 'tag=${SDK_VERSION}' to $GITHUB_OUTPUT without sanitization. Affected writes: 'echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV' (line 30), 'echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV' (line 31), and 'echo "tag=${SDK_VERSION}" >> $GITHUB_OUTPUT' (line 80).

Locations:

- `.github/workflows/upgrader.yaml:30`
- `.github/workflows/upgrader.yaml:31`
- `.github/workflows/upgrader.yaml:80`

### suspicious-run-content (severity: high)

Sub-check: eval-dynamic. In entrypoint.sh, the final command is 'eval "$command $*"', which uses eval with a shell variable ($command) and all positional arguments ($*). This matches the eval-dynamic pattern (eval followed by a shell variable/expansion). An attacker who controls the arguments passed to the Docker entrypoint (via the action's 'args' input) can inject arbitrary shell commands through $*, since $* is not quoted per-word and eval will parse metacharacters in the expanded string.

Locations:

- `entrypoint.sh:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, permissions, script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all 5 findings:
1. unpinned-uses: Pinned actions/checkout@v2 → @0717577d45739eb3c851188b29f50ed6c0b2194e in all 4 jobs in test.yaml; pinned actions/create-release@v1 → @0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml.
2. permissions: Added `permissions: {}` top-level block to both test.yaml and upgrader.yaml.
3. script-injection: Moved ${{ secrets.GH_TOKEN }} out of run: blocks in upgrader.yaml (both 'Checkout repo' and 'Modify Dockerfile' steps) into env: blocks, referenced as ${GH_TOKEN} in shell.
4. github-env-injection: Added `printf '%s' "$VAR" | tr -d '\n\r'` sanitization before writing SDK_VERSION and LATEST_VERSION to $GITHUB_ENV, and before writing tag to $GITHUB_OUTPUT in upgrader.yaml.
5. suspicious-run-content (eval-dynamic): Replaced `eval "$command $*"` with `"$command" "$@"` in entrypoint.sh to eliminate eval and use properly quoted positional arguments.

