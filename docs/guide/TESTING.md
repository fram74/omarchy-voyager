# Developer testing — Omarchy Voyager Layouts

How to test this plugin on a real Omarchy session. Omarchy does **not** ship a QML test runner for third-party plugins. The official automated check is `omarchy plugin validate`; everything else is load-it-and-use-it, plus ordinary tests for the CLI.

User-facing walkthrough: [GUIDE.md](GUIDE.md). Install, flashing, and legal notes: [README](../../README.md).

Plugin id: `net.moggia.voyager-layouts`  
CLI: `voyager-layout` (`voyager-layouts` is the same binary)

---

## Loop

```text
validate  →  enable / rescan  →  CLI tests  →  click through the UI  →  (optional) flash hardware
```

If QML looks stale after an edit: `omarchy-shell shell rescanPlugins`, then `omarchy restart shell`.

---

## 1. Manifest (required before publish)

Same checks the shell and `omarchy plugin add` use: `schemaVersion: 1`, required fields, id not in `omarchy.*`, entry points exist and are safe relative paths, **no symlinks inside** the plugin folder.

```bash
cd /path/to/omarchy-voyager
omarchy plugin validate .
```

Exit 0 means the shell will accept the folder. A whole-directory symlink of the checkout into `~/.config/omarchy/plugins/<id>/` is allowed; a symlink *inside* the folder is not.

---

## 2. Load a local checkout

Do **not** `git clone` and pipe into the installer. From this repo:

```bash
./scripts/install.sh
voyager-layout install-deps --with-dfu
omarchy plugin validate .
omarchy plugin enable net.moggia.voyager-layouts --section right
omarchy-shell shell rescanPlugins
```

`install.sh` links this checkout to `~/.config/omarchy/plugins/net.moggia.voyager-layouts/` and puts `voyager-layout` / `voyager-layouts` on `~/.local/bin`.

Confirm the shell sees it:

```bash
omarchy plugin list
omarchy-shell shell listPlugins
omarchy-shell shell ping
```

Saving files under `~/.config/omarchy/plugins/` reloads plugin QML. `~/.config/omarchy/shell.json` hot-reloads too.

If the bar widget is missing or the dropdown is empty after a QML change, restart the shell (`rescanPlugins` does not always reload bar QML):

```bash
omarchy restart shell
```

---

## 3. CLI unit tests (no keyboard, no network)

Pinning, URL parsing, SHA-256 checks, and the Oryx allowlist:

```bash
python3 tests/test_firmware_pin.py
```

Smoke the installed command (this *does* talk to USB/Oryx when you pin or flash):

```bash
voyager-layout status --json
voyager-layout list --json
voyager-layout pin --all
```

The bar panel parses `--json` stdout. Progress logs go to **stderr** so they do not break that parse.

Stock Oryx layout id `default` is special: latest firmware is  
`https://oryx.zsa.io/firmware/latest/voyager/default`, not `/firmware/latest/default`.

---

## 4. Live UI checklist

Plug in a Voyager. Work through this on the running desktop — a screenshot is not enough.

| Step | Expected |
|------|----------|
| Unplug USB | Keyboard icon **hides** from the bar |
| Plug in, wait a few seconds | Icon **appears** (right section by default) |
| Left-click icon | Dropdown under the icon (Bluetooth / Power pattern) |
| No Zapp | Panel offers **Install flash tools**; layouts are dimmed |
| **Add from Oryx URL** | Text field; Ctrl+V paste; name from Oryx title; firmware **pinned** (revision + sha256 in `~/.config/omarchy-voyager/layouts.toml`) |
| Layout row | Floating terminal; wait for `Waiting for keyboard in bootloader mode...`; Reset **once** |
| Trash on a non-current row | Layout removed from config |
| **Re-pin & flash latest** | Re-pins current layout to Oryx latest, verifies digest, then flashes |
| **Open current in Oryx** | Browser opens the pinned layout URL |
| Super+Space → Voyager (if you merged `menu/voyager-menu.jsonc`) | Same actions as the panel |

IPC from a terminal (opens the panel as a hotkey would):

```bash
omarchy-shell -q net.moggia.voyager-layouts addUrl
```

---

## 5. Hardware flash (optional, destructive)

Flashing can brick or interrupt the board. Use a layout you can recover.

1. Keys work (**normal** mode). If unsure: unplug → 5s → plug into a laptop port (no hub).
2. Start flash from the bar or `voyager-layout flash <id>`.
3. Wait for the waiting line, **then** press Reset once.
4. Confirm `~/.local/state/omarchy-voyager/current` matches the id and the keys match that layout.

Wrong timing is the usual `USB transfer error: hardware fault or protocol violation`. Retry with `--method dfu-util` only after a clean unplug/replug.

---

## 6. Marketplace listing

Push the commit, then the listing issue re-runs Quattro compatibility and the automated security baseline against **that exact SHA**. That scan does not execute the plugin.

Locally, before you push:

```bash
omarchy plugin validate .
python3 tests/test_firmware_pin.py
```

The baseline treats clone-then-`./scripts/install.sh` as unpinned remote execution. Keep the developer path as “from an existing checkout.” Firmware flash must stay bound to a stored revision + SHA-256.

---

## Pitfalls

| Symptom | Likely cause |
|---------|----------------|
| `command not found: voyager-layouts` | CLI is `voyager-layout`; link the plural name too (`install.sh` does) |
| `omarchy plugin validate` fails on symlinks | No symlinks *inside* the plugin folder |
| Bar still on old code | Plugin dir is a separate clone, not this checkout — re-run `./scripts/install.sh` or restart the shell |
| `Oryx HTTP 404` for `/firmware/latest/default` | Need the geometry-qualified URL (fixed in 0.2.x); re-run `./voyager-layout pin --all` from this repo |
| `not pinned (missing sha256)` | `layouts.toml` from 0.1.x — `voyager-layout pin --all` |
| Click does nothing / no dropdown | `omarchy restart shell` |
| Add from the bar fails JSON parse | CLI printed progress on stdout; it must stay on stderr |

---

## Remove a test install

```bash
omarchy plugin disable net.moggia.voyager-layouts
omarchy plugin remove net.moggia.voyager-layouts
```

That does not delete `~/.config/omarchy-voyager/` or the CLI symlinks; see [README → Remove](../../README.md#remove).
