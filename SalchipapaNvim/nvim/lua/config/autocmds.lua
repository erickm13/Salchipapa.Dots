-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Transparencia en ventanas de terminal (claude-code, lazygit, etc.)
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.wo.winhighlight = "Normal:Normal,NormalFloat:Normal"
  end,
})

-- Asegura que los grupos de snacks también sean transparentes al cambiar de colorscheme
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "none" })
    vim.api.nvim_set_hl(0, "SnacksNormalFloat", { bg = "none" })
  end,
})
