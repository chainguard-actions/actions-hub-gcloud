<!-- markdownlint-disable -->

# Hardening Report: actions-hub--gcloud/594.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **actions-hub--gcloud/594.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Docker action entrypoint runs its arguments through eval. The workflow-controlled `args` input reaches the container as positional arguments, and entrypoint.sh line 87 runs `eval "$command $*"`. Because eval joins the arguments and parses them again as shell code, any shell metacharacters in the input (`;`, `|`, `&`, backticks, `$(...)`) run as commands inside the container. This is rule (b): workflow-controlled data gets shell expansion. Fix: run the command directly with `"$command" "$@"` and drop eval.

Locations:

- `entrypoint.sh:87`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

entrypoint.sh no longer uses eval. It joins the positional arguments the same way upstream's "$*" did, then splits them with the quote-aware xargs method (one 'xargs -r true' check first, then the built-in printf through sh -c, read in a NUL-delimited loop). Quoted arguments are split the same way eval split them, but ';', '|', '&', backticks and $(...) now reach the command as plain text and are never run. The command now runs as "$command" "${cli_args[@]}". The 'beta' check looks at the first parsed argument instead of $1. The shebang is now #!/bin/bash because the split needs arrays and process substitution. bash already ships in the google/cloud-sdk alpine base image, and the Dockerfile also gets a safety line ('command -v bash || apk add --no-cache bash') in case it is missing. action.yml is unchanged.

