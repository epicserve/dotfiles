#!/usr/bin/sh
# Install / update the Stripe CLI from Stripe's official GitHub release.
#
# Sourced by setup_omarchy.sh, but also runnable directly to update on demand:
#   sh ~/.dotfiles/scripts/setup_stripe_cli.sh
#
# We deliberately avoid the AUR package: stripe-cli was swept up in the June 2026
# "Atomic Arch" AUR supply-chain incident (orphaned, then adopted by an untrusted
# account during the attack window). Instead we pull the binary Stripe's own CI
# publishes and verify its SHA-256 against Stripe's checksums file before
# installing, so the install never trusts the AUR maintainer chain.
#
# Idempotent + self-updating: compares the installed version against the latest
# GitHub release and only downloads when they differ. (Unlike the install-only
# tools in base_linux_setup.sh, re-running this picks up new releases.)

INSTALL_PATH=/usr/local/bin/stripe

# Map `uname -m` to the arch string Stripe uses in its release asset names.
case "$(uname -m)" in
  x86_64) STRIPE_ARCH=x86_64 ;;
  aarch64 | arm64) STRIPE_ARCH=arm64 ;;
  *) echo "stripe-cli: unsupported architecture $(uname -m), skipping"; return 0 2>/dev/null || exit 0 ;;
esac

# Latest release tag, e.g. v1.42.14 -> 1.42.14 (same grep/cut idiom as base_linux_setup.sh).
LATEST=$(curl -s https://api.github.com/repos/stripe/stripe-cli/releases/latest | grep 'tag_name' | cut -d '"' -f4)
LATEST=${LATEST#v}
if [ -z "$LATEST" ]; then
  echo "stripe-cli: failed to fetch latest release tag, skipping"
  return 0 2>/dev/null || exit 0
fi

# `stripe version` prints "stripe version 1.42.14" (sometimes with extra lines like
# "Checking for new versions..."), so pull the first semver out of its output.
# CURRENT is empty if stripe isn't installed.
CURRENT=$(stripe version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
if [ "$CURRENT" = "$LATEST" ]; then
  echo "stripe-cli: already up to date ($CURRENT)"
  return 0 2>/dev/null || exit 0
fi

# Drop the AUR package if it's still installed, so it can't shadow the official
# binary on PATH or get pulled forward by a future `yay -Syu`.
if pacman -Q stripe-cli >/dev/null 2>&1; then
  echo "stripe-cli: removing AUR package in favor of the official binary..."
  sudo pacman -Rns --noconfirm stripe-cli
fi

echo "stripe-cli: installing ${LATEST} (was: ${CURRENT:-not installed})"
TARBALL="stripe_${LATEST}_linux_${STRIPE_ARCH}.tar.gz"
BASE_URL="https://github.com/stripe/stripe-cli/releases/download/v${LATEST}"
TMP=$(mktemp -d)

if curl -fsSL "$BASE_URL/$TARBALL" -o "$TMP/$TARBALL" &&
   curl -fsSL "$BASE_URL/stripe-linux-checksums.txt" -o "$TMP/checksums.txt"; then
  # Verify the download against Stripe's published SHA-256 before trusting it.
  # --ignore-missing: the checksums file lists every platform; we only fetched one.
  if (cd "$TMP" && sha256sum --ignore-missing --quiet -c checksums.txt); then
    tar -xzf "$TMP/$TARBALL" -C "$TMP"
    sudo install -Dm755 "$TMP/stripe" "$INSTALL_PATH"
    hash -r 2>/dev/null || true
    echo "stripe-cli: installed $(stripe version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1) to $INSTALL_PATH"
  else
    echo "stripe-cli: CHECKSUM VERIFICATION FAILED -- aborting install"
  fi
else
  echo "stripe-cli: download failed, skipping"
fi
rm -rf "$TMP"
