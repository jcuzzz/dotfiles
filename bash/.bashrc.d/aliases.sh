# shellcheck shell=bash
# Portable aliases and functions, loaded by ~/.bashrc on every profile.
#
# Rules: plain Bash and coreutils only; anything needing another program is
# defined only when that program exists; nothing here changes how a
# destructive command (rm, cp, mv, kill, ...) behaves.

# ── Navigation ───────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── Files ────────────────────────────────────────────────────────────────────
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -lhtr'              # newest last: what just changed here?
alias dus='du -sh -- * .[!.]* 2>/dev/null | sort -h'   # size of each entry
alias dfh='df -hT -x tmpfs -x devtmpfs -x squashfs -x overlay'

# ── Editors ──────────────────────────────────────────────────────────────────
# vi/vim open Neovim only when it is installed, and never for root, so
# recovery and sudo sessions keep the system editor.
if command -v nvim >/dev/null 2>&1 && [ "${EUID:-0}" -ne 0 ]; then
    alias vim=nvim
    alias vi=nvim
fi
command -v python3 >/dev/null 2>&1 && alias py=python3

# ── Git ──────────────────────────────────────────────────────────────────────
if command -v git >/dev/null 2>&1; then
    alias g=git
    alias gs='git status -sb'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gl='git log --oneline --graph --decorate -20'
fi

# ── System administration ────────────────────────────────────────────────────
command -v ss >/dev/null 2>&1 && alias ports='ss -tulpn'     # listening sockets
alias psg='ps -eo pid,user,%cpu,%mem,etime,args | grep -v grep | grep -i --'
if command -v systemctl >/dev/null 2>&1; then
    alias sc='systemctl'
    alias scs='systemctl status'
    alias failed='systemctl --failed --no-pager'
fi

# ── Logs ─────────────────────────────────────────────────────────────────────
if command -v journalctl >/dev/null 2>&1; then
    alias jf='journalctl -f'            # follow everything
    alias ju='journalctl -e -u'         # ju postgresql: one unit, jump to end
    alias jboot='journalctl -b -p warning --no-pager'   # this boot's warnings
fi
alias lessf='less +F'                   # follow a log; Ctrl-C to scroll, F to resume

# ── Data / DevOps (only if the tool is installed) ────────────────────────────
command -v docker >/dev/null 2>&1 &&
    alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
command -v kubectl >/dev/null 2>&1 && alias k=kubectl
command -v terraform >/dev/null 2>&1 && alias tf=terraform

# ── tmux ─────────────────────────────────────────────────────────────────────
# tm [name]  attach to session <name>, creating it if needed (default "main").
# With no name, and fzf + zoxide installed, pick a recent directory instead
# and open (or switch to) a session named after it.
if command -v tmux >/dev/null 2>&1; then
    tm() {
        local dir name
        if [ -n "${1:-}" ]; then
            name=$1 dir=$PWD
        elif command -v fzf >/dev/null 2>&1 && command -v zoxide >/dev/null 2>&1; then
            dir=$(zoxide query --list | fzf --prompt="tmux session> ") || return
            name=$(basename "$dir" | tr '.:' '__')
        else
            name=main dir=$HOME
        fi

        if ! tmux has-session -t "=$name" 2>/dev/null; then
            tmux new-session -d -s "$name" -c "$dir" || return
        fi
        if [ -n "${TMUX:-}" ]; then
            tmux switch-client -t "=$name"
        else
            tmux attach-session -t "=$name"
        fi
    }
fi

# ── Misc ─────────────────────────────────────────────────────────────────────
# mkcd dir: make a directory (and parents) and cd into it
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }
