# shellcheck shell=bash
# Optional interactive tools, loaded by ~/.bashrc. Each block runs only if
# the tool is installed, so on a bare container this file does nothing and
# costs nothing. Install the tools with your package manager (see README).
#
# git:      branch in the prompt, via the helper git itself ships
# fzf:      Ctrl-R fuzzy history, Ctrl-T insert file path, Alt-C cd into dir
# zoxide:   `z part-of-dir` jumps to a dir you have visited before
# direnv:   loads/unloads a project's .envrc as you cd in and out
# starship: replaces the prompt entirely when installed
#
# Every init below guards against re-registering its hook, so sourcing
# ~/.bashrc twice does not stack PROMPT_COMMAND entries.

if ! declare -F __git_ps1 >/dev/null; then
    for _f in /usr/lib/git-core/git-sh-prompt \
              /usr/share/git-core/contrib/completion/git-prompt.sh; do
        # shellcheck disable=SC1090
        [ -r "$_f" ] && . "$_f" && break
    done
    unset _f
fi
if declare -F __git_ps1 >/dev/null; then
    # user@host:dir (branch)$  - inserted before the trailing "\$ "
    # shellcheck disable=SC2016  # expanded by bash at each prompt
    PS1="${PS1%'\$ '}"'$(__git_ps1 " (%s)")\$ '
fi

if command -v fzf >/dev/null 2>&1; then
    # `fzf --bash` needs fzf 0.48+; older distro packages ship the script
    if _fzf_init=$(fzf --bash 2>/dev/null); then
        eval "$_fzf_init"
    elif [ -r /usr/share/doc/fzf/examples/key-bindings.bash ]; then
        # shellcheck disable=SC1091
        . /usr/share/doc/fzf/examples/key-bindings.bash
    fi
    unset _fzf_init
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Desktop notification when a long command finishes:  sleep 10; alert
if command -v notify-send >/dev/null 2>&1; then
    alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
fi

return 0
