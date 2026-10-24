local home = os.getenv("HOME")
local d = home .. "/config/dotfiles/hypr/lua/rog/"

dofile(d .. "environment.lua")
dofile(d .. "startup.lua")
