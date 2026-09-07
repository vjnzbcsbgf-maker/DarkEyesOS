# DarkEyesOS

**A Tails-based, kernel-hardened, RAM-loaded, amnesic security distribution.**
Debian-live · Tor **+ I2P** · optional encrypted persistence · minimal GNOME · own identity.

> ### Tails-based, tracks every Tails release
>
> DarkEyesOS replicates Tails' proven security architecture and **tracks Tails
> releases** (7.12 and onward), while shipping its **own** branding, menus,
> wallpapers, GRUB, and tools plus extra upgrades (Tor + I2P dual network, I2P
> Browser, Dolphin, fastfetch). It does **not** remaster Tails' signed image
> (that breaks verification and is brittle). Instead, `scripts/sync-tails.sh`
> and the **Sync Tails baseline** workflow download a Tails release, **verify its
> signature**, and extract its functional config (firewall, Tor, hardening,
> package manifest) into `config/tails-base/<version>/` to base ours on — run on
> demand and monthly so we stay current. See
> [`config/tails-base/README.md`](config/tails-base/README.md).

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
| Dual network (Tor + I2P) | `i2pd` runs alongside Tor; `.i2p` eepsites via the **I2P Browser**. Firewall stays fail-closed — only the Tor and I2P daemons may egress. *This adds reach/compartmentalization, not "double encryption" — see note below.* |
| I2P Browser | Hardened Firefox ESR profile wired to the I2P proxy (there is no separate "I2P Browser" product) |
| Branded system info | `fastfetch` with the DarkEyes eye logo + live Tor/I2P status |
| File manager | **Dolphin** (KDE) set as default |
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

## Honest note on "Tor + I2P for more encryption"

Running Tor and I2P at the same time is real and useful, but **not because it
stacks encryption on the same connection.** They are two separate anonymity
networks for different destinations: Tor reaches the clearnet and `.onion`
services; I2P reaches `.i2p` eepsites. DarkEyesOS runs both, routes each kind of
address to the right network, and keeps the firewall fail-closed (only the Tor
and I2P daemons may reach the internet). You *can* tunnel one over the other,
but that usually **hurts** anonymity and speed, so we don't do it by default.
The benefit here is **broader reach and compartmentalization**, not naive
"double encryption." See `docs/THREAT_MODEL.md`.

## First boot, login, and admin access

- The live user is **`amnesia`** and the desktop **auto-logs in** (no desktop
  password) — consistent with an amnesic, RAM-only system.
- The **root account is locked** — there is no root password and you cannot log
  in as root or `su` to it.
- After the desktop loads, **Set Admin Password** pops up (and is in the menu)
  to optionally enable admin:
  - Set one → `amnesia` gains `sudo` for that session (needed for persistence
    setup, firewall reloads, etc.).
  - Skip it → the system has **no admin/root path at all** (fully locked down),
    Tails-style.
- Admin state is per-session and never persisted; every boot starts fresh.
- *(v2.1: the admin step moved from a pre-boot console greeter to this desktop
  dialog, because the console greeter could hang boot waiting for input.)*

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE). DarkEyesOS bundles third-party
software (Debian, Tor, GNOME, …) under their respective licenses.

## Disclaimer

DarkEyesOS is provided for privacy, journalism, research, and lawful security
work. Anonymity is hard and no system is perfect — read the threat model and
understand what it does and does not protect against before relying on it.
