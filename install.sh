#!/usr/bin/env bash
# Link the packages for one profile into $HOME with GNU Stow.
#
#   ./install.sh [--profile workstation|server|minimal] [--dry-run]
#   ./install.sh --uninstall [--dry-run]
#
# Stow does the linking, re-linking and unlinking. This script only adds
# what stow deliberately leaves to you:
#   * the package list for each profile
#   * moving files that are in the way (e.g. Ubuntu's stock ~/.bashrc) to
#     ~/.dotfiles-backup/<timestamp>/, since stow refuses to overwrite them
# Every run is simulated first (stow --simulate). If anything would conflict
# beyond the files listed for moving, the run stops before changing anything,
# so a failed run never leaves HOME half-done.

set -euo pipefail

DOTFILES="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

ALL="bash git vim tmux nvim nvim-lite starship psql"
packages() {
  case "$1" in
    workstation) echo "bash git vim tmux nvim starship psql" ;;
    server)      echo "bash git vim tmux nvim-lite starship psql" ;;
    minimal)     echo "bash git vim" ;;
    *) return 1 ;;
  esac
}

usage() { sed -n '2,5p' "$0" | cut -c3-; }

PROFILE=workstation DRY_RUN=0 UNINSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift ;;
    --profile=*) PROFILE="${1#*=}" ;;
    -n | --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
PKGS="$(packages "$PROFILE")" || { echo "unknown profile: $PROFILE" >&2; exit 2; }

if ! command -v stow >/dev/null 2>&1; then
  echo "error: GNU Stow is not installed. Run: sudo apt install stow" >&2
  echo "       (no sudo? see README: 'Without stow')" >&2
  exit 1
fi

stow_() { # stow with our dir/target; --simulate on a dry run
  local sim=()
  [ "$DRY_RUN" = 1 ] && sim=(--simulate)
  stow --dir="$DOTFILES" --target="$HOME" --verbose=1 "${sim[@]}" "$@"
}

if [ "$UNINSTALL" = 1 ]; then
  # shellcheck disable=SC2086  # word-split the package list
  stow_ --delete $ALL
  echo "unlinked. Earlier originals, if any, are in ~/.dotfiles-backup/"
  exit 0
fi

# Stow "folds" a directory that only one package's links would occupy into
# a single link to the repo. Fine for ~/.config/nvim, never for ~/.config
# itself (every app's state would land in git). So it must be a real
# directory, and packages are laid out so that every profile with anything
# in ~/.config puts links from several packages there (bash keeps its
# modules in ~/.bashrc.d for that reason).
if [ -L "$HOME/.config" ]; then
  echo "error: ~/.config is a symlink ($(readlink "$HOME/.config")); make it a real directory first" >&2
  exit 1
fi
# (it is created in step 3 below, so a dry run or refused run creates nothing)

# Packages outside this profile get unlinked (e.g. nvim-lite when a machine
# moves to workstation). Stow ignores packages that were never linked.
others=""
for p in $ALL; do
  case " $PKGS " in *" $p "*) ;; *) others="$others $p" ;; esac
done

# ── 1. Plan (changes nothing) ────────────────────────────────────────────────
# Stow refuses to replace anything it doesn't own. Two kinds of path get
# cleared out of its way: absolute links into this repo (left by the old
# installer; stow doesn't recognise them) are removed, and real files or
# directories (e.g. Ubuntu's stock ~/.bashrc) are moved to the backup dir.
# Relative links are stow's own, and anything else it will report itself.
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
clear_rel=() clear_old=()   # path under HOME; old link target, or "" = move
for p in $PKGS; do
  for src in "$DOTFILES/$p"/.[!.]* "$DOTFILES/$p"/.config/*; do
    if [ ! -e "$src" ] || [ "${src##*/}" = .config ]; then
      continue
    fi
    rel="${src#"$DOTFILES/$p/"}"
    dst="$HOME/$rel"
    if [ -L "$dst" ]; then
      target="$(readlink "$dst")"
      case "$target" in
        "$DOTFILES"/*) clear_rel+=("$rel") clear_old+=("$target")
                       echo "replacing old absolute link ~/$rel" ;;
      esac
    elif [ -e "$dst" ]; then
      # Never move something that is really part of this repo (reached
      # through a linked parent directory)
      case "$(readlink -f "$dst")" in "$DOTFILES"/*) continue ;; esac
      clear_rel+=("$rel") clear_old+=("")
      echo "moving ~/$rel to ${backup/#"$HOME"/\~}/$rel"
    fi
  done
done

# ── 2. Preflight: simulate the whole stow run before touching anything ───────
# Stow's simulation still sees the paths planned above. Hide only its
# complaints about those; any other conflict stops the run right here, with
# HOME exactly as it was.
# shellcheck disable=SC2086
out="$(stow --dir="$DOTFILES" --target="$HOME" --verbose=1 --simulate \
         --delete $others --stow $PKGS 2>&1)" || true
keep=""
while IFS= read -r line; do
  case "$line" in
    # stow 2.3/2.4 notes about the old absolute links being replaced
    *"BUG in find_stowed_path"*"path $DOTFILES/"* | *"Ignoring an absolute symlink"*"=> $DOTFILES/"*) continue ;;
    "WARNING: in simulation mode"*) continue ;;
    *"* "*)
      for rel in "${clear_rel[@]}"; do
        # the path itself, or (for a directory being moved) anything in it
        case "$line" in
          *": $rel" | *": $rel/"* | *" target $rel since"* | *" target $rel/"*) continue 2 ;;
        esac
      done ;;
  esac
  keep+="$line"$'\n'
done <<< "$out"
if grep -q '^ *\* ' <<< "$keep"; then
  printf '%s' "$keep" >&2
  echo "error: stow would conflict on the paths marked * above. Nothing was changed;" >&2
  echo "       move those paths aside (or delete them) and re-run." >&2
  exit 1
fi

if [ "$DRY_RUN" = 1 ]; then
  grep -v -e '^WARNING! stowing' -e '^All operations aborted' <<< "${keep%$'\n'}" || true
else
  # ── 3. Execute ─────────────────────────────────────────────────────────────
  mkdir -p "$HOME/.config"
  for i in "${!clear_rel[@]}"; do
    rel="${clear_rel[$i]}"
    if [ -n "${clear_old[$i]}" ]; then
      rm -- "$HOME/$rel"
    else
      mkdir -p "$(dirname "$backup/$rel")"
      mv -- "$HOME/$rel" "$backup/$rel"
    fi
  done

  # One stow transaction: unlink the others, link this profile's packages.
  # Plain --stow is idempotent: links stow already owns are left alone.
  # shellcheck disable=SC2086
  if ! stow_ --delete $others --stow $PKGS; then
    # The preflight passed, so this is unexpected (e.g. HOME changed in
    # between). Stow changed nothing; put back what we moved.
    for i in "${!clear_rel[@]}"; do
      rel="${clear_rel[$i]}"
      if [ -n "${clear_old[$i]}" ]; then
        ln -s -- "${clear_old[$i]}" "$HOME/$rel"
      else
        mv -- "$backup/$rel" "$HOME/$rel"
      fi
    done
    echo "error: stow failed (see above); everything was put back as it was" >&2
    exit 1
  fi
  if [ ${#clear_rel[@]} -gt 0 ] && [ -d "$backup" ]; then
    echo "originals saved in ${backup/#"$HOME"/\~}/"
  fi
fi

# Linking a config doesn't install the program it configures. Say so,
# rather than leaving e.g. nvim-lite linked on a box with no nvim. Look
# where ~/.bashrc will, which this shell may not have loaded yet.
missing=""
for p in $PKGS; do
  case "$p" in
    nvim | nvim-lite) prog=nvim ;;
    tmux | starship) prog="$p" ;;
    *) continue ;;
  esac
  PATH="/opt/nvim/bin:$HOME/.local/bin:$PATH" command -v "$prog" >/dev/null 2>&1 ||
    missing="$missing $prog"
done
if [ -n "$missing" ]; then
  echo "note: not installed:$missing. Their config is linked but unused until they are."
  echo "      Run $DOTFILES/bootstrap.sh --profile $PROFILE (or see README 'Programs')"
fi
case " $PKGS " in *" nvim "*)
  v="$(PATH="/opt/nvim/bin:$HOME/.local/bin:$PATH" NVIM_LOG_FILE=/dev/null nvim --version 2>/dev/null |
       sed -n '1s/^NVIM v\([0-9][0-9.]*\).*/\1/p')" || true
  if [ -n "$v" ] && [ "$(printf '%s\n0.12\n' "$v" | sort -V | head -n 1)" != 0.12 ]; then
    echo "note: Neovim $v is too old for the IDE config, which needs 0.12+."
    echo "      Run $DOTFILES/bootstrap.sh --profile $PROFILE to get a current build"
  fi ;;
esac

if [ "$DRY_RUN" = 1 ]; then
  echo "dry run: profile '$PROFILE' ($PKGS); nothing was changed"
else
  echo "profile '$PROFILE' linked: $PKGS"
  echo "start a new shell (exec bash) to pick it up"
fi
