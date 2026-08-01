-- Claude Code integration
--
-- Connects Neovim to a running `claude` CLI session using the same IDE
-- protocol as the official VS Code/JetBrains extensions: selections,
-- diagnostics, and diffs sync automatically between the editor and the CLI.
-- See: https://github.com/coder/claudecode.nvim

-- [[ Install ]]
vim.pack.add { 'https://github.com/coder/claudecode.nvim' }

-- [[ Setup ]]
require('claudecode').setup {
  terminal = {
    -- Use Neovim's built-in terminal split so this doesn't pull in snacks.nvim.
    provider = 'native',
  },
}

-- [[ Keymaps ]]
vim.keymap.set('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = 'AI: [C]laude toggle' })
vim.keymap.set('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = 'AI: [F]ocus Claude' })
vim.keymap.set('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = 'AI: [R]esume Claude' })
vim.keymap.set('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = 'AI: [C]ontinue Claude' })
vim.keymap.set('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', { desc = 'AI: Select [m]odel' })
vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = 'AI: Add current [b]uffer' })
vim.keymap.set('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = 'AI: [A]ccept diff' })
vim.keymap.set('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = 'AI: [D]eny diff' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'AI: [S]end selection to Claude' })
