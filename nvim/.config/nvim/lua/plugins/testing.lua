-- Test runner.
--
-- Run the test your cursor is in, the whole file, or the whole suite,
-- without leaving Neovim. Results appear as pass/fail marks in the sign
-- column next to each test, and failures can be expanded to show the
-- assertion output.
--
--   <leader>tt   run the test under the cursor
--   <leader>tf   run every test in this file
--   <leader>ta   run the whole suite
--   <leader>tl   re-run the last one
--   <leader>ts   toggle the summary sidebar (a tree of every test)
--   <leader>to   show output for the test under the cursor
--   <leader>tO   toggle the persistent output panel
--   <leader>tw   watch mode: re-run this file whenever it changes
--   <leader>td   debug the test under the cursor (stops at your breakpoints)
--
-- Adapters below detect the framework automatically - pytest for Python,
-- go test for Go, jest for JS/TS.

return {
  {
    "nvim-neotest/neotest",

    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",

      -- Adapters. Delete a line to drop support for that language.
      "nvim-neotest/neotest-python",
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-jest",
    },

    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file" },
      { "<leader>ta", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all tests" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last test" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop running test" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
      {
        "<leader>to",
        function() require("neotest").output.open({ enter = true, auto_close = true }) end,
        desc = "Show test output",
      },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle watch mode" },
      {
        "<leader>td",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "Debug nearest test",
      },
    },

    config = function()
      -- Make failure output readable inside the floating window
      vim.api.nvim_set_hl(0, "NeotestPassed", { fg = "#B8E986" })
      vim.api.nvim_set_hl(0, "NeotestFailed", { fg = "#FF5C57" })
      vim.api.nvim_set_hl(0, "NeotestRunning", { fg = "#FFD75F" })

      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            -- Uses the active virtualenv if there is one
            runner = "pytest",
            dap = { justMyCode = false }, -- step into library code too
          }),
          require("neotest-golang")({
            dap_go_enabled = true,
          }),
          require("neotest-jest")({
            jestCommand = "npm test --",
          }),
        },

        status = { virtual_text = true, signs = true },
        output = { open_on_run = false },
        quickfix = { enabled = false }, -- the summary pane is better than quickfix

        icons = vim.g.have_nerd_font and {
          passed = "",
          failed = "",
          running = "",
          skipped = "",
          unknown = "",
        } or nil,
      })
    end,
  },
}
