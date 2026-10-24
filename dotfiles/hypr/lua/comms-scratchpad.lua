-- Communication slideout scratchpad.
--
-- SUPER + ] toggles a special workspace holding the comms apps (Slack,
-- Telegram) and slides it out over the focused monitor. The apps are silently
-- assigned to the workspace at open time, so toggling only animates an
-- already-laid-out workspace -- the slide is smooth, like the spotify scratchpad.
--
-- The scroll layout adapts to the focused monitor's orientation, applied while
-- the workspace is still hidden so it never reflows mid-slide:
--   vertical monitor (transform odd) -> scroll down, normal gaps
--   horizontal monitor               -> scroll right, larger gaps

local d = os.getenv("HOME") .. "/config/dotfiles/hypr/lua/"
local scratchpad = dofile(d .. "scratchpad.lua")

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
		{ class = "slack", command = "slack" },
		{ class = "org.telegram.desktop", command = "Telegram" },
	},
	special_ws = "comms",
	show_mode = "workspace",
	float = false,
	before_show = apply_layout,
	enable_timer = false,
	close_on_escape_key = true,
})
