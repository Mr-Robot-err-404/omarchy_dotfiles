#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BACKUP_ROOT="$HOME/.local/state/personal-backup/backups/$(date +%Y%m%d-%H%M%S)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

link_config() {
  local source=$1 target=$2 relative
  mkdir -p -- "$(dirname -- "$target")"

  if [[ -L $target && $(readlink -f -- "$target") == $(readlink -f -- "$source") ]]; then
    return
  fi

  if [[ -e $target || -L $target ]]; then
    relative=${target#"$HOME"/}
    mkdir -p -- "$BACKUP_ROOT/$(dirname -- "$relative")"
    mv -- "$target" "$BACKUP_ROOT/$relative"
    printf 'backed up %s to %s\n' "$target" "$BACKUP_ROOT/$relative"
  fi

  ln -s -- "$source" "$target"
}

[[ $EUID -ne 0 ]] || die "run this script as your normal user, not root"
command -v omarchy >/dev/null || die "Omarchy is required"
command -v sudo >/dev/null || die "sudo is required"

omarchy pkg add gamescope
omarchy pkg aur add sunshine

link_config \
  "$REPO_DIR/home/.config/sunshine/apps.json" \
  "$HOME/.config/sunshine/apps.json"
link_config \
  "$REPO_DIR/home/.config/sunshine/sunshine.conf" \
  "$HOME/.config/sunshine/sunshine.conf"

# Autologin bypasses session selection and makes failed sessions harder to recover.
sudo rm -f /etc/sddm.conf.d/autologin.conf
sudo install -Dm644 \
  "$REPO_DIR/system/etc/sddm.conf.d/99-z-gaming-login.conf" \
  /etc/sddm.conf.d/99-z-gaming-login.conf

[[ -f /usr/local/share/wayland-sessions/omarchy.desktop ]] || \
  die "Omarchy session is missing: /usr/local/share/wayland-sessions/omarchy.desktop"

sudo install -Dm644 \
  "$REPO_DIR/system/usr/local/share/wayland-sessions/gamescope-steam.desktop" \
  /usr/local/share/wayland-sessions/gamescope-steam.desktop
sudo install -Dm755 \
  "$REPO_DIR/system/usr/local/bin/gamescope-steam-session" \
  /usr/local/bin/gamescope-steam-session
sudo install -Dm755 \
  "$REPO_DIR/system/usr/local/bin/steamos-session-select" \
  /usr/local/bin/steamos-session-select

for theme_file in Main.qml metadata.desktop theme.conf; do
  sudo install -Dm644 \
    "$REPO_DIR/system/usr/local/share/sddm/themes/omarchy-dual/$theme_file" \
    "/usr/local/share/sddm/themes/omarchy-dual/$theme_file"
done

systemctl --user daemon-reload
systemctl --user enable --now app-dev.lizardbyte.app.Sunshine.service

printf '\nGaming setup installed.\n'
printf 'Reboot when ready to activate the SDDM session chooser.\n'
printf 'SSH, PAM, passwords, firewall rules, networking, and logind were not changed.\n'
