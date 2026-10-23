<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/590.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/590.0.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

entrypoint.sh line 87 runs the container's arguments through `eval "$command $*"`. eval makes the shell parse the joined argument string again, so any metacharacters in it (`;`, `|`, `$(...)`, backticks) run as commands. action.yml currently sets no runs.args, so the only argument right now is the Dockerfile's default CMD ["info"]. But the upstream design passes the untrusted `inputs.args` here. If the args are wired back in, or someone passes them another way, this becomes command injection. Fix: don't use eval. Run the command with its arguments directly, e.g. `"$command" "$@"`. Sub-rule: shell evaluation of arguments in the entrypoint script.

Locations:

- `entrypoint.sh:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

entrypoint.sh: replaced `eval "$command $*"` with `"$command" "$@"`. For Docker actions, the runner already splits `with: args` into separate arguments (quoted parts stay together), so `"$@"` keeps those arguments as they arrive and the shell no longer re-parses them. The command name is still one of the fixed values gcloud, gsutil or kubectl. The shebang stays POSIX sh, and action.yml and the Dockerfile are unchanged.

