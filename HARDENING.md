<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/575.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/575.0.1** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Two `run:` blocks in upgrader.yaml directly interpolate `${{ secrets.GH_TOKEN }}` into shell commands. Per the script-injection check, ANY `${{ ... }}` expression inside a `run:` block is a violation (sub-rule a), regardless of the context it reads from. The offending lines are:
  - `git config --global url."https://${{ secrets.GH_TOKEN }}:@github.com/".insteadOf "https://github.com/"` (Checkout repo step, ~line 10)
  - Same pattern repeated in the Modify Dockerfile step (~line 76)

Locations:

- `.github/workflows/upgrader.yaml:10`
- `.github/workflows/upgrader.yaml:76`

### github-env-injection (severity: high)

In upgrader.yaml, the 'Check if new version exist' step writes `SDK_VERSION` and `LATEST_VERSION` — values derived from external curl API responses (Docker Hub and GitHub API, i.e. untrusted network data) — directly to `$GITHUB_ENV` without sanitization (`printf '%s' ... | tr -d '\n\r'` is never applied). An attacker who can influence the Docker Hub or GitHub API response could inject arbitrary environment variable values. Offending lines:
  `echo "SDK_VERSION=${SDK_VERSION}" >> $GITHUB_ENV`
  `echo "LATEST_VERSION=${LATEST_VERSION}" >> $GITHUB_ENV`

Locations:

- `.github/workflows/upgrader.yaml:37`
- `.github/workflows/upgrader.yaml:38`

### unpinned-uses (severity: high)

Multiple `uses:` references use mutable tags instead of full 40-character commit SHAs, making the workflow vulnerable to supply-chain attacks if the referenced tag is moved or overwritten:
  - `actions/checkout@v2` (test.yaml, all four jobs)
  - `actions/create-release@v1` (upgrader.yaml)

Locations:

- `.github/workflows/test.yaml:9`
- `.github/workflows/upgrader.yaml:96`

### missing-permissions (severity: medium)

Neither `test.yaml` nor `upgrader.yaml` declares a top-level `permissions:` block, and no individual job within either file declares job-level `permissions:`. Without explicit permissions, workflows run with the default (potentially broad) token permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/test.yaml:1`
- `.github/workflows/upgrader.yaml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all four findings across both workflow files:

1. script-injection (upgrader.yaml): Moved `${{ secrets.GH_TOKEN }}` from two `run:` blocks into `env:` blocks as `GH_TOKEN`, referenced as `${GH_TOKEN}` in shell scripts.

2. github-env-injection (upgrader.yaml): Added `printf '%s' "$VAR" | tr -d '\n\r'` sanitization for SDK_VERSION and LATEST_VERSION before writing to $GITHUB_ENV.

3. unpinned-uses: Pinned actions/checkout@v2 → @ee0669bd1cc54295c223e0bb666b733df41de1c5 (all 4 jobs in test.yaml) and actions/create-release@v1 → @0cb9c9b65d5d1901c1f53e5e66eaf4afd303e70e (upgrader.yaml). SHA comments preserved for readability.

4. missing-permissions: Added top-level `permissions: contents: read` to test.yaml and `permissions: contents: write` to upgrader.yaml (write needed for git push and release creation).

### Iteration 2

**Fixes applied:** script-injection, suspicious-run-content, github-env-injection

**Notes:**

1. entrypoint.sh line 79: Replaced `eval "$command $*"` with `"$command" "$@"`. This eliminates the dangerous eval entirely — the command is now invoked directly as a quoted variable (preventing word-splitting on the command name), and `"$@"` passes each positional argument as a separate properly-quoted word, preventing shell injection from user-controlled inputs.args. 2. upgrader.yaml line 88 (Modify Dockerfile step): Added sanitization of SDK_VERSION before writing to GITHUB_OUTPUT: `safe_tag=$(printf '%s' "$SDK_VERSION" | tr -d '\n\r')` then `echo "tag=${safe_tag}" >> $GITHUB_OUTPUT`. This strips embedded newlines that could allow a maliciously crafted Docker Hub tag name to inject additional key=value pairs into the GitHub output context.

