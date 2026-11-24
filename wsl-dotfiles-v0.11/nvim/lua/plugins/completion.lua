-- ==============================================================================
-- Completion: blink.cmp (LazyVim's default engine) — refined "power user" setup
--
--   Only the differences to LazyVim's defaults live here; lazy.nvim deep-merges them.
--   Reference: https://cmp.saghen.dev/configuration/reference  (v1 — LazyVim pins "*")
--
--   Insert mode                          Command line (:)
--   <CR>    accept (preset "enter")      <Tab>      show / next item
--   <C-y>   select + accept              <S-Tab>    previous item
--   <C-Space> menu / toggle docs         <C-y>      accept      <C-e> cancel
--   <C-e>   close menu                   / and ? search: buffer words, no auto menu
--   <C-n>/<C-p>, <C-j>/<C-k>  next / prev item (<C-k> without menu: signature help)
--   <C-b>/<C-f>  scroll docs             <Tab>/<S-Tab> jump in snippets (LazyVim)
-- ==============================================================================

return {
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- ------------------------------------------------------------------ keys
      keymap = {
        preset = "enter",
        ["<C-y>"] = { "select_and_accept" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "cancel", "fallback" },                -- cancel = close + undo the preview
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "show_signature", "hide_signature", "fallback" }, -- menu: prev · else signature
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },

      -- ------------------------------------------------------------ behaviour
      completion = {
        keyword = { range = "full" },                         -- replace the whole word when accepting mid-word
        trigger = {
          show_on_backspace_in_keyword = true,                -- re-open after correcting a typo
          show_on_insert_on_trigger_character = false,        -- no popup just from entering insert mode after "."
        },
        list = {
          max_items = 100,
          selection = {
            -- don't preselect while a snippet is active: <CR> stays a newline / Tab keeps jumping
            preselect = function() return not require("blink.cmp").snippet_active({ direction = 1 }) end,
            auto_insert = false,                              -- ghost text previews instead of rewriting the line
          },
        },
        accept = {
          auto_brackets = { enabled = true },
        },
        menu = {
          border = "rounded",
          scrollbar = false,
          max_height = 14,
          draw = {
            treesitter = { "lsp" },                           -- highlight labels like real code
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },                              -- LSP / Buffer / Snippets / Path / dadbod …
            },
            components = {
              source_name = {
                width = { max = 12 },
                text = function(ctx) return "[" .. ctx.source_name .. "]" end,
                highlight = "Comment",
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 150,
          update_delay_ms = 50,
          window = { border = "rounded", max_width = 90, max_height = 25 },
        },
        ghost_text = {
          enabled = true,
          show_with_selection = true,
          show_without_selection = false,
        },
      },

      -- signature help while typing arguments (replaces noice's popup, see below)
      signature = {
        enabled = true,
        window = { border = "rounded", show_documentation = false },
      },

      -- ---------------------------------------------------------------- fuzzy
      fuzzy = {
        implementation = "prefer_rust_with_warning",          -- prebuilt Rust matcher: typo-tolerant, frecency
        max_typos = function(keyword) return math.floor(#keyword / 4) end,
        frecency = { enabled = true },                        -- items you pick often rank first
        use_proximity = true,                                 -- words near the cursor rank higher
        sorts = { "exact", "score", "sort_text" },            -- exact matches always on top
      },

      -- -------------------------------------------------------------- sources
      sources = {
        -- default = { "lsp", "path", "snippets", "buffer" } — from LazyVim (+ lazydev for lua, dadbod for sql)
        providers = {
          lsp = {
            fallbacks = {},                                   -- show buffer words next to LSP items (ranked lower)
            score_offset = 5,
            timeout_ms = 1000,
            -- drop the "Text" kind most servers pad their lists with
            transform_items = function(_, items)
              local Text = require("blink.cmp.types").CompletionItemKind.Text
              return vim.tbl_filter(function(item) return item.kind ~= Text end, items)
            end,
          },
          path = {
            score_offset = 3,
            opts = {
              show_hidden_files_by_default = true,            -- dotfiles repo: .github, .gitlab-ci.yml, …
              trailing_slash = true,
              label_trailing_slash = true,
            },
          },
          snippets = {
            score_offset = -1,
            min_keyword_length = 2,
            -- no snippets right after "." / ":" / "(" — that's member/argument completion
            should_show_items = function(ctx) return ctx.trigger.initial_kind ~= "trigger_character" end,
            -- own DevOps snippets in ~/.config/nvim/snippets (+ friendly-snippets)
            opts = { search_paths = { vim.fn.stdpath("config") .. "/snippets" }, friendly_snippets = true },
          },
          buffer = {
            score_offset = -3,
            min_keyword_length = 3,
            max_items = 8,
            opts = {
              -- words from all visible, normal buffers (not only the current one)
              get_bufnrs = function()
                return vim.tbl_filter(function(buf)
                  return vim.bo[buf].buftype == ""
                end, vim.tbl_map(vim.api.nvim_win_get_buf, vim.api.nvim_list_wins()))
              end,
            },
          },
        },
      },

      -- ------------------------------------------------------------- cmdline
      cmdline = {
        enabled = true,
        keymap = {
          preset = "cmdline",
          ["<Tab>"] = { "show_and_insert", "select_next" },
          ["<S-Tab>"] = { "show_and_insert", "select_prev" },
          ["<C-y>"] = { "select_and_accept" },
          ["<C-e>"] = { "cancel" },
          ["<Right>"] = false,                                -- keep arrow keys for moving the cursor
          ["<Left>"] = false,
        },
        sources = function()
          local t = vim.fn.getcmdtype()
          if t == "/" or t == "?" then return { "buffer" } end
          if t == ":" or t == "@" then return { "cmdline", "path", "buffer" } end
          return {}
        end,
        completion = {
          list = { selection = { preselect = false, auto_insert = true } },
          -- menu pops up by itself for : commands, not while searching
          menu = { auto_show = function() return vim.fn.getcmdtype() == ":" end },
          ghost_text = { enabled = true },
        },
      },

      appearance = { nerd_font_variant = "mono" },
    },
  },

  -- one signature popup, not two: blink draws it, noice stays out
  {
    "folke/noice.nvim",
    optional = true,
    opts = { lsp = { signature = { enabled = false } } },
  },
}
