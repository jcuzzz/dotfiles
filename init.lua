-- ~/.config/nvim/init.lua
--
-- Entry point. Everything else lives in lua/ so this file stays readable.
--
--   lua/config/   editor settings that do not depend on plugins
--   lua/plugins/  one file per plugin (or per group of related plugins);
--                 lazy.nvim imports the whole directory automatically, so
--                 adding a plugin means adding a file, and removing one
--                 means deleting that file. Nothing else to edit.

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
