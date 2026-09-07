-- Glow — Markdown preview in a floating window
--
-- Opens a rendered Markdown preview (via the `glow` CLI) in a floating
-- window with :Glow. Works on the current buffer or any .md file.
-- Requires `glow` to be installed: brew install glow

-- [[ Install ]]
vim.pack.add { 'https://github.com/ellisonleao/glow.nvim' }

-- [[ Setup ]]
require('glow').setup {
  -- Use the system glow binary installed by Homebrew.
  glow_path = '/opt/homebrew/bin/glow',
  -- Open in a centred floating window (default).
  style = 'dark',
  width = 120,
  height = 100,
  width_ratio = 0.85,
  height_ratio = 0.85,
  border = 'rounded',
}

-- [[ Keymaps ]]
-- <leader>mp  — preview current markdown file
vim.keymap.set('n', '<leader>mp', '<cmd>Glow<cr>', { desc = '[M]arkdown [P]review (Glow)' })
