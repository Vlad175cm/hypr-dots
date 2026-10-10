local art = table.concat({
	"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
	"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
	"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
	"██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
	"██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
	"╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
}, "\n")

local buf = vim.api.nvim_create_buf(false, true)

if vim.fn.argc(-1) == 0 and vim.fn.line2byte("$") == -1 then
	local width = vim.o.columns
	local height = vim.o.lines
	local art_lines = vim.split(art, "\n")
	local padding_x = math.floor((width - #art_lines[1]) / 2)
	local padding_y = math.floor((height - #art_lines) / 2)

	local lines = {}
	for _ = 1, padding_y do
		lines[#lines + 1] = ""
	end
	for _, line in ipairs(art_lines) do
		lines[#lines + 1] = string.rep(" ", padding_x) .. line
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_keymap(buf, "n", "i", "<cmd>enew<cr>", { desc = "splash: replace with empty buffer", silent = true })
	for _, key in ipairs({ "a", "b", "c", "d", "e", "f", "g", "h", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "/", ":", "?" }) do
		vim.api.nvim_buf_set_keymap(buf, "n", key, "<cmd>enew<cr>", { silent = true })
	end
	vim.api.nvim_win_set_buf(0, buf)

	local hlg = vim.api.nvim_create_augroup("splash", { clear = true })
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = hlg,
		callback = function()
			vim.api.nvim_win_set_buf(0, buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "CmdlineEnter", "ModeChanged" }, {
		group = hlg,
		buffer = buf,
		callback = function()
			pcall(vim.cmd, "enew")
		end,
	})
end
