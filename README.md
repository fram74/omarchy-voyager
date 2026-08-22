# Omarchy Voyager Layouts

Switch among [ZSA Voyager](https://www.zsa.io/) [Oryx](https://configure.zsa.io/) layouts from Omarchy: bar dropdown, menu, and CLI.

This is **firmware layout profiles** (flash via [Zapp](https://github.com/zsa/zapp)). It is separate from Omarchy’s `omarchy.keyboard-layout` widget (xkb languages).

## Install (community)

Omarchy **does not** run package installs when you add a plugin. Flash tools are installed on demand (bar button or CLI).

```bash
omarchy plugin add https://github.com/fram74/omarchy-voyager.git --enable
```

Then:

1. Open the keyboard icon on the bar (appears when a Voyager is plugged in).
2. If Zapp is missing, tap **Install flash tools** (installs `zsa-zapp` from the AUR, and optionally `dfu-util`).
3. Copy and edit config:

```bash
mkdir -p ~/.config/omarchy-voyager
cp ~/.config/omarchy/plugins/fram.voyager/config/layouts.toml.example \
   ~/.config/omarchy-voyager/layouts.toml
# Put your Oryx layout URLs in layouts.toml
```

Optional: put the CLI on `PATH`:

```bash
ln -s ~/.config/omarchy/plugins/fram.voyager/bin/voyager-layout ~/.local/bin/voyager-layout
```

### Local checkout

```bash
git clone git@github.com:fram74/omarchy-voyager.git
cd omarchy-voyager
./scripts/install.sh
voyager-layout install-deps --with-dfu
```

## Why flash tools are not auto-installed

From Omarchy’s plugin docs: the installer never runs plugin hooks or sudo — it only clones and enables. Installing AUR packages requires an explicit user action. This plugin surfaces that as **Install flash tools** in the dropdown (`voyager-layout install-deps`).

## Usage

| Action | How |
|--------|-----|
| Pick & flash a layout | Click the bar keyboard icon → choose a layout |
| Install Zapp | Bar → **Install flash tools**, or `voyager-layout install-deps` |
| CLI | `voyager-layout list` / `status` / `flash <id>` / `pick` |

Flashing always needs bootloader mode: wait for the waiting line, then press **Reset** once on the Voyager.

### USB protocol errors

If you see `hardware fault or protocol violation`:

1. Unplug, wait 5s, replug (keys must work — normal mode).
2. Direct laptop USB port, no hub.
3. Press Reset only **after** `Waiting for keyboard in bootloader mode...`
4. Fallback: `voyager-layout flash <id> --method dfu-util`

## Config

`~/.config/omarchy-voyager/layouts.toml` — see `config/layouts.toml.example`.

## Repo layout

```text
manifest.json                 # Omarchy plugin (must be at git root)
BarWidget.qml / Panel.qml
bin/voyager-layout            # CLI (also used by the bar)
config/layouts.toml.example
menu/ hypr/ scripts/
```

Validate before publishing:

```bash
omarchy plugin validate .
```

## License

MIT — not affiliated with ZSA or Basecamp Omarchy.
