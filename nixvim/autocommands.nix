{
  programs.nixvim.autoCmd = [
    # Vertically center document when entering insert mode
    {
      event = "InsertEnter";
      command = "norm zz";
    }

    # Open help in a vertical split
    {
      event = "FileType";
      pattern = "help";
      command = "wincmd L";
    }

    # Enable spellcheck for some filetypes
    {
      event = "FileType";
      pattern = [
        "*.markdown"
        "*.md"
      ];
      command = "setlocal spell spelllang=en";
    }

    {
      event = "BufWinEnter";
      pattern = [
        "*.markdown"
        "*.md"
      ];
      callback = {
        __raw = ''
          function()
            vim.opt.colorcolumn = "80"
            vim.opt.textwidth = 80
          end
        '';
      };
    }

    {
      event = "BufWinLeave";
      pattern = [
        "*.markdown"
        "*.md"
      ];
      callback = {
        __raw = ''
          function()
            vim.opt.colorcolumn = "120"
            vim.opt.textwidth = 120
          end
        '';
      };
    }

    {
      event = "CursorHold";
      pattern = "*";
      callback = {
        __raw = ''
          function()
            for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_win_get_config(winid).zindex then
                return
              end
            end
            vim.diagnostic.open_float(0, {
              scope = "line",
              focusable = false,
              close_events = {
                "CursorMoved",
                "CursorMovedI",
                "BufHidden",
                "InsertCharPre",
                "WinLeave",
              },
            })
          end
        '';
      };
    }
  ];
}
