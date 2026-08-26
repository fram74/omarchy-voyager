# Visual guide — Omarchy Voyager Layouts

Demos captured on an **external monitor** (empty wallpaper workspace) with a ZSA Voyager connected, so no personal app windows appear.  
Plugin version **0.2.4**. For install details, legal disclaimer, and troubleshooting, see the [main README](../../README.md).

> **Unofficial.** Not affiliated with ZSA Technology Labs. Flashing firmware is at your own risk.

---

## Demo — top bar dropdown

**Left-click** the keyboard icon on the Omarchy top bar:

[![Top bar Voyager dropdown demo](https://img.youtube.com/vi/If5TmJpFCKQ/maxresdefault.jpg)](https://www.youtube.com/watch?v=If5TmJpFCKQ&autoplay=1)

[Watch on YouTube](https://youtu.be/If5TmJpFCKQ)

---

## Demo — Super+Space menu

**Super+Space** → *Omarchy Voyager Layouts*:

[![Super+Space Voyager menu demo](https://img.youtube.com/vi/pZb-h5aKjsg/maxresdefault.jpg)](https://www.youtube.com/watch?v=pZb-h5aKjsg&autoplay=1)

[Watch on YouTube](https://youtu.be/pZb-h5aKjsg)

---

## 1. Find the icon on the top bar

When the Voyager is plugged in, a **keyboard icon** appears on the right side of the Omarchy top bar (between the system tray and Agents / Bluetooth).

If the keyboard is unplugged, the icon **hides** automatically.

---

## 2. Open the UI

| How | What you get |
|-----|----------------|
| **Left-click** the keyboard icon | Dropdown panel under the bar (same pattern as Bluetooth or Power) |
| **Super+Space** → *Omarchy Voyager Layouts* | Full Omarchy menu entry for the same actions |

---

## 3. What’s in the panel

| Row | What it does |
|-----|----------------|
| **Layout rows** (Oryx titles) | Flash that layout. A floating terminal opens; press **Reset** when prompted. Trash icon removes it from the config. |
| **Add from Oryx URL** | Opens a text field — paste with Ctrl+V (or **Clipboard**). Pins the compiled image by SHA-256. Name comes from the Oryx layout title. |
| **Re-pin & flash latest** | Re-pin the current layout to Oryx latest, verify SHA-256, then flash. |
| **Open current in Oryx** | Opens the layout in your browser to edit. |
| **Install flash tools** | Shown when Zapp is missing. Tap it in the dropdown — do not run a terminal install unless you want to. |
| **Reinstall / check flash tools** | Same action after Zapp is already installed. |

Header shows connection status and the active layout (e.g. `Layout · Elixir Development`). If flash tools are missing, the header says `Connected · install Zapp to flash` and layout rows stay dimmed until you use the button.

---

## 4. Install flash tools (once, from the dropdown)

Omarchy’s plugin adder only clones this repo. It does **not** install Zapp. You do that from the **same dropdown**, not from a command you have to copy.

1. Plug in the Voyager so the keyboard icon appears.
2. **Left-click** the icon.
3. Tap **Install flash tools**.
4. A floating terminal installs `zsa-zapp` from the AUR (and `dfu-util`). A sudo/password prompt is normal.
5. When it finishes, the panel reloads; layout rows become usable.

You only need this once. Later, **Reinstall / check flash tools** is at the bottom of the dropdown if something is missing.

The CLI (`voyager-layout install-deps`) is optional and documented in the [README](../../README.md).

---

## 5. Add layouts (from the dropdown)

Still in the bar dropdown: **Add from Oryx URL**. Paste a compiled share link with **Ctrl+V** (or **Clipboard**). The plugin pins that firmware (revision + SHA-256) into `~/.config/omarchy-voyager/layouts.toml`.

---

## 6. Flashing (short version)

1. Flash tools installed (section 4) and at least one layout added (section 5).
2. Keys must work (**normal** mode). If unsure: unplug → wait 5s → plug in directly (no hub).
3. Pick a layout **from the dropdown** (or Super+Space).
4. In the floating terminal, wait for:  
   `Waiting for keyboard in bootloader mode...`
5. Press the Voyager **Reset** button **once**.
6. Wait until flashing finishes.

Full procedure, config (`layouts.toml`), CLI, and recovery tips: **[README](../../README.md)**.

---

## 7. Install this plugin

The only command most people need:

```bash
omarchy plugin add https://github.com/fram74/omarchy-voyager.git --enable
```

Then stay on the bar: icon → **Install flash tools** → **Add from Oryx URL** → tap a layout to flash.

Plugin id: `net.moggia.voyager-layouts`

```sh
omarchy plugin disable net.moggia.voyager-layouts
omarchy plugin remove net.moggia.voyager-layouts
```

---

## 8. Developer testing

Validate, load a local checkout, CLI tests, and a live-UI checklist: **[TESTING.md](TESTING.md)**.
