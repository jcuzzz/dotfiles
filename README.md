# dotfiles

WSL/Linux setup: bash, tmux, Neovim, starship, git.

## New machine

```sh
git clone https://github.com/jcuzzz/dotfiles ~/dotfiles
~/dotfiles/install.sh
exec bash
```

`install.sh` puts fzf, zoxide and starship in `~/.local/bin` (no sudo), then
symlinks each package into `$HOME`. Anything it replaces is moved to
`~/.dotfiles-backup/<timestamp>/`. It's safe to re-run. Use `--links` to skip the
tool downloads.

The repo is private, so log in to GitHub first (`gh auth login`) or clone
over SSH.

Neovim installs its plugins on first launch.

## Layout

One folder per app, mirroring `$HOME` (GNU Stow layout, so `stow <pkg>`
works too):

| Package  | Links to                    |
|----------|-----------------------------|
| bash     | `~/.bashrc`                 |
| git      | `~/.gitconfig`              |
| tmux     | `~/.config/tmux/`           |
| nvim     | `~/.config/nvim/`           |
| starship | `~/.config/starship.toml`   |

Because they're symlinks, editing `~/.bashrc` etc. edits the repo. Commit and
push, then `git pull` on the other machine.

## Per-machine settings (not tracked)

| File                          | For                                    |
|-------------------------------|----------------------------------------|
| `~/.bashrc.local`             | PATHs, proxies, work-only aliases      |
| `~/.gitconfig.local`          | e.g. a work email: `[user] email = ...`|
| `nvim/.../lua/config/local.lua`  | Neovim options for this machine     |
| `nvim/.../lua/plugins/local.lua` | Extra plugins for this machine      |

## Shell cheatsheet

| Key / command | Does |
|---|---|
| `Ctrl-R` | fuzzy search history |
| `Ctrl-T` | fuzzy pick a file, insert its path |
| `Alt-C`  | fuzzy pick a subdirectory and cd into it |
| `z foo`  | jump to the most-used dir matching "foo" |
| `zi`     | pick from matching dirs interactively |
| `tm`     | pick a dir, open/switch to a tmux session there |

The tmux prefix is `Ctrl-a`. See `tmux/.config/tmux/tmux.conf` for keys.
