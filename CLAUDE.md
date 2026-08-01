# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A fork of [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), a single-file, fully-commented Neovim configuration meant to be read top-to-bottom and extended in place — it is explicitly *not* a distribution. Almost all core config lives in `init.lua`; treat that file as the primary reference before assuming behavior lives elsewhere.

## Commands

- **Format check**: `stylua --check .` (config in `.stylua.toml`: 2-space indent, 160 col width, single quotes preferred, no parens on single-arg calls). CI runs this via `.github/workflows/stylua.yml` on every PR.
- **Format write**: `stylua .`
- **Reload config after edits**: restart Neovim, or `:source $MYVIMRC` for non-plugin changes.
- **Install/sync plugins**: happens automatically on startup via `vim.pack`. To inspect pending updates: `:lua vim.pack.update(nil, { offline = true })`; to fetch and apply updates: `:lua vim.pack.update()` (`:write` applies, `:quit` cancels).
- **Health check**: `:checkhealth` (this repo adds `lua/kickstart/health.lua`, which is invoked as part of the standard health-check flow).
- There is no test suite, build step, or linter beyond Stylua — this is a config repo, not an application.

## Architecture

### `init.lua` is a sequence of isolated `do ... end` blocks

The file is organized as consecutive `do ... end` blocks, each a self-contained section corresponding to one concern (options, keymaps, autocommands, the `vim.pack` intro, plugin installation, colorscheme, `mini.nvim`, the fuzzy finder, LSP, formatting, snippets, autocomplete, Treesitter). Locals declared inside a block (e.g. the `gh()` URL-builder helper at line ~326) are scoped to that block and not available elsewhere — don't assume a helper defined in one section is reachable from another without re-declaring it in plugin files under `lua/`.

Grep `-- \[\[` in `init.lua` to jump between sections.

### Plugin manager is `vim.pack`, not lazy.nvim/packer

Plugins are installed with `vim.pack.add { 'https://github.com/<owner>/<repo>' }` — there is no `lazy.nvim`-style spec table (no `dependencies`, `config`, `keys`, `cmd` fields). Each plugin is added, then configured immediately afterward with a plain `require('plugin').setup { ... }` call. When adding a plugin, follow this same pattern rather than porting a lazy.nvim spec verbatim.

Post-install/update build steps (e.g. `make` for `telescope-fzf-native.nvim`, `TSUpdate` for `nvim-treesitter`) are handled centrally by a single `PackChanged` autocommand (`init.lua` ~line 297), keyed on `ev.data.spec.name` — not per-plugin hooks. If a new plugin needs a build step, add a branch there.

`nvim-pack-lock.json` pins installed plugin revisions and is tracked in this fork (upstream kickstart gitignores it deliberately, per the README, to ease upstream maintenance — this fork has chosen to track it).

### Two extension points, both off by default

At the bottom of `init.lua` (~line 960 block) are commented-out `require` lines for optional pieces:

- `lua/kickstart/plugins/*.lua` — example plugins shipped by kickstart (debug/DAP, indent_line, lint, autopairs, neo-tree, gitsigns-with-keymaps). Each is a standalone file: `vim.pack.add {...}` followed by `setup`/keymaps.
- `lua/custom/plugins/*.lua` — user-added plugins, auto-loaded by `lua/custom/plugins/init.lua` iterating every `.lua` file in that directory (symlinks followed). Enabling this requires uncommenting `require 'custom.plugins'` in `init.lua` — it does nothing silently if left commented out.

New personal plugins belong in `lua/custom/plugins/<name>.lua`, following the `vim.pack.add` + `setup` + `vim.keymap.set` pattern used throughout (see `lua/custom/plugins/claudecode.lua` for a current example, or `lua/kickstart/plugins/gitsigns.lua` for the upstream style).

### LSP config

Language servers are declared per-language in a table inside the `-- [[ LSP Configuration ]]` block and installed via `mason.nvim`/`mason-lspconfig.nvim`; `blink.cmp` supplies completion capabilities merged into each server's config. Keymaps and LSP-attach behavior (document highlight, inlay hints toggle, etc.) are wired through an `LspAttach` autocommand rather than per-server `on_attach` functions.
