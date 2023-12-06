---@type ChadrcConfig 
local M = {}
M.ui = {
    theme = 'catppuccin'
}
M.plugins = "custom.plugins"
M.mappings = require "custom.mappings"

local windows = vim.fn.has("win32") == 1
if windows then
  vim.opt.shell = 'pwsh'
  vim.opt.shellcmdflag = '-nologo -noprofile -ExecutionPolicy RemoteSigned -command'
  vim.opt.shellxquote = ''
end

return M
