<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/591.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/591.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a)/(b): entrypoint.sh line 87 runs the container arguments through eval: `eval "$command $*"`. Those arguments come from the action's `args` input, which the calling workflow can control. Because eval re-parses them, shell metacharacters such as `;`, `|`, `$(...)` and backticks are executed as commands. Fix: drop eval and run the command directly with its arguments quoted, e.g. `"$command" "$@"`.

Locations:

- `entrypoint.sh:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

I removed `eval "$command $*"` from entrypoint.sh. The script now joins the container arguments and splits them into words with xargs, which honors quotes the same way eval did. It checks for an unmatched quote first, so the step fails instead of silently losing arguments. The words are loaded back into the positional parameters with `set --`, and the command runs as `"$command" "$@"`. Shell characters in the arguments (`;`, `|`, `$(...)`, backticks) are now passed through as plain text and never executed. I kept the script POSIX sh because the image is Alpine (busybox, no bash), and I didn't change the shebang. Nothing was run to test it. One difference from upstream: an argument can no longer contain a newline. The suggested fix, plain `"$command" "$@"`, would have kept quotes inside an argument as literal text. eval used to remove them, so arguments like `--format='value(x)'` would have broken.

