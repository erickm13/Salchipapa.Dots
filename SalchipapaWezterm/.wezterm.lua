-- Salchipapa.Dots — WezTerm (mismo aspecto que SalchipapaKitty: Solarized Osaka, IosevkaTerm)
local wezterm = require("wezterm")
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- ── Windows: abrir la distro de Arch en WSL ─────────────────────
if is_windows then
	-- La distro por defecto de WSL puede ser otra (p. ej. docker-desktop): se nombra explicitamente
	config.default_prog = { "wsl.exe", "-d", "archlinux", "--cd", "~" }
	-- Pasar TERM_PROGRAM a WSL para que fish sepa que esta en WezTerm (abre herdr al arrancar)
	config.set_environment_variables = { WSLENV = "TERM_PROGRAM:TERM_PROGRAM_VERSION" }
end

-- ── Fuente ──────────────────────────────────────────────────────
config.font = wezterm.font("IosevkaTerm Nerd Font")
config.font_size = 14

-- ── Ventana ─────────────────────────────────────────────────────
config.window_background_opacity = 0.75
-- WezTerm solo transparenta el fondo "por defecto"; herdr pinta el fondo de los paneles con un
-- color explicito (no hace caso a panel_bg = "reset") y sin esto queda opaco. Las dos opacidades
-- se combinan: 0.5 deja los paneles cerca de la barra lateral y aun se ven selecciones y resaltados
config.text_background_opacity = 0.5
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
config.hide_tab_bar_if_only_one_tab = true
config.enable_scroll_bar = false
config.window_close_confirmation = "NeverPrompt"
config.audible_bell = "Disabled"

-- ── Rendimiento e imagenes ──────────────────────────────────────
config.max_fps = 120
-- Protocolo de imagenes de kitty: fastfetch, herdr, spotify_player, yt-x
config.enable_kitty_graphics = true

-- ── Cursor ──────────────────────────────────────────────────────
config.default_cursor_style = "SteadyBlock"

-- ── Solarized Osaka ─────────────────────────────────────────────
config.colors = {
	background = "#001419",
	foreground = "#839395",
	cursor_bg = "#839395",
	cursor_fg = "#001419",
	cursor_border = "#839395",
	selection_bg = "#1a6397",
	selection_fg = "#839395",
	ansi = { "#001014", "#db302d", "#849900", "#b28500", "#268bd3", "#d23681", "#29a298", "#9eabac" },
	brights = { "#001419", "#db302d", "#849900", "#b28500", "#268bd3", "#d23681", "#29a298", "#839395" },
}

return config
