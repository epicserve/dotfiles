#!/usr/bin/sh
# Purge the AUR stripe-cli package if present so it cannot shadow mise's install.
#
# Stripe itself is installed by mise (aqua:stripe/stripe-cli — official GitHub
# releases, not the AUR). We still refuse the AUR package: stripe-cli was swept
# up in the June 2026 "Atomic Arch" AUR supply-chain incident.
#
# Sourced by setup_omarchy.sh, but also runnable directly:
#   sh ~/.dotfiles/scripts/setup_stripe_cli.sh

if command -v pacman >/dev/null 2>&1 && pacman -Q stripe-cli >/dev/null 2>&1; then
  echo "stripe-cli: removing AUR package in favor of mise..."
  sudo pacman -Rns --noconfirm stripe-cli
fi
