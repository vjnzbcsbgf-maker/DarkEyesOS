# DarkEyesOS Hardening Reference

This is the concrete list of hardening DarkEyesOS applies, grouped by layer, with
the file that implements each item. Nothing here is aspirational — every entry
maps to a real config/hook in this repo.

## 1. Kernel & boot ("kernel-level optimization")

Applied via boot parameters (`config/includes.binary/isolinux/`, GRUB include)
and `config/includes.chroot/etc/sysctl.d/99-darkeyes-hardening.conf`.

**Boot parameters**

| Parameter | Purpose |
|-----------|---------|
| `slab_nomerge` | Prevent slab-cache merging (harder heap exploitation) |
| `init_on_alloc=1 init_on_free=1` | Zero heap/pages on alloc and free |
| `page_alloc.shuffle=1` | Randomize the page allocator freelist |
| `randomize_kstack_offset=1` | Per-syscall kernel stack offset randomization |
| `pti=on` | Force kernel page-table isolation (Meltdown) |
| `vsyscall=none` | Remove the legacy static vsyscall ROP target |
| `debugfs=off` | Disable debugfs |
| `lockdown=confidentiality` | Kernel lockdown, block ways to read kernel memory |
| `mitigations=auto,nosmt` | Apply CPU-bug mitigations; disable SMT (defense vs. cross-HT leaks) |
| `module.sig_enforce=1` | Only load signed kernel modules |
| `spectre_v2=on spec_store_bypass_disable=on` | Speculative-exec mitigations on |
| `mce=0` (opt) | Reduce a covert side channel surface |

**sysctl** (`99-darkeyes-hardening.conf`) — highlights:

- `kernel.kptr_restrict=2`, `kernel.dmesg_restrict=1`, `kernel.printk=3 3 3 3`
- `kernel.kexec_load_disabled=1`, `kernel.unprivileged_bpf_disabled=1`
- `net.core.bpf_jit_harden=2`
- `kernel.yama.ptrace_scope=2` (only children ptrace; blocks process snooping)
- `kernel.perf_event_paranoid=3`, `kernel.kptr_restrict`, `kernel.sysrq=0`
- `dev.tty.ldisc_autoload=0`, `vm.unprivileged_userfaultfd=0`
- `fs.protected_symlinks/hardlinks/fifos/regular=1/1/2/2`
- `net.ipv4.tcp_syncookies=1`, reverse-path filtering, no redirects/source-route

**Module blacklist** (`config/includes.chroot/etc/modprobe.d/darkeyes-blacklist.conf`):
disables uncommon/attack-surface network protocols (`dccp`, `sctp`, `rds`,
`tipc`), rare filesystems (`cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`,
`udf`), FireWire/Thunderbolt DMA vectors, `vivid`, and (optionally) USB storage
after boot.

**Hardened kernel package**: the build installs Debian's `linux-image-amd64`;
set `DARKEYES_HARDENED_KERNEL=1` to prefer a grsec-style/hardened variant when
available in the configured suite. A from-source kernel is `KERNEL_FROM_SOURCE=1`
(long build; off by default).

## 2. Amnesia / anti-forensics

- **RAM-only**: overlay upper layer is tmpfs; `toram` copies the system into RAM.
- **No swap ever**: `noswap` boot param + no swap in fstab; only `zram` (volatile).
- **Memory wipe on shutdown**: `sdmem` sweep of freed RAM via a systemd
  shutdown unit (`config/includes.chroot/lib/systemd/system/darkeyes-wipe.service`).
- **No persistent logs** unless persistence enabled: `journald` set to `volatile`.
- **MAC randomization**: NetworkManager `wifi.mac-address-randomization` +
  `darkeyes-mac` tool.
- **Timestamps/clock**: time sync via Tor (`tor` + `htpdate`-style) not clearnet NTP.

## 3. Network fail-closed (Tor enforcement)

- Transparent Tor proxy with `nftables`; clearnet, IPv6, and non-Tor UDP are
  **dropped**, so a Tor failure means *no* network rather than a leak.
- Per-application stream isolation in `torrc` (`IsolateDestAddr`,
  `IsolateSOCKSAuth`, separate ports for browser vs. system).
- `systemd-resolved`/clearnet DNS disabled; DNS only via Tor `DNSPort`.
- Outbound firewall default policy `drop`; only Tor's uid may reach the internet.

## 4. Userspace confinement

- **AppArmor** enabled at boot (`apparmor=1 security=apparmor`), enforcing
  profiles for Tor Browser, tor, and risky apps
  (`config/includes.chroot/etc/apparmor.d/local/`).
- **No sudo password by default is refused** — the live user has a locked root
  and controlled `sudo` (admin password set at boot only if the user opts in,
  Tails-style). Screen locks; auto-login only into a confined session.
- Compiler/`ptrace`/`kcore` reads restricted; `/proc` mounted `hidepid=2`.
- `umask 077`, hardened `login.defs`, disabled core dumps
  (`* hard core 0`, `kernel.core_pattern=|/bin/false`).

## 5. Browser hardening (official Tor Browser + policy)

We do **not** fork Tor Browser. Instead:

- Install the official Tor Browser (via `torbrowser-launcher`, verified
  signatures) and pin an **enforced** hardening `user.js`
  (`config/includes.chroot/etc/darkeyes/torbrowser/user.js`): security level
  "Safest" by default, no WebGL/WebRTC/DRM, resist-fingerprinting on, disk cache
  off, etc.
- Confine it with a dedicated AppArmor profile and run it as an isolated user.
- Route it through its own isolated Tor circuit.

Rationale is documented in `docs/THREAT_MODEL.md` §"Why not a custom browser."

## 6. Supply-chain / integrity

- Pinned Debian suite + signed apt repositories (`lb` uses Debian keyring).
- `torbrowser-launcher` verifies Tor Project signatures on download.
- Build emits `SHA256SUMS`/`SHA512SUMS`; reproducible-build work is tracked in
  `docs/BUILDING.md`.

## 7. What we deliberately do NOT claim

- We do not claim to defeat a global passive adversary who can correlate Tor
  traffic timing.
- We do not claim protection against hardware implants, malicious firmware, or a
  compromised CPU microcode you cannot patch.
- We do not claim "unbreakable." Read `docs/THREAT_MODEL.md`.
