#!/bin/bash
# Installs the udev rule that lets your user drive the keyboard lighting
# (needs sudo once), links the kbd-color command, copies the plugin into the
# shell's plugin folder, installs the theme-set hook and puts the widget on
# the bar. Safe to run again.
#
# Usage: install.sh [--yes]

set -euo pipefail

PLUGIN_ID="io.github.markosamo.keyboard-color"
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLED_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
UDEV_RULE="/etc/udev/rules.d/70-kbd-color.rules"
BIN_LINK="$HOME/.local/bin/kbd-color"
FILES=(manifest.json Service.qml BarWidget.qml bin hooks udev install.sh uninstall.sh)

ASSUME_YES=0
[[ ${1:-} == "--yes" || ${1:-} == "-y" ]] && ASSUME_YES=1

confirm() {
  (( ASSUME_YES )) && return 0
  if [[ -t 0 ]]; then
    read -r -p "$1 [y/N] " answer
    [[ $answer == [yY]* ]]
  else
    echo "Not running interactively; pass --yes to confirm." >&2
    return 1
  fi
}

if ! cmp -s "$PLUGIN_DIR/udev/70-kbd-color.rules" "$UDEV_RULE"; then
  echo "This installs $UDEV_RULE (with sudo) so your user can"
  echo "send lighting commands to the keyboard without root."
  confirm "Continue?" || { echo "Aborted; nothing was changed."; exit 1; }
  sudo install -m 644 "$PLUGIN_DIR/udev/70-kbd-color.rules" "$UDEV_RULE"
  sudo udevadm control --reload-rules
  sudo udevadm trigger --subsystem-match=hidraw --action=change
  sudo udevadm settle
fi

# The shell only discovers plugins under ~/.config/omarchy/plugins. When run
# from a local clone, copy the plugin there first.
if [[ $PLUGIN_DIR != "$INSTALLED_DIR" ]]; then
  echo "Copying the plugin to $INSTALLED_DIR"
  mkdir -p "$INSTALLED_DIR"
  for f in "${FILES[@]}"; do cp -r "$PLUGIN_DIR/$f" "$INSTALLED_DIR"/; done
fi

mkdir -p "$(dirname "$BIN_LINK")"
ln -sfn "$INSTALLED_DIR/bin/kbd-color" "$BIN_LINK"

# Re-colour the keyboard on every theme change, whichever app sets the theme.
omarchy hook install theme-set "$INSTALLED_DIR/hooks/kbd-color.hook" >/dev/null

omarchy-shell shell rescanPlugins >/dev/null
# The rescan finishes in the background; wait until the shell knows the id.
for _ in {1..20}; do
  omarchy-shell shell listPlugins | grep -qF "\"$PLUGIN_ID\"" && break
  sleep 0.25
done
omarchy plugin enable "$PLUGIN_ID"
omarchy bar put "$PLUGIN_ID" --section right --index 0 >/dev/null 2>&1 || true
# A running service keeps its old code across plugin reloads until the shell restarts.
omarchy restart shell

"$BIN_LINK" sync || true
echo "Done: the keyboard icon is on the bar. Try 'kbd-color --help'."
