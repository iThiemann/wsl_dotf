-- nvim --headless -c "luafile tests/run.lua"   (tests/run.sh does this for you)
require("devops.test").run({ only = vim.env.DEVOPS_TEST_ONLY })
