<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/572.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **actions-hub--gcloud/572.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In entrypoint.sh, the final command `eval "$command $*"` passes all positional arguments (`$*`) — which originate from the user-controlled `inputs.args` action input — directly to `eval` without quoting or sanitization. An attacker can supply shell metacharacters (`;`, `&&`, `|`, `$(...)`, etc.) in `inputs.args` to execute arbitrary shell commands inside the runner. The `$command` variable (from `inputs.cli`) is also unquoted in the eval string. The fix is to avoid `eval` entirely and use `"$command" "$@"` instead, which preserves argument boundaries without shell re-parsing.

Locations:

- `entrypoint.sh:80`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed script injection vulnerability in entrypoint.sh line 80: replaced `eval "$command $*"` with `"$command" "$@"`. The `eval` form concatenated all positional arguments into a single string and re-parsed it through the shell, allowing attacker-controlled `inputs.args` values containing shell metacharacters (`;`, `&&`, `|`, `$(...)`, etc.) to execute arbitrary commands. The replacement `"$command" "$@"` directly executes the command with each argument as a separate, properly-quoted word, preserving argument boundaries without shell re-parsing.

