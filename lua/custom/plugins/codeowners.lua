-- Shows CODEOWNERS for the current buffer in mini.statusline.
-- Pattern matching follows gitignore semantics (last match wins),
-- based on https://github.com/jasonnutter/vscode-codeowners

local _git_root_cache = {} -- dir → root path, or false if not a repo
local _co_cache = {}       -- codeowners path → { mtime, entries }
local _owners_cache = {}   -- bufnr → owners string, or false if none/no CODEOWNERS

local function glob_to_lua(glob)
  local s = glob:gsub('([%.%+%-%^%$%(%)%[%]%%])', '%%%1')
  -- Handle ** and * in one pass: 2+ asterisks → .*, single → [^/]*
  s = s:gsub('%*+', function(m) return #m >= 2 and '.*' or '[^/]*' end)
  s = s:gsub('%?', '[^/]')
  return s
end

local function path_matches(rel_path, glob)
  local anchored = glob:sub(1, 1) == '/'
  local g = (anchored and glob:sub(2) or glob):gsub('/$', '')
  local pat = glob_to_lua(g)
  if anchored then
    return rel_path:match('^' .. pat .. '$') ~= nil or rel_path:match('^' .. pat .. '/') ~= nil
  end
  return rel_path:match('^' .. pat .. '$') ~= nil
    or rel_path:match('^' .. pat .. '/') ~= nil
    or rel_path:match('/' .. pat .. '$') ~= nil
    or rel_path:match('/' .. pat .. '/') ~= nil
end

local function get_git_root(dir)
  if _git_root_cache[dir] ~= nil then
    return _git_root_cache[dir] or nil
  end
  local out = vim.fn.system('git -C ' .. vim.fn.shellescape(dir) .. ' rev-parse --show-toplevel 2>/dev/null')
  local root = vim.v.shell_error == 0 and vim.trim(out) or false
  _git_root_cache[dir] = root
  return root or nil
end

local function find_codeowners(git_root)
  for _, rel in ipairs { '.github/CODEOWNERS', '.gitlab/CODEOWNERS', 'docs/CODEOWNERS', 'CODEOWNERS' } do
    local p = git_root .. '/' .. rel
    if vim.fn.filereadable(p) == 1 then return p end
  end
end

local function parse_codeowners(co_path)
  local entries = {}
  for line in io.lines(co_path) do
    if line ~= '' and not line:match('^%s*#') then
      local parts = vim.split(line, '%s+', { trimempty = true })
      if #parts >= 1 then
        local owners = {}
        for i = 2, #parts do
          table.insert(owners, parts[i])
        end
        table.insert(entries, { pattern = parts[1], owners = owners })
      end
    end
  end
  return entries
end

local function lookup_owners(filepath)
  local dir = vim.fn.fnamemodify(filepath, ':h')
  local git_root = get_git_root(dir)
  if not git_root then return nil end

  local co_path = find_codeowners(git_root)
  if not co_path then return nil end

  local mtime = vim.fn.getftime(co_path)
  local cached = _co_cache[co_path]
  if not cached or cached.mtime ~= mtime then
    _co_cache[co_path] = { mtime = mtime, entries = parse_codeowners(co_path) }
  end

  local rel_path = filepath:sub(#git_root + 2)
  local entries = _co_cache[co_path].entries

  for i = #entries, 1, -1 do
    local e = entries[i]
    if path_matches(rel_path, e.pattern) then
      return #e.owners > 0 and table.concat(e.owners, ' ') or nil
    end
  end
end

-- Populate owners cache from BufEnter/BufWritePost — never from the statusline
-- itself, which can be called in fast/restricted contexts (e.g. tree-sitter).
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
  callback = function(ev)
    local path = vim.api.nvim_buf_get_name(ev.buf)
    _owners_cache[ev.buf] = path ~= '' and lookup_owners(path) or false
  end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    local ok, mini_sl = pcall(require, 'mini.statusline')
    if not ok then return end

    ---@diagnostic disable-next-line: duplicate-set-field
    mini_sl.active = function()
      local mode, mode_hl = mini_sl.section_mode { trunc_width = 120 }
      local git = mini_sl.section_git { trunc_width = 40 }
      local diff = mini_sl.section_diff { trunc_width = 75 }
      local diagnostics = mini_sl.section_diagnostics { trunc_width = 75 }
      local lsp = mini_sl.section_lsp { trunc_width = 75 }
      local filename = mini_sl.section_filename { trunc_width = 140 }
      local fileinfo = mini_sl.section_fileinfo { trunc_width = 120 }
      local location = mini_sl.section_location { trunc_width = 75 }
      local search = mini_sl.section_searchcount and mini_sl.section_searchcount { trunc_width = 75 } or ''

      local bufnr = vim.api.nvim_get_current_buf()
      local owners = _owners_cache[bufnr] or ''

      return mini_sl.combine_groups {
        { hl = mode_hl, strings = { mode } },
        { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
        '%<',
        { hl = 'MiniStatuslineFilename', strings = { filename } },
        '%=',
        { hl = 'MiniStatuslineDevinfo', strings = { owners } },
        { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
        { hl = 'MiniStatuslineModeNormal', strings = { search, location } },
      }
    end
    vim.cmd.redrawstatus { bang = true }
  end,
})
