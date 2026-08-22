# Visual guide — Omarchy Voyager Layouts

Screenshots captured on an **external monitor** (empty wallpaper workspace) with a ZSA Voyager connected, so no personal app windows appear.  
Plugin version **0.0.1**. For install details, legal disclaimer, and troubleshooting, see the [main README](../../README.md).

> **Unofficial.** Not affiliated with ZSA Technology Labs. Flashing firmware is at your own risk.

---

## 1. Find the icon on the top bar

When the Voyager is plugged in, a **keyboard icon** appears on the right side of the Omarchy top bar (between the system tray and Agents / Bluetooth).

![Top bar with Voyager keyboard icon](images/bar.png)

Closer look — the keyboard glyph is the Voyager control (here between the tray icons and the Agents “A” badge):

![Voyager icon detail on the bar](images/bar-icon.png)

If the keyboard is unplugged, the icon **hides** automatically.

---

## 2. Open the dropdown

**Left-click** the keyboard icon. A panel drops down under the bar (same pattern as Bluetooth or Power):

![Bar with Voyager dropdown open](images/dropdown-context.png)

---

## 3. What’s in the panel

![Voyager layouts dropdown](images/dropdown.png)

| Row | What it does |
|-----|----------------|
| **Daily / Gaming / Coding** (your names) | Flash that Oryx layout. A floating terminal opens; press **Reset** on the Voyager when prompted. |
| **Flash latest revision** | Runs `zapp update` for the layout already on the board. |
| **Open current in Oryx** | Opens the layout in your browser to edit. |
| **Install / Reinstall flash tools** | Installs Zapp from the AUR (and optionally `dfu-util`). Required once before the first flash. |

Header shows connection status and the last recorded layout (e.g. `Current · daily`).

---

## 4. Desktop context

Full desktop with the panel open:

![Desktop overview with Voyager panel](images/desktop-overview.jpg)

---

## 5. Flashing (short version)

1. Keys must work (**normal** mode). If unsure: unplug → wait 5s → plug in directly (no hub).
2. Click a layout in the dropdown.
3. In the floating terminal, wait for:  
   `Waiting for keyboard in bootloader mode...`
4. Press the Voyager **Reset** button **once**.
5. Wait until flashing finishes.

Full procedure, config (`layouts.toml`), CLI, and recovery tips: **[README](../../README.md)**.

---

## 6. Install this plugin

```bash
omarchy plugin add https://github.com/fram74/omarchy-voyager.git --enable
```

Then open the bar icon → **Install flash tools** → copy `config/layouts.toml.example` to `~/.config/omarchy-voyager/layouts.toml` and paste your Oryx URLs.
