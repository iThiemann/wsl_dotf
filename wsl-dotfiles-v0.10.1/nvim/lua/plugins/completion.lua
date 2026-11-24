-- blink.cmp — LazyVim's default completion engine. Only a few tweaks on top of
-- LazyVim's settings (lazy.nvim merges them); delete this file to get stock LazyVim.
return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          border = "rounded",
          draw = {
            -- add a source column: [LSP] [Buffer] [Snippets] [Path] …
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
            components = {
              source_name = {
                text = function(ctx) return "[" .. ctx.source_name .. "]" end,
                highlight = "Comment",
              },
            },
          },
        },
        documentation = { window = { border = "rounded" } },
      },
      fuzzy = { sorts = { "exact", "score", "sort_text" } },  -- exact matches always on top
      sources = {
        providers = {
          -- hidden files too (.gitlab-ci.yml, .github/)
          path = { opts = { show_hidden_files_by_default = true } },
          -- no snippets right after "." / ":" — that's member completion
          snippets = {
            should_show_items = function(ctx) return ctx.trigger.initial_kind ~= "trigger_character" end,
          },
        },
      },
    },
  },
}
