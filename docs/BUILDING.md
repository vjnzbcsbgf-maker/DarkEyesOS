# Building DarkEyesOS

## Requirements

You need an **amd64 Debian or Ubuntu host** (or a container/VM) with:

- `root` (the build uses `debootstrap`, chroots, and loop devices)
- ~15–20 GB free disk for the build tree and cache
- ~4 GB RAM (more is faster), a few CPU cores
- Working outbound network to a Debian mirror and the Tor Project (for
  `torbrowser-launcher` metadata)
- Loop devices + `squashfs`/`overlay` kernel support (any normal Linux host)

The build installs its own dependencies (`live-build`, `debootstrap`,
`squashfs-tools`, `xorriso`, `mtools`, `dosfstools`, …) — you do not need to
install them by hand.

> **Cannot build inside every sandbox.** Some locked-down CI/containers forbid
> `debootstrap`'s chroot syscalls or mounting. If `lb build` fails at the
> bootstrap or squashfs stage with permission errors, run the build on a real
> Debian host, a VM, or a privileged container.

## Getting the image without a Debian box: GitHub Actions

The repo ships a workflow, `.github/workflows/build-image.yml`, that builds the
real image on GitHub's privileged Debian runners and publishes it — no local
Linux host needed.

- **Tag a release:** `git tag v1.0 && git push origin v1.0` → the workflow builds
  and creates a **GitHub Release** with `darkeyes-amd64.img`, the `.iso`, and
  `SHA256SUMS`/`SHA512SUMS` attached as assets.
- **Manual run:** Actions tab → *Build DarkEyesOS image* → *Run workflow*
  (optionally tick *make_release*). The image is always uploaded as a downloadable
  **workflow artifact** even without a release.

The runner installs Debian's modern `live-build` (the same version validated in
this repo), frees disk space, runs `./build.sh`, and makes a `.img` copy of the
isohybrid image (it `dd`s to USB identically). This is the honest way to "put the
`.img` in the assets": the bytes are produced on a real build machine, not faked.

## One-shot local build

```bash
sudo ./build.sh
```

This runs (roughly):

1. `apt-get install` the build toolchain
2. `lb config` — generate the live-build tree from `auto/config`
3. `lb build` — bootstrap → install packages → run hooks → make squashfs → ISO
4. Emit `out/darkeyes-amd64.hybrid.iso` + `SHA256SUMS` + `SHA512SUMS`

## Makefile targets

```bash
make deps      # install build dependencies only
make config    # run `lb config` (validate configuration without building)
make build     # run the full `sudo ./build.sh`
make iso       # alias for build
make vm        # boot the produced ISO in QEMU (needs qemu-system-x86)
make flash DEV=/dev/sdX   # flash to a USB stick (DESTRUCTIVE)
make clean     # lb clean + remove ./out
make distclean # also drop the apt/live-build caches
```

## Build options (environment variables)

| Variable | Default | Effect |
|----------|---------|--------|
| `DARKEYES_SUITE` | `trixie` | Debian suite to bootstrap |
| `DARKEYES_MIRROR` | `https://deb.debian.org/debian/` | Debian mirror |
| `DARKEYES_ARCH` | `amd64` | Target architecture |
| `DARKEYES_HARDENED_KERNEL` | `0` | Prefer a hardened kernel package if present |
| `KERNEL_FROM_SOURCE` | `0` | Compile a hardened kernel from source (slow) |
| `DARKEYES_EXTRA_PACKAGES` | *(empty)* | Space-separated extra packages |
| `DARKEYES_APT_PROXY` | *(empty)* | e.g. `http://apt-cacher:3142/` to speed rebuilds |

Example:

```bash
sudo DARKEYES_HARDENED_KERNEL=1 DARKEYES_APT_PROXY=http://10.0.0.2:3142/ ./build.sh
```

## Flashing to USB

```bash
# Identify the device carefully — this ERASES it.
lsblk
sudo ./scripts/flash-usb.sh out/darkeyes-amd64.hybrid.iso /dev/sdX
```

The image is *isohybrid*: it boots from USB on BIOS and UEFI. After first boot
you can create the encrypted persistence volume from the Control Center; it uses
the free space on the same stick.

## Testing in a VM before flashing

```bash
make vm        # or:
qemu-system-x86_64 -m 2048 -enable-kvm -cdrom out/darkeyes-amd64.hybrid.iso
```

## Verifying reproducibility (roadmap)

Two builds from the same commit with the same suite snapshot should produce
identical squashfs contents. We pin the suite and mirror; pinning to a
`snapshot.debian.org` timestamp (set `DARKEYES_MIRROR` to a snapshot URL) gets
you bit-for-bit closer. Full reproducible-build parity is tracked as future work.

## Troubleshooting

- **`debootstrap: command not found`** → run `make deps` (or `sudo ./build.sh`,
  which installs it).
- **`E: Unable to locate package …`** → the suite may not carry that package;
  check `config/package-lists/*` and the suite you selected.
- **Bootstrap permission denied in a container** → build on a host/VM with real
  loop + chroot privileges (see note above).
- **Out of disk** → `make distclean`, free space, rebuild; the cache lives in
  `./cache`.
