-- Texto de los diagnósticos con el servidor y el código: "msg (jdtls: 1234)"
-- Basado en craftzdog/dotfiles (cap. 5.2 de su video). LazyVim aplica opts.diagnostics
-- con vim.diagnostic.config al cargar nvim-lspconfig, así que va aquí y no en un autocmd.
return {
  "neovim/nvim-lspconfig",
  opts = {
    diagnostics = {
      virtual_text = {
        format = function(d)
          local extra = vim.tbl_filter(function(x)
            return x ~= nil and x ~= ""
          end, { d.source and tostring(d.source) or nil, d.code and tostring(d.code) or nil })
          if #extra == 0 then
            return d.message
          end
          return string.format("%s (%s)", d.message, table.concat(extra, ": "))
        end,
      },
    },
  },
}
