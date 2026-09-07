# DarkEyesOS

**A kernel-hardened, RAM-loaded, amnesic security distribution.**
Debian-live based · Tor-by-default · optional encrypted persistence · minimal GNOME.

DarkEyesOS is a live operating system you flash to a USB stick and boot. It is
designed around the same architecture that makes Tails effective — the whole
system runs from RAM (`toram`), forgets everything on shutdown (amnesia), forces
all network traffic through Tor, and keeps only what *you* explicitly choose in
an encrypted persistent volume.

> ### Read this first — honest scope
>
> This repository is **the build system that produces DarkEyesOS**, not a
> pre-built image. Bootable images are 1–2 GB and cannot live in git. You run
> `./build.sh` on a Debian host (or in a container with root + loop devices) and
> it produces `darkeyes-amd64.hybrid.iso` / `darkeyes.img`.
>
> **What DarkEyesOS is:** a real, buildable Debian derivative that replicates and
> extends the Tails security architecture with aggressive hardening.
>
> **What it is *not* (and why):**
> - It does **not** remaster the official Tails `.img`. Tails is itself built
>   from source with `live-build`; remastering its signed image is fragile and
>   defeats its verification model. We build our own live system the same way
>   Tails does — that is the professional, reproducible path.
> - It does **not** ship a "from-scratch fork" of Tor Browser. Re-forking Tor
>   Browser makes you *less* anonymous (you lose upstream's audited anti-
>   fingerprinting and break the shared-fingerprint anonymity set). We ship
>   **official Tor Browser** plus a locked-down hardening layer (enforced
>   `user.js`, AppArmor confinement, per-app Tor circuits).
> - It does **not** compile a custom kernel from scratch during a normal build
>   (that takes hours). It applies **kernel-level hardening** the effective way:
>   hardened boot parameters, `sysctl` lockdown, module blacklisting, and a
>   hardened kernel package. A from-source kernel is an opt-in build flag.
>
> No security tool is "the most secure in the market." DarkEyesOS aims to be a
> genuinely well-hardened amnesic system built on proven components — and to be
> honest about its threat model (see [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md)).

## Feature summary

| Goal | How DarkEyesOS does it |
|------|------------------------|
| Loads into RAM | `live-boot` with `toram`; the USB can be removed after boot |
| Amnesic | No swap, RAM wiped on shutdown (`sdmem`), nothing persisted by default |
| Tor by default | `tor` + transparent proxy (nftables); non-Tor traffic is dropped |
| ~512 MB idle | Minimal GNOME (no tracker/extra services), zram, tuned session |
| Beautiful GUI control | **DarkEyes Control Center** (GTK) to drive everything |
| Encrypted persistence | LUKS2 volume; opt-in per-feature, like Tails Persistent Storage |
| Hardened browser | Official Tor Browser + enforced hardening profile |
| Lightweight tools | Small GTK/CLI utilities instead of heavyweight suites |
| Kernel hardening | Boot params + `sysctl` + module blacklist + AppArmor + hardened kernel |

## Quick start

```bash
# On a Debian/Ubuntu host (root or sudo), or a container with loop devices:
sudo ./build.sh            # produces build output under ./out/
# Flash the result to a USB stick (DESTROYS the target disk):
sudo ./scripts/flash-usb.sh out/darkeyes-amd64.hybrid.iso /dev/sdX
```

See [`docs/BUILDING.md`](docs/BUILDING.md) for full requirements and options.

## Repository layout

```
build.sh                    Top-level build driver (installs deps, runs live-build)
Makefile                    Convenience targets (config / build / clean / iso / vm)
auto/                       lb config/build/clean wrappers (pinned, reproducible)
config/                     live-build configuration tree
  package-lists/            Package selection, grouped by role
  hooks/live/               chroot hooks that harden and configure the system
  includes.chroot/          Files baked directly into the root filesystem
  includes.binary/          Bootloader / ISO-level includes
tools/                      DarkEyes' own lightweight tools (Control Center, etc.)
persistence/                Persistence feature definitions (Tails-style)
scripts/                    flash-usb, run-vm, checksum helpers
docs/                       Architecture, security, threat model, build guide
```

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE). DarkEyesOS bundles third-party
software (Debian, Tor, GNOME, …) under their respective licenses.

## Disclaimer

DarkEyesOS is provided for privacy, journalism, research, and lawful security
work. Anonymity is hard and no system is perfect — read the threat model and
understand what it does and does not protect against before relying on it.
