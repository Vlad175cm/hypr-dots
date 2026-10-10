local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "no"
opt.showcmd = false
opt.showmode = false
opt.laststatus = 2
opt.showtabline = 2
opt.ruler = false
opt.cmdheight = 1
opt.wrap = false
opt.linebreak = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.breakindent = true
opt.undofile = true
opt.updatetime = 200
opt.timeoutlen = 300
opt.ttimeoutlen = 0
opt.mouse = "a"
opt.hlsearch = true
opt.incsearch = true
opt.cursorline = true
opt.termguicolors = true
opt.hidden = true
opt.splitbelow = true
opt.splitright = true
opt.confirm = true
opt.clipboard = "unnamedplus"
opt.iskeyword:append("-")
opt.shortmess:append({ W = true, I = true, c = true, s = true })
opt.fillchars:append({
	eob = " ",
	fold = " ",
	foldopen = "▾",
	foldsep = " ",
	diff = "╱",
})

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd.colorscheme("default")

local group = vim.api.nvim_create_augroup("minimal", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.hl.on_yank({ timeout = 120 })
	end,
})
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = group,
	callback = function(e)
		if e.file:match("%.$") then
			return
		end
		local dir = vim.fn.fnamemodify(e.file, ":p:h")
		if not (vim.uv.fs_stat(dir) or vim.uv.fs_stat(vim.fn.fnamemodify(e.file, ":p:h"))) then
			vim.fn.mkdir(dir, "p")
		end
	end,
})
vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(args)
		vim.lsp.completion.enable(args.buf, args.data.client_id, true)
	end,
})
