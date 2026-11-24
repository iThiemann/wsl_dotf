-- YAML schemas on top of SchemaStore (which the yaml extra already loads and which
-- covers compose, GitLab CI, helmfile, Ansible, GitHub Actions, kustomization, …).
--
-- Kubernetes: files under k8s/, kubernetes/, manifests/, deploy/ or named *.k8s.yaml
-- get the full Kubernetes schema. Anything else: add a modeline on line 1, e.g.
--   # yaml-language-server: $schema=https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/deployment-apps-v1.json
-- CRDs (cert-manager, ArgoCD, Istio, OpenShift Routes…): kubeconform validates them on
-- save via the CRDs-catalog (see devops-format-lint.lua); `<leader>ko` asks the real cluster.
local k8s = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/all.json"
local gitlab = "https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              keyOrdering = false,
              format = { enable = true },
              validate = true,
              completion = true,
              hover = true,
              customTags = {
                -- GitLab CI
                "!reference sequence",
                -- CloudFormation / AWS SAM
                "!Ref scalar", "!Sub scalar", "!Sub sequence", "!GetAtt scalar", "!GetAtt sequence",
                "!Join sequence", "!If sequence", "!Equals sequence", "!Select sequence",
                "!Split sequence", "!FindInMap sequence", "!ImportValue scalar", "!Base64 scalar",
                "!GetAZs scalar", "!Cidr sequence", "!And sequence", "!Or sequence", "!Not sequence",
                -- Ansible
                "!vault scalar", "!unsafe scalar",
              },
              schemas = {
                [k8s] = {
                  "**/k8s/**/*.yaml", "**/k8s/**/*.yml",
                  "**/kubernetes/**/*.yaml", "**/kubernetes/**/*.yml",
                  "**/manifests/**/*.yaml", "**/manifests/**/*.yml",
                  "**/deploy/**/*.yaml", "**/deploy/**/*.yml",
                  "*.k8s.yaml", "*.k8s.yml",
                },
                [gitlab] = {
                  ".gitlab-ci.yml", "*.gitlab-ci.yml", ".gitlab/ci/**/*.yml", "ci-templates/**/*.yml",
                },
              },
            },
          },
        },
      },
    },
  },
}
