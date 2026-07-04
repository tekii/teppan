#!/usr/bin/env bash
# Launch VS Code with GH_TOKEN pulled from the GNOME keyring (Secret Service),
# so the dev container receives it via devcontainer.json's ${localEnv:GH_TOKEN}.
#
# Store the token once (paste it, Enter, Ctrl-D):
#   secret-tool store --label='tekii/teppan gh PAT' service gh-token account tekii-www
# Manage it in Seahorse: Passwords -> Login -> "tekii/teppan gh PAT".

GH_TOKEN="$(secret-tool lookup service gh-token account tekii-www 2>/dev/null || true)"
if [ -z "${GH_TOKEN}" ]; then
  echo "code-with-gh-token: no token found in the keyring" >&2
  echo "  (service=gh-token account=tekii-www) -- is the keyring unlocked?" >&2
  echo "  store it with:" >&2
  echo "    secret-tool store --label='tekii/teppan gh PAT' service gh-token account tekii-www" >&2
  exit 1
fi
export GH_TOKEN
exec code "$@"
