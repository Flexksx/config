local layer_rules = {
	{ match = { namespace = "notch" }, no_anim = true },
	{ match = { namespace = "grim" }, no_anim = true },
	{ match = { namespace = "grimshot" }, no_anim = true },
	{ match = { namespace = "slurp" }, no_anim = true },
	{ match = { namespace = "selection" }, no_anim = true },
	{ match = { namespace = "hyprexpo" }, no_anim = true },
	{ match = { namespace = "wlogout" }, no_anim = true },
	{ match = { namespace = "overview" }, no_anim = true },
}

local window_rules = {
	{ match = { class = "^(code)$" }, opacity = "0.95 0.95" },
	{ match = { class = "^(cursor)$" }, opacity = "0.95 0.95" },
	{ match = { class = "^(jetbrains-studio)$" }, opacity = "0.95 0.95" },
	{ match = { class = "^(jetbrains-idea)$" }, opacity = "0.95 0.95" },
	{ match = { class = "^(jetbrains-pycharm)$" }, opacity = "0.95 0.95" },
	{ match = { class = "^(sonora)$" }, opacity = "0.95 0.85" },
	{ match = { class = "^(org\\.gnome\\.Nautilus)$" }, opacity = "0.85 0.85" },
	{ match = { class = "^(dev\\.zed\\.Zed)$" }, opacity = "0.95 0.95" },
	{ match = { class = "^(org\\.telegram\\.desktop)$", title = "^(Media viewer)$" }, float = true },
	{ match = { class = "^(imv)$" }, float = true },
	{ match = { class = "^(mpv)$" }, float = true },
	{ match = { class = "^(org\\.gnome\\.Calculator)$" }, float = true },
	{ match = { title = "^(overskride)$" }, float = true },
	{ match = { title = "^(Open Files)$" }, float = true },
	{ match = { class = "^(com\\.github\\.tenderowl\\.frog)$" }, float = true },
	{ match = { class = "^(org\\.pulseaudio\\.pavucontrol)$" }, float = true },
	{ match = { class = "^jetbrains-", float = true }, no_initial_focus = true },
	{ match = { class = "^jetbrains-", float = true, title = "^$" }, stay_focused = true },
}

local function apply_rules(rules, fn)
	for _, rule in ipairs(rules) do
		fn(rule)
	end
end

apply_rules(layer_rules, hl.layer_rule)
apply_rules(window_rules, hl.window_rule)

hl.layer_rule({
	name = "noctalia",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
	},
	no_anim = true,
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})
