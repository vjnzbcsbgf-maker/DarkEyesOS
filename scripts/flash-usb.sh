#!/usr/bin/env bash
# flash-usb.sh — write a DarkEyesOS image to a USB stick. DESTROYS the target.
set -euo pipefail

IMG="${1:?usage: flash-usb.sh <image.iso> <device e.g. /dev/sdX>}"
DEV="${2:?usage: flash-usb.sh <image.iso> <device e.g. /dev/sdX>}"

[ "$(id -u)" = 0 ] || { echo "run as root (sudo)"; exit 1; }
[ -f "$IMG" ] || { echo "image not found: $IMG"; exit 1; }
[ -b "$DEV" ] || { echo "not a block device: $DEV"; exit 1; }

# Refuse to write to a disk that is mounted or looks like the system disk.
if lsblk -no MOUNTPOINT "$DEV" | grep -q '/$'; then
    echo "REFUSING: $DEV appears to hold the running root filesystem." >&2; exit 1
fi

echo "About to ERASE $DEV and write $IMG:"
lsblk -o NAME,SIZE,MODEL,TRAN "$DEV" || true
printf "Type the device path again to confirm (%s): " "$DEV"
read -r confirm
[ "$confirm" = "$DEV" ] || { echo "Aborted."; exit 1; }

echo "Unmounting any partitions on $DEV…"
for p in "${DEV}"?*; do umount "$p" 2>/dev/null || true; done

echo "Writing (this can take several minutes)…"
dd if="$IMG" of="$DEV" bs=4M conv=fsync status=progress
sync
echo "Done. You can now boot from $DEV."
echo "Tip: create encrypted persistence from the Control Center after first boot."
