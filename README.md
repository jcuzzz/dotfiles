# dotfiles

Personal Bash, tmux, Neovim, Vim, Git, Starship and psql settings for one
person working across:

- a **workstation**: WSL Ubuntu or a Linux desktop, with a full Neovim IDE
- **servers**: Ubuntu/Debian VMs reached over SSH (PostgreSQL/dbt warehouse
  VMs, cloud instances, homelab)
- **minimal** environments: containers, recovery shells, unfamiliar boxes

Same keys everywhere: `Ctrl-a` tmux prefix, `Ctrl-h/j/k/l` across tmux panes
and editor splits, vi copy mode, the same aliases.

## What this repo is (and isn't)

| Concern | Handled by |
|---|---|
| Personal shell, editor, tmux, git settings | **this repo**, linked with GNU Stow |
| Installing programs (tmux, neovim, fzf, ...) | your package manager (`apt`) |
| Servers: packages, users, SSH hardening, PostgreSQL, dbt | Ansible, kept separately |

Nothing here installs software, needs sudo once stow is present, or
changes your login shell.

## Install

```sh
sudo apt install stow                 # once per machine (or via Ansible)
git clone https://github.com/jcuzzz/dotfiles ~/dotfiles   # any path works
~/dotfiles/install.sh --profile server   # workstation (default) | server | minimal
exec bash
```

| Command | Does |
|---|---|
| `./install.sh --profile NAME` | link that profile's packages; unlink the rest |
| `./install.sh --profile NAME --dry-run` | show what would happen; change nothing |
| `./install.sh --uninstall` | remove every link stow made |

`install.sh` is a thin wrapper (~130 lines) around GNU Stow:

- **Stow** creates the symlinks, skips ones that are already right (so
  re-running is safe), and refuses to overwrite anything it doesn't own.
  When it refuses, it changes nothing at all.
- **The wrapper** picks the packages for the profile, and moves files that
  would block stow, such as the stock `~/.bashrc` on a fresh Ubuntu, to
  `~/.dotfiles-backup/<timestamp>/`. It also replaces absolute links left by
  this repo's old installer.

Anything else in the way, such as a symlink pointing somewhere unrelated,
makes stow stop and print the path. Nothing changes. Move it aside and
re-run.

### Profiles

A profile is just a list of packages (top-level folders here, laid out
like `$HOME`):

| Package | Links | workstation | server | minimal |
|---|---|:-:|:-:|:-:|
| `bash` | `~/.bashrc`, `~/.bashrc.d/` | ✓ | ✓ | ✓ |
| `git` | `~/.gitconfig` | ✓ | ✓ | ✓ |
| `vim` | `~/.vimrc` (plain Vim; also the base of nvim-lite) | ✓ | ✓ | ✓ |
| `tmux` | `~/.config/tmux/` | ✓ | ✓ | |
| `nvim` | `~/.config/nvim/`: full IDE, lazy.nvim, LSP, DAP ([README](nvim/.config/nvim/README.md)) | ✓ | | |
| `nvim-lite` | `~/.config/nvim/`: no plugins, no network, OSC 52 copy | | ✓ | |
| `starship` | `~/.config/starship.toml` | ✓ | ✓ | |
| `psql` | `~/.psqlrc` | ✓ | ✓ | |

Packages are the only difference between profiles. The config files
themselves are the same on every machine. Anything optional (fzf, zoxide,
starship, direnv, git prompt, `docker`/`kubectl` aliases) switches itself on
only when that program is installed. A bare container therefore gets plain
Bash, and nothing errors.

Want stow directly? `stow -d ~/dotfiles -t ~ bash git vim tmux nvim-lite`
does the same as `--profile server` minus the backup step.

### Without stow

On a box where you can't install anything:

```sh
bash --rcfile ~/dotfiles/bash/.bashrc     # try it, nothing written to HOME
ln -s ~/dotfiles/bash/.bashrc ~/.bashrc   # or link by hand (move the old one first)
ln -s ~/dotfiles/vim/.vimrc ~/.vimrc
```

Or copy just `.bashrc`, `.bashrc.d/` and `.vimrc` over.

## Programs

Install what you want with apt. Every one is optional:

```sh
# server
sudo apt install stow tmux neovim git
# workstation extras
sudo apt install fzf zoxide ripgrep fd-find jq direnv shellcheck
```

| Program | Used for |
|---|---|
| Neovim 0.11+ | workstation IDE. Ubuntu's apt build is older; use the [official tarball](https://github.com/neovim/neovim/releases) in `/opt/nvim` or `~/.local` (`.bashrc` adds both to PATH). nvim-lite works with apt's build |
| tmux 3.2+ | sessions, OSC 52 copy |
| fzf, zoxide | `Ctrl-R`, `Ctrl-T`, `Alt-C`; `z`/`zi`; the `tm` picker |
| starship | prompt; not in older Ubuntu repos: grab the release binary into `~/.local/bin` |
| direnv | per-project env from `.envrc` (keep secrets in gitignored `.envrc` files) |
| ripgrep, fd, jq | search and JSON; Telescope uses rg/fd |

## Updating

Everything is a symlink, so editing `~/.bashrc` edits the repo. Commit and
push, then on the other machines:

```sh
cd ~/dotfiles && git pull && ./install.sh --profile <same profile>
exec bash        # tmux: prefix r; nvim: restart
```

If you delete or rename a file in a package, run `stow -R -d ~/dotfiles -t ~
<package>` once to drop the old link. On the workstation, after a pull run
`nvim -c "Lazy restore" -c qa` to match `lazy-lock.json`.

## Per-machine settings (never committed)

| File | For |
|---|---|
| `~/.bashrc.local` | PATHs, proxies, work aliases. Sourced last |
| `~/.gitconfig.local` | e.g. a work email: `[user] email = ...` |
| `~/.vimrc.local` | Vim and nvim-lite tweaks |
| `~/.config/tmux/local.conf` | tmux tweaks (gitignored) |
| `nvim/.../lua/config/local.lua`, `lua/plugins/local.lua` | IDE settings / plugins (gitignored) |

Secrets never go in the repo: database passwords in `~/.pgpass` (mode 600)
or `~/.pg_service.conf`, cloud keys in `~/.aws/`, SSH keys in `~/.ssh/`.

## Shell

`~/.bashrc` keeps Ubuntu's defaults plus a few additions:
- larger history, timestamped, written after every command
- `EDITOR` set to nvim, falling back to vim, then vi
- `~/.local/bin` and `/opt/nvim/bin` added to PATH once
- `~/.bashrc.d/aliases.sh` and `~/.bashrc.d/tools.sh` loaded

It does nothing in non-interactive shells, so `scp`, `sftp`, `rsync`,
`ssh host cmd` and Ansible behave exactly as on a stock system. Sourcing it
twice doesn't duplicate PATH entries or prompt hooks. `vi`/`vim` open
Neovim only when it is installed and you aren't root.

Aliases. Each exists only if its program does, and none change how `rm`,
`cp`, `mv` etc. behave:

| | |
|---|---|
| Navigation | `..` `...` `....`, `mkcd dir`, `z foo` / `zi` |
| Files | `ll` `la` `l`, `lt` (newest last), `dus` (sizes here), `dfh` (real disks) |
| Git | `g`, `gs`, `gd`, `gds`, `gl` |
| Admin | `ports`, `psg name`, `sc` / `scs` (systemctl), `failed` |
| Logs | `jf` (follow journal), `ju unit`, `jboot`, `lessf file` |
| Other | `py`, `dps`, `k`, `tf`, `tm`, `reload` (`exec bash`), `alert` |

The prompt is Ubuntu's `user@host:dir$`, with ` (branch)` when git is
installed, or Starship if that is installed.

## tmux and SSH

Prefix `Ctrl-a`; everything else is listed in `tmux/.config/tmux/tmux.conf`.

| Key | Does |
|---|---|
| `Ctrl-h/j/k/l` | move between panes *and* Vim/Neovim splits (IDE, nvim-lite and plain Vim) |
| `prefix \|` / `prefix -`, `prefix c` | split right / below / new window, in the current directory |
| `Alt-1..9`, `prefix Tab` | jump to window, last window |
| `prefix Enter` | copy mode (`v` select, `y` copy) |
| `prefix s` / `prefix S` | pick session / window |
| `prefix d` | detach |
| `F12` | nested tmux: send all keys to the inner (remote) one; `F12` again to return |

tmux never starts automatically. To keep work alive on a server across
disconnects:

```sh
ssh db1
tm          # attach to session "main", creating it if needed (tm etl: named)
...         # prefix d, or just lose the connection
ssh db1
tm          # back where you were; tmux ls lists sessions
```

Sessions survive disconnects, not reboots. Over SSH the status bar shows an
amber `host:session` badge, so a remote tmux inside your local one is easy
to tell apart. Press `Ctrl-a` twice to reach the inner one, or use `F12`.

## Clipboard

- **tmux:** `set-clipboard on` sends copies to your terminal as OSC 52.
  They land on the clipboard of the machine you are sitting at, even from a
  server, even through nested tmux. Supported by Windows Terminal, WezTerm,
  kitty, Alacritty, iTerm2, foot and recent xterm. tmux only sends it when
  the terminal advertises support, so others just get no clipboard, never
  stray characters. With a local display (WSLg, desktop) tmux also pipes to
  `xclip` if installed.
- **nvim-lite** (Neovim 0.10+, no display): yanks go out via OSC 52 the same
  way. `p` pastes your last yank. For text from your own machine use the
  terminal's paste key, because reading the clipboard over OSC 52 is blocked
  or prompts in most terminals.
- **The workstation IDE** uses xclip (WSLg), unchanged.
- **Plain Vim and Neovim older than 0.10** have no OSC 52. Copy with tmux
  copy mode instead.

## psql

`~/.psqlrc` changes only interactive behaviour:
- a `user@host:port/db` prompt that marks open transactions
- per-database history
- `ON_ERROR_ROLLBACK interactive`
- upper-case keyword completion

Query output is untouched, so scripts calling `psql` without `-X` see no
difference. Opt-in helpers: `:timing`, `:x`, `:nulls`, `:activity`.

## Recovery

| Situation | Do |
|---|---|
| Stow refused with a conflict | nothing was changed. Move the listed path aside, re-run |
| Want an original back | `rm ~/.bashrc && mv ~/.dotfiles-backup/<timestamp>/.bashrc ~/` |
| Remove everything | `./install.sh --uninstall` (links only; backups and other files untouched) |
| Shell broken after an edit | `bash --norc`, fix the file, `exec bash` |
| SSH login doesn't load `.bashrc` | make `~/.bash_profile` (or `~/.profile`) contain `. ~/.bashrc` |
| Old `~/.tmux.conf` interferes | tmux loads it as well as `~/.config/tmux/tmux.conf`; move it aside |
| `~/.config is a symlink` error | it was folded into a repo by some stow run. Replace it with a real dir: `mv ~/.config ~/.config.link && mkdir ~/.config`, then re-run |

## Testing

```sh
tests/run.sh      # needs stow; tmux/vim/nvim checks run if installed
shellcheck install.sh tests/run.sh bash/.bashrc bash/.bashrc.d/*.sh
```

What the tests cover. Each runs in a throwaway HOME against a copy of the
repo cloned at a path with spaces:
- every profile, re-runs, and profile switches
- dry-run and uninstall changing nothing
- backups of a stock `~/.bashrc`, and stow's refusal on a foreign link
- migration from the old installer's absolute links
- that `~/.config` is never folded into the repo
- bash startup: silent when non-interactive, no duplicated hooks, works on
  a bare system
- the tmux config loading, `.vimrc` in Vim, nvim-lite starting cleanly

CI (`.github/workflows/ci.yml`) runs ShellCheck and the suite on Ubuntu
24.04 with apt's stow, tmux, vim and neovim. It runs it again in a bare
`ubuntu:24.04` container with only stow added.
