local f = io.open("/etc/hostname", "r")
local hostname = f and f:read("*l") or ""

local REFRESH_RATE_60 = "60.0"
local REFRESH_RATE_144 = "144.0"
local RESOLUTION_2K = "2560x1440"

if f then
	f:close()
end

-- Hardware specs keyed by monitor description ("make model serial").
-- Find values with: hyprctl monitors -j | jq '.[].description'
local monitor_specs = {
	-- Office: HP E27q G4 (60 Hz)
	["HP Inc. HP E27q G4 CNK1281ZDF"] = { mode = RESOLUTION_2K .. "@" .. REFRESH_RATE_60, scale = 1.0, transform = 1 },
	["HP Inc. HP E27q G4 CNK1281ZF1"] = { mode = RESOLUTION_2K .. "@" .. REFRESH_RATE_60, scale = 1.0 },
	-- Home: Dell G2724D (left) + AOC Q27G2SG4 (right)
	["Dell Inc. DELL G2724D GXJB4V3"] = { mode = RESOLUTION_2K .. "@" .. REFRESH_RATE_144, scale = 1.0, transform = 1 },
	["AOC Q27G2SG4 XFXPAHA011559"] = { mode = RESOLUTION_2K .. "@" .. REFRESH_RATE_144, scale = 1.0 },
}

-- Built-in panel config per hostname.
-- y_offset centers eDP vertically against a 1440px-tall adjacent horizontal monitor.
local edp_specs = {
	["ccretu-nixos"] = { mode = "3840x2400@60.0", scale = 2.0, y_offset = 120 },
	nixos = { mode = "1920x1080@144.0", scale = 1.0, y_offset = 180 },
}

-- Profiles: sets of external monitors that define a physical setup.
-- edp_x is the total logical width of all external monitors (eDP is placed right of them).
local profiles = {
	office = {
		edp_x = 4000,
		monitors = {
			{ desc = "HP Inc. HP E27q G4 CNK1281ZDF", position = "0x0", workspaces = { 4, 5 } },
			{ desc = "HP Inc. HP E27q G4 CNK1281ZF1", position = "1440x0", workspaces = { 1, 2, 3 } },
		},
	},
	home = {
		edp_x = 4000,
		monitors = {
			{ desc = "Dell Inc. DELL G2724D GXJB4V3", position = "0x0", workspaces = { 4, 5 } },
			{ desc = "AOC Q27G2SG4 XFXPAHA011559", position = "1440x0", workspaces = { 1, 2, 3 } },
		},
	},
}

local EDP_OUTPUT = "eDP-1"
local EDP_WORKSPACE = 10
local HDMI_MIRROR_OUTPUT = "HDMI-A-1"
local HDMI_MIRROR_MODE = "1920x1080@" .. REFRESH_RATE_60

local edp_config = nil

local LID_STATE_PATHS = {
	"/proc/acpi/button/lid/LID0/state",
	"/proc/acpi/button/lid/LID1/state",
	"/proc/acpi/button/lid/LID2/state",
}

local function lid_is_closed()
	for _, path in ipairs(LID_STATE_PATHS) do
		local fh = io.open(path, "r")
		if fh then
			local line = fh:read("*l") or ""
			fh:close()
			return line:find("closed") ~= nil
		end
	end
	return false
end

local function build_edp_config(x)
	local spec = edp_specs[hostname]
	if not spec then
		return nil
	end
	return {
		output = EDP_OUTPUT,
		mode = spec.mode,
		scale = spec.scale,
		position = x .. "x" .. spec.y_offset,
		disabled = false,
	}
end

local function detect_active_profile()
	local connected = {}
	for _, mon in ipairs(hl.get_monitors()) do
		connected[mon.description] = true
	end
	for name, profile in pairs(profiles) do
		local all_present = true
		for _, slot in ipairs(profile.monitors) do
			if not connected[slot.desc] then
				all_present = false
				break
			end
		end
		if all_present then
			return name, profile
		end
	end
	return nil, nil
end

local function apply_profile()
	local _, profile = detect_active_profile()

	if profile then
		for _, slot in ipairs(profile.monitors) do
			local spec = monitor_specs[slot.desc]
			if spec then
				local cfg = {}
				for k, v in pairs(spec) do
					cfg[k] = v
				end
				cfg.output = "desc:" .. slot.desc
				cfg.position = slot.position
				hl.monitor(cfg)
			end
			if slot.workspaces then
				for i, ws in ipairs(slot.workspaces) do
					hl.workspace_rule({ workspace = tostring(ws), monitor = "desc:" .. slot.desc, default = (i == 1) })
				end
			end
		end
	end

	-- Always configure eDP. Falls back to x=0 (standalone) when no profile matches.
	local edp_x = (profile and profile.edp_x) or 0
	edp_config = build_edp_config(edp_x)
	if edp_config then
		hl.workspace_rule({ workspace = tostring(EDP_WORKSPACE), monitor = EDP_OUTPUT, default = true })
		hl.monitor(edp_config)
	end
end

local function sync_edp()
	if not edp_config then
		return
	end
	local has_external = false
	for _, mon in ipairs(hl.get_monitors()) do
		if mon.name ~= EDP_OUTPUT then
			has_external = true
			break
		end
	end
	if lid_is_closed() and has_external then
		hl.monitor({ output = EDP_OUTPUT, disabled = true })
	else
		hl.monitor(edp_config)
	end
end

local function apply_unknown_mirror()
	if not edp_config then
		return
	end
	for _, mon in ipairs(hl.get_monitors()) do
		if mon.name == HDMI_MIRROR_OUTPUT and not monitor_specs[mon.description] then
			hl.monitor({
				output = HDMI_MIRROR_OUTPUT,
				mode = HDMI_MIRROR_MODE,
				position = edp_config.position,
				mirror = EDP_OUTPUT,
			})
			return
		end
	end
end

apply_profile()
sync_edp()
apply_unknown_mirror()

hl.bind("switch:on:Lid Switch", sync_edp, { locked = true })
hl.bind("switch:off:Lid Switch", sync_edp, { locked = true })

hl.on("monitor.added", function()
	apply_profile()
	sync_edp()
	apply_unknown_mirror()
end)
hl.on("monitor.removed", function()
	apply_profile()
	sync_edp()
end)
