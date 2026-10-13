# ~/.bashrc: executed by bash(1) for non-login shells.
# shellcheck shell=bash
# Managed in the dotfiles repo (bash package). Layout:
#
#   ~/.bashrc                   this file: core settings, plain Bash
#   ~/.bashrc.d/aliases.sh      portable aliases and functions
#   ~/.bashrc.d/tools.sh        git prompt, fzf, zoxide, direnv, starship -
#                               each only if it is installed
#   ~/.bashrc.local             this machine only, untracked; sourced last
#
# Identical on every profile: anything optional switches itself on when the
# tool exists, so a bare container gets plain Bash and nothing else.
# Safe to source more than once: PATH entries and hooks are not duplicated.

# If not running interactively, don't do anything. This keeps scp, sftp,
# rsync and `ssh host command` exactly as the system intended.
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=50000
# When each command ran - handy when reconstructing what happened on a server
HISTTIMEFORMAT='%F %T  '

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh /usr/bin/lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ── Prompt ───────────────────────────────────────────────────────────────────
# Ubuntu's default user@host:dir$ prompt. tools.sh adds the git branch, or
# hands over to starship if that is installed.

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "${force_color_prompt:-}" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "${color_prompt:-}" = yes ]; then
    _ps1_user='01;32'                       # green user@host...
    [ "${EUID:-0}" -eq 0 ] && _ps1_user='01;31'   # ...red when root
    PS1='${debian_chroot:+($debian_chroot)}\[\033['"$_ps1_user"'m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt _ps1_user

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(/usr/bin/dircolors -b ~/.dircolors)"
    else
        eval "$(/usr/bin/dircolors -b)"
    fi
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ── Personal additions (managed in ~/dotfiles) ──────────────────────────────

# Write each command to history as soon as it runs, so tmux panes don't lose
# history when another pane exits
case "${PROMPT_COMMAND:-}" in
    *"history -a"*) ;;
    *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# Add a directory to the front of PATH once, and only if it exists
_path_prepend() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# webi/envman: puts ~/.local/bin and Go on PATH, if installed
# shellcheck disable=SC1091
[ -s "$HOME/.config/envman/load.sh" ] && . "$HOME/.config/envman/load.sh"
_path_prepend "$HOME/.local/bin"
_path_prepend /opt/nvim/bin    # official Neovim tarball location, if used

# Editor: Neovim if it is installed, otherwise Vim, otherwise plain vi. Never
# hard-wired, so a server or recovery shell without nvim still works.
if command -v nvim >/dev/null 2>&1; then
    EDITOR='nvim'
elif command -v vim >/dev/null 2>&1; then
    EDITOR='vim'
else
    EDITOR='vi'
fi
export EDITOR
export SUDO_EDITOR="$EDITOR"

alias reload='exec bash'  # fresh shell; cleaner than re-sourcing this file

# ── Modules ──────────────────────────────────────────────────────────────────
# Found next to this file's real location, so they load whether ~/.bashrc is
# a stow link or you start a throwaway shell straight from a clone with
# `bash --rcfile ~/dotfiles/bash/.bashrc` (nothing installed).
_bash_mod="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.bashrc.d"
[ -d "$_bash_mod" ] || _bash_mod="$HOME/.bashrc.d"
for _f in "$_bash_mod/aliases.sh" "$_bash_mod/tools.sh"; do
    # shellcheck disable=SC1090
    [ -r "$_f" ] && . "$_f"
done
unset _bash_mod _f

# Machine-specific settings (PATHs, work proxies, etc.) go in ~/.bashrc.local,
# which is not tracked
# shellcheck disable=SC1091
if [ -f "$HOME/.bashrc.local" ]; then
    . "$HOME/.bashrc.local"
fi
