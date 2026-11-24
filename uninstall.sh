#!/bin/bash
# Undoes install.sh: disables the shell plugin, removes the fluid-lights link,
# the theme-set hook and (with sudo) the udev rule. The keyboard keeps its last colour.

set -euo pipefail

PLUGIN_ID="io.github.markosamo.fluid-lights"
UDEV_RULE="/etc/udev/rules.d/70-fluid-lights.rules"
BIN_LINK="$HOME/.local/bin/fluid-lights"

omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
[[ -L $BIN_LINK ]] && rm -f "$BIN_LINK"
rm -f "$HOME/.config/omarchy/hooks/theme-set.d/fluid-lights.hook"

if [[ -f $UDEV_RULE ]]; then
  sudo rm -f "$UDEV_RULE"
  sudo udevadm control --reload-rules
  echo "Removed $UDEV_RULE"
fi

echo "Uninstalled. To delete the files too: omarchy plugin remove $PLUGIN_ID"
