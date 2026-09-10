# Sourced from ~/.zshenv, so it runs for every zsh, including the non-interactive
# SSH commands Herdr uses to start its remote server.
#
# Shells inside herdr are children of the herdr server, not of the
# SSH session, so they never see the per-connection SSH_AUTH_SOCK. Publish a
# forwarded agent at a stable path; omarchy_overrides.sh prefers it while it
# answers and falls back to the local 1Password agent otherwise.
if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}" ] && [ -n "${SSH_AUTH_SOCK:-}" ] \
   && [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.1password/agent.sock" ]; then
  ln -snf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
fi
