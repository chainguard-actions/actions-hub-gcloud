<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/572.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/572.0.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Workflow files reference actions by mutable version tags instead of pinned full-length commit SHAs. In test.yaml, 'actions/checkout@v2' is used in all four jobs (lines 9, 21, 32, 46). In upgrader.yaml, 'actions/create-release@v1' is used (line 88). These tags can be moved to point to different (potentially malicious) commits at any time, enabling supply-chain attacks.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:21`
- `.github/workflows/test.yaml:32`
- `.github/workflows/test.yaml:46`
- `.github/workflows/upgrader.yaml:88`

### missing-permissions (severity: medium)

Neither workflow file defines a top-level 'permissions:' key, and no individual job defines its own 'permissions:' block. Without explicit permissions, workflows run with the default (often write-all) token permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### script-injection (severity: high)

Sub-rule (a): GitHub Actions expressions are interpolated directly inside run: shell command strings in upgrader.yaml. Line 13: `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf ...` and line 75 (same pattern in the 'Modify Dockerfile' step). Even though secrets.* is not attacker-controlled, any ${{ }} expression inside a run: block undergoes YAML template substitution before the shell sees it, bypassing shell quoting and enabling injection if the value contains shell metacharacters.

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:75`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step writes SDK_VERSION and LATEST_VERSION to $GITHUB_ENV, and the 'Modify Dockerfile' step writes SDK_VERSION to $GITHUB_OUTPUT — all without the required sanitization step (printf '%s' "$VAR" | tr -d '\n\r'). These variables are derived from external HTTP responses (curl to Docker Hub and GitHub API), making them untrusted. A malicious response could inject newlines to poison GITHUB_ENV or GITHUB_OUTPUT with attacker-controlled key-value pairs, affecting subsequent steps. Affected lines: `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV` (line 30), `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV` (line 31), and `echo "tag=${SDK_VERSION}" >> $GITHUB_OUTPUT` (line 84).

Locations:

- `.github/workflows/upgrader.yaml:30`
- `.github/workflows/upgrader.yaml:31`
- `.github/workflows/upgrader.yaml:84`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection, github-env-injection

**Notes:**

Fixed all four findings across test.yaml and upgrader.yaml:

1. unpinned-uses: Pinned actions/checkout@v2 → @0717577d45739eb3c851188b29f50ed6c0b2194e in all 4 jobs in test.yaml; pinned actions/create-release@v1 → @0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml.

2. missing-permissions: Added 'permissions: {}' top-level block to both test.yaml and upgrader.yaml.

3. script-injection: In upgrader.yaml, moved ${{ secrets.GH_TOKEN }} out of run: shell strings into step-level env: blocks (as GH_TOKEN), then referenced as ${GH_TOKEN} in the shell. Applied to both 'Checkout repo' and 'Modify Dockerfile' steps.

4. github-env-injection: In upgrader.yaml, sanitized SDK_VERSION and LATEST_VERSION with 'printf | tr -d' before writing to $GITHUB_ENV (lines 30-31), and sanitized SDK_VERSION before writing to $GITHUB_OUTPUT (line 84).

