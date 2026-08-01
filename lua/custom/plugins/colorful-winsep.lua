-- Colors the border of the focused window, so it's obvious at a glance which
-- split has focus (editor, the built-in terminal, Claude, neo-tree, ...) --
-- something Neovim's own WinSeparator can't do on its own.
-- See: https://github.com/nvim-zh/colorful-winsep.nvim

vim.pack.add { 'https://github.com/nvim-zh/colorful-winsep.nvim' }

require('colorful-winsep').setup {
  -- Derive the border color from the active colorscheme's own accent color
  -- (tokyonight's 'Function' group) instead of the plugin's hardcoded default,
  -- so it stays correct if the colorscheme or its light/dark variant changes.
  highlight = function()
    local accent = vim.api.nvim_get_hl(0, { name = 'Function', link = false }).fg
    vim.api.nvim_set_hl(0, 'ColorfulWinSep', { fg = accent, bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg })
  end,
}
