return {
  "jonroosevelt/gemini-cli.nvim",
  enabled = function()
    return vim.fn.executable("gemini") == 1
  end,
  config = function()
    require("gemini").setup()
  end,
}
