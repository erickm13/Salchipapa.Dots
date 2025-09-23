return {
  {
    "nvzone/showkeys",
    cmd = "ShowkeysToggle",
    opts = {
      position = "bottom-center",
      maxkeys = 3,
      show_count = true,
      winopts = {
        focusable = false,
        relative = "editor",
        style = "minimal",
        border = "single",
        height = 1,
        row = vim.o.lines - 2,
        col = math.floor(vim.o.columns - 30 / 2),
      },
    },
  },
}
