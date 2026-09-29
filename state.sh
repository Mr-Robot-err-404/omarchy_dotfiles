#!/usr/bin/env bash
set -euo pipefail

target=${1:-state}

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
: > "$target"

cat \
  install-gaming.sh \
  system/usr/local/bin/gamescope-steam-session \
  system/usr/local/bin/steamos-session-select \
  system/usr/local/bin/touch_grass \
  system/usr/local/share/wayland-sessions/gamescope-steam.desktop \
  system/etc/sddm.conf.d/99-z-gaming-login.conf \
  system/usr/local/share/sddm/themes/omarchy-dual/Main.qml \
  system/usr/local/share/sddm/themes/omarchy-dual/metadata.desktop \
  system/usr/local/share/sddm/themes/omarchy-dual/theme.conf \
  home/.config/sunshine/apps.json \
  home/.config/sunshine/sunshine.conf \
  >> "$target"
