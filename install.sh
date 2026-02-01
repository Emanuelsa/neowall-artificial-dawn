#!/usr/bin/env bash
# Artificial Dawn installer

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}!${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }
ask()   { read -rp "$* " response; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEOWALL_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/neowall"

# ─────────────────────────────────────────────────────────────
# Check requirements
# ─────────────────────────────────────────────────────────────

if ! command -v neowall >/dev/null; then
    error "neowall is required but not installed.

Install it from AUR:
  yay -S neowall-git

Then run this installer again."
fi

echo "Installing Artificial Dawn..."
echo ""

# Verify source files exist
[[ -f "$SCRIPT_DIR/artificial-dawn.glsl" ]] || error "Missing artificial-dawn.glsl"

# ─────────────────────────────────────────────────────────────
# Install shader
# ─────────────────────────────────────────────────────────────

mkdir -p "$NEOWALL_CONFIG_DIR"
cp "$SCRIPT_DIR/artificial-dawn.glsl" "$NEOWALL_CONFIG_DIR/"
log "Shader installed"

# ─────────────────────────────────────────────────────────────
# Install config (ask if exists)
# ─────────────────────────────────────────────────────────────

generate_config() {
    cat > "$NEOWALL_CONFIG_DIR/config.vibe" <<EOF
# Neowall config for Artificial Dawn
# 15fps saves CPU while still preventing burn-in

default {
  shader $NEOWALL_CONFIG_DIR/artificial-dawn.glsl
  shader_speed 1.0
  shader_fps 15
}
EOF
}

if [[ -f "$NEOWALL_CONFIG_DIR/config.vibe" ]]; then
    warn "You have an existing neowall config."
    ask "Replace it with Artificial Dawn config? [y/N]"
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp "$NEOWALL_CONFIG_DIR/config.vibe" "$NEOWALL_CONFIG_DIR/config.vibe.bak"
        generate_config
        log "Config replaced (backup: config.vibe.bak)"
    else
        log "Keeping your existing config"
    fi
else
    generate_config
    log "Config installed"
fi

# ─────────────────────────────────────────────────────────────
# Optional: Install daemon
# ─────────────────────────────────────────────────────────────

echo ""
echo "The smart daemon starts neowall only when needed (when you have"
echo "multiple tiled windows and gaps are visible). Otherwise neowall"
echo "stays off to save resources."
echo ""
ask "Install the smart daemon? [Y/n]"

if [[ ! "$response" =~ ^[Nn]$ ]]; then
    # Check daemon dependencies
    missing=()
    command -v hyprctl >/dev/null || missing+=("hyprland")
    command -v jq >/dev/null || missing+=("jq")
    command -v socat >/dev/null || missing+=("socat")

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Daemon requires: ${missing[*]}

Install with:
  sudo pacman -S ${missing[*]}"
    fi

    mkdir -p ~/.local/bin
    cp "$SCRIPT_DIR/hypr-oled-protect" ~/.local/bin/
    chmod +x ~/.local/bin/hypr-oled-protect
    log "Daemon installed to ~/.local/bin/hypr-oled-protect"

    # Check PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        warn "\$HOME/.local/bin is not in your PATH"
        echo "  Add to your shell config: export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi

    # Autostart
    hyprconf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
    if [[ -f "$hyprconf" ]]; then
        if grep -q "hypr-oled-protect" "$hyprconf"; then
            log "Autostart already configured"
        else
            ask "Add to Hyprland autostart? [Y/n]"
            if [[ ! "$response" =~ ^[Nn]$ ]]; then
                # Ensure newline before appending
                [[ -s "$hyprconf" && $(tail -c1 "$hyprconf" | wc -l) -eq 0 ]] && echo "" >> "$hyprconf"
                echo -e "# OLED burn-in protection\nexec-once = hypr-oled-protect start" >> "$hyprconf"
                log "Added to hyprland.conf"
            fi
        fi
    fi

    echo ""
    log "Done! Start the daemon with: hypr-oled-protect start"
else
    echo ""
    log "Done! Run neowall manually or add to your autostart."
fi
