-- DevOps / SRE tooling inside nvim: Kubernetes/OpenShift, IaC commands, tmux, sessions,
-- git review, SQL. Everything is under two which-key groups:
--   <leader>k  Kubernetes / OpenShift      <leader>i  Infra (tofu/terraform/terragrunt/helm/ansible)

-- run a shell command for the current file in a floating terminal that stays open
local function run(cmd)
  return function()
    local file = vim.fn.shellescape(vim.fn.expand("%:p"))
    local dir = vim.fn.shellescape(vim.fn.expand("%:p:h"))
    local c = cmd:gsub("%%f", function() return file end)
    c = c:gsub("%%d", function() return dir end)
    vim.cmd("silent! write")
    Snacks.terminal(c, { cwd = vim.fn.expand("%:p:h"), auto_close = false, win = { position = "float" } })
  end
end

local function k8s_context()
  local ctxs = vim.fn.systemlist("kubectl config get-contexts -o name 2>/dev/null")
  if #ctxs == 0 then
    return vim.notify("no kubeconfig contexts", vim.log.levels.WARN)
  end
  vim.ui.select(ctxs, { prompt = "kube context" }, function(choice)
    if choice then
      vim.fn.system({ "kubectl", "config", "use-context", choice })
      vim.notify("kubectl context → " .. choice)
    end
  end)
end

return {
  -- which-key groups
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>k", group = "kubernetes / openshift", icon = "󱃾 " },
        { "<leader>i", group = "infra (iac)", icon = "󰒋 " },
      },
    },
  },

  -- Kubernetes / OpenShift (k9s in a float + per-file commands) ------------------------
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>kk", function() Snacks.terminal("k9s", { win = { position = "float", width = 0.95, height = 0.95 } }) end, desc = "k9s" },
      { "<leader>kx", k8s_context, desc = "Switch kube context" },
      { "<leader>kn", run("kubens 2>/dev/null || kubectl get ns"), desc = "Namespaces" },
      { "<leader>ka", run("kubectl apply --dry-run=server -f %f"), desc = "Dry-run apply (server)" },
      { "<leader>kA", run("kubectl apply -f %f"), desc = "Apply file" },
      { "<leader>kd", run("kubectl diff -f %f"), desc = "Diff file vs cluster" },
      { "<leader>kv", run("kubeconform -strict -summary -ignore-missing-schemas %f"), desc = "kubeconform file" },
      { "<leader>ko", run("oc apply --dry-run=server -f %f"), desc = "OpenShift dry-run apply" },
      { "<leader>kO", run("oc apply -f %f"), desc = "OpenShift apply" },
      { "<leader>kp", run("oc project"), desc = "OpenShift current project" },
      { "<leader>ke", run("kubectl explain $(awk '/^kind:/{print tolower($2); exit}' %f) --recursive | less"), desc = "Explain kind" },

      -- clipboard history (Windows + WSL) and the shell shortcut overview
      { "<leader>fY", function() Snacks.terminal("clip", { win = { position = "float" } }) end, desc = "Clipboard history (all apps)" },
      { "<leader>fK", function() Snacks.terminal("bash -ic keys", { win = { position = "float", width = 0.9, height = 0.9 } }) end, desc = "Shell/tmux/… shortcuts (keys)" },

      -- Infra as code
      { "<leader>ii", run("tofu init"), desc = "tofu init" },
      { "<leader>ip", run("tofu plan"), desc = "tofu plan" },
      { "<leader>iv", run("tofu validate && tflint"), desc = "tofu validate + tflint" },
      { "<leader>iI", run("terraform init"), desc = "terraform init" },
      { "<leader>iP", run("terraform plan"), desc = "terraform plan" },
      { "<leader>ig", run("terragrunt plan"), desc = "terragrunt plan" },
      { "<leader>iG", run("terragrunt hcl format --check || terragrunt hclfmt --terragrunt-check"), desc = "terragrunt format check" },
      { "<leader>ih", run("helm lint %d/.. && helm template %d/.. | less"), desc = "helm lint + template (chart)" },
      { "<leader>if", run("helmfile lint"), desc = "helmfile lint" },
      { "<leader>iF", run("helmfile diff"), desc = "helmfile diff" },
      { "<leader>ia", run("ansible-playbook --syntax-check %f && ansible-lint %f"), desc = "ansible syntax + lint" },
      { "<leader>iA", run("ansible-playbook --check --diff %f"), desc = "ansible check mode (dry run)" },
      { "<leader>id", run("hadolint %f"), desc = "hadolint Dockerfile" },
      { "<leader>ic", run("docker compose -f %f config -q && echo compose OK"), desc = "compose validate" },
      { "<leader>in", run("sudo nginx -t"), desc = "nginx -t" },
      { "<leader>is", run("trivy config %d"), desc = "trivy misconfig scan (dir)" },
    },
  },

  -- tmux: Ctrl-h/j/k/l moves across nvim splits AND tmux panes (pairs with tmux.conf)
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go left (nvim/tmux)" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go down (nvim/tmux)" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go up (nvim/tmux)" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go right (nvim/tmux)" },
      { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Previous pane" },
    },
  },

  -- Session.vim for tmux-resurrect (`@resurrect-strategy-nvim 'session'`)
  {
    "tpope/vim-obsession",
    cmd = "Obsession",
    keys = { { "<leader>qo", "<cmd>Obsession<cr>", desc = "Toggle Session.vim (tmux-resurrect)" } },
  },

  -- git: side-by-side diffs and file history (lazygit stays on <leader>gg)
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview (working tree)" },
      { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
    },
  },

  -- GitLab merge requests in nvim (needs a token; enable when you want it)
  {
    "harrisoncramer/gitlab.nvim",
    enabled = false,
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    build = function() require("gitlab.server").build(true) end,
    opts = {},
  },

  -- SQL: dadbod (from the lang.sql extra) — connections for MariaDB / PostgreSQL go in
  -- lua/plugins/local.lua (git-ignored), e.g.
  --   vim.g.dbs = { { name = "pg-local",    url = "postgres://postgres@localhost:5432/postgres" },
  --                 { name = "maria-local", url = "mysql://root@127.0.0.1:3306/mysql" } }
  -- then <leader>D opens the DB UI.
}
