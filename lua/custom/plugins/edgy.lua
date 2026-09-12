-- Edge-pinned layout for the two sidebar panels (neo-tree, Claude Code)
--
-- Without this, neo-tree and the Claude terminal are just ordinary splits:
-- <C-w>= resizes them along with editing windows, and a stray :vsplit/help/
-- quickfix window can land inside their column instead of the center. Edgy
-- tracks windows matching the rules below, pins them to their edge at a
-- fixed size, excludes them from window-equalization, and keeps ordinary
-- splits confined to the main (center) area.
-- https://github.com/folke/edgy.nvim

vim.pack.add { 'https://github.com/folke/edgy.nvim' }

local function is_scratch_terminal(buf) return vim.b[buf].is_scratch_terminal == true end

require('edgy').setup {
  left = {
    { title = 'Explorer', ft = 'neo-tree' },
  },
  right = {
    {
      title = 'Claude',
      -- claudecode's native terminal buffer never gets a filetype set
      -- (termopen leaves it empty), same as the ad-hoc terminal from
      -- lua/custom/plugins/terminal.lua — edgy groups windows by
      -- filetype first, so both land in the ft='' bucket. `filter` then
      -- picks out only the claudecode one.
      ft = '',
      filter = function(buf) return buf == require('claudecode.terminal').get_active_terminal_bufnr() end,
    },
    {
      title = 'Terminal',
      ft = '',
      -- Always dock the scratch terminal (<leader>tt) to the right, below
      -- Claude — it's listed second in this edgebar, and edgy stacks
      -- same-edge views top-to-bottom in list order.
      filter = is_scratch_terminal,
    },
  },
  -- Edgebar widths as fractions of `columns` rather than fixed column
  -- counts, so the panels keep the same proportions whether nvim is on a
  -- cramped MacBook Air screen or a wide 32" 4K monitor — a fixed-column
  -- width (neo-tree's own default) would look cramped on one and tiny on
  -- the other. Moving the terminal itself between displays sends nvim a
  -- resize event either way, so no extra config is needed to react to
  -- it — this just keeps the resulting layout sane at both sizes.
  options = {
    left = { size = 0.20 },
    right = { size = 0.40 },
  },
}
