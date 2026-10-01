-- markview.nvim — Markdown (and more) renderer inside the buffer
--
-- Renders Markdown, LaTeX, HTML, typst, and YAML front-matter directly in
-- the buffer using extmarks — no external binary required. Replaces glow.nvim.

-- [[ Install ]]
vim.pack.add { 'https://github.com/OXY2DEV/markview.nvim' }

-- [[ Setup ]]
require('markview').setup {}

-- [[ Keymaps ]]
-- <leader>mp  — toggle markview rendering in the current buffer
vim.keymap.set('n', '<leader>mp', '<cmd>Markview toggle<cr>', { desc = '[M]arkdown [P]review (markview)' })
