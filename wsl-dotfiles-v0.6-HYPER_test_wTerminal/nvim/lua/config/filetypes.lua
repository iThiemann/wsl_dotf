-- Filetype detection for DevOps files. Compound filetypes ("yaml.gitlab") keep YAML
-- highlighting + yamlls and additionally start the specialised server.
vim.filetype.add({
  extension = {
    tofu = "opentofu",
    tftest = "terraform",
    j2 = "jinja",
    jinja = "jinja",
    jinja2 = "jinja",
    jq = "jq",
    gotmpl = "gotmpl",
    http = "http",
    -- Podman Quadlet units
    container = "systemd",
    pod = "systemd",
    network = "systemd",
    volume = "systemd",
    kube = "systemd",
    build = "systemd",
  },
  filename = {
    ["terragrunt.hcl"] = "hcl",
    ["root.hcl"] = "hcl",
    [".terraformrc"] = "hcl",
    ["Containerfile"] = "dockerfile",
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
    [".gitlab-ci.yml"] = "yaml.gitlab",
    [".gitlab-ci.yaml"] = "yaml.gitlab",
    ["nginx.conf"] = "nginx",
    [".ansible-lint"] = "yaml",
    [".yamllint"] = "yaml",
    [".sqlfluff"] = "dosini",
    ["kubeconfig"] = "yaml",
  },
  pattern = {
    -- OpenTofu vars
    [".*%.tofuvars"] = "opentofu-vars",
    -- Terragrunt
    [".*/terragrunt%.hcl"] = "hcl",
    -- Containerfiles / Dockerfiles with suffix
    [".*/Containerfile%..*"] = "dockerfile",
    [".*/Dockerfile%..*"] = "dockerfile",
    [".*%.Dockerfile"] = "dockerfile",
    -- compose overrides
    [".*/docker%-compose%..*%.ya?ml"] = "yaml.docker-compose",
    [".*/compose%..*%.ya?ml"] = "yaml.docker-compose",
    -- GitLab CI includes / templates
    [".*%.gitlab%-ci%.ya?ml"] = "yaml.gitlab",
    [".*/%.gitlab/ci/.*%.ya?ml"] = "yaml.gitlab",
    [".*/ci%-templates/.*%.ya?ml"] = "yaml.gitlab",
    -- helmfile (yaml with Go templates) → helm filetype = gotmpl highlighting + helm_ls
    [".*/helmfile.*%.ya?ml%.gotmpl"] = "helm",
    [".*/helmfile%.d/.*%.ya?ml%.gotmpl"] = "helm",
    [".*%.ya?ml%.gotmpl"] = "helm",
    -- Ansible (nvim-ansible covers roles/playbooks; these are the common extras)
    [".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/meta/.*%.ya?ml"] = "yaml.ansible",
    [".*/group_vars/.*"] = "yaml.ansible",
    [".*/host_vars/.*"] = "yaml.ansible",
    [".*/site%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/templates/.*%.j2"] = "jinja",
    -- nginx
    [".*/nginx/.*%.conf"] = "nginx",
    [".*/conf%.d/.*%.conf"] = "nginx",
    [".*/sites%-available/.*"] = "nginx",
    [".*/sites%-enabled/.*"] = "nginx",
    [".*%.nginx"] = "nginx",
    -- ssh
    [".*/%.ssh/config%.d/.*"] = "sshconfig",
    [".*/ssh/config%.d/.*"] = "sshconfig",
    [".*/ssh_config%.d/.*"] = "sshconfig",
    -- SQL dialect hints by file name
    [".*%.mariadb%.sql"] = "sql",
    [".*%.mysql%.sql"] = "sql",
    [".*%.pg%.sql"] = "sql",
    [".*%.psql"] = "sql",
  },
})

-- Tree-sitter: reuse parsers for derived filetypes
vim.treesitter.language.register("hcl", { "opentofu", "opentofu-vars" })
vim.treesitter.language.register("yaml", { "yaml.gitlab", "yaml.docker-compose", "yaml.ansible" })
vim.treesitter.language.register("bash", { "zsh" })
