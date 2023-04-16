if vim.fn.has("nvim-0.7.0") == 0 then
  vim.api.nvim_err_writeln("pensieve requires at least nvim-0.7.0.1")
  return
end

-- make sure this file is loaded only once
if vim.g.loaded_pensieve == 1 then
  return
end
vim.g.loaded_pensieve = 1

-- create any global command that does not depend on user setup
-- usually it is better to define most commands/mappings in the setup function
-- Be careful to not overuse this file!
local pensieve = require("pensieve")

vim.api.nvim_create_user_command(
  "MyAwesomePluginGenericGreet",
  pensieve.generic_greet,
  {})

