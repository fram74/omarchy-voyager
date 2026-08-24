#!/usr/bin/env bash
# Local / developer install of the Voyager plugin + CLI onto this Omarchy user.
# Community users should prefer:  omarchy plugin add <git-url> --enable
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-voyager"
PLUGIN_ID="net.moggia.voyager-layouts"
PLUGIN_DST="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/${PLUGIN_ID}"
MENU_EXT="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/extensions/omarchy-menu.jsonc"

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$(dirname "$PLUGIN_DST")"

chmod +x "$ROOT/bin/voyager-layout"
ln -sfn "$ROOT/bin/voyager-layout" "$BIN_DIR/voyager-layout"
# Plugin id is plural; PATH alias only (never a symlink inside the plugin tree —
# omarchy plugin validate / marketplace Quattro reject inner symlinks).
ln -sfn "$ROOT/bin/voyager-layout" "$BIN_DIR/voyager-layouts"

if [[ ! -f "$CONFIG_DIR/layouts.toml" ]]; then
  cp "$ROOT/config/layouts.toml.example" "$CONFIG_DIR/layouts.toml"
  echo "Wrote $CONFIG_DIR/layouts.toml — edit in your Oryx URLs."
else
  echo "Keeping existing $CONFIG_DIR/layouts.toml"
fi

# Point Omarchy at this checkout (no nested plugin/ dir — manifest is at repo root).
# Note: omarchy plugin validate forbids symlinks *inside* the plugin folder;
# linking the whole checkout from ~/.config/omarchy/plugins/ is fine for local use.
ln -sfn "$ROOT" "$PLUGIN_DST"
echo "Plugin linked at $PLUGIN_DST"

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin enable "$PLUGIN_ID" --section right 2>/dev/null \
    || omarchy plugin enable "$PLUGIN_ID" 2>/dev/null \
    || echo "Enable manually: omarchy plugin enable $PLUGIN_ID --section right"
  omarchy-shell shell rescanPlugins 2>/dev/null || true
fi

if [[ -f "$MENU_EXT" ]] && ! grep -q '"voyager"' "$MENU_EXT" 2>/dev/null; then
  echo "Merge menu keys from $ROOT/menu/voyager-menu.jsonc into $MENU_EXT"
fi

echo ""
echo "Flash tools (Zapp) are NOT installed by the plugin adder."
echo "  Install now:  voyager-layout install-deps --with-dfu"
echo "  Or from the bar dropdown: Install flash tools"
echo ""
echo "Try: voyager-layout status"
