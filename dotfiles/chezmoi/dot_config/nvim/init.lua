vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

vim.opt.number = true
vim.opt.relativenumber = true

if
	vim.fn.globpath(vim.o.packpath, "pack/*/start/mason.nvim") ~= ""
	and vim.fn.globpath(vim.o.packpath, "pack/*/start/mason-tool-installer.nvim") ~= ""
then
	vim.cmd.packadd("mason.nvim")
	vim.cmd.packadd("mason-tool-installer.nvim")
	require("mason").setup()
	require("mason-tool-installer").setup({
		ensure_installed = { "ruff", "ty", "tsc" },
	})
else
	vim.notify("Neovim plugins are missing. Run chezmoi apply.", vim.log.levels.WARN)
end

vim.lsp.enable({ "nixd", "lua_ls", "ruff", "ty", "tsc" })
