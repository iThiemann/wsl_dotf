-- ==============================================================================
-- Completion: blink.cmp — power-user setup for nvim in WSL behind Windows Terminal
--
--   Only differences to LazyVim's defaults live here; lazy.nvim deep-merges them.
--   Reference: https://cmp.saghen.dev/configuration/reference  (v1, LazyVim pins "*")
--
--   Every key below reaches nvim through Windows Terminal + tmux + the AutoHotkey script:
--   no Ctrl+Shift+… (Windows Terminal copy/paste/tabs), no Alt+Shift+… (our WT pane keys),
--   no Alt+Space (tmux which-key), no Ctrl+S (LazyVim save), no Win/Hyper keys.
--
--   Insert mode                                  Command line (:  /  ?)
--   Enter        accept                          Tab / S-Tab   open menu, next / prev
--   Ctrl-y       select first + accept           Ctrl-y        accept
--   Ctrl-Space   menu · toggle docs              Ctrl-e        cancel
--   Ctrl-e       close menu, undo preview        ←/→           move the cursor (not the menu)
--   Ctrl-n/p, Ctrl-j/k   next / prev item
--   Ctrl-k (no menu)     signature help on/off
--   Ctrl-b / Ctrl-f      scroll docs
--   Tab / S-Tab  next / prev item, else jump in snippet, else Tab
--   Esc / CapsLock tap   close menu + normal mode
-- ==============================================================================

local MAX_BUFFER_LINES = 20000 -- buffer words: skip huge files (logs, generated manifests)

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
        -- Windows Terminal sends NUL for Ctrl+Space; nvim reads it as <C-Space> (some setups: <C-@>)
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-@>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "cancel", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "show_signature", "hide_signature", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },

      -- ------------------------------------------------------------ behaviour
      completion = {
        keyword = { range = "full" },                   -- accepting mid-word replaces the whole word
        trigger = {
          show_on_backspace_in_keyword = true,          -- re-open after fixing a typo
          show_on_insert_on_trigger_character = false,  -- no popup just from entering insert after "."
        },
        list = {
          max_items = 100,
          selection = {
            -- no preselect while a snippet is active: Enter stays a newline
            preselect = function() return not require("blink.cmp").snippet_active({ direction = 1 }) end,
            auto_insert = false,                        -- ghost text previews instead of rewriting the line
          },
        },
        accept = { auto_brackets = { enabled = true } },
        menu = {
          border = "rounded",
          scrollbar = false,
          max_height = 14,
          draw = {
            treesitter = { "lsp" },                     -- labels highlighted like code
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },
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
          window = { border = "rounded", max_width = 90, max_height = 25 },
        },
        ghost_text = { enabled = true, show_with_selection = true, show_without_selection = false },
      },

      -- signature help while typing arguments (noice's popup is switched off below)
      signature = {
        enabled = true,
        window = { border = "rounded", show_documentation = false },
      },

      -- ---------------------------------------------------------------- fuzzy
      fuzzy = {
        implementation = "prefer_rust_with_warning",    -- prebuilt Rust matcher, downloaded once
        max_typos = function(keyword) return math.floor(#keyword / 4) end,
        frecency = { enabled = true },                  -- items you pick often rank first
        use_proximity = true,                           -- words near the cursor rank higher
        sorts = { "exact", "score", "sort_text" },      -- exact matches always on top
      },

      -- -------------------------------------------------------------- sources
      -- default list (lsp, path, snippets, buffer) + lazydev (lua) + dadbod (sql) come from LazyVim
      sources = {
        providers = {
          lsp = {
            fallbacks = {},                             -- buffer words next to LSP items (ranked lower)
            score_offset = 5,
            timeout_ms = 1000,
            transform_items = function(_, items)        -- drop the "Text" filler many servers send
              local Text = require("blink.cmp.types").CompletionItemKind.Text
              return vim.tbl_filter(function(item) return item.kind ~= Text end, items)
            end,
          },
          path = {
            score_offset = 3,
            opts = {
              show_hidden_files_by_default = true,      -- .gitlab-ci.yml, .github/, .env …
              trailing_slash = true,
              label_trailing_slash = true,
            },
          },
          snippets = {
            score_offset = -1,
            min_keyword_length = 2,
            -- no snippets right after "." / ":" / "(" (member and argument completion)
            should_show_items = function(ctx) return ctx.trigger.initial_kind ~= "trigger_character" end,
            -- own DevOps snippets in ~/.config/nvim/snippets + friendly-snippets
            opts = { search_paths = { vim.fn.stdpath("config") .. "/snippets" }, friendly_snippets = true },
          },
          buffer = {
            score_offset = -3,
            min_keyword_length = 3,
            max_items = 8,
            opts = {
              -- words from every visible normal buffer, skipping huge ones
              get_bufnrs = function()
                local seen, bufs = {}, {}
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local buf = vim.api.nvim_win_get_buf(win)
                  if not seen[buf] and vim.bo[buf].buftype == ""
                    and vim.api.nvim_buf_line_count(buf) <= MAX_BUFFER_LINES then
                    seen[buf] = true
                    table.insert(bufs, buf)
                  end
                end
                return bufs
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
          ["<Right>"] = false,
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
          menu = { auto_show = function() return vim.fn.getcmdtype() == ":" end },
          ghost_text = { enabled = true },
        },
      },

      term = { enabled = false },                       -- :terminal keeps the shell's own completion

      appearance = { nerd_font_variant = "mono" },      -- JetBrainsMono Nerd Font (Windows Terminal)
    },
  },

  -- one signature popup, not two
  {
    "folke/noice.nvim",
    optional = true,
    opts = { lsp = { signature = { enabled = false } } },
  },
}
