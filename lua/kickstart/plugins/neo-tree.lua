-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    filtered_items = {
      visible = true,
      hide_dotfiles = false,
      hide_gitignored = false,
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['<C-v>'] = 'open_vsplit',
        ['<C-x>'] = 'open_split',
        ['s'] = 'none',
        ['S'] = 'none',
        -- 'y' is already neo-tree's own copy-to-(internal)-clipboard command
        -- (for move/paste within the tree), so this yanks the absolute path
        -- of the node under the cursor to the *system* clipboard instead.
        -- Editor-side equivalent: <leader>yp in init.lua's Basic Keymaps.
        ['Y'] = {
          function(state)
            local path = state.tree:get_node():get_id()
            vim.fn.setreg('+', path)
            vim.notify('Copied: ' .. path)
          end,
          desc = 'copy_path_to_clipboard',
        },
      },
    },
  },
}
