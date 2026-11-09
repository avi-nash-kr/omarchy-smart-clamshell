#!/usr/bin/env bash
# ==============================================================================
# omarchy-smart-clamshell uninstaller
# https://github.com/avi-nash-kr/omarchy-smart-clamshell
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BIN_DIR="$HOME/.local/bin"
HOOKS_DIR="$HOME/.config/omarchy/hooks/post-boot.d"
CONFIG_FILE="$HOME/.config/omarchy/display-mode.conf"
HYPR_BINDINGS="$HOME/.config/hypr/bindings.lua"
TOGGLES_DIR="$HOME/.local/state/omarchy/toggles/hypr"
PLUGIN_ID="avinash-omarchy.clamshell"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

echo -e "${BOLD}${BLUE}==> Uninstalling omarchy-smart-clamshell...${NC}"

# 1. Remove binaries
echo -e "${BLUE}==> Removing binaries from $BIN_DIR...${NC}"
rm -f "$BIN_DIR/display-mode"
rm -f "$BIN_DIR/omarchy-hyprland-monitor-clamshell"
rm -f "$BIN_DIR/omarchy-system-lid-close"

# 2. Remove hook and configs
echo -e "${BLUE}==> Removing hooks and configuration...${NC}"
rm -f "$HOOKS_DIR/display-mode-sync.sh"
rm -f "$CONFIG_FILE"
rm -f "$TOGGLES_DIR/internal-monitor-mirror.lua.clamshell-paused"

# 2b. Remove the Clamshell bar widget
echo -e "${BLUE}==> Removing the Clamshell bar widget...${NC}"
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable "$PLUGIN_ID" >/dev/null 2>&1 || true
fi
rm -rf "$PLUGIN_DIR"

# 3. Clean up Hyprland bindings
if [[ -f "$HYPR_BINDINGS" ]]; then
  if grep -q "omarchy-smart-clamshell" "$HYPR_BINDINGS"; then
    echo -e "${BLUE}==> Reverting $HYPR_BINDINGS (backup created)...${NC}"
    cp "$HYPR_BINDINGS" "${HYPR_BINDINGS}.bak.$(date +%s)"
    sed -i '/-- >>> omarchy-smart-clamshell >>>/,/-- <<< omarchy-smart-clamshell <<</d' "$HYPR_BINDINGS"
  fi
fi

# 4. Reload Hyprland
echo -e "${BLUE}==> Reloading Hyprland...${NC}"
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo -e "\n${BOLD}${GREEN}✔ omarchy-smart-clamshell has been uninstalled.${NC}\n"
