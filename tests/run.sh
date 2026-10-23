#!/usr/bin/env bash
# Tests for install.sh and the shell/editor configs. Each scenario uses a
# throwaway HOME and a throwaway copy of the repo, so neither your real
# dotfiles nor this checkout can be touched. No network, no sudo.
#
#   tests/run.sh
#
# Needs GNU Stow for the install tests; tmux/vim/nvim checks are skipped
# when those are not installed.

# Single-quoted strings below run in a child shell, on purpose:
# shellcheck disable=SC2016,SC2088,SC2001

set -euo pipefail

SRC="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")"
trap 'rm -rf -- "$WORK"' EXIT

# The copy lives at a path with spaces, to prove nothing assumes ~/dotfiles
REPO="$WORK/a clone/dotfiles"
mkdir -p "$(dirname "$REPO")"
cp -a "$SRC" "$REPO"
rm -rf "$REPO/.git"

PASS=0 FAIL=0 SKIP=0
ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$*"; }
bad()  { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$*"; }
skip() { SKIP=$((SKIP + 1)); printf '  skip  %s\n' "$*"; }
check() { local d="$1"; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }
section() { printf '\n%s\n' "$*"; }
show() { sed 's/^/      /' <<< "$1"; }

N=0
new_home() { N=$((N + 1)); H="$WORK/home$N"; mkdir -p "$H"; }
inst() { env HOME="$H" "$REPO/install.sh" "$@"; }
# path|type|link target|size|mtime of everything under a directory
snapshot() { (cd "$1" && find . -printf '%p|%y|%l|%s|%T@\n' | sort); }

expected() { # profile -> "target package-path" lines
  local nvim=nvim
  [ "$1" = server ] && nvim="nvim-lite"
  echo ".bashrc bash/.bashrc
.bashrc.d bash/.bashrc.d
.gitconfig git/.gitconfig
.vimrc vim/.vimrc"
  [ "$1" = minimal ] || echo ".config/tmux tmux/.config/tmux
.config/nvim $nvim/.config/nvim
.config/starship.toml starship/.config/starship.toml
.psqlrc psql/.psqlrc"
}
links_ok() { # profile: every expected target is a link resolving into the repo
  local dst src rc=0
  while read -r dst src; do
    if ! [ -L "$H/$dst" ] || [ "$(readlink -f "$H/$dst")" != "$REPO/$src" ]; then
      echo "      wrong: ~/$dst"; rc=1
    fi
  done <<< "$(expected "$1")"
  return "$rc"
}
config_is_real_dir() { [ -d "$H/.config" ] && [ ! -L "$H/.config" ]; }
# stow may remove an emptied ~/.config, which is fine; it must never fold it
# into a link to the repo
config_not_folded() { [ ! -L "$H/.config" ]; }

repo_before="$(snapshot "$REPO")"

# ── Lint ─────────────────────────────────────────────────────────────────────
section "syntax"
for f in install.sh bootstrap.sh tests/run.sh bash/.bashrc bash/.bashrc.d/*.sh; do
  check "bash -n $f" bash -n "$SRC/$f"
done

if ! command -v stow >/dev/null 2>&1; then
  section "install"
  skip "GNU Stow not installed (sudo apt install stow); install tests skipped"
else
# ── Usage ────────────────────────────────────────────────────────────────────
section "usage"
new_home
check "--help exits 0" bash -c '"$@" >/dev/null' _ env HOME="$H" "$REPO/install.sh" --help
rc=0; inst --bogus >/dev/null 2>&1 || rc=$?
check "unknown option exits 2" [ "$rc" = 2 ]
rc=0; inst --profile laptop >/dev/null 2>&1 || rc=$?
check "unknown profile exits 2" [ "$rc" = 2 ]
nostow="$WORK/nostow"; mkdir -p "$nostow"
for c in bash env dirname sed cut; do ln -sf "$(command -v "$c")" "$nostow/$c"; done
out="$(env -i HOME="$H" PATH="$nostow" "$nostow/bash" "$REPO/install.sh" 2>&1)" && rc=0 || rc=$?
check "no stow: exits 1 with the apt hint" bash -c '[ "$1" = 1 ] && grep -q "apt install stow" <<< "$2"' _ "$rc" "$out"
check "usage errors changed nothing" [ -z "$(ls -A "$H")" ]

# ── Profiles ─────────────────────────────────────────────────────────────────
for profile in workstation server minimal; do
  section "profile: $profile"
  new_home
  out="$(inst --profile "$profile" 2>&1)" && rc=0 || rc=$?
  check "installs" [ "$rc" = 0 ]
  [ "$rc" = 0 ] || show "$out"
  check "expected links" links_ok "$profile"
  check "~/.config is a real directory" config_is_real_dir
  check "no backup when nothing was in the way" [ ! -e "$H/.dotfiles-backup" ]
  before="$(snapshot "$H")"
  inst --profile "$profile" >/dev/null 2>&1
  check "re-run changes nothing" [ "$before" = "$(snapshot "$H")" ]
done

section "switching profiles"
new_home
for profile in server minimal workstation minimal server; do
  inst --profile "$profile" >/dev/null 2>&1
  check "-> $profile: links match" links_ok "$profile"
  check "-> $profile: ~/.config never becomes a link" config_not_folded
done
inst --profile minimal >/dev/null 2>&1
check "minimal leaves no tmux/nvim links behind" \
  bash -c '[ ! -e "$1/.config/tmux" ] && [ ! -e "$1/.config/nvim" ]' _ "$H"

# ── Dry run ──────────────────────────────────────────────────────────────────
section "dry run"
new_home
before="$(snapshot "$H")"
inst --profile server --dry-run >/dev/null 2>&1
check "empty HOME: nothing changed" [ "$before" = "$(snapshot "$H")" ]
new_home
printf 'stock\n' > "$H/.bashrc"
mkdir -p "$H/.config/nvim" && printf 'x\n' > "$H/.config/nvim/init.lua"
before="$(snapshot "$H")"
out="$(inst --profile server --dry-run 2>&1)" && rc=0 || rc=$?
check "stock ~/.bashrc + old ~/.config/nvim dir: exits 0" [ "$rc" = 0 ]
check "stock ~/.bashrc + old ~/.config/nvim dir: nothing changed" [ "$before" = "$(snapshot "$H")" ]
check "reports the file it would move" grep -q 'moving ~/.bashrc' <<< "$out"

# ── Existing files ───────────────────────────────────────────────────────────
section "existing files"
new_home
printf 'stock bashrc\n' > "$H/.bashrc"
mkdir -p "$H/.config/nvim" && printf 'old init\n' > "$H/.config/nvim/init.lua"
printf 'unrelated\n' > "$H/.config/other.conf"
inst --profile workstation >/dev/null 2>&1
check "links in place" links_ok workstation
b="$(find "$H/.dotfiles-backup" -mindepth 1 -maxdepth 1)"
check "stock ~/.bashrc backed up intact" grep -qx 'stock bashrc' "$b/.bashrc"
check "old ~/.config/nvim backed up intact" grep -qx 'old init' "$b/.config/nvim/init.lua"
check "unrelated ~/.config files untouched" grep -qx 'unrelated' "$H/.config/other.conf"
inst --profile workstation >/dev/null 2>&1
check "re-run makes no second backup" [ "$(find "$H/.dotfiles-backup" -mindepth 1 -maxdepth 1 | wc -l)" = 1 ]

new_home
ln -s /somewhere/else "$H/.vimrc"
before="$(snapshot "$H")"
out="$(inst --profile minimal 2>&1)" && rc=0 || rc=$?
check "foreign symlink: refused, exit 1" [ "$rc" = 1 ]
check "foreign symlink: nothing changed" [ "$before" = "$(snapshot "$H")" ]
check "foreign symlink: the error names it" grep -q '\.vimrc' <<< "$out"

# The dangerous case: a file the installer would move (stock .bashrc) plus
# an unrelated conflict. The preflight must stop before moving anything,
# or the account would be left with no ~/.bashrc at all.
new_home
printf 'stock\n' > "$H/.bashrc"
ln -s /somewhere/else "$H/.vimrc"
before="$(snapshot "$H")"
rc=0; inst --profile server >/dev/null 2>&1 || rc=$?
check "stock .bashrc + unrelated conflict: refused, exit 1" [ "$rc" = 1 ]
check "stock .bashrc + unrelated conflict: nothing moved or created" [ "$before" = "$(snapshot "$H")" ]
check "stock .bashrc + unrelated conflict: ~/.bashrc still in place" grep -qx stock "$H/.bashrc"

new_home   # absolute links, as the pre-stow installer made them
mkdir -p "$H/.config"
ln -s "$REPO/bash/.bashrc" "$H/.bashrc"
ln -s "$REPO/tmux/.config/tmux" "$H/.config/tmux"
out="$(inst --profile server --dry-run 2>&1)" && rc=0 || rc=$?
check "migration dry-run: exits 0 without conflict warnings" \
  bash -c '[ "$1" = 0 ] && ! grep -q -e WARNING -e "^ *\* " <<< "$2"' _ "$rc" "$out"
[ "$rc" = 0 ] || show "$out"
ln -s /somewhere/else "$H/.vimrc"
rc=0; inst --profile server --dry-run >/dev/null 2>&1 || rc=$?
check "migration dry-run still reports a real conflict" [ "$rc" = 1 ]
rm "$H/.vimrc"
inst --profile server >/dev/null 2>&1
check "old absolute links migrated to stow links" links_ok server
check "migration needed no backup" [ ! -e "$H/.dotfiles-backup" ]

new_home
ln -s "$REPO/tmux/.config" "$H/.config"
before="$(snapshot "$REPO")"
rc=0; inst --profile server >/dev/null 2>&1 || rc=$?
check "~/.config is a symlink into the repo: refuses, exit 1" [ "$rc" = 1 ]
check "...and the repo is untouched" [ "$before" = "$(snapshot "$REPO")" ]

# ── Uninstall ────────────────────────────────────────────────────────────────
section "uninstall"
new_home
printf 'stock\n' > "$H/.bashrc"
inst --profile server >/dev/null 2>&1
printf 'mine\n' > "$H/.inputrc"
before="$(snapshot "$H")"
inst --uninstall --dry-run >/dev/null 2>&1
check "--uninstall --dry-run changes nothing" [ "$before" = "$(snapshot "$H")" ]
inst --uninstall >/dev/null 2>&1
check "all links removed" bash -c '[ -z "$(find "$1" -type l)" ]' _ "$H"
check "other files kept" grep -qx mine "$H/.inputrc"
check "backup kept" grep -rqx stock "$H/.dotfiles-backup"
# ── Missing programs ─────────────────────────────────────────────────────────
section "missing programs"
# Everything on PATH except the programs the configs are for
notools="$WORK/no-tools"; mkdir -p "$notools"
for d in /bin /usr/bin /usr/local/bin; do
  [ -d "$d" ] && find "$d" -maxdepth 1 ! -type d ! -name tmux ! -name nvim ! -name starship ! -name tree-sitter \
    -exec ln -sf -t "$notools" {} +
done
new_home
out="$(env HOME="$H" PATH="$notools" "$REPO/install.sh" --profile server 2>&1)" && rc=0 || rc=$?
check "server without tmux/starship: still installs" [ "$rc" = 0 ]
check "...and names them in a note" grep -q '^note: not installed:.* tmux.* starship' <<< "$out"
check "...pointing at bootstrap.sh" grep -q 'bootstrap.sh --profile server' <<< "$out"
mkdir -p "$H/.local/bin"
printf '#!/bin/sh\n' > "$H/.local/bin/starship"; chmod +x "$H/.local/bin/starship"
out="$(env HOME="$H" PATH="$notools" "$REPO/install.sh" --profile server 2>&1)"
check "a program in ~/.local/bin counts, even before .bashrc adds it to PATH" \
  bash -c '! grep -q "not installed:.*starship" <<< "$1"' _ "$out"
new_home
out="$(env HOME="$H" PATH="$notools" "$REPO/install.sh" --profile minimal 2>&1)"
check "minimal: no note (it links no tmux/nvim/starship config)" bash -c '! grep -q "^note:" <<< "$1"' _ "$out"
if [ -e /opt/nvim/bin/nvim ]; then
  skip "old-Neovim note (/opt/nvim/bin/nvim would shadow the fake one)"
else
  new_home; mkdir -p "$H/.local/bin"
  printf '#!/bin/sh\necho "NVIM v0.9.5"\n' > "$H/.local/bin/nvim"; chmod +x "$H/.local/bin/nvim"
  out="$(env HOME="$H" PATH="$notools" "$REPO/install.sh" --profile workstation 2>&1)"
  check "workstation with Neovim 0.9: notes it is too old" grep -q 'Neovim 0.9.5 is too old' <<< "$out"
  out="$(env HOME="$H" PATH="$notools" "$REPO/install.sh" --profile server 2>&1)"
  check "server with Neovim 0.9: fine for nvim-lite, no note" bash -c '! grep -q "too old" <<< "$1"' _ "$out"
fi

# ── Bootstrap (dry run only: the real thing needs sudo and network) ──────────
section "bootstrap"
new_home
check "--help exits 0" bash -c '"$@" >/dev/null' _ env HOME="$H" "$REPO/bootstrap.sh" --help
rc=0; env HOME="$H" "$REPO/bootstrap.sh" --bogus >/dev/null 2>&1 || rc=$?
check "unknown option exits 2" [ "$rc" = 2 ]
rc=0; env HOME="$H" "$REPO/bootstrap.sh" --profile laptop >/dev/null 2>&1 || rc=$?
check "unknown profile exits 2" [ "$rc" = 2 ]
for profile in workstation server minimal; do
  new_home
  printf 'stock\n' > "$H/.bashrc"
  before="$(snapshot "$H")"
  out="$(env HOME="$H" "$REPO/bootstrap.sh" --profile "$profile" --dry-run 2>&1)" && rc=0 || rc=$?
  check "$profile --dry-run: exits 0" [ "$rc" = 0 ]
  [ "$rc" = 0 ] || show "$out"
  check "$profile --dry-run: shows the plan and install.sh's" \
    bash -c 'grep -q "^apt install:" <<< "$1" && grep -q "moving ~/.bashrc" <<< "$1"' _ "$out"
  check "$profile --dry-run: nothing changed" [ "$before" = "$(snapshot "$H")" ]
done
out="$(env HOME="$H" PATH="$notools" "$REPO/bootstrap.sh" --profile server --dry-run 2>&1)"
check "server without starship: plans to download it" grep -q '^download to ~/.local: starship' <<< "$out"
out="$(env HOME="$H" PATH="$notools" "$REPO/bootstrap.sh" --profile workstation --dry-run 2>&1)" && rc=0 || rc=$?
check "workstation without tree-sitter: exits 0 and plans to download it" \
  bash -c '[ "$1" = 0 ] && grep -q "^download to ~/.local:.*tree-sitter" <<< "$2"' _ "$rc" "$out"
fi  # stow available

# ── Bash ─────────────────────────────────────────────────────────────────────
section "bash"
filter() { grep -v -e 'no job control' -e 'cannot set terminal process group' || true; }
H="$WORK/bash-home"; mkdir -p "$H"
ln -s "$REPO/bash/.bashrc" "$H/.bashrc"   # what stow makes, without needing stow
sh_env=(env -i HOME="$H" PATH="/usr/local/bin:/usr/bin:/bin" TERM=xterm-256color)

out="$("${sh_env[@]}" bash -c '. ~/.bashrc; echo "[$(alias | wc -l)]"' 2>&1)"
check "non-interactive (scp, ssh host cmd): no output, no aliases" [ "$out" = "[0]" ]
err="$("${sh_env[@]}" bash -i -c true 2>&1 | filter)"
check "interactive shell starts without errors" [ -z "$err" ]
[ -z "$err" ] || show "$err"
out="$("${sh_env[@]}" bash -i -c 'p=$PATH c=$PROMPT_COMMAND; . ~/.bashrc; . ~/.bashrc
  [ "$p" = "$PATH" ] && echo path-ok; [ "$c" = "$PROMPT_COMMAND" ] && echo hooks-ok
  type -t ll' 2>/dev/null)"
check "re-sourcing keeps PATH" grep -q path-ok <<< "$out"
check "re-sourcing keeps PROMPT_COMMAND" grep -q hooks-ok <<< "$out"
check "aliases module loaded" grep -qx alias <<< "$out"
printf 'alias zzlocal=true\n' > "$H/.bashrc.local"
out="$("${sh_env[@]}" bash -i -c 'type -t zzlocal' 2>/dev/null)"
check "~/.bashrc.local sourced" [ "$out" = alias ]

# ~/.bashrc alone on a PATH with no optional tools. --norc skips the
# distro's /etc/bash.bashrc: that is the system's file, not ours (Ubuntu
# 24.04's calls `groups` and `cat` for its sudo hint), and this check is
# about what the dotfiles themselves need.
bare="$WORK/bare-bin"; mkdir -p "$bare"
for c in bash dirname readlink basename; do ln -sf "$(command -v "$c")" "$bare/$c"; done
out="$(env -i HOME="$H" PATH="$bare" TERM=xterm "$bare/bash" --norc -i -c '. ~/.bashrc; type -t ll; echo "EDITOR=$EDITOR"' 2>&1 | filter)"
check "~/.bashrc with no optional tools on PATH: no errors, EDITOR=vi" [ "$out" = $'alias\nEDITOR=vi' ]
[ "$out" = $'alias\nEDITOR=vi' ] || show "$out"

H2="$WORK/no-install-home"; mkdir -p "$H2"
out="$(env -i HOME="$H2" PATH=/usr/bin:/bin bash --rcfile "$REPO/bash/.bashrc" -i -c 'type -t ll' 2>/dev/null)"
check "works straight from a clone: bash --rcfile <repo>/bash/.bashrc" [ "$out" = alias ]

# ── tmux ─────────────────────────────────────────────────────────────────────
section "tmux"
if command -v tmux >/dev/null 2>&1; then
  H="$WORK/tmux-home"; mkdir -p "$H/.config"
  ln -s "$REPO/tmux/.config/tmux" "$H/.config/tmux"
  sock="dotfiles-test-$$"
  # The prefix the config sets proves it was read (tmux's default is C-b)
  prefix="$(sed -n 's/^set -g prefix \([^ ]*\).*/\1/p' "$REPO/tmux/.config/tmux/tmux.conf")"
  # Config errors make tmux open its first pane in view mode to list them
  res="$(env -i HOME="$H" PATH=/usr/bin:/bin TERM=xterm-256color tmux -L "$sock" \
         new-session -d -x 80 -y 24 \; display -p '#{pane_in_mode} #{prefix}' 2>&1 || true)"
  tmux -L "$sock" kill-server 2>/dev/null || true
  check "config loads without errors ($(tmux -V))" [ "$res" = "0 $prefix" ]
  res="$(env -i HOME="$H" PATH=/usr/bin:/bin SSH_CONNECTION='1 2 3 4' tmux -L "$sock" \
         new-session -d \; show -gv status-left 2>&1 || true)"
  tmux -L "$sock" kill-server 2>/dev/null || true
  check "over SSH the status bar shows the host" grep -q '#h' <<< "$res"
else
  skip "tmux not installed"
fi

# ── Editors ──────────────────────────────────────────────────────────────────
section "editors"
H="$WORK/editor-home"; mkdir -p "$H/.config"
ln -s "$REPO/vim/.vimrc" "$H/.vimrc"
ln -s "$REPO/nvim-lite/.config/nvim" "$H/.config/nvim"
ed_env=(env -i HOME="$H" PATH=/usr/bin:/bin TERM=xterm-256color)

if command -v vim >/dev/null 2>&1; then
  out="$("${ed_env[@]}" "$(command -v vim)" -N -u "$H/.vimrc" -i NONE -es \
         -c 'if &shiftwidth != 4 | cquit | endif' -c 'qall!' 2>&1)" && rc=0 || rc=$?
  check "vim loads ~/.vimrc cleanly" [ "$rc" = 0 ]
  [ -z "$out" ] || show "$out"
else
  skip "vim not installed"
fi

if command -v nvim >/dev/null 2>&1; then
  NVIM="$(command -v nvim)"   # the caller's nvim, even if not in /usr/bin
  printf 'a:\n  - b\n' > "$WORK/t.yaml"
  out="$("${ed_env[@]}" "$NVIM" --headless "$WORK/t.yaml" -c 'lua io.stdout:write(
    ("sw=%d clip=%s\n"):format(vim.bo.shiftwidth, vim.g.clipboard and vim.g.clipboard.name or "none"))' \
    -c 'qall!' 2>&1)" && rc=0 || rc=$?
  check "nvim-lite starts cleanly ($("$NVIM" --version | head -n 1))" \
    bash -c '[ "$1" = 0 ] && ! grep -qi -e error -e "E[0-9][0-9]*:" <<< "$2"' _ "$rc" "$out"
  check "nvim-lite uses ~/.vimrc (yaml indent 2)" grep -q 'sw=2' <<< "$out"
  if "$NVIM" --headless -u NONE -i NONE -c 'if !has("nvim-0.10") | cquit | endif' -c 'qall!' 2>/dev/null; then
    check "nvim-lite: OSC 52 clipboard when there is no display" grep -q 'clip=OSC 52' <<< "$out"
  fi
  [ "$rc" = 0 ] || show "$out"
  check "nvim-lite downloaded nothing" [ ! -e "$H/.local/share/nvim/lazy" ]

  out="$("$NVIM" --headless -u NONE -i NONE -c "lua
    local bad = 0
    for _, f in ipairs(vim.fn.globpath([[$REPO]], 'nvim*/.config/nvim/**/*.lua', false, true)) do
      local ok, err = loadfile(f)
      if not ok then print(err) bad = bad + 1 end
    end
    if bad > 0 then vim.cmd('cquit') end" -c 'qall!' 2>&1)" && rc=0 || rc=$?
  check "every Neovim Lua file parses" [ "$rc" = 0 ]
  [ "$rc" = 0 ] || show "$out"
else
  skip "nvim not installed"
fi

# ── The repo itself ──────────────────────────────────────────────────────────
section "repo"
check "nothing above modified the repo copy" [ "$repo_before" = "$(snapshot "$REPO")" ]

printf '\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" = 0 ]
