#!/usr/bin/env bash
# sync-tails.sh — fetch a Tails release, VERIFY its signature, and extract the
# real functional configs we base DarkEyesOS on (firewall, Tor, session/desktop
# hardening, package manifest). Version-parameterized so DarkEyesOS can track
# Tails 7.12 and every future edition.
#
# It does NOT copy Tails' branding, artwork, menus, or names — DarkEyesOS keeps
# its own identity. It extracts CONFIG we can learn from and adapt, not a
# remastered image. Output goes to config/tails-base/<version>/.
#
# Usage: sudo ./scripts/sync-tails.sh [VERSION]   (default: $TAILS_VERSION or 7.12)
set -euo pipefail

VERSION="${1:-${TAILS_VERSION:-7.12}}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${HERE}/config/tails-base/${VERSION}"
WORK="$(mktemp -d)"
trap 'umount "$WORK/iso" 2>/dev/null || true; umount "$WORK/sq" 2>/dev/null || true; rm -rf "$WORK"' EXIT

log() { printf '\033[1;35m[sync-tails]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[sync-tails:ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "run as root (needs loop mount): sudo $0 $VERSION"

# --- Dependencies ---------------------------------------------------------------
command -v unsquashfs >/dev/null || { apt-get update && apt-get install -y squashfs-tools; }
command -v gpgv >/dev/null || { apt-get update && apt-get install -y gpgv gnupg; }
command -v curl >/dev/null || { apt-get update && apt-get install -y curl; }

# --- Download the image + signature + signing key -------------------------------
# Tails distributes IMG (USB) and ISO. We use the ISO (has the same squashfs and
# is loop-mountable read-only without partition math). URL layout as published on
# download.tails.net; if a future release moves it, override TAILS_BASEURL.
BASE="${TAILS_BASEURL:-https://download.tails.net/tails/stable/tails-amd64-${VERSION}}"
ISO="tails-amd64-${VERSION}.iso"
log "Fetching ${BASE}/${ISO}"
curl -fSL --retry 3 -o "$WORK/$ISO"     "${BASE}/${ISO}"     || die "download failed — check the version/URL (TAILS_BASEURL)"
curl -fSL --retry 3 -o "$WORK/$ISO.sig" "${BASE}/${ISO}.sig" || die "signature download failed"
curl -fSL --retry 3 -o "$WORK/tails-signing.key" "https://tails.net/tails-signing.key" \
    || die "could not fetch Tails signing key"

# --- Verify the signature (integrity + authenticity) ----------------------------
log "Verifying OpenPGP signature against the Tails signing key…"
gpg --no-default-keyring --keyring "$WORK/tails.gpg" --import "$WORK/tails-signing.key" >/dev/null 2>&1
if ! gpgv --keyring "$WORK/tails.gpg" "$WORK/$ISO.sig" "$WORK/$ISO" 2>"$WORK/verify.log"; then
    cat "$WORK/verify.log" >&2
    die "SIGNATURE VERIFICATION FAILED — refusing to use this image"
fi
log "Signature OK."

# --- Mount ISO + unsquash the filesystem ---------------------------------------
mkdir -p "$WORK/iso" "$WORK/root"
mount -o loop,ro "$WORK/$ISO" "$WORK/iso" || die "loop-mount failed (need privileges)"
SQUASH="$(find "$WORK/iso" -name 'filesystem.squashfs' | head -n1)"
[ -n "$SQUASH" ] || die "no filesystem.squashfs in the Tails ISO"
log "Unsquashing ${SQUASH##*/} (this takes a minute)…"
unsquashfs -f -d "$WORK/root" "$SQUASH" >/dev/null

# --- Extract the CONFIG we care about (functional, not branding) ----------------
mkdir -p "$OUT"
copy() { # <relative path under Tails root>
    src="$WORK/root/$1"
    if [ -e "$src" ]; then
        dst="$OUT/$1"; mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst" 2>/dev/null && log "  + $1" || true
    fi
}

log "Extracting Tails functional configuration…"
# Network / firewall (Tor enforcement — the most valuable, audited part)
copy etc/nftables.conf
copy etc/nftables.d
copy usr/local/lib/tails-*firewall* 2>/dev/null || true
for f in $(cd "$WORK/root" 2>/dev/null && ls etc/ferm 2>/dev/null); do copy "etc/ferm/$f"; done
copy etc/tor/torrc
copy etc/tor/torrc.d
# Session / desktop hardening + greeter logic (NOT artwork)
copy etc/gdm3/daemon.conf
copy etc/systemd/system
copy etc/apparmor.d
copy etc/sysctl.d
copy etc/modprobe.d
# Package manifest — what Tails ships, so we can match capability
if [ -d "$WORK/root/var/lib/dpkg" ]; then
    chroot "$WORK/root" dpkg-query -W -f='${Package}\n' 2>/dev/null \
        | sort -u > "$OUT/package-manifest.txt" && log "  + package-manifest.txt"
fi

# --- Record provenance ----------------------------------------------------------
cat > "$OUT/PROVENANCE.txt" <<EOF
Tails baseline for DarkEyesOS
Version : ${VERSION}
Source  : ${BASE}/${ISO}
Verified: OpenPGP signature checked against tails.net signing key
Synced  : $(date -u +%Y-%m-%dT%H:%M:%SZ)

This directory holds Tails' functional CONFIG (firewall, Tor, session hardening,
package manifest) used as a reference/baseline. It contains NO Tails branding,
artwork, menus, or trademarks. DarkEyesOS layers its own identity on top.
EOF
log "Done. Tails ${VERSION} baseline in: config/tails-base/${VERSION}/"
log "Review the diff, then fold vetted configs into config/ (keeping our menus/branding)."
