-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Pestañas: solo si hay más de una, con icono + nombre (ver lua/config/tabline.lua)
vim.o.showtabline = 1
vim.o.tabline = "%!v:lua.require('config.tabline').render()"
