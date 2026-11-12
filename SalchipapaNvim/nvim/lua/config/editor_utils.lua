-- Utilidades del editor (basadas en craftzdog/dotfiles, utils/editor.lua).
-- Copiar rutas y trozos de código para pasárselos a un agente (Claude, Codex…)
-- y cerrar los buffers que no se ven.

local M = {}

local function root()
  local ok, r = pcall(function()
    return LazyVim.root()
  end)
  return (ok and r) or vim.uv.cwd()
end

local function copy(text, msg)
  vim.fn.setreg("+", text)
  vim.notify(msg, vim.log.levels.INFO, { title = "Copiado" })
end

--- Ruta relativa a la raíz del proyecto con la línea: lab2/Request.java#L42
function M.yank_relative_path()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("El buffer no tiene archivo", vim.log.levels.WARN)
  end
  local rel = vim.fs.relpath(root(), file) or vim.fn.fnamemodify(file, ":.")
  local path = rel .. "#L" .. vim.fn.line(".")
  copy(path, path)
end

--- Ruta absoluta con la línea
function M.yank_absolute_path()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("El buffer no tiene archivo", vim.log.levels.WARN)
  end
  local path = file .. "#L" .. vim.fn.line(".")
  copy(path, path)
end

--- La selección como bloque de código markdown con archivo y línea:
--- ```java filename="lab2/Request.java" line=42
function M.copy_as_codeblock()
  local s, e = vim.fn.line("'<"), vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("El buffer no tiene archivo", vim.log.levels.WARN)
  end
  local rel = vim.fs.relpath(root(), file) or vim.fn.fnamemodify(file, ":.")
  local lang = ({
    typescriptreact = "tsx",
    javascriptreact = "jsx",
    typescript = "ts",
    javascript = "js",
  })[vim.bo.filetype] or vim.bo.filetype
  local out = { "```" .. lang .. ' filename="' .. rel .. '" line=' .. s }
  vim.list_extend(out, lines)
  table.insert(out, "```")
  copy(table.concat(out, "\n"), #lines .. " líneas como bloque de código")
end

--- Cierra los buffers listados que no están en ninguna ventana (salta los que tienen cambios)
function M.delete_hidden_buffers()
  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  local deleted, skipped = 0, 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and not visible[buf] then
      if vim.bo[buf].modified then
        skipped = skipped + 1
      else
        pcall(vim.api.nvim_buf_delete, buf, {})
        deleted = deleted + 1
      end
    end
  end
  local msg = "Cerrados " .. deleted .. " buffers ocultos"
  if skipped > 0 then
    msg = msg .. " (" .. skipped .. " con cambios sin guardar)"
  end
  vim.notify(msg, vim.log.levels.INFO)
end

return M
