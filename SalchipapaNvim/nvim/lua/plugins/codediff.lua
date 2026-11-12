-- CodeDiff: diff de git al estilo VS Code (lista de archivos cambiados + diff lado a lado)
-- URL: https://github.com/esmuellert/codediff.nvim
-- Complementa a mini.diff (marcas en el margen del buffer abierto): esto es para revisar
-- todos los cambios del repo, un commit, una rama o un PR. La librería del diff se
-- descarga sola la primera vez (:CodeDiff install! para reinstalarla).
--
-- Dentro de la vista: ]f/[f archivo siguiente/anterior, ]c/[c cambio, - stage/unstage,
-- t lado a lado/en línea, g? ayuda, q cerrar.

return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<leader>gv", "<cmd>CodeDiff<cr>", desc = "CodeDiff (cambios del repo)" },
    { "<leader>gV", "<cmd>CodeDiff history %<cr>", desc = "CodeDiff historial del archivo" },
    { "<leader>gV", ":CodeDiff history<cr>", mode = "v", desc = "CodeDiff historial de las líneas" },
  },
  opts = {
    explorer = {
      -- Totales +/- por archivo y carpeta, como en la captura de craftzdog
      line_stats = { enabled = true },
    },
  },
}
