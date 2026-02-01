# Artificial Dawn

A live gradient shader for [neowall](https://github.com/1ay1/neowall) that prevents OLED burn-in when using fixed-size Hyprland tiles for extended periods.

Five orbiting color blobs keep every pixel changing. Runs at 15fps (~0.9% CPU). Includes an optional daemon that activates only when wallpaper gaps are visible.

## Features

- **OLED-safe** — Constant pixel movement prevents static burn-in patterns
- **Low resource usage** — 15fps animation uses minimal CPU
- **Smart mode** — Optional daemon runs the shader only when wallpaper gaps are visible
- **Looks good** — Smooth purple/blue gradients

## Requirements

- [neowall](https://github.com/1ay1/neowall) — GPU shader wallpaper engine (`yay -S neowall-git`)
- Hyprland (for the smart daemon)
- `socat` and `jq` (for the smart daemon)

## Installation

```bash
git clone https://github.com/Emanuelsa/neowall-artificial-dawn.git
cd neowall-artificial-dawn
./install.sh
```

The installer will:
1. Copy the shader to `~/.config/neowall/`
2. Set up the neowall config
3. Optionally install the smart daemon

## Usage

**Always-on mode** (shader runs continuously):
```bash
neowall
```

**Smart mode** (shader runs only when needed):
```bash
hypr-oled-protect start   # Start the daemon
hypr-oled-protect stop    # Stop protection
hypr-oled-protect status  # Check current status
```

The smart daemon monitors your Hyprland windows. When you have 2+ tiled windows (meaning wallpaper gaps are visible), it starts neowall. When you're fullscreen or have a single window, it stops neowall to save resources.

## Configuration

Edit `~/.config/neowall/config.vibe`:

```
default {
  shader ~/.config/neowall/artificial-dawn.glsl
  shader_speed 1.0    # Animation speed (try 0.5 for slower)
  shader_fps 15       # Frames per second (15 is plenty for burn-in prevention)
}
```

To adjust the daemon's window threshold, edit `~/.local/bin/hypr-oled-protect`:
```bash
NEOWALL_MIN_WINDOWS=2  # Start neowall when >= this many tiled windows
```

## How it works

The shader renders 5 colored spotlights at different positions. Each spotlight orbits in an elliptical path at a slightly different speed and phase, creating organic-looking movement.

The colors blend smoothly based on distance from each spotlight center. A subtle brightness oscillation adds extra variation over time.

Technical details:
- No branching or loops in the shader hot path
- Uses `dot()` instead of `sqrt()` for distance calculations
- MAD-friendly math (multiply-add chains) for GPU efficiency
- Compile-time constant colors for optimization

