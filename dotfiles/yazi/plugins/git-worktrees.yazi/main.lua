local M = {}

local currentDirectory = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local function notify(content, level)
	ya.notify({ title = "Git worktrees", content = content, level = level, timeout = 5 })
end

local function listWorktrees(directory)
	local output = Command("git")
		:arg({ "worktree", "list", "--porcelain" })
		:cwd(directory)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output or not output.status.success then
		return nil
	end

	local paths = {}
	for line in output.stdout:gmatch("[^\r\n]+") do
		local path = line:match("^worktree (.+)$")
		if path then
			paths[#paths + 1] = path
		end
	end
	return paths
end

local function pickWorktree(directory, paths)
	local child = Command("fzf")
		:arg({ "--prompt", "worktree> ", "--no-multi" })
		:cwd(directory)
		:stdin(Command.PIPED)
		:stdout(Command.PIPED)
		:spawn()

	if not child then
		return nil
	end

	for _, path in ipairs(paths) do
		child:write_all(path .. "\n")
	end
	child:flush()

	local output = child:wait_with_output()
	if not output or not output.status.success then
		return nil
	end
	return output.stdout:match("^%s*(.-)%s*$")
end

function M:entry()
	local directory = currentDirectory()

	local paths = listWorktrees(directory)
	if not paths then
		return notify("Not inside a git repository", "error")
	elseif #paths < 2 then
		return notify("This repository has no other worktree", "warn")
	end

	local permit = ui.hide()
	local path = pickWorktree(directory, paths)
	permit:drop()

	if path and path ~= "" then
		ya.emit("cd", { Url(path), raw = true })
	end
end

return M
