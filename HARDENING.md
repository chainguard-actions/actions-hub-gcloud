<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/594.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/594.0.1** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

The Docker action's entrypoint script runs its arguments through eval: `eval "$command $*"`. For Docker container actions, the caller's `with: args` value is passed to the ENTRYPOINT as arguments. eval then parses it again as shell code, so any shell metacharacters in it (`;`, `|`, `&&`, `$(...)`, backticks) run as commands. That makes the args value a command-injection point whenever it contains workflow-controlled data such as github.* or inputs.*. Fix: drop eval and run the command with its arguments passed directly as words, e.g. `"$command" "$@"`.

Locations:

- `entrypoint.sh:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

entrypoint.sh: removed `eval "$command $*"`. The image is Alpine with only busybox sh, so the fix stays POSIX. The arguments are now split with quote-aware xargs: `printf '%s' "$*" | xargs -r sh -c 'exec "$0" "$@" <&3' "$command"`, with the original stdin kept on fd 3, plus a check with `xargs -r true` first that fails on an unmatched quote. This keeps upstream's handling of quotes (e.g. --format='value(...)') but no longer evaluates ;, |, $(...), backticks or $VARs, which now reach gcloud/gsutil/kubectl as literal text. Behaviour changes: shell pipes, redirects and $VAR expansion inside args stop working, and a failing command gives xargs's exit code (123 or 124) instead of its own, though the step still fails. Also pinned the Dockerfile base image google/cloud-sdk:594.0.0-alpine to its sha256 digest, keeping the tag inline. action.yml args left unchanged.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

entrypoint.sh: removed the `xargs ... <&3` construct, where the redirect bound to xargs. The script now tokenizes the args quote-aware with xargs, which only feeds a helper that prints each token as a single-quoted, escaped shell word. The positional parameters are rebuilt with `eval "set -- $quoted"`; that eval only sees single-quoted literals, so nothing in a token gets evaluated. Then `exec "$command" "$@"` runs with the container's normal stdin. The unmatched-quote check (`xargs -r true`) stays. Everything is POSIX sh because the Alpine image has no bash.

