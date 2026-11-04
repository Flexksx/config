local home = os.getenv("HOME")
local d = home .. "/config/dotfiles/hypr/lua/"

dofile(d .. "environment.lua")
dofile(d .. "appearance.lua")
dofile(d .. "layout.lua")
dofile(d .. "animations.lua")
dofile(d .. "controls.lua")
dofile(d .. "rules.lua")
dofile(d .. "startup.lua")
dofile(d .. "binds.lua")
dofile(d .. "binds_noctalia.lua")
dofile(d .. "spotify-scratchpad.lua")
dofile(d .. "comms-scratchpad.lua")

dofile(d .. "monitors.lua")

-- Machine-specific overrides
local f = io.open("/etc/hostname", "r")
local hostname = f and f:read("*l") or ""
if f then
	f:close()
end

if hostname == "nixos" then
	dofile(d .. "rog/index.lua")
end
