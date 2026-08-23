# Visual guide — Omarchy Voyager Layouts

Demos captured on an **external monitor** (empty wallpaper workspace) with a ZSA Voyager connected, so no personal app windows appear.  
Plugin version **0.0.1**. For install details, legal disclaimer, and troubleshooting, see the [main README](../../README.md).

> **Unofficial.** Not affiliated with ZSA Technology Labs. Flashing firmware is at your own risk.

---

## Demo — top bar dropdown

**Left-click** the keyboard icon on the Omarchy top bar:

[![Top bar Voyager dropdown demo](https://img.youtube.com/vi/If5TmJpFCKQ/maxresdefault.jpg)](https://www.youtube.com/watch?v=If5TmJpFCKQ&autoplay=1)

[Watch on YouTube](https://youtu.be/If5TmJpFCKQ)

---

## Demo — Super+Space menu

**Super+Space** → *Omarchy Voyager Layouts*:

<video src="images/super-ui.mp4" controls width="100%"></video>

[Open super-ui.mp4](images/super-ui.mp4)

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
| **Daily / Gaming / Coding** (your names) | Flash that Oryx layout. A floating terminal opens; press **Reset** on the Voyager when prompted. |
| **Flash latest revision** | Runs `zapp update` for the layout already on the board. |
| **Open current in Oryx** | Opens the layout in your browser to edit. |
| **Install / Reinstall flash tools** | Installs Zapp from the AUR (and optionally `dfu-util`). Required once before the first flash. |

Header shows connection status and the last recorded layout (e.g. `Current · daily`).

---

## 4. Flashing (short version)

1. Keys must work (**normal** mode). If unsure: unplug → wait 5s → plug in directly (no hub).
2. Pick a layout from the dropdown or Super+Space menu.
3. In the floating terminal, wait for:  
   `Waiting for keyboard in bootloader mode...`
4. Press the Voyager **Reset** button **once**.
5. Wait until flashing finishes.

Full procedure, config (`layouts.toml`), CLI, and recovery tips: **[README](../../README.md)**.

---

## 5. Install this plugin

```bash
omarchy plugin add https://github.com/fram74/omarchy-voyager.git --enable
```

Then open the bar icon → **Install flash tools** → copy `config/layouts.toml.example` to `~/.config/omarchy-voyager/layouts.toml` and paste your Oryx URLs.
