-- Faster comment toggle, mapped to Neovim's built-in `gcc`/`gc` commenting
-- (no plugin needed).
--
-- `<leader>cc` instead of the "well-known" `Ctrl+/` chord: iTerm2 doesn't
-- forward a distinct code for Ctrl+/, it just sends a bare `/`, so Neovim
-- can never tell it apart from plain search. `<leader>/` is also taken
-- (Telescope fuzzy-search-in-buffer, see init.lua), so `<leader>cc` it is.

vim.keymap.set('n', '<leader>cc', 'gcc', { remap = true, desc = '[C]omment toggle line' })
vim.keymap.set('v', '<leader>cc', 'gc', { remap = true, desc = '[C]omment toggle selection' })
