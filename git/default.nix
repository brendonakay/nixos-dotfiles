{ config, pkgs, ... }:

{
    programs.git = {
      enable = true;
      userName  = "Brendon A. Kay";
      userEmail = "bak04280@gmail.com";
      aliases = {
        st = "status";
      };
    };
}
