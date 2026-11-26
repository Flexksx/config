vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

vim.opt.number = true
vim.opt.relativenumber = true

local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazy_path) then
	vim.notify("lazy.nvim is missing. Run chezmoi apply.", vim.log.levels.ERROR)
	return
end
vim.opt.rtp:prepend(lazy_path)

require("lazy").setup({
	{ "neovim/nvim-lspconfig", lazy = false },
	{
		"nvim-tree/nvim-tree.lua",
		cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFindFile" },
		keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" } },
		opts = {},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		lazy = false,
		dependencies = { { "mason-org/mason.nvim", opts = {} } },
		opts = { ensure_installed = { "ruff", "ty", "tsc", "tree-sitter-cli" } },
	},
	{ "nvim-treesitter/nvim-treesitter", lazy = false, build = ":TSUpdate" },
}, { lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json" })

vim.lsp.enable({ "nixd", "lua_ls", "ruff", "ty", "tsc" })

do
	require("nvim-treesitter").setup()
	local installing = false
	local function install_python_parser()
		if not installing and vim.fn.executable("tree-sitter") == 1 then
			installing = true
			require("nvim-treesitter").install({ "python" }):await(function(err, success)
				installing = false
				if err then
					vim.notify("Python parser installation failed: " .. tostring(err), vim.log.levels.ERROR)
				end
				if success then
					for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].filetype == "python" then
							vim.treesitter.start(buffer, "python")
						end
					end
				end
			end)
		end
	end
	vim.api.nvim_create_autocmd("User", { pattern = "MasonToolsUpdateCompleted", callback = install_python_parser })
	install_python_parser()
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client.name == "ty" then
			vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function(event)
		if pcall(vim.treesitter.language.add, "python") then
			vim.treesitter.start(event.buf, "python")
		end
		vim.keymap.set("n", "<leader>f", function()
			vim.lsp.buf.format({ bufnr = event.buf, name = "ruff" })
		end, { buffer = event.buf, desc = "Format with Ruff" })
	end,
})
