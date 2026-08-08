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

-- Columns above this are treated as "big external monitor" rather than the
-- MacBook Air's built-in screen, so the ad-hoc terminal (<leader>tt) docks
-- to the right instead of the bottom. Comfortably between the two measured
-- `:echo &columns` values: 206 on the MacBook Air, 425 on the 32" 4K.
local WIDE_COLUMNS = 300
local function is_wide() return vim.o.columns >= WIDE_COLUMNS end

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
      -- Only claim the scratch terminal once there's enough width to
      -- spare (see WIDE_COLUMNS above). Re-evaluated on every resize, so
      -- moving the window to/from the big monitor flips it live between
      -- here and `bottom` below without needing to reopen it.
      filter = function(buf) return is_scratch_terminal(buf) and is_wide() end,
    },
  },
  bottom = {
    {
      title = 'Terminal',
      ft = '',
      filter = function(buf) return is_scratch_terminal(buf) and not is_wide() end,
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
    right = { size = 0.30 },
  },
}
