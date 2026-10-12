-- Debugger (DAP = Debug Adapter Protocol).
--
-- This is the thing that makes an editor an IDE: set a breakpoint, run the
-- program, and when it stops you get the call stack, every variable's live
-- value, a watch list and a REPL in the paused program's scope. Far better
-- than scattering print statements.
--
-- Try it once on a Python file to see what it does:
--   1. put the cursor on a line inside a function and press <leader>db
--      (a red dot appears in the sign column)
--   2. press <leader>dc and pick "Launch file"
--   3. the UI opens; execution stops at your line
--   4. <leader>do steps over, <leader>di steps into, <leader>dc continues
--   5. <leader>dt ends the session
--
-- Full key list:
--   <leader>db   toggle breakpoint            <leader>dB  conditional breakpoint
--   <leader>dc   continue / start             <leader>dC  run to cursor
--   <leader>di   step into                    <leader>do  step over
--   <leader>dO   step out                     <leader>dt  terminate
--   <leader>du   toggle the debugger UI       <leader>dr  open the REPL
--   <leader>de   evaluate expression under cursor (also works on a selection)
--
-- nvim-dap loads on those keys, or when you open a Python or Go file (the
-- language adapters below register their launch configurations then). The
-- UI panels and the mason installer stay unloaded until a session starts.

return {
  {
    "mfussenegger/nvim-dap",

    -- Only the inline-value display loads with nvim-dap. The UI panels and
    -- the mason adapter installer are separate specs below, so that opening
    -- a .py or .go file does not drag the whole debugger in with it.
    dependencies = {
      -- Each variable's current value shown inline, beside the code
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = { virt_text_pos = "eol", commented = true },
      },
    },

    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Break when this is true: " }, function(cond)
            if cond then require("dap").set_breakpoint(cond) end
          end)
        end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last configuration" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle debugger UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Evaluate expression" },
      { "<leader>dx", function() require("dap").clear_breakpoints() end, desc = "Clear all breakpoints" },
    },

    config = function()
      local dap = require("dap")

      -- Breakpoint signs
      local signs = {
        DapBreakpoint = { text = "●", texthl = "DiagnosticSignError" },
        DapBreakpointCondition = { text = "◆", texthl = "DiagnosticSignWarn" },
        DapLogPoint = { text = "◇", texthl = "DiagnosticSignInfo" },
        DapStopped = { text = "▶", texthl = "DiagnosticSignWarn", linehl = "Visual" },
        DapBreakpointRejected = { text = "✖", texthl = "DiagnosticSignError" },
      }
      for name, opts in pairs(signs) do
        vim.fn.sign_define(name, opts)
      end

      -- Open the UI automatically when a session starts, close it after.
      -- require() inside the callback is what pulls nvim-dap-ui in, so the
      -- panels cost nothing until you actually debug something.
      dap.listeners.after.event_initialized["dapui_config"] = function() require("dapui").open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() require("dapui").close() end
      dap.listeners.before.event_exited["dapui_config"] = function() require("dapui").close() end
    end,
  },

  -- ====================================================================
  -- The debugger UI: scopes, breakpoints, stacks, watches, REPL, console.
  -- Loads on first require - either from the listeners above when a session
  -- starts, or from <leader>du / <leader>de.
  -- ====================================================================
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    main = "dapui",
    dependencies = { "nvim-neotest/nvim-nio" },
    opts = {
      icons = { expanded = "", collapsed = "", current_frame = "" },
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.35 },
            { id = "breakpoints", size = 0.15 },
            { id = "stacks", size = 0.25 },
            { id = "watches", size = 0.25 },
          },
          size = 44,
          position = "left",
        },
        {
          elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } },
          size = 12,
          position = "bottom",
        },
      },
    },
  },

  -- ====================================================================
  -- Installs debug adapters through mason.
  --
  -- This ships a very large table of default adapter configurations, which
  -- cost ~350ms to load, so it is gated behind its commands rather than
  -- loading with nvim-dap. debugpy and delve are already installed; run
  -- :DapInstall <adapter> by hand if you ever need another one.
  -- ====================================================================
  {
    "jay-babu/mason-nvim-dap.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    dependencies = "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "python", "delve" },
      handlers = {}, -- use mason-nvim-dap's default configuration
    },
  },

  -- ====================================================================
  -- Python. Adds "Launch file", "Attach", and "Debug this test" configs.
  -- ====================================================================
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      -- Use the debugpy that mason installed, not one from your project
      local debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      if vim.fn.executable(debugpy) == 1 then
        require("dap-python").setup(debugpy)
      else
        require("dap-python").setup("python3")
      end
    end,
  },

  -- ====================================================================
  -- Go, via delve
  -- ====================================================================
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
  },

  -- ====================================================================
  -- JavaScript / TypeScript debugging needs the vscode-js-debug adapter,
  -- which is a heavier setup. Ask me and I will add it; until then, Node
  -- code is debuggable with `node --inspect` plus an attach config.
  -- ====================================================================
}
