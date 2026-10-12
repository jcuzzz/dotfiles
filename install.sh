#!/usr/bin/env bash
# Set up these dotfiles on a machine: fetch the shell tools, then symlink
# every package into $HOME. Safe to re-run.
#
#   ./install.sh            tools + links
#   ./install.sh --links    links only
#
# Layout is GNU Stow compatible (one dir per package, mirroring $HOME), so
# `stow bash tmux ...` works too if you prefer it; this script just avoids
# needing stow (or sudo) installed.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# ── Tools ────────────────────────────────────────────────────────────────────

latest_tag() { # owner/repo -> e.g. v0.65.0
  curl -fsS --retry 3 -o /dev/null -w '%{redirect_url}' "https://github.com/$1/releases/latest" | sed 's#.*/tag/##'
}

fetch() { # name url  -- extract the binary called <name> from a tarball into $BIN
  local tmp
  tmp="$(mktemp -d)"
  # GitHub's direct asset links sometimes 504; the API route via gh still works
  if ! curl -fsSL --retry 3 -o "$tmp/pkg.tar.gz" "$2"; then
    command -v gh >/dev/null || { echo "download failed: $2" >&2; return 1; }
    echo "    direct download failed, retrying via gh"
    local repo tag file
    repo="$(echo "$2" | cut -d/ -f4-5)"
    file="$(basename "$2")"
    tag="$(echo "$2" | cut -d/ -f8)"
    [ "$tag" = download ] && tag="$(latest_tag "$repo")"
    gh release download "$tag" -R "$repo" -p "$file" -O "$tmp/pkg.tar.gz"
  fi
  tar -xzf "$tmp/pkg.tar.gz" -C "$tmp"
  install -m 755 "$(find "$tmp" -type f -name "$1" | head -1)" "$BIN/$1"
  rm -rf "$tmp"
}

install_tools() {
  local arch tag
  case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    aarch64 | arm64) arch=aarch64 ;;
    *) echo "unsupported arch $(uname -m), skipping tools" >&2; return ;;
  esac
  mkdir -p "$BIN"

  if ! command -v fzf >/dev/null; then
    say "installing fzf"
    tag="$(latest_tag junegunn/fzf)"
    fetch fzf "https://github.com/junegunn/fzf/releases/download/$tag/fzf-${tag#v}-linux_$([ $arch = x86_64 ] && echo amd64 || echo arm64).tar.gz"
  fi

  if ! command -v zoxide >/dev/null; then
    say "installing zoxide"
    tag="$(latest_tag ajeetdsouza/zoxide)"
    fetch zoxide "https://github.com/ajeetdsouza/zoxide/releases/download/$tag/zoxide-${tag#v}-$arch-unknown-linux-musl.tar.gz"
  fi

  if ! command -v starship >/dev/null; then
    say "installing starship"
    fetch starship "https://github.com/starship/starship/releases/latest/download/starship-$arch-unknown-linux-musl.tar.gz"
  fi
}

# ── Links ────────────────────────────────────────────────────────────────────

link() { # source target
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP/$(dirname "${dst#"$HOME"/}")"
    mv "$dst" "$BACKUP/${dst#"$HOME"/}"
    echo "    backed up ~/${dst#"$HOME"/}"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "    ~/${dst#"$HOME"/} -> ${src#"$DOTFILES"/}"
}

link_packages() {
  say "linking packages"
  local pkg entry sub
  for pkg in "$DOTFILES"/*/; do
    pkg="${pkg%/}"
    shopt -s dotglob nullglob
    for entry in "$pkg"/*; do
      if [ "$(basename "$entry")" = .config ]; then
        # Link each app's folder/file inside .config, not .config itself
        for sub in "$entry"/*; do
          link "$sub" "$HOME/.config/$(basename "$sub")"
        done
      else
        link "$entry" "$HOME/$(basename "$entry")"
      fi
    done
    shopt -u dotglob nullglob
  done
  [ -d "$BACKUP" ] && say "originals saved in $BACKUP"
  return 0
}

[ "${1:-}" = --links ] || install_tools
link_packages
say "done - open a new shell or run: source ~/.bashrc"
