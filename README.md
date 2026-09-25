# Personal Omarchy overlay

This repository contains only local policy and configuration layered on top of a
fresh Omarchy quattro installation. It deliberately excludes Omarchy-owned files,
generated state, logs, caches, device identities, and private keys.

## Restore

```bash
git clone <repo-url> ~/gaming_setup
cd ~/gaming_setup
cp secrets.sh.example secrets.sh
$EDITOR secrets.sh
./install.sh
```

For only the gaming stack on an otherwise configured Omarchy machine:

```bash
./install-gaming.sh
```

The gaming-only installer manages Gamescope, Sunshine, Sunshine's declarative
configuration, the SDDM session chooser, and the Gaming Mode session. It does not
touch Tailscale, OpenCode, tmux, API secrets, logind policy, SSH, PAM, passwords,
firewall rules, or networking.

Run the installer as the target desktop user. It requests `sudo` only for
root-owned files and the system Tailscale service. It is idempotent; user configs
that are not already linked to this repo are moved under
`~/.local/state/personal-backup/backups/` before linking.

## What is managed

- `packages/arch.txt`: official packages absent from stock Omarchy.
- `packages/aur.txt`: AUR packages absent from stock Omarchy.
- `system/`: root-owned config copied with mode `0644`.
- `home/`: declarative user config symlinked into `$HOME`.
- `secrets.sh`: local bootstrap secrets, ignored by Git.

The SDDM overlay deliberately disables autologin and limits the greeter to two
explicit sessions: the stock `/usr/local/share/wayland-sessions/omarchy.desktop`
and the repo-owned Gaming Mode session. The custom theme lives under `/usr/local`
so Omarchy package updates cannot overwrite it. The installer does not alter SSH,
PAM, user passwords, firewall rules, or network access.

`moonlight-qt`, `tmux`, and opencode installation are already part of stock
Omarchy quattro. The complete custom `tmux.conf` is repo-owned, and the installer
bootstraps TPM plus every plugin declared by that config. Cloned plugin source and
tmux-resurrect runtime snapshots are intentionally not committed.

## Maintenance

Keep package manifests limited to explicit additions over
`/usr/share/omarchy/install/omarchy-base.packages`. Prefer systemd drop-ins over
copying vendor config. Never add `/usr/share/omarchy`, Sunshine credentials,
opencode auth state, or `secrets.sh`.
