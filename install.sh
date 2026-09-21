#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SECRETS_FILE="$REPO_DIR/secrets.sh"
BACKUP_ROOT="$HOME/.local/state/personal-backup/backups/$(date +%Y%m%d-%H%M%S)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ $EUID -ne 0 ]] || die "run this script as your normal user, not root"
command -v omarchy >/dev/null || die "Omarchy is required"
command -v sudo >/dev/null || die "sudo is required"

if [[ -f $SECRETS_FILE ]]; then
  # shellcheck disable=SC1090
  source "$SECRETS_FILE"
else
  printf 'warning: %s is absent; skipping authenticated setup\n' "$SECRETS_FILE" >&2
fi

read_packages() {
  local file=$1 line
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -z $line || $line == \#* ]] || printf '%s\n' "$line"
  done <"$file"
}

mapfile -t arch_packages < <(read_packages "$REPO_DIR/packages/arch.txt")
mapfile -t aur_packages < <(read_packages "$REPO_DIR/packages/aur.txt")
((${#arch_packages[@]} == 0)) || omarchy pkg add "${arch_packages[@]}"
((${#aur_packages[@]} == 0)) || omarchy pkg aur add "${aur_packages[@]}"

link_config() {
  local source=$1 target=$2
  mkdir -p -- "$(dirname -- "$target")"

  if [[ -L $target && $(readlink -f -- "$target") == $(readlink -f -- "$source") ]]; then
    return
  fi

  if [[ -e $target || -L $target ]]; then
    local relative=${target#"$HOME"/}
    mkdir -p -- "$BACKUP_ROOT/$(dirname -- "$relative")"
    mv -- "$target" "$BACKUP_ROOT/$relative"
    printf 'backed up %s to %s\n' "$target" "$BACKUP_ROOT/$relative"
  fi

  ln -s -- "$source" "$target"
}

while IFS= read -r -d '' source; do
  relative=${source#"$REPO_DIR/home/"}
  link_config "$source" "$HOME/$relative"
done < <(find "$REPO_DIR/home" -type f -print0)

tpm_dir="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d $tpm_dir/.git ]]; then
  command -v git >/dev/null || die "git is required to install tmux plugins"
  mkdir -p -- "$(dirname -- "$tpm_dir")"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi
"$tpm_dir/bin/install_plugins"

sudo install -Dm644 \
  "$REPO_DIR/system/etc/systemd/logind.conf.d/90-personal.conf" \
  /etc/systemd/logind.conf.d/90-personal.conf

sddm_tmp=$(mktemp)
trap 'rm -f -- "$sddm_tmp"' EXIT
sed "s/@USER@/$USER/g" \
  "$REPO_DIR/system/etc/sddm.conf.d/autologin.conf" >"$sddm_tmp"
sudo install -Dm644 "$sddm_tmp" /etc/sddm.conf.d/autologin.conf

sudo install -Dm644 \
  "$REPO_DIR/system/usr/local/share/wayland-sessions/gamescope-steam.desktop" \
  /usr/local/share/wayland-sessions/gamescope-steam.desktop

sudo systemctl enable --now tailscaled.service
if [[ -n ${TAILSCALE_AUTHKEY:-} ]] && ! tailscale status >/dev/null 2>&1; then
  sudo tailscale up --auth-key="$TAILSCALE_AUTHKEY"
fi

systemctl --user daemon-reload
systemctl --user enable --now app-dev.lizardbyte.app.Sunshine.service

if [[ -f $SECRETS_FILE ]]; then
  api_env="$HOME/.config/environment.d/90-personal-backup.conf"
  mkdir -p -- "$(dirname -- "$api_env")"
  : >"$api_env"
  for name in ANTHROPIC_API_KEY OPENAI_API_KEY; do
    value=${!name:-}
    if [[ -n $value ]]; then
      value=${value//\\/\\\\}
      value=${value//\"/\\\"}
      value=${value//\$/\\$}
      value=${value//\`/\\\`}
      printf '%s="%s"\n' "$name" "$value" >>"$api_env"
    fi
  done
  chmod 600 "$api_env"
fi

printf '\nInstalled personal Omarchy overlay.\n'
printf 'Reboot to apply SDDM autologin and logind policy.\n'
printf 'Sunshine pairing credentials are machine state and were intentionally not restored.\n'
