# DarkEyes tools

The DarkEyesOS lightweight tools are shipped as their runnable sources under
`config/includes.chroot/usr/local/bin/` so `live-build` bakes them straight into
the image (no compile step, minimal RAM). This directory holds developer notes;
the source of truth is the `bin` copies.

| Tool | What it does |
|------|--------------|
| `darkeyes-control-center` | GTK4/libadwaita GUI to drive everything (thin wrapper over the CLIs below) |
| `darkeyes-status` | One-glance system state (`--kv` for machine-readable) |
| `darkeyes-tor` | Tor status / new circuit / verify exit, via ControlPort |
| `darkeyes-mac` | Randomize / restore NIC MAC addresses |
| `darkeyes-persistence` | Create / unlock / toggle the LUKS2 persistence volume |
| `darkeyes-firewall-apply` | Render the nftables ruleset with the real tor uid |
| `darkeyes-ramwipe` | Best-effort RAM wipe on shutdown |
| `darkeyes-timesync` | Set the clock over Tor (no clearnet NTP) |

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
