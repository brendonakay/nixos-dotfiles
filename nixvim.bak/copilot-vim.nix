{
  programs.nixvim.plugins = {
    copilot-vim = {
      enable = true;
      settings = {
        filetypes = {
          "*" = false;
          python = true;
          haskell = true;
        };
      };
    };
  };
}
