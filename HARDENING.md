<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/592.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/592.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b)-style shell injection in the entrypoint script: `eval "$command $*"` re-parses the container arguments with the shell. The arguments come from the user-supplied `args` input (`with: args`, which GitHub passes to the Docker ENTRYPOINT). Any shell characters in that input (`;`, `|`, `$(...)`, backticks) will be run as commands. A fix is to run the CLI directly with its arguments, e.g. `"$command" "$@"`. Note that this breaks callers who pass all their arguments as one string that relies on word splitting.

Locations:

- `entrypoint.sh:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

entrypoint.sh: replaced `eval "$command $*"` with `"$command" "$@"`. $command can only be gcloud, gsutil or kubectl, and the container args are now passed straight to the CLI. They keep their boundaries and are never evaluated by a shell. The runner already splits `with: args` into separate words before the container starts (it treats double quotes as grouping), so typical usage like `args: app deploy app.yaml` behaves the same. The difference: a caller who relied on eval for shell features inside args (pipes, `;`, `$(...)`, quotes nested inside one word) won't get those any more. Didn't touch the Dockerfile or action.yml. The script is still POSIX sh.

