#!/usr/bin/env bash
# ==============================================================================
# omarchy-smart-clamshell installer
# https://github.com/avi-nash-kr/omarchy-smart-clamshell
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
HOOKS_DIR="$HOME/.config/omarchy/hooks/post-boot.d"
CONFIG_DIR="$HOME/.config/omarchy"
HYPR_BINDINGS="$HOME/.config/hypr/bindings.lua"

echo -e "${BOLD}${BLUE}==> Installing omarchy-smart-clamshell...${NC}"

# Check prerequisites
for cmd in hyprctl jq sed grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${RED}Error: Required command '$cmd' is not installed.${NC}" >&2
    exit 1
  fi
done

# 1. Create target directories
echo -e "${BLUE}==> Creating directories...${NC}"
mkdir -p "$BIN_DIR" "$HOOKS_DIR" "$CONFIG_DIR"

# 2. Install binaries
echo -e "${BLUE}==> Installing helper binaries to $BIN_DIR...${NC}"
cp -f "$SCRIPT_DIR/bin/"* "$BIN_DIR/"
chmod +x "$BIN_DIR/display-mode"
chmod +x "$BIN_DIR/omarchy-hyprland-monitor-clamshell"
chmod +x "$BIN_DIR/omarchy-system-lid-close"

# 3. Install desktop startup sync hook
echo -e "${BLUE}==> Installing post-boot hook...${NC}"
cp -f "$SCRIPT_DIR/hooks/display-mode-sync.sh" "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/display-mode-sync.sh"

# 4. Initialize display mode configuration if absent
if [[ ! -f "$CONFIG_DIR/display-mode.conf" ]]; then
  echo -e "${BLUE}==> Setting default display mode to 'mirror'...${NC}"
  echo "mode=mirror" > "$CONFIG_DIR/display-mode.conf"
fi

# 5. Patch Hyprland bindings
if [[ -f "$HYPR_BINDINGS" ]]; then
  if grep -q "omarchy-smart-clamshell" "$HYPR_BINDINGS"; then
    echo -e "${YELLOW}==> Hyprland bindings already contain omarchy-smart-clamshell overrides. Skipping.${NC}"
  else
    echo -e "${BLUE}==> Updating $HYPR_BINDINGS (backup created)...${NC}"
    cp "$HYPR_BINDINGS" "${HYPR_BINDINGS}.bak.$(date +%s)"
    cat >> "$HYPR_BINDINGS" << 'EOF'

-- >>> omarchy-smart-clamshell >>>
-- Override lid switch handlers to support seamless clamshell mode with mirroring & workspace migration
hl.unbind("switch:on:Lid Switch")
hl.unbind("switch:off:Lid Switch")
o.bind("switch:on:Lid Switch", nil, os.getenv("HOME") .. "/.local/bin/omarchy-system-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, os.getenv("HOME") .. "/.local/bin/omarchy-hyprland-monitor-clamshell", { locked = true })

-- Override display mirror toggle to use persistent display-mode manager
hl.unbind("SUPER + CTRL + ALT + Delete")
o.bind("SUPER + CTRL + ALT + Delete", "Toggle display mode", os.getenv("HOME") .. "/.local/bin/display-mode toggle")
-- <<< omarchy-smart-clamshell <<<
EOF
  fi
fi

# 6. Reload Hyprland configuration
echo -e "${BLUE}==> Reloading Hyprland configuration...${NC}"
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
  ERRORS=$(hyprctl configerrors 2>/dev/null || true)
  if [[ -n "$ERRORS" ]]; then
    echo -e "${YELLOW}Warning: Hyprland reported config notices:${NC}\n$ERRORS"
  fi
fi

echo -e "\n${BOLD}${GREEN}✔ Installation complete!${NC}\n"
echo -e "${BOLD}Quick Usage:${NC}"
echo -e "  • ${GREEN}display-mode status${NC}   - View current mode"
echo -e "  • ${GREEN}display-mode mirror${NC}   - Set Mirror mode (duplicates when open; standalone on lid close)"
echo -e "  • ${GREEN}display-mode extended${NC} - Set Extended mode (dual screen when open; standalone on lid close)"
echo -e "  • ${GREEN}display-mode toggle${NC}   - Toggle between modes (or press ${BOLD}Super + Ctrl + Alt + Delete${NC})"
echo -e "\nClose your laptop lid at any time to verify the smooth transition!\n"
