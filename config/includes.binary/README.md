# includes.binary

Files placed here are copied into the **binary (ISO) stage** of the build —
i.e. onto the boot medium outside the squashfs, where the bootloader lives.

Use this for bootloader-level customization that must be readable before the
system is loaded into RAM:

- `isolinux/splash.png` — BIOS boot splash image
- `isolinux/isolinux.cfg` fragments / menu theming
- `boot/grub/theme/` — GRUB (UEFI) theme assets

The kernel command-line hardening parameters themselves are **not** set here;
they are declared once in [`auto/config`](../../auto/config) via
`--bootappend-live` so BIOS (isolinux) and UEFI (GRUB) stay in sync. See
[`docs/SECURITY.md`](../../docs/SECURITY.md) for the parameter list.

This directory is intentionally light: DarkEyesOS uses live-build's default
bootloader layout plus the shared boot parameters. Drop branding assets here
when you want a custom boot splash.
