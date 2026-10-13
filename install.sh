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
# If stow still finds a conflict it aborts before changing anything, so a
# failed run never leaves HOME half-linked.

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
[ "$DRY_RUN" = 1 ] || mkdir -p "$HOME/.config"

# Packages outside this profile get unlinked (e.g. nvim-lite when a machine
# moves to workstation). Stow ignores packages that were never linked.
others=""
for p in $ALL; do
  case " $PKGS " in *" $p "*) ;; *) others="$others $p" ;; esac
done

# Clear the way for stow. Anything at a path a package needs is moved to the
# backup dir, except links stow made (relative), which it manages itself.
# Absolute links into this repo come from the old installer; stow does not
# recognise them, so they are just removed.
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
cleared=()   # paths this run clears before stowing
for p in $PKGS; do
  for src in "$DOTFILES/$p"/.[!.]* "$DOTFILES/$p"/.config/*; do
    [ -e "$src" ] && [ "${src##*/}" != .config ] || continue
    rel="${src#"$DOTFILES/$p/"}"
    dst="$HOME/$rel"
    if [ -L "$dst" ]; then
      case "$(readlink "$dst")" in
        "$DOTFILES"/*)
          echo "replacing old absolute link ~/$rel"
          cleared+=("$rel")
          [ "$DRY_RUN" = 1 ] || rm -- "$dst" ;;
      esac
    elif [ -e "$dst" ]; then
      # Never move something that is really part of this repo (reached
      # through a linked parent directory)
      case "$(readlink -f "$dst")" in "$DOTFILES"/*) continue ;; esac
      echo "moving ~/$rel to ${backup/#"$HOME"/\~}/$rel"
      cleared+=("$rel")
      if [ "$DRY_RUN" = 0 ]; then
        mkdir -p "$(dirname "$backup/$rel")"
        mv -- "$dst" "$backup/$rel"
      fi
    fi
  done
done

# One stow transaction: unlink the others, link this profile's packages.
# Plain --stow is idempotent: links stow already owns are left alone.
if [ "$DRY_RUN" = 1 ] && [ ${#cleared[@]} -gt 0 ]; then
  # Stow's simulation still sees the paths listed above, which a real run
  # clears first. Hide only its complaints about those; show anything else.
  # shellcheck disable=SC2086
  out="$(stow_ --delete $others --stow $PKGS 2>&1)" || true
  keep=""
  while IFS= read -r line; do
    case "$line" in
      # stow's notes about the old absolute links being replaced
      *"BUG in find_stowed_path"*"path $DOTFILES/"* | *"Ignoring an absolute symlink"*"=> $DOTFILES/"*) continue ;;
      *"* "*)
        for rel in "${cleared[@]}"; do
          case "$line" in *": $rel" | *" target $rel since"*) continue 2 ;; esac
        done ;;
    esac
    keep+="$line"$'\n'
  done <<< "$out"
  out="${keep%$'\n'}"
  if grep -q '^ *\* ' <<< "$out"; then
    printf '%s\n' "$out"
    echo "error: stow would also hit the conflicts marked * above; move those paths aside first" >&2
    exit 1
  fi
  grep -v -e '^WARNING! stowing' -e '^All operations aborted' <<< "$out" || true
else
  # shellcheck disable=SC2086
  if ! stow_ --delete $others --stow $PKGS; then
    echo "error: stow found conflicts (listed above) and changed nothing; move those paths aside and re-run" >&2
    exit 1
  fi
fi

if [ "$DRY_RUN" = 1 ]; then
  echo "dry run: profile '$PROFILE' ($PKGS); nothing was changed"
else
  echo "profile '$PROFILE' linked: $PKGS"
  echo "start a new shell (exec bash) to pick it up"
fi
