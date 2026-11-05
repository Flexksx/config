local M = {}

function M.create(opts)
	local apps = opts.apps
	local ws_name = opts.special_ws or apps[1].class:lower()
	local special = "special:" .. ws_name
	local timeout = opts.unfocus_timeout or 1000
	local do_timer = opts.enable_timer ~= false
	local mode = opts.show_mode or "window"
	local should_float = opts.float ~= false
	local before_show = opts.before_show

	for _, app in ipairs(apps) do
		if should_float then
			hl.window_rule({ match = { initial_class = "^" .. app.class .. "$" }, float = true })
		end
		hl.window_rule({ match = { initial_class = "^" .. app.class .. "$" }, workspace = special .. " silent" })
	end

	local hide_timer = nil
	local launching = false
	local silent_launches = 0

	local function matches(w)
		for _, app in ipairs(apps) do
			if w.class == app.class or w.initial_class == app.class then
				return true
			end
		end
		return false
	end

	local function get_win()
		for _, w in ipairs(hl.get_windows()) do
			if matches(w) then
				return hl.get_window("address:" .. w.address)
			end
		end
		return nil
	end

	local function addr(win)
		return "address:" .. win.address
	end

	local function cancel()
		if hide_timer then
			hide_timer:set_enabled(false)
			hide_timer = nil
		end
	end

	local function is_hidden(win)
		if mode == "workspace" then
			return not (win.workspace and win.workspace.visible)
		end
		return win.workspace ~= nil and win.workspace.special == true
	end

	local function show(win)
		if mode == "workspace" then
			if is_hidden(win) then
				if before_show then
					before_show()
				end
				hl.dispatch(hl.dsp.workspace.toggle_special(ws_name))
			end
		else
			local ws = hl.get_active_workspace()
			if not ws then
				return
			end
			hl.dispatch(hl.dsp.window.move({ workspace = ws.id, window = addr(win), follow = false }))
			hl.dispatch(hl.dsp.focus({ window = addr(win) }))
			hl.dispatch(hl.dsp.window.center({ window = addr(win) }))
		end
	end

	local function hide(win)
		if mode == "workspace" then
			if not is_hidden(win) then
				local mon = win.workspace and win.workspace.monitor
				if mon then
					hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
				end
				hl.dispatch(hl.dsp.workspace.toggle_special(ws_name))
			end
		else
			hl.dispatch(hl.dsp.window.move({ workspace = special, window = addr(win), follow = false }))
		end
	end

	local function start_hide_timer()
		cancel()
		hide_timer = hl.timer(function()
			local w = get_win()
			if w and not is_hidden(w) then
				hide(w)
			end
			hide_timer = nil
		end, { timeout = timeout, type = "oneshot" })
	end

	hl.on("window.active", function(active, _)
		if active and matches(active) then
			cancel()
		elseif do_timer then
			local win = get_win()
			if win and not is_hidden(win) then
				start_hide_timer()
			end
		end
	end)

	if mode == "workspace" then
		hl.on("workspace.active", function(_, _)
			local win = get_win()
			if win and not is_hidden(win) then
				cancel()
				hide(win)
			end
		end)

		hl.on("monitor.focused", function(mon, _)
			local win = get_win()
			if not win or is_hidden(win) then
				return
			end
			local win_mon = win.workspace and win.workspace.monitor
			if win_mon and win_mon.name ~= mon.name then
				cancel()
				hide(win)
				hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
			end
		end)
	end

	if opts.close_on_escape_key then
		hl.bind("Escape", function()
			local win = get_win()
			if win and not is_hidden(win) then
				cancel()
				hide(win)
			end
		end, { non_consuming = true })
	end

	if opts.launch_at_startup then
		hl.on("hyprland.start", function()
			for _, app in ipairs(apps) do
				silent_launches = silent_launches + 1
				hl.exec_cmd(app.command, { workspace = special .. " silent" })
			end
		end)
	end

	hl.on("window.open", function(win)
		if not matches(win) then
			return
		end
		if silent_launches > 0 then
			silent_launches = silent_launches - 1
			return
		end
		launching = false
		local w = hl.get_window("address:" .. win.address)
		if w then
			show(w)
		end
	end)

	local function toggle()
		local win = get_win()
		if not win then
			if not launching then
				launching = true
				silent_launches = 0
				for _, app in ipairs(apps) do
					hl.exec_cmd(app.command)
				end
			end
			return
		end
		cancel()
		if is_hidden(win) then
			show(win)
		else
			hide(win)
		end
	end

	scratchpads = scratchpads or {}
	scratchpads[ws_name] = toggle
	hl.bind(opts.key_bind, toggle)
end

return M
