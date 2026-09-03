return {
  'pmizio/typescript-tools.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  opts = {
    baseIndentSize = 4,
    indentSive = 4,
    tabSize = 4,
  },

  config = function()
    require('typescript-tools').setup {
      filetypes = {
        'javascript',
        'javascriptreact',
        'javascript.jsx',
        'typescript',
        'typescriptreact',
        'typescript.tsx',
        'vue',
      },
      settings = {
        tsserver_plugins = {
          -- Requires global install of '@vue/typescript-plugin' and '@vue/language-server'
          '@vue/typescript-plugin',
        },
      },
    }
  end,
}
