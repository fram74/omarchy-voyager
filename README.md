# Omarchy Voyager Layouts

An unofficial [Omarchy](https://omarchy.org/) shell plugin and CLI for switching among saved [Oryx](https://configure.zsa.io/) layout profiles on a [ZSA Voyager](https://www.zsa.io/) keyboard by flashing firmware (via [Zapp](https://github.com/zsa/zapp)).

Use the top-bar keyboard icon (dropdown), the Omarchy menu, optional Hyprland hotkeys, or the `voyager-layout` command.

> **Not the same as** Omarchy’s built-in `omarchy.keyboard-layout` widget, which only cycles **OS / xkb** input languages (US, SE, …). This plugin flashes **keyboard firmware layouts**.

[![Top bar Voyager dropdown demo](docs/guide/images/topbar-preview.webp)](https://www.youtube.com/watch?v=If5TmJpFCKQ&autoplay=1)

Full walkthrough: [docs/guide/GUIDE.md](docs/guide/GUIDE.md)

---

## Disclaimer — please read

### No affiliation

**This project is an independent, unofficial community work.**

It is **not** created, endorsed, sponsored, affiliated with, or supported by:

- **ZSA Technology Labs** (Voyager, Oryx, Keymapp, Zapp, or any other ZSA product or trademark)
- **Basecamp** / the **Omarchy** project maintainers
- xAI or any other company mentioned only for interoperability

“Voyager”, “Oryx”, “ZSA”, “Keymapp”, “Zapp”, and related names are property of their respective owners and are used here only to describe compatibility.

### Firmware flashing risk

**Flashing firmware can make your keyboard temporarily or permanently unusable, erase or corrupt layouts, require recovery procedures, or cause other hardware or data issues.** USB flashing tools interact with device bootloaders; mistakes, bad cables, power loss, incompatible firmware, interrupted flashes, or software bugs may result in a board that will not enumerate until recovered (or, in rare cases, not at all). Use this software **at your own risk**.

The “AS IS” warranty disclaimer and limitation of liability are in the [MIT License](LICENSE).

---

## Requirements

| Requirement | Notes |
|-------------|--------|
| [Omarchy](https://omarchy.org/) (Arch-based) | Shell plugins via `omarchy plugin add` |
| ZSA Voyager | USB; detected as `3297:1977` (normal) / `3297:0791` (bootloader) |
| One or more **compiled** Oryx layouts | You need shareable layout URLs or `.bin` files |
| **Zapp** (`zsa-zapp` on the AUR) | Required to flash; **not** installed automatically by the plugin adder |
| Optional: `dfu-util` | Fallback flasher if Zapp hits USB errors |

AUR helpers: Omarchy’s `omarchy pkg aur add`, or `yay`.

---

## Install

### 1. Add the plugin

```bash
omarchy plugin add https://github.com/fram74/omarchy-voyager.git --enable
```

Place the widget on the bar if prompted (default: **right**).

Omarchy’s plugin installer **only clones and enables** the plugin. It does **not** install system packages (no sudo / no AUR hooks). That is an Omarchy design constraint, not an oversight in this repo.

### 2. Install flash tools (required once)

**From the bar (recommended):** plug in the Voyager → click the keyboard icon → **Install flash tools**.

**Or from a terminal:**

```bash
# After the plugin is installed, either use the PATH link below, or:
~/.config/omarchy/plugins/fram.voyager/bin/voyager-layout install-deps --with-dfu
```

This installs `zsa-zapp` from the AUR (and optionally `dfu-util` from official repos). You may be prompted for a password.

### 3. Configure your layouts

```bash
mkdir -p ~/.config/omarchy-voyager
cp ~/.config/omarchy/plugins/fram.voyager/config/layouts.toml.example \
   ~/.config/omarchy-voyager/layouts.toml
```

Edit `~/.config/omarchy-voyager/layouts.toml`:

1. In [Oryx](https://configure.zsa.io/voyager), open a layout you have **compiled**.
2. Copy the layout URL, for example:  
   `https://configure.zsa.io/voyager/layouts/xPOwx/latest`  
   or a specific revision:  
   `https://configure.zsa.io/voyager/layouts/xPOwx/PBM6GG`
3. Replace each `REPLACE_ME…` value with your real URLs.
4. Set `id` / `name` to whatever you like; `id` is what the CLI and bar use.

Example:

```toml
[settings]
default = "daily"
notify = true

[[layouts]]
id = "daily"
name = "Daily"
oryx = "https://configure.zsa.io/voyager/layouts/YOUR_ID/latest"
favorite = true

[[layouts]]
id = "gaming"
name = "Gaming"
oryx = "https://configure.zsa.io/voyager/layouts/OTHER_ID/latest"
favorite = true
```

You can also point at a local firmware file instead of (or in addition to) an Oryx URL:

```toml
file = "/home/YOU/.local/share/voyager/gaming.bin"
```

### 4. Optional: CLI on your PATH

```bash
ln -sfn ~/.config/omarchy/plugins/fram.voyager/bin/voyager-layout ~/.local/bin/voyager-layout
```

### 5. Optional: Omarchy menu entries

Merge the keys from  
`~/.config/omarchy/plugins/fram.voyager/menu/voyager-menu.jsonc`  
into `~/.config/omarchy/extensions/omarchy-menu.jsonc` (or run `./scripts/install.sh` from a git checkout, which can help with a fresh setup).

### 6. Optional: Hyprland hotkeys

See `hypr/bindings.lua.snippet`. Append the bindings you want into `~/.config/hypr/bindings.lua`. Suggested defaults:

| Shortcut | Action |
|----------|--------|
| `Super+Shift+V` | Layout picker, then flash |
| `Super+Shift+U` | Flash latest revision of what’s on the board (`zapp update`) |
| `Super+Shift+Alt+V` | Cycle layouts marked `favorite = true` |

Hotkeys **stage** a flash; you still must press **Reset** when prompted.

---

## Using the bar

1. Plug in the Voyager. The keyboard icon appears on the top bar (hidden when unplugged).
2. Left-click → dropdown under the icon (same pattern as Bluetooth / Power).
3. Choose a layout → a floating terminal runs the flash.
4. When you see **Waiting for keyboard in bootloader mode…**, press the Voyager **Reset** button **once** (top edge near the `3` key on the default layout, or a Reset key you mapped in Oryx).
5. Do **not** press Reset during download, and do **not** start a flash while the board is already in bootloader mode—unplug/replug first so keys work normally.

Other panel actions:

- **Flash latest revision** — `zapp update` for the layout already stored on the board  
- **Open current in Oryx** — opens the layout URL in your browser  
- **Install flash tools** / **Reinstall / check flash tools** — user-initiated AUR install  

---

## Flashing procedure (important)

Wrong timing is the most common cause of `USB transfer error: hardware fault or protocol violation`.

1. Voyager in **normal** mode (keys type). If unsure: unplug USB → wait 5s → plug **directly** into the laptop (no hub/dock), both halves joined with the TRRS cable.
2. Start flash (bar or CLI).
3. Wait for: `Waiting for keyboard in bootloader mode...`
4. Press **Reset once**.
5. Wait until the process finishes before unplugging.

Keep at least one known-good layout URL in your config so you can recover if a flash goes wrong.

---

## CLI reference

```bash
voyager-layout status              # USB mode, current layout, whether Zapp is installed
voyager-layout list                # Configured layouts
voyager-layout flash <id>          # Flash a layout from config (then Reset)
voyager-layout flash --latest      # Update layout already on the board
voyager-layout flash <id> --method dfu-util   # Fallback flasher
voyager-layout open [id]           # Open layout in Oryx
voyager-layout pick                # Omarchy menu picker, then flash
voyager-layout cycle-favorites     # Next favorite = true layout
voyager-layout install-deps        # Install Zapp (AUR)
voyager-layout install-deps --with-dfu -y
```

Config path: `~/.config/omarchy-voyager/layouts.toml`  
State (last flashed id): `~/.local/state/omarchy-voyager/current`

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| No bar icon | Plug in the Voyager; wait a few seconds; `omarchy restart shell` |
| Click does nothing / no dropdown | `omarchy restart shell` (rescan alone does not reload bar QML) |
| “zapp not found” | Bar → **Install flash tools**, or `voyager-layout install-deps` |
| `hardware fault or protocol violation` | Unplug/replug to normal mode; direct USB port; Reset only after the waiting line; or `--method dfu-util` |
| Flash starts with no waiting line | Board was already in bootloader — unplug/replug, then flash again |
| Layout URL errors | Compile the layout in Oryx first; use `/latest` or a real revision id |
| Want to remove the plugin | `omarchy plugin disable fram.voyager` then `omarchy plugin remove fram.voyager` |

Official ZSA flashing docs (for comparison / recovery): [zsa.io/flash](https://zsa.io/flash). This project does not replace Keymapp or ZSA support.

---

## Developer / local checkout

```bash
git clone git@github.com:fram74/omarchy-voyager.git
cd omarchy-voyager
./scripts/install.sh
voyager-layout install-deps --with-dfu
omarchy plugin validate .
```

Repo layout:

```text
manifest.json              # Required at git root for omarchy plugin add
BarWidget.qml / Panel.qml
bin/voyager-layout
config/layouts.toml.example
menu/  hypr/  scripts/
```

---

## License

Distributed under the [MIT License](LICENSE).

**Trademarks and products of ZSA Technology Labs, Basecamp, and others remain their property. This software is unofficial and unsupported by those parties. Use at your own risk.**
