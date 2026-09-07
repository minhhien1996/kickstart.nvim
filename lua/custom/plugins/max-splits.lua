-- Enforce a 2×2 cap on the main editing area using LRU eviction.
--
-- Window focus order is tracked on WinEnter. When a new split would push the
-- main-window count past 4, the least recently used main window is closed to
-- make room — the new split stays open. Edgy-managed windows (neo-tree,
-- Claude, scratch terminal) set winfixwidth and are excluded from both the
-- count and eviction. Floating windows and quickfix are also excluded.

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
  if bt == 'quickfix' or bt == 'nofile' then return false end
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
