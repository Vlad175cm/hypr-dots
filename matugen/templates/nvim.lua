vim.api.nvim_set_hl_name = "matugen"

local P = {
	primary = "{{colors.primary.default.hex}}",
	on_primary = "{{colors.on_primary.default.hex}}",
	primary_container = "{{colors.primary_container.default.hex}}",
	secondary = "{{colors.secondary.default.hex}}",
	on_secondary = "{{colors.on_secondary.default.hex}}",
	secondary_container = "{{colors.secondary_container.default.hex}}",
	tertiary = "{{colors.tertiary.default.hex}}",
	tertiary_container = "{{colors.tertiary_container.default.hex}}",
	on_tertiary_container = "{{colors.on_secondary_container.default.hex}}",
	error = "{{colors.error.default.hex}}",
	surface = "{{colors.surface.default.hex}}",
	surface_container = "{{colors.surface_container.default.hex}}",
	surface_container_high = "{{colors.surface_container_high.default.hex}}",
	surface_variant = "{{colors.surface_variant.default.hex}}",
	on_surface = "{{colors.on_surface.default.hex}}",
	on_surface_variant = "{{colors.on_surface_variant.default.hex}}",
	outline = "{{colors.outline.default.hex}}",
	outline_variant = "{{colors.outline_variant.default.hex}}",
	inverse_surface = "{{colors.inverse_surface.default.hex}}",
	inverse_primary = "{{colors.inverse_primary.default.hex}}",
}

local hl = vim.api.nvim_set_hl
local none = { bg = "NONE" }

hl(0, "Normal", { fg = P.on_surface, bg = "NONE" })
hl(0, "NormalNC", { fg = P.on_surface, bg = "NONE" })
hl(0, "EndOfBuffer", { fg = P.surface_container, bg = "NONE" })

hl(0, "Comment", { fg = P.outline, italic = true })
hl(0, "String", { fg = P.secondary })
hl(0, "Character", { fg = P.secondary })
hl(0, "Number", { fg = P.tertiary })
hl(0, "Boolean", { fg = P.tertiary })
hl(0, "Float", { fg = P.tertiary })
hl(0, "Constant", { fg = P.tertiary })
hl(0, "Identifier", { fg = P.on_surface })
hl(0, "Function", { fg = P.primary })
hl(0, "Statement", { fg = P.primary })
hl(0, "Keyword", { fg = P.primary, bold = true })
hl(0, "Conditional", { fg = P.secondary })
hl(0, "Repeat", { fg = P.secondary })
hl(0, "Label", { fg = P.secondary })
hl(0, "Operator", { fg = P.on_surface_variant })
hl(0, "Exception", { fg = P.error })
hl(0, "PreProc", { fg = P.tertiary })
hl(0, "Include", { fg = P.tertiary })
hl(0, "Define", { fg = P.tertiary })
hl(0, "Macro", { fg = P.tertiary })
hl(0, "Type", { fg = P.tertiary })
hl(0, "StorageClass", { fg = P.secondary })
hl(0, "Structure", { fg = P.secondary })
hl(0, "Special", { fg = P.secondary })
hl(0, "SpecialChar", { fg = P.tertiary })
hl(0, "Delimiter", { fg = P.on_surface_variant })
hl(0, "MatchParen", { bg = P.surface_container_high, fg = P.primary, bold = true })
hl(0, "Todo", { fg = P.primary })
hl(0, "Underlined", { fg = P.primary, underline = true })

hl(0, "StatusLine", { fg = P.on_surface_variant, bg = "NONE" })
hl(0, "StatusLineNC", { fg = P.outline_variant, bg = "NONE" })
hl(0, "TabLine", { fg = P.on_surface_variant, bg = "NONE" })
hl(0, "TabLineFill", { fg = P.on_surface_variant, bg = "NONE" })
hl(0, "TabLineSel", { fg = P.on_surface, bg = "NONE", bold = true })
hl(0, "MsgArea", { fg = P.on_surface, bg = "NONE" })
hl(0, "MoreMsg", { fg = P.primary, bg = "NONE" })
hl(0, "ModeMsg", { fg = P.primary, bg = "NONE" })
hl(0, "WildMenu", { bg = P.surface_container_high, fg = P.on_surface })
hl(0, "LineNr", { fg = P.outline_variant, bg = "NONE" })
hl(0, "CursorLineNr", { fg = P.primary, bg = "NONE", bold = true })
hl(0, "SignColumn", { fg = P.on_surface_variant, bg = "NONE" })
hl(0, "ColorColumn", none)
hl(0, "CursorLine", { bg = P.surface_container })
hl(0, "Visual", { bg = P.surface_container_high })
hl(0, "CursorColumn", none)
hl(0, "WinSeparator", { fg = P.outline_variant, bg = "NONE" })
hl(0, "VertSplit", { fg = P.outline_variant, bg = "NONE" })
hl(0, "Folded", { bg = P.surface_container, fg = P.on_surface_variant })
hl(0, "FoldColumn", { fg = P.outline_variant, bg = "NONE" })

hl(0, "Pmenu", { bg = P.surface_container_high, fg = P.on_surface })
hl(0, "PmenuSel", { bg = P.primary, fg = P.on_primary })
hl(0, "PmenuSbar", { bg = P.surface_container_high })
hl(0, "PmenuThumb", { bg = P.outline_variant })
hl(0, "NormalFloat", { bg = P.surface })
hl(0, "FloatBorder", { fg = P.outline_variant, bg = P.surface })
hl(0, "FloatTitle", { fg = P.primary, bg = P.surface })
hl(0, "TelescopeNormal", { bg = P.surface })
hl(0, "TelescopePromptTitle", { fg = P.primary, bg = P.surface })
hl(0, "TelescopeResultsTitle", { fg = P.secondary, bg = P.surface })
hl(0, "TelescopePreviewTitle", { fg = P.tertiary, bg = P.surface })
hl(0, "TelescopePromptBorder", { fg = P.outline_variant, bg = P.surface })
hl(0, "TelescopeResultsBorder", { fg = P.outline_variant, bg = P.surface })
hl(0, "TelescopePreviewBorder", { fg = P.outline_variant, bg = P.surface })
hl(0, "TelescopeSelection", { bg = P.surface_container_high })
hl(0, "TelescopeMatching", { fg = P.primary })

hl(0, "Search", { bg = P.primary, fg = P.on_primary })
hl(0, "IncSearch", { bg = P.secondary, fg = P.on_secondary })
hl(0, "CurSearch", { bg = P.tertiary, fg = P.on_tertiary_container })
hl(0, "Substitute", { bg = P.tertiary, fg = P.on_tertiary_container })

hl(0, "DiagnosticError", { fg = P.error })
hl(0, "DiagnosticWarn", { fg = P.tertiary })
hl(0, "DiagnosticInfo", { fg = P.primary })
hl(0, "DiagnosticHint", { fg = P.inverse_primary })
hl(0, "DiagnosticUnderlineError", { fg = P.error, undercurl = true })
hl(0, "DiagnosticUnderlineWarn", { fg = P.tertiary, undercurl = true })
hl(0, "DiagnosticUnderlineInfo", { fg = P.primary, undercurl = true })
hl(0, "DiagnosticUnderlineHint", { fg = P.inverse_primary, undercurl = true })
hl(0, "WarningMsg", { fg = P.tertiary, bg = "NONE" })
hl(0, "ErrorMsg", { fg = P.error, bg = "NONE" })

hl(0, "GitSignsAdd", { fg = P.secondary })
hl(0, "GitSignsChange", { fg = P.tertiary })
hl(0, "GitSignsDelete", { fg = P.error })

hl(0, "SplashTitle", { fg = P.primary, bg = "NONE", bold = true })

vim.g.colors_name = "matugen"
