# DarkEyesOS Threat Model

Being honest about what a tool protects is part of security. Here is what
DarkEyesOS is built to resist, what it is not, and why some "obvious" ideas were
deliberately rejected.

## Who it protects

DarkEyesOS is for people who need a **disposable, leave-no-trace, anonymized**
computing session on hardware they don't fully trust to stay clean: journalists,
researchers, activists, incident responders, and privacy-conscious users.

## Adversaries it aims to raise the cost for

| Adversary | Mitigation in DarkEyesOS |
|-----------|--------------------------|
| Someone who later seizes the computer/USB | Amnesia: nothing written to internal disks; RAM wiped on shutdown; persistence is LUKS2-encrypted |
| Local network / ISP observer | All traffic forced through Tor, fail-closed; MAC randomized |
| Malware in a downloaded file (this session) | AppArmor confinement; amnesia removes it on reboot; no persistence by default |
| Websites fingerprinting the browser | Official Tor Browser + resist-fingerprinting, shared anonymity set |
| Accidental clearnet leak | nftables drops all non-Tor traffic; no clearnet DNS |
| Cold-ish memory remnants | `sdmem` wipe on shutdown, no swap |

## Adversaries it does NOT defeat (be realistic)

- **Global passive adversary** who can observe both ends of the Tor network and
  correlate timing. This is an open research problem; no low-latency anonymity
  system solves it, and neither does DarkEyesOS.
- **Malicious hardware/firmware**: BIOS/UEFI implants, malicious peripherals,
  compromised CPU microcode, a hardware keylogger. If the machine's firmware is
  backdoored, no live OS saves you.
- **Cold-boot attacks** against RAM that is still powered (we wipe on ordered
  shutdown, not on a yanked-power freeze attack).
- **You deanonymizing yourself**: logging into your real accounts, revealing
  identifying info, or persisting identifying data defeats the whole system.
- **Targeted 0-day** against the kernel or Tor Browser by a well-resourced
  attacker. Hardening raises cost; it is not immunity.

## Design decisions you might question

### Why not remaster the official Tails image?
Tails ships a signed, verified image whose security depends on that verification
chain. Unsquashing, editing, and resquashing it (a) breaks the signature and the
user's ability to verify authenticity, (b) is brittle across Tails releases, and
(c) means you're shipping a modified Tails you can't call Tails and can't easily
keep patched. Building our own live system with `live-build` — which is exactly
how Tails itself is built — is reproducible, auditable, and keeps us on Debian's
security-update track.

### Why not build a "custom, more secure" Tor Browser from scratch?
Anonymity on Tor comes partly from **looking identical to every other Tor Browser
user**. A custom fork:
- has a different fingerprint → shrinks your anonymity set → makes you *easier*
  to single out;
- loses the Tor Project's continuously-audited anti-fingerprinting patches;
- falls behind on security updates the moment upstream ships a fix.
The secure move is the official browser plus an *enforced* hardening policy and
sandbox, which is what we ship.

### Why not compile a bespoke kernel every build?
A from-scratch kernel compile takes hours and, done casually, tends to *reduce*
security (missing Debian's hardening patchset and signed-module infrastructure).
We get "kernel-level" security through boot-time lockdown, `sysctl`, module
blacklisting, AppArmor, and a hardened kernel package — with a from-source build
available as an opt-in flag for those who want it.

## Operational security reminders (the human layer)

- Don't enable persistence for things that identify you unless you truly need it.
- Don't mix identities across sessions; reboot between them.
- Verify the image checksum/signature before flashing.
- Physically control the USB stick.
- Understand that Tor exit traffic can be observed — use end-to-end encryption.
