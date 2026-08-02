-- Add indentation guides even on blank lines

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
vim.pack.add { 'https://github.com/lukas-reineke/indent-blankline.nvim' }

-- Color the scope guide with the colorscheme's own accent color (same
-- source tokyonight 'Function' color used for the focused-window border
-- in colorful-winsep.lua), so it stays correct across colorscheme/light-dark
-- changes. Registered as a hook (rather than set once) since ibl re-runs it
-- on every colorscheme change.
local hooks = require 'ibl.hooks'
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
  local accent = vim.api.nvim_get_hl(0, { name = 'Function', link = false }).fg
  vim.api.nvim_set_hl(0, 'IblScope', { fg = accent })
end)

require('ibl').setup {
  -- Blank (not empty!) guide for every indent level: a zero-width char
  -- disables ibl's scope-substitution logic entirely (see virt_text.lua),
  -- so the current-block guide below would never render. A space has
  -- width 1 (keeping substitution working) but is visually invisible.
  indent = { char = ' ' },
  -- Show a thin vertical guide only for the current block (scope), with
  -- no underline on the block's start/end lines.
  scope = { char = '▏', show_start = false, show_end = false },
}