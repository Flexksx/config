--- Noctalia shell IPC binds.
--- v4 (noctalia-shell) and v5 (noctalia) are separate binaries with separate
--- IPC sockets, so each bind fires both calls: the running shell handles it and
--- the inactive one fails fast and is silenced.
local mod = "SUPER"

local function ipc(v4, v5)
	local parts = {}
	if v4 then
		parts[#parts + 1] = "noctalia-shell ipc call " .. v4 .. " 2>/dev/null"
	end
	if v5 then
		parts[#parts + 1] = "noctalia msg " .. v5 .. " 2>/dev/null"
	end
	return table.concat(parts, "; ")
end

local function bind_mod_exec(key, cmd)
	hl.bind(mod .. " + " .. key, hl.dsp.exec_cmd(cmd))
end

local noctalia_binds = {
	{
		"SPACE",
		"qs -p "
			.. os.getenv("HOME")
			.. "/config/dotfiles/quickshell ipc call launcher toggle || qs -d -p "
			.. os.getenv("HOME")
			.. "/config/dotfiles/quickshell",
	},
	{ "I", ipc("sessionMenu toggle", "panel-toggle session") },
	{ "M", ipc("lockScreen lock", "session lock") },
	{ "Y", "walker -m clipboard" },
	{ "grave", ipc("plugin:workspace-overview toggle", nil) },
}
for _, bind in ipairs(noctalia_binds) do
	bind_mod_exec(bind[1], bind[2])
end
