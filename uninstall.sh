#!/bin/bash
# Undoes install.sh: disables the shell plugin, removes the kbd-color link,
# the theme-set hook and (with sudo) the udev rule. The keyboard keeps its last colour.

set -euo pipefail

PLUGIN_ID="io.github.markosamo.keyboard-color"
UDEV_RULE="/etc/udev/rules.d/70-kbd-color.rules"
BIN_LINK="$HOME/.local/bin/kbd-color"

omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
[[ -L $BIN_LINK ]] && rm -f "$BIN_LINK"
rm -f "$HOME/.config/omarchy/hooks/theme-set.d/kbd-color.hook"

if [[ -f $UDEV_RULE ]]; then
  sudo rm -f "$UDEV_RULE"
  sudo udevadm control --reload-rules
  echo "Removed $UDEV_RULE"
fi

echo "Uninstalled. To delete the files too: omarchy plugin remove $PLUGIN_ID"
