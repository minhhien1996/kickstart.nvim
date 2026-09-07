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
  diff_opts = {
    -- Inline single-buffer diff instead of a side-by-side/stacked split —
    -- avoids squeezed panes on a small laptop screen.
    layout = 'unified',
  },
}

-- [[ Keymaps ]]
vim.keymap.set('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = 'AI: [C]laude toggle' })
vim.keymap.set('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = 'AI: [R]esume Claude' })
vim.keymap.set('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = 'AI: [C]ontinue Claude' })
vim.keymap.set('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', { desc = 'AI: Select [m]odel' })
vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = 'AI: Add current [b]uffer' })
vim.keymap.set('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = 'AI: [A]ccept diff' })
vim.keymap.set('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = 'AI: [D]eny diff' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'AI: [S]end selection to Claude' })

-- <leader>af only works in Normal mode, so it's unreachable while typing in the
-- Claude terminal (terminal-mode keystrokes go straight to the `claude` process).
-- <C-,> is bound in both Normal and Terminal mode as a single toggle that always
-- works: it drops out of terminal-mode first, then hands off to the smart focus
-- toggle, so one keystroke gets you back to the editor from inside the chat.
-- Note: claudecode's native provider calls startinsert itself; windows.nvim is
-- configured to ignore terminal buftype so its deferred feedkeys pass can't
-- override the mode after focus lands.
vim.keymap.set('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = 'AI: [F]ocus Claude' })
vim.keymap.set('n', '<C-,>', '<cmd>ClaudeCodeFocus<cr>', { desc = 'AI: Focus/return from Claude' })
vim.keymap.set('t', '<C-,>', [[<C-\><C-n><Cmd>ClaudeCodeFocus<CR>]], { desc = 'AI: Focus/return from Claude' })

-- Scroll the Claude terminal buffer from terminal mode without needing to exit it.
-- <C-\><C-n> exits terminal mode momentarily, scrolls, then re-enters.
vim.keymap.set('t', '<C-u>', [[<C-\><C-n><C-u>]], { desc = 'Scroll Claude terminal up' })
vim.keymap.set('t', '<C-d>', [[<C-\><C-n><C-d>]], { desc = 'Scroll Claude terminal down' })

-- [[ Distinct panel background, matching neo-tree ]]
-- Give the Claude terminal window the same sidebar-panel background
-- tokyonight already uses for neo-tree ('NeoTreeNormal'/'NeoTreeNormalNC'),
-- so it visually reads as a panel rather than a plain editor split. Read
-- dynamically (rather than hardcoding a color) so it stays correct across
-- colorscheme/light-dark changes; registered as a ColorScheme autocmd since
-- that's when tokyonight (re)defines 'NeoTreeNormal'.
local function set_claudecode_panel_bg()
  local sidebar_bg = vim.api.nvim_get_hl(0, { name = 'NeoTreeNormal', link = false }).bg
  vim.api.nvim_set_hl(0, 'ClaudeCodeNormal', { bg = sidebar_bg })
end
set_claudecode_panel_bg() -- the colorscheme is already loaded by the time this file runs

local claudecode_bg_augroup = vim.api.nvim_create_augroup('claudecode-panel-bg', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = claudecode_bg_augroup,
  callback = set_claudecode_panel_bg,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  desc = 'Apply the panel background to the Claude terminal window',
  group = claudecode_bg_augroup,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    -- Deferred to next tick: claudecode's native provider fires BufWinEnter
    -- (via `:enew`, ahead of `termopen()`) before it finishes assigning its
    -- own tracked bufnr, so get_active_terminal_bufnr() isn't reliable
    -- synchronously here — by the time this runs, open_terminal() has
    -- returned and the state is settled.
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(win) then return end
      local claude_winhighlight = 'Normal:ClaudeCodeNormal,NormalNC:ClaudeCodeNormal'
      local buf = vim.api.nvim_win_get_buf(win)
      if buf == require('claudecode.terminal').get_active_terminal_bufnr() then
        vim.api.nvim_set_option_value('winhighlight', claude_winhighlight, { win = win })
      elseif vim.api.nvim_get_option_value('winhighlight', { win = win }) == claude_winhighlight then
        -- A window's local options (including winhighlight) carry over to a
        -- split made from it, or to a different buffer opened in the same
        -- window later — only clean up after ourselves (not e.g. neo-tree's
        -- own winhighlight, if this ever happened to be its window).
        vim.api.nvim_set_option_value('winhighlight', '', { win = win })
      end
    end)
  end,
})

-- [[ Don't let indent guides punch holes in the diff highlight ]]
-- The unified diff buffer highlights whole added/deleted lines via
-- `line_hl_group` extmarks (see diff_inline.lua), but indent-blankline's own
-- indent-guide virtual text draws over the leading-whitespace columns with
-- its own (unhighlighted) background — visually cutting the green/red out
-- of the indentation. Indent guides aren't meaningful in a diff view anyway,
-- so just disable ibl for that one buffer.
vim.api.nvim_create_autocmd('User', {
  pattern = 'ClaudeCodeDiffOpened',
  group = claudecode_bg_augroup,
  callback = function(ev)
    local diff_window = ev.data and ev.data.diff_window
    if diff_window and vim.api.nvim_win_is_valid(diff_window) then
      local ok, ibl = pcall(require, 'ibl')
      if ok then ibl.setup_buffer(vim.api.nvim_win_get_buf(diff_window), { enabled = false }) end
    end
  end,
})
