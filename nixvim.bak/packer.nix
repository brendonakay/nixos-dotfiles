{
  programs.nixvim.plugins = {
    packer = {
      enable = true;
      plugins = [ "vimwiki/vimwiki" ];
    };
  };
}
