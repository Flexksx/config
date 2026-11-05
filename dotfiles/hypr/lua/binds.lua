local home = os.getenv("HOME")
local mod = "SUPER"
local terminal = "ghostty"
local fileManager = "nautilus"
local browser = "zen-beta"
local editor = "zeditor"
local screenshot = "hyprshot -m region --clipboard-only"
local screenshotEdit = "wl-paste | satty --filename -"
local quickshell = "qs -p " .. home .. "/config/dotfiles/quickshell"

local function quickshell_toggle(target)
	return quickshell .. " ipc call " .. target .. " toggle || " .. quickshell .. " -d"
end

local wallpaperPicker = quickshell_toggle("wallpaper")
local overview = quickshell_toggle("overview")

local function bind_mod(key, action, opts)
	hl.bind(mod .. " + " .. key, action, opts)
end

local function bind_key_exec(key, cmd)
	hl.bind(key, hl.dsp.exec_cmd(cmd))
end

local function bind_mod_exec(key, cmd)
	bind_key_exec(mod .. " + " .. key, cmd)
end

local key_commands = {
	{ "XF86AudioNext", "playerctl next" },
	{ "XF86AudioPrev", "playerctl previous" },
	{ "XF86AudioPlay", "playerctl play-pause" },
	{ "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
	{ "XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
	{ "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
	{ "XF86MonBrightnessUp", "brightnessctl set 5%+" },
	{ "XF86MonBrightnessDown", "brightnessctl set 5%-" },
	{ "Print", screenshot },
}
for _, bind in ipairs(key_commands) do
	bind_key_exec(bind[1], bind[2])
end

local mod_key_commands = {
	{ "RETURN", terminal },
	{ "E", fileManager },
	{ "B", browser },
	{ "F", editor },
	{ "Z", editor .. " " .. home .. "/config/" },
	{ "N", "pkill java" },
	{ "S", screenshot },
	{ "SHIFT + S", screenshotEdit },
	{ "W", wallpaperPicker },
	{ "TAB", overview },
}
for _, bind in ipairs(mod_key_commands) do
	bind_mod_exec(bind[1], bind[2])
end

hl.bind(mod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("wlrctl pointer scroll 0 -3"), { ["repeat"] = true })
hl.bind(mod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("wlrctl pointer scroll 0 3"), { ["repeat"] = true })

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

bind_mod("C", hl.dsp.window.close())
bind_mod("V", hl.dsp.window.float({ action = "toggle" }))

bind_mod("comma", hl.dsp.layout("move -col"))
bind_mod("period", hl.dsp.layout("move +col"))
bind_mod("SHIFT + comma", hl.dsp.layout("colresize -conf"))
bind_mod("SHIFT + period", hl.dsp.layout("colresize +conf"))
hl.bind("CTRL + " .. mod .. " + comma", hl.dsp.layout("swapcol l"))
hl.bind("CTRL + " .. mod .. " + period", hl.dsp.layout("swapcol r"))
bind_mod("slash", hl.dsp.layout("center"))

local directions = {
	{ vim = "H", arrow = "left", mouse = "mouse_left", dir = "l" },
	{ vim = "J", arrow = "down", mouse = "mouse_down", dir = "d" },
	{ vim = "K", arrow = "up", mouse = "mouse_up", dir = "u" },
	{ vim = "L", arrow = "right", mouse = "mouse_right", dir = "r" },
}
for _, k in ipairs(directions) do
	local focus = hl.dsp.focus({ direction = k.dir })
	bind_mod(k.vim, focus)
	bind_mod(k.arrow, focus)
	bind_mod(k.mouse, focus)
end

for i = 1, 9 do
	bind_mod(i, hl.dsp.focus({ workspace = i }))
	bind_mod("SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
bind_mod("0", hl.dsp.focus({ workspace = 10 }))
bind_mod("SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

bind_mod("mouse:276", hl.dsp.focus({ workspace = "e-1" }))
bind_mod("mouse:273", hl.dsp.focus({ workspace = "e+1" }))
