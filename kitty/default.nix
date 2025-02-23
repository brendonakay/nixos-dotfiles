{
  # Kitty terminal
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty.conf;
    # font = {
    #   name = "FiraCode Nerd Font Mono";
    #   size = 14;
    # };
    # shellIntegration.enableZshIntegration = true;
    # settings = {
    #   bold_font = "auto";
    #   italic_font = "auto";
    #   bold_italic_font = "auto";
    # };
  };
}
