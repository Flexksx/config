local d = os.getenv("HOME") .. "/config/dotfiles/hypr/lua/"
local scratchpad = dofile(d .. "scratchpad.lua")

hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 5,
	bezier = "expressive_default_spatial",
	style = "slidevert",
})

scratchpad.create({
	key_bind = "SUPER + P",
	apps = { { class = "sonora", command = "sonora" } },
	special_ws = "sonora-scratchpad",
	show_mode = "workspace",
	launch_at_startup = false,
	enable_timer = true,
	unfocus_timeout = 1000,
	close_on_escape_key = true,
})

local SPECIAL = "special:comms"
local GAPS_VERTICAL = 12
local GAPS_HORIZONTAL = 60

local last_direction = nil

local function apply_layout()
	local mon = hl.get_active_monitor()
	local vertical = mon ~= nil and (mon.transform % 2 == 1)
	local direction = vertical and "down" or "right"
	if direction == last_direction then
		return
	end
	last_direction = direction
	local gaps = vertical and GAPS_VERTICAL or GAPS_HORIZONTAL
	hl.workspace_rule({ workspace = SPECIAL, layout_opts = { direction = direction }, gaps_out = gaps })
end

scratchpad.create({
	key_bind = "SUPER + bracketright",
	apps = {
		{ class = "org.telegram.desktop", command = "Telegram" },
	},
	special_ws = "comms",
	show_mode = "workspace",
	float = false,
	before_show = apply_layout,
	launch_at_startup = true,
	enable_timer = false,
	close_on_escape_key = true,
})
