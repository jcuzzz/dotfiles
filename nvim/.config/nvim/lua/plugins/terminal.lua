-- Integrated terminal.
--
--   <C-\>         toggle a floating terminal (works from inside it too)
--   <leader>gg    lazygit in a full-screen float, if lazygit is installed
--   <leader>tp    a python REPL
--
-- Inside a terminal, <Esc><Esc> returns to normal mode so you can scroll
-- and copy; i goes back to typing.

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { [[<C-\>]], "<cmd>ToggleTerm<CR>", mode = { "n", "t" }, desc = "Toggle terminal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Terminal (float)" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Terminal (below)" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<CR>", desc = "Terminal (right)" },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = { border = "rounded" },
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      shade_terminals = false,
      start_in_insert = true,
      persist_size = true,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      local Terminal = require("toggleterm.terminal").Terminal

      -- lazygit: a full TUI for staging, committing, branching, rebasing.
      -- Not installed on this machine yet:
      --     sudo apt-get install -y lazygit
      -- (or see https://github.com/jesseduffield/lazygit#installation)
      local lazygit = Terminal:new({
        cmd = "lazygit",
        direction = "float",
        hidden = true,
        float_opts = { border = "rounded", width = 10000, height = 10000 },
        on_open = function(term)
          -- let lazygit have the q key
          vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = term.bufnr })
        end,
      })

      vim.keymap.set("n", "<leader>gg", function()
        if vim.fn.executable("lazygit") == 0 then
          vim.notify("lazygit is not installed", vim.log.levels.WARN)
          return
        end
        lazygit:toggle()
      end, { desc = "Lazygit" })

      -- A Python REPL, using the project's virtualenv if one is active
      local python = Terminal:new({ cmd = "python3", direction = "float", hidden = true })
      vim.keymap.set("n", "<leader>tp", function()
        python:toggle()
      end, { desc = "Python REPL" })
    end,
  },
}
