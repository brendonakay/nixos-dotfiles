{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;

      nixvimInjections = true;

      folding = false;

      settings = {
        auto_install = false;
        ensure_installed = "all";
        highlight = {
          additional_vim_regex_highlighting = true;
          custom_captures = { };
          enable = true;
        };
        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = false;
            node_decremental = "grm";
            node_incremental = "grn";
            scope_incremental = "grc";
          };
        };
        indent = {
          enable = true;
        };
        parser_install_dir = {
          __raw = "vim.fs.joinpath(vim.fn.stdpath('data'), 'treesitter')";
        };
        sync_install = false;
      };

    };

    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 4;
      };
    };

    treesitter-refactor = {
      enable = true;
      highlightDefinitions = {
        enable = true;
        # Set to false if you have an `updatetime` of ~100.
        clearOnCursorMove = false;
      };
    };

    hmts.enable = true;
  };
}
