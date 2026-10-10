if vim.fn.argc(-1) == 0 then
	local buf = vim.api.nvim_create_buf(false, true)

	local width, height = vim.o.columns, vim.o.lines
	local pad_y = math.floor((height - 1) / 2)
	local pad_x = math.floor(math.max(width - 6, 6) / 2)
	local art_row = pad_y + 1

	local lines = {}
	for _ = 1, pad_y do
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = string.rep(" ", pad_x) .. "NEOVIM"
	while #lines < height do
		lines[#lines + 1] = ""
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_add_highlight(buf, -1, "SplashTitle", art_row - 1, 0, -1)
	vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_win_set_cursor(0, { art_row, math.max(pad_x + 1, 1) })

	for _, key in ipairs({
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h",
		"j",
		"k",
		"l",
		"m",
		"n",
		"o",
		"p",
		"q",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
		"z",
		"/",
		":",
		"?",
		"i",
	}) do
		vim.keymap.set("n", key, "<cmd>enew<cr>", { buffer = buf, silent = true, desc = "splash: open empty buffer" })
	end
end
