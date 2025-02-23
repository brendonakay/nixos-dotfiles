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
        "markdown"
      ];
      command = "setlocal spell spelllang=en";
    }

    {
      event = "BufWinEnter";
      pattern = "*.md";
      command = "
          function()
            vim.opt.colorcolumn = \"80\"
            vim.opt.textwidth = 80
          end
      ";
    }

    {
      event = "BufWinLeave";
      pattern = "*.md";
      command = "
          function()
            vim.opt.colorcolumn = \"120\"
            vim.opt.textwidth = 120
          end
      ";
    }
  ];
}
