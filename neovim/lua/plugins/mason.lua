return {
  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "flake8",
        -- go
        "json-to-struct",
        "staticcheck",
        "misspell",
        "revive",
        "impl",
        "delve",
        -- bash
        "bash-language-server",
        "shellcheck",
        "shfmt",
        -- python
        "jedi-language-server",
        "flake8",
        "black",
        "isort",
        "mypy",
        "pylint",
        -- terraform
        "tflint",
        "terraform-ls",
        -- javascript
        "eslint-lsp",
        "prettier",
        "eslint_d",
        "typescript-language-server",
        --"deno",
        -- lua
        "lua-language-server",
        "stylua",
        -- proto
        --"buf",
        -- misc
        "editorconfig-checker",
        "codespell",
        "css-lsp",
        "gitlint",
        "json-lsp",
        "sqlls",
        "vale",
      },
    },
  },
}
