# DarkEyesOS Architecture

DarkEyesOS is a **Debian live system** built with `live-build`. This document
explains how the pieces fit together, from the moment the USB is plugged in to a
running, Tor-forced, RAM-only desktop.

## 1. Build pipeline

```
        build.sh
           │  installs live-build, debootstrap, squashfs-tools, xorriso …
           ▼
   lb config (auto/config)         ← declares the distro (Debian trixie, amd64, GNOME, toram)
           │
           ▼
   lb build
     ├─ bootstrap:  debootstrap a minimal Debian into chroot/
     ├─ chroot:     install package-lists/*, run hooks/live/*, copy includes.chroot/*
     ├─ binary:     build squashfs, assemble ISO (isolinux/grub), hybrid-mark it
     └─ output:     out/darkeyes-amd64.hybrid.iso  (+ checksums)
```

`live-build` is the same framework Tails and Kali use. We do **not** post-process
someone else's image; we declare our own from a pinned Debian suite so builds are
reproducible and auditable.

## 2. Boot flow

```
USB firmware / UEFI
    → GRUB / isolinux   (config/includes.binary, boot params)
    → Linux kernel + initramfs (live-boot)
    → live-boot copies the squashfs into RAM  (boot param: toram)
    → overlayfs: read-only squashfs (lower) + tmpfs (upper)   → writable, volatile "/"
    → optional: unlock LUKS persistence, bind-mount persisted dirs
    → systemd → GNOME (minimal) → DarkEyes first-run
```

Key boot parameters (set in the bootloader configs and `live` package):

| Param | Effect |
|-------|--------|
| `boot=live` | use live-boot |
| `toram` | copy filesystem to RAM, then USB can be removed |
| `nopersistence` (default off) | persistence is opt-in and gated by a boot menu entry |
| `noswap` | never activate swap (amnesia) |
| `module=darkeyes` | live-boot module name for persistence label |
| Hardening params | see `docs/SECURITY.md` (`slab_nomerge`, `init_on_alloc=1`, `lockdown=confidentiality`, `mitigations=auto,nosmt`, …) |

## 3. Filesystem model (why it's amnesic)

```
┌──────────────────────────────────────────────────────────┐
│ tmpfs (RAM)  ── upper layer, read-write, VOLATILE         │  ← all changes land here
├──────────────────────────────────────────────────────────┤
│ overlayfs merges the two into a normal-looking "/"        │
├──────────────────────────────────────────────────────────┤
│ squashfs (copied to RAM by toram) ── lower, READ-ONLY     │  ← the shipped system
└──────────────────────────────────────────────────────────┘
```

Because the writable layer is a tmpfs in RAM, **powering off discards
everything**. On shutdown we additionally `sdmem`-wipe freed memory and never
touch a swap device. The only thing that survives is the encrypted persistence
volume, and only the directories the user opted into.

## 4. Persistence model (Tails-style, opt-in)

A LUKS2 volume labeled `DarkEyes-Persistence` on the same USB holds an ext4
filesystem. `persistence/persistence.d/*` defines features (Tor Browser
bookmarks, GnuPG keys, dotfiles, additional software, …). Each feature maps a
persisted directory to a live path via bind mounts, activated *after* the user
unlocks the volume at boot. Nothing is persisted unless the user creates the
volume and enables the feature in the Control Center. See
[`persistence/README.md`](../persistence/README.md).

## 5. Network model (Tor by default)

```
Applications ──► nftables transparent proxy ──► tor (TransPort/DNSPort) ──► Tor network
                        │
                        └── everything not destined for Tor is DROPPED (fail-closed)
```

- `tor` runs as a system service; `/etc/tor/torrc` opens `TransPort`, `DNSPort`,
  and an isolated `SocksPort` per application family (`IsolateDestAddr`,
  `IsolateSOCKSAuth`).
- `nftables` (`config/includes.chroot/etc/nftables.conf` + hook) redirects all
  TCP/DNS from non-Tor users to Tor and **drops** anything that would leak
  (clearnet, IPv6 by default, non-Tor UDP). This is fail-closed: if `tor` is
  down, you have no network, not a clearnet leak.
- `NetworkManager` handles the link layer; MAC address randomization is on.

## 6. Desktop (minimal GNOME, ~512 MB idle)

We ship GNOME Shell but strip the RAM-hungry pieces:

- Disable `tracker3` / `tracker-miner` indexing.
- Remove GNOME Software background service, online-accounts, geoclue.
- `zram` swap-on-RAM for graceful pressure handling without a disk swap.
- dconf defaults that turn off animations-heavy and telemetry-ish features.
- A curated set of lightweight apps (see `config/package-lists/`).

The **DarkEyes Control Center** (`tools/darkeyes-control-center`) is the single
GTK surface to manage Tor, persistence, MAC, the firewall, and updates.

## 7. Source of truth for versions

Everything pinnable is pinned in `auto/config` (Debian suite, mirrors,
architecture) so two builds from the same commit yield the same package set,
which is the foundation for eventual reproducible builds.
