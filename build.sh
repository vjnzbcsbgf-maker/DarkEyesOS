#!/usr/bin/env bash
# build.sh — top-level DarkEyesOS build driver.
# Installs the toolchain, runs live-build, and collects the image + checksums.
# Run as root (or with sudo) on a Debian/Ubuntu host with loop-device support.
set -euo pipefail

# ---- Configuration (override via environment; see docs/BUILDING.md) ------------
export DARKEYES_SUITE="${DARKEYES_SUITE:-trixie}"
export DARKEYES_MIRROR="${DARKEYES_MIRROR:-https://deb.debian.org/debian/}"
export DARKEYES_ARCH="${DARKEYES_ARCH:-amd64}"
export DARKEYES_HARDENED_KERNEL="${DARKEYES_HARDENED_KERNEL:-0}"
export DARKEYES_APT_PROXY="${DARKEYES_APT_PROXY:-}"

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${HERE}/out"

log() { printf '\033[1;35m[darkeyes]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[darkeyes:ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "must run as root (use: sudo ./build.sh)"
[ -f "${HERE}/auto/config" ] || die "run from the repository root"

# ---- 1. Dependencies -----------------------------------------------------------
install_deps() {
    log "Installing build dependencies…"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    # Everything EXCEPT live-build. We install live-build separately so a
    # pre-installed modern Debian live-build (e.g. put in place by CI) is NOT
    # clobbered by a distro's possibly-EOL packaged version.
    apt-get install -y --no-install-recommends \
        debootstrap debian-archive-keyring squashfs-tools xorriso \
        mtools dosfstools syslinux-common syslinux-utils isolinux \
        grub-pc-bin grub-efi-amd64-bin \
        ca-certificates gnupg curl rsync \
        || die "dependency install failed"

    if command -v lb >/dev/null 2>&1; then
        log "live-build already present ($(dpkg-query -W -f='${Version}' live-build 2>/dev/null)); keeping it"
    else
        apt-get install -y --no-install-recommends live-build \
            || die "live-build install failed"
    fi
}

# ---- 2. Sanity: environment can actually build a live system -------------------
preflight() {
    log "Preflight checks…"
    command -v debootstrap >/dev/null || die "debootstrap missing after install"
    command -v lb >/dev/null || die "live-build (lb) missing after install"

    # Require the modern Debian live-build branch. Ubuntu ships an EOL 3.0~aNN
    # fork whose option syntax (e.g. --bootloader vs --bootloaders) is
    # incompatible and would silently misbuild. Debian's is versioned 1:YYYYMMDD.
    lb_ver="$(dpkg-query -W -f='${Version}' live-build 2>/dev/null || echo '')"
    case "$lb_ver" in
        1:2*|2*)
            log "live-build ${lb_ver} (modern Debian branch) — OK" ;;
        3.0~a*)
            die "live-build ${lb_ver} is the EOL Ubuntu fork and is incompatible.
     Build on a Debian (trixie+) host, or install Debian's live-build:
       curl -fsSLO https://deb.debian.org/debian/pool/main/l/live-build/live-build_20250505+deb13u1_all.deb
       sudo apt-get remove -y live-build && sudo dpkg -i live-build_20250505+deb13u1_all.deb" ;;
        *)
            log "WARN: unrecognized live-build version '${lb_ver}'; proceeding, but a modern Debian live-build is expected" ;;
    esac
    grep -qw overlay /proc/filesystems || log "WARN: overlay fs not in kernel (build may still work)"
    if ! grep -qw squashfs /proc/filesystems && ! modprobe squashfs 2>/dev/null; then
        log "WARN: squashfs not available; mksquashfs userspace tool will still be used"
    fi
    # debootstrap needs to be able to chroot; warn in obviously locked-down sandboxes.
    if ! unshare -r true 2>/dev/null; then
        log "WARN: user namespaces restricted; if bootstrap fails, build on a real host/VM"
    fi
}

# ---- 3. Configure + build ------------------------------------------------------
do_build() {
    cd "${HERE}"
    log "Cleaning previous build state…"
    lb clean --purge 2>/dev/null || true

    log "Generating live-build configuration (lb config)…"
    lb config

    log "Building the image (lb build) — this downloads packages and takes a while…"
    lb build

    mkdir -p "${OUT}"
    shopt -s nullglob
    local produced=()
    for img in *.iso *.hybrid.iso *.img; do
        mv -f "${img}" "${OUT}/darkeyes-${DARKEYES_ARCH}.hybrid.iso"
        produced+=("darkeyes-${DARKEYES_ARCH}.hybrid.iso")
    done
    [ "${#produced[@]}" -gt 0 ] || die "no image was produced (check darkeyes-build.log)"

    log "Generating checksums…"
    ( cd "${OUT}" && sha256sum ./*.iso > SHA256SUMS && sha512sum ./*.iso > SHA512SUMS )
    log "Build complete. Output in: ${OUT}"
    ls -lh "${OUT}"
}

case "${1:-all}" in
    deps)      install_deps ;;
    preflight) preflight ;;
    config)    install_deps; preflight; cd "${HERE}" && lb config && log "lb config OK" ;;
    all|build) install_deps; preflight; do_build ;;
    *) die "usage: $0 [deps|preflight|config|build]" ;;
esac
