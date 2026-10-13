-- Lightweight Neovim for servers (the `nvim-lite` package; the workstation
-- profile installs the full IDE from the `nvim` package instead).
--
-- No plugins, no plugin manager, no network, no Nerd Font. Settings and
-- keymaps come from ~/.vimrc (the `vim` package), so Vim and Neovim behave
-- the same on a server. Works on distro builds back to Neovim 0.6.

local vimrc = vim.fn.expand("~/.vimrc")
if vim.fn.filereadable(vimrc) == 1 then
  vim.cmd("source " .. vim.fn.fnameescape(vimrc))
end

-- Nothing to probe for at startup
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Clipboard over SSH (Neovim 0.10+): yanks are sent to your terminal as an
-- OSC 52 escape, which puts them on the clipboard of the machine you are
-- sitting at (through tmux too, via its set-clipboard). Copy only: `p`
-- pastes what you last yanked here, and your terminal's paste key brings
-- in text from outside, because reading the clipboard over OSC 52 is
-- blocked or prompts in most terminals. Skipped when a display exists.
local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
local display = (os.getenv("DISPLAY") or "") ~= "" or (os.getenv("WAYLAND_DISPLAY") or "") ~= ""
if ok and not display then
  local last = { ["+"] = { { "" }, "v" }, ["*"] = { { "" }, "v" } }
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last[reg] = { lines, regtype }
      send(lines, regtype)
    end
  end
  local function paste(reg)
    return function() return last[reg] end
  end
  vim.g.clipboard = {
    name = "OSC 52 (copy only)",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste("+"), ["*"] = paste("*") },
  }
  vim.opt.clipboard = "unnamedplus"
end

-- Briefly highlight what was yanked (vim.hl is 0.11+, vim.highlight older)
vim.cmd([[autocmd TextYankPost * silent! lua (vim.hl or vim.highlight).on_yank()]])

-- This machine only (untracked): ~/.vimrc.local is sourced by ~/.vimrc
