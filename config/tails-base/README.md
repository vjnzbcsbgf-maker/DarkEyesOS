# Tails baseline (config/tails-base/)

DarkEyesOS is a **Tails-based** amnesic distribution: it replicates Tails'
proven security architecture and tracks Tails releases, while shipping its **own
identity** (branding, menus, wallpapers, GRUB, tools) and extra upgrades
(Tor + I2P dual network, I2P Browser, Dolphin, fastfetch, …).

## How the "based on Tails" part works — honestly

We do **not** remaster the signed Tails image (that breaks Tails' verification
and is brittle). Instead:

1. **`scripts/sync-tails.sh`** downloads a Tails release, **verifies its OpenPGP
   signature** against the Tails signing key, loop-mounts it, unsquashes it, and
   extracts Tails' **functional configuration** — firewall (`nftables`), Tor
   (`torrc`), session/desktop hardening (`sysctl`, `apparmor`, `gdm3`), and the
   installed **package manifest** — into `config/tails-base/<version>/`.
2. That baseline is a **reference** we fold into our own `config/` (live-build)
   tree, keeping DarkEyesOS' branding and menus on top.
3. The **`Sync Tails baseline`** GitHub workflow runs this on demand and monthly,
   opening a PR whenever a new Tails version (7.12 → 7.13 → 8.0 → …) is synced —
   so DarkEyesOS stays flexible and current with every Tails edition.

## What is and isn't taken from Tails

**Taken (functional, GPL, auditable):** firewall/Tor enforcement, session and
kernel hardening, package/capability manifest.

**NOT taken:** Tails' name, logo, artwork, boot menus, wallpapers, or any
branding. DarkEyesOS has its own — see the emblem, wallpapers, fastfetch logo,
and boot splash under `config/includes.chroot/`.

## Updating to a new Tails version

```bash
# locally (needs root + loop devices):
sudo TAILS_VERSION=7.13 ./scripts/sync-tails.sh
# or run the "Sync Tails baseline" workflow from the Actions tab with the version.
```
Then review the PR/diff and merge the parts that improve DarkEyesOS.
