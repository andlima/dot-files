#!/usr/bin/env bash
# Replays every customization of my Omarchy install on top of a fresh one.
# Idempotent: re-running changes nothing that is already in place.
#
#   ./omarchy/bootstrap.sh              # everything that is safe on any laptop
#   ./omarchy/bootstrap.sh --monitors   # also install monitors.lua (hardware-specific)
#   ./omarchy/bootstrap.sh --spec       # also install the specbutler CLI via pipx
#
# See omarchy/README.md for what each step does and why.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
WITH_MONITORS=0 WITH_SPEC=0
for arg in "$@"; do
  case "$arg" in
    --monitors) WITH_MONITORS=1 ;;
    --spec)     WITH_SPEC=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

TEXT_SIZE_PX=11
TMUX_LINE='source-file ~/.tmux.conf'

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip() { printf '    %s (already in place)\n' "$*"; }
todo() { printf '\033[1;33m TODO\033[0m %s\n' "$*"; }

# install_file SRC DST: copy SRC over DST, keeping a timestamped backup when DST differs.
install_file() {
  local src="$1" dst="$2"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then skip "$dst"; return; fi
  mkdir -p "$(dirname "$dst")"
  [[ -f "$dst" ]] && cp "$dst" "$dst.bak.$(date +%s)"
  cp "$src" "$dst"
  echo "    installed $dst"
}

# ---------------------------------------------------------------- Hyprland
log "Hyprland input (caps->ctrl, natural scroll, BM-615, 3-finger swipe, click-to-focus)"
install_file "$HERE/hypr/input.lua" "$HOME/.config/hypr/input.lua"
if (( WITH_MONITORS )); then
  log "Hyprland monitors (scale 1.25, GDK scale 1)"
  install_file "$HERE/hypr/monitors.lua" "$HOME/.config/hypr/monitors.lua"
else
  echo "    monitors.lua skipped (pass --monitors on the same laptop model)"
fi
if command -v hyprctl >/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  hyprctl reload >/dev/null
  errors="$(hyprctl configerrors)"
  if [[ -n "$errors" && "$errors" != "no errors" ]]; then
    echo "$errors" >&2; echo "Hyprland config errors, fix before continuing." >&2; exit 1
  fi
  echo "    hyprctl reload: ok, no config errors"
fi

# ---------------------------------------------------------------- Text size
log "Desktop text size ${TEXT_SIZE_PX}px (terminals 8pt, GTK ~0.91)"
if command -v omarchy >/dev/null; then
  current="$(omarchy display text size 2>/dev/null | sed -n 's/^text size: \([0-9]*\) px.*/\1/p')"
  if [[ "$current" == "$TEXT_SIZE_PX" ]]; then skip "text size $current px"; else omarchy display text size "$TEXT_SIZE_PX"; fi
fi

# ---------------------------------------------------------------- tmux
log "tmux: personal ~/.tmux.conf (prefix C-z) sourced after Omarchy's config"
if [[ -L "$HOME/.tmux.conf" && "$(readlink -f "$HOME/.tmux.conf")" == "$REPO/.tmux.conf" ]]; then
  skip "~/.tmux.conf -> $REPO/.tmux.conf"
else
  [[ -e "$HOME/.tmux.conf" ]] && mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$(date +%s)"
  ln -s "$REPO/.tmux.conf" "$HOME/.tmux.conf"
  echo "    linked ~/.tmux.conf -> $REPO/.tmux.conf"
fi
OMARCHY_TMUX="$HOME/.config/tmux/tmux.conf"
if [[ -f "$OMARCHY_TMUX" ]] && grep -qxF "$TMUX_LINE" "$OMARCHY_TMUX"; then
  skip "$OMARCHY_TMUX sources ~/.tmux.conf"
else
  mkdir -p "$(dirname "$OMARCHY_TMUX")"
  printf '\n# Personal overrides (loaded last so they win over the defaults above)\n%s\n' "$TMUX_LINE" >> "$OMARCHY_TMUX"
  echo "    appended '$TMUX_LINE' to $OMARCHY_TMUX"
fi

# ---------------------------------------------------------------- git / ssh
log "git config (~/.config/git/config: identity, gh credential helper, SSH for GitHub)"
install_file "$HERE/git/config" "$HOME/.config/git/config"

log "SSH config + ed25519 key for GitHub"
install_file "$HERE/ssh/config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  skip "~/.ssh/id_ed25519"
else
  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -C "andre.lima@gmail.com $(hostname)" >/dev/null
  echo "    generated ~/.ssh/id_ed25519"
  todo "register the key on GitHub: gh ssh-key add ~/.ssh/id_ed25519.pub --title \"$(hostname)\"  (needs: gh auth refresh -s admin:public_key)"
fi

# ---------------------------------------------------------------- mise
log "mise tools (claude, codex, copilot, gh, pi, pipx, uv, node 26)"
install_file "$HERE/mise/config.toml" "$HOME/.config/mise/config.toml"
if command -v mise >/dev/null; then
  mise install --quiet
  echo "    mise install: done"
else
  todo "mise not found on PATH; Omarchy ships it, open a new shell and re-run"
fi
if command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1; then
  todo "gh auth login --web   (then: gh config set git_protocol ssh)"
fi

# ---------------------------------------------------------------- emacs
log "Emacs (emacs-wayland from pacman, config in ~/.config/emacs)"
if pacman -Qq emacs-wayland >/dev/null 2>&1; then
  skip "emacs-wayland installed"
else
  sudo pacman -S --needed --noconfirm emacs-wayland
fi
install_file "$HERE/emacs/early-init.el" "$HOME/.config/emacs/early-init.el"
install_file "$HERE/emacs/init.el" "$HOME/.config/emacs/init.el"
if [[ -d "$HOME/.emacs.d" ]]; then
  if rmdir "$HOME/.emacs.d" 2>/dev/null; then echo "    removed empty ~/.emacs.d (it would shadow ~/.config/emacs)";
  else todo "~/.emacs.d exists and is not empty; Emacs will prefer it over ~/.config/emacs"; fi
fi
[[ -e "$HOME/.emacs" ]] && todo "~/.emacs exists; Emacs will prefer it over ~/.config/emacs (don't run the root setup.sh on Omarchy)"

# ---------------------------------------------------------------- optional: specbutler
if (( WITH_SPEC )); then
  log "specbutler (spec CLI) via pipx"
  if command -v spec >/dev/null; then skip "spec"; else
    pipx install "specbutler[tui] @ git+https://github.com/specbutler/specbutler.git@v0.5.0"
  fi
fi

# ---------------------------------------------------------------- manual steps
log "Manual steps that can't be scripted"
todo "Bluetooth mouse BM-615: bluetoothctl -> scan on, pair 13:05:AA:00:01:4F, trust, connect"
echo
echo "Done."
