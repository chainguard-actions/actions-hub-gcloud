<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/593.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/593.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): the container entrypoint runs its positional arguments through eval: `eval "$command $*"`. The args come from the caller (for example `with: args:` when the action is used as docker://, or the image's CMD). eval re-parses them as shell code, so metacharacters such as ;, |, &, backticks and $(...) in the args run as commands inside the container. Fix: drop eval and run the command directly with the args as an argument list: `"$command" "$@"`.

Locations:

- `entrypoint.sh:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

entrypoint.sh: replaced `eval "$command $*"` with `"$command" "$@"`, so the container args reach gcloud/gsutil/kubectl as an argv list and are never re-parsed by a shell. This stays POSIX sh, which matters because the image is Alpine, and the shebang is unchanged. action.yml defines no runs.args, so the args come from the runner, which already splits them into separate arguments, or from the Dockerfile's exec-form CMD ["info"]. Normal use keeps the same argument boundaries. Shell syntax inside args (pipes, $VAR, $(...)) is no longer evaluated, and that was the intended fix.

