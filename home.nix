# Inputs
{ pkgs, ... }:

# Outputs
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "brendonakay";
  home.homeDirectory = "/home/brendonakay";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # Modules
  imports = [
    ./git/default.nix
    ./go/default.nix
    #./neovim/default.nix
    ./nixvim/default.nix
    ./ocaml/default.nix
    ./python/default.nix
    ./tmux/default.nix
    #./wayland/default.nix
    ./zsh/default.nix
    ./haskell/default.nix
    ./kitty/default.nix
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # AWS
    pkgs.awscli2

    # C Compiler
    pkgs.gcc
    # Make
    pkgs.cmake

    # Direnv
    pkgs.direnv

    # Rust
    pkgs.cargo
    pkgs.rustc

    # NodeJS
    pkgs.nodejs

    # Discord
    pkgs.discord

    # Spotify
    pkgs.spotify

    # Slack
    pkgs.slack

    # Torrent clients
    pkgs.fragments

    # Gleam
    pkgs.gleam

    # Erlang
    pkgs.erlang
    pkgs.rebar3

    # Tomli for Python
    # pkgs.tomli

    # Tex
    pkgs.texlive.combined.scheme-full

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/brendonakay/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Maybe move these to their own files
  programs.lazygit = { enable = true; };
}
