local d = os.getenv("HOME") .. "/config/dotfiles/hypr/lua/"
local scratchpad = dofile(d .. "scratchpad.lua")

-- Only relevant when show_mode = "workspace"
hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 5,
	bezier = "expressive_default_spatial",
	style = "slidevert",
})

scratchpad.create({
	key_bind = "SUPER + P",
	apps = { { class = "spotify", command = "spotify" } },
	special_ws = "spotify-scratchpad",
	show_mode = "workspace", -- "window": float on active ws, auto-hide on focus loss
	-- "workspace": overlay with slidevert, auto-hide on ws/monitor change
	enable_timer = true,
	unfocus_timeout = 1000,
	close_on_escape_key = true,
})
