# DarkEyesOS Persistence

DarkEyesOS is amnesic by default: every boot forgets everything. **Persistence is
opt-in**, encrypted, and modeled on Tails' Persistent Storage.

## How it works

1. You create an encrypted volume on the same USB stick (LUKS2, ext4), labeled
   `DarkEyes-Persistence`. The Control Center → *Persistence* does this, or:
   ```bash
   sudo darkeyes-persistence create /dev/sdX3
   ```
2. At boot, if that volume is present, live-boot offers a *persistence* entry.
   You unlock it with your passphrase.
3. Only the **features you enabled** are bind-mounted from the volume into the
   live system. Everything else stays amnesic.

## What can be persisted

The catalog lives at
`config/includes.chroot/usr/share/darkeyes/persistence.d/darkeyes.conf`. Features:

| Feature | Persisted path |
|---------|----------------|
| Personal files | `~/Persistent` |
| GnuPG keys | `~/.gnupg` |
| SSH keys | `~/.ssh` |
| Tor Browser bookmarks/data | `~/.local/share/torbrowser` |
| KeePassXC config | `~/.config/keepassxc` |
| Additional software | APT archives + a package list re-applied at boot |

## Security notes

- The volume is **LUKS2** with Argon2id KDF; choose a strong passphrase.
- Persisting identifying data (keys, bookmarks) trades amnesia for convenience —
  enable only what you truly need (see `docs/THREAT_MODEL.md`).
- "Additional software" persists a **package list**, and packages are reinstalled
  into RAM at each boot — the binaries themselves live in RAM, only the *list* and
  the apt cache are on disk. This keeps the running system in RAM per your spec.
- Deleting the LUKS volume (Control Center → *Persistence* → Delete) is a secure
  wipe of the header, rendering the data unrecoverable.

## CLI

```bash
darkeyes-persistence status          # show volume + enabled features
sudo darkeyes-persistence create DEV # make a new LUKS2 persistence volume
sudo darkeyes-persistence unlock     # unlock + mount at boot (usually automatic)
darkeyes-persistence enable gnupg    # toggle a feature on
darkeyes-persistence disable gnupg   # toggle a feature off
sudo darkeyes-persistence wipe       # securely destroy the volume header
```
