-- Línea de pestañas propia (basada en craftzdog/dotfiles, utils/tabline.lua).
-- La nativa acorta la ruta entera ("oil:///home/..." → "o///h/s/D/..."); esta muestra
-- icono + nombre del archivo, y para oil la carpeta con ~.
-- Los colores salen del tema activo (cambia con Salchipapa-Shell), no de una paleta fija.

local M = {}

local LEFT = "" -- nf-ple-lower_right_triangle
local RIGHT = "" -- nf-ple-lower_left_triangle
local MAX_NAME = 20
local TRUNCATE_TO = 17

local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

function M.setup_hl()
  local accent = hl("DiagnosticWarn").fg or hl("WarningMsg").fg
  local base = hl("Normal")
  local dim = hl("CursorLine").bg or hl("Visual").bg
  local text = hl("Comment").fg or base.fg

  vim.api.nvim_set_hl(0, "TabLineActive", { fg = base.bg or 0x000000, bg = accent, bold = true })
  vim.api.nvim_set_hl(0, "TabLineInactive", { fg = text, bg = dim })
  vim.api.nvim_set_hl(0, "TabLineSepActive", { fg = accent, bg = "NONE" })
  vim.api.nvim_set_hl(0, "TabLineSepInactive", { fg = dim, bg = "NONE" })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
end

local function icon_for(filename)
  local ok, icons = pcall(require, "mini.icons")
  if ok and icons.get then
    return (icons.get("file", filename))
  end
  return ""
end

local function buf_info(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local bt, ft = vim.bo[bufnr].buftype, vim.bo[bufnr].filetype

  if bt == "terminal" then
    return "[Terminal]", ""
  end
  if ft == "oil" then
    local dir = vim.fn.fnamemodify((name:gsub("^oil://", "")), ":~")
    if #dir > MAX_NAME then
      dir = "…" .. dir:sub(-TRUNCATE_TO)
    end
    return dir, ""
  end
  if name == "" then
    return "[Sin nombre]", ""
  end
  -- Buffers de plugins (codediff, etc.) con nombre tipo "codediff://...": solo el final
  local file = vim.fn.fnamemodify(name, ":t")
  if file == "" then
    file = name
  end
  if #file > MAX_NAME then
    file = file:sub(1, TRUNCATE_TO) .. "…"
  end
  return file, icon_for(file)
end

local function render_tab(tabnr, active)
  local bufnr = vim.fn.tabpagebuflist(tabnr)[vim.fn.tabpagewinnr(tabnr)]
  if not bufnr then
    return ""
  end
  local name, icon = buf_info(bufnr)
  local title = "  " .. (vim.bo[bufnr].modified and "[+] " or "") .. icon .. " " .. name .. "  "
  local tab_hl = active and "%#TabLineActive#" or "%#TabLineInactive#"
  local sep_hl = active and "%#TabLineSepActive#" or "%#TabLineSepInactive#"
  -- %NT ... %T: pestaña clicable
  return string.format("%%%dT%s%s%s%s%s%s%%T", tabnr, sep_hl, LEFT, tab_hl, title, sep_hl, RIGHT)
end

function M.render()
  local ok, out = pcall(function()
    local parts, current = {}, vim.fn.tabpagenr()
    for tabnr = 1, vim.fn.tabpagenr("$") do
      parts[#parts + 1] = render_tab(tabnr, tabnr == current)
    end
    return table.concat(parts) .. "%#TabLineFill#"
  end)
  return ok and out or "%#TabLineFill#"
end

M.setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("salchipapa_tabline", { clear = true }),
  callback = M.setup_hl,
})

return M
