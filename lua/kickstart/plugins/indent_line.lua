-- Add indentation guides even on blank lines

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
vim.pack.add { 'https://github.com/lukas-reineke/indent-blankline.nvim' }
require('ibl').setup {
  -- Blank (not empty!) guide for every indent level: a zero-width char
  -- disables ibl's scope-substitution logic entirely (see virt_text.lua),
  -- so the current-block guide below would never render. A space has
  -- width 1 (keeping substitution working) but is visually invisible.
  indent = { char = ' ' },
  -- ...and show a thin guide only for the current block (scope).
  scope = { char = '▏' },
}