# DarkEyes tools

The DarkEyesOS lightweight tools are shipped as their runnable sources under
`config/includes.chroot/usr/local/bin/` so `live-build` bakes them straight into
the image (no compile step, minimal RAM). This directory holds developer notes;
the source of truth is the `bin` copies.

| Tool | What it does |
|------|--------------|
| `darkeyes-control-center` | GTK4/libadwaita GUI to drive everything (thin wrapper over the CLIs below) |
| `darkeyes-status` | One-glance system state (`--kv` for machine-readable) |
| `darkeyes-tor` | Tor status / new circuit / **onion circuits** / verify exit, via ControlPort |
| `darkeyes-mac` | Randomize / restore NIC MAC addresses |
| `darkeyes-persistence` | Create / unlock / toggle the LUKS2 persistence volume |
| `darkeyes-unsafe-browser` | Tails-style Unsafe Browser for Wi-Fi captive portals (non-Tor, isolated `clearnet` user, off by default) |
| `darkeyes-metadata-cleaner` | Strip identifying metadata from files before sharing (mat2 + zenity) |
| `darkeyes-additional-software` | Tails-style Additional Software: persist a package list, reinstall into RAM at boot |
| `darkeyes-firewall-apply` | Render the nftables ruleset with the real tor uid (+ conditional captive-portal exception) |
| `darkeyes-ramwipe` | Best-effort RAM wipe on shutdown |
| `darkeyes-timesync` | Set the clock over Tor (no clearnet NTP) |

## Optimized Tails tools

DarkEyesOS reimplements the signature Tails tools as smaller, scriptable pieces:

- **Unsafe Browser** — runs a lightweight browser (Epiphany) as a dedicated
  `clearnet` user whose traffic bypasses Tor *only* while the browser is open
  (a temporary nftables exception), for logging in to captive portals. Warns
  loudly; off by default so the system stays fail-closed Tor-only.
- **Onion Circuits** — `darkeyes-tor circuits` lists your live Tor circuits and
  their relay path from the control port.
- **Metadata Cleaner** — a thin GUI over `mat2` wired into Nautilus' "Open With"
  and the file manager via a MimeType-scoped desktop entry.
- **Additional Software** — persists only a *package list* + the apt cache; the
  packages themselves are reinstalled into RAM at each boot, so the running
  system stays in RAM per the amnesic design.

## Design principles

- **Python + GObject, not Electron.** The GUI is a few hundred KB of Python over
  the system GTK the desktop already loads — it does not spin up a browser engine.
- **Logic in the CLIs, GUI stays thin.** Every button shells out to a CLI tool,
  so the same actions work headless over SSH-less console and are trivially
  auditable.
- **No background daemons of our own.** State is read on demand from
  `/proc`, `systemctl`, `nft`, and `cryptsetup`.

## Testing a tool without building the whole image

The CLIs are POSIX `sh`/Python and can be run on any Debian box for smoke tests
(they degrade gracefully when Tor/nft aren't present):

```bash
config/includes.chroot/usr/local/bin/darkeyes-status
config/includes.chroot/usr/local/bin/darkeyes-mac list
```
