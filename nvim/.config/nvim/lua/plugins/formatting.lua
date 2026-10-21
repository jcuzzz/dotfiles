-- Formatting, via conform.nvim.
--
-- Runs on every save. To turn it off temporarily:
--   :FormatDisable          this session, every buffer
--   :FormatDisable!         this buffer only
--   :FormatEnable           back on
-- Or format by hand with <leader>cf, which also works on a visual selection.
--
-- To change which tool formats a language, edit formatters_by_ft below. The
-- tools themselves are installed by mason (see lsp.lua).

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },

    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer / selection",
      },
    },

    opts = {
      -- A list means "run all of these in order".
      -- { "a", "b", stop_after_first = true } means "first one installed wins".
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
        go = { "goimports", "gofumpt" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        sql = { "sql_formatter" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        -- C#: handled by the language server until you install csharpier
        -- cs = { "csharpier" },
      },

      default_format_opts = { lsp_format = "fallback" },

      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end,

      formatters = {
        shfmt = { prepend_args = { "-i", "2" } },
        -- PostgreSQL by default (sql-formatter.json next to init.lua). A project
        -- can override it with its own .sql-formatter.json, e.g. for SQLite:
        --   { "language": "sqlite", "keywordCase": "lower" }
        sql_formatter = {
          prepend_args = function(_, ctx)
            local cfg = vim.fs.find(".sql-formatter.json", { path = ctx.dirname, upward = true })[1]
            return { "--config", cfg or (vim.fn.stdpath("config") .. "/sql-formatter.json") }
          end,
        },
      },
    },

    init = function()
      -- Let conform own the gq operator too
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, { desc = "Disable format-on-save (! = this buffer only)", bang = true })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = "Re-enable format-on-save" })
    end,
  },
}
