-- Language servers: the "intelligence" half of an IDE.
--
-- Go-to-definition, find-references, rename-symbol, hover docs, inline
-- errors, code actions. Each language has its own server binary; mason
-- downloads and updates those for you.
--
--   :Mason        browse and manage installed servers, formatters, linters
--   :LspInfo      which servers are attached to this buffer, and why
--   :checkhealth vim.lsp
--
-- To add a language: add an entry to the `servers` table below. mason
-- installs it on next start. To remove one: delete its entry.

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },

    dependencies = {
      { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      -- JSON/YAML schemas, so package.json and CI files get real completion
      "b0o/schemastore.nvim",
      -- Small spinner showing which server is indexing
      { "j-hui/fidget.nvim", opts = { notification = { window = { winblend = 0 } } } },
    },

    config = function()
      -- ==================================================================
      -- How diagnostics look
      -- ==================================================================
      local nf = vim.g.have_nerd_font
      vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        update_in_insert = false, -- do not nag mid-keystroke
        virtual_text = {
          spacing = 2,
          source = "if_many",
          prefix = nf and "●" or "*",
        },
        float = { border = "rounded", source = "if_many" },
        signs = nf and {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
          },
        } or true,
      })

      -- ==================================================================
      -- Keymaps, bound only in buffers that actually have a server attached
      -- ==================================================================
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(event)
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          -- Navigation. These open in Telescope so you get a previewable list
          -- rather than jumping blind.
          local ok, builtin = pcall(require, "telescope.builtin")
          if ok then
            map("gd", builtin.lsp_definitions, "Go to definition")
            map("gr", builtin.lsp_references, "Go to references")
            map("gi", builtin.lsp_implementations, "Go to implementation")
            map("gy", builtin.lsp_type_definitions, "Go to type definition")
            map("<leader>cs", builtin.lsp_document_symbols, "Document symbols")
            map("<leader>cS", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")
          else
            map("gd", vim.lsp.buf.definition, "Go to definition")
            map("gr", vim.lsp.buf.references, "Go to references")
            map("gi", vim.lsp.buf.implementation, "Go to implementation")
          end
          map("gD", vim.lsp.buf.declaration, "Go to declaration")

          -- Documentation. K is the vim convention for "what is this".
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<C-k>", vim.lsp.buf.signature_help, "Signature help", "i")

          -- Changing code
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          -- Highlight every other use of the symbol under the cursor
          if client:supports_method("textDocument/documentHighlight") then
            local hl_group = vim.api.nvim_create_augroup("user_lsp_highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Inlay hints: inferred types and parameter names shown inline.
          -- Off by default because they shift text around; toggle per buffer.
          if client:supports_method("textDocument/inlayHint") then
            map("<leader>ch", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
            end, "Toggle inlay hints")
          end
        end,
      })

      -- ==================================================================
      -- Capabilities: tell servers what this editor can do. blink.cmp
      -- advertises extra completion features, so ask it.
      -- ==================================================================
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end
      vim.lsp.config("*", { capabilities = capabilities })

      -- ==================================================================
      -- The servers themselves.
      -- Key = lspconfig server name. Value = per-server settings.
      -- ==================================================================
      local servers = {
        -- Lua, tuned for editing this Neovim config (see lazydev in
        -- completion.lua, which supplies the vim API types)
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              codeLens = { enable = true },
              hint = { enable = true, arrayIndex = "Disable" },
              diagnostics = { disable = { "missing-fields" } },
              format = { enable = false }, -- stylua does this instead
            },
          },
        },

        -- Python: basedpyright types and navigates, ruff lints and formats.
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard", -- "strict" if you want the full firehose
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticSeverityOverrides = {
                  reportMissingImports = "warning",
                },
              },
            },
          },
        },
        ruff = {
          -- basedpyright already provides hover; let it own that
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },

        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              staticcheck = true,
              usePlaceholders = true,
              analyses = {
                unusedparams = true,
                shadow = true,
                nilness = true,
                unusedwrite = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },

        -- Web
        ts_ls = {},
        html = {},
        cssls = {},
        eslint = {},
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },

        -- SQL. Keyword completion and syntax diagnostics out of the box.
        --
        -- sqls (not sqlls - that one is unmaintained and crashes on Node 22)
        -- can also do schema-aware completion, but only once you point it at
        -- a database. To do that, create ~/.config/sqls/config.yml:
        --
        --     connections:
        --       - driver: postgresql
        --         dataSourceName: host=127.0.0.1 port=5432 user=me dbName=mydb
        --
        -- See https://github.com/sqls-server/sqls#db-configuration
        sqls = {},
      }

      for name, cfg in pairs(servers) do
        vim.lsp.config(name, cfg)
      end

      -- ==================================================================
      -- C#
      -- ==================================================================
      -- omnisharp needs the .NET SDK, which is not installed on this machine.
      -- Install it first:
      --     sudo apt-get install -y dotnet-sdk-8.0
      -- then add "omnisharp" to ensure_installed below and restart Neovim.
      -- Treesitter already highlights C# without any of this.

      -- ==================================================================
      -- Install everything above, plus the command-line tools that conform
      -- and nvim-lint shell out to.
      -- ==================================================================
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = true, -- v2 calls vim.lsp.enable() for each
      })

      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua",        -- lua formatter
          "gofumpt",       -- go formatter (stricter gofmt)
          "goimports",     -- go import organiser
          "prettier",      -- js/ts/html/css/json/yaml/markdown formatter
          "sql-formatter", -- sql formatter
          "shfmt",         -- shell formatter
          -- Debug adapters (debugpy, delve) are installed by mason-nvim-dap
          -- in dap.lua. Listing them here too makes both race for the same
          -- package and one of them errors out.
        },
        run_on_start = true,
        auto_update = false,
      })

      vim.keymap.set("n", "<leader>cm", "<cmd>Mason<CR>", { desc = "Mason (LSP installer)" })
    end,
  },
}
