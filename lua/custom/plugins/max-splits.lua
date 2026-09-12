-- Enforce a 2×2 cap on the main editing area using LRU eviction, and
-- auto-convert horizontal splits into vertical ones on narrow screens.
--
-- Window focus order is tracked on WinEnter. When a new split would push the
-- main-window count past 4, the least recently used main window is closed to
-- make room — the new split stays open. Edgy-managed windows (neo-tree,
-- Claude, scratch terminal) set winfixwidth and are excluded from both the
-- count and eviction. Floating windows, quickfix, help and terminal buffers
-- are also excluded.
--
-- On a screen narrow enough that stacked horizontal splits get unreadably
-- short (see NARROW_COLUMNS below), a horizontal split among the main
-- windows is immediately closed and reopened as a vertical split instead.
-- This only ever fires in the main editing area — neo-tree/Claude/the
-- scratch terminal already open as vertical splits (or are excluded above)
-- no matter the screen width.

-- Columns below this are treated as a small/laptop screen rather than a big
-- external monitor. Comfortably between the two measured `:echo &columns`
-- values: 206 on the MacBook Air, 425 on the 32" 4K.
local NARROW_COLUMNS = 300
local function is_narrow() return vim.o.columns < NARROW_COLUMNS end

local win_order = {} -- window ids ordered by last focus, oldest first

local function record_focus(win)
  for i, w in ipairs(win_order) do
    if w == win then
      table.remove(win_order, i)
      break
    end
  end
  table.insert(win_order, win) -- most recent at the end
end

local function is_main_win(win)
  if not vim.api.nvim_win_is_valid(win) then return false end
  if vim.api.nvim_win_get_config(win).relative ~= '' then return false end -- float
  if vim.wo[win].winfixwidth then return false end -- edgy sidebar / pinned panel
  local bt = vim.bo[vim.api.nvim_win_get_buf(win)].buftype
  if bt == 'quickfix' or bt == 'nofile' or bt == 'terminal' or bt == 'help' then return false end
  return true
end

vim.api.nvim_create_autocmd('WinEnter', {
  desc = 'Track window focus order for LRU split eviction',
  callback = function() record_focus(vim.api.nvim_get_current_win()) end,
})

vim.api.nvim_create_autocmd('WinNew', {
  desc = 'Cap editor splits at four (2×2) — evict the LRU window',
  callback = function()
    local main_wins = vim.tbl_filter(is_main_win, vim.api.nvim_list_wins())
    if #main_wins <= 4 then return end

    -- Find the oldest main window still in the focus-order list
    local main_set = {}
    for _, w in ipairs(main_wins) do
      main_set[w] = true
    end

    local lru_win
    for _, w in ipairs(win_order) do
      if main_set[w] then
        lru_win = w
        break
      end
    end

    -- Fallback: evict the first main window that is not the newly created one
    if not lru_win then
      local cur = vim.api.nvim_get_current_win()
      for _, w in ipairs(main_wins) do
        if w ~= cur then
          lru_win = w
          break
        end
      end
    end

    if lru_win then pcall(vim.api.nvim_win_close, lru_win, false) end
  end,
})

-- [[ Auto-convert horizontal splits to vertical on narrow screens ]]

---Finds the immediate layout-group kind ('row' side-by-side, 'col' stacked)
---that `win` sits in, per `winlayout()`'s nested tree.
---@param win integer
---@param node table?
---@return 'row'|'col'|nil
local function parent_split_kind(win, node)
  node = node or vim.fn.winlayout()
  local kind, children = node[1], node[2]
  if kind == 'leaf' then return nil end
  for _, child in ipairs(children) do
    if child[1] == 'leaf' and child[2] == win then return kind end
    local found = parent_split_kind(win, child)
    if found then return found end
  end
  return nil
end

-- Guards against the vsplit created below re-triggering this same
-- conversion (it fires its own WinNew).
local converting = false

local function convert_to_vertical(win)
  if converting or not vim.api.nvim_win_is_valid(win) then return end
  local alt_win = vim.fn.win_getid(vim.fn.winnr '#')
  if alt_win == 0 or alt_win == win or not vim.api.nvim_win_is_valid(alt_win) then return end

  local buf = vim.api.nvim_win_get_buf(win)
  local ok_cursor, cursor = pcall(vim.api.nvim_win_get_cursor, win)

  converting = true
  pcall(function()
    vim.api.nvim_win_close(win, false)
    vim.api.nvim_set_current_win(alt_win)
    vim.cmd.vsplit()
    local new_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(new_win, buf)
    if ok_cursor then pcall(vim.api.nvim_win_set_cursor, new_win, cursor) end
  end)
  converting = false
end

vim.api.nvim_create_autocmd('WinNew', {
  desc = 'On a narrow screen, turn a new horizontal split into a vertical one',
  callback = function()
    if converting or not is_narrow() then return end
    local win = vim.api.nvim_get_current_win()
    -- Deferred: right after WinNew, a fresh terminal split (scratch
    -- terminal, `:terminal`) still carries its pre-split buffer/buftype —
    -- `is_main_win` can't yet tell it apart from a real edit split. By the
    -- next tick the buftype (and any edgy winfixwidth) has settled.
    vim.schedule(function()
      if converting or not (vim.api.nvim_win_is_valid(win) and is_main_win(win)) then return end
      local ok, kind = pcall(parent_split_kind, win)
      if ok and kind == 'col' then convert_to_vertical(win) end
    end)
  end,
})
