-- Follow the OS light/dark appearance setting (checked as it changes, not
-- just on startup). Cross-platform OS detection + polling is more than a
-- few lines to hand-roll reliably, so use a small dedicated plugin instead.
-- See: https://github.com/f-person/auto-dark-mode.nvim

vim.pack.add { 'https://github.com/f-person/auto-dark-mode.nvim' }

-- 'tokyonight' (unsuffixed) picks day/moon based on 'background' each time
-- it's loaded, so the hooks below must reload the colorscheme, not just
-- flip the option, to actually change styles.
require('auto-dark-mode').setup {
  set_dark_mode = function()
    vim.o.background = 'dark'
    vim.cmd.colorscheme 'tokyonight'
  end,
  set_light_mode = function()
    vim.o.background = 'light'
    vim.cmd.colorscheme 'tokyonight'
  end,
  update_interval = 10000,
}
