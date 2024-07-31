local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 12
config.window_decorations = "RESIZE"
config.adjust_window_size_when_changing_font_size = false

config.initial_cols = 120
config.font = wezterm.font("MonaspiceNe NFM", { weight = "Regular" })

return config
