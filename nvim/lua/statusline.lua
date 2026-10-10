local hl = vim.api.nvim_set_hl
local none = { bg = "NONE", default = true }

hl(0, "Normal", none)
hl(0, "NormalNC", none)
hl(0, "StatusLine", { fg = "#8b949e", bg = "NONE" })
hl(0, "StatusLineNC", { fg = "#484f58", bg = "NONE" })
hl(0, "TabLine", { fg = "#6e7681", bg = "NONE" })
hl(0, "TabLineFill", none)
hl(0, "TabLineSel", { fg = "#f0f6fc", bg = "NONE", bold = true })
hl(0, "MsgArea", none)
hl(0, "NormalFloat", { bg = "#000000" })
hl(0, "FloatBorder", { fg = "#444c56", bg = "#000000" })
hl(0, "WinSeparator", { fg = "#30363d", bg = "NONE" })
hl(0, "VertSplit", { fg = "#30363d", bg = "NONE" })
hl(0, "EndOfBuffer", { fg = "#21262d", bg = "NONE" })
hl(0, "LineNr", { fg = "#484f58", bg = "NONE" })
hl(0, "CursorLineNr", { fg = "#f0f6fc", bg = "NONE" })
hl(0, "SignColumn", none)
hl(0, "ColorColumn", none)
hl(0, "Visual", { bg = "#1c2f3f" })
hl(0, "CursorLine", { bg = "#0f1014" })
hl(0, "TelescopeNormal", { bg = "#000000" })
hl(0, "TelescopePromptTitle", { fg = "#6e7681", bg = "#000000" })
hl(0, "TelescopeResultsTitle", { fg = "#6e7681", bg = "#000000" })
hl(0, "TelescopePreviewTitle", { fg = "#6e7681", bg = "#000000" })
hl(0, "TelescopePromptBorder", { fg = "#30363d", bg = "#000000" })
hl(0, "TelescopeResultsBorder", { fg = "#30363d", bg = "#000000" })
hl(0, "TelescopePreviewBorder", { fg = "#30363d", bg = "#000000" })
hl(0, "WarningMsg", { fg = "#d29922", bg = "NONE" })
hl(0, "ErrorMsg", { fg = "#f85149", bg = "NONE" })
hl(0, "DiagnosticError", { fg = "#f85149", bg = "NONE" })
hl(0, "DiagnosticWarn", { fg = "#d29922", bg = "NONE" })

local SEV = { ["1"] = "✗", ["2"] = "▲", ["3"] = "»" }

local function statusline()
	local bufnr = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(bufnr)
	name = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
	local mod = vim.bo[bufnr].modified and "+" or ""

	local diag = {}
	for sev, ch in pairs(SEV) do
		local n = #vim.diagnostic.get(bufnr, { severity = tonumber(sev) })
		if n > 0 then
			diag[#diag + 1] = ch .. n
		end
	end

	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	local lsp = clients[1] and clients[1].name or ""

	local pos = math.floor(vim.fn.line(".") / math.max(vim.fn.line("$"), 1) * 100)

	return table.concat({
		" ",
		name,
		mod ~= "" and "." or "",
		#diag > 0 and (" " .. table.concat(diag, " ")) or "",
		"%=",
		lsp ~= "" and (lsp .. " │ ") or "",
		("%d:%d %d%% "):format(vim.fn.line("."), vim.fn.col("."), pos),
	})
end

local function tabline()
	local parts = { " " }
	local cur = vim.api.nvim_get_current_buf()
	for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
		if vim.bo[b.bufnr].buflisted and (vim.api.nvim_buf_is_loaded(b.bufnr) or b.bufnr == cur) then
			local name = b.name ~= "" and vim.fn.fnamemodify(b.name, ":t") or "[No Name]"
			local hlgroup = b.bufnr == cur and "%#TabLineSel#" or "%#TabLine#"
			parts[#parts + 1] = hlgroup .. name .. (vim.bo[b.bufnr].modified and " +" or "")
		end
	end
	return table.concat(parts, "  ") .. "%T%="
end

vim.o.statusline = "%!v:lua.STATUSLINE()"
vim.o.tabline = "%!v:lua.TABLINE()"

function _G.STATUSLINE()
	return statusline()
end

function _G.TABLINE()
	return tabline()
end
