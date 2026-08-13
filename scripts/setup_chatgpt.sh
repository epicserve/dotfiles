#!/usr/bin/env bash

# Install or update OpenAI's official ChatGPT Linux app on Omarchy/Arch.
# OpenAI publishes deb/rpm packages but no native Arch package, so this script
# verifies the signed RPM repository metadata and repackages the RPM for pacman.

set -euo pipefail

readonly CHATGPT_REPO_URL="https://persistent.oaistatic.com/codex-app-prod/linux/rpm/x86_64"
readonly OPENAI_KEY_FINGERPRINT="3BFA0E4AE8B8CC16A2D9BA684A3B4A566C4660E4"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly OPENAI_KEY_FILE="$DOTFILES_DIR/config/chatgpt/openai-linux-repository.asc"

readonly -a BUILD_DEPENDENCIES=(
  base-devel
  libarchive
)

readonly -a RUNTIME_DEPENDENCIES=(
  alsa-lib
  at-spi2-core
  cairo
  dbus
  expat
  gdk-pixbuf2
  glib2
  glibc
  gtk3
  libcups
  libdrm
  libgcc
  libglvnd
  libnotify
  libsecret
  libusb
  libx11
  libxcb
  libxcomposite
  libxdamage
  libxext
  libxfixes
  libxkbcommon
  libxrandr
  mesa
  nspr
  nss
  openssl
  pango
  systemd-libs
  xdg-utils
)

check_only=false
force=false

usage() {
  cat <<'EOF'
Usage: setup_chatgpt.sh [--check] [--force]

Install or update the official ChatGPT Linux app as a native Arch package.

  --check  Report whether an update is available without installing it
  --force  Rebuild and reinstall even when the installed version is current
  --help   Show this help
EOF
}

while (($#)); do
  case "$1" in
    --check)
      check_only=true
      ;;
    --force)
      force=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if $check_only && $force; then
  printf '%s\n' '--check and --force cannot be used together.' >&2
  exit 2
fi

if [[ $(uname -m) != x86_64 ]]; then
  printf 'ChatGPT updater currently supports only x86_64 Omarchy systems.\n' >&2
  exit 1
fi

if ! command -v omarchy >/dev/null 2>&1; then
  printf 'This updater requires Omarchy.\n' >&2
  exit 1
fi

if [[ ! -r $OPENAI_KEY_FILE ]]; then
  printf 'OpenAI repository key is missing: %s\n' "$OPENAI_KEY_FILE" >&2
  exit 1
fi

# These are inexpensive no-ops when already installed. Use Omarchy's package
# helper so a fresh system gets the tools needed to authenticate repository
# metadata. Build and runtime dependencies are deferred until an update exists.
omarchy pkg add curl gnupg gzip libxml2

for command_name in curl gpg gpgv gzip sha256sum xmllint bsdtar makepkg vercmp pacman; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command is unavailable after dependency setup: %s\n' "$command_name" >&2
    exit 1
  fi
done

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/chatgpt-updater.XXXXXX")
cleanup() {
  rm -rf -- "$work_dir"
}
trap cleanup EXIT INT TERM

curl_metadata() {
  curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry 3 \
    --retry-all-errors \
    --connect-timeout 15 \
    --max-time 120 \
    "$@"
}

printf 'Checking OpenAI repository metadata...\n'

key_fingerprint=$(
  gpg --batch --no-autostart --show-keys --with-colons "$OPENAI_KEY_FILE" 2>/dev/null |
    awk -F: '$1 == "fpr" { print $10; exit }'
)
if [[ $key_fingerprint != "$OPENAI_KEY_FINGERPRINT" ]]; then
  printf 'OpenAI repository key fingerprint mismatch.\n' >&2
  exit 1
fi

gpg --batch --yes --dearmor \
  --output "$work_dir/openai-linux-repository.gpg" \
  "$OPENAI_KEY_FILE"

curl_metadata \
  --output "$work_dir/repomd.xml" \
  "$CHATGPT_REPO_URL/repodata/repomd.xml"
curl_metadata \
  --output "$work_dir/repomd.xml.asc" \
  "$CHATGPT_REPO_URL/repodata/repomd.xml.asc"

gpgv \
  --keyring "$work_dir/openai-linux-repository.gpg" \
  "$work_dir/repomd.xml.asc" \
  "$work_dir/repomd.xml"

primary_href=$(
  xmllint --xpath \
    'string(/*[local-name()="repomd"]/*[local-name()="data"][@type="primary"]/*[local-name()="location"]/@href)' \
    "$work_dir/repomd.xml"
)
primary_checksum=$(
  xmllint --xpath \
    'string(/*[local-name()="repomd"]/*[local-name()="data"][@type="primary"]/*[local-name()="checksum"][@type="sha256"])' \
    "$work_dir/repomd.xml"
)

if [[ ! $primary_href =~ ^repodata/[0-9a-f]{64}-primary\.xml\.gz$ ]] ||
  [[ ! $primary_checksum =~ ^[0-9a-f]{64}$ ]]; then
  printf 'OpenAI repository metadata contains an unexpected primary record.\n' >&2
  exit 1
fi

curl_metadata \
  --output "$work_dir/primary.xml.gz" \
  "$CHATGPT_REPO_URL/$primary_href"
printf '%s  %s\n' "$primary_checksum" "$work_dir/primary.xml.gz" |
  sha256sum --check --status
gzip -dc "$work_dir/primary.xml.gz" >"$work_dir/primary.xml"

package_xpath='/*[local-name()="metadata"]/*[local-name()="package"][*[local-name()="name"]="chatgpt" and *[local-name()="arch"]="x86_64"]'
remote_version=$(
  xmllint --xpath "string($package_xpath/*[local-name()=\"version\"]/@ver)" "$work_dir/primary.xml"
)
remote_release=$(
  xmllint --xpath "string($package_xpath/*[local-name()=\"version\"]/@rel)" "$work_dir/primary.xml"
)
rpm_checksum=$(
  xmllint --xpath "string($package_xpath/*[local-name()=\"checksum\"][@type=\"sha256\"])" "$work_dir/primary.xml"
)
rpm_href=$(
  xmllint --xpath "string($package_xpath/*[local-name()=\"location\"]/@href)" "$work_dir/primary.xml"
)

if [[ ! $remote_version =~ ^[0-9][0-9A-Za-z._+]*$ ]] ||
  [[ ! $remote_release =~ ^[0-9][0-9A-Za-z._+]*$ ]] ||
  [[ ! $rpm_checksum =~ ^[0-9a-f]{64}$ ]] ||
  [[ ! $rpm_href =~ ^chatgpt-[0-9A-Za-z._+-]+\.x86_64\.rpm$ ]]; then
  printf 'OpenAI repository metadata contains an unexpected ChatGPT package record.\n' >&2
  exit 1
fi

remote_package_version="$remote_version-$remote_release"
installed_version=''
if installed_package=$(pacman -Q chatgpt-bin 2>/dev/null); then
  installed_version=${installed_package#* }
fi

if [[ -n $installed_version ]] && ! $force; then
  comparison=$(vercmp "$installed_version" "$remote_package_version")
  if ((comparison >= 0)); then
    if ((comparison == 0)); then
      printf 'ChatGPT is current: %s\n' "$installed_version"
    else
      printf 'Installed ChatGPT %s is newer than repository version %s; leaving it unchanged.\n' \
        "$installed_version" "$remote_package_version"
    fi
    exit 0
  fi
fi

if [[ -n $installed_version ]]; then
  printf 'ChatGPT update available: %s -> %s\n' "$installed_version" "$remote_package_version"
else
  printf 'ChatGPT is not installed; version %s is available.\n' "$remote_package_version"
fi

if $check_only; then
  exit 0
fi

if pgrep -x ChatGPT >/dev/null 2>&1; then
  printf 'Quit ChatGPT before installing version %s, then rerun this updater.\n' \
    "$remote_package_version" >&2
  exit 1
fi

omarchy pkg add "${BUILD_DEPENDENCIES[@]}" "${RUNTIME_DEPENDENCIES[@]}"

printf 'Downloading ChatGPT %s...\n' "$remote_package_version"
curl \
  --fail \
  --show-error \
  --location \
  --retry 3 \
  --retry-all-errors \
  --connect-timeout 20 \
  --output "$work_dir/$rpm_href" \
  "$CHATGPT_REPO_URL/$rpm_href"
printf '%s  %s\n' "$rpm_checksum" "$work_dir/$rpm_href" |
  sha256sum --check --status

cat >"$work_dir/PKGBUILD" <<EOF
pkgname=chatgpt-bin
pkgver=$remote_version
pkgrel=$remote_release
pkgdesc="Official ChatGPT desktop app"
arch=('x86_64')
url="https://chatgpt.com/download/"
license=('custom')

depends=(
  'alsa-lib' 'at-spi2-core' 'cairo' 'dbus' 'expat'
  'gdk-pixbuf2' 'glib2' 'glibc' 'gtk3' 'libcups' 'libdrm'
  'libgcc' 'libglvnd' 'libnotify' 'libsecret' 'libusb' 'libx11'
  'libxcb' 'libxcomposite' 'libxdamage' 'libxext' 'libxfixes'
  'libxkbcommon' 'libxrandr' 'mesa' 'nspr' 'nss' 'openssl'
  'pango' 'systemd-libs' 'xdg-utils'
)

optdepends=('git: local repository support')
provides=('chatgpt')
conflicts=('chatgpt')
options=('!strip' '!debug')

source=('$rpm_href')
noextract=('$rpm_href')
sha256sums=('$rpm_checksum')

package() {
  bsdtar -xf "\$srcdir/$rpm_href" -C "\$pkgdir"
}
EOF

printf 'Building native Arch package...\n'
(
  cd "$work_dir"
  makepkg --cleanbuild --clean --force
)

package_file=$(find "$work_dir" -maxdepth 1 -type f -name 'chatgpt-bin-*.pkg.tar.zst' -print -quit)
if [[ -z $package_file ]]; then
  printf 'ChatGPT package build completed without producing a package.\n' >&2
  exit 1
fi

printf 'Installing ChatGPT %s with pacman...\n' "$remote_package_version"
sudo pacman -U --noconfirm --needed "$package_file"

installed_package=$(pacman -Q chatgpt-bin)
installed_version=${installed_package#* }
if [[ $installed_version != "$remote_package_version" ]]; then
  printf 'Installed version %s does not match expected version %s.\n' \
    "$installed_version" "$remote_package_version" >&2
  exit 1
fi

printf 'ChatGPT %s installed successfully.\n' "$installed_version"
