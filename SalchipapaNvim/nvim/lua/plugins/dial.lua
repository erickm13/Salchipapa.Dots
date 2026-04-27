return {
  "monaqa/dial.nvim",
  keys = {
    { "<C-a>", function() require("dial.map").manipulate("increment", "normal") end, desc = "Increment" },
    { "<C-x>", function() require("dial.map").manipulate("decrement", "normal") end, desc = "Decrement" },
    { "g<C-a>", function() require("dial.map").manipulate("increment", "gnormal") end, desc = "Increment (sequential)" },
    { "g<C-x>", function() require("dial.map").manipulate("decrement", "gnormal") end, desc = "Decrement (sequential)" },
    { "<C-a>", function() require("dial.map").manipulate("increment", "visual") end, mode = "v", desc = "Increment" },
    { "<C-x>", function() require("dial.map").manipulate("decrement", "visual") end, mode = "v", desc = "Decrement" },
    { "g<C-a>", function() require("dial.map").manipulate("increment", "gvisual") end, mode = "v", desc = "Increment (sequential)" },
    { "g<C-x>", function() require("dial.map").manipulate("decrement", "gvisual") end, mode = "v", desc = "Decrement (sequential)" },
    { "<leader>uD", function()
      vim.g.dial_enabled = vim.g.dial_enabled ~= false
      pcall(vim.keymap.del, "n", "<C-a>")

      if vim.g.dial_enabled then
        vim.keymap.set("n", "<C-a>", function() require("dial.map").manipulate("increment", "normal") end, { desc = "Increment" })
        vim.notify("Dial habilitado (<C-a> incrementa)", vim.log.levels.INFO)
      else
        vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select All" })
        vim.notify("Dial deshabilitado (<C-a> = Select All)", vim.log.levels.INFO)
      end
    end, desc = "Toggle Dial / Select All" },
  },
  config = function()
    local augend = require("dial.augend")
    require("dial.config").augends:register_group({
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.alias["%Y/%m/%d"],
        augend.date.alias["%Y-%m-%d"],
        augend.date.alias["%d/%m/%Y"],
        augend.constant.alias.bool,
        augend.semver.alias.semver,
        augend.constant.new({ elements = { "&&", "||" }, word = false, cyclic = true }),
        augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
        augend.constant.new({ elements = { "let", "const" }, word = true, cyclic = true }),
        augend.constant.new({ elements = { "===", "!==" }, word = false, cyclic = true }),
      },
    })
  end,
}
