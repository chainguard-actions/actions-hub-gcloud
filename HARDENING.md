<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/588.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/588.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

entrypoint.sh line 80 uses `eval "$command $*"` where `$command` is derived from the inherited environment variables `$CLI` and `$INPUT_CLI` (set by the calling workflow — untrusted), and `$*` expands all positional arguments passed to the Docker entrypoint (sourced from `inputs.args`). Both variables are unquoted inside `eval`, allowing an attacker to inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) via the `args` or `cli` inputs to execute arbitrary commands. This violates rule (b): unquoted shell variable expansion of untrusted/workflow-controllable data. The fix is to avoid `eval` entirely and invoke the command directly with properly quoted arguments, e.g. `"$command" "$@"`.

Locations:

- `entrypoint.sh:80`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Replaced `eval "$command $*"` with `"$command" "$@"` in entrypoint.sh line 80. This eliminates the eval-based shell injection vulnerability: `eval` was interpreting shell metacharacters (`;`, `|`, `&`, `$(...)`) in both `$command` (derived from untrusted `$CLI`/`$INPUT_CLI` env vars) and `$*` (from untrusted `inputs.args`). The fix uses direct invocation with `"$command"` (quoted, single word) and `"$@"` (each positional arg separately quoted), which is safe and POSIX-compatible with the existing `#!/bin/sh` shebang.

