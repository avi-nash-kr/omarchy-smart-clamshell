#!/bin/bash
# Sync display mode and reconcile clamshell state on desktop startup

CONF="$HOME/.config/omarchy/display-mode.conf"
if [[ -f $CONF ]]; then
  mode=$(sed -n 's/^mode=//p' "$CONF")
  if [[ "$mode" == "extended" ]]; then
    "$HOME/.local/bin/display-mode" extended >/dev/null 2>&1 || true
  elif [[ "$mode" == "mirror" ]]; then
    "$HOME/.local/bin/display-mode" mirror >/dev/null 2>&1 || true
  fi
fi

"$HOME/.local/bin/omarchy-hyprland-monitor-clamshell" >/dev/null 2>&1 || true
