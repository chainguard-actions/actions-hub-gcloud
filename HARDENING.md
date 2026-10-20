<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/590.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/590.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a) via the Docker entrypoint. The action is built from a local Dockerfile whose ENTRYPOINT is ["/entrypoint.sh"]. The script passes all of its arguments, which come from the workflow-controlled `with: args` input, to the shell's eval: `eval "$command $*"`. The shell re-parses the joined text, so characters like `;`, `|`, `&&` and `$(...)` in args run as extra commands inside the container. A safer approach is to run the command directly with the arguments quoted, e.g. `"$command" "$@"`, and not use eval.

Locations:

- `entrypoint.sh:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

entrypoint.sh: replaced `eval "$command $*"` with `"$command" "$@"`. The runner already splits the docker args into separate argv entries and honors quotes, so the arguments reach gcloud, gsutil or kubectl unchanged and the shell never re-parses them. The script is still POSIX sh, which matters because the alpine image ships no bash. The Dockerfile and action.yml are unchanged. One behavior change: shell syntax inside args (like $VAR or $(...)) is no longer expanded inside the container.

