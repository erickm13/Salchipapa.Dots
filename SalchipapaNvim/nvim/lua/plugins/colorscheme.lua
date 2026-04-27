return {
  {
    -- {
    --   "xiyaowong/transparent.nvim",
    --   config = function()
    --     require("transparent").setup({
    --       extra_groups = { -- table/string: additional groups that should be cleared
    --         "Normal",
    --         "NormalNC",
    --         "Comment",
    --         "Constant",
    --         "Special",
    --         "Identifier",
    --         "Statement",
    --         "PreProc",
    --         "Type",
    --         "Underlined",
    --         "Todo",
    --         "String",
    --         "Function",
    --         "Conditional",
    --         "Repeat",
    --         "Operator",
    --         "Structure",
    --         "LineNr",
    --         "NonText",
    --         "SignColumn",
    --         "CursorLineNr",
    --         "EndOfBuffer",
    --       },
    --       exclude_groups = {}, -- table: groups you don't want to clear
    --     })
    --   end,
    -- },
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      opts = {
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        transparent_background = true, -- disables setting the background color.
        term_colors = true, -- sets terminal colors (e.g. `g:terminal_color_0`)
      },
    },
    {
      "Gentleman-Programming/gentleman-kanagawa-blur",
      name = "gentleman-kanagawa-blur",
      priority = 1000,
    },
    {
      "Alan-TheGentleman/oldworld.nvim",
      lazy = false,
      priority = 1000,
      opts = {},
    },
    {
      "rebelot/kanagawa.nvim",
      priority = 1000,
      lazy = true,
      config = function()
        require("kanagawa").setup({
          compile = false, -- enable compiling the colorscheme
          undercurl = true, -- enable undercurls
          commentStyle = { italic = true },
          functionStyle = {},
          keywordStyle = { italic = true },
          statementStyle = { bold = true },
          typeStyle = {},
          transparent = true, -- do not set background color
          dimInactive = false, -- dim inactive window `:h hl-NormalNC`
          terminalColors = true, -- define vim.g.terminal_color_{0,17}
          colors = { -- add/modify theme and palette colors
            palette = {},
            theme = {
              wave = {},
              lotus = {},
              dragon = {},
              all = {
                ui = {
                  bg_gutter = "none", -- set bg color for normal background
                  bg_sidebar = "none", -- set bg color for sidebar like nvim-tree
                  bg_float = "none", -- set bg color for floating windows
                },
              },
            },
          },
          overrides = function(colors) -- add/modify highlights
            return {
              LineNr = { bg = "none" },
              NormalFloat = { bg = "none" },
              FloatBorder = { bg = "none" },
              FloatTitle = { bg = "none" },
              TelescopeNormal = { bg = "none" },
              TelescopeBorder = { bg = "none" },
              LspInfoBorder = { bg = "none" },
            }
          end,
          theme = "wave", -- Load "wave" theme
          background = { -- map the value of 'background' option to a theme
            dark = "wave", -- try "dragon" !
            light = "lotus",
          },
        })
      end,
    },
    {
      "rose-pine/neovim",
      name = "rose-pine",
      priority = 1000,
      opts = {
        variant = "moon", -- auto, main, moon, dawn
        dark_variant = "moon",
        dim_inactive_windows = false,
        extend_background_behind_borders = true,
        styles = {
          bold = true,
          italic = true,
          transparency = true,
        },
      },
    },
    {
      "EdenEast/nightfox.nvim",
      priority = 1000,
      opts = {
        options = {
          transparent = true,
          terminal_colors = true,
          styles = {
            comments = "italic",
            keywords = "bold",
            functions = "italic,bold",
          },
        },
      },
    },
    {
      "scottmckendry/cyberdream.nvim",
      priority = 1000,
      opts = {
        transparent = true,
        italic_comments = true,
        hide_fillchars = true,
        borderless_telescope = true,
      },
    },
    {
      "navarasu/onedark.nvim",
      priority = 1000,
      opts = {
        style = "darker", -- dark, darker, cool, deep, warm, warmer, light
        transparent = true,
        term_colors = true,
        code_style = {
          comments = "italic",
          keywords = "none",
          functions = "none",
          strings = "none",
          variables = "none",
        },
      },
    },
    {
      "sainnhe/gruvbox-material",
      priority = 1000,
      init = function()
        vim.g.gruvbox_material_background = "hard" -- soft, medium, hard
        vim.g.gruvbox_material_foreground = "material" -- material, mix, original
        vim.g.gruvbox_material_transparent_background = 1
        vim.g.gruvbox_material_enable_italic = 1
        vim.g.gruvbox_material_enable_bold = 1
      end,
    },
    -- Oscuros / Minimalistas
    {
      "nyoom-engineering/oxocarbon.nvim",
      priority = 1000,
      lazy = true,
    },
    {
      "slugbyte/lackluster.nvim",
      priority = 1000,
      lazy = true,
      opts = {},
    },
    {
      "mcchrish/zenbones.nvim",
      priority = 1000,
      lazy = true,
      dependencies = { "rktjmp/lush.nvim" },
    },
    -- Cálidos / Naturaleza
    {
      "neanias/everforest-nvim",
      priority = 1000,
      lazy = true,
      opts = {
        style = "hard", -- soft, medium, hard
        transparent_background_level = 2,
        italics = true,
      },
    },
    {
      "ellisonleao/gruvbox.nvim",
      priority = 1000,
      lazy = true,
      opts = {
        transparent_mode = true,
        italic = {
          strings = false,
          emphasis = true,
          comments = true,
          operators = false,
          folds = true,
        },
      },
    },
    {
      "xero/miasma.nvim",
      priority = 1000,
      lazy = true,
    },
    -- Nord / Fríos
    {
      "AlexvZyl/nordic.nvim",
      priority = 1000,
      lazy = true,
      opts = {
        transparent = {
          bg = true,
          float = true,
        },
        bright_border = false,
        reduced_blue = true,
        italic_comments = true,
      },
    },
    {
      "shaunsingh/nord.nvim",
      priority = 1000,
      lazy = true,
      init = function()
        vim.g.nord_contrast = true
        vim.g.nord_borders = false
        vim.g.nord_disable_background = true
        vim.g.nord_italic = true
        vim.g.nord_bold = true
      end,
    },
    -- Synthwave / Retro
    {
      "maxmx03/fluoromachine.nvim",
      priority = 1000,
      lazy = true,
      opts = {
        glow = false,
        theme = "fluoromachine", -- fluoromachine, retrowave, delta
        transparent = true,
      },
    },
    {
      "samharju/synthweave.nvim",
      priority = 1000,
      lazy = true,
      opts = {
        transparent = true,
      },
    },
    -- Inspirados en editores populares
    {
      "projekt0n/github-nvim-theme",
      name = "github-theme",
      priority = 1000,
      lazy = true,
      opts = {
        options = {
          transparent = true,
          styles = {
            comments = "italic",
            keywords = "bold",
          },
        },
      },
    },
    {
      "olimorris/onedarkpro.nvim",
      priority = 1000,
      lazy = true,
      opts = {
        styles = {
          comments = "italic",
          keywords = "bold",
          functions = "italic",
        },
        options = {
          transparency = true,
        },
      },
    },
    {
      "craftzdog/solarized-osaka.nvim",
      priority = 1000,
      lazy = false,
      opts = {
        transparent = true,
        styles = {
          comments = { italic = true },
          keywords = { bold = true },
        },
      },
    },
    {
      "marko-cerovac/material.nvim",
      priority = 1000,
      lazy = true,
      init = function()
        vim.g.material_style = "deep ocean" -- darker, lighter, oceanic, palenight, deep ocean
      end,
      opts = {
        contrast = {
          terminal = false,
          sidebars = false,
          floating_windows = false,
          non_current_windows = false,
        },
        styles = {
          comments = { italic = true },
          keywords = { bold = true },
          functions = { italic = true },
        },
        disable = {
          background = true,
        },
      },
    },
    -- Kanagawa family
    {
      "sho-87/kanagawa-paper.nvim",
      priority = 1000,
      lazy = true,
      opts = {
        transparent = true,
        ink = true,
      },
    },
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "solarized-osaka",
      },
    },
  },
}
