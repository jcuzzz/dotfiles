#!/usr/bin/env bash
# Install the programs a profile uses, then link its config with install.sh.
#
#   ./bootstrap.sh [--profile workstation|server|minimal] [--dry-run]
#
# install.sh only links config. This is the one-command setup for a new box:
#   * apt packages (Debian/Ubuntu), through sudo unless already root
#   * release builds apt doesn't have or has too old, into ~/.local (no
#     sudo): Neovim 0.12+ and the tree-sitter CLI for the workstation IDE,
#     starship wherever its config is linked
#   * then install.sh with the same profile
# Safe to re-run: anything already on PATH is skipped, so a tool installed
# some other way (a tarball, webi, Ansible) is never installed twice.

set -euo pipefail

DOTFILES="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

apt_packages() {
  case "$1" in
    workstation) echo "stow git vim tmux fzf ripgrep jq curl ca-certificates" \
                      "zoxide fd-find direnv shellcheck build-essential unzip" \
                      "nodejs npm golang-go python3-venv" ;;
    server)      echo "stow git vim tmux neovim fzf ripgrep jq curl ca-certificates" ;;
    minimal)     echo "stow git vim" ;;
    *) return 1 ;;
  esac
}

usage() { sed -n '2,4p' "$0" | cut -c3-; }

PROFILE=workstation DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift ;;
    --profile=*) PROFILE="${1#*=}" ;;
    -n | --dry-run) DRY_RUN=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
APT="$(apt_packages "$PROFILE")" || { echo "unknown profile: $PROFILE" >&2; exit 2; }

# Look where ~/.bashrc will look, in the same order, so a re-run (or a
# shell that hasn't loaded the new .bashrc yet) sees what an earlier run put
# in ~/.local/bin
PATH="/opt/nvim/bin:$HOME/.local/bin:$PATH"

have() { command -v "$1" >/dev/null 2>&1; }
# Is this apt package's program already here? Checked by command, not dpkg.
present() {
  case "$1" in
    build-essential) have cc && have make ;;
    ca-certificates) [ -s /etc/ssl/certs/ca-certificates.crt ] ;;
    fd-find) have fd || have fdfind ;;
    golang-go) have go ;;
    neovim) have nvim ;;
    nodejs) have node ;;
    python3-venv) have python3 && python3 -c 'import ensurepip' 2>/dev/null ;;
    ripgrep) have rg ;;
    *) have "$1" ;;
  esac
}
# "1.2.3" >= "1.2"?
version_ge() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" = "$2" ]; }
# Empty when not installed. (NVIM_LOG_FILE: 0.12 otherwise creates
# ~/.local/state/nvim just to print its version)
nvim_version() { NVIM_LOG_FILE=/dev/null nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9.]*\).*/\1/p' || true; }
ts_version() { tree-sitter --version 2>/dev/null | sed -n '1s/^tree-sitter \([0-9][0-9.]*\).*/\1/p' || true; }

# ── 1. Plan (changes nothing) ────────────────────────────────────────────────
need_apt=""
for p in $APT; do
  present "$p" || need_apt="$need_apt $p"
done
need_apt="${need_apt# }"

need_get=""
if [ "$PROFILE" = workstation ]; then
  v="$(nvim_version)"
  if [ -z "$v" ] || ! version_ge "$v" 0.12; then
    need_get="$need_get nvim"
    if [ -n "$v" ] && [ "$(command -v nvim)" = /opt/nvim/bin/nvim ]; then
      echo "warning: /opt/nvim holds Neovim $v and comes first on PATH, so it would" >&2
      echo "         hide the new one in ~/.local/bin. Remove it: sudo rm -rf /opt/nvim" >&2
    fi
  fi
  v="$(ts_version)"
  if [ -z "$v" ] || ! version_ge "$v" 0.26.1; then need_get="$need_get tree-sitter"; fi
fi
if [ "$PROFILE" != minimal ] && ! have starship; then need_get="$need_get starship"; fi
need_get="${need_get# }"

case "$(uname -m)" in
  x86_64) nvim_arch=x86_64 ts_arch=x64 ss_arch=x86_64 ;;
  aarch64 | arm64) nvim_arch=arm64 ts_arch=arm64 ss_arch=aarch64 ;;
  *)
    [ -z "$need_get" ] || echo "warning: no release builds for $(uname -m); skipping: $need_get" >&2
    need_get="" ;;
esac

if [ "$DRY_RUN" = 1 ]; then
  echo "apt install: ${need_apt:-nothing}"
  echo "download to ~/.local: ${need_get:-nothing}"
  echo
  exec "$DOTFILES/install.sh" --profile "$PROFILE" --dry-run
fi

# ── 2. apt ───────────────────────────────────────────────────────────────────
if [ -n "$need_apt" ]; then
  sudo=()
  if [ "$(id -u)" != 0 ]; then sudo=(sudo); fi
  if ! have apt-get; then
    echo "warning: no apt-get here. Install these with your package manager:" >&2
    echo "         $need_apt" >&2
  elif [ ${#sudo[@]} -gt 0 ] && ! have sudo; then
    echo "warning: not root and no sudo; skipping apt. Ask for: $need_apt" >&2
  else
    echo "apt install: $need_apt"
    "${sudo[@]}" apt-get update -q
    # Older releases lack some (e.g. zoxide before Ubuntu 22.04). Install
    # the rest rather than letting one unknown name fail the whole lot.
    ok=() skipped=()
    for p in $need_apt; do
      if apt-cache show "$p" >/dev/null 2>&1; then ok+=("$p"); else skipped+=("$p"); fi
    done
    [ ${#skipped[@]} -eq 0 ] || echo "warning: not in this release's apt, skipped: ${skipped[*]}" >&2
    if [ ${#ok[@]} -gt 0 ]; then
      "${sudo[@]}" env DEBIAN_FRONTEND=noninteractive \
        apt-get install -y -q --no-install-recommends "${ok[@]}"
    fi
  fi
fi

# ── 3. Release builds into ~/.local ──────────────────────────────────────────
if [ -n "$need_get" ]; then
  if ! have curl; then
    echo "error: curl is needed to download: $need_get" >&2
    exit 1
  fi
  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
  # Unpack beside the destination, so the final move is a rename
  tmp="$(mktemp -d "$HOME/.local/opt/.bootstrap.XXXXXX")"
  trap 'rm -rf -- "$tmp"' EXIT
  get() { curl -fsSL --retry 3 -o "$2" "https://github.com/$1"; }

  for tool in $need_get; do
    echo "downloading $tool"
    case "$tool" in
      nvim)
        get "neovim/neovim/releases/latest/download/nvim-linux-$nvim_arch.tar.gz" "$tmp/nvim.tgz"
        mkdir "$tmp/nvim"
        tar -xzf "$tmp/nvim.tgz" -C "$tmp/nvim" --strip-components=1
        rm -rf "$HOME/.local/opt/nvim"
        mv "$tmp/nvim" "$HOME/.local/opt/nvim"
        ln -sfn "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
        ;;
      tree-sitter)
        get "tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-$ts_arch.gz" "$tmp/ts.gz"
        gunzip "$tmp/ts.gz"
        chmod +x "$tmp/ts"
        mv "$tmp/ts" "$HOME/.local/bin/tree-sitter"
        ;;
      starship)
        get "starship/starship/releases/latest/download/starship-$ss_arch-unknown-linux-musl.tar.gz" "$tmp/ss.tgz"
        tar -xzf "$tmp/ss.tgz" -C "$tmp" starship
        mv "$tmp/starship" "$HOME/.local/bin/starship"
        ;;
    esac
  done
  rm -rf -- "$tmp"   # exec below skips the EXIT trap
  trap - EXIT
  hash -r
fi

if [ -z "$need_apt" ] && [ -z "$need_get" ]; then
  echo "programs: all present"
fi

# ── 4. Link the config ───────────────────────────────────────────────────────
exec "$DOTFILES/install.sh" --profile "$PROFILE"
