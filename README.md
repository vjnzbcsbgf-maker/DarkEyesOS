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
> This repository is **the build system that produces DarkEyesOS**. A bootable
> image is 1–2 GB and cannot live in git (GitHub rejects files over 100 MB), so
> the image is produced by a build, not committed. There are two supported ways
> to get the flashable `darkeyes-amd64.img`:
>
> 1. **Automated (recommended): GitHub Actions builds it and attaches it to a
>    Release.** Push a tag (`git tag v1.0 && git push origin v1.0`) or run the
>    *Build DarkEyesOS image* workflow manually. A privileged Debian runner runs
>    `lb build` and uploads `darkeyes-amd64.img` (+ `.iso` + checksums) to the
>    release assets. See [`.github/workflows/build-image.yml`](.github/workflows/build-image.yml).
> 2. **Local:** run `sudo ./build.sh` on a Debian host (root + loop devices) to
>    produce the image under `./out/`.
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
| Identity | Bibata Modern Classic (dark) cursor + "Your Data Is Yours" emblem |
| Encrypted persistence | LUKS2 volume; opt-in per-feature, like Tails Persistent Storage |
| Hardened browser | Official Tor Browser + enforced hardening profile |
| Tails-style tools | Unsafe Browser (captive portals), Onion Circuits, Metadata Cleaner, Additional Software |
| Lightweight tools | Small GTK/CLI utilities instead of heavyweight suites |
| Kernel hardening | Boot params + `sysctl` + module blacklist + AppArmor + hardened kernel |
| Boots on slow USB 2.0 | isohybrid image; `toram` reads once at boot (~75 s @ 20 MB/s) then runs from RAM |

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

## First boot, login, and admin access

- The live user is **`amnesia`** and the desktop **auto-logs in** (no desktop
  password) — consistent with an amnesic, RAM-only system.
- The **root account is locked** — there is no root password and you cannot log
  in as root or `su` to it.
- On boot, the **DarkEyes Greeter** (console, before the desktop) asks whether to
  set an **administration password**:
  - Set one → `amnesia` gains `sudo` for that session (needed for persistence
    setup, firewall reloads, etc.).
  - Skip it → the system has **no admin/root path at all** (fully locked down),
    Tails-style.
- Admin state is per-session and never persisted; every boot starts fresh.

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE). DarkEyesOS bundles third-party
software (Debian, Tor, GNOME, …) under their respective licenses.

## Disclaimer

DarkEyesOS is provided for privacy, journalism, research, and lawful security
work. Anonymity is hard and no system is perfect — read the threat model and
understand what it does and does not protect against before relying on it.
