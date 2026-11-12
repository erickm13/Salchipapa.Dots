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
    -- Basado en la config de craftzdog (cap. 6.3 de su video)
    explorer = {
      width = 50,
      view_mode = "tree",
      -- Abrir el diff al moverte por la lista con j/k, sin pulsar Enter
      auto_open_on_cursor = true,
      -- Totales +/- por archivo y carpeta
      line_stats = { enabled = true },
    },
    diff = {
      -- Modo compacto: pliega lo que no cambió y deja 8 líneas de contexto (gc lo alterna)
      compact = true,
      compact_context_lines = 8,
      compact_sync_folds = true, -- abrir/cerrar pliegues en los dos lados a la vez
    },
  },
}
