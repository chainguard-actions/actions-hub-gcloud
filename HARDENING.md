<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/574.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **actions-hub--gcloud/574.0.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In entrypoint.sh, the line `eval "$command $*"` passes user-controlled input directly to eval. The positional parameters `$*` come from `inputs.args` (the Docker CMD), and `$command` is derived from `inputs.cli` (via $CLI/$INPUT_CLI). Because `$*` is expanded unquoted inside the eval string, an attacker can inject arbitrary shell commands through the `args` input. For example, an `args` value of `info; malicious-command` would be executed by the shell. The correct fix is to avoid eval entirely and use `$command "$@"` instead, which preserves argument boundaries without shell re-parsing.

Locations:

- `entrypoint.sh:79`

### suspicious-run-content (severity: high)

Sub-check eval-dynamic: The entrypoint.sh script uses `eval "$command $*"` where `$*` is a shell variable expansion of all positional arguments (user-supplied via inputs.args). User-controlled data is dynamically constructed and executed as a shell command via eval, enabling arbitrary command injection. Matching pattern: eval followed by a double-quoted string containing unquoted $* expansion.

Locations:

- `entrypoint.sh:79`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, suspicious-run-content

**Notes:**

Replaced `eval "$command $*"` with `$command "$@"` in entrypoint.sh line 79. The original code used eval with unquoted $* expansion, allowing user-controlled positional parameters (from inputs.args) to inject arbitrary shell commands. The fix avoids eval entirely and uses "$@" which preserves argument boundaries without shell re-parsing, preventing command injection.

