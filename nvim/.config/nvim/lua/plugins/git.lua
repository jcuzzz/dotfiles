-- Git integration.
--
-- gitsigns  marks changed lines in the sign column, and lets you stage,
--           reset and preview a single hunk without leaving the file
-- diffview  full side-by-side diffs, file history, merge conflict resolution
--
--   ]h / [h        next / previous changed hunk
--   <leader>gs     stage the hunk under the cursor
--   <leader>gr     reset (discard) that hunk
--   <leader>gp     preview it in a popup
--   <leader>gb     blame this line
--   <leader>gd     open the full diff view
--   <leader>gh     file history for the current file

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      current_line_blame = false, -- toggled with <leader>gB
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },

      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
        end

        map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Previous hunk")

        map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline blame")
        map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")

        -- ih is a text object: `vih` selects the hunk, `dih` deletes it
        map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end,
    },
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view (working tree)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "File history (branch)" },
      { "<leader>gx", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
      },
    },
  },
}
