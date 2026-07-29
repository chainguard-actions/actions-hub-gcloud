<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/578.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/578.0.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Workflow files reference actions by mutable tags instead of full 40-character commit SHAs. In test.yaml, `actions/checkout@v2` is used in all four jobs. In upgrader.yaml, `actions/create-release@v1` is used. These mutable refs can be silently redirected to malicious code via tag mutation.

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/test.yaml:21`
- `.github/workflows/test.yaml:32`
- `.github/workflows/test.yaml:45`
- `.github/workflows/upgrader.yaml:86`

### permissions (severity: medium)

Neither test.yaml nor upgrader.yaml defines a top-level `permissions:` key, and no job within either file defines its own `permissions:` block. This means workflows run with the default (broad) repository permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

### script-injection (severity: high)

Sub-rule (a): `${{ secrets.GH_TOKEN }}` is directly interpolated inside `run:` shell command strings in upgrader.yaml. In the 'Checkout repo' step: `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/"...` and in the 'Modify Dockerfile' step the same pattern appears. Any `${{ ... }}` expression interpolated directly into a `run:` block is a script-injection risk because the value is substituted into the shell command string before the shell parses it, allowing special characters to be interpreted.

Locations:

- `.github/workflows/upgrader.yaml:13`
- `.github/workflows/upgrader.yaml:68`

### github-env-injection (severity: high)

In upgrader.yaml's 'Check if new version exist' step, `SDK_VERSION` and `LATEST_VERSION` are populated from external curl calls to Docker Hub and the GitHub API (untrusted external data). These values are then written directly to `$GITHUB_ENV` and `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A malicious response from either API could inject newlines to poison the environment file, enabling environment variable injection into subsequent steps. Affected lines: `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV`, `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV`, `echo "newest=yes" >> $GITHUB_OUTPUT`, and `echo "tag=${SDK_VERSION}" >> $GITHUB_OUTPUT` in the Modify Dockerfile step.

Locations:

- `.github/workflows/upgrader.yaml:31`
- `.github/workflows/upgrader.yaml:32`
- `.github/workflows/upgrader.yaml:33`
- `.github/workflows/upgrader.yaml:83`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, permissions, script-injection, github-env-injection

**Notes:**

Fixed all four findings across test.yaml and upgrader.yaml:

1. unpinned-uses: Pinned actions/checkout@v2 to SHA 0717577d45739eb3c851188b29f50ed6c0b2194e in all 4 jobs in test.yaml, and pinned actions/create-release@v1 to SHA 0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e in upgrader.yaml.

2. permissions: Added `permissions: {}` to test.yaml (no write access needed) and `permissions: contents: write` to upgrader.yaml (needed to push commits and create releases).

3. script-injection: In upgrader.yaml, moved `${{ secrets.GH_TOKEN }}` out of both `run:` blocks ('Checkout repo' and 'Modify Dockerfile' steps) into `env:` blocks as `GH_TOKEN`, then referenced as `${GH_TOKEN}` in the shell scripts.

4. github-env-injection: In upgrader.yaml's 'Check if new version exist' step, sanitized SDK_VERSION and LATEST_VERSION with `printf '%s' "$VAR" | tr -d '\n\r'` before writing to $GITHUB_ENV. In the 'Modify Dockerfile' step, sanitized SDK_VERSION before writing as the `tag` output to $GITHUB_OUTPUT.

