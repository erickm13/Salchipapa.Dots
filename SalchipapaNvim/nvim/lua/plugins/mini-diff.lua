-- mini.diff (extra de LazyVim): saltar entre cambios con ]c/[c en vez de ]h/[h,
-- la misma tecla que dentro de codediff (como craftzdog).
return {
  "nvim-mini/mini.diff",
  opts = {
    mappings = {
      goto_next = "]c",
      goto_prev = "[c",
      goto_last = "]C",
      goto_first = "[C",
    },
  },
}
