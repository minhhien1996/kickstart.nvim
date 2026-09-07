-- GitHub permalink generator
--
-- Builds a permanent URL (pinned to the current commit SHA) for the current
-- line or visual selection — the same thing GitHub's web UI gives you when
-- you press 'y' on a file. Works with SSH and HTTPS remotes and several hosts
-- (GitHub, GitLab, Bitbucket, Gitea, …).
-- See: https://github.com/linrongbin16/gitlinker.nvim

-- [[ Install ]]
vim.pack.add { 'https://github.com/linrongbin16/gitlinker.nvim' }

-- [[ Setup ]]
require('gitlinker').setup {
  -- Yank to clipboard only; don't auto-open the browser.
  -- Use <leader>gY (capital Y) to open in browser as well.
  highlight_duration = 500,
}

-- [[ Keymaps ]]
-- <leader>gy  — copy permalink to clipboard (normal: current line; visual: selected range)
-- <leader>gY  — copy permalink AND open it in the browser
vim.keymap.set({ 'n', 'v' }, '<leader>gy', '<cmd>GitLink<cr>', { desc = 'Git: copy permalink to clipboard' })
vim.keymap.set({ 'n', 'v' }, '<leader>gY', '<cmd>GitLink!<cr>', { desc = 'Git: copy permalink and open in browser' })
