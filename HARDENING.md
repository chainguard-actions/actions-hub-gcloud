<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/586.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/586.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): `entrypoint.sh` uses `eval "$command $*"` where `$*` expands all positional arguments (sourced from `inputs.args`, a required user-controlled input) unquoted into `eval`. This allows an attacker to inject arbitrary shell commands via the `args` input. The offending line is: `eval "$command $*"`. The value should at minimum be double-quoted (`eval "$command" "$@"`) and ideally passed directly without `eval`.

Locations:

- `entrypoint.sh:80`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Replaced `eval "$command $*"` with `"$command" "$@"` on line 80 of entrypoint.sh. This removes the eval-based shell injection vector: eval is eliminated entirely (no re-parsing of the command string), and $* (unquoted expansion of all args into a single string) is replaced with "$@" (each argument preserved as a separate quoted word). The fix is POSIX-compatible and safe for the Alpine/busybox sh environment used by the Docker action.

