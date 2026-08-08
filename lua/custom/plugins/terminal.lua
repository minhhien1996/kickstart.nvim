-- A single reusable terminal split for running ad-hoc shell commands
-- alongside the editor. Built on Neovim's own `:terminal` — no plugin needed.
--
-- Exit terminal-mode with `<Esc><Esc>` (see Basic Keymaps in init.lua),
-- then resize with Neovim's built-in window commands: <C-w>+/-/</>/=/_/|

local term_win, term_buf

local function toggle_terminal()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
    return
  end

  vim.cmd.split()
  term_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(term_win, math.floor(vim.o.lines * 0.3))

  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.api.nvim_win_set_buf(term_win, term_buf)
  else
    vim.cmd.terminal()
    term_buf = vim.api.nvim_get_current_buf()
    -- Tag so lua/custom/plugins/edgy.lua can single this buffer out from
    -- other terminal-buftype buffers (e.g. claudecode's) and decide which
    -- screen edge to pin it to.
    vim.b[term_buf].is_scratch_terminal = true
  end

  vim.cmd.startinsert()
end

vim.keymap.set('n', '<leader>tt', toggle_terminal, { desc = '[T]oggle [t]erminal' })
